"""Production LangGraph executor for validated declarative workflow manifests.

The graph owns workflow dispatch after bootstrap.  It never creates commands or
dependencies: every executable and source must already be represented by the
manifest. Raw subprocess output is kept under the machine runtime root rather
than in GraphState or a repository.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import subprocess
import tempfile
from pathlib import Path
from typing import Any, Protocol, TypedDict

from langgraph.checkpoint.sqlite import SqliteSaver
from langgraph.graph import END, START, StateGraph


NODE_TYPES = {"agent", "decision", "command", "finalization"}
RUN_ID = re.compile(r"^[A-Za-z0-9._-]+$")


class GraphState(TypedDict, total=False):
    run_id: str
    manifest_fingerprint: str
    next_node: str | None
    completed_stages: list[str]
    events: list[dict[str, str]]
    outputs: dict[str, dict[str, Any]]
    status: str
    review_revision: int
    approval_tree_revision: str
    approval_review_node: str
    last_outcome: str
    runtime_root: str


class SemanticExecutor(Protocol):
    def execute(self, node: dict[str, Any], capsule: dict[str, Any], runtime_root: Path) -> dict[str, Any]: ...


def _edge_parts(edge: str | dict[str, Any]) -> tuple[str, str, str]:
    if isinstance(edge, str):
        match = re.fullmatch(r"([A-Za-z][A-Za-z0-9_-]*)(?:\(([A-Za-z][A-Za-z0-9_-]*)\))?->([A-Za-z][A-Za-z0-9_-]*)", edge)
        if not match:
            raise ValueError(f"invalid manifest edge: {edge}")
        return match.group(1), match.group(2) or "", match.group(3)
    if not isinstance(edge, dict) or not isinstance(edge.get("from"), str) or not isinstance(edge.get("to"), str):
        raise ValueError("object edge requires string from and to")
    return edge["from"], str(edge.get("condition", "")), edge["to"]


def validate_manifest(manifest: dict[str, Any]) -> None:
    required = {"schemaVersion", "kind", "fingerprint", "projectRoot", "sourceFiles", "nodes", "edges", "policy"}
    if not required.issubset(manifest) or manifest["schemaVersion"] != 1 or manifest["kind"] != "validated-execution-manifest":
        raise ValueError("invalid manifest header")
    if not re.fullmatch(r"[a-f0-9]{64}", str(manifest["fingerprint"])):
        raise ValueError("invalid manifest fingerprint")
    sources = manifest["sourceFiles"]
    if not isinstance(sources, list) or not sources or len(sources) != len(set(sources)):
        raise ValueError("manifest sourceFiles must be a non-empty unique list")
    if any(not isinstance(value, str) or Path(value).is_absolute() or ".." in Path(value).parts for value in sources):
        raise ValueError("manifest sourceFiles must be project-relative")
    nodes = manifest["nodes"]
    if not isinstance(nodes, list) or not nodes:
        raise ValueError("manifest nodes are required")
    ids = [node.get("id") for node in nodes if isinstance(node, dict)]
    if len(ids) != len(nodes) or len(ids) != len(set(ids)) or any(not isinstance(value, str) or not re.fullmatch(r"[A-Za-z][A-Za-z0-9_-]*", value) for value in ids):
        raise ValueError("manifest node ids must be unique")
    for node in nodes:
        kind = node.get("type")
        if kind not in NODE_TYPES:
            raise ValueError(f"unsupported node type: {kind}")
        if kind in {"agent", "decision"} and not isinstance(node.get("role"), str):
            raise ValueError(f"semantic node {node['id']} requires role")
        if "source" in node and node["source"].replace("\\", "/") not in sources:
            raise ValueError(f"node source is undeclared: {node['id']}")
        if kind == "command":
            command = node.get("command")
            if not isinstance(command, dict) or command.get("filePath", "").replace("\\", "/") not in sources or not isinstance(command.get("arguments"), list):
                raise ValueError(f"command is undeclared or malformed: {node['id']}")
        if kind == "finalization" and not isinstance(node.get("finalization"), dict):
            raise ValueError(f"finalization node requires declaration: {node['id']}")
        if kind == "finalization" and node["finalization"].get("manifestPath", "").replace("\\", "/") not in sources:
            raise ValueError(f"finalization manifest is undeclared: {node['id']}")
    edges = [_edge_parts(edge) for edge in manifest["edges"]]
    if sum(source == "START" for source, _, _ in edges) != 1:
        raise ValueError("manifest needs exactly one START edge")
    for source, _, target in edges:
        if source != "START" and source not in ids or target not in ids:
            raise ValueError("manifest edge references unknown node")
    policy = manifest["policy"]
    if not isinstance(policy, dict) or any(policy.get(key) is not True for key in ("reviewBeforeGate", "gateFailureBlocksFinalization", "rawLogsExternal")):
        raise ValueError("manifest policy does not enforce execution invariants")
    gate_ids = {node["id"] for node in nodes if node["type"] == "command" and (node.get("phase") == "gate" or "gate" in node["id"].lower())}
    reviews = {node["id"] for node in nodes if node["type"] == "decision" and ("review" in node.get("role", "").lower() or "review" in node["id"].lower())}
    finals = {node["id"] for node in nodes if node["type"] == "finalization"}
    for gate in gate_ids:
        if not any(target == gate and condition == "APPROVED" and source in reviews for source, condition, target in edges):
            raise ValueError(f"gate {gate} lacks APPROVED review predecessor")
    for review in reviews:
        finding_edges = [(condition, target) for source, condition, target in edges if source == review and condition == "FINDING"]
        if len(finding_edges) != 1:
            raise ValueError(f"review {review} requires exactly one FINDING correction edge")
        correction = finding_edges[0][1]
        correction_node = next(node for node in nodes if node["id"] == correction)
        if correction_node["type"] != "agent":
            raise ValueError(f"review {review} FINDING target must be an agent correction")
        correction_edges = [(condition, target) for source, condition, target in edges if source == correction]
        if correction_edges != [("", review)]:
            raise ValueError(f"correction {correction} must route only back to review {review}")
        if any(source == review and condition == "FINDING" and target != correction for source, condition, target in edges):
            raise ValueError(f"review {review} has a FINDING bypass")
    for final in finals:
        for source, condition, target in edges:
            if target == final and (source not in gate_ids or condition != "GREEN"):
                raise ValueError("finalization may only follow a GREEN gate")


def _routing(node: dict[str, Any], manifest: dict[str, Any]) -> tuple[str, str]:
    routing = manifest.get("routing", {})
    roles = routing.get("roles", {}) if isinstance(routing, dict) else {}
    configured = roles.get(node.get("role"), {}) if isinstance(roles, dict) else {}
    model = node.get("model") or configured.get("model") or routing.get("defaultModel", "gpt-5.6-luna")
    reasoning = node.get("reasoning") or configured.get("reasoning") or routing.get("defaultReasoning", "medium")
    if node.get("role") == "architect_escalation":
        model, reasoning = model if "sol" in str(model).lower() else "gpt-5.6-sol", "low"
    return str(model), str(reasoning)


def _runtime_root(path: str | Path) -> Path:
    root = Path(path).resolve()
    root.mkdir(parents=True, exist_ok=True)
    probe = subprocess.run(["git", "-C", str(root), "rev-parse", "--show-toplevel"], capture_output=True, text=True)
    if probe.returncode == 0:
        raise ValueError(f"runtime root must be outside a Git worktree: {probe.stdout.strip()}")
    return root


def _git_tree_revision(project_root: str) -> str:
    root = Path(project_root).resolve()
    def git_bytes(*args: str) -> bytes:
        result = subprocess.run(["git", "-C", str(root), *args], capture_output=True)
        if result.returncode != 0:
            raise RuntimeError(f"Git tree revision command failed: {' '.join(args)}")
        return result.stdout

    try:
        head = git_bytes("rev-parse", "HEAD")
        staged = git_bytes("diff", "--cached", "--binary", "--no-ext-diff")
        unstaged = git_bytes("diff", "--binary", "--no-ext-diff")
        untracked = git_bytes("ls-files", "--others", "--exclude-standard", "-z")
    except RuntimeError:
        raise RuntimeError("cannot capture Git tree revision for approval")
    digest = hashlib.sha256()
    for label, evidence in ((b"HEAD", head), (b"STAGED", staged), (b"UNSTAGED", unstaged)):
        digest.update(label + b"\0" + evidence + b"\0")
    for relative in sorted(part for part in untracked.split(b"\0") if part):
        candidate = (root / os.fsdecode(relative)).resolve()
        if root not in candidate.parents or not candidate.is_file():
            raise RuntimeError("untracked path escaped project root during approval capture")
        digest.update(b"UNTRACKED\0" + relative + b"\0" + hashlib.sha256(candidate.read_bytes()).digest())
    return digest.hexdigest()


def _decision_schema(node: dict[str, Any], manifest: dict[str, Any]) -> dict[str, Any]:
    outcomes = {condition for source, condition, _ in map(_edge_parts, manifest["edges"]) if source == node["id"] and condition}
    if any(source == node["id"] and not condition for source, condition, _ in map(_edge_parts, manifest["edges"])):
        outcomes.add("DONE")
    if not outcomes:
        raise ValueError(f"semantic node has no declared outcome: {node['id']}")
    return {
        "type": "object",
        "additionalProperties": False,
        "required": ["decision", "summary", "artifacts"],
        "properties": {
            "decision": {"type": "string", "enum": sorted(outcomes)},
            "summary": {"type": "string", "maxLength": 2000},
            "artifacts": {"type": "array", "maxItems": 20, "items": {"type": "string", "maxLength": 512}},
        },
    }


def _parse_jsonl(text: str, allowed_decisions: set[str]) -> dict[str, Any]:
    messages: list[str] = []
    for line in text.splitlines():
        try:
            item = json.loads(line)
        except json.JSONDecodeError:
            continue
        if isinstance(item.get("response"), dict) and isinstance(item["response"].get("output_text"), str):
            messages.append(item["response"]["output_text"])
        inner = item.get("item")
        if isinstance(inner, dict) and inner.get("type") in {"agent_message", "message"}:
            value = inner.get("text") or inner.get("content")
            if isinstance(value, str):
                messages.append(value)
    if not messages:
        raise ValueError("Codex JSONL did not contain an agent message")
    try:
        value = json.loads(messages[-1])
    except json.JSONDecodeError as error:
        raise ValueError("Codex final message is not JSON") from error
    if not isinstance(value, dict) or set(value) != {"decision", "summary", "artifacts"}:
        raise ValueError("Codex response does not match the decision schema")
    if value["decision"] not in allowed_decisions or not isinstance(value["summary"], str) or len(value["summary"]) > 2000:
        raise ValueError("Codex response decision or summary is invalid")
    if not isinstance(value["artifacts"], list) or len(value["artifacts"]) > 20 or any(not isinstance(item, str) or len(item) > 512 for item in value["artifacts"]):
        raise ValueError("Codex response artifacts are invalid")
    return value


class CodexCliExecutor:
    """Provider adapter. It uses the existing ChatGPT Codex login, never an API key."""

    def __init__(self, executable: str = "codex") -> None:
        self.executable = executable

    def execute(self, node: dict[str, Any], capsule: dict[str, Any], runtime_root: Path) -> dict[str, Any]:
        model, reasoning = _routing(node, capsule["manifest"])
        response_schema = _decision_schema(node, capsule["manifest"])
        schema = runtime_root / f"{node['id']}.response-schema.json"
        schema.write_text(json.dumps(response_schema), encoding="utf-8")
        prompt = json.dumps({"role": node["role"], "node": node["id"], "source": node.get("source"), "capsule": capsule["capsule"], "instruction": "Return only a JSON object conforming to the output schema. decision is APPROVED, FINDING, DONE, or BLOCKED."}, ensure_ascii=False)
        environment = os.environ.copy()
        environment.pop("OPENAI_API_KEY", None)
        process = subprocess.run([self.executable, "exec", "--ephemeral", "--json", "--ignore-user-config", "--ignore-rules", "--output-schema", str(schema), "-m", model, "-c", f"model_reasoning_effort={reasoning}", prompt], capture_output=True, text=True, cwd=capsule["project_root"], env=environment, timeout=int(capsule.get("timeout_seconds", 3600)))
        log = runtime_root / f"{node['id']}.codex.jsonl"
        log.write_text(process.stdout + ("\n[stderr]\n" + process.stderr if process.stderr else ""), encoding="utf-8")
        if process.returncode != 0:
            raise RuntimeError(f"Codex semantic node failed ({node['id']}); raw log: {log}")
        return _parse_jsonl(process.stdout, set(response_schema["properties"]["decision"]["enum"]))


def _command_result(manifest: dict[str, Any], node: dict[str, Any], state: GraphState) -> str:
    root = Path(manifest["projectRoot"]).resolve()
    command = node["command"]
    file_path = (root / command["filePath"]).resolve()
    if root not in file_path.parents or not file_path.is_file():
        raise ValueError(f"command escapes project root: {command['filePath']}")
    cwd = (root / command.get("cwd", ".")).resolve()
    if cwd != root and root not in cwd.parents:
        raise ValueError("command cwd escapes project root")
    args = command["arguments"]
    runner = Path(__file__).resolve().parents[1] / "bin" / "agentic-run.ps1"
    pwsh = os.environ.get("AGENTIC_PWSH", "pwsh")
    executable, argv = (pwsh, ["-NoProfile", "-File", str(file_path), *args]) if file_path.suffix.lower() == ".ps1" else (str(file_path), args)
    result = subprocess.run([pwsh, "-NoProfile", "-File", str(runner), "-FilePath", executable, "-ArgumentsJson", json.dumps(argv), "-WorkingDirectory", str(cwd), "-RuntimeRoot", str(state["runtime_root"]), "-RunId", f"{state['run_id']}-{node['id']}", "-Phase", str(node.get("phase", "command"))], capture_output=True, text=True, timeout=int(command.get("timeoutSeconds", 3600)) + 20)
    log = Path(state["runtime_root"]) / f"{node['id']}.runner.json"
    log.write_text(result.stdout + ("\n[stderr]\n" + result.stderr if result.stderr else ""), encoding="utf-8")
    try:
        compact = json.loads(result.stdout)
    except json.JSONDecodeError as error:
        raise RuntimeError(f"runner did not return compact JSON: {log}") from error
    return "GREEN" if compact.get("status") == "COMPLETED" else str(compact.get("status", "FAILED"))


def _finalize(manifest: dict[str, Any], node: dict[str, Any], state: GraphState, allow_write: bool, allow_commit: bool) -> str:
    declaration = node["finalization"]
    if declaration.get("allowWrite", False) and not allow_write or declaration.get("allowCommit", False) and not allow_commit:
        return "BLOCKED"
    root = Path(manifest["projectRoot"]).resolve()
    target = (root / declaration["manifestPath"]).resolve()
    if root not in target.parents or not target.is_file():
        raise ValueError("finalization manifest escapes or is missing")
    args = ["-NoProfile", "-File", str(Path(__file__).resolve().parents[1] / "bin" / "agentic-finalize.ps1"), "-ManifestPath", str(target)]
    if declaration.get("allowWrite") and allow_write: args.append("-AllowWrite")
    if declaration.get("allowCommit") and allow_commit: args.append("-AllowCommit")
    result = subprocess.run([os.environ.get("AGENTIC_PWSH", "pwsh"), *args], capture_output=True, text=True, cwd=root, timeout=3600)
    (Path(state["runtime_root"]) / f"{node['id']}.finalize.json").write_text(result.stdout + ("\n[stderr]\n" + result.stderr if result.stderr else ""), encoding="utf-8")
    return "DONE" if result.returncode == 0 else "FAILED"


def build_graph(manifest: dict[str, Any], checkpointer: SqliteSaver, executor: SemanticExecutor, allow_write: bool, allow_commit: bool):
    validate_manifest(manifest)
    by_id = {node["id"]: node for node in manifest["nodes"]}

    graph = StateGraph(GraphState)
    def node_handler(node: dict[str, Any]):
        def execute_node(state: GraphState) -> dict[str, Any]:
            node_id = node["id"]
            try:
                if node["type"] in {"agent", "decision"}:
                    answer = executor.execute(node, {"manifest": manifest, "project_root": manifest["projectRoot"], "capsule": {"runId": state["run_id"], "completedStages": state.get("completed_stages", []), "reviewRevision": state.get("review_revision", 0)}}, Path(state["runtime_root"]))
                    outcome = answer["decision"]
                elif node["type"] == "command":
                    if node.get("phase") == "gate" or "gate" in node_id.lower():
                        if state.get("approval_tree_revision") != _git_tree_revision(manifest["projectRoot"]):
                            answer, outcome = {"error": "tree changed after review approval"}, "TREE_CHANGED"
                        else:
                            answer, outcome = {}, _command_result(manifest, node, state)
                    else:
                        answer, outcome = {}, _command_result(manifest, node, state)
                else:
                    answer, outcome = {}, _finalize(manifest, node, state, allow_write, allow_commit)
            except Exception as error:
                answer, outcome = {"error": str(error)}, "FAILED"
            approval = state.get("approval_tree_revision", "")
            approval_node = state.get("approval_review_node", "")
            if node["type"] == "decision" and outcome == "APPROVED":
                approval, approval_node = _git_tree_revision(manifest["projectRoot"]), node_id
            status = "RUNNING"
            if outcome in {"FAILED", "TREE_CHANGED", "BLOCKED"}:
                status = "GATE_FAILED" if node.get("phase") == "gate" or "gate" in node_id.lower() else "BLOCKED"
            if node["type"] == "finalization" and outcome == "DONE":
                status = "DONE"
            revision = state.get("review_revision", 0) + (1 if node_id.lower().startswith("correction") and outcome == "DONE" else 0)
            return {"completed_stages": [*state.get("completed_stages", []), node_id], "events": [*state.get("events", []), {"stage": node_id, "status": outcome}], "outputs": {**state.get("outputs", {}), node_id: answer}, "review_revision": revision, "approval_tree_revision": approval, "approval_review_node": approval_node, "last_outcome": outcome, "status": status}
        return execute_node

    for node in manifest["nodes"]:
        graph.add_node(node["id"], node_handler(node))
    edge_groups: dict[str, list[tuple[str, str]]] = {}
    for source, condition, target in map(_edge_parts, manifest["edges"]):
        if source == "START":
            graph.add_edge(START, target)
        else:
            edge_groups.setdefault(source, []).append((condition, target))
    for source, routes in edge_groups.items():
        if len(routes) == 1 and not routes[0][0]:
            graph.add_edge(source, routes[0][1])
            continue
        mapping = {condition: target for condition, target in routes if condition}
        fallback = next((target for condition, target in routes if not condition), END)
        destinations = {target: target for target in [*mapping.values(), fallback]}
        destinations[END] = END
        graph.add_conditional_edges(source, lambda state, m=mapping, f=fallback: m.get(state.get("last_outcome", ""), f), destinations)
    for node in manifest["nodes"]:
        if node["id"] not in edge_groups:
            graph.add_edge(node["id"], END)
    return graph.compile(checkpointer=checkpointer)


def run(manifest: dict[str, Any], run_id: str, checkpoint_path: str, *, resume: bool = False, executor: SemanticExecutor | None = None, runtime_root: str | None = None, allow_write: bool = False, allow_commit: bool = False) -> dict[str, Any]:
    if not RUN_ID.fullmatch(run_id):
        raise ValueError("unsafe run_id")
    validate_manifest(manifest)
    root = _runtime_root(runtime_root or Path(tempfile.gettempdir()) / "agentic-harness" / "graph-runs" / run_id)
    checkpoint = Path(checkpoint_path).resolve()
    _runtime_root(checkpoint.parent)
    checkpoint.parent.mkdir(parents=True, exist_ok=True)
    semantic = executor or CodexCliExecutor()
    with SqliteSaver.from_conn_string(str(checkpoint)) as checkpointer:
        graph = build_graph(manifest, checkpointer, semantic, allow_write, allow_commit)
        config = {"configurable": {"thread_id": run_id}}
        previous = graph.get_state(config).values
        if resume:
            if not previous:
                raise ValueError(f"no checkpoint exists for run_id={run_id}")
            if previous.get("manifest_fingerprint") != manifest["fingerprint"]:
                raise ValueError("checkpoint fingerprint does not match manifest")
            return dict(previous)
        else:
            if previous:
                raise ValueError(f"checkpoint already exists for run_id={run_id}; use resume")
            state = {"run_id": run_id, "manifest_fingerprint": manifest["fingerprint"], "completed_stages": [], "events": [], "outputs": {}, "status": "RUNNING", "review_revision": 0, "runtime_root": str(root)}
        return dict(graph.invoke(state, config))


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--manifest", required=True)
    parser.add_argument("--run-id", required=True)
    parser.add_argument("--checkpoint", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--runtime-root")
    parser.add_argument("--resume", action="store_true")
    parser.add_argument("--allow-write", action="store_true")
    parser.add_argument("--allow-commit", action="store_true")
    args = parser.parse_args()
    manifest = json.loads(Path(args.manifest).read_text(encoding="utf-8"))
    state = run(manifest, args.run_id, args.checkpoint, resume=args.resume, runtime_root=args.runtime_root, allow_write=args.allow_write, allow_commit=args.allow_commit)
    Path(args.output).parent.mkdir(parents=True, exist_ok=True)
    Path(args.output).write_text(json.dumps(state, indent=2), encoding="utf-8")
    print(json.dumps({"status": state.get("status"), "runId": args.run_id, "checkpoint": args.checkpoint}))
    return 0 if state.get("status") == "DONE" else 1


if __name__ == "__main__":
    raise SystemExit(main())
