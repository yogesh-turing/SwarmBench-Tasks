# SwarmBench Guidelines

## Section A — Project Overview

### A.1 — What Is SwarmBench
SwarmBench is a benchmark for evaluating multi-agent AI systems on tasks that are structurally too large or too complex for a single AI agent to solve reliably. It is built on the Harbor evaluation harness, uses Docker for isolated execution, and measures the gap between single-agent and multi-agent performance on real-world tasks.

As a trainer, your job is to create tasks. Each task you produce is a self-contained evaluation unit — a real-world problem, an execution environment, a gold-standard oracle, and a verifier that scores the agent's work. You are not writing prompts. You are building evaluation environments.

What you will create for each task:
* A human-authored task prompt (instruction.md) — a real problem a professional would face
* A Docker environment (environment/Dockerfile) — the container the agent works inside
* Input data (input_artifacts/) — the files, databases, or codebase the agent must process
* A gold oracle (oracle.json or test suite) — the correct answer or test harness
* A verifier (test.sh + judge.py or verify.py) — the script that scores the agent
* A decomposition guide (decomposition.yaml) — how a multi-agent system should split the work

What Harbor does automatically: builds the container, runs the agent, runs your verifier, collects the score, saves the trajectory. You do not manage containers or infrastructure.

Two agent modes run on every task:
* swarm-kimi-single — Kimi K2.5 running alone, with sub-agent spawning disabled
* swarm-kimi-multi — Kimi K2.5 as an orchestrator, reading your decomposition guide and spawning sub-agents

Both run just 1 time each. You compare the scores.

### A.2 — The Problem We Are Solving
Every day, professionals across medicine, research, engineering, and finance face tasks that are structurally too large for one person — or one AI — to handle alone.

A clinical fellow reviewing 1,500 case reports to identify a pattern in a rare post-procedural complication cannot hold all 1,500 cases in their head simultaneously. They divide the work: one resident reads cardiology cases, another reads vascular, a third reads systemic presentations. They meet, compare notes, synthesize. That coordination — divide, process in parallel, aggregate — is not a workaround. It is the only way the work gets done correctly.

A research team producing a systematic survey of 50 AI benchmark papers cannot assign all 50 to one person without losing rigor. Paper 47 gets a cursory skim. Subtle distinctions between benchmarks get conflated. Quotes get misattributed. The paper suffers.

A DevOps team responding to a critical CVE in a 200,000-line codebase cannot have one engineer read every module, identify every vulnerable call site, and patch them all before the disclosure deadline. They split by service, work in parallel, have a lead integrate.

This is what we are building the training data for: AI systems that coordinate the way expert human teams coordinate.

### A.3 — Why Single Agents Fail at Scale
Large language models are extremely capable within a context window. The problem is structural, not one of intelligence.

For knowledge and research tasks (llm-judge):
Consider our medical research task — a clinician must read and clinically assess 1,500 case reports across three specialty databases (~500,000 tokens). A single agent attempting this faces:
* Context overflow: By case 300, early cases are pushed out of the effective attention window. The agent forgets what it read in the first cardiac batch when synthesizing the vascular findings.
* Attention degradation: With 500K tokens in context, the signal-to-noise ratio collapses. The agent begins hallucinating PMCIDs — citing cases that do not exist or mixing up details between cases.
* Loss of diagnostic thread: The final synthesis requires holding three domains simultaneously. A single agent that has been reading for hours of context has no reliable working memory left for cross-domain reasoning.

A single expert clinician reviewing 1,500 case files would take weeks. The AI equivalent fails in a different way — it reads fast but loses precision the deeper it goes. This is the failure mode we are benchmarking.

For our agent benchmark landscape task — 11 research papers, each requiring careful extraction of 6 structured fields with verbatim quote evidence — a single agent begins confusing papers by paper 7. It attributes quotes from CRMArena to WorkArena. It hallucinates that a benchmark has 15 domains when the paper says 4. The errors compound. By paper 11, the extraction is unreliable.

For code and SWE tasks (executable):
Consider a team that has discovered CVE-2024-XXXXX in their authentication service — a token validation bug that exists in three microservices and 47 different call sites across 180,000 lines of Python. The remediation requires:
1. Finding every vulnerable call site across three services
2. Patching each one correctly without breaking adjacent logic
3. Running 340 integration tests across all three services to verify

A single agent exploring this codebase will run out of context budget before it finishes service one. It will patch 12 call sites, miss 35, and produce a codebase that still fails security tests — but now also has regression bugs.

Or consider a company migrating a monolithic Java 8 application to Java 17 — 80 modules, dozens of deprecated API calls, type casting changes, and library version conflicts. A single agent can handle perhaps 5–8 modules before its context fills and it starts introducing errors in module 9 that conflict with changes it made in module 2.

These are not toy scenarios. They are the exact situations where real engineering teams coordinate — and where AI needs to learn to do the same.

### A.4 — What You Are Building
As a trainer, you are not writing test cases. You are building the training signal that teaches AI systems when and how to decompose, delegate, and synthesize — the cognitive architecture of a coordinated team.

Every task you create is a proof that:
1. This problem is real — a professional would spend 10–100+ hours solving it
2. A single agent structurally cannot solve it (not just slowly — structurally, due to context limits or attention degradation)
3. A coordinated multi-agent system can solve it by dividing context, working in parallel, and synthesizing results

The benchmark is rigorous by design. A task only counts if:
* Single-agent -> it genuinely fails, not just struggles
* Multi-agent -> the coordination strategy actually works
* At least a 23-point gap between the two
* Single agent times out or fails on a single trial
* Multi-agent succeeds on a single trial

A task where both approaches score 60% is not useful. A task where both score 0% is broken. What you are looking for is a task with a structural wedge — one approach fails by design, the other succeeds by design.

### A.5 — What Makes a Good Task
The task prompt must be human-authored. It should read like a real professional request — specific, grounded, with realistic constraints. We are looking for real-world problem statements, not synthetic data.

The prompt should be neither underspecified ("analyze these files") nor overspecified ("on line 342 of server-01.log, find the…"). It should give the agent the same level of briefing a human expert would receive before starting the work.

Good task sources:
* Real clinical cases, research synthesis tasks, or data audits you have encountered professionally
* Open-source repos with real bugs, real PRs, real CVEs
* Public datasets that require multi-source cross-referencing
* Literature review tasks drawn from real research questions

Two real examples from our benchmark:
Task: Diagnose a rare cardiac complication from 1,500 medical case files across 3 specialty databases
Pattern: fan-out/synthesize
Why it works: 500K tokens; single agent hallucinates PMCIDs by case 300; 15 sub-agents each handle 100 cases within attention range

Task: Survey 11 agent benchmark papers and extract 6 structured fields with verbatim quote evidence
Pattern: fan-out/synthesize
Why it works: Context fills by paper 7; sub-agents each own one paper with clean isolated context; evaluator sub-agents cross-check claims