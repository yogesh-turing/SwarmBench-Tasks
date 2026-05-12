# Supabase Partner Experience + Form Flow Update

The repository at `/testbed` is a large Supabase monorepo.

Your goal is to implement the partner experience updates below while keeping changes consistent across routing, forms, schema logic, and submission handling.

The task is intentionally broad and time-constrained, so focus on shipping a complete and coherent implementation rather than over-optimizing individual files.

---

# Main Areas to Work In

## Partner Pages + Routing

- `apps/www/app/layout.tsx`
- `apps/www/app/partners/page.tsx`
- `apps/www/app/partners/PartnersContent.tsx`
- `apps/www/app/partners/integrations/page.tsx`
- `apps/www/app/partners/integrations/IntegrationsContent.tsx`
- `apps/www/pages/_app.tsx`
- `apps/www/pages/partners/index.tsx`
- `apps/www/pages/partners/integrations/index.tsx`

---

## Partner Components + Data

- `apps/www/components/Partners/BecomeAPartner.tsx`
- `apps/www/components/Partners/PartnerIntakeForm.tsx`
- `apps/www/data/partners/index.tsx`

---

## Shared Marketing Form System

- `packages/marketing/index.ts`
- `packages/marketing/src/forms/index.ts`
- `packages/marketing/src/forms/MarketingForm.tsx`
- `packages/marketing/src/forms/HubSpotFormEmbed.tsx`
- `packages/marketing/src/go/schemas.ts`
- `packages/marketing/src/go/sections/FormSection.tsx`
- `packages/marketing/src/go/showWhen.ts`
- `packages/marketing/src/go/actions/submitForm.ts`

---

## Docs / Shared UI Dependencies

- `apps/docs/app/layout.tsx`
- `apps/docs/components/Breadcrumbs.tsx`
- `apps/docs/lib/breadcrumbs.ts`
- `apps/docs/lib/json-ld.ts`
- `apps/docs/styles/globals.css`
- `apps/docs/tailwind.config.cjs`
- `apps/design-system/styles/globals.css`
- `apps/design-system/tailwind.config.js`

---

## Studio References

- `apps/studio/components/interfaces/Docs/Description.tsx`
- `apps/studio/components/interfaces/ProjectAPIDocs/Content/Introduction.tsx`
- `apps/studio/components/layouts/AppLayout/NoticeBanner.tsx`
- `apps/studio/components/interfaces/DatabaseNavShortcuts.tsx`

---

## Partner Integration Pages

- `apps/www/app/partners/integrations/auth0/page.tsx`
- `apps/www/app/partners/integrations/vercel/page.tsx`
- `apps/www/app/partners/integrations/resend/page.tsx`

---

## Related Docs Content

- `apps/docs/content/guides/auth/auth-anonymous.mdx`
- `apps/docs/content/guides/auth/auth-captcha.mdx`
- `apps/docs/content/guides/auth/custom-oauth-providers.mdx`
- `apps/docs/content/guides/getting-started/quickstarts/reactjs.mdx`
- `apps/docs/content/guides/local-development.mdx`
- `apps/docs/content/guides/storage/s3/authentication.mdx`
- `apps/docs/content/guides/storage/uploads/resumable-uploads.mdx`
- `apps/docs/content/guides/telemetry/logs.mdx`
- `apps/docs/content/troubleshooting/auth-error-503-authretryablefetcherror-51b88c.mdx`

---

# Workstream 1 - Partners Routing and Page Migration

Move the partners experience fully onto the App Router implementation.

## Requirements

- `/partners` should be served from the App Router.
- `/partners/integrations` should also use the App Router implementation.
- Existing partner/integration content must still remain accessible after migration.
- All "Become a Partner" CTAs should link to:

```txt
/partners#become-a-partner
```

instead of external hosted form URLs.

---

# Workstream 2 - Inline Partner Intake Form

Add the full partner intake flow directly onto the `/partners` page.

## Requirements

- Render the consolidated intake form inline at:

```txt
/partners#become-a-partner
```

- The form should support conditional sections based on selected partner type.
- Conditional rendering must use the shared `showWhen` behavior.
- Add checkbox-group style multi-select support for the "Solutions" partner track.

---

# Workstream 3 - Shared Marketing Form Engine Consistency

The marketing form engine currently has duplicated or fragmented conditional logic.

## Requirements

- Centralize `showWhen` evaluation into shared logic.
- Avoid separate client/server implementations with different behavior.
- Ensure schemas, rendering, and conditional evaluation all support the same field types and rules.
- Keep exports and module wiring stable across the marketing package.

---

# Workstream 4 - Submission Routing and Provider Gating

Improve how submissions are forwarded to downstream providers.

## Requirements

- Submission fan-out should support provider-level `sendWhen` conditions.
- All submissions must still go to HubSpot.
- Notion sync should only run for qualifying partner types such as `Technology Partner`.
- Non-qualifying submissions must NOT be mirrored to Notion.
- Avoid placeholder-only gating logic. Implement real conditional behavior.

---

# Consistency Expectations

The implementation should behave consistently across the entire flow:

- Routing
- CTA links
- Form rendering
- Conditional visibility
- Validation and schema behavior
- Submission routing
- Provider gating

The same conditional rules used to show or hide form sections in the UI should also drive backend and provider submission behavior.

---

# Constraint

This task is intentionally wide in scope and designed for a limited runtime budget.

Prioritize:

- end-to-end consistency
- reasonable completeness
- working cross-feature integration

over deep optimization or isolated refactors.