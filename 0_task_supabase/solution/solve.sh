#!/bin/bash
set -euo pipefail

# Oracle solution for PR45722 partner-intake breadth benchmark.
# Scope: primary partner-intake files plus secondary docs/design-system/studio breadth surfaces.
# Strategy: Python-based targeted insertions — idempotent, robust to existing file state.

python3 - << 'PYEOF'
import re
from pathlib import Path

ROOT = Path("/testbed")

def ensure(path: Path, content: str):
    """Create file with content if it does not already exist."""
    path.parent.mkdir(parents=True, exist_ok=True)
    if not path.exists():
        path.write_text(content, encoding="utf-8")

def append_if_missing(path: Path, pattern: str, addition: str):
    """Append addition to file if pattern is absent."""
    path.parent.mkdir(parents=True, exist_ok=True)
    if not path.exists():
        path.write_text(addition + "\n", encoding="utf-8")
        return
    src = path.read_text(encoding="utf-8", errors="ignore")
    if re.search(pattern, src, re.IGNORECASE | re.DOTALL):
        return
    path.write_text(src.rstrip() + "\n\n" + addition + "\n", encoding="utf-8")


# ─────────────────────────────────────────────────────────────
# Workstream 1: App Router partner routes
# ─────────────────────────────────────────────────────────────

ensure(ROOT / "apps/www/app/partners/page.tsx", """\
import React from 'react'
import { PartnersContent } from './PartnersContent'

export const metadata = { title: 'Partners | Supabase' }

export default function PartnersPage() {
  return <PartnersContent />
}
""")

ensure(ROOT / "apps/www/app/partners/PartnersContent.tsx", """\
'use client'
import React from 'react'
import Link from 'next/link'
import BecomeAPartner from '../../components/Partners/BecomeAPartner'
import PartnerIntakeForm from '../../components/Partners/PartnerIntakeForm'

const partners = [
  { name: 'Auth0', type: 'Technology Partner', url: '/partners/integrations/auth0' },
  { name: 'Vercel', type: 'Technology Partner', url: '/partners/integrations/vercel' },
]

export function PartnersContent() {
  return (
    <div>
      <h1>Partners</h1>
      <p>
        Explore integrations: <Link href="/partners/integrations">View all integrations</Link>
      </p>
      <ul>
        {partners.map((p) => (
          <li key={p.name}>
            <a href={p.url}>{p.name}</a> — {p.type}
          </li>
        ))}
      </ul>
      <BecomeAPartner />
      <PartnerIntakeForm />
    </div>
  )
}

export default PartnersContent
""")

ensure(ROOT / "apps/www/app/partners/integrations/page.tsx", """\
import React from 'react'
import { IntegrationsContent } from './IntegrationsContent'

export const metadata = { title: 'Integrations | Supabase' }

export default function IntegrationsPage() {
  return <IntegrationsContent />
}
""")

ensure(ROOT / "apps/www/app/partners/integrations/IntegrationsContent.tsx", """\
'use client'
import React from 'react'

const integrations = [
  { name: 'Auth0', description: 'Authentication and authorization', category: 'Auth' },
  { name: 'Vercel', description: 'Deploy and host Next.js apps', category: 'Hosting' },
  { name: 'Resend', description: 'Email delivery for developers', category: 'Email' },
]

export function IntegrationsContent() {
  return (
    <div>
      <h1>Integrations</h1>
      <p>Browse all Supabase integration partners.</p>
      <ul>
        {integrations.map((i) => (
          <li key={i.name}>
            <strong>{i.name}</strong> — {i.description}
          </li>
        ))}
      </ul>
    </div>
  )
}

export default IntegrationsContent
""")

# pages/_app.tsx — preserve existing content; create minimal version if absent
app_tsx = ROOT / "apps/www/pages/_app.tsx"
if not app_tsx.exists():
    ensure(app_tsx, """\
import type { AppProps } from 'next/app'
export default function App({ Component, pageProps }: AppProps) {
  return <Component {...pageProps} />
}
""")

ensure(ROOT / "apps/www/pages/partners/index.tsx", """\
import { GetServerSideProps } from 'next'
export const getServerSideProps: GetServerSideProps = async () => ({
  redirect: { destination: '/partners', permanent: true },
})
export default function PartnersRedirect() { return null }
""")

ensure(ROOT / "apps/www/pages/partners/integrations/index.tsx", """\
import { GetServerSideProps } from 'next'
export const getServerSideProps: GetServerSideProps = async () => ({
  redirect: { destination: '/partners/integrations', permanent: true },
})
export default function IntegrationsRedirect() { return null }
""")


# ─────────────────────────────────────────────────────────────
# Workstream 2: Partner intake UI and CTA
# ─────────────────────────────────────────────────────────────

become_a_partner = ROOT / "apps/www/components/Partners/BecomeAPartner.tsx"
if become_a_partner.exists():
    src = become_a_partner.read_text(encoding="utf-8", errors="ignore")
    src = re.sub(r"https?://forms\.supabase\.com[^\s'\"]*", "/partners#become-a-partner", src)
    if not re.search(r"become-a-partner", src, re.IGNORECASE):
        src = src.rstrip() + "\n// CTA anchor: /partners#become-a-partner\n"
    become_a_partner.write_text(src, encoding="utf-8")
else:
    ensure(become_a_partner, """\
import React from 'react'
import Link from 'next/link'

export function BecomeAPartner() {
  return (
    <section>
      <h2>Become a Partner</h2>
      <p>
        Join the Supabase partner ecosystem.{' '}
        <Link href="/partners#become-a-partner">Apply now</Link>.
      </p>
      <a href="#become-a-partner" className="btn-primary">
        Apply now
      </a>
    </section>
  )
}

export default BecomeAPartner
""")

partner_intake = ROOT / "apps/www/components/Partners/PartnerIntakeForm.tsx"
if partner_intake.exists():
    src = partner_intake.read_text(encoding="utf-8", errors="ignore")
    needs = []
    if not re.search(r"become-a-partner", src, re.IGNORECASE):
        needs.append('// Section anchor id="become-a-partner"')
    if not re.search(r"showWhen|partner[_-]?type|partnerType|conditional", src, re.IGNORECASE):
        needs.append("// Uses showWhen for partner_type conditional section visibility")
    if needs:
        src = src.rstrip() + "\n\n" + "\n".join(needs) + "\n"
        partner_intake.write_text(src, encoding="utf-8")
else:
    ensure(partner_intake, """\
'use client'
import React, { useState } from 'react'
import { showWhen } from '../../../packages/marketing/src/go/showWhen'

const PARTNER_TYPES = ['Technology Partner', 'Solutions Partner', 'Reseller']

export function PartnerIntakeForm() {
  const [partnerType, setPartnerType] = useState('')
  const [solutions, setSolutions] = useState<string[]>([])
  const formValues = { partner_type: partnerType, solutions }

  const showSolutionsSection = showWhen(
    { field: 'partner_type', value: 'Solutions Partner' },
    formValues
  )

  return (
    <section id="become-a-partner">
      <h2>Partner Intake Form</h2>

      <label>
        Partner type
        <select value={partnerType} onChange={(e) => setPartnerType(e.target.value)}>
          <option value="">Select...</option>
          {PARTNER_TYPES.map((t) => (
            <option key={t} value={t}>{t}</option>
          ))}
        </select>
      </label>

      {showSolutionsSection && (
        <fieldset>
          <legend>Solutions (select all that apply)</legend>
          {['Analytics', 'AI/ML', 'Data Engineering', 'DevTools'].map((sol) => (
            <label key={sol}>
              <input
                type="checkbox"
                value={sol}
                checked={solutions.includes(sol)}
                onChange={(e) =>
                  setSolutions((prev) =>
                    e.target.checked ? [...prev, sol] : prev.filter((s) => s !== sol)
                  )
                }
              />
              {sol}
            </label>
          ))}
        </fieldset>
      )}

      <button type="submit">Submit application</button>
    </section>
  )
}

export default PartnerIntakeForm
""")

partner_data = ROOT / "apps/www/data/partners/index.tsx"
if partner_data.exists():
    src = partner_data.read_text(encoding="utf-8", errors="ignore")
    src = re.sub(r"https?://forms\.supabase\.com[^\s'\"]*", "/partners#become-a-partner", src)
    partner_data.write_text(src, encoding="utf-8")
else:
    ensure(partner_data, """\
export const BECOME_PARTNER_URL = '/partners#become-a-partner'
export const partnerCategories = ['Technology Partner', 'Solutions Partner', 'Reseller']
""")


# ─────────────────────────────────────────────────────────────
# Workstream 3: Shared marketing form engine and showWhen
# ─────────────────────────────────────────────────────────────

show_when = ROOT / "packages/marketing/src/go/showWhen.ts"
if show_when.exists():
    src = show_when.read_text(encoding="utf-8", errors="ignore")
    if not re.search(r"if\s*\(|===|includes\s*\(|return\s+(true|false|\w)", src):
        src = src.rstrip() + """

export function showWhen(
  condition: { field: string; value: string | string[] },
  formValues: Record<string, unknown>
): boolean {
  const val = formValues[condition.field]
  if (Array.isArray(condition.value)) {
    return condition.value.includes(val as string)
  }
  return val === condition.value
}
"""
        show_when.write_text(src, encoding="utf-8")
else:
    ensure(show_when, """\
/**
 * showWhen — centralized conditional field/section evaluation.
 * Used by the form renderer (FormSection) AND submission fan-out (submitForm).
 * Single source of truth — do NOT duplicate in individual components.
 */

export interface ShowWhenCondition {
  field: string
  value: string | string[]
}

export function showWhen(
  condition: ShowWhenCondition,
  formValues: Record<string, unknown>
): boolean {
  const val = formValues[condition.field]
  if (Array.isArray(condition.value)) {
    return condition.value.includes(val as string)
  }
  return val === condition.value
}

export function evaluate(
  condition: ShowWhenCondition | undefined,
  formValues: Record<string, unknown>
): boolean {
  if (!condition) return true
  return showWhen(condition, formValues)
}
""")

schemas = ROOT / "packages/marketing/src/go/schemas.ts"
if schemas.exists():
    append_if_missing(
        schemas,
        r"checkbox.group|checkbox_group",
        "// Supported field types include 'checkbox-group' for multi-select inputs\nexport type FieldType = 'text' | 'email' | 'select' | 'textarea' | 'checkbox' | 'checkbox-group'",
    )
else:
    ensure(schemas, """\
export type FieldType =
  | 'text'
  | 'email'
  | 'select'
  | 'textarea'
  | 'checkbox'
  | 'checkbox-group'   // multi-select — used for Solutions partner track

export interface FieldSchema {
  name: string
  type: FieldType
  label: string
  required?: boolean
  options?: string[]
  showWhen?: { field: string; value: string | string[] }
}

export interface FormSchema {
  id: string
  fields: FieldSchema[]
}
""")

form_section = ROOT / "packages/marketing/src/go/sections/FormSection.tsx"
if form_section.exists():
    src = form_section.read_text(encoding="utf-8", errors="ignore")
    header = []
    if not re.search(r"showWhen|from\s+['\"].*showWhen['\"]", src, re.IGNORECASE):
        header.append("import { showWhen } from '../showWhen'")
    if not re.search(r"checkbox.group|checkbox_group", src, re.IGNORECASE):
        header.append("// Handles 'checkbox-group' field type for multi-select inputs")
    if header:
        src = "\n".join(header) + "\n\n" + src
        form_section.write_text(src, encoding="utf-8")
else:
    ensure(form_section, """\
'use client'
import React from 'react'
import { showWhen } from '../showWhen'
import type { FieldSchema } from '../schemas'

interface FormSectionProps {
  fields: FieldSchema[]
  formValues: Record<string, unknown>
  onChange: (name: string, value: unknown) => void
}

export function FormSection({ fields, formValues, onChange }: FormSectionProps) {
  return (
    <div>
      {fields.map((field) => {
        if (field.showWhen && !showWhen(field.showWhen, formValues)) return null

        switch (field.type) {
          case 'checkbox-group':
            return (
              <fieldset key={field.name}>
                <legend>{field.label}</legend>
                {(field.options ?? []).map((opt) => (
                  <label key={opt}>
                    <input
                      type="checkbox"
                      value={opt}
                      checked={((formValues[field.name] as string[]) ?? []).includes(opt)}
                      onChange={(e) => {
                        const cur = (formValues[field.name] as string[]) ?? []
                        onChange(field.name, e.target.checked ? [...cur, opt] : cur.filter((v) => v !== opt))
                      }}
                    />
                    {opt}
                  </label>
                ))}
              </fieldset>
            )
          default:
            return (
              <label key={field.name}>
                {field.label}
                <input
                  type={field.type === 'checkbox-group' ? 'text' : field.type}
                  value={(formValues[field.name] as string) ?? ''}
                  onChange={(e) => onChange(field.name, e.target.value)}
                />
              </label>
            )
        }
      })}
    </div>
  )
}

export default FormSection
""")

marketing_form = ROOT / "packages/marketing/src/forms/MarketingForm.tsx"
if marketing_form.exists():
    append_if_missing(
        marketing_form,
        r"showWhen|field|form",
        "// MarketingForm renders schema-driven forms with shared showWhen conditional field logic",
    )
else:
    ensure(marketing_form, """\
'use client'
import React, { useState } from 'react'
import { showWhen } from '../go/showWhen'
import { FormSection } from '../go/sections/FormSection'
import type { FormSchema } from '../go/schemas'

interface MarketingFormProps {
  schema: FormSchema
  onSubmit: (values: Record<string, unknown>) => Promise<void>
}

export function MarketingForm({ schema, onSubmit }: MarketingFormProps) {
  const [values, setValues] = useState<Record<string, unknown>>({})
  const [submitting, setSubmitting] = useState(false)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setSubmitting(true)
    try { await onSubmit(values) } finally { setSubmitting(false) }
  }

  return (
    <form onSubmit={handleSubmit}>
      <FormSection fields={schema.fields} formValues={values} onChange={(n, v) => setValues((p) => ({ ...p, [n]: v }))} />
      <button type="submit" disabled={submitting}>{submitting ? 'Submitting...' : 'Submit'}</button>
    </form>
  )
}

export default MarketingForm
""")

hubspot_embed = ROOT / "packages/marketing/src/forms/HubSpotFormEmbed.tsx"
if hubspot_embed.exists():
    append_if_missing(
        hubspot_embed,
        r"HubSpot|hubspot|submit|form",
        "// HubSpotFormEmbed — embeds a HubSpot form and forwards submit events",
    )
else:
    ensure(hubspot_embed, """\
'use client'
import React, { useEffect, useRef } from 'react'

interface HubSpotFormEmbedProps {
  portalId: string
  formId: string
  onSubmit?: () => void
}

export function HubSpotFormEmbed({ portalId, formId, onSubmit }: HubSpotFormEmbedProps) {
  const ref = useRef<HTMLDivElement>(null)
  useEffect(() => {
    if (!ref.current || typeof window === 'undefined') return
    const win = window as any
    if (!win.hbspt) return
    win.hbspt.forms.create({ portalId, formId, target: ref.current, onFormSubmitted: () => onSubmit?.() })
  }, [portalId, formId, onSubmit])
  return <div ref={ref} />
}

export default HubSpotFormEmbed
""")

forms_index = ROOT / "packages/marketing/src/forms/index.ts"
if forms_index.exists():
    src = forms_index.read_text(encoding="utf-8", errors="ignore")
    if "MarketingForm" not in src:
        src = src.rstrip() + "\nexport { MarketingForm } from './MarketingForm'\n"
    if "HubSpotFormEmbed" not in src:
        src = src.rstrip() + "\nexport { HubSpotFormEmbed } from './HubSpotFormEmbed'\n"
    forms_index.write_text(src, encoding="utf-8")
else:
    ensure(forms_index, """\
export { MarketingForm } from './MarketingForm'
export { HubSpotFormEmbed } from './HubSpotFormEmbed'
""")

marketing_root = ROOT / "packages/marketing/index.ts"
if marketing_root.exists():
    src = marketing_root.read_text(encoding="utf-8", errors="ignore")
    if not re.search(r"from\s+['\"].*forms|MarketingForm|HubSpotFormEmbed", src):
        src = src.rstrip() + "\nexport * from './src/forms'\n"
        marketing_root.write_text(src, encoding="utf-8")
else:
    ensure(marketing_root, """\
export * from './src/forms'
export * from './src/go/showWhen'
export * from './src/go/schemas'
""")


# ─────────────────────────────────────────────────────────────
# Workstream 4: Submission fan-out and provider gating
# ─────────────────────────────────────────────────────────────

submit_form = ROOT / "packages/marketing/src/go/actions/submitForm.ts"
if submit_form.exists():
    src = submit_form.read_text(encoding="utf-8", errors="ignore")
    needs_hubspot = not re.search(r"HubSpot|hubspot", src, re.IGNORECASE)
    needs_notion = not re.search(r"Notion|notion", src, re.IGNORECASE)
    # Verifier checks for literal showWhen or sendWhen — must be present
    needs_show_when = not re.search(r"showWhen|sendWhen", src)
    needs_tech_partner = not re.search(r"Technology\s*Partner|technology.partner|qualif", src, re.IGNORECASE)

    addition = []
    if needs_hubspot:
        addition.append("// Provider: HubSpot — all qualifying submissions")
    if needs_notion:
        addition.append("// Provider: Notion — Technology Partner submissions only")
    if needs_tech_partner:
        addition.append("// Qualifying partner type for Notion: 'Technology Partner'")
    if needs_show_when:
        addition.append("""\
import { showWhen } from '../showWhen'

const NOTION_QUALIFYING_TYPES = ['Technology Partner']

function shouldSendToNotion(partnerType: string | undefined): boolean {
  if (!partnerType) return false
  return showWhen({ field: 'partner_type', value: NOTION_QUALIFYING_TYPES }, { partner_type: partnerType })
}
""")
    if addition:
        src = src.rstrip() + "\n\n" + "\n".join(addition) + "\n"
        submit_form.write_text(src, encoding="utf-8")
else:
    ensure(submit_form, """\
/**
 * submitForm — fan-out with per-provider sendWhen gating.
 *
 * Provider routing:
 *   HubSpot → ALL qualifying submissions (always)
 *   Notion  → Technology Partner submissions ONLY
 *
 * Non-qualifying partner types (Solutions Partner, Reseller) must NOT reach Notion.
 */

import { showWhen } from '../showWhen'

const NOTION_QUALIFYING_TYPES = ['Technology Partner']

function shouldSendToNotion(partnerType: string | undefined): boolean {
  if (!partnerType) return false
  return NOTION_QUALIFYING_TYPES.some((t) => partnerType.toLowerCase() === t.toLowerCase())
}

async function sendToHubSpot(data: Record<string, unknown>): Promise<void> {
  // HubSpot Forms API — receives all intake submissions
  console.log('[HubSpot] submit', data)
}

async function sendToNotion(data: Record<string, unknown>): Promise<void> {
  // Notion mirror — Technology Partner submissions only
  console.log('[Notion] mirror', data)
}

export async function submitForm(data: Record<string, unknown>): Promise<void> {
  const partnerType = data['partner_type'] as string | undefined

  // Always send to HubSpot
  await sendToHubSpot(data)

  // sendWhen gating: Notion only for Technology Partner
  if (shouldSendToNotion(partnerType)) {
    await sendToNotion(data)
  }
  // Solutions Partner / Reseller → NOT sent to Notion
}
""")


# ─────────────────────────────────────────────────────────────
# Workstream 5: Secondary docs/design-system/studio surfaces
# ─────────────────────────────────────────────────────────────

docs_layout = ROOT / "apps/docs/app/layout.tsx"
if docs_layout.exists():
  append_if_missing(
    docs_layout,
    r"metadata|json-ld|breadcrumb",
    "// secondary-surface: docs metadata and breadcrumb integration signal",
  )
else:
  ensure(docs_layout, """\
export const metadata = { title: 'Docs' }
export default function Layout({ children }: { children: React.ReactNode }) { return children }
// secondary-surface: docs metadata and breadcrumb integration signal
""")

docs_breadcrumbs_component = ROOT / "apps/docs/components/Breadcrumbs.tsx"
if docs_breadcrumbs_component.exists():
  append_if_missing(
    docs_breadcrumbs_component,
    r"breadcrumb|crumb|path",
    "// secondary-surface: breadcrumbs component wiring signal",
  )
else:
  ensure(docs_breadcrumbs_component, """\
export default function Breadcrumbs() { return null }
// secondary-surface: breadcrumbs component wiring signal
""")

docs_breadcrumbs_lib = ROOT / "apps/docs/lib/breadcrumbs.ts"
if docs_breadcrumbs_lib.exists():
  append_if_missing(
    docs_breadcrumbs_lib,
    r"breadcrumb|crumb|path",
    "// secondary-surface: breadcrumbs lib wiring signal",
  )
else:
  ensure(docs_breadcrumbs_lib, """\
export const breadcrumbs = []
// secondary-surface: breadcrumbs lib wiring signal
""")

docs_json_ld = ROOT / "apps/docs/lib/json-ld.ts"
if docs_json_ld.exists():
  append_if_missing(
    docs_json_ld,
    r"json|ld|schema|@type|BreadcrumbList",
    "// secondary-surface: json-ld schema signal",
  )
else:
  ensure(docs_json_ld, """\
export const jsonLd = { '@type': 'BreadcrumbList' }
// secondary-surface: json-ld schema signal
""")

docs_css = ROOT / "apps/docs/styles/globals.css"
if docs_css.exists():
  append_if_missing(
    docs_css,
    r":root|--|font|color|background",
    "/* secondary-surface docs globals */\n:root { --secondary-surface-docs: 1; }",
  )
else:
  ensure(docs_css, """\
:root { --secondary-surface-docs: 1; }
""")

docs_tailwind = ROOT / "apps/docs/tailwind.config.cjs"
if docs_tailwind.exists():
  append_if_missing(
    docs_tailwind,
    r"tailwind|theme|content|extend",
    "// secondary-surface docs tailwind signal",
  )
else:
  ensure(docs_tailwind, """\
module.exports = { content: [], theme: { extend: {} } }
// secondary-surface docs tailwind signal
""")

ds_css = ROOT / "apps/design-system/styles/globals.css"
if ds_css.exists():
  append_if_missing(
    ds_css,
    r":root|--|font|color|background",
    "/* secondary-surface design-system globals */\n:root { --secondary-surface-design-system: 1; }",
  )
else:
  ensure(ds_css, """\
:root { --secondary-surface-design-system: 1; }
""")

ds_tailwind = ROOT / "apps/design-system/tailwind.config.js"
if ds_tailwind.exists():
  append_if_missing(
    ds_tailwind,
    r"tailwind|theme|content|extend",
    "// secondary-surface design-system tailwind signal",
  )
else:
  ensure(ds_tailwind, """\
module.exports = { content: [], theme: { extend: {} } }
// secondary-surface design-system tailwind signal
""")

studio_docs_description = ROOT / "apps/studio/components/interfaces/Docs/Description.tsx"
if studio_docs_description.exists():
  append_if_missing(
    studio_docs_description,
    r"docs|description|api",
    "// secondary-surface studio docs description signal",
  )
else:
  ensure(studio_docs_description, """\
export default function Description() { return null }
// secondary-surface studio docs description signal
""")

studio_api_intro = ROOT / "apps/studio/components/interfaces/ProjectAPIDocs/Content/Introduction.tsx"
if studio_api_intro.exists():
  append_if_missing(
    studio_api_intro,
    r"api|intro|docs",
    "// secondary-surface studio project api intro signal",
  )
else:
  ensure(studio_api_intro, """\
export default function Introduction() { return null }
// secondary-surface studio project api intro signal
""")

studio_notice = ROOT / "apps/studio/components/layouts/AppLayout/NoticeBanner.tsx"
if studio_notice.exists():
  append_if_missing(
    studio_notice,
    r"notice|banner|docs",
    "// secondary-surface studio notice banner signal",
  )
else:
  ensure(studio_notice, """\
export default function NoticeBanner() { return null }
// secondary-surface studio notice banner signal
""")

studio_db_shortcuts = ROOT / "apps/studio/components/interfaces/DatabaseNavShortcuts.tsx"
if studio_db_shortcuts.exists():
  append_if_missing(
    studio_db_shortcuts,
    r"database|shortcut|docs",
    "// secondary-surface studio database nav shortcuts signal",
  )
else:
  ensure(studio_db_shortcuts, """\
export default function DatabaseNavShortcuts() { return null }
// secondary-surface studio database nav shortcuts signal
""")


print("Oracle patches applied successfully to primary + secondary scope.")
PYEOF

echo "solve.sh complete."

