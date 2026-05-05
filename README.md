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

Copia el directorio `agents-stack/` a la raíz de tu proyecto y ejecuta el
instalador:

```bash
cp -r agents-stack/ /ruta/de/tu/proyecto/
cd /ruta/de/tu/proyecto/agents-stack
./install.sh --target both   # opencode + Claude Code
# o usa un target específico:
#   ./install.sh --target opencode
#   ./install.sh --target claude
# Windows PowerShell:
#   .\install.ps1 -Target both
```

Esto crea:

| Directorio | Contenido |
|------------|-----------|
| `.opencode/agents/` | Symlinks a los agentes |
| `.claude/agents/` | Copias con modelo inyectado |
| `.opencode/commands/` | Comandos slash (`/planner`, `/tasks`, `/implement`, `/pr-ready`) |
| `.claude/commands/` | Comandos slash |
| `.opencode/skills/` | Skills de lenguaje/framework (symlinks) |
| `.claude/skills/` | Skills de lenguaje/framework (symlinks) |
| `AGENTS.md` | Instrucciones del pipeline |

## Configurar modelos

Los modelos se definen en `agents-stack/models.json`, la fuente única de
verdad. El instalador lee este archivo y genera `opencode.json`
automáticamente.

```json
{
  "opencode": {
    "planner":       "opencode-go/deepseek-v4-pro",
    "task-splitter": "opencode-go/deepseek-v4-flash",
    "implementer":   "opencode-go/minimax-m2.7",
    "pr-creator":    "opencode-go/deepseek-v4-flash"
  },
  "claude": {
    "planner":       "sonnet",
    "task-splitter": "haiku",
    "implementer":   "sonnet",
    "pr-creator":    "haiku"
  }
}
```

Para cambiar un modelo, edita `agents-stack/models.json` y vuelve a ejecutar
el instalador:

```bash
./agents-stack/install.sh --target both
```

Para Claude Code no se requiere configuración adicional — los modelos se
inyectan desde `models.json` durante la instalación.

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
| **implementer** | Detecta el stack (lenguaje + framework), carga la skill correspondiente, implementa con clean architecture y código comentado. | Sonnet / Opus |
| **pr-creator** | Corre tests, resume cambios, crea commit y PR, verifica conflictos con `main`. | Haiku |

## Agregar skills de lenguajes y frameworks

El implementer detecta el lenguaje y framework del proyecto y carga la skill
correspondiente con esta precedencia:

1. `<framework>-patterns` (ej. `fastapi-patterns`, `django-patterns`)
2. `<lenguaje>-patterns` (ej. `python-patterns`, `go-patterns`)
3. Si ninguna existe, usa el `_template` como fallback

El mapeo de dependencias a frameworks está definido en
`agents-stack/agents/implementer.md`.

### Skill de lenguaje (fallback genérico)

```bash
cp -r agents-stack/skills/_template agents-stack/skills/python
vim agents-stack/skills/python/SKILL.md
```

### Skill de framework (específico, mayor prioridad)

```bash
cp -r agents-stack/skills/_template agents-stack/skills/fastapi
vim agents-stack/skills/fastapi/SKILL.md
```

El frontmatter `name` debe ser `<framework>-patterns` o `<lenguaje>-patterns`.

Luego re-ejecuta el instalador:

```bash
./agents-stack/install.sh
```

## Estructura del proyecto

```
tu-proyecto/
├── .opencode/
│   ├── agents/           → symlinks a agents-stack/agents/
│   ├── commands/         → symlinks a agents-stack/commands/
│   └── skills/           → symlinks a skills instalados (python/, fastapi/)
├── .claude/
│   ├── agents/           → copias con modelo inyectado
│   ├── commands/         → symlinks
│   └── skills/           → symlinks
├── agents-stack/
│   ├── models.json       ← fuente única de modelos
│   ├── agents/           → definiciones de subagentes
│   ├── commands/         → definiciones de comandos slash
│   ├── skills/           → python/, fastapi/, _template/
│   ├── install.sh
│   └── install.ps1
├── opencode.json         ← generado por el instalador
├── AGENTS.md             → documentación del pipeline
├── plan.md               → generado por /planner
└── tasks.md              → generado por /tasks
```
