# Memory domain boundaries

The existing `global/memory-bank/` remains the shared, cross-profile memory bank and keeps its index-first structure unchanged.

| Domain | Durable memory owner | Versioning rule |
|---|---|---|
| Shared/global | `global/memory-bank/` | only cross-profile facts, preferences, decisions, and confirmed lessons |
| Software | each software repository | architecture, commands, active specs, and project decisions stay with the project |
| Assistant | a future explicitly configured assistant memory source | stable non-sensitive preferences and routines only |
| Knowledge | the Obsidian vault | personal knowledge remains in the vault, not copied into this repository |
| Home | Home Assistant plus bounded documentation | safe conceptual configuration only; never credentials, access data, or household secrets |

Conversation history remains working memory in every runtime. Discovery of a memory source does not load it automatically.
