# AGENTS — Subagent Pipeline

AI-assisted software development pipeline with 6 subagent stages.
Compatible with **opencode** and **Claude Code**.

```
/planner  →  [/bdd-spec (optional)]  →  /tasks  →  /implement  →  /validate  →  /fix(optional)  →  /pr-ready
(plan)       (BDD scenarios)            (split)     (build)         (verify)       (repair)           (ship)
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
#   ./install.sh --target claude --bdd-lang es    # BDD scenarios in Spanish
#   ./install.sh --bdd-lang fr                    # BDD scenarios in French
# Windows PowerShell:
#   .\install.ps1 -Target both
```

This creates:

| Directory | Contents |
|-----------|----------|
| `.opencode/agents/` | Symlinks to agent definitions |
| `.claude/agents/` | Copies with injected model config |
| `.opencode/commands/` | Slash commands (`/planner`, `/bdd-spec`, `/tasks`, `/implement`, `/validate`, `/fix`, `/pr-ready`, `/context`, `/readme`, `/reference`) |
| `.claude/commands/` | Slash commands (same set) |
| `.opencode/skills/` | Language/framework skill symlinks (includes `bdd-patterns` for BDD) |
| `.claude/skills/` | Language/framework skill symlinks (includes `bdd-patterns` for BDD) |
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
    "bdd-specifier":       "opencode-go/deepseek-v4-flash",
    "readme-generator":    "opencode-go/deepseek-v4-flash",
    "context-generator":   "opencode-go/deepseek-v4-flash",
    "reference-extractor": "opencode-go/deepseek-v4-flash"
  },
  "claude": {
    "planner":       "sonnet",
    "task-splitter": "haiku",
    "implementer":   "sonnet",
    "validator":     "haiku",
    "fixer":         "haiku",
    "pr-creator":    "haiku",
    "bdd-specifier": "haiku",
    "readme-generator":    "haiku",
    "context-generator":   "haiku",
    "reference-extractor": "haiku"
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

# 2. (Optional) Generate BDD scenarios from the plan
opencode run "/bdd-spec --lang es"

# 3. Decompose plan into atomic tasks
opencode run "/tasks"

# 4. Implement tasks one by one
opencode run "/implement 1"
opencode run "/implement 2"

# 5. Validate an implementation against the plan
opencode run "/validate 1"

# 6. (Optional) Fix minor validation issues
opencode run "/fix 1"

# 7. Run tests, commit, and create PR
opencode run "/pr-ready"
```

### Utility Commands

| Command | Description |
|---------|-------------|
| `/context` | Generate project context docs (read by planner automatically) |
| `/bdd-spec [--lang <code>]` | Convert plan.md into Gherkin `.feature` files (BDD). Language auto-detected from plan or set via `--lang` (es, en, fr, de, pt, etc.) |
| `/readme` | Generate a professional README.md |
| `/reference --repo <url>` | Import external repository structure reference |

## Subagents

| Agent | Role | Model |
|-------|------|-------|
| **@planner** | Interactive requirements analyst — asks clarifying questions, produces `plan.md` | DeepSeek V4 Pro / Sonnet |
| **@task-splitter** | Decomposes plan into atomic, ordered, testable tasks in `tasks.md` | DeepSeek V4 Flash / Haiku |
| **@implementer** | Detects project stack, loads matching skill (incl. `bdd-patterns`), implements with clean architecture + tests + BDD step definitions | MiniMax M2.7 / Sonnet |
| **@bdd-specifier** | Converts plan.md into Gherkin `.feature` files. Supports multilingual BDD (es, en, fr, de, pt, etc.) | DeepSeek V4 Flash / Haiku |
| **@validator** | Read-only quality check — validates against plan, runs unit + BDD tests, classifies issues (minor/major) | DeepSeek V4 Flash / Haiku |
| **@fixer** | Surgical fixes for minor validation issues only (major issues go back to planner) | DeepSeek V4 Flash / Haiku |
| **@pr-creator** | Runs all tests (unit + BDD), creates conventional commit, verifies conflicts, creates PR | DeepSeek V4 Flash / Haiku |
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
  └── bdd-patterns       ← BDD conventions (auto-loaded when features/ detected)
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
│   ├── agents/           → subagent definitions (10 agents)
│   ├── commands/         → slash command definitions (11 commands)
│   ├── skills/           → python/, typescript/, react/, django/, fastapi/, textual/, bdd/, _template/
│   ├── tests/            → integration tests
│   ├── install.sh
│   ├── install.ps1
│   ├── AGENTS.md
│   └── README.md
├── opencode.json         ← auto-generated by installer
├── AGENTS.md             ← pipeline documentation
├── plan.md               ← generated by /planner
└── tasks.md              ← generated by /tasks
```

## License

MIT
