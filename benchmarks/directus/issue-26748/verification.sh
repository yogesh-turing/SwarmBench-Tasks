#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-$(pwd)}"
TASK_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

if ! command -v pnpm >/dev/null 2>&1; then
  echo "pnpm is required" >&2
  exit 2
fi

pnpm install --frozen-lockfile

git apply --check "$TASK_DIR/failing_test.patch"
git apply "$TASK_DIR/failing_test.patch"

set +e
pnpm --filter @directus/api test -- src/services/versions.permission-regression.test.ts
FAIL_STATUS=$?
set -e

if [ "$FAIL_STATUS" -eq 0 ]; then
  echo "Expected version-save permission regression test to fail on the vulnerable revision, but it passed." >&2
  exit 1
fi

git apply --check "$TASK_DIR/solution.patch"
git apply "$TASK_DIR/solution.patch"

pnpm --filter @directus/api test -- src/services/versions.permission-regression.test.ts

echo "issue-26748 verification passed"