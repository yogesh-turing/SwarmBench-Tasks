# Task: Selected Node Overlay Update Lag

## Task Category
async

## Task Description
Investigate and resolve issue #5703 in Node-RED as a production debugging task. The defect is reproducible with provided artifacts and requires repository exploration, targeted validation, and a robust fix that avoids regressions.

## Constraints
- Preserve backward compatibility.
- Existing tests must pass.
- Avoid regressions in editor behavior and deploy workflow.
- Maintain editor/runtime separation and plugin compatibility.
- Keep fix maintainable and avoid one-off hacks.

## Artifacts Provided
- Repository snapshot
- Reproduction notes in repro.md
- Logs and traces in artifacts/
- Verifier checks in verifier/checks.yaml

## Success Criteria
- Reproduction no longer fails after the fix.
- Existing relevant tests pass.
- Added/updated regression coverage prevents recurrence.
- No observable regressions in adjacent workflows.

## Expected Agent Capabilities
- Repository exploration
- Runtime and UI debugging
- Event-driven reasoning
- Async/state tracking
- Verification behavior
- Monorepo navigation

## Hidden Difficulty
Status updates and selection redraws originate from different lifecycle paths.

## Common Failure Modes
- Broad repaint harms performance
- Only one update source is fixed
