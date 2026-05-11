The supabase repository at `/testbed`, it is Postgres development platform. Supabase is a combination of open source tools.

Following bugs have been reported against this codebase. Find and fix all of them. Also add mentioned new feature/s.

## Affected files

- `apps/studio/components/interfaces/Auth/ProtectionAuthSettingsForm/ProtectionAuthSettingsForm.tsx` — bug1 1
- `apps/studio/components/interfaces/Auth/SessionsAuthSettingsForm/SessionsAuthSettingsForm.tsx` — bug 1
- `scripts/authorizeVercelDeploys.ts` - bug 2
- `apps/www/components/MagnifiedProducts.tsx` - bug 3
- `apps/design-system/components/mdx-components.tsx` - feat 1
- `apps/design-system/content/docs/color-usage.mdx` - feat 1

## Bug reports

**Bug 1** — display inactivity timeout in human readable format

The `auth.sessions.inactivity_timeout` value is correctly configured in `config.toml` using duration format such as:

```
[auth.sessions]
inactivity_timeout = "10h0m0s"
During deployment, the backend correctly converts this value internally to seconds (36000).
```
However, in the Supabase Dashboard/Auth Sessions UI, the value is displayed directly as 36000 without clarifying that the unit is seconds. This creates confusion because users expect the configured duration (10 hours) rather than the raw converted value.

**Bug 2** - The Vercel deployment authorization script calls the GitHub Status API without authentication.

Step to reproduce the bug:
    Run the Vercel authorization script in CI without providing a GITHUB_TOKEN.
    Steps:
        Run the script with only these env variables:
        HEAD_COMMIT_SHA
        VERCEL_TOKEN
        Script calls:
        https://api.github.com/repos/supabase/supabase/statuses/{sha}
        GitHub API responds with rate limit / unauthenticated request.
        Deployment authorization fails.

Expected behavior
    The script should:
        - Authenticate GitHub API requests using GITHUB_TOKEN
        - Work reliably in CI
        - Support private repositories
        - Not hang indefinitely on network calls
        - Retry temporary API failures
        - Safely skip statuses without target_url
        - Exit with non-zero code when authorization fails


**Bug 3** - fix broken vector link in MagnifiedProducts component

The Vector product link in the MagnifiedProducts component points to /vector which returns a 404. The correct URL is /modules/vector.

**Feature 1** - Add a color palette to design-system

Add a color palette to the Design system for easier reference. 

Create new file with name `apps/design-system/components/color-palette.tsx` (if needed)