# Incident: Ctrl+Space Shortcut Lost Under Workspace Focus

A release regression causes modifier-based shortcut handling to become unreliable when workspace canvas focus and pan-mode logic overlap.

Restore shortcut behavior without breaking existing panning and keyboard interactions.

## Requirements
- Global shortcut with modifier + space must work under workspace focus.
- Existing spacebar panning behavior must remain intact.
- State tracking must remain correct if modifiers are introduced mid-interaction.

## Verifier-Enforced Constraints
- Tests must execute.
- Shortcut event path must not be swallowed by workspace handler when modifiers are present.
- Existing cursor/state cleanup behavior must remain safe.

## Definition of Done
- Behavioral and static checks pass.
- No regression to panning-mode behavior.
