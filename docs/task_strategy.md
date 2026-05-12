After reviewing the additional benchmark design guidance, here is a consolidated **generic summary of the core principles for designing strong multi-agent LLM evaluation tasks**. These principles complement and reinforce the earlier SwarmBench guidance.  

# Generic Summary — Designing Strong Multi-Agent Evaluation Tasks

---

# Core Principle

The goal is NOT to create tasks that are merely difficult.

The goal is to create tasks where:

```text id="m3w7gx"
single agents fail structurally,
while multi-agent systems succeed structurally.
```

The benchmark must reward:

* decomposition
* parallel ownership
* reconciliation
* coverage
* synthesis
* consistency verification

NOT:

* brute-force reasoning
* prompt tricks
* hidden verifier rules
* arbitrary complexity

---

# 1. Breadth Under Budget Is The Most Important Design Principle

The strongest tasks are not defined by:

* one hard insight
* one deep algorithm
* one difficult file

They are defined by:

* many artifacts
* many constraints
* many outputs
* limited time budget

This creates natural pressure on single agents:

| Single-Agent Failure Modes |
| -------------------------- |
| loses coverage             |
| forgets constraints        |
| misses edge cases          |
| fails reconciliation       |
| exceeds timeout            |
| loses consistency          |

Multi-agent systems succeed because they:

* divide ownership
* parallelize work
* isolate context
* use reducers/orchestrators
* reconcile outputs systematically

---

# 2. Tasks Must Have Natural Parallelism

Before building a benchmark, ask:

```text id="8f4vzp"
Can this task be split into 4–10 meaningful independent workstreams?
```

If NO:

* discard the task

Good task shapes:

* many files
* many datasets
* many reports
* many modules
* many workflows

Bad task shapes:

* one sequential dependency chain
* one core insight
* one isolated algorithm
* one-file debugging

---

# 3. Coverage Failure Is More Valuable Than Pure Difficulty

Single agents are already very good at:

* solving one hard thing

They are weak at:

* exhaustive coverage
* consistency across many units
* parallel reconciliation

Strong task examples:

* patch 30+ deprecated usages consistently
* reconcile multiple reports/contracts
* update tests/docs/manifests together
* process many datasets correctly

The benchmark should reward:

```text id="u7g1ns"
coverage completeness
```

NOT just:

```text id="d9q6kt"
local correctness
```

---

# 4. Context Overload Should Come From The Environment

Do NOT overload prompts artificially.

Instead:

* distribute information across files/repos/artifacts

Good:

```text id="p3m6vk"
/src/module_a
/src/module_b
/docs/
contracts/
datasets/
reports/
```

Bad:

```text id="w6t9yr"
huge monolithic prompt
```

Why this works:

* single agents degrade during traversal
* multi-agents preserve local focused contexts

---

# 5. Multiple Outputs That Must Agree Create Strong Benchmarks

One of the best benchmark strategies:

Require:

* several outputs
* all internally consistent

Example:

```text id="a1j4fd"
update code
+
update tests
+
update docs
+
generate migration notes
+
generate manifests
+
ensure all agree
```

Why this is powerful:

Single agents:

* fix primary task
* forget secondary artifacts
* produce inconsistencies

Multi-agent systems:

* assign ownership
* reconcile outputs centrally

This creates strong structural advantage.

---

# 6. Timeout Is A Legitimate Structural Failure Mode

Single-agent failure does NOT need to mean:

```text id="z7n5cq"
wrong answer
```

Valid failure:

```text id="x2r8jd"
incomplete work under same time budget
```

Correct workflow:

1. oracle → 1.0
2. multi-agent runtime measured
3. timeout set near multi-agent runtime
4. single-agent evaluated under same budget

If:

* multi-agent completes
* single-agent still exploring

that is a VALID benchmark gap.

---

# 7. Prefer Read-Heavy Parallelism

Multi-agent systems parallelize BEST when:

* reading
* analyzing
* extracting
* validating
* classifying

They parallelize poorly when:

* many agents edit same output

Best architecture:

```text id="f5v2oy"
parallel reading + planning
centralized synthesis/writing
```

This minimizes:

* merge conflicts
* coordination noise

and maximizes:

* coverage
* specialization

---

# 8. Strong Tasks Require Reconciliation

The best benchmarks require:

```text id="r3k8pj"
independent outputs
+
final consistency verification
```

This creates:

* synthesis pressure
* orchestration necessity
* reducer importance

Without reconciliation:

* multi-agent advantage collapses

---

# 9. Decomposition Quality Matters More Than Raw Difficulty

Most failed benchmarks fail because:

```text id="h1n7sz"
bad decomposition
```

NOT because:

```text id="t9y5wc"
task too easy
```

Bad decomposition:

```text id="g6x2am"
Agent A edits file1
Agent B edits file2
```

Good decomposition:

```text id="m2k4qt"
Agent A audits auth/session semantics
Agent B validates realtime consistency
Agent C updates integration tests
Reducer verifies synthesis
```

Key rule:

```text id="d7r3fl"
assign ownership of technical workstreams,
not ownership of files.
```

---

# 10. Real Artifacts Are Essential

Good sources:

* real repositories
* real contracts
* real reports
* real datasets
* real papers

Avoid:

* toy problems
* synthetic puzzles
* artificial prompts

Real systems naturally create:

* hidden dependencies
* noisy environments
* integration complexity
* coverage pressure

which is exactly what multi-agent systems handle better.

---

# 11. Partial Scoring Is Critical

The verifier should support:

```text id="s6c8nf"
partial completion
```

Example:

* 60% coverage → 0.60 score
* 100% coverage → 1.0 score

This is important because:

* single agents often complete partial scope
* multi-agent systems complete full scope

Without partial scoring:

* gap signal becomes noisy

---

# 12. The Gap Must Be Structural

A good benchmark creates:

```text id="y2p9lx"
>=23% score gap
```

because:

* decomposition matters
* coordination matters
* synthesis matters
* coverage matters

NOT because:

* verifier unfairness
* hidden requirements
* brittle regexes
* arbitrary scoring tricks

---

# 13. Strong Benchmarks Usually Follow This Pattern

```text id="q4v1zb"
Many artifacts
+
Independent workstreams
+
Coverage pressure
+
Time pressure
+
Consistency requirements
+
Reducer/orchestrator synthesis
```

This combination reliably produces:

* single-agent degradation
* multi-agent structural advantage

---

# 14. Acceptance Criteria For Good Tasks

Keep tasks ONLY if:

| Requirement   | Target                |
| ------------- | --------------------- |
| oracle        | 1.0                   |
| multi-agent   | 0.95–1.0              |
| single-agent  | ≤0.72 or timeout      |
| gap           | ≥23%                  |
| decomposition | meaningful            |
| verification  | behavioral/structured |
| artifacts     | real-world            |

Otherwise:

* improve decomposition
* increase breadth
* add reconciliation
* tighten timeout
* or discard the task

---

# Final Design Principle

The entire benchmark strategy can be summarized as:

```text id="p9f7rw"
Break single agents with:
- breadth
- coverage requirements
- reconciliation pressure
- context overload
- time constraints

Then let multi-agent systems succeed through:
- structured decomposition
- isolated ownership
- parallel execution
- reducer-based synthesis
- integration verification
```

That is the most reliable way to create benchmarks that remain meaningful even as single-agent LLMs continue improving. 
