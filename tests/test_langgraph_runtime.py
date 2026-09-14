"""Discovery-compatible entrypoint for the deterministic LangGraph tests."""
from __future__ import annotations

import importlib.util
from pathlib import Path

source = Path(__file__).with_name("test-langgraph-runtime.py")
spec = importlib.util.spec_from_file_location("agentic_harness_langgraph_tests", source)
if spec is None or spec.loader is None:  # pragma: no cover - import-system guard
    raise RuntimeError(f"Unable to load {source}")
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
LangGraphRuntimeTests = module.LangGraphRuntimeTests
