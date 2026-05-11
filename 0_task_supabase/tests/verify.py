#!/usr/bin/env python3

import os
import re
import sys
from pathlib import Path

ROOT = Path("/testbed")

PROTECTION_FORM = ROOT / "apps/studio/components/interfaces/Auth/ProtectionAuthSettingsForm/ProtectionAuthSettingsForm.tsx"
SESSIONS_FORM = ROOT / "apps/studio/components/interfaces/Auth/SessionsAuthSettingsForm/SessionsAuthSettingsForm.tsx"
AUTHORIZE_SCRIPT = ROOT / "scripts/authorizeVercelDeploys.ts"
MAGNIFIED_PRODUCTS = ROOT / "apps/www/components/MagnifiedProducts.tsx"
COLOR_PALETTE_COMPONENT = ROOT / "apps/design-system/components/color-palette.tsx"
COPY_BUTTON_COMPONENT = ROOT / "apps/design-system/components/copy-button.tsx"
MDX_COMPONENTS = ROOT / "apps/design-system/components/mdx-components.tsx"
COLOR_USAGE_DOC = ROOT / "apps/design-system/content/docs/color-usage.mdx"
ACCESSIBILITY_DOC = ROOT / "apps/design-system/content/docs/accessibility.mdx"

TOTAL_WEIGHT = 0.0
PASSED_WEIGHT = 0.0


def read(path: Path) -> str:
    assert path.exists(), f"Missing required file: {path}"
    return path.read_text(encoding="utf-8", errors="ignore")


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


def assert_contains_any(src: str, patterns, message: str):
    for pattern in patterns:
        if re.search(pattern, src, re.DOTALL | re.IGNORECASE):
            return
    raise AssertionError(message)


# =========================================================
# Bug 1: auth inactivity timeout should be human-readable in UI,
# then converted back to seconds on submit.
# =========================================================

def test_auth_forms_exist():
    assert PROTECTION_FORM.exists(), "Protection auth form file missing"
    assert SESSIONS_FORM.exists(), "Sessions auth form file missing"


def test_auth_forms_display_human_readable_inactivity_timeout():
    protection = read(PROTECTION_FORM)
    sessions = read(SESSIONS_FORM)

    assert_contains_any(
        protection,
        [
            r"SESSIONS_INACTIVITY_TIMEOUT\s*:\s*[^\n]*/\s*3600",
            r"SESSIONS_INACTIVITY_TIMEOUT\s*:\s*secondsToHours",
        ],
        "Protection form does not convert inactivity timeout to human-readable units",
    )

    assert_contains_any(
        sessions,
        [
            r"SESSIONS_INACTIVITY_TIMEOUT\s*:\s*[^\n]*/\s*3600",
            r"SESSIONS_INACTIVITY_TIMEOUT\s*:\s*secondsToHours",
        ],
        "Sessions form does not convert inactivity timeout to human-readable units",
    )


def test_auth_forms_convert_inactivity_timeout_back_on_submit():
    protection = read(PROTECTION_FORM)
    sessions = read(SESSIONS_FORM)

    assert_contains_any(
        protection,
        [
            r"SESSIONS_INACTIVITY_TIMEOUT\s*=\s*[^\n]*\*\s*3600",
            r"SESSIONS_INACTIVITY_TIMEOUT\s*:\s*hoursToSeconds",
        ],
        "Protection form does not convert inactivity timeout back to seconds on submit",
    )

    assert_contains_any(
        sessions,
        [
            r"SESSIONS_INACTIVITY_TIMEOUT\s*=\s*[^\n]*\*\s*3600",
            r"SESSIONS_INACTIVITY_TIMEOUT\s*:\s*hoursToSeconds",
        ],
        "Sessions form does not convert inactivity timeout back to seconds on submit",
    )


# =========================================================
# Bug 2 + Bug 4: GitHub status fetch auth + resilience.
# =========================================================

def test_authorize_script_exists_and_targets_github_statuses():
    src = read(AUTHORIZE_SCRIPT)
    assert "api.github.com/repos/supabase/supabase/statuses" in src, "GitHub statuses URL missing/changed"


def test_authorize_uses_github_token_auth_header():
    src = read(AUTHORIZE_SCRIPT)

    assert "GITHUB_TOKEN" in src, "GITHUB_TOKEN handling missing"
    assert re.search(r"Authorization", src), "Authorization header handling missing"


def test_authorize_has_timeout_handling():
    src = read(AUTHORIZE_SCRIPT)

    assert_contains_any(
        src,
        [
            r"AbortController",
            r"signal\s*:",
            r"setTimeout\s*\(\s*\(\)\s*=>\s*.*abort",
            r"timeout",
        ],
        "Request timeout/abort handling missing",
    )


def test_authorize_retries_transient_failures():
    src = read(AUTHORIZE_SCRIPT)

    assert_contains_any(
        src,
        [r"retry", r"MAX_RETRIES", r"attempt", r"backoff"],
        "Retry mechanism not detected",
    )
    assert_contains_any(
        src,
        [r"429", r">=\s*500", r"5xx", r"isTransient"],
        "Transient error condition for 429/5xx not detected",
    )


def test_authorize_skips_statuses_without_target_url():
    src = read(AUTHORIZE_SCRIPT)

    # Accept either explicit continue/if checks or filtered array forms.
    assert_contains_any(
        src,
        [
            r"if\s*\(\s*!status\.target_url\s*\)",
            r"filter\(.*target_url",
            r"status\.target_url\s*\?",
        ],
        "Statuses without target_url are not safely handled",
    )


def test_authorize_has_nonzero_exit_on_failure():
    src = read(AUTHORIZE_SCRIPT)

    assert_contains_any(
        src,
        [r"process\.exit\s*\(\s*1\s*\)", r"throw new Error"],
        "Authorization failure does not clearly lead to non-zero/error path",
    )


# =========================================================
# Bug 3 + Bug 5: MagnifiedProducts vector link + visible label.
# =========================================================

def _extract_vector_block(src: str) -> str:
    m = re.search(r"vector\s*:\s*\{.*?\n\s*\}", src, re.DOTALL | re.IGNORECASE)
    assert m, "Vector product definition missing"
    return m.group(0)


def test_vector_link_points_to_modules_vector():
    src = read(MAGNIFIED_PRODUCTS)
    block = _extract_vector_block(src)

    assert_contains_any(
        block,
        [r"url\s*:\s*['\"]\/modules\/vector['\"]"],
        "Vector product URL is not /modules/vector",
    )


def test_vector_label_is_non_empty():
    src = read(MAGNIFIED_PRODUCTS)
    block = _extract_vector_block(src)

    assert re.search(r"label\s*:\s*['\"]\s*[^'\"\s][^'\"]*['\"]", block), \
        "Vector product label is empty or missing"


# =========================================================
# Feature 1 + Feature 2: color palette component + docs + a11y.
# =========================================================

def test_color_palette_component_exists_and_is_interactive():
    src = read(COLOR_PALETTE_COMPONENT)

    assert "useState" in src, "ColorPalette should manage copy state"
    assert_contains_any(
        src,
        [r"onClick", r"handleCopy"],
        "ColorPalette click/copy behavior missing",
    )
    assert_contains_any(
        src,
        [r"navigator\.clipboard", r"copyToClipboardWithMeta"],
        "Clipboard copy behavior missing",
    )


def test_color_palette_has_explicit_accessibility_label():
    src = read(COLOR_PALETTE_COMPONENT)

    assert_contains_any(
        src,
        [r"aria-label", r"ariaLabel"],
        "ColorPalette swatches are missing explicit accessible labels",
    )


def test_mdx_components_registers_color_palette():
    src = read(MDX_COMPONENTS)

    assert_contains_any(
        src,
        [r"import\s*\{\s*ColorPalette\s*\}\s*from\s*['\"]@/components/color-palette['\"]"],
        "mdx-components is missing ColorPalette import",
    )
    assert_contains_any(
        src,
        [r"\bColorPalette\b"],
        "mdx-components does not reference ColorPalette in component map",
    )


def test_color_usage_doc_mentions_palette_and_copy_feedback():
    src = read(COLOR_USAGE_DOC)

    assert re.search(r"##\s+.*palette", src, re.IGNORECASE), "Color usage docs missing palette section"
    assert "<ColorPalette />" in src, "Color usage docs missing ColorPalette usage"
    assert_contains_any(
        src,
        [r"copy", r"copied", r"feedback"],
        "Color usage docs missing copy feedback guidance",
    )


# =========================================================
# Execute checks with weighted scoring.
# =========================================================

check("auth forms exist", test_auth_forms_exist, weight=0.5)
check(
    "auth forms display human-readable inactivity timeout",
    test_auth_forms_display_human_readable_inactivity_timeout,
    weight=2.0,
)
check(
    "auth forms convert inactivity timeout to seconds on submit",
    test_auth_forms_convert_inactivity_timeout_back_on_submit,
    weight=2.0,
)

check(
    "authorize script exists and targets github statuses",
    test_authorize_script_exists_and_targets_github_statuses,
    weight=1.0,
)
check("authorize uses github token auth", test_authorize_uses_github_token_auth_header, weight=1.5)
check("authorize has timeout handling", test_authorize_has_timeout_handling, weight=2.0)
check("authorize retries transient failures", test_authorize_retries_transient_failures, weight=2.0)
check("authorize skips statuses without target_url", test_authorize_skips_statuses_without_target_url, weight=2.0)
check("authorize has nonzero exit on failure", test_authorize_has_nonzero_exit_on_failure, weight=1.5)

check("vector link points to /modules/vector", test_vector_link_points_to_modules_vector, weight=1.5)
check("vector label is non-empty", test_vector_label_is_non_empty, weight=1.5)

check(
    "color palette component exists and is interactive",
    test_color_palette_component_exists_and_is_interactive,
    weight=1.5,
)
check(
    "color palette has explicit accessibility label",
    test_color_palette_has_explicit_accessibility_label,
    weight=1.5,
)
check("mdx components registers color palette", test_mdx_components_registers_color_palette, weight=1.5)
check(
    "color usage docs mention palette and copy feedback",
    test_color_usage_doc_mentions_palette_and_copy_feedback,
    weight=1.5,
)


# =========================================================
# Feature 1 detail: copied feedback text + auto-clear timeout
# =========================================================

def test_color_palette_copied_feedback_with_timeout():
    src = read(COLOR_PALETTE_COMPONENT)
    assert re.search(r"['\"]Copied[!\.]?['\"]", src), \
        "color-palette.tsx missing 'Copied!' feedback text"
    assert re.search(r"setTimeout\s*\(", src), \
        "color-palette.tsx missing setTimeout to auto-clear copied state"
    assert_contains_any(
        src,
        [r"setTimeout\s*\([^,]+,\s*\d{3,}", r"setTimeout\s*\([^,]+,\s*COPY_FEEDBACK_DURATION_MS"],
        "color-palette.tsx setTimeout missing numeric delay or shared timeout constant",
    )


# =========================================================
# Feature 2 detail: aria-label must be descriptive/dynamic
# =========================================================

def test_color_palette_aria_label_is_descriptive():
    src = read(COLOR_PALETTE_COMPONENT)
    # The aria-label should include a dynamic reference to the color name and/or step
    assert_contains_any(
        src,
        [
            r"aria-label=\{`[^`]*\$\{[^}]+\}[^`]*`\}",  # template literal
            r"aria-label=\{`Copy[^`]*\$\{",              # "Copy ${name} ..."
        ],
        "color-palette.tsx aria-label is not dynamic/descriptive (must include color name/step via template literal)",
    )


def test_color_palette_is_keyboard_focusable():
    src = read(COLOR_PALETTE_COMPONENT)
    assert_contains_any(
        src,
        [r"tabIndex\s*=\s*\{\s*0\s*\}", r"tabIndex\s*=\s*['\"]0['\"]"],
        "color-palette.tsx swatches are missing explicit keyboard focusability via tabIndex={0}",
    )


def test_copy_button_exports_shared_feedback_duration_constant():
    src = read(COPY_BUTTON_COMPONENT)
    assert_contains_any(
        src,
        [r"export\s+const\s+COPY_FEEDBACK_DURATION_MS\s*=\s*1500", r"export\s*\{\s*COPY_FEEDBACK_DURATION_MS\s*\}"],
        "copy-button.tsx missing exported COPY_FEEDBACK_DURATION_MS constant",
    )


def test_color_palette_reuses_shared_feedback_duration_constant():
    src = read(COLOR_PALETTE_COMPONENT)
    assert_contains_any(
        src,
        [
            r"COPY_FEEDBACK_DURATION_MS",
            r"from\s*['\"].*copy-button['\"]",
        ],
        "color-palette.tsx does not reuse shared copy-button feedback duration constant",
    )


def test_accessibility_doc_mentions_palette_swatch_a11y():
    src = read(ACCESSIBILITY_DOC)
    assert_contains_any(
        src,
        [r"color swatches", r"palette swatches", r"interactive color swatches"],
        "accessibility.mdx missing color swatch accessibility guidance",
    )
    assert_contains_any(
        src,
        [r"aria-label", r"keyboard focus", r"tabIndex"],
        "accessibility.mdx missing aria-label or keyboard-focus guidance for color swatches",
    )


# =========================================================
# Bug 4 detail: named constants for retry and timeout
# =========================================================

def test_authorize_has_named_max_retries_constant():
    src = read(AUTHORIZE_SCRIPT)
    assert re.search(r"\bMAX_RETRIES\b", src), \
        "authorizeVercelDeploys.ts missing MAX_RETRIES named constant"
    assert re.search(r"MAX_RETRIES\s*=\s*\d+", src), \
        "authorizeVercelDeploys.ts MAX_RETRIES is not assigned a numeric value"


def test_authorize_has_named_timeout_ms_constant():
    src = read(AUTHORIZE_SCRIPT)
    assert_contains_any(
        src,
        [r"\bREQUEST_TIMEOUT_MS\b", r"\bTIMEOUT_MS\b", r"\bFETCH_TIMEOUT\b"],
        "authorizeVercelDeploys.ts missing named timeout constant (e.g. REQUEST_TIMEOUT_MS)",
    )


def test_authorize_waits_between_retries():
    src = read(AUTHORIZE_SCRIPT)
    # Must have actual delay between retries (not just immediate retry)
    assert_contains_any(
        src,
        [
            r"waitForRetry",
            r"await new Promise[^;]*setTimeout",
            r"await.*sleep",
            r"backoff",
        ],
        "authorizeVercelDeploys.ts retry logic has no delay/backoff between attempts",
    )


# =========================================================
# Bug 1 detail: Sessions form submit conversion (separate from Protection)
# =========================================================

def test_sessions_form_converts_inactivity_timeout_on_submit():
    sessions = read(SESSIONS_FORM)
    assert_contains_any(
        sessions,
        [
            r"SESSIONS_INACTIVITY_TIMEOUT\s*=\s*[^\n]*\*\s*3600",
            r"SESSIONS_INACTIVITY_TIMEOUT\s*:\s*hoursToSeconds",
            r"Math\.round\([^)]*SESSIONS_INACTIVITY_TIMEOUT[^)]*3600\)",
        ],
        "Sessions form does not convert inactivity timeout back to seconds on submit",
    )


check("color palette copied feedback with timeout", test_color_palette_copied_feedback_with_timeout, weight=1.5)
check("color palette aria-label is dynamic/descriptive", test_color_palette_aria_label_is_descriptive, weight=1.5)
check("color palette swatches are explicitly keyboard focusable", test_color_palette_is_keyboard_focusable, weight=1.5)
check("copy-button exports shared feedback duration constant", test_copy_button_exports_shared_feedback_duration_constant, weight=1.5)
check("color palette reuses shared feedback duration constant", test_color_palette_reuses_shared_feedback_duration_constant, weight=2.0)
check("accessibility docs mention palette swatch a11y", test_accessibility_doc_mentions_palette_swatch_a11y, weight=2.0)
check("authorize has named MAX_RETRIES constant", test_authorize_has_named_max_retries_constant, weight=1.5)
check("authorize has named timeout-ms constant", test_authorize_has_named_timeout_ms_constant, weight=1.5)
check("authorize waits between retries (backoff)", test_authorize_waits_between_retries, weight=2.0)
check("sessions form converts inactivity timeout on submit", test_sessions_form_converts_inactivity_timeout_on_submit, weight=2.0)

reward = PASSED_WEIGHT / TOTAL_WEIGHT if TOTAL_WEIGHT else 0.0
print(f"\nReward: {reward:.4f}")

os.makedirs("/logs/verifier", exist_ok=True)
with open("/logs/verifier/reward.txt", "w", encoding="utf-8") as f:
    f.write(str(reward))

sys.exit(0)
