# Directus v11.17.2 - Four Integrated Fixes

## Background

[Directus](https://github.com/directus/directus) is an open-source data platform and headless CMS built on Node.js.
The repository is checked out at `/testbed`; all paths below are relative to `/testbed`.

Your goal is to implement all four fixes so the verifier reports full reward.

## Required Behaviors

### Bug 1 - SSR-safe shortcut listener initialization (Issue #27119)

File: `packages/composables/src/use-shortcut.ts`

Requirements:
- `R1.1`: No `document.body.addEventListener(...)` call at module scope.
- `R1.2`: Keyboard listener attachment is encapsulated in a helper path.
- `R1.3`: Listener attachment is invoked from `onMounted()` only.
- `R1.4`: Listener attachment is idempotent (no duplicate global handlers).

### Bug 2 - Production build excludes test-only sources (Issue #26978)

Files: `api/tsdown.config.ts`, `api/tsconfig.prod.json`

Requirements:
- `R2.1`: `tsdown` entry excludes `src/test-utils`, `src/__utils__`, `src/__setup__`, and `src/database/run-ast/lib/apply-query/mock.ts`.
- `R2.2`: `tsconfig.prod.json` excludes `src/test-utils`.
- `R2.3`: Effective entry behavior excludes those test-only paths while still including normal production sources.

### Bug 3 - Reject collection names containing slash (Issue #27093)

File: `api/src/services/collections.ts`

Requirements:
- `R3.1`: `CollectionsService.createOne()` rejects names containing `/`.
- `R3.2`: Rejection uses `InvalidPayloadError`.
- `R3.3`: Validation occurs before collection name parsing to avoid creating invalid routable names.

### Bug 4 - Respect collection accountability in version save (Issue #25894)

File: `api/src/services/versions.ts`

Requirements:
- `R4.1`: `VersionsService.save()` reads collection `accountability` from `this.schema`.
- `R4.2`: If accountability is `null`, skip activity and revision writes.
- `R4.3`: If accountability is `activity`, write activity but skip revision.
- `R4.4`: Only when accountability is `all`, write both activity and revision.

## Scope

Edit only the files listed above for each bug.

## Acceptance

Run:

```bash
python3 /tests/verify.py
```

The run must finish with full reward and zero failed checks.
