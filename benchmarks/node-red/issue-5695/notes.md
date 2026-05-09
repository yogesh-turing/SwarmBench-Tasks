# Phase 1 + Gap Analysis

- Issue: #5695
- Fixing PR: https://github.com/node-red/node-red/pull/5700
- Core commit: a232930131017ca80fe20bc8781a5295d142ea94

Context competition: activation semantics, drag lifecycle, and keyboard parity. Single agents often patch the symptom by changing one event hook but miss drag-state cleanup. Multi-agent decomposition isolates these threads.
