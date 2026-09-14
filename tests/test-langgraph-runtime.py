"""Deterministic V3 tests. No test invokes a real model or stores raw logs in state."""
from __future__ import annotations

import hashlib
import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from runtime import langgraph_runtime as runtime


class FakeExecutor:
    def __init__(self) -> None:
        self.calls: list[str] = []

    def execute(self, node, capsule, runtime_root):
        self.calls.append(node["id"])
        if node["id"] == "REVIEW" and "CORRECTION" not in capsule["capsule"]["completedStages"]:
            return {"decision": "FINDING", "summary": "fixture finding", "artifacts": []}
        return {"decision": "APPROVED" if node["id"] == "REVIEW" else "DONE", "summary": "fixture", "artifacts": []}


def manifest(root: Path, fingerprint: str = "a" * 64):
    for name in ("preflight.md", "implementation.md", "review.md", "gate.ps1", "finalize.json"):
        (root / name).write_text("fixture", encoding="utf-8")
    return {
        "schemaVersion": 1,
        "kind": "validated-execution-manifest",
        "fingerprint": fingerprint,
        "projectRoot": str(root),
        "sourceFiles": ["preflight.md", "implementation.md", "review.md", "gate.ps1", "finalize.json"],
        "nodes": [
            {"id": "PREFLIGHT", "type": "agent", "role": "scout", "source": "preflight.md"},
            {"id": "IMPLEMENT", "type": "agent", "role": "implementer", "source": "implementation.md"},
            {"id": "REVIEW", "type": "decision", "role": "reviewer", "source": "review.md"},
            {"id": "CORRECTION", "type": "agent", "role": "implementer", "source": "implementation.md"},
            {"id": "GATE", "type": "command", "phase": "gate", "command": {"filePath": "gate.ps1", "arguments": ["space value", "", "&|;"], "cwd": "."}},
            {"id": "FINALIZE", "type": "finalization", "finalization": {"manifestPath": "finalize.json", "allowWrite": False, "allowCommit": False}},
        ],
        "edges": ["START->PREFLIGHT", "PREFLIGHT->IMPLEMENT", "IMPLEMENT->REVIEW", "REVIEW(FINDING)->CORRECTION", "CORRECTION->REVIEW", "REVIEW(APPROVED)->GATE", "GATE(GREEN)->FINALIZE"],
        "policy": {"reviewBeforeGate": True, "gateFailureBlocksFinalization": True, "rawLogsExternal": True},
        "routing": {"defaultModel": "gpt-5.6-luna", "defaultReasoning": "medium"},
    }


def make_git_repo(root: Path) -> None:
    for args in (("init",), ("config", "user.email", "tests@example.invalid"), ("config", "user.name", "Tests"), ("add", "."), ("commit", "-m", "fixture")):
        subprocess.run(["git", "-C", str(root), *args], check=True, capture_output=True)


class LangGraphRuntimeTests(unittest.TestCase):
    def test_finding_correction_rereview_gate_and_finalization(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            fake = FakeExecutor()
            with patch.object(runtime, "_command_result", return_value="GREEN"), patch.object(runtime, "_finalize", return_value="DONE"), patch.object(runtime, "_git_tree_revision", return_value="tree-a"):
                state = runtime.run(manifest(root), "finding", str(root / "checkpoint.sqlite"), executor=fake, runtime_root=str(root / "logs"))
        self.assertEqual(state["status"], "DONE")
        self.assertEqual([item["status"] for item in state["events"]], ["DONE", "DONE", "FINDING", "DONE", "APPROVED", "GREEN", "DONE"])
        self.assertEqual(fake.calls, ["PREFLIGHT", "IMPLEMENT", "REVIEW", "CORRECTION", "REVIEW"])
        self.assertNotIn("raw", json.dumps(state))

    def test_checkpoint_resume_rejects_fingerprint_change(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            fake = FakeExecutor()
            with patch.object(runtime, "_command_result", return_value="GREEN"), patch.object(runtime, "_finalize", return_value="DONE"), patch.object(runtime, "_git_tree_revision", return_value="tree-a"):
                runtime.run(manifest(root), "resume", str(root / "checkpoint.sqlite"), executor=fake)
                with self.assertRaisesRegex(ValueError, "fingerprint"):
                    runtime.run(manifest(root, "b" * 64), "resume", str(root / "checkpoint.sqlite"), resume=True, executor=fake)

    def test_invalid_finalization_and_gate_order_are_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            value = manifest(Path(directory))
            value["edges"][-1] = "IMPLEMENT->FINALIZE"
            with self.assertRaisesRegex(ValueError, "finalization"):
                runtime.validate_manifest(value)
            value = manifest(Path(directory))
            value["edges"][3] = "REVIEW(FINDING)->GATE"
            with self.assertRaisesRegex(ValueError, "FINDING"):
                runtime.validate_manifest(value)

    def test_codex_jsonl_parser_requires_structured_agent_message(self):
        payload = json.dumps({"item": {"type": "agent_message", "text": '{"decision":"APPROVED","summary":"ok","artifacts":[]}'}})
        self.assertEqual(runtime._parse_jsonl(payload, {"APPROVED"})["decision"], "APPROVED")
        with self.assertRaisesRegex(ValueError, "not JSON"):
            runtime._parse_jsonl(json.dumps({"item": {"type": "agent_message", "text": "plain text"}}), {"APPROVED"})

    def test_schema_rejects_extra_or_undeclared_decision(self):
        payload = json.dumps({"item": {"type": "agent_message", "text": '{"decision":"DANGEROUS","summary":"ok","artifacts":[],"extra":true}'}})
        with self.assertRaisesRegex(ValueError, "decision schema"):
            runtime._parse_jsonl(payload, {"APPROVED"})

    def test_runtime_root_and_checkpoint_parent_are_external(self):
        with tempfile.TemporaryDirectory() as directory, tempfile.TemporaryDirectory() as runtime_directory:
            root = Path(directory)
            value = manifest(root)
            make_git_repo(root)
            checkpoint = Path(runtime_directory) / "nested" / "state.sqlite"
            fake = FakeExecutor()
            with patch.object(runtime, "_command_result", return_value="GREEN"), patch.object(runtime, "_finalize", return_value="DONE"), patch.object(runtime, "_git_tree_revision", return_value="tree-a"):
                runtime.run(value, "parent", str(checkpoint), executor=fake, runtime_root=str(Path(runtime_directory) / "logs"))
            self.assertTrue(checkpoint.exists())
            with self.assertRaisesRegex(ValueError, "outside a Git worktree"):
                runtime.run(value, "inside", str(Path(runtime_directory) / "other.sqlite"), executor=fake, runtime_root=str(root / "logs2"))
            with self.assertRaisesRegex(ValueError, "outside a Git worktree"):
                runtime.run(value, "inside-checkpoint", str(root / "inside.sqlite"), executor=fake, runtime_root=str(Path(runtime_directory) / "logs3"))

    def test_tree_drift_after_approval_blocks_gate(self):
        with tempfile.TemporaryDirectory() as directory, tempfile.TemporaryDirectory() as runtime_directory:
            root = Path(directory)
            value = manifest(root)
            make_git_repo(root)
            (root / "gate.ps1").write_text("modified before approval", encoding="utf-8")
            untracked = root / "untracked.txt"
            untracked.write_text("first content", encoding="utf-8")
            original_revision = runtime._git_tree_revision
            calls = 0
            def drifted_revision(project_root: str) -> str:
                nonlocal calls
                calls += 1
                if calls == 2:
                    (root / "gate.ps1").write_text("modified again after approval", encoding="utf-8")
                    untracked.write_text("changed untracked content after approval", encoding="utf-8")
                return original_revision(project_root)
            with patch.object(runtime, "_command_result", return_value="GREEN") as command, patch.object(runtime, "_finalize", return_value="DONE"), patch.object(runtime, "_git_tree_revision", side_effect=drifted_revision):
                state = runtime.run(value, "drift", str(Path(runtime_directory) / "state.sqlite"), executor=FakeExecutor(), runtime_root=str(Path(runtime_directory) / "logs"))
        self.assertEqual(state["status"], "GATE_FAILED")
        command.assert_not_called()

    def test_routing_keeps_escalation_at_sol_low(self):
        model, reasoning = runtime._routing({"id": "ARCH", "role": "architect_escalation"}, {"routing": {"defaultModel": "gpt-5.6-luna", "defaultReasoning": "high"}})
        self.assertEqual((model, reasoning), ("gpt-5.6-sol", "low"))


if __name__ == "__main__":
    unittest.main()
