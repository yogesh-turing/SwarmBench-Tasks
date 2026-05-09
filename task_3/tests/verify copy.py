#!/usr/bin/env python3
"""
Verify that the Firebug Lite security issue is fixed in Lodash.

Checks:
1. firebug-lite-debug.js is removed OR not usable
2. Dangerous textEditorInner input is not exposed
3. File is not referenced in test/HTML files
4. No unsafe inline console execution surface remains
"""

import os
import re

LODASH_DIR = "/lodash"
sys.path.insert(0, os.path.join(LODASH_DIR, "src"))

passed = 0
total = 0


def check(name, fn):
    global passed, total
    total += 1
    try:
        fn()
        print(f"  PASS  {name}")
        passed += 1
    except Exception as e:
        print(f"  FAIL  {name}: {e}")


# ---------------------------------------------------------------------------
# Utility helpers
# ---------------------------------------------------------------------------
def read_file(path):
    with open(path, "r", encoding="utf-8", errors="ignore") as f:
        return f.read()


def file_exists(path):
    return os.path.exists(path)


# ---------------------------------------------------------------------------
# Check 1: firebug-lite-debug.js removed OR sanitized
# ---------------------------------------------------------------------------
def test_firebug_file_removed_or_disabled():
    path = os.path.join(
        LODASH_DIR,
        "vendor/firebug-lite/src/firebug-lite-debug.js"
    )

    if not file_exists(path):
        return  # acceptable: file removed

    content = read_file(path)

    # If file exists, it must NOT contain dangerous editor input
    assert "textEditorInner" not in content, (
        "firebug-lite-debug.js still contains 'textEditorInner' input element "
        "which allows arbitrary JS execution."
    )


# ---------------------------------------------------------------------------
# Check 2: No unsafe input/editor surface
# ---------------------------------------------------------------------------
def test_no_text_editor_input():
    path = os.path.join(
        LODASH_DIR,
        "vendor/firebug-lite/src/firebug-lite-debug.js"
    )

    if not file_exists(path):
        return

    content = read_file(path)

    dangerous_patterns = [
        "textEditorInner",
        "contentEditable",
        "eval(",
        "new Function("
    ]

    for pattern in dangerous_patterns:
        assert pattern not in content, (
            f"Unsafe pattern '{pattern}' still present in firebug-lite-debug.js"
        )


# ---------------------------------------------------------------------------
# Check 3: File is not referenced in HTML/test files
# ---------------------------------------------------------------------------
def test_no_firebug_script_reference():
    html_files = []

    for root, _, files in os.walk(LODASH_DIR):
        for f in files:
            if f.endswith(".html"):
                html_files.append(os.path.join(root, f))

    for file in html_files:
        content = read_file(file)

        assert "firebug-lite-debug.js" not in content, (
            f"{file} still references firebug-lite-debug.js. "
            "This exposes the debug console in runtime."
        )


# ---------------------------------------------------------------------------
# Check 4: No dynamic injection of Firebug Lite
# ---------------------------------------------------------------------------
def test_no_dynamic_firebug_injection():
    js_files = []

    for root, _, files in os.walk(LODASH_DIR):
        for f in files:
            if f.endswith(".js"):
                js_files.append(os.path.join(root, f))

    for file in js_files:
        content = read_file(file)

        # Detect script injection patterns
        if "firebug-lite" in content.lower():
            assert False, (
                f"{file} contains dynamic reference to Firebug Lite. "
                "Debug tools must not be injected dynamically."
            )


# ---------------------------------------------------------------------------
# Check 5: Regression — lodash still usable
# ---------------------------------------------------------------------------
def test_lodash_basic_usage():
    import subprocess
    import tempfile
    import json

    js_code = """
    const _ = require('./lodash.js');

    const result = _.map([1,2,3], x => x * 2);
    console.log(JSON.stringify(result));
    """

    with tempfile.NamedTemporaryFile(delete=False, suffix=".js") as f:
        f.write(js_code.encode())
        temp_file = f.name

    try:
        output = subprocess.check_output(
            ["node", temp_file],
            cwd=LODASH_DIR
        ).decode().strip()

        assert json.loads(output) == [2, 4, 6], (
            "Lodash functionality broken after security fix"
        )

    except Exception as e:
        raise AssertionError(f"Lodash execution failed: {e}")


# ---------------------------------------------------------------------------
# Helper to run Node.js code
# ---------------------------------------------------------------------------
def run_node(code):
    with tempfile.NamedTemporaryFile(delete=False, suffix=".js") as f:
        f.write(code.encode())
        path = f.name

    try:
        output = subprocess.check_output(
            ["node", path],
            cwd=LODASH_DIR
        ).decode().strip()
        return output
    except Exception as e:
        raise AssertionError(f"Node execution failed: {e}")


# ---------------------------------------------------------------------------
# Check 1: &#38; decodes to &
# ---------------------------------------------------------------------------
def test_decimal_ampersand_entity():
    code = """
    const _ = require('./lodash.js');
    console.log(_.unescape('&#38;'));
    """
    output = run_node(code)

    assert output == "&", (
        f"Expected '&#38;' to decode to '&', got '{output}'"
    )


# ---------------------------------------------------------------------------
# Check 2: Standard entities still work
# ---------------------------------------------------------------------------
def test_standard_entities():
    code = """
    const _ = require('./lodash.js');
    console.log(JSON.stringify([
        _.unescape('&amp;'),
        _.unescape('&lt;'),
        _.unescape('&gt;'),
        _.unescape('&quot;'),
        _.unescape('&#39;')
    ]));
    """
    output = run_node(code)
    result = json.loads(output)

    expected = ["&", "<", ">", "\"", "'"]

    assert result == expected, (
        f"Standard entities broken. Expected {expected}, got {result}"
    )


# ---------------------------------------------------------------------------
# Check 3: Mixed string decoding
# ---------------------------------------------------------------------------
def test_mixed_string():
    code = """
    const _ = require('./lodash.js');
    const str = 'Hello &#38; welcome &lt;user&gt;';
    console.log(_.unescape(str));
    """
    output = run_node(code)

    assert output == "Hello & welcome <user>", (
        f"Mixed entity decoding failed, got '{output}'"
    )


# ---------------------------------------------------------------------------
# Check 4: Double decode safety (no over-decoding)
# ---------------------------------------------------------------------------
def test_no_overdecode():
    code = """
    const _ = require('./lodash.js');
    const once = _.unescape('&amp;');
    const twice = _.unescape(once);
    console.log(JSON.stringify([once, twice]));
    """
    output = run_node(code)
    once, twice = json.loads(output)

    assert once == "&", "First unescape failed"
    assert twice == "&", (
        "Second unescape changed value incorrectly (over-decoding bug)"
    )


# ---------------------------------------------------------------------------
# Check 5: Regression — escape/unescape roundtrip
# ---------------------------------------------------------------------------
def test_escape_unescape_roundtrip():
    code = """
    const _ = require('./lodash.js');
    const str = '<div>& "test"</div>';
    const escaped = _.escape(str);
    const unescaped = _.unescape(escaped);
    console.log(unescaped);
    """
    output = run_node(code)

    assert output == '<div>& "test"</div>', (
        "escape/unescape roundtrip failed"
    )



# ---------------------------------------------------------------------------
# Check 1: clone preserves own hasOwnProperty
# ---------------------------------------------------------------------------
def test_clone_preserves_shadowed_property():
    code = """
    const _ = require('./lodash.js');

    const obj = { hasOwnProperty: 'custom-value' };
    const cloned = _.clone(obj);

    console.log(cloned.hasOwnProperty);
    """
    output = run_node(code)

    assert output == "custom-value", (
        "_.clone dropped own 'hasOwnProperty' property"
    )


# ---------------------------------------------------------------------------
# Check 2: cloneDeep preserves shadowed property
# ---------------------------------------------------------------------------
def test_cloneDeep_preserves_shadowed_property():
    code = """
    const _ = require('./lodash.js');

    const obj = { hasOwnProperty: 'deep-value' };
    const cloned = _.cloneDeep(obj);

    console.log(cloned.hasOwnProperty);
    """
    output = run_node(code)

    assert output == "deep-value", (
        "_.cloneDeep dropped own 'hasOwnProperty' property"
    )


# ---------------------------------------------------------------------------
# Check 3: Works when Object.prototype is frozen
# ---------------------------------------------------------------------------
def test_clone_with_frozen_prototype():
    code = """
    const _ = require('./lodash.js');

    Object.freeze(Object.prototype);

    const obj = { hasOwnProperty: 'frozen-case' };
    const cloned = _.clone(obj);

    console.log(cloned.hasOwnProperty);
    """
    output = run_node(code)

    assert output == "frozen-case", (
        "_.clone failed when Object.prototype is frozen"
    )


# ---------------------------------------------------------------------------
# Check 4: cloneDeep with frozen prototype + nested object
# ---------------------------------------------------------------------------
def test_cloneDeep_nested_frozen():
    code = """
    const _ = require('./lodash.js');

    Object.freeze(Object.prototype);

    const obj = {
        nested: {
            hasOwnProperty: 'nested-value'
        }
    };

    const cloned = _.cloneDeep(obj);

    console.log(cloned.nested.hasOwnProperty);
    """
    output = run_node(code)

    assert output == "nested-value", (
        "_.cloneDeep failed for nested object with frozen prototype"
    )


# ---------------------------------------------------------------------------
# Check 5: No TypeError thrown in strict mode
# ---------------------------------------------------------------------------
def test_no_type_error_strict_mode():
    code = """
    'use strict';
    const _ = require('./lodash.js');

    Object.freeze(Object.prototype);

    const obj = { hasOwnProperty: 'strict-mode' };

    try {
        const cloned = _.clone(obj);
        console.log(cloned.hasOwnProperty);
    } catch (e) {
        console.log("ERROR");
    }
    """
    output = run_node(code)

    assert output != "ERROR", (
        "_.clone throws TypeError in strict mode with frozen prototype"
    )


# ---------------------------------------------------------------------------
# Check 6: Regression — normal cloning still works
# ---------------------------------------------------------------------------
def test_normal_clone_regression():
    code = """
    const _ = require('./lodash.js');

    const obj = { a: 1, b: 2 };
    const cloned = _.clone(obj);

    console.log(JSON.stringify(cloned));
    """
    output = run_node(code)

    assert json.loads(output) == {"a": 1, "b": 2}, (
        "Normal cloning behavior broken"
    )

# ---------------------------------------------------------------------------
# Known typo list (from task)
# ---------------------------------------------------------------------------
TYPOS = [
    "occurances",
    "acess",
    "intance",
    "acessible",
    "remvove",
    "beeing",
    "shoud",
    "insted",
    "agressively",
    "overriden",
    "comparisions",
    "seperately",
    "delimeters"
]

# ---------------------------------------------------------------------------
# Helper: scan all files
# ---------------------------------------------------------------------------
def scan_repo():
    matches = []

    for root, _, files in os.walk(LODASH_DIR):
        for f in files:
            path = os.path.join(root, f)

            # Skip binaries / minified large files
            if any(ext in f for ext in [".png", ".jpg", ".lock", ".min.js"]):
                continue

            try:
                with open(path, "r", encoding="utf-8", errors="ignore") as file:
                    content = file.read().lower()

                    for typo in TYPOS:
                        if re.search(r"\b" + typo + r"\b", content):
                            matches.append((path, typo))
            except:
                continue

    return matches


# ---------------------------------------------------------------------------
# Check 1: No typos remain
# ---------------------------------------------------------------------------
def test_no_known_typos():
    matches = scan_repo()

    assert not matches, (
        f"Found unresolved typos: {matches[:5]} (showing first 5)"
    )


# ---------------------------------------------------------------------------
# Check 2: Case-insensitive check
# ---------------------------------------------------------------------------
def test_no_typos_case_insensitive():
    matches = scan_repo()

    assert len(matches) == 0, (
        "Typos still present (case-insensitive scan)"
    )


# ---------------------------------------------------------------------------
# Check 3: lodash.js still exists
# ---------------------------------------------------------------------------
def test_lodash_file_exists():
    path = os.path.join(LODASH_DIR, "lodash.js")

    assert os.path.exists(path), (
        "lodash.js missing after typo fixes"
    )


# ---------------------------------------------------------------------------
# Check 4: Basic lodash functionality
# ---------------------------------------------------------------------------
def test_lodash_execution():
    code = """
    const _ = require('./lodash.js');
    console.log(_.join(['a', 'b', 'c'], '-'));
    """

    with tempfile.NamedTemporaryFile(delete=False, suffix=".js") as f:
        f.write(code.encode())
        temp_file = f.name

    try:
        output = subprocess.check_output(
            ["node", temp_file],
            cwd=LODASH_DIR
        ).decode().strip()

        assert output == "a-b-c", (
            "Basic lodash functionality broken after typo fixes"
        )

    except Exception as e:
        raise AssertionError(f"Node execution failed: {e}")


# ---------------------------------------------------------------------------
# Check 5: Ensure no accidental keyword corruption
# ---------------------------------------------------------------------------
def test_no_keyword_corruption():
    path = os.path.join(LODASH_DIR, "lodash.js")

    with open(path, "r", encoding="utf-8", errors="ignore") as f:
        content = f.read()

    # sanity checks for critical keywords
    required_keywords = ["function", "return", "var", "if"]

    for kw in required_keywords:
        assert kw in content, (
            f"Critical keyword '{kw}' missing — possible bad replacement"
        )



# ---------------------------------------------------------------------------
# Run checks
# ---------------------------------------------------------------------------
check("Firebug file removed or sanitized", test_firebug_file_removed_or_disabled)
check("No unsafe editor/input surface", test_no_text_editor_input)
check("No Firebug script references in HTML", test_no_firebug_script_reference)
check("No remaining inline console execution surface", test_no_inline_console)

check("Decimal entity &#38; decoded correctly", test_decimal_ampersand_entity)
check("Standard entities still work", test_standard_entities)
check("Mixed string decoding works", test_mixed_string)
check("No over-decoding occurs", test_no_overdecode)
check("escape/unescape roundtrip works", test_escape_unescape_roundtrip)

check("clone preserves shadowed property", test_clone_preserves_shadowed_property)
check("cloneDeep preserves shadowed property", test_cloneDeep_preserves_shadowed_property)
check("clone works with frozen prototype", test_clone_with_frozen_prototype)
check("cloneDeep nested + frozen prototype", test_cloneDeep_nested_frozen)
check("no TypeError in strict mode", test_no_type_error_strict_mode)
check("regression: normal clone works", test_normal_clone_regression)

check("No known typos remain", test_no_known_typos)
check("No typos (case insensitive)", test_no_typos_case_insensitive)
check("lodash.js exists", test_lodash_file_exists)
check("Lodash execution works", test_lodash_execution)
check("No keyword corruption", test_no_keyword_corruption)

reward = passed / total
print(f"\nResult: {passed}/{total} checks passed")
print(f"Reward: {reward:.4f}")

os.makedirs("/logs/verifier", exist_ok=True)
with open("/logs/verifier/reward.txt", "w") as f:
    f.write(str(reward))

sys.exit(0)
