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
pnpm --filter @directus/app test -- src/composables/use-permissions/item/lib/get-fields.test.ts src/composables/use-permissions/item/use-item-permissions.test.ts
FAIL_STATUS=$?
set -e

if [ "$FAIL_STATUS" -eq 0 ]; then
  echo "Expected version-permission regression tests to fail on the vulnerable revision, but they passed." >&2
  exit 1
fi

git apply --check "$TASK_DIR/solution.patch"
git apply "$TASK_DIR/solution.patch"

pnpm --filter @directus/app test -- src/composables/use-permissions/item/lib/get-fields.test.ts src/composables/use-permissions/item/use-item-permissions.test.ts

echo "issue-26721 verification passed"