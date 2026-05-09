# Plan 1 - Reviewer Remediation + >=30% Multi-Agent Gap Preservation

## Objective
Address the reviewer findings (coverage, oracle-instruction alignment, completeness, instruction leakage, infrastructure shortcuts) by hardening benchmark specification, oracle behavior, and verification logic so scores reflect real bug-fix quality while preserving a measurable single-vs-multi agent performance gap of at least 30%.

## Gap Target Definition
- Primary metric: mean reward across repeated runs per agent mode.
- Gap formula: `Gap = (Mean_multi - Mean_single) / Mean_single`.
- Acceptance threshold: `Gap >= 0.30`.
- Stability gate: threshold must hold across at least 3 seeds per mode.

## Reviewer Finding -> Action Mapping

### 1) Missing enforcers for required behaviors (QD-02.6, QD-03.2)
Action:
- Build a full requirement matrix: every requirement sentence in `instruction.md` must map to at least one verifier check ID.
- For each currently unenforced requirement, either:
  - Add a verifier check (preferred if requirement is essential), or
  - Remove/relax wording in `instruction.md` so it no longer claims mandatory behavior.
- Add a `requirements_traceability.md` artifact listing:
  - Requirement ID
  - Instruction location
  - Verifier check IDs
  - Oracle implementation location

Deliverable:
- Zero mandatory requirement without an enforcer.

### 2) Oracle-instruction divergence (QD-02.9)
Action:
- Align oracle implementation with final instruction requirements exactly.
- Remove fallback patterns that satisfy checks by comment token injection.
- Replace token-only fallback writes with code-structure transforms that preserve executable logic.
- Add oracle self-check assertions that verify semantic edits (not just string presence), and fail fast when semantic patching cannot be applied.

Deliverable:
- Oracle changes cover all required files/behaviors claimed by instructions.

### 3) Instruction leakage of verifier patterns (QD-04.3)
Action:
- Remove explicit verifier token disclosure from `instruction.md`.
- Rewrite acceptance criteria in behavioral terms only (what must happen, not exact strings).
- Keep verifier internals private and independent from user-facing instruction text.

Deliverable:
- Instruction does not expose literal matcher strings or exact verifier anchors.

### 4) Infrastructure shortcut vulnerability (QD-04.7)
Action:
- Replace broad substring checks with stronger checks:
  - AST/parse-based checks where feasible.
  - Contextual regex checks requiring code shape and proximity.
  - Behavioral checks that execute targeted scenarios.
- Add anti-cheat guardrails:
  - Reject checks satisfied only from comments.
  - Require modified code path execution evidence for key behaviors.

Deliverable:
- Comment-only string stuffing cannot achieve high score.

### 5) Prohibition enforcement gaps (QD-02.6)
Action:
- Remove prohibitions that cannot be reliably enforced in runtime environment, OR add enforceable checks:
  - file scope checks for writes outside allowed tree
  - checks ensuring tests/ verifier harness remain unchanged
- Keep only prohibitions that are testable in the verifier container.

Deliverable:
- No unenforceable prohibition remains in instruction.

## Verifier Redesign (Scoring)
- Behavioral-heavy weighting: 70-80% behavioral, 20-30% structural.
- Subscore partitions:
  - Core regressions fixed in runtime tests.
  - Negative tests proving non-regression.
  - Minimal structural sanity checks for intended file/area touch.
- Require all critical checks to pass for full reward; partial credit only for non-critical dimensions.

## Oracle Redesign
- Ensure deterministic, idempotent patch logic.
- Eliminate brittle exact-anchor replacements where possible; use robust transforms with validation.
- Add post-patch semantic validation per requirement family.
- Fail if required semantic edits are absent.

## Preserving >=30% Multi-Agent Advantage

### Task Design Levers
- Keep fan-out-synthesize shape with at least 4 independent technical threads and one integration thread.
- Ensure failures occur at integration boundaries (cross-file interaction), not only single-file edits.
- Add coupled tests that require fixes to coexist without regression.

### Difficulty Balancing
- Single agent should frequently reach partial completion but miss one integration edge.
- Multi-agent should gain from parallel exploration + synthesis and pass full integration more often.
- Avoid trivial token checks that collapse both modes to near-100% quickly.

### Experimental Protocol
- Run `oracle`, `single`, `multi` with same environment and seed set.
- Minimum 3 runs per mode.
- Capture mean, variance, pass-rate on critical checks.
- If gap < 30%:
  - Increase integration coupling complexity.
  - Reduce token/static-only scoring influence.
  - Add one additional cross-subsystem behavioral assertion.

## Execution Plan
1. Freeze current benchmark snapshot and produce requirement matrix.
2. Rewrite instruction text to remove verifier leakage and unenforceable prohibitions.
3. Upgrade verifier checks to semantic + behavioral enforcement for all required items.
4. Align oracle implementation to full requirement set and remove string-stuffing fallbacks.
5. Run local sanity validation (oracle path + verifier consistency).
6. Run Harbor evaluation matrix (oracle/single/multi; >=3 seeds each).
7. Compute gap, iterate on coupling/scoring until `Gap >= 0.30` is stable.
8. Finalize docs: requirements traceability, scoring rationale, gap evidence.

## Definition of Done
- Every mandatory instruction requirement has at least one verifier enforcer.
- Oracle implements all required behaviors and cannot pass via comment-only injection.
- Instruction has no verifier-token leakage.
- Prohibitions are either enforceable and enforced, or removed.
- Repeated Harbor runs show `Gap >= 0.30` between multi and single modes.
