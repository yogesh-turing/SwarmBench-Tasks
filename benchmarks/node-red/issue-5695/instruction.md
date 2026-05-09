# Incident: Footer Sidebar Buttons Trigger During Drag Drop

A user interaction regression causes footer sidebar actions to trigger when drag-release occurs over tab controls. Keyboard activation semantics also diverge from expected behavior.

Fix the event handling so click, drag, and keyboard workflows all remain correct.

## Requirements
- Drag-drop release over footer buttons must not trigger unrelated actions.
- Keyboard activation on buttons must remain valid.
- Drag-state guard must not persist and block subsequent real actions.

## Verifier-Enforced Constraints
- Event binding must use appropriate activation event semantics.
- Drag state must be reset in drag lifecycle completion.
- Existing click path remains operational.

## Definition of Done
- Behavioral and static checks pass.
- No regressions in sidebar tab interactions.
