# Incident: Build Pipeline Fails on Windows Path Patterns

The build pipeline fails in Windows environments due to path-pattern handling divergence. Unix paths pass while Windows path semantics trigger file-matching failures.

Fix build-path behavior so the same build scripts work reliably across supported platforms.

## Requirements
- Build path expansion must work on Windows and non-Windows environments.
- Existing concat/build semantics must remain unchanged.
- Error reporting should reference normalized patterns where applicable.

## Verifier-Enforced Constraints
- Build command path must remain executable.
- Path normalization behavior must be present in concat expansion logic.
- Pattern/file checks must operate on normalized path representation.

## Definition of Done
- Behavioral and static checks pass.
- No regressions to non-Windows path behavior.
