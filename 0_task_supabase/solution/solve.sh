#!/bin/bash
set -euo pipefail

cat > /testbed/solution_patch.diff << '__BUGFIX1__'
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

cd /testbed
patch --fuzz=5 -p1 -i /testbed/solution_patch.diff
