#!/bin/bash
set -euo pipefail

mkdir -p /logs/verifier

cd /testbed

set +e
python3 /tests/verify.py 2>&1 | tee /logs/verifier/test-output.log
set -e

exit 0