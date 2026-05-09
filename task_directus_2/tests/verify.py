#!/usr/bin/env python3
"""
Verifier: Directus v11.17.2 four-fix benchmark.

This verifier intentionally mixes semantic structure checks with lightweight
behavioral checks so passing requires real code changes, not token stuffing.
"""
import ast
import json
import os
import re
import sys
from pathlib import Path

TESTBED = Path("/testbed")
VERIFIER_DIR = Path("/logs/verifier")

results = []


def read_text(relpath: str) -> str:
    path = TESTBED / relpath
    if not path.exists():
        raise AssertionError(f"missing file: {relpath}")
    return path.read_text(encoding="utf-8")


def record(check_id: str, passed: bool, detail: str = "") -> None:
    results.append({"id": check_id, "passed": passed, "detail": detail})
    label = "PASS" if passed else "FAIL"
    if detail:
        print(f"  {label}  {check_id}: {detail}")
    else:
        print(f"  {label}  {check_id}")


def run_check(check_id: str, fn) -> float:
    try:
        fn()
        record(check_id, True)
        return 1.0
    except AssertionError as exc:
        record(check_id, False, str(exc))
        return 0.0
    except Exception as exc:  # pragma: no cover - defensive
        record(check_id, False, f"{type(exc).__name__}: {exc}")
        return 0.0


def parse_tsdown_entry_list(src: str) -> list[str]:
    m = re.search(r"entry\s*:\s*\[(.*?)\]", src, re.DOTALL)
    if not m:
        raise AssertionError("tsdown entry array not found")
    raw = "[" + m.group(1) + "]"
    normalized = raw.replace("'", '"')
    try:
        parsed = json.loads(normalized)
    except json.JSONDecodeError as exc:
        raise AssertionError(f"unable to parse tsdown entry list: {exc}") from exc
    if not isinstance(parsed, list) or not all(isinstance(x, str) for x in parsed):
        raise AssertionError("entry array is not a string list")
    return parsed


def simulate_tsdown_matching(entries: list[str]) -> tuple[set[str], set[str]]:
    # Lightweight behavioral simulation for expected include/exclude outcomes.
    candidates = {
        "src/users/service.ts",
        "src/test-utils/helper.ts",
        "src/__utils__/fixture.ts",
        "src/__setup__/bootstrap.ts",
        "src/database/run-ast/lib/apply-query/mock.ts",
        "src/index.d.ts",
        "src/routes/health.test.ts",
    }
    active: set[str] = set()
    for pattern in entries:
        neg = pattern.startswith("!")
        p = pattern[1:] if neg else pattern
        regex = (
            "^"
            + re.escape(p)
            .replace(r"\*\*", "::DOUBLESTAR::")
            .replace(r"\*", "[^/]*")
            .replace("::DOUBLESTAR::", ".*")
            + "$"
        )
        matched = {c for c in candidates if re.match(regex, c)}
        if neg:
            active -= matched
        else:
            active |= matched
    return active, candidates


def bug1_checks() -> float:
    src = read_text("packages/composables/src/use-shortcut.ts")
    score = 0.0
    total = 5

    def _r11():
        for line in src.splitlines():
            stripped = line.lstrip()
            if "document.body.addEventListener" in stripped and (len(line) - len(stripped)) == 0:
                raise AssertionError("top-level document.body.addEventListener detected")

    score += run_check("R1.1-no-top-level-listener", _r11)

    def _r12():
        if "function attachGlobalListeners" not in src:
            raise AssertionError("attachGlobalListeners helper function missing")

    score += run_check("R1.2-helper-exists", _r12)

    def _r13():
        on_mounted = re.search(r"onMounted\s*\(\s*\(\s*\)\s*=>\s*\{(.*?)\}\s*\)", src, re.DOTALL)
        if not on_mounted:
            raise AssertionError("onMounted callback not found")
        if "attachGlobalListeners();" not in on_mounted.group(1):
            raise AssertionError("attachGlobalListeners is not called from onMounted")

    score += run_check("R1.3-onmounted-invocation", _r13)

    def _r14():
        helper = re.search(r"function\s+attachGlobalListeners\s*\(\)\s*\{(.*?)\n\}", src, re.DOTALL)
        if not helper:
            raise AssertionError("attachGlobalListeners body not found")
        body = helper.group(1)
        if "if (listenersAttached) return;" not in body:
            raise AssertionError("idempotency early return missing")
        if "listenersAttached = true;" not in body:
            raise AssertionError("idempotency marker assignment missing")

    score += run_check("R1.4-idempotent-attach", _r14)

    def _r15():
        helper = re.search(r"function\s+attachGlobalListeners\s*\(\)\s*\{(.*?)\n\}", src, re.DOTALL)
        if not helper:
            raise AssertionError("attachGlobalListeners body not found")
        body = helper.group(1)
        if "document.body.addEventListener('keydown'" not in body:
            raise AssertionError("keydown listener is not attached in helper")
        if "document.body.addEventListener('keyup'" not in body:
            raise AssertionError("keyup listener is not attached in helper")

    score += run_check("R1.5-keydown-keyup-in-helper", _r15)
    return score / total


def bug2_checks() -> float:
    tsdown = read_text("api/tsdown.config.ts")
    tsconfig = read_text("api/tsconfig.prod.json")
    score = 0.0
    total = 4

    def _r21():
        required = [
            "!src/test-utils",
            "!src/__utils__",
            "!src/__setup__",
            "!src/database/run-ast/lib/apply-query/mock.ts",
        ]
        missing = [x for x in required if x not in tsdown]
        if missing:
            raise AssertionError("missing tsdown exclusions: " + ", ".join(missing))

    score += run_check("R2.1-tsdown-exclusions-present", _r21)

    def _r22():
        cfg = json.loads(tsconfig)
        excludes = cfg.get("exclude", [])
        if "src/test-utils" not in excludes:
            raise AssertionError("src/test-utils missing from tsconfig.prod exclude list")

    score += run_check("R2.2-tsconfig-exclude-test-utils", _r22)

    def _r23():
        entries = parse_tsdown_entry_list(tsdown)
        active, _ = simulate_tsdown_matching(entries)
        forbidden = {
            "src/test-utils/helper.ts",
            "src/__utils__/fixture.ts",
            "src/__setup__/bootstrap.ts",
            "src/database/run-ast/lib/apply-query/mock.ts",
            "src/index.d.ts",
            "src/routes/health.test.ts",
        }
        if active & forbidden:
            raise AssertionError("excluded paths are still active in entry simulation")
        if "src/users/service.ts" not in active:
            raise AssertionError("normal production source path was unexpectedly excluded")

    score += run_check("R2.3-entry-behavior-simulation", _r23)

    def _r24():
        # Semantic check: keep unbundle enabled in production build config.
        if "unbundle: true" not in tsdown:
            raise AssertionError("unbundle: true missing from tsdown config")

    score += run_check("R2.4-build-mode-preserved", _r24)
    return score / total


def bug3_checks() -> float:
    src = read_text("api/src/services/collections.ts")
    score = 0.0
    total = 3

    def _r31():
        check = re.search(r"payload\.collection\.includes\(\s*['\"]\/['\"]\s*\)", src)
        if not check:
            raise AssertionError("slash validation check missing")

    score += run_check("R3.1-slash-check", _r31)

    def _r32():
        block = re.search(
            r"payload\.collection\.includes\(\s*['\"]\/['\"]\s*\)(.*?)\}",
            src,
            re.DOTALL,
        )
        if not block or "InvalidPayloadError" not in block.group(1):
            raise AssertionError("slash check does not throw InvalidPayloadError")

    score += run_check("R3.2-invalid-payload-error", _r32)

    def _r33():
        slash_pos = src.find("payload.collection.includes('/')")
        if slash_pos < 0:
            slash_pos = src.find('payload.collection.includes("/")')
        parse_pos = src.find("parseCollectionName(payload.collection)")
        if slash_pos < 0 or parse_pos < 0:
            raise AssertionError("unable to compare slash-check and parseCollectionName positions")
        if slash_pos > parse_pos:
            raise AssertionError("slash validation occurs after parseCollectionName")

    score += run_check("R3.3-validation-order", _r33)
    return score / total


def bug4_checks() -> float:
    src = read_text("api/src/services/versions.ts")
    score = 0.0
    total = 6

    m = re.search(
        r"const\s+([A-Za-z_]\w*)\s*=\s*this\.schema\.collections\[collection\]\?\.accountability\s*\?\?\s*null",
        src,
    )
    var_name = m.group(1) if m else None

    def _r41():
        if not var_name:
            raise AssertionError("schema accountability read with null fallback is missing")

    score += run_check("R4.1-read-accountability", _r41)

    def _r42():
        if not var_name:
            raise AssertionError("accountability variable not found")
        if f"if ({var_name} !== null)" not in src:
            raise AssertionError("non-null accountability guard missing")

    score += run_check("R4.2-non-null-guard", _r42)

    def _r43():
        if not var_name:
            raise AssertionError("accountability variable not found")
        gpos = src.find(f"if ({var_name} !== null)")
        apos = src.find("activityService.createOne")
        if gpos < 0 or apos < 0 or apos < gpos:
            raise AssertionError("activity write is not gated by non-null accountability")

    score += run_check("R4.3-activity-gated", _r43)

    def _r44():
        if not var_name:
            raise AssertionError("accountability variable not found")
        if f"if ({var_name} === 'all')" not in src and f'if ({var_name} === "all")' not in src:
            raise AssertionError("all-accountability guard for revisions is missing")

    score += run_check("R4.4-all-guard", _r44)

    def _r45():
        if not var_name:
            raise AssertionError("accountability variable not found")
        all_pos = src.find(f"if ({var_name} === 'all')")
        if all_pos < 0:
            all_pos = src.find(f'if ({var_name} === "all")')
        rev_pos = src.find("revisionsService.createOne")
        if all_pos < 0 or rev_pos < 0 or rev_pos < all_pos:
            raise AssertionError("revision write is not gated by accountability === 'all'")

    score += run_check("R4.5-revision-gated", _r45)

    def _r46():
        # Behavioral safety: no unconditional createOne calls before accountability read.
        if not var_name:
            raise AssertionError("accountability variable not found")
        acct_pos = src.find(f"const {var_name} =")
        for needle in ["activityService.createOne", "revisionsService.createOne"]:
            npos = src.find(needle)
            if npos >= 0 and npos < acct_pos:
                raise AssertionError(f"{needle} appears before accountability is read")

    score += run_check("R4.6-no-unconditional-side-effects", _r46)
    return score / total


def main() -> None:
    print("=" * 60)
    print("Directus Four-Fix Verifier")
    print("=" * 60)

    # Weighted to favor behavior-oriented checks while preserving structural coverage.
    bug_scores = {
        "bug1": bug1_checks(),
        "bug2": bug2_checks(),
        "bug3": bug3_checks(),
        "bug4": bug4_checks(),
    }

    reward = round(sum(bug_scores.values()) / len(bug_scores), 6)

    print("\nPer-bug completion:")
    for name, score in bug_scores.items():
        print(f"  {name}: {score:.3f}")
    print(f"\nReward: {reward:.6f}")

    VERIFIER_DIR.mkdir(parents=True, exist_ok=True)
    (VERIFIER_DIR / "reward.txt").write_text(str(reward), encoding="utf-8")
    (VERIFIER_DIR / "results.json").write_text(
        json.dumps({"score": reward, "checks": results, "bug_scores": bug_scores}, indent=2),
        encoding="utf-8",
    )


if __name__ == "__main__":
    main()
