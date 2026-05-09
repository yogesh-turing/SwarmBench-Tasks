#!/usr/bin/env bash
set -euo pipefail

apply_patch <<'"'"'PATCH'"'"'
*** Begin Patch
*** Update File: packages/node_modules/@node-red/editor-client/src/js/ui/sidebar.js
@@
-        options.tabButton.on('mouseup', function(evt) {
+        options.tabButton.on('click', function(evt) {
             if (draggingTabButton) {
                 draggingTabButton = false
                 return
@@
                 options.tabButtonTooltip = RED.popover.tooltip(options.tabButton, options.name, options.action);
                 // Save the sidebar state
                 exportSidebarState()
+                draggingTabButton = false
             }
         })
@@
-                            globalTabBar.container.find('button[data-tab-id="'+tabId+'"]').trigger('mouseup')
+                            globalTabBar.container.find('button[data-tab-id="'+tabId+'"]').trigger('click')
*** End Patch
PATCH

npm test -- --help >/dev/null
