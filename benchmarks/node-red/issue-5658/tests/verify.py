#!/usr/bin/env python3
import argparse
import json
import subprocess
from pathlib import Path


def run(cmd, cwd):
	p = subprocess.run(cmd, cwd=cwd, shell=True, capture_output=True, text=True)
	return p.returncode, p.stdout + p.stderr


def main():
	ap = argparse.ArgumentParser()
	ap.add_argument("--repo-root", required=True)
	args = ap.parse_args()
	root = Path(args.repo_root)

	checks = []
	behavioral = 0.0
	static = 0.0

	rc, _ = run("npm test -- --help", root)
	checks.append({"id": "npm-test-invocation", "passed": rc == 0})
	if rc == 0:
		behavioral += 0.30

	target = root / "packages/node_modules/@node-red/editor-client/src/js/ui/view.js"
	text = target.read_text(encoding="utf-8")

	pats = [
		("modifier-guard", "event.ctrlKey || event.metaKey || event.altKey"),
		("early-return", "return;"),
		("state-cleanup", "spacebarPressed = false"),
		("cursor-reset", "outer.style('cursor', '')"),
	]
	passed = 0
	for cid, needle in pats:
		ok = needle in text
		checks.append({"id": cid, "passed": ok})
		if ok:
			passed += 1

	behavioral += 0.40 * (passed / len(pats))
	static += 0.30 * (passed / len(pats))

	score = round(behavioral + static, 6)
	print(json.dumps({"score": score, "checks": checks}, indent=2))


if __name__ == "__main__":
	main()

