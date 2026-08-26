# Reusable lessons

## 2026-08-26 — Model override requires a limited or empty fork

- Context: Spawning a subagent with an explicit model tier different from the primary agent.
- Observed failure: A spawn requested `gpt-5.6-luna` together with `fork_turns: "all"`; the full-history fork inherited the primary `gpt-5.6-sol` model, so the requested override did not take effect.
- Durable lesson: When specifying `model` or `reasoning_effort`, never use `fork_turns: "all"`. Use `fork_turns: "none"` or a positive limited turn count and include the necessary context explicitly. Report the model actually used, not merely the intended routing tier.
- Evidence or provenance: Verified by the user's process display and acknowledged during the INT410 firmware task on 2026-08-26.
- Supersedes: none

Use this format only after a pattern is verified:

## YYYY-MM-DD — Short title

- Context:
- Observed failure:
- Durable lesson:
- Evidence or provenance:
- Supersedes: none
