#!/usr/bin/env python3
import json
import os
import subprocess
import sys

LOGS_DIR = '/logs/verifier'
REWARD_FILE = os.path.join(LOGS_DIR, 'reward.txt')
TEST_FILE = '/tests/run_tests.js'


def write_score(score):
    os.makedirs(LOGS_DIR, exist_ok=True)
    with open(REWARD_FILE, 'w', encoding='utf-8') as f:
        f.write(str(score))


def main():
    os.makedirs(LOGS_DIR, exist_ok=True)

    try:
        result = subprocess.run(
            ['node', TEST_FILE],
            capture_output=True,
            text=True,
            timeout=180,
            check=False,
        )
    except Exception as exc:
        print(f'Failed to run tests: {exc}', file=sys.stderr)
        write_score(0.0)
        return

    stdout = result.stdout.strip()
    stderr = result.stderr.strip()

    if stderr:
        print(stderr, file=sys.stderr)

    json_line = None
    for line in reversed(stdout.splitlines()):
        line = line.strip()
        if line.startswith('{') and line.endswith('}'):
            json_line = line
            break

    if not json_line:
        print('No JSON result found in test output', file=sys.stderr)
        print(stdout, file=sys.stderr)
        write_score(0.0)
        return

    try:
        data = json.loads(json_line)
    except json.JSONDecodeError as exc:
        print(f'Invalid JSON output: {exc}', file=sys.stderr)
        write_score(0.0)
        return

    passed = int(data.get('passed', 0))
    failed = int(data.get('failed', 0))
    total = passed + failed

    if total <= 0:
        write_score(0.0)
        return

    score = passed / total
    print(f'Passed {passed}/{total} tests, score={score:.4f}')

    for test in data.get('tests', []):
        state = 'PASS' if test.get('passed') else 'FAIL'
        msg = test.get('name', 'unnamed')
        if not test.get('passed') and test.get('error'):
            msg += f" :: {test['error']}"
        print(f'{state}: {msg}')

    write_score(score)


if __name__ == '__main__':
    main()
