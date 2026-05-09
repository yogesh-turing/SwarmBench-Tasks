# Repro

1. Start editor and open sidebar/palette-heavy workspace.
2. Navigate controls with keyboard only and inspect semantic attributes.
3. Trigger overflow menus, expand/collapse sections, open trays, and show notifications with actions.
4. Observe missing semantics and inconsistent focus behavior before fix.

Expected after fix:
- Controls expose state attributes correctly.
- Keyboard activation is supported where required.
- Modal/action notifications can receive focus.
- Transient toasts do not steal focus.
- Inactive tray regions are non-interactive.
