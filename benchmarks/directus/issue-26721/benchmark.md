# Directus Issue 26721

Title: Permission conditions are checked against the main object instead of the versioned object being edited
Issue: https://github.com/directus/directus/issues/26721
Fixing PR: https://github.com/directus/directus/pull/26815
Primary commits:
- `1315c18f3be03a8f2299fe38e3ac40daf3164683`
- `6cdeb3dc98af31369271764b79917b19f6118b61`
- `823de6196eba2a5c24fcabe7869a4f1d19d2aeed`
- `a45018cb417b42449adf27d06c4f8dadc3145875`
- merge commit `5ec69e2e59a11a67f309bba6dbd5dae2e8aba9bc`
Release fixed in: `v11.17.0`
Recommended vulnerable base: `v11.15.4`

## Phase 1 Summary

Root cause:
The app-side permission composables treated version editing as if it were editing the main item directly. When the main item failed a custom update condition, the UI locked fields and disabled updates even though the user was editing a content version and version editing should bypass the underlying collection update gate until promote time.

Architectural reasoning behind the fix:
The Directus team chose to thread explicit version context through the app permission layer rather than rework the backend condition evaluator. The fix introduced an `isVersion` flag through `useItem -> usePermissions -> useItemPermissions -> isActionAllowed/getFields`, making the version-editing behavior explicit and local to the app permission abstraction.

Exact files changed in the original fix:
- `app/src/composables/use-item/index.ts`
- `app/src/composables/use-permissions/index.ts`
- `app/src/composables/use-permissions/item/lib/get-fields.ts`
- `app/src/composables/use-permissions/item/lib/is-action-allowed.ts`
- `app/src/composables/use-permissions/item/use-item-permissions.ts`
- `app/src/composables/use-permissions/item/lib/get-fields.test.ts`
- `app/src/composables/use-permissions/item/use-item-permissions.test.ts`
- `.changeset/thin-files-film.md`

Regression tests:
- Upstream added regression coverage in `get-fields.test.ts`
- Upstream added a new `use-item-permissions.test.ts`

Fix breadth:
Broad but still localized. The fix spans several composables because version context had to be propagated through the permission API surface.

Fix type:
- permission regression
- stateful UI bug
- monorepo app-layer integration bug

## Changed-file Summary

- Added an explicit `isVersion` signal when an item view is opened with a version query parameter
- Bypassed update-field gating for version edits in the app
- Preserved delete/share behavior and preserved new-item semantics
- Fixed a related partial-access edge case where `fields: undefined` had been treated like `no fields allowed`

## Benchmark Intent

This task should force the agent to reason about two concurrent object states: the main item and the versioned item. It is intentionally easy to misdiagnose as a backend permission-policy problem when the practical regression lives in the app permission composables.