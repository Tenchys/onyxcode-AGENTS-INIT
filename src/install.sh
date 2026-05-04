#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Subagent Stack Installer
# Installs agent configs for both opencode and Claude Code
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SRC_DIR="$SCRIPT_DIR"
MODELS_FILE="$SRC_DIR/models.json"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err()  { echo -e "${RED}[✗]${NC} $1"; }
info() { echo -e "${CYAN}[→]${NC} $1"; }

# ---------------------------------------------------------------------------
# Parse models.json using python3
# ---------------------------------------------------------------------------
get_model() {
  local tool="$1" agent="$2"
  python3 -c "
import json, sys
with open('$MODELS_FILE') as f:
    data = json.load(f)
print(data.get('$tool', {}).get('$agent', ''))
"
}

# ---------------------------------------------------------------------------
# Create directory and clean existing symlinks/copies
# ---------------------------------------------------------------------------
prepare_dir() {
  local dir="$1"
  mkdir -p "$dir"
}

# ---------------------------------------------------------------------------
# Install agent for opencode (symlink)
# ---------------------------------------------------------------------------
install_opencode_agent() {
  local agent_name="$1"
  local src="$SRC_DIR/agents/${agent_name}.md"
  local dst="$PROJECT_ROOT/.opencode/agents/${agent_name}.md"

  [ -f "$src" ] || { err "Source not found: $src"; return 1; }

  prepare_dir "$(dirname "$dst")"
  ln -sf "$src" "$dst"
  log "opencode agent: ${agent_name} → .opencode/agents/${agent_name}.md"
}

# ---------------------------------------------------------------------------
# Install agent for Claude Code (copy with model injected)
# ---------------------------------------------------------------------------
install_claude_agent() {
  local agent_name="$1"
  local src="$SRC_DIR/agents/${agent_name}.md"
  local dst="$PROJECT_ROOT/.claude/agents/${agent_name}.md"
  local model
  model=$(get_model "claude" "$agent_name")

  [ -f "$src" ] || { err "Source not found: $src"; return 1; }

  prepare_dir "$(dirname "$dst")"

  if [ -n "$model" ]; then
    # Inject model line after 'description:' line in frontmatter
    awk -v model="$model" '
      BEGIN { injected = 0 }
      /^description:/ && !injected {
        print
        print "model: " model
        injected = 1
        next
      }
      { print }
    ' "$src" > "$dst"
    log "claude agent:   ${agent_name} → .claude/agents/${agent_name}.md  (model: ${model})"
  else
    cp "$src" "$dst"
    log "claude agent:   ${agent_name} → .claude/agents/${agent_name}.md  (model: inherit)"
  fi
}

# ---------------------------------------------------------------------------
# Install commands (symlink to both targets)
# ---------------------------------------------------------------------------
install_commands() {
  local cmd_name="$1"
  local src="$SRC_DIR/commands/${cmd_name}.md"
  local dst_opencode="$PROJECT_ROOT/.opencode/commands/${cmd_name}.md"
  local dst_claude="$PROJECT_ROOT/.claude/commands/${cmd_name}.md"

  [ -f "$src" ] || { err "Source not found: $src"; return 1; }

  prepare_dir "$(dirname "$dst_opencode")"
  prepare_dir "$(dirname "$dst_claude")"

  ln -sf "$src" "$dst_opencode"
  ln -sf "$src" "$dst_claude"
  log "command:        ${cmd_name} → .opencode/commands/ & .claude/commands/"
}

# ---------------------------------------------------------------------------
# Install skills (symlink to both targets)
# ---------------------------------------------------------------------------
install_skills() {
  local skill_name="$1"
  local src="$SRC_DIR/skills/${skill_name}/SKILL.md"
  local dst_opencode="$PROJECT_ROOT/.opencode/skills/${skill_name}/SKILL.md"
  local dst_claude="$PROJECT_ROOT/.claude/skills/${skill_name}/SKILL.md"

  [ -f "$src" ] || { err "Source not found: $src"; return 1; }

  prepare_dir "$(dirname "$dst_opencode")"
  prepare_dir "$(dirname "$dst_claude")"

  ln -sf "$src" "$dst_opencode"
  ln -sf "$src" "$dst_claude"
  log "skill:          ${skill_name} → .opencode/skills/ & .claude/skills/"
}

# ---------------------------------------------------------------------------
# Generate opencode.json snippet
# ---------------------------------------------------------------------------
generate_opencode_snippet() {
  local snippet_file="$PROJECT_ROOT/.opencode/agent-models.generated.json"

  python3 -c "
import json, sys

with open('$MODELS_FILE') as f:
    data = json.load(f)

agents = data.get('opencode', {})
config = {
    '\$schema': 'https://opencode.ai/config.json',
    'agent': {}
}

for name, model in agents.items():
    config['agent'][name] = {
        'model': model,
        'mode': 'subagent'
    }

with open('$snippet_file', 'w') as f:
    json.dump(config, f, indent=2)
" 2>/dev/null || {
    warn "Could not generate opencode.json snippet. Merge manually:"
    echo ""
    for agent in planner task-splitter implementer pr-creator; do
      local model
      model=$(get_model "opencode" "$agent")
      echo "  \"$agent\": { \"model\": \"$model\", \"mode\": \"subagent\" }"
    done
    return
  }

  log "Generated: .opencode/agent-models.generated.json"
  info "Merge the 'agent' section into your opencode.json manually."
}

# ============================================================================
# Main
# ============================================================================

echo ""
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  Subagent Stack Installer${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

[ -f "$MODELS_FILE" ] || { err "models.json not found at $MODELS_FILE"; exit 1; }

# --- Agents ---
info "Installing agents..."
for agent in planner task-splitter implementer pr-creator; do
  install_opencode_agent "$agent"
  install_claude_agent "$agent"
done

# --- Commands ---
echo ""
info "Installing slash commands..."
for cmd in planner tasks implement pr-ready; do
  install_commands "$cmd"
done

# --- Skills ---
echo ""
info "Installing skills..."
for skill_dir in "$SRC_DIR"/skills/*/; do
  skill_name=$(basename "$skill_dir")
  [ "$skill_name" = "_template" ] && continue
  [ -f "$skill_dir/SKILL.md" ] && install_skills "$skill_name"
done

# Install template skill for reference
if [ -f "$SRC_DIR/skills/_template/SKILL.md" ]; then
  install_skills "_template"
fi

# --- opencode.json snippet ---
echo ""
generate_opencode_snippet

# --- Final instructions ---
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Installation complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Next steps:"
echo ""
echo "  1. Merge .opencode/agent-models.generated.json into your opencode.json"
echo "     or add the 'agent' section directly:"
echo ""
echo '     "agent": {'
echo '       "planner":       { "model": "anthropic/claude-sonnet-4-20250514", "mode": "subagent" },'
echo '       "task-splitter": { "model": "anthropic/claude-haiku-4-20250514",  "mode": "subagent" },'
echo '       "implementer":   { "model": "anthropic/claude-sonnet-4-20250514", "mode": "subagent" },'
echo '       "pr-creator":    { "model": "anthropic/claude-haiku-4-20250514",  "mode": "subagent" }'
echo '     }'
echo ""
echo "  2. Copy AGENTS.md to your target project root if not already there."
echo ""
echo "  3. Available slash commands:"
echo "     /planner \"description\"   — Interactive requirement planning"
echo "     /tasks                    — Decompose plan into atomic tasks"
echo "     /implement <task-id>      — Implement a task (clean architecture)"
echo "     /pr-ready                 — Test, commit, and create PR"
echo ""
