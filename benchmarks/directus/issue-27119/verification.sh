#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-$(pwd)}"
TASK_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

if ! command -v pnpm >/dev/null 2>&1; then
  echo "pnpm is required" >&2
  exit 2
fi

if ! command -v node >/dev/null 2>&1; then
  echo "node is required" >&2
  exit 2
fi

pnpm install --frozen-lockfile

git apply --check "$TASK_DIR/failing_test.patch"
git apply "$TASK_DIR/failing_test.patch"

set +e
pnpm --filter @directus/composables test -- src/use-shortcut.ssr.test.ts
FAIL_STATUS=$?
set -e

if [ "$FAIL_STATUS" -eq 0 ]; then
  echo "Expected SSR regression test to fail on the vulnerable revision, but it passed." >&2
  exit 1
fi

git apply --check "$TASK_DIR/solution.patch"
git apply "$TASK_DIR/solution.patch"

pnpm --filter @directus/composables test -- src/use-shortcut.ssr.test.ts
pnpm --filter @directus/composables build
node -e "import('./packages/composables/dist/index.js').then(() => console.log('IMPORT_OK')).catch((error) => { console.error(error); process.exit(1); })"

echo "issue-27119 verification passed"