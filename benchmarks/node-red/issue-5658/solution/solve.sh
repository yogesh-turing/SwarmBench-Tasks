#!/usr/bin/env bash
set -euo pipefail

apply_patch <<'"'"'PATCH'"'"'
*** Begin Patch
*** Update File: packages/node_modules/@node-red/editor-client/src/js/ui/view.js
@@
-            } else if (event.keyCode === 32 || event.key === ' ') {
+            } else if (event.keyCode === 32 || event.key === ' ') {
+                // Don't claim the event when a shortcut modifier is held — Ctrl/Cmd/Alt+Space
+                // belongs to the global keymap (e.g. ctrl-space -> core:toggle-sidebar).
+                if (event.ctrlKey || event.metaKey || event.altKey) {
+                    if (spacebarPressed && mouse_mode !== RED.state.PANNING) {
+                        spacebarPressed = false;
+                        outer.style('cursor', '');
+                    }
+                    return;
+                }
                 if (mouse_mode === RED.state.PANNING) {
*** End Patch
PATCH

npm test -- --help >/dev/null
