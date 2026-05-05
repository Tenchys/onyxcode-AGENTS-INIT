#!/usr/bin/env bash
# Integration test suite for the AGENTS subagent pipeline
# Usage: ./agents-stack/tests/run.sh
#   or    bash agents-stack/tests/run.sh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$(cd "$ROOT/.." && pwd)"
PASS=0
FAIL=0
ERRORS=""

heading() {
  echo ""
  echo "========================================"
  echo "  $1"
  echo "========================================"
}

ok() {
  PASS=$((PASS + 1))
  echo "  [✓] $1"
}

fail() {
  FAIL=$((FAIL + 1))
  echo "  [✗] $1"
  ERRORS="${ERRORS}  FAIL: $1${2:+  ($2)}"$'\n'
}

# ------------------------------------------------------------------
# Expected data
# ------------------------------------------------------------------

AGENTS=(
  planner
  task-splitter
  implementer
  validator
  fixer
  pr-creator
  readme-generator
  context-generator
  reference-extractor
)

COMMANDS=(
  planner
  tasks
  implement
  validate
  fix
  pr-ready
  plan-extend
  readme
  context
  reference
)

SKILLS=(
  python
  typescript
  react
  django
  fastapi
  textual
)

AGENT_NAMES=(
  planner
  task-splitter
  implementer
  validator
  fixer
  pr-creator
  readme-generator
  context-generator
  reference-extractor
)

# ------------------------------------------------------------------
# 1. Agent files exist
# ------------------------------------------------------------------
heading "1. Agent definitions"

for agent in "${AGENTS[@]}"; do
  file="$ROOT/agents/${agent}.md"
  if [ -f "$file" ]; then
    ok "agent file exists: ${agent}.md"
  else
    fail "agent file missing: ${agent}.md"
  fi
done

# Verify no stale agent files (files without a corresponding entry)
for file in "$ROOT"/agents/*.md; do
  name=$(basename "$file" .md)
  found=0
  for a in "${AGENTS[@]}"; do
    [ "$a" = "$name" ] && found=1 && break
  done
  if [ "$found" -eq 0 ]; then
    fail "unexpected agent file: ${name}.md"
  fi
done

# ------------------------------------------------------------------
# 2. Agent frontmatter validity
# ------------------------------------------------------------------
heading "2. Agent frontmatter"

for agent in "${AGENTS[@]}"; do
  file="$ROOT/agents/${agent}.md"
  [ -f "$file" ] || continue

  if grep -q '^description:' "$file"; then
    ok "${agent}.md has description"
  else
    fail "${agent}.md missing description"
  fi

  if grep -q '^mode: subagent' "$file"; then
    ok "${agent}.md mode: subagent"
  else
    fail "${agent}.md missing mode: subagent"
  fi

  if grep -q '^permission:' "$file"; then
    ok "${agent}.md has permissions"
  else
    fail "${agent}.md missing permissions"
  fi
done

# ------------------------------------------------------------------
# 3. Command files exist
# ------------------------------------------------------------------
heading "3. Slash commands"

for cmd in "${COMMANDS[@]}"; do
  file="$ROOT/commands/${cmd}.md"
  if [ -f "$file" ]; then
    ok "command file exists: ${cmd}.md"
  else
    fail "command file missing: ${cmd}.md"
  fi
done

# Verify no stale command files
for file in "$ROOT"/commands/*.md; do
  name=$(basename "$file" .md)
  found=0
  for c in "${COMMANDS[@]}"; do
    [ "$c" = "$name" ] && found=1 && break
  done
  if [ "$found" -eq 0 ]; then
    fail "unexpected command file: ${name}.md"
  fi
done

# ------------------------------------------------------------------
# 4. Commands reference valid agents
# ------------------------------------------------------------------
heading "4. Command-to-agent references"

for cmd in "${COMMANDS[@]}"; do
  file="$ROOT/commands/${cmd}.md"
  [ -f "$file" ] || continue

  refs=$(grep -oE '@[a-zA-Z0-9_-]+' "$file" | sed 's/^@//' || true)
  if [ -z "$refs" ]; then
    fail "${cmd}.md references no subagents"
    continue
  fi

  while IFS= read -r ref; do
    found=0
    for a in "${AGENTS[@]}"; do
      if [ "$a" = "$ref" ]; then
        found=1
        break
      fi
    done
    if [ "$found" -eq 1 ]; then
      ok "${cmd}.md → @${ref}"
    else
      fail "${cmd}.md references unknown agent: @${ref}"
    fi
  done <<< "$refs"
done

# ------------------------------------------------------------------
# 5. Skill files exist
# ------------------------------------------------------------------
heading "5. Skills"

for skill in "${SKILLS[@]}"; do
  file="$ROOT/skills/${skill}/SKILL.md"
  if [ -f "$file" ]; then
    ok "skill exists: ${skill}/SKILL.md"
  else
    fail "skill missing: ${skill}/SKILL.md"
  fi
done

# Template must exist
if [ -f "$ROOT/skills/_template/SKILL.md" ]; then
  ok "_template/SKILL.md exists"
else
  fail "_template/SKILL.md missing"
fi

# Verify skill frontmatter has required fields
for skill in "${SKILLS[@]}"; do
  file="$ROOT/skills/${skill}/SKILL.md"
  [ -f "$file" ] || continue

  if grep -q '^name:' "$file"; then
    ok "${skill} has name"
  else
    fail "${skill} missing name field"
  fi

  if grep -q '^description:' "$file"; then
    ok "${skill} has description"
  else
    fail "${skill} missing description field"
  fi
done

# ------------------------------------------------------------------
# 6. models.json consistency
# ------------------------------------------------------------------
heading "6. models.json"

if [ -f "$ROOT/models.json" ]; then
  ok "models.json exists"
else
  fail "models.json missing"
fi

# Check opencode section has all agents
for agent in "${AGENTS[@]}"; do
  if grep -q "\"$agent\"" "$ROOT/models.json"; then
    ok "models.json → opencode.${agent}"
  else
    fail "models.json missing opencode.${agent}"
  fi
done

# Check claude section has all agents
for agent in "${AGENTS[@]}"; do
  if grep -q '"claude"' "$ROOT/models.json"; then
    # already confirmed file exists, check agent
    true
  fi
done

# Verify models.json entries are valid (use python3 for proper JSON parsing)
python3 -c "
import json, sys
with open('$ROOT/models.json') as f:
    data = json.load(f)
expected = {$(for a in "${AGENTS[@]}"; do echo -n "'$a', "; done)}
for section in ('opencode', 'claude'):
    agents = data.get(section, {})
    for name in agents:
        if name not in expected:
            print(f'models.json has unknown agent in {section}: {name}')
            sys.exit(1)
    for name in expected:
        if name not in agents:
            print(f'models.json missing {name} in {section}')
            sys.exit(1)
print('ok')
" && ok "models.json entries match agent definitions" || fail "models.json has mismatched entries"

# ------------------------------------------------------------------
# 7. Install script consistency (install.sh)
# ------------------------------------------------------------------
heading "7. install.sh agent/command coverage"

if [ -f "$ROOT/install.sh" ]; then
  ok "install.sh exists"

  for agent in "${AGENTS[@]}"; do
    if grep -q "$agent" "$ROOT/install.sh"; then
      ok "install.sh references agent: ${agent}"
    else
      fail "install.sh missing agent: ${agent}"
    fi
  done

  for cmd in "${COMMANDS[@]}"; do
    if grep -q "$cmd" "$ROOT/install.sh"; then
      ok "install.sh references command: ${cmd}"
    else
      fail "install.sh missing command: ${cmd}"
    fi
  done
else
  fail "install.sh missing"
fi

# ------------------------------------------------------------------
# 8. Install script consistency (install.ps1)
# ------------------------------------------------------------------
heading "8. install.ps1 agent/command coverage"

if [ -f "$ROOT/install.ps1" ]; then
  ok "install.ps1 exists"

  for agent in "${AGENTS[@]}"; do
    if grep -q "$agent" "$ROOT/install.ps1"; then
      ok "install.ps1 references agent: ${agent}"
    else
      fail "install.ps1 missing agent: ${agent}"
    fi
  done

  for cmd in "${COMMANDS[@]}"; do
    if grep -q "$cmd" "$ROOT/install.ps1"; then
      ok "install.ps1 references command: ${cmd}"
    else
      fail "install.ps1 missing command: ${cmd}"
    fi
  done
else
  fail "install.ps1 missing"
fi

# ------------------------------------------------------------------
# 9. AGENTS.md at project root
# ------------------------------------------------------------------
heading "9. Project root files"

if [ -f "$PROJECT/AGENTS.md" ]; then
  ok "AGENTS.md exists at project root"
else
  fail "AGENTS.md missing from project root"
fi

# ------------------------------------------------------------------
# Summary
# ------------------------------------------------------------------
heading "RESULTS"
echo "  Passed: $PASS"
echo "  Failed: $FAIL"
echo ""

if [ "$FAIL" -eq 0 ]; then
  echo "  All tests passed!"
else
  echo "  Failures:"
  echo -n "$ERRORS"
fi

echo ""
exit "$FAIL"
