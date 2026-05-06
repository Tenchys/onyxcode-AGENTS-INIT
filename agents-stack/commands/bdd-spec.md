---
description: Generate Gherkin .feature files from plan.md with optional --lang <code> flag
---

There is a subagent available called @bdd-specifier that specializes in
converting requirement plans into executable Gherkin feature files.

Invoke the bdd-specifier subagent now. It will:
1. Read `plan.md` and `features/.bddconfig` (if exists)
2. Auto-detect or use the configured language (default: `en`)
3. Group functional requirements into feature files
4. Write `features/<domain>/<feature>.feature` with Given/When/Then scenarios
5. Create `features/.bddconfig` if not present

Use `--lang <code>` to override the language (e.g., `--lang es`, `--lang fr`).

$ARGUMENTS
