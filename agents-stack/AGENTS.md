# AGENTS — Subagent Pipeline Configuration

This file configures a 4-stage subagent pipeline for AI-assisted software
development. Compatible with both **opencode** and **Claude Code**.

Copy this file to your project root, run the installer, and use the slash
commands below.

## Pipeline Overview

```bash
/planner → [/bdd-spec (optional)] → /tasks → /implement → /validate → /fix(optional) → /pr-ready
(plan)      (BDD scenarios)         (split)    (build)      (verify)     (repair)         (ship)
```

| Stage | Command | Subagent | What it does |
|-------|---------|----------|--------------|
| 1 | `/planner "description"` | @planner | Clarifies requirements interactively, produces `plan.md`. Reads `docs/context/` if available. |
| 2a | `/bdd-spec [--lang <code>]` | @bdd-specifier | *Optional.* Converts `plan.md` into Gherkin `.feature` files. Language auto-detected from plan or set via `--lang` (es, en, fr, de, pt, etc.). |
| 2b | `/tasks` | @task-splitter | Reads `plan.md` (and `.feature` files if present), decomposes into atomic tasks in `tasks.md` |
| 3 | `/implement <task-id>` | @implementer | Implements one task with clean architecture + unit tests + BDD step definitions (if features exist) |
| 4 | `/validate <task-id>` | @validator | Validates implementation against plan, runs unit + BDD tests, classifies issues (minor/major) |
| 5 | `/fix <task-id>` | @fixer | Applies surgical fixes for minor validation issues (major issues go back to `/planner`) |
| 6 | `/pr-ready` | @pr-creator | Runs all tests (unit + BDD), creates commit + PR with results report |

## Utility Commands

These commands run independently of the pipeline.

### `/context` — Project Context Documentation

Generates and maintains structured business/domain documentation about your
project. The `@planner` automatically reads this context if it exists, giving
it deep knowledge of your project before planning.

| Command | When | What it does |
|---------|------|--------------|
| `/context` | First run | Interactive Q&A for all 3 sections: overview, tech stack, roadmap |
| `/context` | Re-run | Update mode — shows current content, asks what changed |
| `/context --add <name>` | Anytime | Adds a new custom section (e.g., `--add domain-model`) |

**Examples:**

```bash
# First time — interactive Q&A for all sections
opencode run "/context"

# Update the roadmap after a milestone
opencode run "/context"

# Add a new custom section
opencode run "/context --add domain-model"
```

**How it integrates:**

```
/context (on demand)
     ↓
docs/context/  ──read by──→  @planner (if exists)
                                  ↓
                            /planner → /tasks → /implement → ...
```

### `/reference` — Repository Reference Importer

Imports an external repository reference into `docs/references/`. Fetches the
repo structure via GitHub/GitLab API and saves it as a single `.md` file with
the URL + filtered project tree — so AI agents can understand a dependency
without browsing the full repo.

```bash
# Import a GitHub repo reference
opencode run "/reference --repo https://github.com/user/repo"
```

### `/readme` — README Generator

Generates a professional `README.md` with auto-detected stack, prerequisites,
scripts, and test commands.

```bash
opencode run "/readme"
```

## Setup

### 1. Install subagent configurations

```bash
cd agents-stack && ./install.sh --target opencode      # macOS / Linux
# o
cd agents-stack && ./install.sh --target claude
# o
cd agents-stack && ./install.sh --target both
# or
cd agents-stack; .\install.ps1 -Target opencode       # Windows PowerShell
# o
cd agents-stack; .\install.ps1 -Target claude
# o
cd agents-stack; .\install.ps1 -Target both
```

This creates the necessary symlinks/copies in `.opencode/` and `.claude/`.

### 2. Configure models (opencode only)

Add the `agent` section to your `opencode.json`:

```jsonc
{
  "$schema": "https://opencode.ai/config.json",
  "agent": {
    "planner":       { "model": "anthropic/claude-sonnet-4-20250514", "mode": "subagent" },
    "task-splitter": { "model": "anthropic/claude-haiku-4-20250514",  "mode": "subagent" },
    "implementer":   { "model": "anthropic/claude-sonnet-4-20250514", "mode": "subagent" },
    "validator":     { "model": "anthropic/claude-haiku-4-20250514",  "mode": "subagent" },
    "fixer":         { "model": "anthropic/claude-haiku-4-20250514",  "mode": "subagent" },
    "pr-creator":    { "model": "anthropic/claude-haiku-4-20250514",  "mode": "subagent" }
  }
}
```

Claude Code users don't need this — models are injected by `agents-stack/install.sh`.

### 3. (Optional) Add language-specific skills

Copy `agents-stack/skills/_template/` to `agents-stack/skills/<language>/` and customize
`SKILL.md`. The implementer will auto-detect the project stack and load the
matching skill.

After adding a skill, re-run `agents-stack/install.sh`.

## Usage Examples

```bash
# OpenCode
opencode run "/planner Add a dark mode toggle to settings"
opencode run "/tasks"
opencode run "/implement 1"
opencode run "/validate 1"
opencode run "/fix 1"
opencode run "/pr-ready"

# Claude Code
claude -p "/planner Add user authentication with OAuth"
claude -p "/tasks"
claude -p "/implement 3"
claude -p "/validate 3"
claude -p "/fix 3"
claude -p "/pr-ready"
```

## Project Structure (after install)

```
<your-project>/
├── .opencode/
│   ├── agents/           → symlinks to agents-stack/agents/
│   ├── commands/         → symlinks to agents-stack/commands/
│   └── skills/           → symlinks to agents-stack/skills/
├── .claude/
│   ├── agents/           → copies with model injected
│   ├── commands/         → symlinks to agents-stack/commands/
│   └── skills/           → symlinks to agents-stack/skills/
├── AGENTS.md             ← this file
├── plan.md               ← generated by /planner
└── tasks.md              ← generated by /tasks
```
