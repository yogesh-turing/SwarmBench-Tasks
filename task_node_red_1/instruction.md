# Node-RED Editor: Fix Five Cross-Subsystem Bugs

The Node-RED editor has five known bugs that span independent subsystems: the
accessibility layer, two editor-event-handling paths in the canvas view, the
build pipeline, and the sidebar drag interaction. All five must be fixed together
for a stable editor release. The repository is at `/testbed`.

---

## Bug 1 — Spacebar Panning Intercepts Ctrl/Cmd/Alt+Space Shortcuts

**File:** `packages/node_modules/@node-red/editor-client/src/js/ui/view.js`

When the user presses Ctrl+Space (or Cmd+Space / Alt+Space), the canvas
space-bar panning handler claims the event before the global keymap can process
it (e.g. `core:toggle-sidebar`). Fix the `keydown` handler for `keyCode 32`
so that it:

- Does **not** activate panning when any of `ctrlKey`, `metaKey`, or `altKey`
  is held at the time of the keydown.
- Cleans up any in-progress panning state (`spacebarPressed = false`, cursor
  reset) if those modifiers are held while panning is already active, then
  returns early.

The verifier checks that `view.js` contains `event.ctrlKey || event.metaKey || event.altKey`,
that `spacebarPressed = false` appears as a cleanup path for modifier-held
events, and that the modified branch ends with an early `return`.

---

## Bug 2 — Status/Halo Geometry Not Redrawn After Status Height Changes

**File:** `packages/node_modules/@node-red/editor-client/src/js/ui/view.js`

When a node's status text/icon appears or disappears, the halo (`__halo__`)
element is not resized to account for the new `statusHeight`. This leaves the
selection highlight clipped or oversized.

Fix the `redrawStatus` function so that:

- A variable (e.g. `currentStatusHeight`) captures the old `d.statusHeight`
  before the status is redrawn.
- After computing the new `d.statusHeight`, if it changed, the halo's `height`
  attribute is updated to `d.h + (d.statusHeight || 0) + 6`.
- The button-halo width calculation uses a variable (e.g. `haloWidthAdjustment`)
  so the width is computed conditionally based on button toggle state.

The verifier checks for `currentStatusHeight`, a `setAttribute("height"` call
that includes `d.statusHeight`, and `haloWidthAdjustment` in `view.js`.

---

## Bug 3 — Sidebar Tab Activates on Drag-End Due to mouseup Listener

**File:** `packages/node_modules/@node-red/editor-client/src/js/ui/sidebar.js`

The sidebar tab button uses a `mouseup` listener to detect clicks. When the
user drags a tab to reorder it and releases the mouse button, the `mouseup`
fires and activates the tab unintentionally.

Fix this by:

- Changing the tab-button event listener from `mouseup` to `click` (a `click`
  event does not fire at the end of a drag, whereas `mouseup` does).
- Ensuring `draggingTabButton` is reset to `false` inside the `sortable`
  stop-callback so that subsequent real clicks work correctly.
- Updating any `trigger('mouseup')` call that synthetically activates a tab to
  use `trigger('click')` instead.

The verifier checks that `sidebar.js` uses `.on('click'` for the tab button,
contains `draggingTabButton = false` in the stop handler, and uses
`.trigger('click')`.

---

## Bug 4 — Build Script Fails on Windows Due to Unormalised Path Separators

**File:** `scripts/build/concat.js`

The build script passes raw path strings (which may use backslashes on Windows)
directly to `fast-glob` and `fs.existsSync`. Both functions expect POSIX
forward-slash separators on all platforms.

Fix the `expand` function by:

- Adding a `normalizePath` helper that replaces backslashes with forward slashes
  on `process.platform === 'win32'` and is a no-op on other platforms.
- Applying `normalizePath` to each pattern before it is passed to `fg()` or
  `existsSync()`.
- Using the normalised value in any error messages referencing the pattern.

The verifier checks that `concat.js` contains a `function normalizePath`,
`process.platform === "win32"`, and a variable (e.g. `globPattern`) that holds
the normalised value before it is passed to `fg`.

---

## Bug 5 — Accessibility Attributes Missing from Common UI Widgets

**Files (all under `packages/node_modules/@node-red/editor-client/src/js/ui/common/`):**

- `editableList.js`
- `searchBox.js`
- `toggleButton.js`
- `treeList.js`
- `typedInput.js`

**Also:** `ui/notifications.js`, `ui/palette.js`

Screen readers cannot navigate these widgets correctly because they lack the
required ARIA attributes. Apply the following minimum changes:

- `editableList.js` and `treeList.js`: pass `aria-label` / `aria-labelledby`
  from `options` to the root element when present.
- `searchBox.js`: add `aria-haspopup="menu"` and `aria-expanded` (toggled on
  show/hide) to the options dropdown button.
- `toggleButton.js`: add `aria-pressed` attribute, set to `"true"` when
  selected and `"false"` when deselected.
- `typedInput.js`: forward `aria-label` and `aria-labelledby` from the options
  array of forwarded attributes.
- `palette.js`: add `role="button"`, `tabindex="0"`, and `aria-expanded` to
  palette category headers; handle `keydown` Enter/Space to trigger toggle.
- `notifications.js`: when a notification is modal or has action buttons, move
  focus to the first visible button after the notification slides in.

The verifier checks that `toggleButton.js` contains `aria-pressed`,
`searchBox.js` contains `aria-expanded`, and `palette.js` contains
`aria-expanded`.

---

## Constraints

- Work exclusively inside `/testbed`.
- Do **not** modify `tests/` directories or the test runner configuration.
- Do **not** modify any file outside the Node-RED source tree.
- The repository has no git history; do not rely on `git log` or `git diff`.
- Run `npm test` from `/testbed` to verify no regressions after your changes.
  The test suite must exit with code 0.
