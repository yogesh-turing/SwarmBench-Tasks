#!/usr/bin/env python3
import argparse
import json
import subprocess
from pathlib import Path


def run(cmd, cwd):
    p = subprocess.run(cmd, cwd=cwd, shell=True, capture_output=True, text=True)
    return p.returncode, p.stdout + p.stderr


def contains(path, needle):
    return needle in path.read_text(encoding="utf-8")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo-root", required=True)
    args = ap.parse_args()
    root = Path(args.repo_root)

    checks = []
    score = 0.0

    behavioral = 0.0
    static = 0.0

    rc, out = run("npm test -- --help", root)
    checks.append({"id": "npm-test-invocation", "passed": rc == 0})
    if rc == 0:
        behavioral += 0.20

    p_sidebar = root / "packages/node_modules/@node-red/editor-client/src/js/ui/sidebar.js"
    p_palette = root / "packages/node_modules/@node-red/editor-client/src/js/ui/palette.js"
    p_tray = root / "packages/node_modules/@node-red/editor-client/src/js/ui/tray.js"
    p_notifications = root / "packages/node_modules/@node-red/editor-client/src/js/ui/notifications.js"
    p_toggle = root / "packages/node_modules/@node-red/editor-client/src/js/ui/common/toggleButton.js"

    b_checks = [
        ("sidebar-aria-expanded", contains(p_sidebar, "aria-expanded")),
        ("palette-aria-expanded", contains(p_palette, "aria-expanded")),
        ("tray-inert-handling", contains(p_tray, ".prop(\"inert\"")),
        ("notification-focus-guard", contains(p_notifications, "transient toasts must not steal focus")),
        ("toggle-aria-pressed", contains(p_toggle, "aria-pressed")),
    ]
    passed_b = sum(1 for _, ok in b_checks if ok)
    behavioral += 0.50 * (passed_b / len(b_checks))
    for cid, ok in b_checks:
        checks.append({"id": cid, "passed": ok})

    s_checks = [
        ("editablelist-aria-label-support", contains(root / "packages/node_modules/@node-red/editor-client/src/js/ui/common/editableList.js", "ariaLabel")),
        ("treelist-aria-labelledby-support", contains(root / "packages/node_modules/@node-red/editor-client/src/js/ui/common/treeList.js", "ariaLabelledBy")),
        ("typedinput-aria-propagation", contains(root / "packages/node_modules/@node-red/editor-client/src/js/ui/common/typedInput.js", "aria-labelledby")),
    ]
    passed_s = sum(1 for _, ok in s_checks if ok)
    static += 0.30 * (passed_s / len(s_checks))
    for cid, ok in s_checks:
        checks.append({"id": cid, "passed": ok})

    score = behavioral + static
    print(json.dumps({"score": round(score, 6), "checks": checks}, indent=2))


if __name__ == "__main__":
    main()
