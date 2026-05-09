# Snapshot 1 (Pre-remediation Freeze)

Date: 2026-05-09
Task: task_directus_2
Baseline source commit in environment: 2218212e43ed49f0c737deee0dad7ba0d8c4f064

This snapshot freezes key benchmark artifacts before remediation edits.

## File Hashes (SHA-256)

- instruction.md: 764B59F5F816D738AA9884B750FFA353010087CD628BAE2991510B8B7E3F3AC4
- task.toml: A7B3022C8F5D07CA33ED00F9DE45613267E83954419428893DBBAFE119A3739B
- decomposition.yaml: 224A654A5AC109931B129E44A09C66C157A3369A4DEA684CCFD6A9AB46627DE5
- tests/verify.py: C6AFA912C2D3C5EC60CB209452AB37882E563CB4B302B08CDA685CFEE745CDA5
- tests/test.sh: 677389D86D6C63BD8121E072AD4B9BD1028173B114C15823E6392183C2D490D0
- solution/solve.sh: 07FDE2E737068B456A19F579D434025D71E18FE21CAF2C9B97FD736DC7EAA1B3

## Freeze Purpose

- Preserve auditability of the benchmark state prior to requirement-enforcement hardening.
- Enable before/after comparison for instruction cleanliness, verifier strength, and oracle alignment.
- Support downstream gap analysis with reproducible benchmark provenance.
