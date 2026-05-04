# ============================================================================
# Subagent Stack Installer (Windows PowerShell)
# Installs agent configs for both opencode and Claude Code
# ============================================================================

param()

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$SrcDir = $ScriptDir
$ModelsFile = Join-Path $SrcDir "models.json"

if (-not (Test-Path $ModelsFile)) {
    Write-Host "[✗] models.json not found at $ModelsFile" -ForegroundColor Red
    exit 1
}

$Models = Get-Content $ModelsFile | ConvertFrom-Json

function Get-Model($Tool, $Agent) {
    $m = $Models.$Tool.$Agent
    if ($m) { return $m } else { return "" }
}

function Prepare-Dir($Dir) {
    if (-not (Test-Path $Dir)) {
        New-Item -ItemType Directory -Path $Dir -Force | Out-Null
    }
}

function Install-OpenCodeAgent($AgentName) {
    $src = Join-Path $SrcDir "agents" "$AgentName.md"
    $dst = Join-Path $ProjectRoot ".opencode" "agents" "$AgentName.md"

    if (-not (Test-Path $src)) {
        Write-Host "[✗] Source not found: $src" -ForegroundColor Red
        return
    }

    Prepare-Dir (Split-Path $dst -Parent)
    New-Item -ItemType SymbolicLink -Path $dst -Target $src -Force | Out-Null
    Write-Host "[✓] opencode agent: $AgentName → .opencode/agents/$AgentName.md" -ForegroundColor Green
}

function Install-ClaudeAgent($AgentName) {
    $src = Join-Path $SrcDir "agents" "$AgentName.md"
    $dst = Join-Path $ProjectRoot ".claude" "agents" "$AgentName.md"
    $model = Get-Model "claude" $AgentName

    if (-not (Test-Path $src)) {
        Write-Host "[✗] Source not found: $src" -ForegroundColor Red
        return
    }

    Prepare-Dir (Split-Path $dst -Parent)

    $content = Get-Content $src -Raw
    if ($model) {
        $content = $content -replace "(?m)^(description:.*)$", "`$1`nmodel: $model"
    }
    Set-Content -Path $dst -Value $content -NoNewline

    if ($model) {
        Write-Host "[✓] claude agent:   $AgentName → .claude/agents/$AgentName.md  (model: $model)" -ForegroundColor Green
    } else {
        Write-Host "[✓] claude agent:   $AgentName → .claude/agents/$AgentName.md  (model: inherit)" -ForegroundColor Green
    }
}

function Install-Commands($CmdName) {
    $src = Join-Path $SrcDir "commands" "$CmdName.md"
    $dstOpenCode = Join-Path $ProjectRoot ".opencode" "commands" "$CmdName.md"
    $dstClaude = Join-Path $ProjectRoot ".claude" "commands" "$CmdName.md"

    if (-not (Test-Path $src)) {
        Write-Host "[✗] Source not found: $src" -ForegroundColor Red
        return
    }

    Prepare-Dir (Split-Path $dstOpenCode -Parent)
    Prepare-Dir (Split-Path $dstClaude -Parent)

    New-Item -ItemType SymbolicLink -Path $dstOpenCode -Target $src -Force | Out-Null
    New-Item -ItemType SymbolicLink -Path $dstClaude -Target $src -Force | Out-Null
    Write-Host "[✓] command:        $CmdName → .opencode/commands/ & .claude/commands/" -ForegroundColor Green
}

function Install-Skills($SkillName) {
    $src = Join-Path $SrcDir "skills" $SkillName "SKILL.md"
    $dstOpenCode = Join-Path $ProjectRoot ".opencode" "skills" $SkillName "SKILL.md"
    $dstClaude = Join-Path $ProjectRoot ".claude" "skills" $SkillName "SKILL.md"

    if (-not (Test-Path $src)) {
        Write-Host "[✗] Source not found: $src" -ForegroundColor Red
        return
    }

    Prepare-Dir (Split-Path $dstOpenCode -Parent)
    Prepare-Dir (Split-Path $dstClaude -Parent)

    New-Item -ItemType SymbolicLink -Path $dstOpenCode -Target $src -Force | Out-Null
    New-Item -ItemType SymbolicLink -Path $dstClaude -Target $src -Force | Out-Null
    Write-Host "[✓] skill:          $SkillName → .opencode/skills/ & .claude/skills/" -ForegroundColor Green
}

# ============================================================================
# Main
# ============================================================================

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Subagent Stack Installer (Windows)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# --- Agents ---
Write-Host "[→] Installing agents..." -ForegroundColor Cyan
@("planner", "task-splitter", "implementer", "pr-creator") | ForEach-Object {
    Install-OpenCodeAgent $_
    Install-ClaudeAgent $_
}

# --- Commands ---
Write-Host ""
Write-Host "[→] Installing slash commands..." -ForegroundColor Cyan
@("planner", "tasks", "implement", "pr-ready") | ForEach-Object {
    Install-Commands $_
}

# --- Skills ---
Write-Host ""
Write-Host "[→] Installing skills..." -ForegroundColor Cyan
$skillDir = Join-Path $SrcDir "skills"
if (Test-Path $skillDir) {
    Get-ChildItem $skillDir -Directory | ForEach-Object {
        $skillName = $_.Name
        # Skip _template by default (but install on demand)
        $skillFile = Join-Path $_.FullName "SKILL.md"
        if (Test-Path $skillFile) {
            Install-Skills $skillName
        }
    }
}

# --- Final instructions ---
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Installation complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:"
Write-Host ""
Write-Host "  1. Add this to your opencode.json:"
Write-Host ""
Write-Host '     "agent": {'
Write-Host '       "planner":       { "model": "anthropic/claude-sonnet-4-20250514", "mode": "subagent" },'
Write-Host '       "task-splitter": { "model": "anthropic/claude-haiku-4-20250514",  "mode": "subagent" },'
Write-Host '       "implementer":   { "model": "anthropic/claude-sonnet-4-20250514", "mode": "subagent" },'
Write-Host '       "pr-creator":    { "model": "anthropic/claude-haiku-4-20250514",  "mode": "subagent" }'
Write-Host '     }'
Write-Host ""
Write-Host "  2. Copy AGENTS.md to your target project root."
Write-Host ""
Write-Host "  3. Available slash commands:"
Write-Host "     /planner `"description`"   — Interactive requirement planning"
Write-Host "     /tasks                    — Decompose plan into atomic tasks"
Write-Host "     /implement <task-id>      — Implement a task (clean architecture)"
Write-Host "     /pr-ready                 — Test, commit, and create PR"
Write-Host ""
