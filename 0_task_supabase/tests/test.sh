#!/bin/bash
set -euo pipefail
mkdir -p /logs/verifier

cd /testbed

set +e
python3 /tests/verify.py 2>&1 | tee /logs/verifier/test-output.log
set -e

if [ ! -f /logs/verifier/reward.txt ]; then
  echo 0 > /logs/verifier/reward.txt
fi
