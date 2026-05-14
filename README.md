# AGENTS — Subagent Pipeline

AI-assisted software development pipeline with 6 subagent stages.
Compatible with **opencode** and **Claude Code**.

```
/planner  →  /spec  →  /tasks  →  /implement-all  →  /pr-ready
(plan)       (spec)    (split)    (batch)            (ship)

Manual: /implement <id> → /validate <id> → /fix <id>
```

## Requirements

- [opencode](https://opencode.ai) or [Claude Code](https://docs.anthropic.com/en/docs/claude-code/overview)
- Python 3
- Git

## Installation

Copy `agents-stack/` to your project root and run the installer:

```bash
cp -r agents-stack/ /path/to/your/project/
cd /path/to/your/project/agents-stack
./install.sh --target both
# or:
#   ./install.sh --target opencode
#   ./install.sh --target claude
# Windows PowerShell:
#   .\install.ps1 -Target both
```

This creates:

| Directory | Contents |
|-----------|----------|
| `.opencode/agents/` | Symlinks to agent definitions |
| `.claude/agents/` | Copies with injected model config |
| `.opencode/commands/` | Slash commands (`/planner`, `/spec`, `/tasks`, `/implement`, `/validate`, `/fix`, `/implement-all`, `/pr-ready`, `/context`, `/readme`, `/reference`) |
| `.claude/commands/` | Slash commands (same set) |
| `.opencode/skills/` | Language/framework skill symlinks |
| `.claude/skills/` | Language/framework skill symlinks |
| `opencode.json` | Auto-generated model configuration |
| `AGENTS.md` | Pipeline documentation |

## Configure Models

Models are defined in `agents-stack/models.json` (single source of truth).
The installer reads this file and generates `opencode.json` automatically.

```json
{
  "opencode": {
    "planner":             "opencode-go/deepseek-v4-pro",
    "task-splitter":       "opencode-go/deepseek-v4-flash",
    "implementer":         "opencode-go/minimax-m2.7",
    "validator":           "opencode-go/deepseek-v4-flash",
    "fixer":               "opencode-go/deepseek-v4-flash",
    "pr-creator":          "opencode-go/deepseek-v4-flash",
    "spec-writer":         "opencode-go/deepseek-v4-flash",
    "batch-implementer":   "opencode-go/deepseek-v4-pro",
    "readme-generator":    "opencode-go/deepseek-v4-flash",
    "context-generator":   "opencode-go/deepseek-v4-flash",
    "reference-extractor": "opencode-go/deepseek-v4-flash",
    "manifest-generator":  "opencode-go/deepseek-v4-flash"
  },
  "claude": {
    "planner":              "sonnet",
    "task-splitter":        "haiku",
    "implementer":          "sonnet",
    "validator":            "haiku",
    "fixer":                "haiku",
    "pr-creator":           "haiku",
    "spec-writer":          "haiku",
    "batch-implementer":    "sonnet",
    "readme-generator":    "haiku",
    "context-generator":   "haiku",
    "reference-extractor": "haiku",
    "manifest-generator":  "haiku"
  }
}
```

To change a model, edit `agents-stack/models.json` and re-run the installer:

```bash
./agents-stack/install.sh
```

Claude Code users don't need additional configuration — models are injected
from `models.json` during installation.

## Usage

### Full Pipeline

```bash
# 1. Plan an idea interactively
opencode run "/planner Add OAuth authentication to the API"

# 2. Generate Gherkin specs from the plan
opencode run "/spec --lang es"

# 3. Decompose plan into atomic tasks
opencode run "/tasks"

# 4. Batch implement all tasks
opencode run "/implement-all"

# 5. Run tests, commit, and create PR
opencode run "/pr-ready"

# Manual mode (per task):
#   opencode run "/implement 1"
#   opencode run "/validate 1"
#   opencode run "/fix 1"
```

### Utility Commands

| Command | Description |
|---------|-------------|
| `/context` | Generate project context docs (read by planner automatically) |
| `/spec [--lang <code>]` | Convert plan into Gherkin `.feature` files. Language auto-detected or set via `--lang` (es, en, fr, de, pt, etc.) |
| `/readme` | Generate a professional README.md |
| `/reference --repo <url>` | Import external repository structure reference |

## Subagents

| Agent | Role | Model |
|-------|------|-------|
| **@planner** | Interactive requirements analyst — produces section files in `docs/pipeline/plan/` | DeepSeek V4 Pro / Sonnet |
| **@spec-writer** | Converts plan into Gherkin `.feature` files. Supports multilingual specs | DeepSeek V4 Flash / Haiku |
| **@task-splitter** | Decomposes plan into atomic tasks in `tasks.md` | DeepSeek V4 Flash / Haiku |
| **@implementer** | Detects project stack, loads matching skill, implements task with tests | MiniMax M2.7 / Sonnet |
| **@batch-implementer** | Orchestrates implement→validate→fix for all pending tasks | DeepSeek V4 Pro / Sonnet |
| **@validator** | Validates against plan, runs tests, classifies issues (minor/major) | DeepSeek V4 Flash / Haiku |
| **@fixer** | Surgical fixes for minor validation issues | DeepSeek V4 Flash / Haiku |
| **@pr-creator** | Runs tests, creates commit + PR with test results | DeepSeek V4 Flash / Haiku |
| **@context-generator** | Generates structured business/domain docs in `docs/context/` | DeepSeek V4 Flash / Haiku |
| **@readme-generator** | Generates professional README.md with auto-detected stack | DeepSeek V4 Flash / Haiku |
| **@reference-extractor** | Imports external repo structure via GitHub API | DeepSeek V4 Flash / Haiku |

## Add Language/Framework Skills

Skills provide language-specific conventions for the implementer.
They are loaded on demand when the matching stack is detected.

The naming convention is:

| Element | Convention | Example |
|---------|-----------|---------|
| Frontmatter `name` | `<lang>-patterns` | `go-patterns` |
| Directory name | `<lang>` | `go/` |
| File name | `SKILL.md` | `skills/go/SKILL.md` |

```bash
# Copy the template
cp -r agents-stack/skills/_template agents-stack/skills/go

# Edit the skill
vim agents-stack/skills/go/SKILL.md

# Re-run the installer
./agents-stack/install.sh
```

Framework skills load on top of language base skills:

```
python-patterns          ← base language
  └── django-patterns    ← framework layer
  └── fastapi-patterns   ← framework layer
```

Run tests after changes:

```bash
./agents-stack/tests/run.sh
```

## Project Structure

```
your-project/
├── .opencode/
│   ├── agents/           → symlinks to agents-stack/agents/
│   ├── commands/         → symlinks to agents-stack/commands/
│   └── skills/           → symlinks to installed skills
├── .claude/
│   ├── agents/           → copies with model injected
│   ├── commands/         → symlinks
│   └── skills/           → symlinks
├── agents-stack/
│   ├── models.json       ← single source of truth for models
│   ├── agents/           → subagent definitions
│   ├── commands/         → slash command definitions
│   ├── skills/           → python/, typescript/, react/, django/, fastapi/, textual/, _template/
│   ├── tests/            → integration tests
│   ├── install.sh
│   ├── install.ps1
│   ├── AGENTS.md
│   └── README.md
├── opencode.json         ← auto-generated by installer
├── AGENTS.md             ← pipeline documentation
├── docs/pipeline/plan/   ← generated by /planner (section files)
├── docs/pipeline/tasks.md ← generated by /tasks
└── docs/pipeline/features/ ← generated by /spec
```

## License

MIT
