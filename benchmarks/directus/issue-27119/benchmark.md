# Directus Issue 27119

Title: Unable to register API extensions hook because `document` is not defined
Issue: https://github.com/directus/directus/issues/27119
Fixing PR: https://github.com/directus/directus/pull/27155
Primary commits:
- `f00b520730797a69c72a958a35b7f08515a67dc1`
- `60c00ea9b85cdbd992beb456ee40e866e95fe8cf`
Release fixed in: `v11.17.4`
Recommended vulnerable base: `v11.17.2`

## Phase 1 Summary

Root cause:
`packages/composables/src/use-shortcut.ts` attached global DOM listeners at module evaluation time via top-level `document.body.addEventListener(...)` calls. That works in the browser, but API extensions that externalize `@directus/extensions-sdk` cause Node.js to import `@directus/composables` on the server, where `document` does not exist.

Architectural reasoning behind the fix:
The Directus team kept the existing public API and avoided a breaking export split between browser-only and server-safe composables. Instead, the fix moved listener registration behind an explicit runtime boundary so the module can be imported safely in non-browser contexts and still attach listeners once the DOM exists.

Exact files changed in the original fix:
- `packages/composables/src/use-shortcut.ts`
- `.changeset/plain-mice-arrive.md`

Regression tests:
- No dedicated upstream regression test landed in PR `#27155`
- This benchmark therefore includes a derived SSR-safety regression test patch

Fix breadth:
Minimal. One behavioral source file change plus a changeset.

Fix type:
- runtime boundary
- integration bug
- monorepo dependency issue

## Changed-file Summary

- Introduced an `attachGlobalListeners()` helper
- Added a `listenersAttached` guard to keep behavior idempotent
- Delayed listener registration until `onMounted()` so the DOM is guaranteed to exist

## Benchmark Intent

This task should force the agent to trace the import chain from API extensions into `@directus/extensions-sdk` and then into `@directus/composables`, instead of stopping at the misleading `document is not defined` stack trace.