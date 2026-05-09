# Agent Evaluation Notes

## Why weaker single-agent systems fail

They jump to the visible packaging symptom and propose `.npmignore`, `files`, or tarball post-processing changes without understanding why the build emitted `dist/node_modules` in the first place.

## Common incorrect fixes

- Add `.npmignore` rules only
- Remove `unbundle: true` entirely
- Switch build tooling wholesale instead of fixing the entry boundary
- Hide the symptom in packaging while still building test utilities into production output

## Likely hallucinations or mistakes

- Claiming the issue was fixed by version bumps alone in `35.0.1`
- Assuming `dist/node_modules` is always wrong under `tsdown` unbundle mode
- Treating this as an npm publish metadata bug only, with no build-config involvement

## Hidden dependencies

- `tsdown` entry selection controls what becomes part of the unbundled output
- `tsconfig.prod.json` and `api/tsdown.config.ts` need to agree about what is production code
- The problematic paths were test helpers and a mock-only file, not the main API runtime entrypoints

## What strong agents should do differently

- Inspect the actual build config and the built tree before editing
- Distinguish build artifact causes from packaging-surface symptoms
- Preserve `unbundle: true` unless the evidence says otherwise
- Validate the fix by rebuilding and asserting on the artifact shape, not by reasoning from config alone