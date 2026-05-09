# Rejected Issues (Phase 1)

The following selected issues were rejected for final SwarmBench task implementation because they are unlikely to produce a structural multi-agent advantage >= 0.23 under deterministic verification:

- #5707, #5705, #5704, #5702, #5696, #5683, #5676, #5674, #5656
  - Reason: narrowly scoped UX/cosmetic deltas; limited cross-subsystem synthesis requirement.

- #5672
  - Reason: tooling migration step too shallow in isolation for robust multi-agent edge.

- #5668
  - Reason: very strong PR-scale candidate but not included in this implementation pass due very high patch volume and elevated oracle-maintenance burden; should be built as a dedicated long-horizon benchmark.

- #5693, #5699
  - Reason: theming refactor candidate is viable, but requires a dedicated visual-diff behavioral harness and broad CSS integration checks to avoid brittle scoring. Deferred to a separate theming-focused benchmark pack.
