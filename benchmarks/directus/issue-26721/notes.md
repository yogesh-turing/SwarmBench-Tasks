# Agent Evaluation Notes

## Why weaker single-agent systems fail

They often misclassify this as a backend authorization bug because the user-visible symptom is a permissions failure. The actual regression for this issue is in the app composables that compute editability and field readonly state.

## Common incorrect fixes

- Change server-side permission policies instead of app behavior
- Bypass all permissions for versioned items, including delete/share
- Special-case only one composable and forget to thread version context through the full permission chain
- Fix `updateAllowed` but forget field readonly logic in `getFields`

## Likely hallucinations or mistakes

- Claiming that version deltas are merged in the frontend and therefore no permission context change is needed
- Assuming the backend promote path is the same as the app-side editability path
- Changing collection-level permission store semantics globally rather than adding explicit version context

## Hidden dependencies

- `useItem()` is the point where route query state first becomes available
- `usePermissions()` and `useItemPermissions()` form a chain; missing the extra argument in one place breaks the fix
- `getFields()` and `isActionAllowed()` must stay behaviorally aligned

## What strong agents should do differently

- Follow the full composable call chain before editing
- Treat main-item state and version-edit state as separate contexts
- Preserve non-version behavior and preserve delete/share restrictions
- Validate with focused app tests rather than broad manual reasoning only