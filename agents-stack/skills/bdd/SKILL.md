---
name: bdd-patterns
description: BDD conventions for Gherkin syntax, step definitions, and test execution patterns across languages.
license: MIT
compatibility: both
metadata:
  audience: implementers
  type: skill
---

## What I Do

Provide BDD (Behavior-Driven Development) conventions for the implementer
subagent. Framework-specific BDD skills (e.g., `bdd-python-behave`) layer
on top of this and take precedence when available.

---

## Gherkin Keywords by Language

Every `.feature` file starts with `# language: <code>` to tell the runner
which keyword set to use. Use the keywords from the table below matching
the `lang` field in `features/.bddconfig`.

| EN | ES | FR | DE | PT |
|----|----|----|----|----|
| `Feature:` | `Característica:` | `Fonctionnalité:` | `Funktionalität:` | `Funcionalidade:` |
| `Scenario:` | `Escenario:` | `Scénario:` | `Szenario:` | `Cenário:` |
| `Given` | `Dado` / `Dada` / `Dados` | `Étant donné` | `Angenommen` | `Dado` / `Dada` |
| `When` | `Cuando` | `Quand` | `Wenn` | `Quando` |
| `Then` | `Entonces` | `Alors` | `Dann` | `Então` |
| `And` | `Y` | `Et` | `Und` | `E` |
| `But` | `Pero` | `Mais` | `Aber` | `Mas` |
| `Background:` | `Antecedentes:` | `Contexte:` | `Grundlage:` | `Contexto:` |
| `Scenario Outline:` | `Esquema del escenario:` | `Plan du scénario:` | `Szenariogrundriss:` | `Esquema do Cenário:` |
| `Examples:` | `Ejemplos:` | `Exemples:` | `Beispiele:` | `Exemplos:` |

For any other language, reference the official Gherkin i18n JSON:
https://github.com/cucumber/gherkin/blob/main/gherkin-languages.json

## Language Rules

- **Step text**: written in the configured language (from `.bddconfig`)
- **Technical terms**: keep in English (`token JWT`, `endpoint /api/auth`,
  `email`, `API`, `OAuth`, `database`, `ID`)
- **Variable/data names**: as defined in plan.md (usually English)
- **The `# language: <code>` directive**: ALWAYS present at line 1 of each `.feature`

## Gherkin Conventions

### Scenario Structure

```
Background:     ← shared state (optional, use sparingly)
  Given ...

Scenario: <business outcome>     ← tags: @happy-path @edge-case @error @slow
  Given <precondition>
  When  <action>
  Then  <observable result>
  And   <additional outcome>
```

### Rules

- One `When` per scenario (testing exactly one action)
- `Given` describes state, not actions the user/system performs
- `Then` describes observable business outcomes, not implementation internals
- Steps must use natural language — never describe code, DB queries, or HTTP internals
- Technical terms are the exception (they stay in English)
- Max 10 steps per scenario (including Background)

### Tags

| Tag | When to use |
|-----|-------------|
| `@happy-path` | Main success scenario |
| `@edge-case` | Boundary conditions, unusual inputs |
| `@error` | Error handling, failure modes |
| `@slow` | Scenarios that take >1s (can be skipped in dev) |
| `@wip` | Work in progress, not yet passing |

### Scenario Outlines

Use for data-driven variations (validation rules, permissions, formats):

```gherkin
Scenario Outline: Validación del campo email
  Given que ingreso el email "<email>"
  When envío el formulario de registro
  Then veo el mensaje "<mensaje>"

  Examples:
    | email              | mensaje                     |
    | ""                 | "El email es obligatorio"   |
    | "no-es-email"      | "Formato de email inválido" |
    | user@domain.com    | "Registro exitoso"          |
```

## Step Definition Patterns

### From .feature to code

Each Gherkin step must have a corresponding step definition function.
The step definition decorator uses the exact text (or regex) from the
`.feature` file.

Python (behave):
```python
@given('que "{email}" no ha iniciado sesión')
def step_user_not_logged_in(context, email):
    context.client = APIClient()
```

JavaScript (cucumber-js):
```javascript
Given('que {email} no ha iniciado sesión', function(email) {
    this.client = new APIClient();
});
```

### Context/World pattern

- Python/Behave: `context` object passed between steps
- JS/Cucumber: `this` is the World instance
- Shared state goes on context/world (DB connection, HTTP client, auth tokens)

### Red-Green-Refactor cycle

1. Write step definitions that match .feature text → RED (undefined steps gone)
2. Run `behave` — steps fail because production code doesn't exist → RED
3. Implement production code → GREEN
4. Refactor if needed

## Project Structure

```
features/
  .bddconfig                      ← {"lang": "es", "version": 1}
  <domain>/
    <feature>.feature             ← Gherkin scenarios
  steps/
    <domain>_steps.<ext>          ← Step definitions
    conftest.py (Python)          ← Shared fixtures (HTTP client, DB, etc.)
```

## BDD vs Unit Tests

| Aspect | BDD | Unit Tests |
|--------|-----|------------|
| **Scope** | End-to-end business flow | Single function/class |
| **Audience** | Stakeholders, QA, devs | Developers only |
| **Language** | Natural language (configured locale) | Code (English) |
| **Execution** | `behave` / `cucumber-js` | `pytest` / `jest` |
| **Speed** | Slower (integrates multiple components) | Fast (isolated) |
| **Coverage** | Happy paths + critical edge cases | All branches + edge cases |
