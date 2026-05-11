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


def assert_contains_any(src, patterns, msg):
    for pattern in patterns:
        if re.search(pattern, src, re.DOTALL):
            return
    raise AssertionError(msg)


#
# =========================================================
# AUTH SETTINGS FORM TESTS
# =========================================================
#

def test_both_forms_have_duration_conversion_logic():
    protection = read(PROTECTION_FORM)
    sessions = read(SESSIONS_FORM)

    # Accept either helper functions or inline math as long as conversion exists.
    assert_contains_any(
        protection,
        [r"secondsToHours", r"/\s*3600", r"\*\s*3600"],
        "Protection form missing duration conversion logic",
    )

    assert_contains_any(
        sessions,
        [r"secondsToHours", r"/\s*3600", r"\*\s*3600"],
        "Sessions form missing duration conversion logic",
    )


def test_form_reset_uses_human_readable_values():
    protection = read(PROTECTION_FORM)
    sessions = read(SESSIONS_FORM)

    # Reset/initialize should not display raw backend second values directly.
    assert_contains_any(
        protection,
        [
            r"SESSIONS_TIMEBOX\s*:\s*secondsToHours",
            r"SESSIONS_TIMEBOX\s*:\s*[^\n]*\/\s*3600",
        ],
        "Protection form reset does not convert session timeout to human-readable units",
    )

    assert_contains_any(
        sessions,
        [
            r"SESSIONS_TIMEBOX\s*:\s*secondsToHours",
            r"SESSIONS_TIMEBOX\s*:\s*[^\n]*\/\s*3600",
        ],
        "Sessions form reset does not convert session timeout to human-readable units",
    )


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


def test_submit_payload_converts_back_to_seconds():
    protection = read(PROTECTION_FORM)
    sessions = read(SESSIONS_FORM)

    # Submit path should serialize human-readable values back to backend seconds.
    assert_contains_any(
        protection,
        [
            r"SESSIONS_TIMEBOX\s*:\s*hoursToSeconds",
            r"SESSIONS_TIMEBOX\s*:\s*[^\n]*\*\s*3600",
        ],
        "Protection form submit does not convert session timeout to backend seconds",
    )

    assert_contains_any(
        sessions,
        [
            r"SESSIONS_TIMEBOX\s*:\s*hoursToSeconds",
            r"SESSIONS_TIMEBOX\s*:\s*[^\n]*\*\s*3600",
        ],
        "Sessions form submit does not convert session timeout to backend seconds",
    )

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


def test_authorization_uses_github_token():
    src = read(AUTHORIZE_SCRIPT)

    # Allow token/bearer schemes; requirement is authenticated request via env token.
    assert re.search(r"Authorization", src), \
        "Authorization header wiring missing"
    assert re.search(r"process\.env\.GITHUB_TOKEN", src), \
        "Authorization does not use GITHUB_TOKEN"


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


def test_fetch_has_timeout_and_abort_controller():
    src = read(AUTHORIZE_SCRIPT)

    assert_contains_any(
        src,
        [r"AbortController", r"signal\s*:", r"REQUEST_TIMEOUT", r"setTimeout\s*\(\s*\(\)\s*=>\s*.*abort"],
        "Missing timeout/abort handling for request safety",
    )


def test_fetch_has_retries_for_transient_failures():
    src = read(AUTHORIZE_SCRIPT)

    assert_contains_any(
        src,
        [r"MAX_RETRIES", r"attempt", r"retry"],
        "Missing retry configuration for GitHub status fetch",
    )

    assert_contains_any(
        src,
        [r"429", r">=\s*500", r"5xx"],
        "Transient failure retry conditions missing",
    )


def test_statuses_without_target_url_are_filtered():
    src = read(AUTHORIZE_SCRIPT)

    assert re.search(r"filter\(.*?target_url", src, re.DOTALL), \
        "Statuses without target_url are not safely filtered"





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


def test_vector_product_has_non_empty_label():
    src = read(MAGNIFIED_PRODUCTS)

    vector_block = re.search(r"vector\s*:\s*\{.*?\n\s*\}", src, re.DOTALL | re.IGNORECASE)
    assert vector_block, "Vector product definition missing"

    block = vector_block.group(0)
    assert re.search(r"label\s*:\s*['\"]\s*[^'\"\s][^'\"]*['\"]", block), \
        "Vector product label is missing or empty"

    # Keep expected metadata presence intact.
    assert "description" in block, "Vector product description field missing"





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

    # ColorPalette must be registered in components map; exact ordering is irrelevant.
    assert re.search(r"const\s+components\s*=\s*\{", src), \
        "components map declaration missing"
    assert re.search(r"\bColorPalette\b", src), \
        "ColorPalette not added as property in components object"


def test_mdx_components_registers_color_palette():
    src = read(MDX_COMPONENTS)

    assert "import { ColorPalette } from '@/components/color-palette'" in src, \
        "mdx-components.tsx missing ColorPalette import"

    assert re.search(r"\bColorPalette\b", src), \
        "ColorPalette not referenced in mdx components map"


def test_color_usage_doc_references_palette():
    src = read(COLOR_USAGE_DOC)

    assert re.search(r"##\s+.*palette", src, re.IGNORECASE), \
        "color-usage.mdx missing palette section heading"

    assert "<ColorPalette />" in src, \
        "color-usage.mdx missing ColorPalette component usage"


def test_color_palette_buttons_have_accessibility_attributes():
    src = read(COLOR_PALETTE_COMPONENT)

    assert "aria-label" in src, \
        "ColorPalette buttons missing explicit aria-label"


def test_color_usage_doc_mentions_copy_feedback():
    src = read(COLOR_USAGE_DOC)

    assert re.search(r"copy", src, re.IGNORECASE), \
        "Color usage docs missing copy behavior guidance"
    assert re.search(r"feedback|copied|accessib", src, re.IGNORECASE), \
        "Color usage docs missing accessibility/copy feedback guidance"





#
# =========================================================
# RUN TESTS
# =========================================================
#

#
# Auth settings conversion tests
#

check(
    "both auth forms have duration conversion logic",
    test_both_forms_have_duration_conversion_logic,
    weight=1.5,
)

check(
    "form reset uses human-readable values",
    test_form_reset_uses_human_readable_values,
    weight=1.5,
)

check(
    "submit payload transforms values",
    test_submit_payload_transforms_values,
    weight=1.0,
)

check(
    "submit payload converts back to seconds",
    test_submit_payload_converts_back_to_seconds,
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
    "authorization uses github token",
    test_authorization_uses_github_token,
    weight=1.5,
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
    "fetch has timeout and abort controller",
    test_fetch_has_timeout_and_abort_controller,
    weight=2.0,
)

check(
    "fetch retries transient failures",
    test_fetch_has_retries_for_transient_failures,
    weight=2.0,
)

check(
    "statuses without target url are filtered",
    test_statuses_without_target_url_are_filtered,
    weight=2.0,
)



check(
    "vector link points to modules path",
    test_vector_link_points_to_modules_path,
    weight=1.5,
)

check(
    "vector product has non-empty label",
    test_vector_product_has_non_empty_label,
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

check(
    "color palette buttons have accessibility attributes",
    test_color_palette_buttons_have_accessibility_attributes,
    weight=1.5,
)

check(
    "color usage doc mentions copy feedback",
    test_color_usage_doc_mentions_copy_feedback,
    weight=1.5,
)



reward = PASSED_WEIGHT / TOTAL_WEIGHT if TOTAL_WEIGHT else 0.0

print(f"\nReward: {reward:.4f}")

os.makedirs("/logs/verifier", exist_ok=True)
with open("/logs/verifier/reward.txt", "w") as f:
    f.write(str(reward))

sys.exit(0)