# [Later] AI-assisted specification drafting and ambiguity questions

## Goal
Help non-SQL experts draft domain specs while keeping AI output untrusted and requiring human validation.

## Acceptance criteria
- [ ] Transform a business question into a proposed restricted-Python spec.
- [ ] Surface ambiguities about counting, time boundaries, NULL values, exclusions, and entity identity.
- [ ] Require explicit user approval of choices rather than silently interpreting them.
- [ ] Any verified guarantee refers to the approved formal spec, not the raw prompt.

**Priority:** P2 · **Depends on:** #08
