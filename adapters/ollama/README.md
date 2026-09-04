# Ollama adapter

The Ollama adapter is included in every harness installation. The Ollama runtime and model weights remain optional external dependencies. The versioned files define two aliases over the official `qwen3.5:9b` library model:

```powershell
ollama create qwen-local -f .\adapters\ollama\Modelfile.qwen-local
ollama create qwen-local-deep -f .\adapters\ollama\Modelfile.qwen-local-deep
```

- `qwen-local`: 8K context, intended for the validated fast profile and full GPU placement on the user's RTX 4060.
- `qwen-local-deep`: 16K context, intended for deeper work with partial CPU/GPU placement when required.

Ollama chooses actual layer placement from current VRAM and runtime conditions. The portable Modelfiles therefore do not hardcode a machine-specific GPU layer count. Confirm the observed placement with `ollama ps`: `100% GPU` is the fast-profile target, while a mixed CPU/GPU percentage is expected for the deep profile on the validated machine.

The installer materializes these Modelfiles under `~/.agentic-harness/adapters/ollama/` but does not run `ollama create`, because that may download large weights and depends on machine-local capacity. Model weights and local blob paths are deliberately excluded. Qwen is selected directly for private, offline, batch, simple-transform, or quota-saving work; it is not a mandatory pre-cloud hop.

References checked on 2026-09-04:

- https://ollama.com/library/qwen3.5
- https://docs.ollama.com/modelfile
- https://docs.ollama.com/faq
