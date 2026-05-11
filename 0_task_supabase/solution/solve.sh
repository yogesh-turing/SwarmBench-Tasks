#!/bin/bash
set -euo pipefail

cat > /testbed/solution_patch_1.diff << '__BUGFIX1__'
diff --git a/apps/studio/components/interfaces/Auth/ProtectionAuthSettingsForm/ProtectionAuthSettingsForm.tsx b/apps/studio/components/interfaces/Auth/ProtectionAuthSettingsForm/ProtectionAuthSettingsForm.tsx
index f1d8f94d48117..074a988811ad5 100644
--- a/apps/studio/components/interfaces/Auth/ProtectionAuthSettingsForm/ProtectionAuthSettingsForm.tsx
+++ b/apps/studio/components/interfaces/Auth/ProtectionAuthSettingsForm/ProtectionAuthSettingsForm.tsx
@@ -49,6 +49,14 @@ const CAPTCHA_PROVIDERS = [
 
 type CaptchaProviders = 'hcaptcha' | 'turnstile'
 
+function secondsToHours(seconds: number): number {
+  return seconds / 3600
+}
+
+function hoursToSeconds(hours: number): number {
+  return Math.round(hours * 3600)
+}
+
 const baseSchema = z.object({
   DISABLE_SIGNUP: z.boolean(),
   EXTERNAL_ANONYMOUS_USERS_ENABLED: z.boolean(),
@@ -167,8 +175,10 @@ export const ProtectionAuthSettingsForm = () => {
           SECURITY_CAPTCHA_ENABLED: authConfig.SECURITY_CAPTCHA_ENABLED,
           SECURITY_CAPTCHA_SECRET: authConfig.SECURITY_CAPTCHA_SECRET || '',
           SECURITY_CAPTCHA_PROVIDER,
-          SESSIONS_TIMEBOX: authConfig.SESSIONS_TIMEBOX || 0,
-          SESSIONS_INACTIVITY_TIMEOUT: authConfig.SESSIONS_INACTIVITY_TIMEOUT || 0,
+          SESSIONS_TIMEBOX: secondsToHours(authConfig.SESSIONS_TIMEBOX || 0),
+          SESSIONS_INACTIVITY_TIMEOUT: secondsToHours(
+            authConfig.SESSIONS_INACTIVITY_TIMEOUT || 0
+          ),
           SESSIONS_SINGLE_PER_USER: authConfig.SESSIONS_SINGLE_PER_USER || false,
           PASSWORD_MIN_LENGTH: authConfig.PASSWORD_MIN_LENGTH || 6,
           PASSWORD_REQUIRED_CHARACTERS:
@@ -184,8 +194,10 @@ export const ProtectionAuthSettingsForm = () => {
           SECURITY_CAPTCHA_ENABLED: authConfig.SECURITY_CAPTCHA_ENABLED,
           SECURITY_CAPTCHA_SECRET: authConfig.SECURITY_CAPTCHA_SECRET || '',
           SECURITY_CAPTCHA_PROVIDER,
-          SESSIONS_TIMEBOX: authConfig.SESSIONS_TIMEBOX || 0,
-          SESSIONS_INACTIVITY_TIMEOUT: authConfig.SESSIONS_INACTIVITY_TIMEOUT || 0,
+          SESSIONS_TIMEBOX: secondsToHours(authConfig.SESSIONS_TIMEBOX || 0),
+          SESSIONS_INACTIVITY_TIMEOUT: secondsToHours(
+            authConfig.SESSIONS_INACTIVITY_TIMEOUT || 0
+          ),
           SESSIONS_SINGLE_PER_USER: authConfig.SESSIONS_SINGLE_PER_USER || false,
           PASSWORD_MIN_LENGTH: authConfig.PASSWORD_MIN_LENGTH || 6,
           PASSWORD_REQUIRED_CHARACTERS:
@@ -197,7 +209,11 @@ export const ProtectionAuthSettingsForm = () => {
   }, [authConfig, isUpdatingConfig])
 
   const onSubmitProtection = (values: any) => {
-    const payload = { ...values }
+    const payload = {
+      ...values,
+      SESSIONS_TIMEBOX: hoursToSeconds(values.SESSIONS_TIMEBOX),
+      SESSIONS_INACTIVITY_TIMEOUT: hoursToSeconds(values.SESSIONS_INACTIVITY_TIMEOUT),
+    }
     payload.DISABLE_SIGNUP = !values.DISABLE_SIGNUP
     // The backend uses empty string to represent no required characters in the password
     if (payload.PASSWORD_REQUIRED_CHARACTERS === NO_REQUIRED_CHARACTERS) {
diff --git a/apps/studio/components/interfaces/Auth/SessionsAuthSettingsForm/SessionsAuthSettingsForm.tsx b/apps/studio/components/interfaces/Auth/SessionsAuthSettingsForm/SessionsAuthSettingsForm.tsx
index 03b333ed17a84..36064088cecb5 100644
--- a/apps/studio/components/interfaces/Auth/SessionsAuthSettingsForm/SessionsAuthSettingsForm.tsx
+++ b/apps/studio/components/interfaces/Auth/SessionsAuthSettingsForm/SessionsAuthSettingsForm.tsx
@@ -48,6 +48,14 @@ function HoursOrNeverText({ value }: { value: number }) {
   }
 }
 
+function secondsToHours(seconds: number): number {
+  return seconds / 3600
+}
+
+function hoursToSeconds(hours: number): number {
+  return Math.round(hours * 3600)
+}
+
 const RefreshTokenSchema = z.object({
   REFRESH_TOKEN_ROTATION_ENABLED: z.boolean(),
   SECURITY_REFRESH_TOKEN_REUSE_INTERVAL: z.coerce.number().min(0, 'Must be a value more than 0'),
@@ -118,8 +126,10 @@ export const SessionsAuthSettingsForm = () => {
 
       if (!isUpdatingUserSessions) {
         userSessionsForm.reset({
-          SESSIONS_TIMEBOX: authConfig.SESSIONS_TIMEBOX || 0,
-          SESSIONS_INACTIVITY_TIMEOUT: authConfig.SESSIONS_INACTIVITY_TIMEOUT || 0,
+          SESSIONS_TIMEBOX: secondsToHours(authConfig.SESSIONS_TIMEBOX || 0),
+          SESSIONS_INACTIVITY_TIMEOUT: secondsToHours(
+            authConfig.SESSIONS_INACTIVITY_TIMEOUT || 0
+          ),
           SESSIONS_SINGLE_PER_USER: authConfig.SESSIONS_SINGLE_PER_USER || false,
         })
       }
@@ -146,7 +156,11 @@ export const SessionsAuthSettingsForm = () => {
   }
 
   const onSubmitUserSessions = (values: any) => {
-    const payload = { ...values }
+    const payload = {
+      ...values,
+      SESSIONS_TIMEBOX: hoursToSeconds(values.SESSIONS_TIMEBOX),
+      SESSIONS_INACTIVITY_TIMEOUT: hoursToSeconds(values.SESSIONS_INACTIVITY_TIMEOUT),
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
index 0000000000000..2f8f3012bd7ec
--- /dev/null
+++ b/apps/design-system/components/color-palette.tsx
@@ -0,0 +1,84 @@
+'use client'
+
+import { useState } from 'react'
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
+      await navigator.clipboard.writeText(value)
+      setCopied(value)
+      setTimeout(() => setCopied(null), 1500)
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
index 2b4305949e24b..d8a2a0b6f1c8e 100644
--- a/scripts/authorizeVercelDeploys.ts
+++ b/scripts/authorizeVercelDeploys.ts
@@ -1,6 +1,9 @@
 import { exec } from 'child_process'
 import { promisify } from 'util'
 
+const MAX_RETRIES = 2
+const REQUEST_TIMEOUT_MS = 10_000
+
 interface GitHubStatus {
   state: 'success' | 'pending' | 'failure'
   description: string
@@ -38,14 +41,41 @@ async function fetchGitHubStatuses(sha: string): Promise<GitHubStatus[]> {
   const url = `https://api.github.com/repos/supabase/supabase/statuses/${sha}`
   console.log(`Fetching GitHub statuses for SHA: ${sha}`)
 
-  const headers: Record<string, string> = {}
-  
-  if (process.env.GITHUB_TOKEN) {
-    headers['Authorization'] = `token ${process.env.GITHUB_TOKEN}`
-  }
-
-  const response = await fetch(url, { headers })
-  if (!response.ok) {
-    throw new Error(`Failed to fetch GitHub statuses: ${response.status} ${response.statusText}`)
+  for (let attempt = 0; attempt <= MAX_RETRIES; attempt++) {
+    try {
+      const controller = new AbortController()
+      const timeoutId = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS)
+
+      const headers: Record<string, string> = {}
+      if (process.env.GITHUB_TOKEN) {
+        headers['Authorization'] = `token ${process.env.GITHUB_TOKEN}`
+      }
+
+      const response = await fetch(url, { headers, signal: controller.signal })
+      clearTimeout(timeoutId)
+
+      if (!response.ok) {
+        const isTransient = response.status === 429 || response.status >= 500
+        if (isTransient && attempt < MAX_RETRIES) {
+          console.log(`Transient failure (${response.status}), retrying... (attempt ${attempt + 1}/${MAX_RETRIES})`)
+          await new Promise(resolve => setTimeout(resolve, 1000 * (attempt + 1)))
+          continue
+        }
+        throw new Error(`Failed to fetch GitHub statuses: ${response.status} ${response.statusText}`)
+      }
+
+      const data = await response.json()
+      return data.filter((status: GitHubStatus) => status.target_url)
+    } catch (error) {
+      if (attempt === MAX_RETRIES) throw error
+      console.log(`Request failed (${error}), retrying...`)
+      await new Promise(resolve => setTimeout(resolve, 1000 * (attempt + 1)))
+    }
   }
+
+  throw new Error('Failed to fetch GitHub statuses after retries')
 }
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
index 2f8f3012bd7ec..4a1c2e1a8f3e2 100644
--- a/apps/design-system/components/color-palette.tsx
+++ b/apps/design-system/components/color-palette.tsx
@@ -61,13 +61,16 @@ const ColorPalette = () => {
                   <button
                     key={step}
                     type="button"
                     onClick={() => handleCopy(reference)}
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
diff --git a/apps/design-system/content/docs/color-usage.mdx b/apps/design-system/content/docs/color-usage.mdx
index b8f5f16b55567..e4c3e08a1b08e 100644
--- a/apps/design-system/content/docs/color-usage.mdx
+++ b/apps/design-system/content/docs/color-usage.mdx
@@ -72,8 +72,9 @@ These can also be accessed with `foreground`. Like `text-foreground-light`.
 
 ## Color palette
 
-Every Radix scale exposed via `--colors-{name}{1..12}`. Click a swatch to copy the CSS variable reference. The colors are taken
-from `@radix-ui/colors` v0.1.9 except the `Brand` and `Scale` colors.
+Every Radix scale exposed via `--colors-{name}{1..12}`. Click a swatch to copy the CSS variable reference. Accessible labels indicate the copied state and provide clear feedback on interaction. The colors are taken
+from `@radix-ui/colors` v0.1.9 except the `Brand` and `Scale` colors.
 
 <ColorPalette />
__FEAT2__

cd /testbed
patch --fuzz=5 -p1 -i /testbed/solution_patch_1.diff
patch --fuzz=5 -p1 -i /testbed/solution_patch_2.diff
patch --fuzz=5 -p1 -i /testbed/solution_patch_3.diff
patch --fuzz=5 -p1 -i /testbed/solution_patch_4.diff
patch --fuzz=5 -p1 -i /testbed/solution_patch_5.diff
patch --fuzz=5 -p1 -i /testbed/solution_patch_6.diff
patch --fuzz=5 -p1 -i /testbed/solution_patch_7.diff