---
description: Validate an implemented task against its plan, run tests, and classify issues
---

There is a subagent available called @validator that specializes in
validating implemented tasks against their plan specifications.

Invoke the @validator subagent now. It will:
1. Read the task from `tasks.md`
2. Check files, tests, and test results
3. Cross-reference with `plan.md`
4. Classify issues as minor (fixable by @fixer) or major (needs /planner)
5. Produce a structured validation report with next steps

$ARGUMENTS
