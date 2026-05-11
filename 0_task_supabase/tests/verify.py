#!/usr/bin/env python3

import re
import sys
import os
from pathlib import Path

TOTAL_WEIGHT = 0.0
PASSED_WEIGHT = 0.0


def check(name, fn, weight=1.0):
    global TOTAL_WEIGHT, PASSED_WEIGHT

    TOTAL_WEIGHT += weight

    try:
        fn()
        PASSED_WEIGHT += weight
        print(f"PASS {name}")
    except AssertionError as e:
        print(f"FAIL {name}: {e}")
    except Exception as e:
        print(f"ERROR {name}: {e}")


ROOT = Path("/testbed")

PROTECTION_FORM = ROOT / "apps/studio/components/interfaces/Auth/ProtectionAuthSettingsForm/ProtectionAuthSettingsForm.tsx"

SESSIONS_FORM = ROOT / "apps/studio/components/interfaces/Auth/SessionsAuthSettingsForm/SessionsAuthSettingsForm.tsx"

AUTHORIZE_SCRIPT = ROOT / "scripts/authorizeVercelDeploys.ts"

def read(path):
    return path.read_text()


#
# =========================================================
# AUTH SETTINGS FORM TESTS
# =========================================================
#

def test_both_forms_updated():
    protection = read(PROTECTION_FORM)
    sessions = read(SESSIONS_FORM)

    assert "3600" in protection, \
        "Protection form missing hour/second conversion logic"

    assert "3600" in sessions, \
        "Sessions form missing hour/second conversion logic"


def test_submit_payload_transforms_values():
    protection = read(PROTECTION_FORM)
    sessions = read(SESSIONS_FORM)

    assert "payload" in protection, \
        "Protection form payload transformation missing"

    assert "payload" in sessions, \
        "Sessions form payload transformation missing"

    assert "SESSIONS_TIMEBOX" in protection, \
        "Protection form missing SESSIONS_TIMEBOX handling"

    assert "SESSIONS_TIMEBOX" in sessions, \
        "Sessions form missing SESSIONS_TIMEBOX handling"

#
# =========================================================
# authorizeVercelDeploys.ts TESTS
# =========================================================
#

def test_github_token_env_handling_exists():
    src = read(AUTHORIZE_SCRIPT)

    assert "GITHUB_TOKEN" in src, \
        "GITHUB_TOKEN environment handling missing"


def test_authorization_header_support_exists():
    src = read(AUTHORIZE_SCRIPT)

    assert "Authorization" in src, \
        "Authorization header support missing"


def test_fetch_called_with_headers():
    src = read(AUTHORIZE_SCRIPT)

    fetch_pattern = r"fetch\s*\([^)]*headers"

    assert re.search(fetch_pattern, src, re.DOTALL), \
        "fetch() is not called with headers options"


def test_authorization_uses_token_scheme():
    src = read(AUTHORIZE_SCRIPT)

    assert re.search(r"token\s*\$\{?\s*process\.env\.GITHUB_TOKEN", src), \
        "Authorization header does not use GitHub token scheme"


def test_headers_object_created():
    src = read(AUTHORIZE_SCRIPT)

    assert re.search(r"headers\s*:\s*Record<", src) or "headers =" in src, \
        "Headers object creation missing"


def test_github_status_url_preserved():
    src = read(AUTHORIZE_SCRIPT)

    expected = "https://api.github.com/repos/supabase/supabase/statuses"

    assert expected in src, \
        "GitHub status URL changed unexpectedly"


def test_fetch_still_checks_response_status():
    src = read(AUTHORIZE_SCRIPT)

    assert "response.ok" in src, \
        "Response status validation missing after auth changes"


#
# =========================================================
# PARTIAL FIX DETECTION
# =========================================================
#

def test_auth_header_is_conditional():
    src = read(AUTHORIZE_SCRIPT)

    conditional_pattern = r"if\s*\(\s*process\.env\.GITHUB_TOKEN\s*\)"

    assert re.search(conditional_pattern, src), \
        "Authorization header is not conditionally applied"


def test_no_hardcoded_token():
    src = read(AUTHORIZE_SCRIPT)

    assert "ghp_" not in src, \
        "Hardcoded GitHub token detected"


#
# =========================================================
# RUN TESTS
# =========================================================
#

#
# Auth settings conversion tests
#

check(
    "both auth forms updated",
    test_both_forms_updated,
    weight=1.0,
)

check(
    "submit payload transforms values",
    test_submit_payload_transforms_values,
    weight=1.0,
)

#
# authorizeVercelDeploys tests
#

check(
    "github token environment handling exists",
    test_github_token_env_handling_exists,
    weight=1.0,
)

check(
    "authorization header support exists",
    test_authorization_header_support_exists,
    weight=1.0,
)

check(
    "fetch called with headers",
    test_fetch_called_with_headers,
    weight=2.0,
)

check(
    "authorization uses token auth scheme",
    test_authorization_uses_token_scheme,
    weight=1.5,
)

check(
    "headers object created",
    test_headers_object_created,
    weight=1.0,
)

check(
    "github status url preserved",
    test_github_status_url_preserved,
    weight=1.0,
)

check(
    "response status validation preserved",
    test_fetch_still_checks_response_status,
    weight=1.0,
)

check(
    "auth header applied conditionally",
    test_auth_header_is_conditional,
    weight=1.5,
)

check(
    "no hardcoded token present",
    test_no_hardcoded_token,
    weight=1.0,
)

reward = PASSED_WEIGHT / TOTAL_WEIGHT if TOTAL_WEIGHT else 0.0

print(f"\nReward: {reward:.4f}")

os.makedirs("/logs/verifier", exist_ok=True)
with open("/logs/verifier/reward.txt", "w") as f:
    f.write(str(reward))

sys.exit(0)