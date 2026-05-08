---
description: Extend an existing plan with a new requirement — appends to plan.md without losing prior planning
---

There is a subagent available called @planner that now supports an **append mode**.
When `plan.md` already exists, the planner reads the existing plan and appends a
new `## Extension N:` section for the new requirement without modifying the
original plan.

Invoke the @planner subagent with the following instructions:

1. Read the argument: $ARGUMENTS
2. Read `docs/pipeline/plan.md` (it should already exist — if not, tell
   the user to run `/planner` first).
3. Read `docs/pipeline/tasks.md` and `docs/pipeline/state.json` to
   understand existing task statuses.
4. Enter append mode: clarify the new requirement with the user using the same
   thorough questioning workflow, then append a new `## Extension N:` section to
   `docs/pipeline/plan.md`.
5. When done, tell the user to run `/spec` to generate feature specs for the
   extension, then `/tasks` to merge the new extension into `tasks.md`.
