## Deterministic execution boundaries

- If no semantic decision exists between operations, do not insert a model inference between them. An agent reasons until a decision boundary; a deterministic runner executes and waits between decision boundaries.
- Preserve commands defined by an authoritative project instruction exactly in purpose, executable, arguments, working directory, and required environment. The global harness may change only the execution mechanics used to wait, capture output, and report terminal status.
- When the installed blocking runner is available, gates, test suites, full builds, restores or installs that may run long, migrations, Docker lifecycle checks, integrated validation scripts, and any command that would otherwise require polling MUST use it.
- Starting a process and repeatedly asking for status through model/tool turns is forbidden when the blocking runner is available. The runner owns waiting through `completed`, `failed`, or `timeout` and returns one compact structured terminal result.
- Keep stdout, stderr, run state, and result files in the runner's machine-local runtime directory. Return bounded summaries and paths by default; inspect only a targeted tail or range when failure analysis needs it.
- Operational run state is not durable project documentation. Never place runtime logs, state, credentials, tokens, or secrets in a repository merely to make them accessible to an agent.
- Small read-only commands such as focused search, status, diff statistics, bounded file reads, and version checks may run directly.
- Mechanical finalization consumes an explicit structured manifest derived from the current authoritative instruction. It must not invent project-specific paths or actions, and staging or commit requires both manifest intent and explicit runtime authorization.

The installed portable interfaces are `~/.agentic-harness/bin/agentic-run.ps1` and `~/.agentic-harness/bin/agentic-finalize.ps1`. Adapters may expose a more native invocation, but must preserve these semantics.
