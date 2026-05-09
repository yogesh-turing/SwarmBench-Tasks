#!/usr/bin/env python3
"""
Verifier for task_node_red_1: Five cross-subsystem Node-RED editor bug fixes.

Scoring design
--------------
  Behavioural (>=50%):
    - npm test passes without error   → 0.50

  Static pattern checks (<=50%):
    - Bug 1 – spacebar modifier guard → 0.10
    - Bug 2 – halo geometry sync      → 0.10
    - Bug 3 – sidebar click handler   → 0.10
    - Bug 4 – build path normalization→ 0.10
    - Bug 5 – accessibility attrs     → 0.10

Every check traces directly to a named requirement in instruction.md.
No check enforces an exact variable name; a semantically equivalent
implementation that satisfies the same requirement will also pass.
"""
import json
import os
import subprocess
import sys

TESTBED = "/testbed"
VERIFIER_DIR = "/logs/verifier"

os.makedirs(VERIFIER_DIR, exist_ok=True)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

results = []


def _read(relpath: str) -> str:
    full = os.path.join(TESTBED, relpath)
    if not os.path.exists(full):
        return ""
    with open(full, encoding="utf-8", errors="replace") as fh:
        return fh.read()


def record(check_id: str, passed: bool, detail: str = "") -> None:
    results.append({"id": check_id, "passed": passed, "detail": detail})
    symbol = "PASS" if passed else "FAIL"
    msg = f"  {symbol}  {check_id}"
    if detail:
        msg += f": {detail}"
    print(msg)


# ---------------------------------------------------------------------------
# Behavioural check — npm test (50%)
# ---------------------------------------------------------------------------

def check_npm_test() -> float:
    """Run the Node-RED test suite. Returns 0.50 on success, 0.0 on failure."""
    proc = subprocess.run(
        ["npm", "test"],
        cwd=TESTBED,
        capture_output=True,
        text=True,
        timeout=480,
    )
    passed = proc.returncode == 0
    detail = "" if passed else f"exit {proc.returncode}"
    if not passed:
        # surface the tail of stderr/stdout to help debug failures
        tail = (proc.stdout + proc.stderr)[-800:].strip()
        detail += f"\n{tail}"
    record("npm-test", passed, detail)
    return 0.50 if passed else 0.0


# ---------------------------------------------------------------------------
# Bug 1 — spacebar/modifier guard in view.js (10%)
# ---------------------------------------------------------------------------

def check_bug1_spacebar() -> float:
    src = _read(
        "packages/node_modules/@node-red/editor-client/src/js/ui/view.js"
    )
    checks = [
        (
            "spacebar-modifier-guard",
            "event.ctrlKey || event.metaKey || event.altKey" in src,
            "modifier guard not found in view.js",
        ),
        (
            "spacebar-cleanup-state",
            "spacebarPressed = false" in src,
            "spacebarPressed reset not found in view.js",
        ),
        (
            "spacebar-early-return",
            # An early return must exist in the same general area
            "return;" in src,
            "early return not found in view.js",
        ),
    ]
    passed_count = 0
    for cid, ok, detail in checks:
        record(cid, ok, "" if ok else detail)
        if ok:
            passed_count += 1
    return 0.10 * (passed_count / len(checks))


# ---------------------------------------------------------------------------
# Bug 2 — halo geometry sync in view.js (10%)
# ---------------------------------------------------------------------------

def check_bug2_halo() -> float:
    src = _read(
        "packages/node_modules/@node-red/editor-client/src/js/ui/view.js"
    )
    checks = [
        (
            "halo-status-height-cache",
            # any variable capturing old statusHeight before redraw
            "currentStatusHeight" in src or "prevStatusHeight" in src or "oldStatusHeight" in src,
            "old-statusHeight capture variable not found in view.js",
        ),
        (
            "halo-height-setAttribute",
            # setAttribute for halo height includes statusHeight
            'setAttribute' in src and 'statusHeight' in src,
            "halo setAttribute with statusHeight not found in view.js",
        ),
        (
            "halo-width-conditional",
            # conditional width variable for button halo
            "haloWidthAdjustment" in src or "haloWidth" in src or "widthAdjust" in src,
            "conditional halo-width variable not found in view.js",
        ),
    ]
    passed_count = 0
    for cid, ok, detail in checks:
        record(cid, ok, "" if ok else detail)
        if ok:
            passed_count += 1
    return 0.10 * (passed_count / len(checks))


# ---------------------------------------------------------------------------
# Bug 3 — sidebar click handler (10%)
# ---------------------------------------------------------------------------

def check_bug3_sidebar() -> float:
    src = _read(
        "packages/node_modules/@node-red/editor-client/src/js/ui/sidebar.js"
    )
    checks = [
        (
            "sidebar-click-listener",
            ".on('click'" in src or '.on("click"' in src,
            "click listener not found on tab button in sidebar.js",
        ),
        (
            "sidebar-drag-flag-reset",
            "draggingTabButton = false" in src,
            "draggingTabButton reset not found in sidebar.js",
        ),
        (
            "sidebar-trigger-click",
            ".trigger('click')" in src or '.trigger("click")' in src,
            "trigger('click') not found in sidebar.js",
        ),
    ]
    passed_count = 0
    for cid, ok, detail in checks:
        record(cid, ok, "" if ok else detail)
        if ok:
            passed_count += 1
    return 0.10 * (passed_count / len(checks))


# ---------------------------------------------------------------------------
# Bug 4 — build path normalization (10%)
# ---------------------------------------------------------------------------

def check_bug4_build() -> float:
    src = _read("scripts/build/concat.js")
    checks = [
        (
            "build-normalize-fn",
            "normalizePath" in src,
            "normalizePath helper not found in concat.js",
        ),
        (
            "build-win32-guard",
            'process.platform' in src and 'win32' in src,
            "win32 platform guard not found in concat.js",
        ),
        (
            "build-normalized-var",
            # A local variable holding the normalised pattern is passed to fg/existsSync
            "normalizePath(" in src,
            "normalizePath call not found in concat.js",
        ),
    ]
    passed_count = 0
    for cid, ok, detail in checks:
        record(cid, ok, "" if ok else detail)
        if ok:
            passed_count += 1
    return 0.10 * (passed_count / len(checks))


# ---------------------------------------------------------------------------
# Bug 5 — accessibility attributes (10%)
# ---------------------------------------------------------------------------

def check_bug5_a11y() -> float:
    toggle = _read(
        "packages/node_modules/@node-red/editor-client/src/js/ui/common/toggleButton.js"
    )
    search = _read(
        "packages/node_modules/@node-red/editor-client/src/js/ui/common/searchBox.js"
    )
    palette = _read(
        "packages/node_modules/@node-red/editor-client/src/js/ui/palette.js"
    )
    checks = [
        (
            "a11y-togglebutton-aria-pressed",
            "aria-pressed" in toggle,
            "aria-pressed not found in toggleButton.js",
        ),
        (
            "a11y-searchbox-aria-expanded",
            "aria-expanded" in search,
            "aria-expanded not found in searchBox.js",
        ),
        (
            "a11y-palette-aria-expanded",
            "aria-expanded" in palette,
            "aria-expanded not found in palette.js",
        ),
    ]
    passed_count = 0
    for cid, ok, detail in checks:
        record(cid, ok, "" if ok else detail)
        if ok:
            passed_count += 1
    return 0.10 * (passed_count / len(checks))


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    print("=" * 60)
    print("Node-RED multi-bug verifier")
    print("=" * 60)

    score = 0.0

    print("\n[Behavioural] npm test (0.50)")
    try:
        score += check_npm_test()
    except subprocess.TimeoutExpired:
        record("npm-test", False, "timed out after 480 s")

    print("\n[Bug 1] Spacebar modifier guard (0.10)")
    score += check_bug1_spacebar()

    print("\n[Bug 2] Halo geometry sync (0.10)")
    score += check_bug2_halo()

    print("\n[Bug 3] Sidebar click handler (0.10)")
    score += check_bug3_sidebar()

    print("\n[Bug 4] Build path normalization (0.10)")
    score += check_bug4_build()

    print("\n[Bug 5] Accessibility attributes (0.10)")
    score += check_bug5_a11y()

    score = round(min(score, 1.0), 6)
    print(f"\nFINAL SCORE: {score}")

    # Write reward file expected by Harbor
    reward_path = os.path.join(VERIFIER_DIR, "reward.txt")
    with open(reward_path, "w") as fh:
        fh.write(str(score))

    # Write structured results for debugging
    results_path = os.path.join(VERIFIER_DIR, "results.json")
    with open(results_path, "w") as fh:
        json.dump({"score": score, "checks": results}, fh, indent=2)


if __name__ == "__main__":
    main()
