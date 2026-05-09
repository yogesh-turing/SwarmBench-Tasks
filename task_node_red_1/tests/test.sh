#!/bin/bash
set -euo pipefail
mkdir -p /logs/verifier

cd /testbed

set +e
python3 /tests/verify.py 2>&1 | tee /logs/verifier/test-output.log
set -e

# verify.py writes a fractional reward directly to /logs/verifier/reward.txt.
# Do not overwrite it here — partial credit matters for training signal.

exit 0
