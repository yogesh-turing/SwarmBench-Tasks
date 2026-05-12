#!/usr/bin/env python3

import os
import re
import sys
from pathlib import Path

ROOT = Path("/testbed")

APP_LAYOUT = ROOT / "apps/www/app/layout.tsx"
APP_PARTNERS_PAGE = ROOT / "apps/www/app/partners/page.tsx"
APP_PARTNERS_CONTENT = ROOT / "apps/www/app/partners/PartnersContent.tsx"
APP_PARTNERS_INTEGRATIONS_PAGE = ROOT / "apps/www/app/partners/integrations/page.tsx"
APP_PARTNERS_INTEGRATIONS_CONTENT = ROOT / "apps/www/app/partners/integrations/IntegrationsContent.tsx"
PAGES_APP = ROOT / "apps/www/pages/_app.tsx"
PAGES_PARTNERS_INDEX = ROOT / "apps/www/pages/partners/index.tsx"
PAGES_PARTNERS_INTEGRATIONS_INDEX = ROOT / "apps/www/pages/partners/integrations/index.tsx"

BECOME_A_PARTNER = ROOT / "apps/www/components/Partners/BecomeAPartner.tsx"
PARTNER_INTAKE_FORM = ROOT / "apps/www/components/Partners/PartnerIntakeForm.tsx"
PARTNER_DATA = ROOT / "apps/www/data/partners/index.tsx"

MARKETING_INDEX = ROOT / "packages/marketing/index.ts"
FORMS_INDEX = ROOT / "packages/marketing/src/forms/index.ts"
MARKETING_FORM = ROOT / "packages/marketing/src/forms/MarketingForm.tsx"
HUBSPOT_FORM_EMBED = ROOT / "packages/marketing/src/forms/HubSpotFormEmbed.tsx"
GO_SCHEMAS = ROOT / "packages/marketing/src/go/schemas.ts"
FORM_SECTION = ROOT / "packages/marketing/src/go/sections/FormSection.tsx"
SHOW_WHEN = ROOT / "packages/marketing/src/go/showWhen.ts"
SUBMIT_FORM = ROOT / "packages/marketing/src/go/actions/submitForm.ts"

DOCS_APP_LAYOUT = ROOT / "apps/docs/app/layout.tsx"
DOCS_BREADCRUMBS_COMPONENT = ROOT / "apps/docs/components/Breadcrumbs.tsx"
DOCS_BREADCRUMBS_LIB = ROOT / "apps/docs/lib/breadcrumbs.ts"
DOCS_JSON_LD = ROOT / "apps/docs/lib/json-ld.ts"
DOCS_GLOBALS_CSS = ROOT / "apps/docs/styles/globals.css"
DOCS_TAILWIND = ROOT / "apps/docs/tailwind.config.cjs"
DS_GLOBALS_CSS = ROOT / "apps/design-system/styles/globals.css"
DS_TAILWIND = ROOT / "apps/design-system/tailwind.config.js"
STUDIO_DOCS_DESCRIPTION = ROOT / "apps/studio/components/interfaces/Docs/Description.tsx"
STUDIO_PROJECT_API_INTRO = ROOT / "apps/studio/components/interfaces/ProjectAPIDocs/Content/Introduction.tsx"
STUDIO_NOTICE_BANNER = ROOT / "apps/studio/components/layouts/AppLayout/NoticeBanner.tsx"
STUDIO_DB_SHORTCUTS = ROOT / "apps/studio/components/interfaces/DatabaseNavShortcuts.tsx"

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


def assert_not_contains_any(src: str, patterns, message: str):
    for pattern in patterns:
        if re.search(pattern, src, re.DOTALL | re.IGNORECASE):
            raise AssertionError(message)


# =========================================================
# Workstream 1: routing and CTA anchor integration
# =========================================================

def test_routing_surfaces_exist():
    paths = [
        APP_LAYOUT,
        APP_PARTNERS_PAGE,
        APP_PARTNERS_CONTENT,
        APP_PARTNERS_INTEGRATIONS_PAGE,
        APP_PARTNERS_INTEGRATIONS_CONTENT,
        PAGES_APP,
        PAGES_PARTNERS_INDEX,
        PAGES_PARTNERS_INTEGRATIONS_INDEX,
    ]
    missing = [str(p) for p in paths if not p.exists()]
    assert not missing, f"Missing routing artifacts: {', '.join(missing)}"


def test_app_router_partner_routes_present():
    page_src = read(APP_PARTNERS_PAGE)
    integrations_src = read(APP_PARTNERS_INTEGRATIONS_PAGE)

    assert_contains_any(
        page_src,
        [r"PartnersContent", r"/partners"],
        "App Router /partners page does not appear wired",
    )
    assert_contains_any(
        integrations_src,
        [r"IntegrationsContent", r"/partners/integrations"],
        "App Router /partners/integrations page does not appear wired",
    )


def test_become_partner_cta_points_to_anchor_not_external_forms_host():
    become = read(BECOME_A_PARTNER)
    partner_data = read(PARTNER_DATA)

    combined = "\n".join([become, partner_data])

    assert_contains_any(
        combined,
        [
            r"/partners#become-a-partner",
            r"#become-a-partner",
            r"become-a-partner",
        ],
        "Partner CTA does not reference #become-a-partner anchor",
    )

    assert_not_contains_any(
        combined,
        [r"forms\.supabase\.com", r"https?://[^\s'\"]*forms[^\s'\"]*"],
        "Partner CTA still appears to use external forms host URL",
    )


# =========================================================
# Workstream 2: inline intake and conditional sections
# =========================================================

def test_inline_partner_intake_anchor_and_section_present():
    src = read(PARTNER_INTAKE_FORM)

    assert_contains_any(
        src,
        [
            r"become-a-partner",
            r"id\s*=\s*['\"]become-a-partner['\"]",
        ],
        "Partner intake form is missing #become-a-partner anchor/section hook",
    )


def test_partner_intake_uses_conditional_visibility_semantics():
    src = read(PARTNER_INTAKE_FORM)

    assert_contains_any(
        src,
        [r"showWhen", r"sendWhen", r"partner[_-]?type", r"conditional"],
        "Partner intake form is missing partner-type conditional section behavior",
    )


def test_checkbox_group_support_visible_in_schema_and_rendering():
    schemas = read(GO_SCHEMAS)
    form_section = read(FORM_SECTION)

    assert_contains_any(
        schemas,
        [r"checkbox-group", r"checkbox_group"],
        "Schema does not include checkbox-group field support",
    )
    assert_contains_any(
        form_section,
        [r"checkbox-group", r"checkbox_group"],
        "Form section renderer does not handle checkbox-group fields",
    )


# =========================================================
# Workstream 3: shared marketing showWhen behavior
# =========================================================

def test_showwhen_module_exists_and_exports_logic():
    src = read(SHOW_WHEN)

    assert_contains_any(
        src,
        [r"export", r"showWhen", r"evaluate"],
        "showWhen module is missing exports/evaluator logic",
    )


def test_showwhen_is_reused_in_renderer_and_submission():
    form_section = read(FORM_SECTION)
    submit_form = read(SUBMIT_FORM)

    assert_contains_any(
        form_section,
        [r"showWhen", r"from\s+['\"].*showWhen['\"]"],
        "Renderer does not appear to use shared showWhen logic",
    )
    assert_contains_any(
        submit_form,
        [r"showWhen", r"from\s+['\"].*showWhen['\"]", r"sendWhen"],
        "Submission fan-out does not appear to use shared conditional semantics",
    )


def test_marketing_exports_are_wired_consistently():
    root_index = read(MARKETING_INDEX)
    forms_index = read(FORMS_INDEX)
    marketing_form = read(MARKETING_FORM)
    hubspot_embed = read(HUBSPOT_FORM_EMBED)

    assert_contains_any(
        forms_index,
        [r"MarketingForm", r"HubSpotFormEmbed"],
        "forms/index.ts does not export expected form modules",
    )
    assert_contains_any(
        root_index,
        [r"from\s+['\"].*forms['\"]", r"MarketingForm", r"HubSpotFormEmbed"],
        "packages/marketing/index.ts is not wiring form exports consistently",
    )
    assert_contains_any(
        marketing_form,
        [r"showWhen", r"form", r"field"],
        "MarketingForm.tsx appears to miss shared form semantics",
    )
    assert_contains_any(
        hubspot_embed,
        [r"HubSpot", r"submit", r"form"],
        "HubSpotFormEmbed.tsx appears incomplete for form integration",
    )


# =========================================================
# Workstream 4: provider fan-out and sendWhen gating
# =========================================================

def test_submit_form_mentions_hubspot_and_notion_providers():
    src = read(SUBMIT_FORM)

    assert_contains_any(
        src,
        [r"HubSpot", r"hubspot"],
        "submitForm.ts is missing HubSpot provider handling",
    )
    assert_contains_any(
        src,
        [r"Notion", r"notion"],
        "submitForm.ts is missing Notion provider handling",
    )


def test_submit_form_uses_sendwhen_or_conditional_provider_gating():
    src = read(SUBMIT_FORM)

    assert_contains_any(
        src,
        [r"sendWhen", r"showWhen", r"if\s*\(.*notion", r"partner[_-]?type"],
        "submitForm.ts is missing conditional provider gating for fan-out",
    )


def test_notion_gating_references_qualifying_partner_types():
    src = read(SUBMIT_FORM)

    assert_contains_any(
        src,
        [
            r"Technology\s+Partner",
            r"technology[_ -]?partner",
            r"partner[_-]?type",
            r"qualif",
        ],
        "Notion gating does not reference partner-type qualification criteria",
    )


# =========================================================
# Cross-artifact consistency checks
# =========================================================

def test_partner_type_key_is_used_across_schema_ui_and_submit():
    schema_src = read(GO_SCHEMAS)
    intake_src = read(PARTNER_INTAKE_FORM)
    submit_src = read(SUBMIT_FORM)

    combined = "\n".join([schema_src, intake_src, submit_src])
    assert_contains_any(
        combined,
        [r"partner[_-]?type", r"partnerType"],
        "partner type key is not consistently visible across schema/UI/submission",
    )


def test_integrations_route_linkage_is_preserved():
    app_content = read(APP_PARTNERS_CONTENT)
    integrations_content = read(APP_PARTNERS_INTEGRATIONS_CONTENT)

    assert_contains_any(
        app_content + "\n" + integrations_content,
        [r"integrations", r"/partners/integrations"],
        "Integrations listing/navigation linkage appears broken",
    )


# =========================================================
# Instruction clause: existing partner listing reachable after routing
# =========================================================

def test_partner_listing_content_remains_reachable():
    # The partners content and integrations content components must still render
    # partner/integration listing data — not be empty stubs or redirect-only.
    partners_content = read(APP_PARTNERS_CONTENT)
    integrations_content = read(APP_PARTNERS_INTEGRATIONS_CONTENT)

    assert_contains_any(
        partners_content,
        [r"partner", r"data", r"map\s*\(", r"Partner"],
        "PartnersContent appears to be a stub with no listing content",
    )
    assert_contains_any(
        integrations_content,
        [r"integration", r"data", r"map\s*\(", r"Integration"],
        "IntegrationsContent appears to be a stub with no listing content",
    )


# =========================================================
# Instruction clause: no placeholder-only behavior in core gating logic
# =========================================================

def test_gating_logic_is_not_placeholder_only():
    submit_src = read(SUBMIT_FORM)
    show_when_src = read(SHOW_WHEN)

    # submitForm.ts must not be a TODO/stub — it must contain real logic
    assert_not_contains_any(
        submit_src,
        [r"TODO\s*:.*notion", r"throw new Error\(['\"]not implemented"],
        "submitForm.ts appears to use placeholder/not-implemented gating for Notion",
    )

    # showWhen.ts must have an actual conditional expression, not just an export stub
    assert_contains_any(
        show_when_src,
        [r"if\s*\(", r"===", r"includes\s*\(", r"return\s+(true|false|\w)"],
        "showWhen.ts contains no conditional evaluation logic (placeholder only)",
    )


# =========================================================
# Secondary breadth surfaces: docs/design-system/studio
# =========================================================

def test_secondary_surfaces_exist():
    paths = [
        DOCS_APP_LAYOUT,
        DOCS_BREADCRUMBS_COMPONENT,
        DOCS_BREADCRUMBS_LIB,
        DOCS_JSON_LD,
        DOCS_GLOBALS_CSS,
        DOCS_TAILWIND,
        DS_GLOBALS_CSS,
        DS_TAILWIND,
        STUDIO_DOCS_DESCRIPTION,
        STUDIO_PROJECT_API_INTRO,
        STUDIO_NOTICE_BANNER,
        STUDIO_DB_SHORTCUTS,
    ]
    missing = [str(p) for p in paths if not p.exists()]
    assert not missing, f"Missing secondary artifacts: {', '.join(missing)}"


def test_docs_navigation_and_meta_wiring_signals():
    docs_layout = read(DOCS_APP_LAYOUT)
    docs_breadcrumbs_component = read(DOCS_BREADCRUMBS_COMPONENT)
    docs_breadcrumbs_lib = read(DOCS_BREADCRUMBS_LIB)
    docs_json_ld = read(DOCS_JSON_LD)

    assert_contains_any(
        docs_layout,
        [r"metadata", r"layout", r"json-ld", r"breadcrumb"],
        "apps/docs/app/layout.tsx appears to miss docs metadata/navigation wiring",
    )
    assert_contains_any(
        docs_breadcrumbs_component + "\n" + docs_breadcrumbs_lib,
        [r"breadcrumb", r"crumb", r"path", r"guide"],
        "Docs breadcrumbs component/lib appears disconnected or placeholder-only",
    )
    assert_contains_any(
        docs_json_ld,
        [r"json", r"ld", r"schema", r"BreadcrumbList", r"@type"],
        "apps/docs/lib/json-ld.ts appears to miss structured metadata semantics",
    )


def test_design_system_and_studio_surface_signals():
    docs_css = read(DOCS_GLOBALS_CSS)
    docs_tailwind = read(DOCS_TAILWIND)
    ds_css = read(DS_GLOBALS_CSS)
    ds_tailwind = read(DS_TAILWIND)
    studio_combined = "\n".join(
        [
            read(STUDIO_DOCS_DESCRIPTION),
            read(STUDIO_PROJECT_API_INTRO),
            read(STUDIO_NOTICE_BANNER),
            read(STUDIO_DB_SHORTCUTS),
        ]
    )

    assert_contains_any(
        docs_css + "\n" + ds_css,
        [r"--", r":root", r"font", r"color", r"background"],
        "Docs/design-system global styles appear incomplete or disconnected",
    )
    assert_contains_any(
        docs_tailwind + "\n" + ds_tailwind,
        [r"tailwind", r"theme", r"content", r"extend"],
        "Docs/design-system tailwind configs appear incomplete",
    )
    assert_contains_any(
        studio_combined,
        [r"docs", r"api", r"notice", r"database", r"description"],
        "Studio secondary docs/navigation surfaces appear missing expected semantics",
    )


# =========================================================
# Execute checks with weighted scoring
# =========================================================

check("routing surfaces exist", test_routing_surfaces_exist, weight=1.0)
check("app router partner routes present", test_app_router_partner_routes_present, weight=2.0)
check(
    "become-a-partner CTA uses anchor and not external forms host",
    test_become_partner_cta_points_to_anchor_not_external_forms_host,
    weight=2.0,
)

check("inline intake anchor/section present", test_inline_partner_intake_anchor_and_section_present, weight=1.5)
check("partner intake conditional visibility semantics", test_partner_intake_uses_conditional_visibility_semantics, weight=2.0)
check("checkbox-group support in schema and renderer", test_checkbox_group_support_visible_in_schema_and_rendering, weight=2.0)

check("showWhen module exists with exports", test_showwhen_module_exists_and_exports_logic, weight=1.5)
check("showWhen reused in renderer and submission", test_showwhen_is_reused_in_renderer_and_submission, weight=2.0)
check("marketing exports wiring consistency", test_marketing_exports_are_wired_consistently, weight=2.0)

check("submit form includes HubSpot and Notion", test_submit_form_mentions_hubspot_and_notion_providers, weight=1.5)
check("submit form uses conditional provider gating", test_submit_form_uses_sendwhen_or_conditional_provider_gating, weight=2.0)
check("notion gating references qualifying partner types", test_notion_gating_references_qualifying_partner_types, weight=1.5)

check("partner type key consistency across surfaces", test_partner_type_key_is_used_across_schema_ui_and_submit, weight=1.5)
check("integrations route linkage preserved", test_integrations_route_linkage_is_preserved, weight=1.0)
check("partner listing content reachable after routing", test_partner_listing_content_remains_reachable, weight=1.5)
check("gating logic is not placeholder-only", test_gating_logic_is_not_placeholder_only, weight=2.0)
check("secondary surfaces exist", test_secondary_surfaces_exist, weight=1.5)
check("docs navigation/meta wiring signals", test_docs_navigation_and_meta_wiring_signals, weight=1.5)
check("design-system and studio surface signals", test_design_system_and_studio_surface_signals, weight=1.5)

reward = PASSED_WEIGHT / TOTAL_WEIGHT if TOTAL_WEIGHT else 0.0
print(f"\nReward: {reward:.4f}")

os.makedirs("/logs/verifier", exist_ok=True)
with open("/logs/verifier/reward.txt", "w", encoding="utf-8") as f:
    f.write(str(reward))

# Keep verifier non-terminating for partial-credit scoring workflows.
sys.exit(0)
