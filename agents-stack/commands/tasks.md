---
description: Decompose plan/ into atomic, ordered, testable tasks. Produces tasks.md
---

There is a subagent available called @task-splitter that specializes in
breaking down plans into atomic tasks with test specifications.

Invoke the task-splitter subagent now. It will read section files from
`docs/pipeline/plan/` and produce a `docs/pipeline/tasks.md` file with
ordered, dependency-aware, individually testable tasks.

$ARGUMENTS
