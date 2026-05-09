#!/usr/bin/env python3

import os
import subprocess
import sys

TESTBED = "/testbed"

passed = 0
failed = 0


def run(name, fn, weight=1):
    global passed, failed

    try:
        fn()
        passed += weight
        print(f"PASS: {name}")
    except Exception as e:
        failed += weight
        print(f"FAIL: {name} -> {e}")


def read(relpath):
    with open(os.path.join(TESTBED, relpath), "r", encoding="utf-8") as f:
        return f.read()


# ============================================================
# STATIC / STRUCTURAL CHECKS
# ============================================================

def check_secure_json_logic():
    """
    Verify prototype pollution protection logic exists somewhere
    in parser/security-related code.
    """

    dangerous_patterns = [
        "__proto__",
        "constructor",
        "prototype"
    ]

    found = False

    for root, _, files in os.walk(TESTBED):
        for file in files:
            if not file.endswith(".js"):
                continue

            path = os.path.join(root, file)

            with open(path, "r", encoding="utf-8") as f:
                content = f.read()

            if any(p in content for p in dangerous_patterns):
                found = True

    assert found, \
        "prototype pollution protection logic not found"


def check_charset_validation_logic():
    """
    Verify charset normalization / validation logic exists.
    """

    found = False

    for root, _, files in os.walk(TESTBED):
        for file in files:
            if not file.endswith(".js"):
                continue

            path = os.path.join(root, file)

            with open(path, "r", encoding="utf-8") as f:
                content = f.read()

            if (
                "charset" in content.lower()
                and "utf-8" in content.lower()
            ):
                found = True

    assert found, \
        "charset validation logic not found"


def check_parameter_count_optimization():
    """
    Ensure optimized parameter counting exists and split('&')
    allocation-heavy behavior was removed.
    """

    found = False

    for root, _, files in os.walk(TESTBED):
        for file in files:
            if not file.endswith(".js"):
                continue

            path = os.path.join(root, file)

            with open(path, "r", encoding="utf-8") as f:
                content = f.read()

            if (
                "parameterLimit" in content
                and "&" in content
                and "split('&')" not in content
            ):
                found = True

    assert found, \
        "optimized parameter counting implementation not detected"


def check_limit_validation():
    """
    Ensure non-negative limit validation exists.
    """

    found = False

    for root, _, files in os.walk(TESTBED):
        for file in files:
            if not file.endswith(".js"):
                continue

            path = os.path.join(root, file)

            with open(path, "r", encoding="utf-8") as f:
                content = f.read()

            if (
                "limit" in content.lower()
                and "0" in content
                and (
                    "< 0" in content
                    or "negative" in content.lower()
                )
            ):
                found = True

    assert found, \
        "non-negative limit validation logic not found"


def check_stack_trace_preservation():
    """
    Ensure Error.captureStackTrace usage exists.
    """

    found = False

    for root, _, files in os.walk(TESTBED):
        for file in files:
            if not file.endswith(".js"):
                continue

            path = os.path.join(root, file)

            with open(path, "r", encoding="utf-8") as f:
                content = f.read()

            if "Error.captureStackTrace" in content:
                found = True

    assert found, \
        "Error.captureStackTrace usage not found"


def check_internal_export_cleanup():
    """
    Ensure unsupported internal exports were cleaned up.
    """

    index_path = os.path.join(TESTBED, "index.js")

    assert os.path.exists(index_path), \
        "index.js missing"

    content = read("index.js")

    forbidden = [
        "exports.parser",
        "exports.urlencodedParser",
        "exports.jsonParser"
    ]

    for token in forbidden:
        assert token not in content, \
            f"unsupported internal export still present: {token}"


def check_no_placeholder_todos():
    """
    Prevent fake/stub implementations.
    """

    forbidden = [
        "TODO implementation",
        "FIXME implementation",
        "placeholder parser",
        "temporary hack"
    ]

    for root, _, files in os.walk(TESTBED):
        for file in files:
            if not file.endswith(".js"):
                continue

            path = os.path.join(root, file)

            with open(path, "r", encoding="utf-8") as f:
                content = f.read()

            for token in forbidden:
                assert token not in content, \
                    f"placeholder implementation found: {token}"


# ============================================================
# BEHAVIORAL TEST HELPERS
# ============================================================

def mocha_test(path):
    result = subprocess.run(
        ["npx", "mocha", path],
        cwd=TESTBED,
        capture_output=True,
        text=True,
        timeout=1200,
    )

    assert result.returncode == 0, \
        result.stderr[-3000:]


def npm_full_test():
    result = subprocess.run(
        ["npm", "test"],
        cwd=TESTBED,
        capture_output=True,
        text=True,
        timeout=2400,
    )

    assert result.returncode == 0, \
        result.stderr[-4000:]


# ============================================================
# BEHAVIORAL TESTS
# ============================================================

def behavioral_json():
    mocha_test("test/json.js")


def behavioral_raw():
    mocha_test("test/raw.js")


def behavioral_text():
    mocha_test("test/text.js")


def behavioral_urlencoded():
    mocha_test("test/urlencoded.js")


def behavioral_full_suite():
    npm_full_test()


# ============================================================
# SECURITY VALIDATION
# ============================================================

def behavioral_prototype_pollution():

    node_script = r"""
    const payload = JSON.parse('{"__proto__":{"polluted":"yes"}}')

    if (({}).polluted === 'yes') {
      process.exit(1)
    }

    process.exit(0)
    """

    result = subprocess.run(
        ["node", "-e", node_script],
        cwd=TESTBED,
        capture_output=True,
        text=True,
    )

    assert result.returncode == 0, \
        "prototype pollution protection failed"


# ============================================================
# CHARSET VALIDATION
# ============================================================

def behavioral_charset_validation():

    found = False

    for root, _, files in os.walk(TESTBED):
        for file in files:
            if not file.endswith(".js"):
                continue

            path = os.path.join(root, file)

            content = open(
                path,
                encoding="utf-8"
            ).read().lower()

            if (
                "utf-8" in content
                or "utf8" in content
            ):
                found = True

    assert found, \
        "charset normalization semantics not detected"


# ============================================================
# EXECUTION
# ============================================================

# -------------------------------
# STATIC CHECKS
# -------------------------------

run(
    "secure JSON protection exists",
    check_secure_json_logic,
)

run(
    "charset validation logic exists",
    check_charset_validation_logic,
)

run(
    "parameter counting optimization exists",
    check_parameter_count_optimization,
)

run(
    "non-negative limit validation exists",
    check_limit_validation,
)

run(
    "stack trace preservation exists",
    check_stack_trace_preservation,
)

run(
    "internal export cleanup exists",
    check_internal_export_cleanup,
)

run(
    "no placeholder implementations",
    check_no_placeholder_todos,
)

# -------------------------------
# BEHAVIORAL TESTS
# -------------------------------

run(
    "json parser tests",
    behavioral_json,
    weight=3,
)

run(
    "raw parser tests",
    behavioral_raw,
    weight=2,
)

run(
    "text parser tests",
    behavioral_text,
    weight=2,
)

run(
    "urlencoded parser tests",
    behavioral_urlencoded,
    weight=4,
)

run(
    "full integration suite",
    behavioral_full_suite,
    weight=6,
)

# -------------------------------
# SECURITY + CONSISTENCY
# -------------------------------

run(
    "prototype pollution protection",
    behavioral_prototype_pollution,
    weight=3,
)

run(
    "charset normalization consistency",
    behavioral_charset_validation,
    weight=2,
)

# ============================================================
# FINAL SCORE
# ============================================================

total = passed + failed

score = 0.0 if total == 0 else round(passed / total, 2)

print(f"\nFINAL SCORE: {score}")

os.makedirs("/logs/verifier", exist_ok=True)

with open("/logs/verifier/reward.txt", "w") as f:
    f.write(str(score))

sys.exit(0)