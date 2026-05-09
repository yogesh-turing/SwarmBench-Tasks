# Incident: Selected Node Halo Fails to Track Status Mutations

Selection visuals become stale when node status changes while the node remains selected. This causes incorrect geometry and stale interaction affordances.

Fix status/halo synchronization so visual state updates correctly under dynamic status mutations.

## Requirements
- Selection halo dimensions must remain consistent with current status presentation.
- Changes must work for status icon and status text combinations.
- Existing node button/geometry behavior must not regress.

## Verifier-Enforced Constraints
- Status redraw path must compute and apply updated halo dimensions.
- Node button rendering path must preserve halo width behavior.
- Core redraw flow must continue to pass test invocation.

## Definition of Done
- Behavioral and static checks pass.
- No regressions in selection halo geometry under dynamic status updates.
