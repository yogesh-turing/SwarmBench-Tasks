# Reproduction

Repository: https://github.com/directus/directus
Base revision: `v11.17.2`
Working directory: repository root

## Setup

1. Check out `v11.17.2`
2. Ensure `node@22` and `pnpm@10` are available
3. Run `pnpm install --frozen-lockfile`
4. Build the composables package with `pnpm --filter @directus/composables build`

## Deterministic Failure Reproduction

The upstream issue was triggered indirectly through API extension loading, but the core failure is simpler: importing the composables entrypoint in a non-browser runtime evaluates `use-shortcut.ts` and immediately touches `document`.

Reproduction command:

```sh
node -e "import('./packages/composables/dist/index.js').then(() => console.log('IMPORT_OK')).catch((error) => { console.error(error); process.exit(1); })"
```

## Expected Failure Behavior

On the vulnerable revision, the command exits non-zero and stderr contains one of:

- `ReferenceError: document is not defined`
- a stack frame inside `packages/composables/dist/index.js`
- the top-level `use-shortcut` listener registration path

## Logs / Signals To Capture

Capture:
- the full thrown error
- the first stack frame in `@directus/composables`
- the process exit code

## Notes

The benchmark verification script uses a derived regression test instead of spinning up a full Directus server. That keeps the failure deterministic, CI-friendly, and directly scoped to the runtime boundary that actually broke.