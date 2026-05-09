# Directus Issue 26978

Title: The `@directus/api` v35.0.0 package includes `dist/node_modules` subdirectory
Issue: https://github.com/directus/directus/issues/26978
Fixing PR: https://github.com/directus/directus/pull/27067
Primary commit:
- `e9765109603a8ae9cdd3663a68e9baf7ad347e5d`
Issue persisted through: `@directus/api@35.0.1`
Fixed in: `@directus/api@35.1.0`
Recommended vulnerable base: `v11.17.0`

## Phase 1 Summary

Root cause:
The API package used `tsdown` in unbundle mode with an overly broad entry set. Test helpers and a mock-only source file were being treated as production build entries, which in turn pulled extra build-time dependencies into the unbundled output and produced `api/dist/node_modules/` in the published package contents.

Architectural reasoning behind the fix:
The upstream fix did not switch away from unbundle mode and did not patch npm publish ignores. Instead, it narrowed the production build boundary so `tsdown` only emitted production entries. The fix excluded `src/test-utils` and the `apply-query/mock.ts` helper from the API build and aligned `tsconfig.prod.json` with that boundary.

Exact files changed in the original fix:
- `api/tsconfig.prod.json`
- `api/tsdown.config.ts`
- plus unrelated monorepo package/build updates in the same PR

Regression tests:
- No dedicated upstream regression test landed for the packaging artifact shape
- This benchmark therefore includes a derived artifact-check script patch

Fix breadth:
Minimal in the API package itself. The PR was broader, but the benchmark solution patch keeps only the API build-config changes that address the issue.

Fix type:
- tooling/build issue
- package artifact regression
- monorepo build boundary bug

## Changed-file Summary

- Excluded `src/test-utils` from `tsconfig.prod.json`
- Replaced the broad `tsdown` entry glob with a list that explicitly excludes test utilities, setup helpers, and a mock-only file
- Left `unbundle: true` intact

## Benchmark Intent

This task should force the agent to distinguish between a build artifact problem and a publish-ignore problem. The real fix is to stop feeding non-production sources into the build, not to hide the symptom after the fact.