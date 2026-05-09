#!/usr/bin/env python3

import re
import sys
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


def read(path):
    return path.read_text()

def test_both_forms_updated():
    protection = read(PROTECTION_FORM)
    sessions = read(SESSIONS_FORM)

    assert "3600" in protection, \
        "Protection form missing conversion fix"

    assert "3600" in sessions, \
        "Sessions form missing conversion fix"


def test_submit_payload_transforms_values():
    protection = read(PROTECTION_FORM)
    sessions = read(SESSIONS_FORM)

    assert "payload" in protection
    assert "payload" in sessions

    assert "SESSIONS_TIMEBOX" in protection
    assert "SESSIONS_TIMEBOX" in sessions


#
# -------------------------
# RUN TESTS
# -------------------------
#
check(
    "both forms updated",
    test_both_forms_updated,
    weight=1.0,
)

check(
    "submit payload transforms values",
    test_submit_payload_transforms_values,
    weight=1.0,
)

reward = PASSED_WEIGHT / TOTAL_WEIGHT

print(f"\nReward: {reward:.4f}")
