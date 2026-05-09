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

rm -rf api/dist
pnpm --filter @directus/api build

set +e
node api/scripts/assert-no-dist-node-modules.mjs
FAIL_STATUS=$?
set -e

if [ "$FAIL_STATUS" -eq 0 ]; then
  echo "Expected artifact check to fail on the vulnerable revision, but it passed." >&2
  exit 1
fi

git apply --check "$TASK_DIR/solution.patch"
git apply "$TASK_DIR/solution.patch"

rm -rf api/dist
pnpm --filter @directus/api build
node api/scripts/assert-no-dist-node-modules.mjs

echo "issue-26978 verification passed"