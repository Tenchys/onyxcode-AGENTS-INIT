---
name: language-template
description: Template for creating stack-specific implementation skills. Copy this and customize for your language/framework.
license: MIT
compatibility: both
metadata:
  audience: implementers
  type: template
---

## What I Do

Provide language-specific coding conventions for the implementer subagent.

## How to Create a New Skill

1. Copy this entire directory to `src/skills/<language-name>/`
2. Edit `SKILL.md` — update the `name`, `description`, and body below.
3. The implementer will call `skill({ name: "<language-name>-patterns" })`.

---

## Clean Architecture Patterns

- Directory structure convention for this language:
  ```
  src/
    domain/          # Entities, value objects, domain exceptions
    application/     # Use cases, ports (interfaces)
    infrastructure/  # Adapters (DB, HTTP, messaging implementations)
    presentation/    # Controllers, presenters, views (if applicable)
  tests/
    unit/
    integration/
    e2e/
  ```

## Code Conventions

- Naming conventions: [e.g., PascalCase for classes, camelCase for functions]
- File naming: [e.g., kebab-case.ts, snake_case.py]
- Import order: [e.g., standard library → third-party → local]
- Max function length: 20 lines
- Max file length: 300 lines

## Testing

- Test framework: [e.g., Jest, pytest, testing package]
- Test file convention: [e.g., `*.test.ts`, `test_*.py`, `*_test.go`]
- Run command: [e.g., `npm test`, `pytest`, `go test ./...`]
- Mocking library: [e.g., Jest mocks, unittest.mock, testify/mock]

## Common Patterns

- Dependency injection approach
- Error handling convention
- Logging convention
- Configuration management
- Database access pattern (repository, ORM)
- API client pattern
- Background job pattern

## Anti-patterns to Avoid

- List common mistakes in this language/framework
