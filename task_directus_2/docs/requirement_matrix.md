# Requirement Matrix

Date: 2026-05-09
Task: task_directus_2

## Coverage Table

| Requirement ID | Instruction Requirement (Behavioral) | Verifier Enforcer(s) | Oracle Implementation |
|---|---|---|---|
| R1.1 | No module-scope document listener registration | R1.1-no-top-level-listener | solution/solve.sh ensure_use_shortcut |
| R1.2 | Listener attachment is encapsulated in helper path | R1.2-helper-exists | solution/solve.sh ensure_use_shortcut |
| R1.3 | Listener attachment invoked from onMounted only | R1.3-onmounted-invocation | solution/solve.sh ensure_use_shortcut |
| R1.4 | Listener attachment is idempotent | R1.4-idempotent-attach | solution/solve.sh ensure_use_shortcut |
| R1.5 | Keydown and keyup listeners attached together in helper | R1.5-keydown-keyup-in-helper | solution/solve.sh ensure_use_shortcut |
| R2.1 | tsdown excludes all required test-only paths | R2.1-tsdown-exclusions-present | solution/solve.sh ensure_ts_build_config |
| R2.2 | tsconfig.prod excludes src/test-utils | R2.2-tsconfig-exclude-test-utils | solution/solve.sh ensure_ts_build_config |
| R2.3 | Effective entry behavior excludes test-only inputs and includes production source | R2.3-entry-behavior-simulation | solution/solve.sh ensure_ts_build_config |
| R3.1 | Slash-containing collection names are rejected | R3.1-slash-check | solution/solve.sh ensure_collections_validation |
| R3.2 | Slash rejection uses InvalidPayloadError | R3.2-invalid-payload-error | solution/solve.sh ensure_collections_validation |
| R3.3 | Slash validation occurs before parseCollectionName | R3.3-validation-order | solution/solve.sh ensure_collections_validation |
| R4.1 | save() reads accountability from schema | R4.1-read-accountability | solution/solve.sh ensure_versions_accountability |
| R4.2 | null accountability skips side effects | R4.2-non-null-guard, R4.6-no-unconditional-side-effects | solution/solve.sh ensure_versions_accountability |
| R4.3 | activity mode writes activity only (revision gated out) | R4.3-activity-gated, R4.4-all-guard | solution/solve.sh ensure_versions_accountability |
| R4.4 | all mode writes activity and revision | R4.5-revision-gated | solution/solve.sh ensure_versions_accountability |

## Notes

- Instruction text avoids revealing literal verifier search tokens.
- Verifier uses semantic order checks and a lightweight behavior simulation for build-entry inclusion/exclusion.
- Oracle avoids string-stuffing fallbacks and fails fast if semantic anchors are absent.
