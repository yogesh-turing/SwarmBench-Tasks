# Agent Evaluation Notes

## Why weaker single-agent systems fail

They see `admin: true` and either miss its significance entirely or delete it wholesale. The right fix is subtler: preserve the internal sudo write but put the user-facing permission check before the elevation.

## Common incorrect fixes

- Remove all `admin: true` usage from `VersionsService`
- Add the permission check in the router instead of the service
- Check permissions after constructing the sudo `ItemsService`, which is already too late
- Validate the source collection update permission instead of `directus_versions` update permission

## Likely hallucinations or mistakes

- Claiming that the issue is solved by the Visual Editor PR `#26749`
- Claiming there is a direct public PR linked from the issue when the issue was actually closed in favor of the advisory
- Confusing `save()` with `promote()` and patching the wrong entrypoint

## Hidden dependencies

- `VersionsService` extends `ItemsService`, so reads and writes share mocked prototypes in tests
- `save()` is a user-facing path, while the internal elevated write is still needed for persistence
- The issue report explicitly distinguishes `read` on `directus_versions` from missing `create` / `update`

## What strong agents should do differently

- Treat the issue as a service-layer privilege boundary problem
- Preserve the internal architecture and only enforce access before elevation
- Validate with a focused regression test that proves both the failure and the absence of the sudo write on denied access
- Be explicit about the lack of a standalone public fix PR and keep the benchmark honest about that provenance