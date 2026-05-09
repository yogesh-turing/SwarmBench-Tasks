# Reproduction

Repository: https://github.com/directus/directus
Base revision: `v11.17.0`
Working directory: repository root

## Setup

1. Check out `v11.17.0`
2. Ensure `node@22` and `pnpm@10` are available
3. Run `pnpm install --frozen-lockfile`

## Deterministic Failure Reproduction

1. Build the API package:

```sh
pnpm --filter @directus/api build
```

2. Inspect the build output for `api/dist/node_modules`

The benchmark includes a derived artifact-check script that fails if that directory exists.

## Expected Failure Behavior

Before the fix:
- `api/dist/node_modules` exists after the build
- the artifact-check script exits non-zero and prints the unexpected directory path

## Logs / Signals To Capture

Capture:
- whether `api/dist/node_modules` exists
- the artifact-check script exit code
- the API build command output

## Notes

The original user report observed the problem from the npm package explorer. This benchmark checks the local build artifact directly, which is deterministic and CI-friendly while still targeting the underlying regression that shipped to npm.