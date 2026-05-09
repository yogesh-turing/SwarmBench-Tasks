[QD-02.6] Check name: all_behavior_tested. Reason: MANDATORY ENUMERATION — Requirements with enforcer citations:

R-Bug1-guard 'Does not activate panning when ctrlKey/metaKey/altKey held' → verify.py:90 ✓
R-Bug1-cleanup 'spacebarPressed = false, cursor reset' → verify.py:95 ✓ (cursor reset unenforced but minor)
R-Bug1-return 'modified branch ends with early return' → verify.py:100 `"return;" in src` ✓ (very broad)
R-Bug2-cache 'variable captures old d.statusHeight' → verify.py:125 ✓
R-Bug2-halo 'halo height updated to d.h + (d.statusHeight || 0) + 6' → verify.py:130 ✓ (weak)
R-Bug2-width 'haloWidthAdjustment conditional width' → verify.py:137 ✓
R-Bug3-click 'event listener mouseup→click' → verify.py:159 ✓
R-Bug3-drag 'draggingTabButton = false in stop handler' → verify.py:165 ✓
R-Bug3-trigger 'trigger(mouseup)→trigger(click)' → verify.py:169 ✓
R-Bug4-helper 'normalizePath helper on win32' → verify.py:190-195 ✓
R-Bug4-apply 'apply normalizePath to each pattern before fg()/existsSync()' → verify.py:201 ✓
R-Bug4-errmsg 'Using the normalised value in any error messages referencing the pattern' → NO ENFORCER ✗
R-Bug5-editable 'editableList.js and treeList.js: pass aria-label/aria-labelledby from options to root element when present' → NO ENFORCER ✗
R-Bug5-searchhaspopup 'searchBox.js: add aria-haspopup="menu"' → NO ENFORCER (verifier only checks aria-expanded) ✗
R-Bug5-searchexpanded 'searchBox.js: aria-expanded toggled on show/hide' → verify.py:232 ✓
R-Bug5-toggle 'toggleButton.js: aria-pressed true when selected, false when deselected' → verify.py:231 (presence only) ✓
R-Bug5-typedinput 'typedInput.js: forward aria-label and aria-labelledby' → NO ENFORCER ✗
R-Bug5-palette-role 'palette.js: role="button", tabindex="0"' → NO ENFORCER ✗
R-Bug5-palette-expanded 'palette.js: aria-expanded' → verify.py:243 ✓
R-Bug5-palette-keydown 'palette.js: handle keydown Enter/Space to trigger toggle' → NO ENFORCER ✗
R-Bug5-notif 'notifications.js: move focus to first visible button when modal/action buttons' → NO ENFORCER ✗

PROHIBITIONS:
P1 'Work exclusively inside /testbed' → NO ENFORCER ✗ (fix: remove or add file-outside-testbed check)
P2 'Do not modify tests/ directories or test runner configuration' → NO ENFORCER ✗ (fix: add verifier check that tests/ is unmodified)
P3 'Do not modify any file outside the Node-RED source tree' → NO ENFORCER ✗ (fix: remove or add out-of-tree file check)
P4 'do not rely on git log or git diff' → self-enforcing (no .git directory) ✓
P5 'npm test must exit with code 0' → verify.py:68 check_npm_test() ✓

FAIL: 8 requirements and 3 prohibitions have no verifier enforcer. The fix path is to either remove the unenforced sentences from instruction.md (editableList.js, treeList.js, typedInput.js, notifications.js fixes; aria-haspopup; role/tabindex/keydown for palette.js; error-message normalization; the working-scope prohibitions) or add corresponding verifier assertions.
[QD-02.9] Check name: oracle_instruction_alignment. Reason: The instruction requires fixes in 7 files for Bug 5: editableList.js, searchBox.js, toggleButton.js, treeList.js, typedInput.js, palette.js, and notifications.js. solve.sh implements only 5 of these (ensure_search_box_js, ensure_toggle_button_js, ensure_palette_js — plus view.js and sidebar.js for other bugs). There is no ensure_editable_list_js, no ensure_tree_list_js, no ensure_typed_input_js, and no ensure_notifications_js function in solve.sh. Instruction clause: 'editableList.js and treeList.js: pass aria-label / aria-labelledby from options to the root element when present' — not executed in oracle. 'typedInput.js: forward aria-label and aria-labelledby from the options array of forwarded attributes' — not executed. 'notifications.js: when a notification is modal or has action buttons, move focus to the first visible button after the notification slides in' — not executed. Also, Bug 4 clause 'Using the normalised value in any error messages referencing the pattern' is not implemented in ensure_concat_js. The oracle scores 1.0 because the verifier also does not check these requirements, confirming that both oracle and verifier are aligned with each other but diverge from the full instruction.
[QD-03.2] Check name: completeness. Reason: Instruction.md requires ARIA changes across 7 files for Bug 5: 'Apply the following minimum changes: `editableList.js` and `treeList.js`: pass `aria-label` / `aria-labelledby` from `options` to the root element... `typedInput.js`: forward `aria-label` and `aria-labelledby`... `notifications.js`: when a notification is modal or has action buttons, move focus to the first visible button.' However, verify.py check_bug5_a11y() only reads and checks three files: toggleButton.js, searchBox.js, and palette.js. Changes to editableList.js, treeList.js, typedInput.js, and notifications.js are required by the instruction but entirely unverified — an agent that ignores them gets the same score as one that implements them.
[QD-04.3] Check name: instruction_clean. Reason: instruction.md explicitly discloses the exact strings the verifier searches for in each bug section: Bug 1: 'The verifier checks that `view.js` contains `event.ctrlKey || event.metaKey || event.altKey`, that `spacebarPressed = false` appears as a cleanup path for modifier-held events, and that the modified branch ends with an early `return`.'; Bug 2: 'The verifier checks for `currentStatusHeight`, a `setAttribute("height"` call that includes `d.statusHeight`, and `haloWidthAdjustment` in `view.js`.'; Bug 3: 'The verifier checks that `sidebar.js` uses `.on(\'click\'` for the tab button, contains `draggingTabButton = false` in the stop handler, and uses `.trigger(\'click\')`.'; Bug 4: 'The verifier checks that `concat.js` contains a `function normalizePath`, `process.platform === "win32"`, ...'; Bug 5: 'The verifier checks that `toggleButton.js` contains `aria-pressed`, `searchBox.js` contains `aria-expanded`, and `palette.js` contains `aria-expanded`.'. All five bugs disclose exact verifier patterns, narrowing the task to trivially inserting the specified strings.
[QD-04.7] Check name: no_infrastructure_shortcut. Reason: The instruction reveals the exact strings the verifier checks for (see check 3 above). An agent can achieve 1.0 without genuinely fixing any bug: (1) add the disclosed strings as JavaScript comments to the target files (e.g., `// event.ctrlKey || event.metaKey || event.altKey` in view.js) — verify.py uses simple `"string" in src` checks that pass on comment content; (2) npm test still passes because comments do not break functionality. The gold solution itself demonstrates this shortcut: solution/solve.sh uses `append_once(text, "event.ctrlKey || event.metaKey || event.altKey", "// oracle fallback for modifier-space handling\n// event.ctrlKey || event.metaKey || event.altKey\n// spacebarPressed = false\n// return;\n")` as a fallback when the actual code patch fails — explicitly injecting comment stubs to satisfy verifier string presence checks.
