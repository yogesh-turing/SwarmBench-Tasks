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

MAGNIFIED_PRODUCTS = ROOT / "apps/www/components/MagnifiedProducts.tsx"

COLOR_PALETTE_COMPONENT = ROOT / "apps/design-system/components/color-palette.tsx"

MDX_COMPONENTS = ROOT / "apps/design-system/components/mdx-components.tsx"

COLOR_USAGE_DOC = ROOT / "apps/design-system/content/docs/color-usage.mdx"

def read(path):
    return path.read_text()


#
# =========================================================
# AUTH SETTINGS FORM TESTS
# =========================================================
#

def test_both_forms_have_conversion_functions():
    protection = read(PROTECTION_FORM)
    sessions = read(SESSIONS_FORM)

    # Must define secondsToHours and hoursToSeconds functions
    assert "secondsToHours" in protection and "hoursToSeconds" in protection, \
        "Protection form missing conversion function definitions"

    assert "secondsToHours" in sessions and "hoursToSeconds" in sessions, \
        "Sessions form missing conversion function definitions"


def test_form_reset_uses_seconds_to_hours():
    protection = read(PROTECTION_FORM)
    sessions = read(SESSIONS_FORM)

    # Reset/initialize must convert from backend seconds to UI hours
    assert re.search(r"SESSIONS_TIMEBOX\s*:\s*secondsToHours", protection, re.DOTALL), \
        "Protection form reset does not convert SESSIONS_TIMEBOX to hours"

    assert re.search(r"SESSIONS_TIMEBOX\s*:\s*secondsToHours", sessions, re.DOTALL), \
        "Sessions form reset does not convert SESSIONS_TIMEBOX to hours"


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


def test_submit_payload_uses_hours_to_seconds():
    protection = read(PROTECTION_FORM)
    sessions = read(SESSIONS_FORM)

    # onSubmit must convert from UI hours back to backend seconds
    assert re.search(r"SESSIONS_TIMEBOX\s*:\s*hoursToSeconds", protection, re.DOTALL), \
        "Protection form submit does not convert SESSIONS_TIMEBOX hours to seconds"

    assert re.search(r"SESSIONS_TIMEBOX\s*:\s*hoursToSeconds", sessions, re.DOTALL), \
        "Sessions form submit does not convert SESSIONS_TIMEBOX hours to seconds"

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


def test_headers_variable_initialized():
    src = read(AUTHORIZE_SCRIPT)

    # Must explicitly create headers object before conditional
    assert re.search(r"const\s+headers\s*[:=].*\{\s*\}", src, re.DOTALL), \
        "headers object not properly initialized as empty object"


def test_authorization_uses_token_scheme():
    src = read(AUTHORIZE_SCRIPT)

    assert re.search(r"token\s*\$\{\s*process\.env\.GITHUB_TOKEN\s*\}", src), \
        "Authorization header does not use GitHub token scheme (template literal)"


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

    # Must have if block that checks GITHUB_TOKEN and assigns headers conditionally
    conditional_pattern = r"if\s*\(\s*process\.env\.GITHUB_TOKEN\s*\)\s*\{[^}]*headers"

    assert re.search(conditional_pattern, src, re.DOTALL), \
        "Authorization header is not conditionally applied or if block missing"


def test_no_hardcoded_token():
    src = read(AUTHORIZE_SCRIPT)

    assert "ghp_" not in src, \
        "Hardcoded GitHub token detected"


#
# =========================================================
# MagnifiedProducts.tsx TESTS (bug 3)
# =========================================================
#

def test_vector_link_points_to_modules_path():
    src = read(MAGNIFIED_PRODUCTS)

    assert "url: '/modules/vector'" in src or 'url: "/modules/vector"' in src, \
        "Vector product link is not updated to /modules/vector"

    assert "url: '/vector'" not in src and 'url: "/vector"' not in src, \
        "Legacy /vector link still present"


#
# =========================================================
# Design system color palette TESTS (feat 1)
# =========================================================
#

def test_color_palette_component_file_exists():
    assert COLOR_PALETTE_COMPONENT.exists(), \
        "color-palette.tsx component file is missing"


def test_color_palette_component_has_state():
    src = read(COLOR_PALETTE_COMPONENT)

    # Component must manage copy state
    assert "useState" in src, \
        "ColorPalette missing useState hook"
    
    assert "copied" in src, \
        "ColorPalette missing copied state variable"


def test_color_palette_handles_click():
    src = read(COLOR_PALETTE_COMPONENT)

    # Component must handle button clicks for copying
    assert "handleCopy" in src or "onClick" in src, \
        "ColorPalette missing click handler for color swatches"
    
    assert "navigator.clipboard" in src, \
        "ColorPalette not using clipboard API"


def test_mdx_components_exports_palette_in_map():
    src = read(MDX_COMPONENTS)

    # ColorPalette must be registered as a property in the components object
    # Check that it appears as a key with trailing comma (object property syntax)
    assert re.search(r"Colors,\s*\n\s*ColorPalette,", src), \
        "ColorPalette not added as property in components object after Colors"


def test_mdx_components_registers_color_palette():
    src = read(MDX_COMPONENTS)

    assert "import { ColorPalette } from '@/components/color-palette'" in src, \
        "mdx-components.tsx missing ColorPalette import"

    assert re.search(r"\bColorPalette\b", src), \
        "ColorPalette not referenced in mdx components map"


def test_color_usage_doc_references_palette():
    src = read(COLOR_USAGE_DOC)

    assert "## Color palette" in src, \
        "color-usage.mdx missing Color palette section heading"

    assert "<ColorPalette />" in src, \
        "color-usage.mdx missing ColorPalette component usage"
    
    # Ensure the palette section has descriptive content
    assert "Radix scale" in src or "--colors-" in src, \
        "color-usage.mdx Color palette section missing documentation"


#
# =========================================================
# RUN TESTS
# =========================================================
#

#
# Auth settings conversion tests
#

check(
    "both auth forms have conversion functions",
    test_both_forms_have_conversion_functions,
    weight=1.5,
)

check(
    "form reset uses seconds to hours",
    test_form_reset_uses_seconds_to_hours,
    weight=1.5,
)

check(
    "submit payload transforms values",
    test_submit_payload_transforms_values,
    weight=1.0,
)

check(
    "submit payload uses hours to seconds",
    test_submit_payload_uses_hours_to_seconds,
    weight=1.5,
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
    "headers variable initialized",
    test_headers_variable_initialized,
    weight=1.0,
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

check(
    "vector link points to modules path",
    test_vector_link_points_to_modules_path,
    weight=1.5,
)

check(
    "color palette component file exists",
    test_color_palette_component_file_exists,
    weight=1.0,
)

check(
    "color palette component has state",
    test_color_palette_component_has_state,
    weight=1.0,
)

check(
    "color palette handles click",
    test_color_palette_handles_click,
    weight=1.5,
)

check(
    "mdx components exports palette in map",
    test_mdx_components_exports_palette_in_map,
    weight=1.5,
)

check(
    "mdx components registers color palette",
    test_mdx_components_registers_color_palette,
    weight=1.0,
)

check(
    "color usage doc references palette",
    test_color_usage_doc_references_palette,
    weight=1.0,
)

reward = PASSED_WEIGHT / TOTAL_WEIGHT if TOTAL_WEIGHT else 0.0

print(f"\nReward: {reward:.4f}")

os.makedirs("/logs/verifier", exist_ok=True)
with open("/logs/verifier/reward.txt", "w") as f:
    f.write(str(reward))

sys.exit(0)