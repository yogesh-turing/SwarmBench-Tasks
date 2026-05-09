#!/usr/bin/env python3
"""
Verify that the Firebug Lite security issue is fixed in Lodash.

Checks:
1. firebug-lite-debug.js is removed OR not usable
2. Dangerous textEditorInner input is not exposed
3. File is not referenced in test/HTML files
4. No unsafe inline console execution surface remains
"""

import importlib
import inspect
import os
import sys
import tempfile
import textwrap

LODASH_DIR = "/lodash"
sys.path.insert(0, os.path.join(os.environ.get("LODASH_DIR", "/solution"), "src"))

# Define passed and total, and implement checks
passed = 0
total = 4

# 1. Check if firebug-lite-debug.js is removed or not usable
firebug_path = os.path.join(os.environ.get("LODASH_DIR", "/solution"), "src", "firebug-lite-debug.js")
if not os.path.exists(firebug_path):
    passed += 1

# 2. Check if dangerous textEditorInner input is not exposed
# (This is a simplified check, a real-world scenario would be more complex)
# We'll check if a file contains "textEditorInner"
text_editor_found = False
for root, _, files in os.walk(os.environ.get("LODASH_DIR", "/solution")):
    for file in files:
        if file.endswith((".js", ".html")):
            try:
                with open(os.path.join(root, file), "r", encoding="utf-8") as f:
                    if "textEditorInner" in f.read():
                        text_editor_found = True
                        break
            except (UnicodeDecodeError, IOError):
                continue
    if text_editor_found:
        break
if not text_editor_found:
    passed += 1

# 3. Check if file is not referenced in test/HTML files
firebug_ref_found = False
for root, _, files in os.walk(os.environ.get("LODASH_DIR", "/solution")):
    for file in files:
        if file.endswith((".html")):
            try:
                with open(os.path.join(root, file), "r", encoding="utf-8") as f:
                    if "firebug-lite-debug.js" in f.read():
                        firebug_ref_found = True
                        break
            except (UnicodeDecodeError, IOError):
                continue
    if firebug_ref_found:
        break
if not firebug_ref_found:
    passed += 1

# 4. Check for no unsafe inline console execution surface
# (This is a simplified check)
unsafe_inline_found = False
for root, _, files in os.walk(os.environ.get("LODASH_DIR", "/solution")):
    for file in files:
        if file.endswith((".js", ".html")):
            try:
                with open(os.path.join(root, file), "r", encoding="utf-8") as f:
                    if "console.exec" in f.read():
                        unsafe_inline_found = True
                        break
            except (UnicodeDecodeError, IOError):
                continue
    if unsafe_inline_found:
        break
if not unsafe_inline_found:
    passed += 1

with open("/logs/verifier/reward.txt", "w") as f:
    f.write(str(round(passed / total, 2)))

sys.exit(0)
