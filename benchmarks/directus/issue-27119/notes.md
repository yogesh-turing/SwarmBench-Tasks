# Agent Evaluation Notes

## Why weaker single-agent systems fail

They usually stop at the stack trace and blame the extension code, because that is the visible runtime failure. The real defect lives in a different package and only manifests when the SDK is externalized and evaluated in Node.js.

## Common incorrect fixes

- Add a `typeof document` guard inside the extension instead of in `@directus/composables`
- Patch the API extension manager to special-case the import path
- Replace the top-level access with a loose `globalThis.document && ...` but keep side effects at module scope

## Likely hallucinations or mistakes

- Claiming that Directus uses SSR rendering for the app and the bug is in Vue hydration
- Claiming that the fix requires changing `@directus/extensions-sdk` exports
- Assuming the issue is in the extension author's bundler config rather than in Directus

## Hidden dependencies

- `@directus/extensions-sdk` re-exports code that eventually reaches `@directus/composables`
- ESM module evaluation order is the key runtime boundary
- The vulnerable path only appears when the SDK is externalized instead of bundled away

## What strong agents should do differently

- Trace imports across packages before changing code
- Distinguish browser-only side effects from module-safe initialization
- Validate the fix with a non-browser import, not only with a browser smoke test
- Prefer the smallest fix that preserves the package API and current browser behavior