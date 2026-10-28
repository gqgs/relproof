# [MVP] Differential/property-based testing with shrinking counterexamples

## Goal
Compare the independent reference interpreter with SQLite execution on generated finite admissible databases.

## Acceptance criteria
- [ ] Generator respects declared primary/foreign keys and type constraints.
- [ ] Compare canonical results across at least dozens of generated database instances.
- [ ] Intentionally faulty `COUNT(*)` after joining order items is detected.
- [ ] Minimize and print a small explainable failing database (or document shrink limitations).
- [ ] Reports explicitly state `TESTED`, never `PROVED`, for finite samples.

**Priority:** P0 · **Depends on:** #05, #06
