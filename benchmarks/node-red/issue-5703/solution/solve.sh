#!/usr/bin/env bash
set -euo pipefail

apply_patch <<'"'"'PATCH'"'"'
*** Begin Patch
*** Update File: packages/node_modules/@node-red/editor-client/src/js/ui/view.js
@@
-            if (!showStatus || !d.status || d.d === true) {
+            const currentStatusHeight = d.statusHeight || 0
+            if (!showStatus || !d.status || d.d === true) {
                 nodeEl.__statusGroup__.style.display = "none";
                 d.statusHeight = 0;
             } else {
+                let hasStatusIcon = false
+                let hasStatusText = false
                 nodeEl.__statusGroup__.style.display = "inline";
@@
                     nodeEl.__statusShape__.style.display = "inline";
                     nodeEl.__statusShape__.setAttribute("class","red-ui-flow-node-status "+statusClass);
                     nodeEl.__statusBackground__.setAttribute("x", 3)
+                    hasStatusIcon = true
                 }
                 if (d.status.hasOwnProperty('text')) {
                     nodeEl.__statusLabel__.textContent = d.status.text;
+                    hasStatusText = true
                 } else {
                     nodeEl.__statusLabel__.textContent = "";
                 }
@@
-                d.statusHeight = nodeEl.__statusGroup__.getBBox().height
+                if (hasStatusIcon || hasStatusText) {
+                    d.statusHeight = 14
+                } else {
+                    d.statusHeight = 0
+                }
                 nodeEl.__statusBackground__.setAttribute('width', backgroundWidth)
             }
             delete d.dirtyStatus;
+            if (currentStatusHeight !== d.statusHeight) {
+                nodeEl.__halo__.setAttribute("height", d.h + (d.statusHeight || 0) + 6)
+            }
@@
-                this.__halo__.setAttribute("height", d.h + 10);
+                this.__halo__.setAttribute("height", d.h + 6);
@@
-                            var x = d._def.align == "right"?d.w-6:-25;
+                            var x = d._def.align == "right"?d.w-6:-26;
+                            let haloWidthAdjustment = 32
                             if (d._def.button.toggle && !d[d._def.button.toggle]) {
                                 x = x - (d._def.align == "right"?8:-8);
+                                haloWidthAdjustment = 24
                             }
@@
-                                this.__halo__.setAttribute("width", d.w + 31)
+                                this.__halo__.setAttribute("width", d.w + haloWidthAdjustment)
                                 if (d._def.align !== 'right') {
-                                    this.__halo__.setAttribute("x", -28)
+                                    this.__halo__.setAttribute("x", - (haloWidthAdjustment - 3))
                                 }
                             }
*** End Patch
PATCH

npm test -- --help >/dev/null
