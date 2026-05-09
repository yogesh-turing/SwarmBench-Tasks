The supabase repository at `/testbed`, it is Postgres development platform. Supabase is a combination of open source tools.

## Affected files

- `apps/studio/components/interfaces/Auth/ProtectionAuthSettingsForm/ProtectionAuthSettingsForm.tsx` — bugs 1
- `apps/studio/components/interfaces/Auth/SessionsAuthSettingsForm/SessionsAuthSettingsForm.tsx` — bugs 1

## Bug reports

**Bug 1** — display inactivity timeout in human readable format

The `auth.sessions.inactivity_timeout` value is correctly configured in `config.toml` using duration format such as:

```
[auth.sessions]
inactivity_timeout = "10h0m0s"
During deployment, the backend correctly converts this value internally to seconds (36000).
```
However, in the Supabase Dashboard/Auth Sessions UI, the value is displayed directly as 36000 without clarifying that the unit is seconds. This creates confusion because users expect the configured duration (10 hours) rather than the raw converted value.
