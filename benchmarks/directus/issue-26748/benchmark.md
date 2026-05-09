# Directus Issue 26748

Title: Version permissions not enforced for version save operations
Issue: https://github.com/directus/directus/issues/26748
Security advisory: https://github.com/directus/directus/security/advisories/GHSA-7p53-c7p5-8j2j
Fixing PR: no dedicated public PR linked from the issue before closure
Relevant public references:
- issue discussion: https://github.com/directus/directus/issues/26748
- related Visual Editor note calling out the backend gap: https://github.com/directus/directus/pull/26749
- later public hardening commits in adjacent version-permission flows:
  - `49adf1a543522a3cf6cbfa9708fcd8c535237453`
  - `991189e5e475337d5f0bc1ff8342b4697d643a35`
  - `b9815f69eb99764fde496da5740d130bee939124`
Recommended vulnerable base: `v11.15.4`

## Phase 1 Summary

Root cause:
`api/src/services/versions.ts` implements `VersionsService.save()` by building the new version delta and then persisting it through a nested `ItemsService` constructed with `admin: true`. That means a caller only needs enough access to reach the `save()` path; the actual write to `directus_versions` happens under elevated privileges and bypasses the caller's missing update permission.

Architectural reasoning behind the fix:
The service still needs an internal elevated write for the final persistence step, but the user-facing `save()` entrypoint must first validate the caller's permission to update the version record itself. The smallest production-quality fix is to keep the sudo write and insert an explicit access check on `directus_versions` immediately before elevation.

Exact files changed in this benchmark fix:
- `api/src/services/versions.ts`
- derived regression test file `api/src/services/versions.permission-regression.test.ts`

Regression tests:
- No dedicated public regression test was found in the vulnerable release line
- This benchmark therefore includes a derived regression test patch scoped to `VersionsService.save()`

Fix breadth:
Minimal. One service-layer permission check.

Fix type:
- permission regression
- security bug
- service-layer integration bug

## Original-fix Lineage Note

Directus closed the issue in favor of the security advisory instead of a standalone public PR on the issue. Because of that, this benchmark uses the original issue report to derive the minimal service-layer fix that matches the stated vulnerability and intended architecture.

## Benchmark Intent

This task should force the agent to distinguish between a legitimate internal sudo write and an illegitimate user-facing privilege bypass. The correct answer is not to remove every `admin: true` use, but to validate access before the internal elevation.