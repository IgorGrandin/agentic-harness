# Portable global Codex configuration V1

Status: compatibility baseline; architecture superseded by `agentic-platform-v2.md`

## Problem

The user's project memory banks travel with their repositories, but the global SDD agreements, durable cross-project memory, reusable subagent roles, and custom skills currently live only on one computer.

## Desired outcome

Maintain a private, reviewable Git repository containing only portable Codex configuration. A new Windows computer can install the same global behavior without copying credentials, sessions, caches, logs, or machine identity.

## Scope

- Global `AGENTS.md`.
- Markdown memory bank.
- Reusable subagent role definitions.
- User-authored skills.
- Sanitized `[agents]` routing configuration.
- PowerShell install, export, and verification scripts.
- Private GitHub publication and documented update workflow.

## Out of scope

- Authentication and connector credentials.
- Chat, session, goal, application, browser, or plugin cache state.
- Automatic background synchronization.
- Project-specific memory or instructions.
- Formal workflow graph execution.

## Acceptance criteria

- **AC-01:** The repository contains the current global Markdown memory, instructions, roles, and user-authored skills using an explicit allowlist.
- **AC-02:** Installation backs up every managed destination before replacement and never replaces the whole `.codex` or `.agents` directory.
- **AC-03:** Installation merges only the portable keys in the `[agents]` section of `config.toml`, preserving all other sections and keys.
- **AC-04:** Export copies only allowlisted assets from a computer into the repository.
- **AC-05:** Verification rejects forbidden local-state paths, likely credential values, invalid JSON, and PowerShell syntax errors.
- **AC-06:** Documentation explains first installation, routine pull/export/push usage, recovery, and exclusions.
- **AC-07:** The repository is initialized locally and published to a private GitHub repository when authenticated GitHub creation is available.
- **AC-08:** Genuine microtasks use a direct one-pass fast lane with no spec, plan, subagent, routing log, or redundant verification.
- **AC-09:** Delegation occurs only when expected token, context, verification, or latency gains exceed spawn and synthesis overhead; Luna Max remains a narrow reasoning escalation.
- **AC-10:** Low-risk work uses the smallest decisive check, does not repeat passing checks without relevant changes, and does not add separate verification or review agents by default.
- **AC-11:** Features and architecture decisions prefer existing extension points and the smallest sufficient change surface; speculative infrastructure requires an explicit present requirement.
- **AC-12:** Codex spawns explicitly declare model and reasoning effort, use empty or limited context when changing model tiers, and reserve Sol subagents for a recorded consequential signal.

## Verification strategy

1. Parse every PowerShell script with the PowerShell AST parser.
2. Run repository verification.
3. Install into isolated temporary Codex and Agents homes.
4. Assert installed files match their repository sources.
5. Assert unrelated `config.toml` sections and `[agents]` keys survive the merge.
6. Exercise `-WhatIf` without mutating the temporary destination.

## Decisions

- Copy mode is the V1 default because it works without symbolic-link privileges and makes each computer usable offline.
- Git is the synchronization mechanism; updates are explicit rather than background-driven.
- The repository stores a sanitized routing fragment instead of the full local `config.toml`.
- Custom skills are synchronized from an explicit manifest rather than copying system or plugin caches.
- Delegation and parallelism are independent, opt-in decisions justified by expected net gain.
- Luna Medium is the configured bounded-worker default. Luna Max is explicit escalation for narrow reasoning-heavy work; Terra High and Sol High handle broader or consequential complexity.
- Reasoning effort is proportional rather than fixed: Sol Low for microtasks, Sol Medium for clear bounded intake and synthesis, and Sol High for consequential work.
- Existing extension points and the smallest sufficient change surface take precedence over speculative abstractions or future-proofing.
- Codex routing does not rely on the default subagent model to override a full-history fork; model-changing spawns are explicit and receive bounded context.
