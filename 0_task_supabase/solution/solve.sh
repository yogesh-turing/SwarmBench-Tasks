#!/bin/bash
set -euo pipefail

cat > /testbed/solution_patch_1.diff << '__BUGFIX1__'
diff --git a/apps/studio/components/interfaces/Auth/ProtectionAuthSettingsForm/ProtectionAuthSettingsForm.tsx b/apps/studio/components/interfaces/Auth/ProtectionAuthSettingsForm/ProtectionAuthSettingsForm.tsx
index f1d8f94d48117..74ec4b1a11111 100644
--- a/apps/studio/components/interfaces/Auth/ProtectionAuthSettingsForm/ProtectionAuthSettingsForm.tsx
+++ b/apps/studio/components/interfaces/Auth/ProtectionAuthSettingsForm/ProtectionAuthSettingsForm.tsx
@@ -167,8 +167,8 @@ export const ProtectionAuthSettingsForm = () => {
           SECURITY_CAPTCHA_ENABLED: authConfig.SECURITY_CAPTCHA_ENABLED,
           SECURITY_CAPTCHA_SECRET: authConfig.SECURITY_CAPTCHA_SECRET || '',
           SECURITY_CAPTCHA_PROVIDER,
-          SESSIONS_TIMEBOX: authConfig.SESSIONS_TIMEBOX || 0,
-          SESSIONS_INACTIVITY_TIMEOUT: authConfig.SESSIONS_INACTIVITY_TIMEOUT || 0,
+          SESSIONS_TIMEBOX: authConfig.SESSIONS_TIMEBOX || 0,
+          SESSIONS_INACTIVITY_TIMEOUT: (authConfig.SESSIONS_INACTIVITY_TIMEOUT || 0) / 3600,
           SESSIONS_SINGLE_PER_USER: authConfig.SESSIONS_SINGLE_PER_USER || false,
           PASSWORD_MIN_LENGTH: authConfig.PASSWORD_MIN_LENGTH || 6,
           PASSWORD_REQUIRED_CHARACTERS:
@@ -184,8 +184,8 @@ export const ProtectionAuthSettingsForm = () => {
           SECURITY_CAPTCHA_ENABLED: authConfig.SECURITY_CAPTCHA_ENABLED,
           SECURITY_CAPTCHA_SECRET: authConfig.SECURITY_CAPTCHA_SECRET || '',
           SECURITY_CAPTCHA_PROVIDER,
-          SESSIONS_TIMEBOX: authConfig.SESSIONS_TIMEBOX || 0,
-          SESSIONS_INACTIVITY_TIMEOUT: authConfig.SESSIONS_INACTIVITY_TIMEOUT || 0,
+          SESSIONS_TIMEBOX: authConfig.SESSIONS_TIMEBOX || 0,
+          SESSIONS_INACTIVITY_TIMEOUT: (authConfig.SESSIONS_INACTIVITY_TIMEOUT || 0) / 3600,
           SESSIONS_SINGLE_PER_USER: authConfig.SESSIONS_SINGLE_PER_USER || false,
           PASSWORD_MIN_LENGTH: authConfig.PASSWORD_MIN_LENGTH || 6,
           PASSWORD_REQUIRED_CHARACTERS:
@@ -206,6 +206,10 @@ export const ProtectionAuthSettingsForm = () => {
     if (payload.PASSWORD_REQUIRED_CHARACTERS === NO_REQUIRED_CHARACTERS) {
       payload.PASSWORD_REQUIRED_CHARACTERS = ''
     }
+    // Convert UI hours back to backend seconds.
+    if (payload.SESSIONS_INACTIVITY_TIMEOUT !== undefined) {
+      payload.SESSIONS_INACTIVITY_TIMEOUT = Math.round(payload.SESSIONS_INACTIVITY_TIMEOUT * 3600)
+    }
 
     updateAuthConfig({ projectRef: projectRef!, config: payload })
   }
diff --git a/apps/studio/components/interfaces/Auth/SessionsAuthSettingsForm/SessionsAuthSettingsForm.tsx b/apps/studio/components/interfaces/Auth/SessionsAuthSettingsForm/SessionsAuthSettingsForm.tsx
index 03b333ed17a84..f84fa8f222222 100644
--- a/apps/studio/components/interfaces/Auth/SessionsAuthSettingsForm/SessionsAuthSettingsForm.tsx
+++ b/apps/studio/components/interfaces/Auth/SessionsAuthSettingsForm/SessionsAuthSettingsForm.tsx
@@ -118,8 +118,9 @@ export const SessionsAuthSettingsForm = () => {
 
       if (!isUpdatingUserSessions) {
         userSessionsForm.reset({
-          SESSIONS_TIMEBOX: authConfig.SESSIONS_TIMEBOX || 0,
-          SESSIONS_INACTIVITY_TIMEOUT: authConfig.SESSIONS_INACTIVITY_TIMEOUT || 0,
+          SESSIONS_TIMEBOX: authConfig.SESSIONS_TIMEBOX || 0,
+          // Convert seconds from backend to hours for display.
+          SESSIONS_INACTIVITY_TIMEOUT: (authConfig.SESSIONS_INACTIVITY_TIMEOUT || 0) / 3600,
           SESSIONS_SINGLE_PER_USER: authConfig.SESSIONS_SINGLE_PER_USER || false,
         })
       }
@@ -147,6 +148,10 @@ export const SessionsAuthSettingsForm = () => {
 
   const onSubmitUserSessions = (values: any) => {
     const payload = { ...values }
+    // Convert UI hours back to backend seconds.
+    if (payload.SESSIONS_INACTIVITY_TIMEOUT !== undefined) {
+      payload.SESSIONS_INACTIVITY_TIMEOUT = Math.round(payload.SESSIONS_INACTIVITY_TIMEOUT * 3600)
+    }
     setIsUpdatingUserSessions(true)
 
     updateAuthConfig(
__BUGFIX1__

cat > /testbed/solution_patch_2.diff << '__BUGFIX2__'
diff --git a/scripts/authorizeVercelDeploys.ts b/scripts/authorizeVercelDeploys.ts
index 8a068193d5144..2b4305949e24b 100644
--- a/scripts/authorizeVercelDeploys.ts
+++ b/scripts/authorizeVercelDeploys.ts
@@ -38,7 +38,13 @@ async function fetchGitHubStatuses(sha: string): Promise<GitHubStatus[]> {
   const url = `https://api.github.com/repos/supabase/supabase/statuses/${sha}`
   console.log(`Fetching GitHub statuses for SHA: ${sha}`)
 
-  const response = await fetch(url)
+  const headers: Record<string, string> = {}
+
+  if (process.env.GITHUB_TOKEN) {
+    headers['Authorization'] = `token ${process.env.GITHUB_TOKEN}`
+  }
+
+  const response = await fetch(url, { headers })
   if (!response.ok) {
     throw new Error(`Failed to fetch GitHub statuses: ${response.status} ${response.statusText}`)
   }
__BUGFIX2__

cat > /testbed/solution_patch_3.diff << '__BUGFIX3__'
diff --git a/apps/www/components/MagnifiedProducts.tsx b/apps/www/components/MagnifiedProducts.tsx
index 685dabbcc10d5..fdd3e8e74875b 100644
--- a/apps/www/components/MagnifiedProducts.tsx
+++ b/apps/www/components/MagnifiedProducts.tsx
@@ -174,7 +174,7 @@ const products = {
     description: 'Integrate your favorite ML-models to store, index and search vector embeddings.',
     description_short: '',
     label: '',
-    url: '/vector',
+    url: '/modules/vector',
   },
 }
__BUGFIX3__

cat > /testbed/solution_patch_4.diff << '__FEAT1__'
diff --git a/apps/design-system/components/color-palette.tsx b/apps/design-system/components/color-palette.tsx
new file mode 100644
index 0000000000000..6c8b74c1ab111
--- /dev/null
+++ b/apps/design-system/components/color-palette.tsx
@@ -0,0 +1,85 @@
+'use client'
+
+import { useState } from 'react'
+import { COPY_FEEDBACK_DURATION_MS, copyToClipboardWithMeta } from './copy-button'
+
+const colorNames = [
+  'Amber',
+  'Blue',
+  'Brand',
+  'Crimson',
+  'Gold',
+  'Gray',
+  'Green',
+  'Indigo',
+  'Orange',
+  'Pink',
+  'Purple',
+  'Red',
+  'Scale',
+  'Slate',
+  'Tomato',
+  'Violet',
+  'Yellow',
+]
+
+const SCALE_STEPS = Array.from({ length: 12 }, (_, i) => i + 1)
+
+const GRID_COLS = 'grid-cols-[6rem_repeat(12,minmax(0,1fr))]'
+
+const ColorPalette = () => {
+  const [copied, setCopied] = useState<string | null>(null)
+
+  const handleCopy = async (value: string) => {
+    try {
+      await copyToClipboardWithMeta(value)
+      setCopied(value)
+      setTimeout(() => setCopied(null), COPY_FEEDBACK_DURATION_MS)
+    } catch (err) {
+      console.error('Failed to copy text: ', err)
+    }
+  }
+
+  return (
+    <div className="my-6 w-full">
+      <div className="flex min-w-[640px] flex-col gap-1">
+        <div className={`grid gap-1 ${GRID_COLS}`}>
+          <div />
+          {SCALE_STEPS.map((step) => (
+            <div key={step} className="text-center font-mono text-[10px] text-foreground-lighter">
+              {step}
+            </div>
+          ))}
+        </div>
+        {colorNames.map((name) => {
+          const slug = name.toLowerCase()
+          return (
+            <div key={slug} className={`grid items-center gap-1 ${GRID_COLS}`}>
+              <div className="pr-2 text-sm font-medium text-foreground">{name}</div>
+              {SCALE_STEPS.map((step) => {
+                const reference = `var(--colors-${slug}${step})`
+                const isCopied = copied === reference
+                return (
+                  <button
+                    key={step}
+                    type="button"
+                    onClick={() => handleCopy(reference)}
+                    className="group relative flex aspect-square w-full items-center justify-center rounded-sm border border-overlay/40 transition hover:scale-[1.05] focus:outline-none focus-visible:ring-2 focus-visible:ring-foreground"
+                    style={{ backgroundColor: reference }}
+                    title={reference}
+                  >
+                    <span className="rounded-xs bg-surface-100/90 px-1 font-mono text-[10px] text-foreground-light opacity-0 transition group-hover:opacity-100">
+                      {isCopied ? 'Copied!' : step}
+                    </span>
+                  </button>
+                )
+              })}
+            </div>
+          )
+        })}
+      </div>
+    </div>
+  )
+}
+
+export { ColorPalette }
diff --git a/apps/design-system/components/mdx-components.tsx b/apps/design-system/components/mdx-components.tsx
index 6d260d75c57b6..d753761ad1516 100644
--- a/apps/design-system/components/mdx-components.tsx
+++ b/apps/design-system/components/mdx-components.tsx
@@ -31,6 +31,7 @@ import { StyleWrapper } from './style-wrapper'
 import { Callout } from '@/components/callout'
 import { CodeBlockWrapper } from '@/components/code-block-wrapper'
 import { CodeFragment } from '@/components/code-fragment'
+import { ColorPalette } from '@/components/color-palette'
 import { Colors } from '@/components/colors'
 import { ComponentExample } from '@/components/component-example'
 import { ComponentPreview } from '@/components/component-preview'
@@ -265,6 +266,7 @@ const components = {
     />
   ),
   Colors,
+  ColorPalette,
   Icons,
   ThemeSettings,
   CodeFragment,
diff --git a/apps/design-system/content/docs/color-usage.mdx b/apps/design-system/content/docs/color-usage.mdx
index e4635a07a70fc..b8f5f16b55567 100644
--- a/apps/design-system/content/docs/color-usage.mdx
+++ b/apps/design-system/content/docs/color-usage.mdx
@@ -69,3 +69,10 @@ This is not to be confused with `Dialogs`, they require to use the same app back
 These can also be accessed with `foreground`. Like `text-foreground-light`.
 
 <Colors definition={'colors'} />
+
+## Color palette
+
+Every Radix scale exposed via `--colors-{name}{1..12}`. Click a swatch to copy the CSS variable reference. The colors are taken
+from `@radix-ui/colors` v0.1.9 except the `Brand` and `Scale` colors.
+
+<ColorPalette />
__FEAT1__

cat > /testbed/solution_patch_5.diff << '__BUGFIX4__'
diff --git a/scripts/authorizeVercelDeploys.ts b/scripts/authorizeVercelDeploys.ts
index 2b4305949e24b..a30f95e8bc001 100644
--- a/scripts/authorizeVercelDeploys.ts
+++ b/scripts/authorizeVercelDeploys.ts
@@ -1,4 +1,21 @@
 import { exec } from 'child_process'
 import { promisify } from 'util'
 
+const MAX_RETRIES = 2
+const REQUEST_TIMEOUT_MS = 10_000
+
+function createTimeoutSignal() {
+  const controller = new AbortController()
+  setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS)
+  return controller.signal
+}
+
+function isRetryableStatus(status: number) {
+  return status === 429 || status >= 500
+}
+
+async function waitForRetry(attempt: number) {
+  await new Promise((resolve) => setTimeout(resolve, 1000 * (attempt + 1)))
+}
+
 interface GitHubStatus {
   state: 'success' | 'pending' | 'failure'
   description: string
__BUGFIX4__

cat > /testbed/solution_patch_6.diff << '__BUGFIX5__'
diff --git a/apps/www/components/MagnifiedProducts.tsx b/apps/www/components/MagnifiedProducts.tsx
index fdd3e8e74875b..8d3c4e6f9b2f7 100644
--- a/apps/www/components/MagnifiedProducts.tsx
+++ b/apps/www/components/MagnifiedProducts.tsx
@@ -174,7 +174,7 @@ const products = {
     description: 'Integrate your favorite ML-models to store, index and search vector embeddings.',
     description_short: '',
-    label: '',
+    label: 'Beta',
     url: '/modules/vector',
   },
 }
__BUGFIX5__

cat > /testbed/solution_patch_7.diff << '__FEAT2__'
diff --git a/apps/design-system/components/color-palette.tsx b/apps/design-system/components/color-palette.tsx
index 6c8b74c1ab111..8a91d7fcd2222 100644
--- a/apps/design-system/components/color-palette.tsx
+++ b/apps/design-system/components/color-palette.tsx
@@ -63,13 +63,17 @@ const ColorPalette = () => {
                   <button
                     key={step}
                     type="button"
                     onClick={() => handleCopy(reference)}
+                    tabIndex={0}
                     className="group relative flex aspect-square w-full items-center justify-center rounded-sm border border-overlay/40 transition hover:scale-[1.05] focus:outline-none focus-visible:ring-2 focus-visible:ring-foreground"
                     style={{ backgroundColor: reference }}
                     title={reference}
+                    aria-label={`Copy ${name} color ${step} CSS variable`}
+                    data-copy-variable={reference}
+                    data-copied={isCopied}
                   >
                     <span className="rounded-xs bg-surface-100/90 px-1 font-mono text-[10px] text-foreground-light opacity-0 transition group-hover:opacity-100">
                       {isCopied ? 'Copied!' : step}
                     </span>
__FEAT2__

cat > /testbed/solution_patch_8.diff << '__FEAT3__'
diff --git a/apps/design-system/components/copy-button.tsx b/apps/design-system/components/copy-button.tsx
index 3513e88f7e111..4ab6e22d8f222 100644
--- a/apps/design-system/components/copy-button.tsx
+++ b/apps/design-system/components/copy-button.tsx
@@ -12,6 +12,8 @@ interface CopyButtonProps extends React.HTMLAttributes<HTMLButtonElement> {
   //   event?: Event['name']
 }
 
+export const COPY_FEEDBACK_DURATION_MS = 1500
+
 export async function copyToClipboardWithMeta(
   value: string
   // event?: Event
@@ -31,7 +33,7 @@ export function CopyButton({
   React.useEffect(() => {
     if (hasCopied) {
       setTimeout(() => {
         setHasCopied(false)
-      }, 2000)
+      }, COPY_FEEDBACK_DURATION_MS)
     }
   }, [hasCopied])
@@ -66,7 +68,7 @@ export function CopyWithClassNames({
   React.useEffect(() => {
     setTimeout(() => {
       setHasCopied(false)
-    }, 2000)
+    }, COPY_FEEDBACK_DURATION_MS)
   }, [hasCopied])
 
   const copyToClipboard = React.useCallback((value: string) => {
diff --git a/apps/design-system/content/docs/accessibility.mdx b/apps/design-system/content/docs/accessibility.mdx
index 5f9d4f6d90111..aa4d991c90222 100644
--- a/apps/design-system/content/docs/accessibility.mdx
+++ b/apps/design-system/content/docs/accessibility.mdx
@@ -94,3 +94,6 @@
 Never use `aria-hidden={true}` on focusable elements, since these are critical pieces of functionality.
+
+Interactive color swatches, such as the design-system ColorPalette, should expose a descriptive `aria-label`
+and remain keyboard focusable with `tabIndex={0}` so the same copy interaction is available to non-pointer users.
__FEAT3__

cd /testbed
patch --fuzz=5 -p1 -i /testbed/solution_patch_1.diff
patch --fuzz=5 -p1 -i /testbed/solution_patch_2.diff
patch --fuzz=5 -p1 -i /testbed/solution_patch_3.diff
patch --fuzz=5 -p1 -i /testbed/solution_patch_4.diff
patch --fuzz=5 -p1 -i /testbed/solution_patch_5.diff
patch --fuzz=5 -p1 -i /testbed/solution_patch_6.diff
patch --fuzz=5 -p1 -i /testbed/solution_patch_7.diff
patch --fuzz=5 -p1 -i /testbed/solution_patch_8.diff
