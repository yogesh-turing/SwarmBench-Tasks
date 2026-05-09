# Node-RED Autonomous Agent Benchmark Suite

This dataset converts selected real Node-RED issues into production-grade autonomous debugging and engineering tasks.

## Structure
- issue-*/benchmark.md: task contract for agents
- issue-*/repro.md: deterministic reproduction and validation notes
- issue-*/metadata.json: machine-readable task metadata
- issue-*/verifier/checks.yaml: pass/fail check scaffold
- splits/*.json: recommended evaluation subsets
- suite-metadata.json: top-level suite summary

## Recommended Use
- Harbor and OpenHands workflows
- SWE-bench style patch-and-verify loops
- Multi-agent orchestration experiments
- Long-horizon debugging and recovery studies

## Notes
- Tasks are designed to require exploration and verification, not trivial one-file edits.
- Keep reproducibility artifacts under each issue folder.
