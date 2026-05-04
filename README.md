# Stack de Subagentes

Pipeline de 4 subagentes para desarrollo de software asistido por IA, compatible
con **opencode** y **Claude Code**.

```
/planner    →  /tasks    →  /implement  →  /pr-ready
(planear)      (dividir)    (construir)    (publicar)
```

## Requisitos

- [opencode](https://opencode.ai) o [Claude Code](https://docs.anthropic.com/en/docs/claude-code/overview)
- Python 3 (viene preinstalado en macOS y la mayoría de distribuciones Linux)
- Git

## Instalación

### 1. Copiá los archivos a tu proyecto

```bash
cp -r agents-stack/ /ruta/de/tu/proyecto/
cp AGENTS.md /ruta/de/tu/proyecto/
```

### 2. Ejecutá el instalador

```bash
cd /ruta/de/tu/proyecto/agents-stack
./install.sh          # macOS / Linux
# o
.\install.ps1         # Windows PowerShell
```

Esto crea:

| Directorio | Contenido |
|------------|-----------|
| `.opencode/agents/` | Symlinks a los agentes (compatible con opencode) |
| `.claude/agents/` | Copias de los agentes con modelo inyectado (compatible con Claude Code) |
| `.opencode/commands/` | Comandos slash (`/planner`, `/tasks`, `/implement`, `/pr-ready`) |
| `.claude/commands/` | Comandos slash (ídem) |
| `.opencode/skills/` | Skills de lenguajes (symlinks) |
| `.claude/skills/` | Skills de lenguajes (symlinks) |

### 3. Configurá los modelos

#### opencode

Agregá la sección `agent` a tu `opencode.json`. El instalador genera un snippet
en `.opencode/agent-models.generated.json` que podés copiar.

```jsonc
{
  "$schema": "https://opencode.ai/config.json",
  "agent": {
    "planner":       { "model": "anthropic/claude-sonnet-4-20250514", "mode": "subagent" },
    "task-splitter": { "model": "anthropic/claude-haiku-4-20250514",  "mode": "subagent" },
    "implementer":   { "model": "anthropic/claude-sonnet-4-20250514", "mode": "subagent" },
    "pr-creator":    { "model": "anthropic/claude-haiku-4-20250514",  "mode": "subagent" }
  }
}
```

Ajustá los IDs de modelo según los que tengas configurados en tu provider.

#### Claude Code

No requiere configuración adicional. Los modelos ya se inyectan desde
`agents-stack/models.json` durante la instalación. Si querés cambiar un modelo, editá
ese archivo y volvé a ejecutar `./install.sh`.

## Uso

### Flujo completo

```bash
# 1. Planificar
/planner "Agregar autenticación con OAuth a la API"

# 2. Dividir en tareas
/tasks

# 3. Implementar tarea por tarea
/implement 1
/implement 2
/implement 3

# 4. Crear PR
/pr-ready
```

### Con opencode

```bash
opencode run "/planner Agregar tema oscuro a la configuración"
opencode run "/tasks"
opencode run "/implement 1"
opencode run "/pr-ready"
```

### Con Claude Code

```bash
claude -p "/planner Agregar autenticación con OAuth"
claude -p "/tasks"
claude -p "/implement 3"
claude -p "/pr-ready"
```

## Subagentes

| Agente | Descripción | Modelo sugerido |
|--------|-------------|-----------------|
| **planner** | Planifica requerimientos haciendo preguntas interactivas hasta cubrir todo el contexto. Genera `plan.md`. | Sonnet / Opus |
| **task-splitter** | Lee `plan.md` y lo descompone en tareas atómicas con specs de tests unitarios y E2E. Genera `tasks.md`. | Haiku |
| **implementer** | Detecta el stack, carga la skill del lenguaje, implementa con clean architecture y código comentado. | Sonnet / Opus |
| **pr-creator** | Corre tests, resume cambios, crea commit y PR, verifica conflictos con `main`. | Haiku |

## Agregar skills de lenguajes

El implementer carga automáticamente la skill correspondiente al stack del
proyecto. Para agregar un nuevo lenguaje:

```bash
# 1. Copiá el template
cp -r agents-stack/skills/_template agents-stack/skills/python

# 2. Editá el SKILL.md con las convenciones del lenguaje
vim agents-stack/skills/python/SKILL.md

# 3. Re-ejecutá el instalador
./agents-stack/install.sh
```

La skill debe llamarse `<lenguaje>-patterns` (ej. `python-patterns`,
`go-patterns`) para que el implementer pueda encontrarla.

## Cambiar modelos

Editá `agents-stack/models.json` y volvé a ejecutar `./agents-stack/install.sh`:

```json
{
  "opencode": {
    "planner":       "anthropic/claude-sonnet-4-20250514",
    "task-splitter": "anthropic/claude-haiku-4-20250514",
    "implementer":   "anthropic/claude-sonnet-4-20250514",
    "pr-creator":    "anthropic/claude-haiku-4-20250514"
  },
  "claude": {
    "planner":       "sonnet",
    "task-splitter": "haiku",
    "implementer":   "sonnet",
    "pr-creator":    "haiku"
  }
}
```

## Estructura del proyecto

```
tu-proyecto/
├── .opencode/
│   ├── agents/           → symlinks a agents-stack/agents/
│   ├── commands/         → symlinks a agents-stack/commands/
│   └── skills/           → symlinks a agents-stack/skills/
├── .claude/
│   ├── agents/           → copias con modelo inyectado
│   ├── commands/         → symlinks a agents-stack/commands/
│   └── skills/           → symlinks a agents-stack/skills/
├── agents-stack/
│   ├── models.json       → configuración de modelos
│   ├── agents/           → definiciones fuente de los subagentes
│   ├── commands/         → definiciones de comandos slash
│   ├── skills/           → skills de lenguajes
│   ├── install.sh
│   └── install.ps1
├── AGENTS.md             → documentación del pipeline
├── plan.md               → generado por /planner
└── tasks.md              → generado por /tasks
```
