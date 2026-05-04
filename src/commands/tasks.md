---
description: Decompose plan.md into atomic, ordered, testable tasks. Produces tasks.md
---

There is a subagent available called @task-splitter that specializes in
breaking down plans into atomic tasks with test specifications.

Invoke the task-splitter subagent now. It will read `plan.md` and produce a
`tasks.md` file with ordered, dependency-aware, individually testable tasks.

$ARGUMENTS
