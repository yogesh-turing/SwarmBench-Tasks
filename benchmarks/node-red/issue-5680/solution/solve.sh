#!/usr/bin/env bash
set -euo pipefail

apply_patch <<'"'"'PATCH'"'"'
*** Begin Patch
*** Update File: scripts/build/concat.js
@@
 const fg = require("fast-glob");
 const { concatEditor, concatVendor } = require("./config");
+
+const isWindows = process.platform === "win32";
+function normalizePath(p) {
+    return isWindows ? p.replace(/\\/g, "/") : p;
+}
 
 async function expand(patterns) {
@@
     const seen = new Set();
     for (const pattern of patterns) {
         const isGlob = /[*?[\]{}]/.test(pattern);
+        const globPattern = normalizePath(pattern);
         if (isGlob) {
-            const matches = (await fg(pattern, { onlyFiles: true })).sort();
+            const matches = (await fg(globPattern, { onlyFiles: true })).sort();
             if (matches.length === 0) {
-                throw new Error(`concat: pattern matched no files: ${pattern}`);
+                throw new Error(`concat: pattern matched no files: ${globPattern}`);
             }
@@
         } else {
-            if (!fs.existsSync(pattern)) {
-                throw new Error(`concat: file not found: ${pattern}`);
+            if (!fs.existsSync(globPattern)) {
+                throw new Error(`concat: file not found: ${globPattern}`);
             }
-            if (!seen.has(pattern)) {
-                seen.add(pattern);
-                out.push(pattern);
+            if (!seen.has(globPattern)) {
+                seen.add(globPattern);
+                out.push(globPattern);
             }
         }
     }
*** End Patch
PATCH

npm test -- --help >/dev/null
