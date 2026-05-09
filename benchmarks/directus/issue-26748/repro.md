# Reproduction

Repository: https://github.com/directus/directus
Base revision: `v11.15.4`
Working directory: repository root

## Setup

1. Check out `v11.15.4`
2. Ensure `node@22` and `pnpm@10` are available
3. Run `pnpm install --frozen-lockfile`

## Functional Scenario

A user with only read access to `directus_versions` should not be able to persist version deltas through `POST /versions/:pk/save`. On the vulnerable revision, `VersionsService.save()` performs the final write under `admin: true`, so the update succeeds even when the caller does not have update permission.

## Deterministic CI Reproduction

This benchmark uses a derived service test rather than a full HTTP stack:

- the regression test forces `validateAccess()` to reject `update` on `directus_versions`
- on the vulnerable revision, `save()` still resolves because it never performs that check
- after the fix, `save()` rejects with `ForbiddenError`

## Expected Failure Behavior

Before the fix:
- the derived regression test fails because `VersionsService.save()` does not throw
- the mocked `ItemsService.updateOne()` is still reached despite denied version access

## Logs / Signals To Capture

Capture:
- the failing test name
- whether `validateAccess()` was invoked
- whether the sudo `updateOne()` write still happened

## Notes

This benchmark isolates the security boundary at the service layer. It avoids external auth setup while still proving the underlying privilege-escalation behavior deterministically.