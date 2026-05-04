---
description: Run tests, create a commit, and open a pull request with results summary
---

There is a subagent available called @pr-creator that specializes in validating
changes, running tests, and creating pull requests.

Invoke the pr-creator subagent now. It will:
1. Run the full test suite
2. Summarize the changes
3. Create a commit with a conventional commit message
4. Check for conflicts with main
5. Create a pull request with test results and conflict status

$ARGUMENTS
