# Reproduction

Repository: https://github.com/directus/directus
Base revision: `v11.15.4`
Working directory: repository root

## Setup

1. Check out `v11.15.4`
2. Ensure `node@22` and `pnpm@10` are available
3. Run `pnpm install --frozen-lockfile`

## Functional Scenario

1. A collection item exists with a status field
2. The main item is in a state that fails the editor's collection `update` condition
3. The editor creates a content version whose merged state should be editable
4. The app still marks fields read-only because it consults the main-item permission result instead of version context

## Deterministic CI Reproduction

The benchmark uses upstream regression tests to model the bug deterministically:

- `app/src/composables/use-permissions/item/lib/get-fields.test.ts`
- `app/src/composables/use-permissions/item/use-item-permissions.test.ts`

The failing tests demonstrate two broken behaviors on the vulnerable revision:

- versions inherit main-item field restrictions even when version edits should bypass them
- `useItemPermissions()` does not understand an explicit version context

## Expected Failure Behavior

Before the fix:
- at least one of the added tests fails
- or TypeScript/Vitest fails because `useItemPermissions()` does not accept the version-context parameter yet

## Logs / Signals To Capture

Capture:
- failing test names
- assertion mismatch around `readonly` / `updateAllowed`
- any type error about the extra `isVersion` argument

## Notes

This benchmark intentionally avoids spinning up the full app. The targeted composable tests exercise the actual regression while remaining deterministic and fast in CI.