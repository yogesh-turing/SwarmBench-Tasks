# Reproduction Guide: issue #5683

## Goal
Produce deterministic steps that demonstrate the failure before patching and pass criteria after patching.

## Environment
- Node.js LTS
- Clean install of repository dependencies
- Default local settings unless otherwise specified

## Steps
1. Build and start the relevant Node-RED components.
2. Load provided fixture/config from artifacts/ when applicable.
3. Trigger the user workflow tied to issue #5683.
4. Capture observed behavior and compare against expected behavior.

## Expected Failure Signal (Before Fix)
- The issue-specific incorrect behavior is observable and repeatable.

## Expected Pass Signal (After Fix)
- The incorrect behavior is gone.
- Adjacent behavior remains intact.

## Verification Notes
- Run targeted tests first, then broader suite checks.
- Record commands, logs, and screenshots where relevant.
