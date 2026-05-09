# Incident: Accessibility Attribute and Focus Semantics Regression Hardening

The editor has a cluster of accessibility regressions that were surfaced during release validation. Users report inconsistent keyboard navigation behavior across multiple widgets and poor screen-reader semantics in common controls.

Your task is to restore expected accessibility behavior across the impacted editor surfaces while preserving existing interaction models.

## Requirements
- Ensure interactive controls that are not native buttons expose correct semantic affordances.
- Ensure toggle-like controls report state changes consistently.
- Ensure popup/menu controls expose expanded/collapsed state correctly.
- Ensure keyboard traversal and focus movement remains usable when notifications or tray/panel surfaces appear.
- Ensure hidden/inactive overlay surfaces do not remain focusable.

## Constraints Enforced by Verifier
- Existing tests must pass.
- A11y semantics must be present in all impacted widget families.
- State attributes must transition with UI state.
- Focus behavior must avoid stealing focus for transient notifications.
- Changes must span multiple technical surfaces (not a one-file local patch).

## Non-Goals
- Do not rewrite unrelated rendering logic.
- Do not remove existing keyboard shortcuts.

## Definition of Done
- Behavioral and static verifier checks pass.
- Regression safety checks pass for sidebar/palette/tray/notification-related interactions.
