# Summary: Creating SwarmBench Tasks Where Single Agents Fail by ≥23%

## Goal

Build tasks where:
- **Single agent scores X**
- **Multi-agent scores X + ≥0.23**
- The gap is structural — not luck, not difficulty, but architecture

The task must be impossible (or unreliable) for one agent by design, and solvable by a coordinated team.

---

## Why Single Agents Fail (The Core Mechanisms)

Understanding these failure modes is the key to designing tasks correctly.

### 1. Context Overflow
A single agent has a fixed context window. When a task requires reading or modifying more content than fits in that window, the agent loses earlier information as it goes deeper. It starts making contradictory changes, forgetting files it already touched, or hallucinating content.

**Example:** A codebase with 30+ files that must all be changed in a consistent way. By file 10, the agent has pushed file 1 out of context.

### 2. Attention Degradation
Even within context limits, quality degrades as token count increases. With 500K tokens in context, signal-to-noise collapses — the agent starts confusing details between modules, attributing logic to the wrong subsystem, or hallucinating that it already fixed something it hasn't.

### 3. Competing Technical Threads
When a task has multiple distinct technical concerns (e.g., security, compatibility, serialization, query optimization) that each need deep focus, a single agent must context-switch. Each switch costs precision. A multi-agent system gives each thread its own isolated context.

### 4. Cross-Subsystem Synthesis Requirement
When the correct solution requires integrating work from multiple independent subsystems — and each subsystem requires enough investigation to fill significant context — a single agent cannot hold all subsystems in mind simultaneously for final synthesis.

### 5. Time Budget (Timeout-Based Failure)
For large tasks, set `timeout_sec` to the time multi-agent needs to succeed. A single agent attempting the same scope within that window will necessarily do incomplete work. This is a valid structural failure.

---

## What Makes a Task Structurally Multi-Agent-Requiring

### For Code/SWE Tasks (executable verifier)

**Strong signals that a task REQUIRES multi-agent:**

| Signal | Why It Forces Multi-Agent |
|--------|--------------------------|
| 20+ files changed across multiple subsystems | Single agent runs out of context navigating and patching all of them |
| Multiple interacting technical threads (ORM + migrations + serialization) | Each thread needs focused isolated context |
| Changes must be consistent across modules that don't share code | Single agent loses thread consistency across distant files |
| A CVE or bug that exists in 30+ call sites across 3 services | Single agent patches 10, misses 20, introduces regressions |
| Cross-module refactor with regression risk in each module | Agents each own a module; orchestrator resolves conflicts |

**Weak signals (avoid these — they don't force multi-agent):**
- Many files changed, but all changes are the same pattern (one agent can loop)
- Large PR but all changes in one logical subsystem
- File count driven by fixtures, docs, or generated output
- "Different domains" as the only justification for splitting

### For Knowledge/Research Tasks (llm-judge verifier)

| Signal | Why It Forces Multi-Agent |
|--------|--------------------------|
| 500K+ tokens of input material | Single agent loses early material before synthesis |
| 10+ papers/reports each needing structured extraction | Single agent conflates details by document 7 |
| Synthesis from 3+ independent data domains | Single agent cannot hold all domains simultaneously at synthesis time |

---

## Anatomy of a Strong Task: What You Must Produce

Every task requires three fundamental components:

### 1. Real-World Scenario Prompt with Authentic Context

Do **not** invent the problem. Surf the web, GitHub, industry resources to gather authentic, large-context material from your domain.

**For code/SWE tasks:**
- Clone and study real open-source repositories
- Read actual incident postmortems (GitHub issues, blog posts, vulnerability disclosures)
- Research real CVEs or production bugs reported in live systems
- Use actual codebase snapshots at specific commits or tags as grounding

**For knowledge/research tasks:**
- Collect real research papers, datasets, regulatory documents
- Use authentic corpora (medical case files, financial reports, benchmark surveys)
- Ground the task in material that professionals actually work with — not synthetic data

**Why this matters:** Authentic context makes the problem space realistic. A single agent struggling with a real 200K-line codebase is fundamentally different from struggling with a toy 50-file scenario. Multi-agent coordination only becomes necessary when the scope and interconnection genuinely exceed single-agent capacity.

### 2. Concrete Problem Statement

Frame a specific, professional task on top of that context.

**The problem statement must:**
- Be stated the way a professional would receive a task (specific, bounded, actionable)
- Clearly describe what "success" looks like
- Name all constraints the verifier will enforce
- Surface any critical file paths, identifiers, or requirements
- **NOT** be overspecified (don't hand out the exact implementation recipe)

**The problem must be inherently parallelizable:**
- Multiple independent technical threads that each need deep focus
- Work that can proceed in isolation without blocking other agents
- A synthesis step where results from parallel agents must be integrated
- A way that one agent would have to context-switch, while a team wouldn't

### 3. Golden Solution + Deterministic Test Cases

**Golden solution:**
- The reference correct output (oracle.json for llm-judge, solve.sh for executable)
- Must be fully reproducible and score 1.0 on your verifier
- Must be self-contained (no network fetches, no external state)

**Test cases:**
- Deterministic checks that grade any submission against the gold
- For code/SWE: ≥50% weight on behavioral execution (actually running code)
- For knowledge/research: structured extraction with exact comparison or LLM judge
- Both: early test cases catch low-hanging errors; late test cases catch subtle bugs

**Performance bar:**
- **Multi-agent must outperform single-agent by ≥0.23 points**
- If gap is < 0.23, the task fails the benchmark quality threshold
- If multi-agent and single-agent both score similarly (both high or both low), the task is not valid
- If single-agent actually outperforms multi-agent, the task architecture is broken

---

## How to Choose the Right PR for a Code/SWE Task

Follow this workflow: **LLM search → manual shortlist → build → validate → keep or discard**

### Step 1: Hard Requirements for PR Selection
A candidate PR must be:
- Merged/closed (preferred; open is also acceptable)
- Real SWE/code work — not docs-only, not UI polish, not fixture churn
- **At least 20 files changed** — real code files, not generated/template/screenshot files
- Touching **multiple interacting subsystems** (ORM + schema, concurrency + locking, migrations + serialization, etc.)
- Believable multi-agent decomposition: each subagent owns a meaningful workstream, not just "agent A has file 1"

### Step 2: Ask the Core Question
> "Can one agent solve this comfortably in one pass, or does it require synthesis across multiple technical threads?"

If one agent can solve it in one pass → reject the PR.

### Step 3: Decide the Task Shape Before Building
Before writing any files, decide:
- Is this `fan-out-synthesize` or `map-reduce`?
- What exactly does the verifier test?
- Why will single-agent fail?
- Why will multi-agent succeed?

**Use `fan-out-synthesize` when:** multiple distinct technical threads each need focused work, then integration.  
**Use `map-reduce` when:** many similar units of work, each handled the same way, correctness depends on aggregating all results.

For most strong SWE PRs, `fan-out-synthesize` is the right pattern.

---

## Designing the Decomposition to Force Multi-Agent Success

The decomposition is not just documentation — it is the mechanism that gives multi-agent its advantage.

### Good Decomposition
- Each subagent owns a **meaningful workstream**, not just a file or directory
- Descriptions are **outcome-oriented**: what each agent must deliver, not how to code it
- Each subagent has **complete, isolated context** — they don't share state with other subagents
- The orchestrator synthesizes the results, resolving conflicts and ensuring consistency

### Bad Decomposition (Will Be Rejected)
- "Agent A handles file 1, agent B handles file 2" — this is parallel file editing, not coordination
- Descriptions that include exact code strings, function signatures, or line-by-line steps (turns decomposition into an answer key)
- Subagent split that a single agent could replicate trivially by just working sequentially

### Example Good Decomposition (fan-out-synthesize)
```yaml
agents:
  - name: agent-query-compiler
    scope: "Investigate and fix all query compilation issues in the ORM layer. Identify incorrect AST transformations and fix them without breaking backward compatibility."
  - name: agent-backend-adapters
    scope: "Audit backend-specific SQL generation for PostgreSQL, MySQL, and SQLite. Ensure each backend produces correct output for the changed query semantics."
  - name: agent-migrations
    scope: "Update migration serialization and deserialization to handle new field types introduced by the ORM changes."
  - name: agent-test-regression
    scope: "Run the full test suite, identify all newly failing tests, and determine which failures are expected regressions vs. bugs."
  - name: agent-orchestrator
    scope: "Receive all sub-agent patches. Resolve merge conflicts. Verify the integrated result passes all tests."
```

---

## Task File Structure and Key Rules

```
<task_root>/
├── instruction.md          # Human-authored, professional-quality prompt
├── task.toml               # Metadata: domain, pattern, AHT, timeout
├── decomposition.yaml      # Work division plan (not implementation recipe)
├── environment/
│   └── Dockerfile          # Pinned base image, no kimi-cli, rm -rf .git
├── tests/
│   ├── test.sh             # Calls verify.py, writes reward.txt
│   └── verify.py           # ≥50% behavioral tests, ≤50% static checks
├── solution/
│   └── solve.sh            # Gold oracle — self-contained, no curl/wget
└── execution_logs/
    ├── oracle/             # Must exist, mean reward = 1.0
    ├── single-kimi-agent/  # 1 run
    └── multi-kimi-agent/   # 1 run, gap ≥ 0.23
```

### Critical Rules

**instruction.md**
- Human-authored only — do not generate it with an LLM
- State every constraint the verifier checks
- Name all critical file paths, functions, or identifiers the verifier enforces
- Do not hide requirements — if the verifier checks for it, the prompt must surface it

**Dockerfile**
- Never install `kimi-cli` or `kimi-agent-sdk` — Harbor installs these automatically
- Pin exact base image versions: `python:3.9.18-slim` not `python:3.9-slim`
- Remove `.git` directory after checkout to prevent answer leakage via commit history
- No `npm install kimi-*` or similar

**solve.sh (Gold Oracle)**
- Fully self-contained — no `curl`, `wget`, or any external URL
- Use inline heredocs for patches, not downloaded diffs
- Must produce oracle reward = 1.0 when run through Harbor

**verify.py**
- ≥50% of score weight must come from behavioral/functional tests (actually running code)
- Substring/static checks should be ≤50% and only as lightweight guardrails
- A non-working solution that inserts dead code should not be able to pass

**decomposition.yaml**
- Describe what each subagent must accomplish (deliverables)
- Do not include exact code strings, attribute names, or line-by-line steps
- Use `fan-out-synthesize` or `map-reduce` — avoid weaker patterns unless justified

---

## The Scoring Gap: Making It ≥23 Points

The gap requirement is `multi_score - single_score ≥ 0.23`.

### Levers to Increase the Gap

1. **Increase scope beyond single-agent context budget**  
   More files, more subsystems, more interdependencies → single agent runs out of context.

2. **Tighten the timeout**  
   Set `timeout_sec` to the time multi-agent needs. Single agent cannot finish the same scope in the same window.

3. **Require cross-subsystem consistency**  
   Verifier checks that subsystem A and subsystem B are consistent with each other. Single agent loses this thread. Multi-agent orchestrator enforces it.

4. **Make each technical thread deep**  
   If each workstream requires meaningful investigation (not just "find and replace"), a single agent context-switches poorly. Each subagent stays focused.

5. **Weight verifier toward integration tests**  
   If passing requires all subsystems to work together correctly, partial solutions (what single agent produces) score low. Complete multi-agent synthesis scores high.

### Signs the Gap Will Be Too Small
- The task can be solved by one agent working sequentially through files
- The decomposition is just "one file per agent"
- A large file count but all changes are the same pattern
- The verifier weights static checks too heavily (easy to game)

---

## Validation Workflow

Run in this exact order:

1. **Oracle** (`-a oracle`): Must score 1.0. Fix verifier or solve.sh until it does.
2. **Single agent** (`-a swarm-kimi-single`, 1 run): Record score.
3. **Multi agent** (`-a swarm-kimi-multi`, 1 run): Record score.
4. **Check gap**: `multi - single ≥ 0.23`

**What each run tells you:**
- Oracle = 1.0 validates that your golden solution is correct and your verifier is fair
- Single agent score shows how well one model handles the full scope alone
- Multi agent score shows how well the team coordinates using your decomposition
- The gap (≥0.23) proves that multi-agent decomposition is necessary, not optional

**Gap too small?** Do not force weak PRs. Instead:
- Is the scenario truly authentic and complex enough? (real 200K codebase vs. toy 50-file mock)
- Is the problem statement parallelizable, or can one agent solve it sequentially?
- Do multiple technical threads genuinely need focus, or is it the same pattern repeated?
- Is the verifier measuring integration (synthesis of multiple agents' work) or just aggregation?
- Is decomposition outcome-focused (meaningful workstreams) or just file-splitting?

If after good-faith design the gap remains < 0.23, **switch tasks** rather than compromising quality.

---

## How the Three Components Work Together

**Scenario (Authentic Context) → Problem (Parallelizable) → Solution (Multi-Threaded)**

The scenario must be large and complex enough that a single agent cannot hold it all in mind.
- Small, artificial scenarios will never produce a 23-point gap
- Real 200K-line codebases with 40 files to patch across 4 services will

The problem statement must describe work that naturally decomposes.
- If the task reads as "do X in file A, then do Y in file B, then merge" — that's sequential, not parallelizable
- If it reads as "fix query compilation, fix backend adapters, fix migrations, then synthesize" — that's parallel

The golden solution must demonstrate how decomposition succeeds.
- Single agent: tackles the full codebase, context fills by module 3, misses cross-module consistency, introduces regressions
- Multi-agent: each agent owns one thread with full context, all threads proceed in parallel, orchestrator integrates and validates
- The gap emerges from this structural difference — it is not about speed, it is about capability under constraint

**Example correlation:**
- Scenario: "Real Express.js 200 KB codebase with async/security/compatibility bugs across 8 files"
- Problem: "Three independent technical threads (async correctness, CRLF hardening, Node 22 compat) must all be fixed"
- Solution: Orchestrator coordinates 4 specialized agents, each owns one thread, final integration passes all tests
- Result: Single agent patches async but misses CRLF or compat → 0.60. Multi agent completes all three → 0.90. Gap = 0.30 ✓

---

## Common Mistakes and How to Avoid Them

| Mistake | Fix |
|---------|-----|
| Installing `kimi-cli` in Dockerfile | Never install it — Harbor handles it |
| Using LLM to generate Dockerfile | Start from official template, add only task-specific deps |
| Synthetic task / invented scenario | Use real GitHub PRs, real repos, real CVEs only |
| Optimizing for single < 0.3 and multi > 0.7 | Focus on gap ≥ 0.23, not specific absolute scores |
| Verifier checks things instruction never mentioned | Align prompt and verifier; if verifier checks it, instruction must state it |
| Decomposition includes exact code strings | Keep descriptions outcome-oriented, not implementation-level |
| Git history left in repo | `rm -rf .git` after checkout; use `--depth 1` when cloning |
| Verifier mostly substring matching | ≥50% weight must be behavioral execution tests |
| Unpinned base image or dependencies | Pin exact versions in Dockerfile and pip requirements |
| `curl` in solve.sh | Embed all patches as inline heredocs; no network calls at oracle time |
| Missing oracle execution logs | Run oracle through Harbor; include `execution_logs/oracle/result.json` |
| Large PR but shallow coordination | Reject early; file count alone is not sufficient |

---

## Quick Reference Checklist Before Submitting

- [ ] PR is real, merged/closed, 20+ real code files changed, multiple interacting subsystems
- [ ] `instruction.md` is human-authored, states all verifier-enforced requirements
- [ ] Dockerfile uses pinned versions, no `kimi-cli`, removes `.git`
- [ ] `solve.sh` is self-contained (no curl/wget), scores 1.0 through Harbor oracle run
- [ ] Verifier: ≥50% behavioral tests, ≤50% static checks
- [ ] Decomposition describes outcomes/deliverables, not code-level steps
- [ ] `task.toml` has correct `timeout_sec` matching multi-agent run time
- [ ] All 3 execution logs present: oracle (1.0), single-agent, multi-agent
- [ ] `multi - single ≥ 0.23`
- [ ] ZIP follows exact naming convention: `<uuid>-SWARMBENCH-<PATTERN>-<DOMAIN>-<TASK-NAME>`
- [ ] Draft review passed at LLM reviewer tool before final submission
