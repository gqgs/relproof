# [MVP] Parse and validate the restricted Python AST

## Goal
Use `ast.parse` to parse Python-compatible query source without running arbitrary user-written Python.

## Acceptance criteria
- [ ] Whitelist supported syntax; reject imports, arbitrary calls, mutation, recursion, loops outside comprehensions, and execution hooks.
- [ ] Preserve source ranges for diagnostics.
- [ ] Bind identifiers to typed schema entities and pure helper definitions.
- [ ] Accept `repeat_buyers`; reject crafted unsupported syntax with actionable errors.

**Priority:** P0 · **Depends on:** #01, #02
