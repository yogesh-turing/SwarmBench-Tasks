# Multi-Agent Gap Justification

Implemented tasks: #5653, #5658, #5680, #5695, #5703

## Why single-agent systems fail
- Competing technical threads force context switching between event semantics, state transitions, and regression safety.
- High probability of symptom-level fixes that pass one path but regress others.

## Why multi-agent orchestration succeeds
- Fan-out decomposition isolates technical threads in parallel.
- Orchestrator can synthesize event/state/build constraints into one coherent patch.
- Verification-focused subagent catches cross-thread regressions before finalization.

## Target gap strategy (>=0.23)
- Behavioral scoring dominates (0.70).
- Verifier rewards integrated outcomes, not isolated code edits.
- Decomposition emphasizes concurrent investigation + synthesis, which weak single-agent baselines struggle to emulate under timeout.
