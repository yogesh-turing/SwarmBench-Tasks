#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TASK_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

python3 "$SCRIPT_DIR/verify.py" --repo-root "$TASK_DIR" > "$SCRIPT_DIR/result.json"
python3 - <<'PY'
import json
from pathlib import Path
result = json.loads(Path('tests/result.json').read_text())
score = result.get('score', 0.0)
Path('reward.txt').write_text(f"{score:.6f}\n")
print(json.dumps(result, indent=2))
PY
