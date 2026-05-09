Please go through the Project Overview to avoid alot of errors.
Section 11 — Quick Start Checklist
One-page walkthrough from idea to submission. Follow these steps in order for your first task.
1. Choose your verifier type (Section 1)
Knowledge, research, or data analysis → llm-judge
Code or SWE with test suite → executable
2. Choose your coordination pattern (Section 2)
Data splits into independent similar chunks → map-reduce
Multiple independent analytical threads → fan-out-synthesize
3. Choose your domain (Section 3)
code-swe
knowledge-research
data-analysis
planning-operations
reasoning-math
4. Estimate difficulty (Section 4)
How many hours would a human expert need? 10–50h = Easy, 50–100h = Medium, 100+ = Hard
Write the justification with numbers, not prose
5. Write instruction.md (Section 5)
Human-authored only
End with output format block for llm-judge tasks (keys must match oracle.json)
State every constraint your verifier checks
State file paths, working directory, and what not to modify
6. Build environment/Dockerfile (Section 6)
LLM-judge: FROM python:3.12-slim + pip install openai + COPY input_artifacts/
Executable: clone repo at pinned base commit + install dependencies
Build and test it locally:
docker build -t test .
7. Write your verifier (Section 7)
LLM-judge: copy judge.py and test.sh templates — no changes needed for most tasks
Executable: write verify.py that checks exactly what the prompt specified
8. Write oracle.json or gold patch (Section 8)
LLM-judge: create tests/oracle.json + solution/oracle.json (identical copies)
Executable: write solution/solve.sh with the gold diff
9. Write decomposition.yaml (Section 9)
Minimal agents, clear responsibilities, self-contained descriptions
Every sub-agent gets complete context — they cannot see instruction.md
10. Fill in task.toml (Section 10)
All metadata fields required
IMPORTANT
If your multi-agent run solves the task in X minutes, set the agent timeout to that same value for both runs:

[agent]
timeout_sec = 1800   # e.g. 30 min if multi-agent solved in ~30 min

Then run the single-agent with the same timeout. If single-agent fails within that window where multi-agent passes — that's a valid, time-constrained failure and counts as strong evidence of multi-agent necessity.
IMPORTANT (BEFORE RUNNING THE EXECUTION LOGS)
Make sure to utilize the LLM reviewer at the following link:
https://script.google.com/a/macros/turing.com/s/AKfycbzol5MwCe_bPpfkIy6su6jUxr0lyHq9wYmq0_FvIF4Kgmd1Bzh6zmKJ7i9nonCh1tWy/exec
This will do both static (structural) checks and dynamic (semantic) checks as well
Login with your Turing email
Click on Draft Review
Upload the the mandatory files as a .zip as shown in the picture below

Click the Run Draft Review button
It will produce a quality report like the example below
QG Report — 7c591699acf1415aafb2903a025c207a-SWARMBENCH-MAPREDUCE-CODE-SWE-DJANGO-ADMIN-FILTER-HORIZONTAL-BUGFIX — REJECT
After addressing issues (that actually exist), 
submit the latest .zip file into the draft review again
Run report again and repeat until all actual issues are resolved
This means the AI can hallucinate and if you see some hallucinations happening, please escalate to Edgar Kibet or Muhammad Sulaiman Nadeem
Then continue with the steps below as usual if everything looks fine

Important:
This is a draft review tool only — it is not a substitute for the final quality gate. Before submitting, you must still run the full review, pass it, and attach that final report to the LT form. Do not submit the draft review output.
Use this to iterate faster and catch issues early. Final submissions still require the full pipeline.





11. Run oracle validation
cd harbor
uv run harbor run -p /path/to/your-task -a oracle \
  --ve FIREWORKS_API_KEY=$FIREWORKS_API_KEY
Must score 1.0. If not, fix your verifier.
12. Run single agent 1 time
uv run harbor run -p /path/to/your-task -a swarm-kimi-single \
  -m fireworks_ai/accounts/fireworks/models/kimi-k2p5 \
  -k 1 -n 1 \
  --job-name "single-kimi-agent" \
  --jobs-dir /path/to/your-task/execution_logs \
  --ve FIREWORKS_API_KEY=$FIREWORKS_API_KEY \
  --ae FIREWORKS_API_KEY=$FIREWORKS_API_KEY \
  --quiet

13. Run multi agent 1 time
uv run harbor run -p /path/to/your-task -a swarm-kimi-multi \
  -m fireworks_ai/accounts/fireworks/models/kimi-k2p5 \
  -k 1 -n 1 \
  --job-name "multi-kimi-agent" \
  --jobs-dir /path/to/your-task/execution_logs \
  --ve FIREWORKS_API_KEY=$FIREWORKS_API_KEY \
  --ae FIREWORKS_API_KEY=$FIREWORKS_API_KEY \
  --quiet
Gap between single and multi agent ≥ 23 points. The least allowed is 23 points.
14. Debug if needed (Section 9.5)
Read execution_logs/*/agent/judge_justification.txt for scoring details
Read execution_logs/*/agent/trajectory.json for agent behavior
Fix false failures in prompt or oracle, improve decomposition, and re-run
15. Submit (Section 12)

Section 12 — Task Submission Process
IMPORTANT (BEFORE SUBMITTING TO THE LABELING TOOL)
Make sure to utilize the LLM reviewer at the following link:
https://script.google.com/a/macros/turing.com/s/AKfycbzol5MwCe_bPpfkIy6su6jUxr0lyHq9wYmq0_FvIF4Kgmd1Bzh6zmKJ7i9nonCh1tWy/exec
This will do both static (structural) checks and dynamic (semantic) checks as well
Login with your Turing email
Provide your drive link and paste it in the field
Click the Submit for Review button
It will produce a quality report like the example below
QG Report — 7c591699acf1415aafb2903a025c207a-SWARMBENCH-MAPREDUCE-CODE-SWE-DJANGO-ADMIN-FILTER-HORIZONTAL-BUGFIX — REJECT

      6. After addressing issues (that actually exist), 
submit the latest task into the drive again
Run report again and repeat until all actual issues are resolved
This means the AI can hallucinate and if you see some hallucinations happening, please escalate to Edgar Kibet or Muhammad Sulaiman Nadeem
      7. Then continue with the steps below as usual if everything looks fine
This section will be finalized once the submission pipeline is confirmed. Placeholder below.
After your task passes validation (oracle = 1.0, multi - single >= 0.4):
Ensure your task directory contains all required files (instruction.md, task.toml, decomposition.yaml, environment/, tests/, solution/)
Ensure execution_logs/ contains results from 1 single-agent and 1 multi-agent runs
Submit via the process defined by your pod lead
QA reviewers will check: oracle validity, AHT justification, decomposition quality, and pass-rate gap

Glossary
Agent — An AI model (Kimi K2.5) running inside a Docker container, executing a task. In our benchmark, agents are either single (one instance, tool-restricted) or multi (orchestrator + sub-agents).
Decomposition — The strategy for splitting a task into sub-tasks that multiple agents work on in parallel. Defined in decomposition.yaml.
Harbor — The evaluation harness framework. Handles Docker container lifecycle, agent execution, verification, and result collection. We use a patched version with custom SwarmBench agents.
LLM Judge — A separate LLM call (Kimi K2.5 via Fireworks) that grades the agent’s output against the oracle. Returns a score between 0.0 and 1.0 with field-by-field justification.
Oracle — The gold-standard correct answer (oracle.json) or gold fix (solve.sh). Used by the verifier to score the agent’s work. Also refers to the oracle agent (-a oracle) which applies the gold solution to validate the pipeline.
Reward — The score produced by the verifier. For llm-judge tasks: float 0.0–1.0 in reward.json. For executable tasks: binary 1 or 0 in reward.txt.
Sub-agent — An agent spawned by the orchestrator during multi-agent runs. Sub-agents run in isolated context — they cannot see the main instruction or other sub-agents’ output. Only available to swarm-kimi-multi.
Trajectory — A structured log of every step the agent took: tool calls, reasoning, observations, token counts. Saved as trajectory.json in the agent logs.
Trial — One execution of one agent on one task. A job with -k 1 produces 1 trials.
Verifier — The script (test.sh) that scores the agent’s output. For llm-judge: calls judge.py. For executable: calls verify.py. Must write a reward file to /logs/verifier/.
Volume mount — A Docker feature where a directory on your laptop is shared with the container. /logs/agent/ inside the container is the same as trial_dir/agent/ on your laptop. Files written inside appear outside instantly.


Task Submission Rules
1. Claim a Task
Go to the labeling tool project:
https://labeling-m.turing.com/projects/258/view
Claim an available task
Fill all required fields in the form
Ensure metadata is correct before starting work

2. Build the Task
Each task must be created in full Harbor format with all required components.
Required Task Structure
<task_root>/
├── instruction.md
├── task.toml
├── decomposition.yaml
├── environment/
│   ├── Dockerfile
│   └── input_artifacts/   (if applicable)
├── tests/
│   ├── test.sh
│   ├── judge.py OR verify.py
│   └── oracle.json        (for llm-judge)
├── solution/
│   ├── solve.sh
│   └── oracle.json        (for llm-judge)
└── execution_logs/
    ├── oracle/
    ├── single-kimi-agent/
    └── multi-kimi-agent/
IMPORTANT (BEFORE RUNNING THE EXECUTION LOGS)
Make sure to utilize the LLM reviewer at the following link:
https://script.google.com/a/macros/turing.com/s/AKfycbzol5MwCe_bPpfkIy6su6jUxr0lyHq9wYmq0_FvIF4Kgmd1Bzh6zmKJ7i9nonCh1tWy/exec
This will do both static (structural) checks and dynamic (semantic) checks as well
Login with your Turing email
Click on Draft Review
Upload the the mandatory files as a .zip as shown in the picture below

Click the Run Draft Review button
It will produce a quality report like the example below
QG Report — 7c591699acf1415aafb2903a025c207a-SWARMBENCH-MAPREDUCE-CODE-SWE-DJANGO-ADMIN-FILTER-HORIZONTAL-BUGFIX — REJECT
After addressing issues (that actually exist), 
submit the latest .zip file into the draft review again
Run report again and repeat until all actual issues are resolved
This means the AI can hallucinate and if you see some hallucinations happening, please escalate to Edgar Kibet or Muhammad Sulaiman Nadeem
Then continue with the steps below as usual if everything looks fine

Important:
This is a draft review tool only — it is not a substitute for the final quality gate. Before submitting, you must still run the full review, pass it, and attach that final report to the LT form. Do not submit the draft review output.
Use this to iterate faster and catch issues early. Final submissions still require the full pipeline.



3. Delivery Format (MANDATORY)
You must submit a ZIP file
The final submission must be a ZIP file
ZIP must contain exactly one root folder

Root Folder Naming (STRICT)
Format:
<uuid>-SWARMBENCH-<PATTERN>-<DOMAIN>-<TASK_NAME>
Examples:
4c3c848bb2f9459cb908d78f02897c6f-SWARMBENCH-FANOUT-CODESWE-DJANGO-AUTH-BUGFIX
Rules
<uuid> must match Task UUID in labeling tool
Must contain SWARMBENCH
<PATTERN> must match:
fan-out-synthesize → FANOUT
map-reduce → MAPREDUCE
"specialist-routing": "SPECIALIST",
"pipeline": "PIPELINE",
"hierarchical": "HIERARCHICAL",
"debate": "DEBATE"
<DOMAIN> must match:
code-swe → CODESWE
<TASK_NAME> must match Task Name (slug)
The regex in LLM Reviewer only accepts uppercase letters, digits, and hyphens in the final segment. The tail comparative-knowledge-system-assessment has lowercase letters, so it fails [A-Z0-9-]+.
What the regex accepts:
<32-hex>-SWARMBENCH-<SLUG>-<ALL-CAPS-WORD>-<ALL-CAPS-WITH-DIGITS-AND-HYPHENS>
Valid example:
6ece0e239c60442c952b334a10815e3c-SWARMBENCH-FANOUT-KNOWLEDGE-RESEARCH-COMPARATIVE-KNOWLEDGE-SYSTEM-ASSESSMENT
No spaces
Must exactly match [task].name in task.toml


4. Execution Logs (MANDATORY)
Your ZIP must include:
execution_logs/
├── oracle/
├── single-kimi-agent/
└── multi-kimi-agent/
Required Conditions
Oracle
1 run
mean reward = 1.0
Single-agent
1 run
Multi-agent
1 run
Gap
multi - single ≥ 0.23

5. Upload Submission
After completing the task:
Zip the task folder
Upload the ZIP to:
https://drive.google.com/drive/folders/1mcMPW-V0Hqm3xZCNQd0UmwcEsVTlu8ip
IMPORTANT (BEFORE SUBMITTING TO THE LABELING TOOL)
Make sure to utilize the LLM reviewer at the following link:
https://script.google.com/a/macros/turing.com/s/AKfycbzol5MwCe_bPpfkIy6su6jUxr0lyHq9wYmq0_FvIF4Kgmd1Bzh6zmKJ7i9nonCh1tWy/exec
This will do both static (structural) checks and dynamic (semantic) checks as well
Login with your Turing email
Provide your drive link and paste it in the field
Click the Submit for Review button
It will produce a quality report like the example below
QG Report — 7c591699acf1415aafb2903a025c207a-SWARMBENCH-MAPREDUCE-CODE-SWE-DJANGO-ADMIN-FILTER-HORIZONTAL-BUGFIX — REJECT
      6. After addressing issues (that actually exist), 
submit the latest task into the drive again
Run report again and repeat until all actual issues are resolved
This means the AI can hallucinate and if you see some hallucinations happening, please escalate to Edgar Kibet or Muhammad Sulaiman Nadeem
     7.Then continue with the steps below as usual if everything looks fine
     8. Copy the Drive link
Paste the link in the labeling tool form
Fill your attendance form for the day:
https://docs.google.com/forms/d/e/1FAIpQLSfInJrDV3s0ITpHehRdLsnXMIROKVJt7lUlMtBFsOUszgG_3A/viewform?usp=dialog


6. Final Checklist Before Submission
Ensure all of the following:
Task claimed in labeling tool
All metadata fields filled correctly
ZIP contains exactly one root folder
Root folder name follows required format
task.toml name matches folder name exactly
All required files exist
Oracle run = 1.0
Gap ≥ 0.23
No missing execution logs

7. Rejection Conditions
Your task will be rejected immediately if:
ZIP format is incorrect
Folder naming is incorrect
UUID mismatch
Missing files or folders
Oracle ≠ 1.0
Gap < 0.23
Execution logs missing
Task not reproducible


Packaging & ZIP Issues
macOS GUI zip adds __MACOSX/ folder — always zip from terminal using zip -r task.zip folder/ instead of right-click compress
CRLF line endings — files created on Windows/macOS may have \r\n shebangs that break Linux execution; run dos2unix on all shell scripts before zipping



Mistake 1: Addressing Agent Setup Timeouts
We have identified that certain Dockerfile configurations are triggering the "Agent setup timed out after 360.0 seconds" error. Please review the following to prevent this in your tasks.

Root Cause
Timeouts often occur when a Dockerfile includes: 

RUN pip install kimi-cli kimi-agent-sdk ...

Because Harbor automatically handles the installation of kimi-cli during Phase 3 of agent setup, pre-installing it in the Dockerfile forces a redundant runtime installation via UV. This process downloads Python 3.13 and all dependencies from scratch, consistently exceeding the 360-second limit and causing trial failure.

Required Fix
Never manually install kimi-cli or kimi-agent-sdk. Instead, use the following standardized template from our Trainer Guidelines:

FROM python:3.12-slim
RUN apt-get update && apt-get install -y curl git
RUN pip install openai    # only needed for llm-judge tasks
COPY input_artifacts/ /input_artifacts/
WORKDIR /workspace

🚨 The Core Issue: Avoid LLM-Generated Dockerfiles
These errors frequently stem from using Cursor or other LLMs to draft Dockerfiles. These models are unaware of Harbor's internal mechanics, automated installation phases, or specific folder conventions.

Action Items for All Trainers:
Prioritize the Guidelines: Reference Section 6 of the Trainer Guidelines for detailed Dockerfile setups, templates, and troubleshooting.
Template-First Approach: Do not build from scratch using an LLM. Start with the official template and only add necessary, task-specific dependencies.
Consult the Team: If the guidelines do not address your specific technical hurdle, contact the team directly rather than relying on an LLM.

Please ensure you have read the guidelines thoroughly before proceeding with your task builds.

Mistake 2: Choosing Synthetic or Out-of-Scope Tasks (mostly for code-swe tasks)

We have identified that some code/swe submitted tasks are being built from synthetic prompts, custom-created scenarios, or repos/problems that do not fall under the code-swe domain. Please review the following to avoid rejection.
Root Cause
Rejections happen when a trainer creates a task from scratch instead of grounding it in a real software engineering problem, or when the selected work is outside the code-swe scope. For example, a data analysis task built around a Kaggle dataset does not qualify as a code-swe task. There is also no current client requirement that the PR you select must already be closed.
Required Fix
Only use real software engineering tasks grounded in actual repositories, PRs, or issues that clearly align with the code-swe domain. Do not create synthetic tasks from scratch. Before starting, verify that the task involves genuine code changes in a software project. You do not need to limit yourself to already-closed PRs unless future guidance explicitly changes.
Action Items for All Trainers:
Stay in Domain: Confirm that the repo and task are clearly software-engineering focused before building.
Avoid Synthetic Setups: Do not invent your own problem statement or task scenario.
Do Not Over-Restrict PR Selection: A PR does not need to be closed unless that becomes an explicit requirement later.

Mistake 3: Using the Wrong Trial and Gap Criteria

We have identified that some tasks are being judged against the wrong scoring targets, which leads to unnecessary rework and weak task design decisions. Please review the following to avoid invalid evaluations.
Root Cause
A common mistake is optimizing around arbitrary thresholds such as “single-agent must be below 0.3” and “multi-agent must be above 0.7.” That is not the key requirement. The more important standard is an absolute gap of at least 0.40 between single-agent and multi-agent performance. Another issue is failing to run the required trajectories consistently. In addition, when a task requires changes across 30+ files but only produces a 0.2 gap, that usually indicates the task framing or subagent setup needs improvement.
Required Fix
Run one single-agent trial and one multi-agent trial for every task. Evaluate the task based on whether it achieves a gap of >= 0.40, not whether it hits a specific low/high score pair. For example, 0.5 single-agent vs 0.9 multi-agent is still acceptable because the 0.40 gap is present. If the gap is too small, revise the task framing, instruction clarity, or decomposition structure.
Action Items for All Trainers:
Run Both Required Trajectories: One single-agent trial and one multi-agent trial for each task.
Focus on the Gap: Prioritize a 0.23+ gap over arbitrary target scores.
Revisit Weak Gaps: If a large task produces only a small separation, improve the task structure rather than forcing the numbers.

Mistake 4: Instruction.md and Verifier Requirements Do Not Match (foir executable tasks)
We have identified that some otherwise valid solutions are being rejected because the verifier is enforcing requirements that are not clearly surfaced in instruction.md. Please review the following to prevent false negatives.
Root Cause
This happens when the verifier expects a specific identifier, path, function name, file, or configuration choice that the instruction does not clearly communicate. For example, if the verifier checks for a particular setting or file path but the prompt only gives a vague description, a correct implementation can still score zero simply because it used a different name or location.
Required Fix
Phrase the problem clearly in instruction.md and make sure any verifier-critical names, files, or paths are discoverable from the task instructions. This does not mean every implementation detail must be spelled out verbatim, but any requirement the verifier strictly enforces must be communicated clearly enough that a correct agent can satisfy it.
🚨 The Core Issue: Hidden Requirements Create False Failures
If the verifier is stricter than the instruction, then the task is not measuring problem solving fairly. The agent should not have to guess hidden naming conventions or invisible file expectations.
Action Items for All Trainers:
Align Prompt and Verifier: Make sure the instruction and verifier are testing the same outcome.
Name Critical Files Clearly: If a specific file or path matters, surface it in the task.
Remove Hidden Constraints: Do not enforce requirements the prompt never made visible.

Mistake 5: Decomposition Describes HOW Instead of WHAT

We have identified that some decomposition.yaml files are written like implementation scripts instead of work-division plans. Please review the following to avoid unfair task setups and poor multi-agent behavior.
Root Cause
This issue occurs when decomposition descriptions include exact code strings, precise attribute names, function signatures, or line-by-line implementation steps. That turns the decomposition into a coded answer key instead of a high-level division of work. It also gives multi-agent runs an artificial advantage and weakens the quality of the task. In many cases, poor subagent design is also the reason a large task still shows only a small score gap.
Required Fix
Your decomposition should describe what each subagent must accomplish, not how to implement it. Keep the descriptions outcome-oriented and scoped around meaningful workstreams. Avoid exact code snippets, exact attribute names, and implementation-level instructions. When possible, prefer the map-reduce and fan-out-synthesize coordination patterns rather than weaker alternatives.
🚨 The Core Issue: Decomposition Is for Work Division, Not Code Authoring
A good decomposition tells each subagent which part of the problem space it owns. It should not hand out the exact implementation recipe.
Action Items for All Trainers:
Describe Deliverables, Not Code: Focus on goals and ownership boundaries.
Avoid Exact Implementation Cues: Do not include exact strings, exact names, or line-by-line edits.
Use Strong Coordination Patterns: Stick to map-reduce and fan-out-synthesize unless there is a compelling reason not to.
Re-scope Weak Tasks: If a 30+ file task only produces a small gap, redesign the subagent breakdown.

Mistake6: Missing Oracle Logs (executable explanation below)

We have identified that some tasks are being rejected immediately because the required oracle execution logs are not included. Please review the following before submission.
Root Cause
If solve.sh is not run through Harbor, or if the resulting oracle artifacts are not preserved, the task cannot be validated properly. Missing oracle logs are treated as a hard failure during review.
Required Fix
Run solve.sh through Harbor and include:
execution_logs/oracle/result.json
No oracle logs means the task is incomplete and subject to automatic rejection.
Action Items for All Trainers:
Run the Oracle Path: Always execute solve.sh through Harbor before submission.
Check the Output Artifacts: Confirm that execution_logs/oracle/result.json exists and is included.
Treat This as Mandatory: Do not submit a task without oracle logs.

Mistake7: Git History Leaks the Answer (executable and code-swe only tasks)
We have identified that some tasks unintentionally expose the solution because the repository history is left intact. Please review the following to prevent answer leakage.
Root Cause
If you clone a repository with full git history, the agent can inspect prior commits, locate the original PR, and potentially cherry-pick the answer directly. This is especially risky when the task is based on a real upstream change.
Required Fix
Restrict history whenever possible, and remove git metadata after checking out the required state. At minimum, use:
git clone <repo_url> repo
git checkout <commit_hash>
rm -rf .git
Where appropriate, --depth 1 can also help reduce exposure.
🚨 The Core Issue: Repository History Can Reveal the Gold Answer
If the agent can browse commit history freely, the task stops measuring reasoning and starts measuring lookup.
Action Items for All Trainers:
Limit History Exposure: Use shallow cloning when possible.
Remove .git After Checkout: Do not leave commit history inside the task environment.
Audit for Leakage: Assume the agent will inspect anything you leave accessible.

Mistake 8: Verification Relies Too Heavily on Substring Matching

We have identified that some verifiers are awarding too much weight to static text checks instead of real behavioral validation. Please review the following to make your tasks robust.
Root Cause
Checks such as “does this file contain import zoneinfo” or “does this string appear in source” are easy to game. An agent can insert dead code or irrelevant text and still pass. When most of the verifier weight comes from substring checks, the task no longer measures whether the implementation actually works.
Required Fix
Make sure a substantial share of verifier weight comes from real execution, such as running a test suite or exercising the changed behavior directly. As a rule of thumb, aim for 50% or more of verifier weight to come from behavioral or functional testing. Use pattern checks only as light support, not as the foundation of the verifier.
Action Items for All Trainers:
Prioritize Behavioral Validation: Use test runs or functional execution whenever possible.
Use Pattern Checks Sparingly: Reserve them for lightweight guardrails, not primary scoring.
Check for Dead-Code Passes: Ask whether a non-working solution could still pass your verifier.

Mistake 9: Leaving Dockerfile Dependencies Unpinned

We have identified that some Dockerfiles are still using unpinned base images or package versions, which creates reproducibility issues across runs. Please review the following to prevent avoidable failures.
Root Cause
Using broad image tags such as python:3.9-slim or installing packages without version pins allows the environment to drift over time. This can break reproducibility, cause inconsistent trials, and introduce failures that are unrelated to the quality of the task itself.
Required Fix
Pin the base image tag and pin all pip-installed dependencies. For example, prefer:
FROM python:3.9.18-slim
and ensure that pip packages are version-pinned as well.
Action Items for All Trainers:
Pin the Base Image: Use exact version tags instead of floating variants.
Pin Python Dependencies: Do not leave pip packages unversioned.
Protect Reproducibility: The environment should behave the same across repeated task runs.


Mistake 10 
Solution / solve.sh Issues
Live network fetch in solve.sh — using curl github.com/.../pull/N.diff | patch makes the oracle non-reproducible and exposes the PR number as a reward-hacking vector; embed the full diff inline as a heredoc instead
Reference to internet files — solve.sh must be fully self-contained; no curl, wget, or any external URL at oracle runtime


Mistake 11:

If you select verifier_type = "llm-judge", then you should not use a static checker in the test case. In that situation, the evaluation must rely on the LLM judge.
If you are unsure how to formulate the verifier, please go through the samples already available in the repo:
https://github.com/turing-genai-apps/Multi-Agent-Swarm-Benchmark-/tree/main/example_tasks
This is especially important for scenarios where the expected response is subjective or can be expressed in multiple valid formats. For example, if the task asks the model to go through input artifacts and find the total number of tasks, then an LLM judge is necessary. The model might answer in different acceptable ways, such as:
12
The total number of tasks is 12
Unless you explicitly instruct that only an integer is accepted, a static checker would be too strict and may incorrectly fail valid answers.

Mistake 12:
No Synthetic Data
Do not generate clean, uniform data for your tasks. Real-world data has noise, missing fields, multi-line entries, encoding issues, and uneven distributions. Synthetic data (e.g. exactly 3 vulnerabilities per module across all modules) is an automatic fail. Use real corpora, real logs, real codebases.

Mistake 13:
Enforce What You Forbid
If your instruction.md says "don't use Python scripts" or "don't use keyword matching" — the verifier (test.sh) must actually detect and penalize violations. You cannot rely on the agent to follow honor-system rules. If you can't write a check for it, don't add the restriction. 


Mistake 14:
Oracle Values Must Be Defensible (Only for LLM judge as a verifier tasks) 
Every ground-truth value in your oracle must be traceable to a specific source (paper quote, line in codebase, data row). Ambiguous values (e.g. a paper says both 314 and 2,202 for the same metric) need a documented reason for which one you chose.



Section A — Project Overview

A.1 — What Is SwarmBench
SwarmBench is a benchmark for evaluating multi-agent AI systems on tasks that are structurally too large or too complex for a single AI agent to solve reliably. It is built on the Harbor evaluation harness, uses Docker for isolated execution, and measures the gap between single-agent and multi-agent performance on real-world tasks.
As a trainer, your job is to create tasks. Each task you produce is a self-contained evaluation unit — a real-world problem, an execution environment, a gold-standard oracle, and a verifier that scores the agent's work. You are not writing prompts. You are building evaluation environments.
What you will create for each task:
A human-authored task prompt (instruction.md) — a real problem a professional would face
A Docker environment (environment/Dockerfile) — the container the agent works inside
Input data (input_artifacts/) — the files, databases, or codebase the agent must process
A gold oracle (oracle.json or test suite) — the correct answer or test harness
A verifier (test.sh + judge.py or verify.py) — the script that scores the agent
A decomposition guide (decomposition.yaml) — how a multi-agent system should split the work
What Harbor does automatically: builds the container, runs the agent, runs your verifier, collects the score, saves the trajectory. You do not manage containers or infrastructure.
Two agent modes run on every task:
swarm-kimi-single — Kimi K2.5 running alone, with sub-agent spawning disabled
swarm-kimi-multi — Kimi K2.5 as an orchestrator, reading your decomposition guide and spawning sub-agents
Both run just 1 time each. You compare the scores.

A.2 — The Problem We Are Solving
Every day, professionals across medicine, research, engineering, and finance face tasks that are structurally too large for one person — or one AI — to handle alone.
A clinical fellow reviewing 1,500 case reports to identify a pattern in a rare post-procedural complication cannot hold all 1,500 cases in their head simultaneously. They divide the work: one resident reads cardiology cases, another reads vascular, a third reads systemic presentations. They meet, compare notes, synthesize. That coordination — divide, process in parallel, aggregate — is not a workaround. It is the only way the work gets done correctly.
A research team producing a systematic survey of 50 AI benchmark papers cannot assign all 50 to one person without losing rigor. Paper 47 gets a cursory skim. Subtle distinctions between benchmarks get conflated. Quotes get misattributed. The paper suffers.
A DevOps team responding to a critical CVE in a 200,000-line codebase cannot have one engineer read every module, identify every vulnerable call site, and patch them all before the disclosure deadline. They split by service, work in parallel, have a lead integrate.
This is what we are building the training data for: AI systems that coordinate the way expert human teams coordinate.

A.3 — Why Single Agents Fail at Scale
Large language models are extremely capable within a context window. The problem is structural, not one of intelligence.
For knowledge and research tasks (llm-judge):
Consider our medical research task — a clinician must read and clinically assess 1,500 case reports across three specialty databases (~500,000 tokens). A single agent attempting this faces:
Context overflow: By case 300, early cases are pushed out of the effective attention window. The agent forgets what it read in the first cardiac batch when synthesizing the vascular findings.
Attention degradation: With 500K tokens in context, the signal-to-noise ratio collapses. The agent begins hallucinating PMCIDs — citing cases that do not exist or mixing up details between cases.
Loss of diagnostic thread: The final synthesis requires holding three domains simultaneously. A single agent that has been reading for hours of context has no reliable working memory left for cross-domain reasoning.
A single expert clinician reviewing 1,500 case files would take weeks. The AI equivalent fails in a different way — it reads fast but loses precision the deeper it goes. This is the failure mode we are benchmarking.
For our agent benchmark landscape task — 11 research papers, each requiring careful extraction of 6 structured fields with verbatim quote evidence — a single agent begins confusing papers by paper 7. It attributes quotes from CRMArena to WorkArena. It hallucinates that a benchmark has 15 domains when the paper says 4. The errors compound. By paper 11, the extraction is unreliable.
For code and SWE tasks (executable):
Consider a team that has discovered CVE-2024-XXXXX in their authentication service — a token validation bug that exists in three microservices and 47 different call sites across 180,000 lines of Python. The remediation requires:
Finding every vulnerable call site across three services
Patching each one correctly without breaking adjacent logic
Running 340 integration tests across all three services to verify
A single agent exploring this codebase will run out of context budget before it finishes service one. It will patch 12 call sites, miss 35, and produce a codebase that still fails security tests — but now also has regression bugs.
Or consider a company migrating a monolithic Java 8 application to Java 17 — 80 modules, dozens of deprecated API calls, type casting changes, and library version conflicts. A single agent can handle perhaps 5–8 modules before its context fills and it starts introducing errors in module 9 that conflict with changes it made in module 2.
These are not toy scenarios. They are the exact situations where real engineering teams coordinate — and where AI needs to learn to do the same.

A.4 — What You Are Building
As a trainer, you are not writing test cases. You are building the training signal that teaches AI systems when and how to decompose, delegate, and synthesize — the cognitive architecture of a coordinated team.
Every task you create is a proof that:
This problem is real — a professional would spend 10–100+ hours solving it
A single agent structurally cannot solve it (not just slowly — structurally, due to context limits or attention degradation)
A coordinated multi-agent system can solve it by dividing context, working in parallel, and synthesizing results
The benchmark is rigorous by design. A task only counts if:
Single-agent -> it genuinely fails, not just struggles
Multi-agent -> the coordination strategy actually works
At least a 23-point gap between the two
Single agent times out or fails on a single trial
Multi-agent succeeds on a single trial
A task where both approaches score 60% is not useful. A task where both score 0% is broken. What you are looking for is a task with a structural wedge — one approach fails by design, the other succeeds by design.

A.5 — What Makes a Good Task
The task prompt must be human-authored. It should read like a real professional request — specific, grounded, with realistic constraints. We are looking for real-world problem statements, not synthetic data.
The prompt should be neither underspecified ("analyze these files") nor overspecified ("on line 342 of server-01.log, find the…"). It should give the agent the same level of briefing a human expert would receive before starting the work.
Good task sources:
Real clinical cases, research synthesis tasks, or data audits you have encountered professionally
Open-source repos with real bugs, real PRs, real CVEs
Public datasets that require multi-source cross-referencing
Literature review tasks drawn from real research questions
Two real examples from our benchmark:
Task: Diagnose a rare cardiac complication from 1,500 medical case files across 3 specialty databases
Pattern: fan-out/synthesize
Why it works: 500K tokens; single agent hallucinates PMCIDs by case 300; 15 sub-agents each handle 100 cases within attention range
Task: Survey 11 agent benchmark papers and extract 6 structured fields with verbatim quote evidence
Pattern: fan-out/synthesize
Why it works: Context fills by paper 7; sub-agents each own one paper with clean isolated context; evaluator sub-agents cross-check claims

Section 0 — How the Harness Works


0.0 — Setting Up Your Environment
Before you can create or test tasks, set up Harbor locally. Do this once.
To set up the evaluation harness, clone https://github.com/MathavanSG14/swarmbench-harness and follow the README.

If you do not have uv:
curl -LsSf https://astral.sh/uv/install.sh | sh
Docker Desktop must be running for any task execution.

0.1 — What Harbor Is (From a Trainer's Perspective)
Harbor is an evaluation harness. It takes your task folder, spins up a Docker container, runs an AI agent inside it, then runs your verification script, and collects a score.
As a trainer, you are responsible for three things:
The task — the instruction the agent reads
The environment — the Docker container the agent works inside
The verifier — the script that scores the agent's work
Everything else — container lifecycle, parallelism, result collection, trajectory logging — is handled by Harbor automatically.

0.2 — Task Directory Structure
Every task you create is a folder with this structure:
your-task/
├── instruction.md
├── task.toml
├── decomposition.yaml
├── environment/
│   └── Dockerfile
├── tests/
│   ├── test.sh
│   ├── oracle.json
│   ├── judge.py
│   └── verify.py
└── solution/
    └── solve.sh
instruction.md — What the agent reads. The full task prompt lives here.
task.toml — Task metadata and configuration (timeouts, resources, etc.)
decomposition.yaml — Gold decomposition guide for multi-agent runs
environment/
Dockerfile — Defines the container. Copies input files, clones repos, installs dependencies
tests/
test.sh — Harbor uploads this folder into the container and runs test.sh
oracle.json — Expected answer (llm-judge tasks)
judge.py — LLM scoring script (llm-judge tasks)
verify.py — Custom test script (executable tasks)
solution/
solve.sh — The gold solution. Only runs when you use the oracle agent
Key rule: Every file in tests/ is copied into the container at /tests/ before verification runs. Your test.sh and judge.py are accessible at /tests/test.sh and /tests/judge.py inside the container.

0.3 — Execution Phases
When you run:
harbor run -p ./your-task -a swarm-kimi-single
Harbor executes these phases in order:
Phase 1: BUILD
Docker image built from environment/Dockerfile
Your input files, repos, dependencies are baked into the image
This is the environment the agent will work in
Phase 2: START
Container started from the image
Three directories on your laptop are mounted into the container:
trial_dir/agent/     ←→  /logs/agent/
trial_dir/verifier/  ←→  /logs/verifier/
trial_dir/artifacts/ ←→  /logs/artifacts/
Anything written to /logs/ inside the container appears on your laptop automatically
Phase 3: AGENT SETUP
Harbor installs the agent (kimi-cli) inside the running container
Phase 4: AGENT RUN
Harbor reads instruction.md and passes it to the agent
The agent works inside the container — reads files, modifies code, writes answers
For llm-judge tasks:
Agent writes /logs/agent/output.json
For executable tasks:
Agent modifies files in the container
Phase 5: VERIFICATION
Harbor copies your tests/ folder into the container at /tests/
Harbor runs:
/tests/test.sh > /logs/verifier/test-stdout.txt 2>&1
test.sh runs your judge or verify script
The script writes the reward:
/logs/verifier/reward.json (llm-judge → {"reward": 0.75})
/logs/verifier/reward.txt (executable → "1" or "0")
Harbor reads the reward file and records the score
Phase 6: CLEANUP
Container stopped and removed
All results are on your laptop in trial_dir/

0.4 — The Oracle Agent: What Actually Runs
When you run Harbor with -a oracle instead of -a swarm-kimi-single, the agent phase changes completely:
Phase 4 (oracle): AGENT RUN
Harbor uploads your solution/ folder into the container at /solution/
Harbor runs:
/solution/solve.sh
This is the only thing that runs in Phase 4 for oracle
No LLM is called
No API request
Only your shell script executes
For an llm-judge task, your solve.sh is:
cp /solution/oracle.json /logs/agent/output.json
This copies the correct answer to /logs/agent/output.json. Then verification runs normally — test.sh calls judge.py, which compares output.json with oracle.json. Since they match, the exact-match shortcut returns reward = 1.0.
Why this matters:
The oracle run validates your pipeline. It proves that:
Your Dockerfile builds correctly
Your test.sh runs without errors
Your judge.py correctly scores a perfect answer
The reward file is written and readable
If the oracle run gives reward = 1.0, your task is structurally correct. If not, your verifier has a bug and must be fixed before running real agents.

0.5 — The Volume Mount: Why /logs/agent/ Matters
Harbor mounts directories between your laptop and the container:
Your laptop            Inside container
trial_dir/agent/  ←→   /logs/agent/
trial_dir/verifier/ ←→ /logs/verifier/
What this means: Anything written to /logs/agent/ inside the container instantly appears on your laptop in trial_dir/agent/.
This is why your instruction.md must explicitly say:
Write your final answer to /logs/agent/output.json
Any other path (e.g., /workspace/output.json) will not be collected and will be lost when the container stops.
After each run, your laptop contains:
trial_dir/
├── agent/
│   ├── output.json
│   ├── judge_justification.txt
│   ├── kimi-cli.txt
│   └── trajectory.json
├── verifier/
│   ├── reward.json
│   └── test-stdout.txt
└── result.json

0.6 — What Happens When Verification Fails
If your test.sh crashes (syntax error, missing file, import error), Harbor does not receive a reward file and the trial fails with RewardFileNotFoundError.
This appears as an exception, not a score.
To debug:
Open trial_dir/verifier/test-stdout.txt
This file contains everything printed before the crash
Common causes:
judge.py has a syntax error
Check with: python3 -c "import judge"
output.json was not written
The agent may have timed out or written to the wrong path
oracle.json is missing from tests/
FIREWORKS_API_KEY was not passed via --ve flag

With this foundation, you are ready to create your first task.

Section 1 — Choosing Your Verifier Type
Think of a task as a challenge you are setting for an AI agent — something genuinely hard, where a single agent would struggle but a coordinated team could succeed. Before writing a single line, you need to answer one question:
How will you know if the agent got it right?
That answer determines your verifier type, which shapes every file you create. There are two paths.


1.1 — LLM Judge (verifier_type = "llm-judge")
The idea: The agent produces a structured JSON answer. Another LLM (Kimi K2.5) reads that answer, compares it against your oracle, and scores it field by field — returning a float between 0.0 and 1.0.
This is the right choice when you are asking an agent to think, synthesize, or analyze — tasks where partial credit is meaningful and the answer can be captured as a JSON object.
Use this for:
Reading and synthesizing large document collections (research papers, case files, reports)
Data analysis where results are numbers, lists, or rankings
Diagnosis, classification, or recommendation tasks
Any task where a human expert would produce a structured report
How it works at runtime:
Agent works → writes /logs/agent/output.json
                        ↓
Harbor uploads tests/ → container at /tests/
                        ↓
test.sh calls judge.py
  → reads /logs/agent/output.json + /tests/oracle.json
  → calls Kimi K2.5: "score this field by field"
  → {"score": 0.75, "passed": 6, "total": 8, "justification": "..."}
                        ↓
/logs/verifier/reward.json written → Harbor reads it
Reward: 0.0–1.0. Score of 0.75 = 6 out of 8 criteria passed.
Files you create:
tests/oracle.json — The expected answer. Can be exact values or a validation rubric with accepted answers and minimum criteria.
solution/solve.sh — One line. Copies the correct answer to the agent output path. The oracle agent runs this and always scores 1.0 — validates your full pipeline before running real agents.
#!/bin/bash
set -euo pipefail
cp /solution/oracle.json /logs/agent/output.json
tests/test.sh — Calls judge.py. Use this template unchanged:
#!/bin/bash
set -euo pipefail
mkdir -p /logs/verifier
python3 /tests/judge.py \
  --agent-output /logs/agent/output.json \
  --oracle /tests/oracle.json \
  --reward-out /logs/verifier/reward.json
tests/judge.py — LLM judge. Use this template unchanged for most tasks:
import argparse
import json
import os
import re

from openai import OpenAI


def extract_json(text: str) -> str:
    text = text.strip()
    match = re.search(r"```(?:json)?\s*([\s\S]*?)```", text)
    if match:
        return match.group(1).strip()
    return text


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--agent-output")
    parser.add_argument("--oracle")
    parser.add_argument("--reward-out")
    args = parser.parse_args()

    try:
        agent_output = json.load(open(args.agent_output))
    except (FileNotFoundError, json.JSONDecodeError) as e:
        json.dump({"reward": 0.0}, open(args.reward_out, "w"))
        with open("/logs/agent/judge_justification.txt", "w") as f:
            f.write(f"Score: 0.0\n\nAgent output missing or invalid: {e}")
        return

    oracle = json.load(open(args.oracle))

    # Exact match shortcut — oracle agent always scores 1.0
    if agent_output == oracle:
        json.dump({"reward": 1.0}, open(args.reward_out, "w"))
        with open("/logs/agent/judge_justification.txt", "w") as f:
            f.write("Score: 1.0\n\nAgent output exactly matches oracle.")
        return

    client = OpenAI(
        api_key=os.environ["FIREWORKS_API_KEY"],
        base_url="https://api.fireworks.ai/inference/v1",
    )

    prompt = (
        "You are an evaluation judge grading an agent's output against a gold oracle.\n\n"
        f"ORACLE:\n{json.dumps(oracle, indent=2)}\n\n"
        f"AGENT OUTPUT:\n{json.dumps(agent_output, indent=2)}\n\n"
        "Evaluate the agent output field by field against the oracle.\n"
        "- Score 1.0 if ALL fields are correct.\n"
        "- Score 0.0 if completely wrong or missing.\n"
        "- Score between 0.0 and 1.0 based on fraction of fields that pass.\n\n"
        "List EACH field, PASSED or FAILED, with a brief reason.\n"
        "Respond in JSON only (no markdown):\n"
        '{"score": <float 0.0-1.0>, "passed": <int>, "total": <int>, '
        '"justification": "<field-by-field breakdown>"}'
    )

    response = client.chat.completions.create(
        model="accounts/fireworks/models/kimi-k2p5",
        messages=[{"role": "user", "content": prompt}],
        temperature=0,
    )

    raw = response.choices[0].message.content or ""
    try:
        result = json.loads(extract_json(raw))
    except json.JSONDecodeError as e:
        json.dump({"reward": 0.0}, open(args.reward_out, "w"))
        with open("/logs/agent/judge_justification.txt", "w") as f:
            f.write(f"Score: 0.0\n\nJudge parse error: {e}\nRaw: {raw}")
        return

    score = float(result.get("score", 0.0))
    json.dump({"reward": score}, open(args.reward_out, "w"))

    with open("/logs/agent/judge_justification.txt", "w") as f:
        f.write(
            f"Score: {score} ({result.get('passed','?')}/{result.get('total','?')} passed)\n\n"
            f"{result.get('justification', '')}"
        )


if __name__ == "__main__":
    main()
environment/Dockerfile — Base image with input files:
FROM python:3.12-slim
RUN apt-get update && apt-get install -y curl git
RUN pip install openai
COPY input_artifacts/ /input_artifacts/
WORKDIR /workspace
instruction.md — Must end with the output format. Use /logs/agent/output.json — it is volume-mounted and auto-collected by Harbor:
...your task prompt...

---

Write your final answer to `/logs/agent/output.json` in this exact JSON format:

{
  "field_1": <type>,
  "field_2": [<type>, ...],
  ...
}

Do not write anything else to that file.
Real examples from our benchmark:
Medical case diagnosis across 1500 case files → llm-judge
Vendor contradiction cross-reference across 10 reports → llm-judge
Agent benchmark landscape synthesis from 11 papers → llm-judge


1.2 — Executable Verifier (verifier_type = "executable")
The idea: The agent modifies code or files inside the Docker container. You write a test script that checks the result deterministically. No LLM is involved. Pass = 1, fail = 0.
This is the right choice for software engineering tasks. The key insight: you write the tests yourself. You are not dependent on whether a repo already has failing tests. You define exactly what “correct” means for this task and write a script that verifies it.
Use this for:
Bug fixes — the agent patches the root cause, and your test verifies the correct behavior
Feature implementations — agent writes code, your test checks the spec
Code migrations — the agent upgrades the codebase, and your test verifies nothing broke
Documentation or config changes verifiable by regex or static analysis
Any SWE task where correctness is binary
How it works at runtime:
Agent reads codebase + instruction → modifies files
                        ↓
Harbor uploads tests/ → container at /tests/
                        ↓
test.sh runs your verify.py
  → verify.py checks the agent's work
  → exits 0 (pass) or 1 (fail)
                        ↓
test.sh writes reward.txt → Harbor reads it
Reward: 1 (pass) or 0 (fail).
Files you create:
environment/Dockerfile — Clone the real repo at a pinned base commit. This is the state the agent starts from.
FROM python:3.12-slim

RUN apt-get update && apt-get install -y git curl patch
RUN curl -LsSf https://astral.sh/uv/0.7.13/install.sh | sh
RUN mkdir -p /logs

# Clone at the base commit — the starting state for the agent
RUN git clone https://github.com/your-org/your-repo.git /testbed
WORKDIR /testbed
RUN git checkout <base_commit_hash>



RUN pip install -e .
tests/verify.py — This is the most important file you write. It defines correctness for your specific task. Check whatever the agent should have changed — function behavior, file content, regex patterns, test output. Exit 0 for pass, non-zero for fail.
#!/usr/bin/env python3
"""
Verify that the agent correctly fixed the midnight UTC token expiry bug.
"""
import subprocess
import sys

# Run the specific behavior that should now work
result = subprocess.run(
    ["python3", "-c",
     "from auth import validate_token; assert validate_token('midnight_token') == True"],
    cwd="/testbed",
    capture_output=True,
    text=True,
)

if result.returncode != 0:
    print(f"FAILED: {result.stderr}")
    sys.exit(1)

print("PASSED: midnight UTC token now correctly validates")
sys.exit(0)
You can make verify.py as sophisticated as you need — run multiple checks, verify file contents, run pytest on a specific test, check regex patterns. As long as it exits 0 for correct and non-zero for incorrect.
tests/test.sh — Runs your verify.py and writes the reward. Harbor’s only requirement is that this script writes reward.txt. The pattern is always the same:
#!/bin/bash
set -euo pipefail
mkdir -p /logs/verifier

cd /testbed

# Run trainer-written verification script
set +e
python3 /tests/verify.py 2>&1 | tee /logs/verifier/test-output.log
exit_code=$?
set -e

# CRITICAL: Harbor reads reward.txt to determine the trial score.
# Without this, the trial fails with RewardFileNotFoundError.
if [ "${exit_code}" -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi

exit "${exit_code}"
solution/solve.sh — Apply the gold patch. Validates that your verify.py correctly detects a passing solution before running real agents.
#!/bin/bash
set -euo pipefail

cat > /testbed/solution_patch.diff << '__SOLUTION__'
<paste your git diff here>
__SOLUTION__

cd /testbed
patch --fuzz=5 -p1 -i /testbed/solution_patch.diff
instruction.md — Describe the task as a developer would file it. Point to the repo. Do not include the fix.
The repository at `/testbed` has a bug in the authentication module.

When a user provides a valid token with an expiry at exactly midnight UTC,
`validate_token()` incorrectly raises `TokenExpiredError`.

Fix the bug. Do not modify the test files. The repo is at `/testbed`.
Real examples (future tasks):
Fix a Django form validation bug → executable, verify.py runs the specific broken test
Migrate a Java 8 repo to Java 17 → executable, verify.py compiles and runs the suite
Add type annotations to a module → executable, verify.py runs mypy and checks exit code


1.3 — Decision Guide
What does the agent produce?
│
├── A structured JSON answer (findings, stats, diagnosis, report)
│   └── verifier_type = "llm-judge"
│
└── Modified code or files inside a codebase
   └── verifier_type = "executable"
       → You write verify.py that defines correctness
If unsure: knowledge, research, planning and operations, reasoning and math, and data analysis → llm-judge. Software engineering, data analysis → executable, and you own the test definition completely.

Section 2 — Agent Coordination Patterns
Before you write a single line of your task, decide how a multi-agent system should coordinate to solve it. This shapes your decomposition guide, your oracle, and what failure looks like for a single agent. In Phase 1 we support two patterns.



2.1 — Map-Reduce
The idea: The input is too large for one agent. Split it into independent shards — one per agent — process each in parallel, then aggregate all results.
When to use it: Multiple files, logs, databases, or records that are structurally similar. Each shard can be processed independently. The final answer requires merging.
Why single agent fails: Reading all shards sequentially fills the context window. The agent truncates early, hallucinates values from shards it can no longer see, or loses precision as context grows. The failure is structural — more data means less reliable output.
Real-world examples:
Scenario
Shard
Map
Reduce
Security audit: 6 microservice logs (500K events)
One log per agent
Error types, anomalous IPs, p95 latency
Global error distribution, deduplicate IPs, rank slow endpoints
Clinical diagnosis from 1,500 case files
~100 cases per agent
Classify relevance, extract PMCID + verbatim excerpt
Aggregate domain stats, cross-reference evidence, final diagnosis
Financial reconciliation across 12 quarterly reports
One report per agent
Revenue, COGS, margins, flag anomalies
YoY trends, cross-report discrepancies

coordination_pattern = "map-reduce"
decomposition.yaml structure:
sub_tasks:
  - id: map-shard-1
    description: "Process shard 1 — extract X, Y, Z"
    parallel_group: map
  - id: reduce-aggregate
    description: "Merge all mapper outputs into final answer"
    depends_on: [map-shard-1, map-shard-2]
    parallel_group: reduce


2.2 — Fan-Out / Synthesize
The idea: The task has multiple independent analytical threads, each needing focused attention. Fan out to parallel agents — one per thread — then synthesize all findings.
When to use it: Multiple independent dimensions requiring different lenses or sources. Each thread requires deep focused work. Final output synthesizes across threads — not just concatenates.
Why single agent fails: Holding all threads simultaneously dilutes attention. By thread 6–7, the agent conflates findings between threads, misses subtle distinctions, and produces a blurred synthesis. The failure is precision degradation under context pressure — not hard truncation.
Real-world examples:
Scenario
Thread
Fan-out
Synthesis
Survey 11 AI benchmark papers: 6 fields + verbatim quotes per paper
One paper per agent
Read completely, extract structured fields with exact quotes
Cross-validate, deduplicate overlapping benchmarks, final comparison table
Vendor cross-reference: contradictions across 10 reports in 4 domains
One domain per agent
Read all 10 reports through one domain lens, extract contradictions
Deduplicate, classify by severity, cross-domain summary
Drug interaction analysis across 6 clinical specialties
One specialty per agent
Literature review for specialty-specific interactions
Cross-specialty risk matrix, flag compound interactions

coordination_pattern = "fan-out-synthesize"
decomposition.yaml structure:
sub_tasks:
  - id: research-thread-1
    description: "Deep analysis of thread 1 — extract X, Y, Z with evidence"
    parallel_group: fan-out
  - id: synthesize
    description: "Merge all thread findings, resolve conflicts, final output"
    depends_on: [research-thread-1, research-thread-2]
    parallel_group: synthesize

2.3 — Choosing Between Them
Does the input split into independent, structurally similar chunks?
  YES → map-reduce
  NO  → Do multiple independent threads need parallel exploration?
          YES → fan-out-synthesize
          NO  → Rethink the task structure
In map-reduce, every agent does the same operation on a different chunk.
In fan-out, every agent does a different operation (or the same operation through a different lens) on the full input.

Section 3 — Domain Taxonomy
Every task belongs to a domain. Choose the one that best reflects the primary skill required. The domain determines which reviewers evaluate your task and what multi-agent benefit is expected.
Domain
task.toml value
Why Multi-Agent Helps
Example
Code / SWE
code-swe
Multi-file changes, parallel code review, cross-module analysis across large repos
CVE patching across 3 microservices; migrating 80 Java modules to Java 17
Knowledge / Research
knowledge-research
Multi-source synthesis and fact verification with isolated per-source attention
Survey of 11 benchmark papers; diagnosis from 1,500 case files
Data Analysis
data-analysis
Parallel processing of disconnected logs, tables, large datasets
Root cause across 6 service logs; 10-vendor cross-reference
Planning / Operations
planning-operations
Parallel research satisfying multiple independent constraints
500-person conference: venue, catering, AV, travel in parallel
Reasoning / Math
reasoning-math
Decomposes complex problems; independent solutions for consensus verification
Multi-part competition math with cross-check reliability



Section 3.5 (Task Exploration and Breaking Strategies)

For CODESWE domain 
PR Choosing Workflow
Use other languages like Rust, Ruby i.e. other languages as well
Agents are trained on Python because of SWE-Bench. Other languages are not 
Use newer PRs and Repos (current year) instead of really old ones as LLMs are really good at them
Go for types of tasks where the agent has to do
Feature deletion
Refactoring
Conversions
E.g., Moving from Pandas 2.0 to 2.2
NOTE: If you see a PR Issue that has been worked on in the sheet below, please avoid working on those problems
MultiAgentSwarm Problems Worked on

For the other domains, we are yet to add strategies here on how to tackle them

For Math/Reasoning domain

Go through the below document to get a better understanding at how to formulate expert level math problems.
SwarmBench Math/Reasoning

For Knowledge/Research domain

Go through the below document to get a better understanding at how to formulate expert level research problems
Knowledge/Research Domain Guide for Task Authoring


ALL DOMAINS
In cases where Single + multi failing
giving helping hand to both agents in instructions.md, but single still fails, but multi passes
To let the agent use the reduce step as a subagent
The reduce step could explicitly say “MUST be executed by a dedicated fifth reducer sub-agent."
NOTE: This can backfire if your decomposition.yaml isn’t properly written; you are artificially increasing the computation, leading to 





Strategy for Designing Tasks Where Single Agents Fail and Multi-Agent Systems Pass

Overview
The correct way to create a strong and durable gap between single-agent and multi-agent systems is not by trying to “trick” the model with clever wording. Instead, the focus should be on task structure.
Well-designed tasks should naturally reward:
Decomposition
Parallel execution
Structured synthesis
Verifiable completeness
A successful task typically follows this structure:
Many artifacts → Independent subproblem solving → Reducer synthesis → Verified final output
In contrast, tasks like:
One bug → One file → One fix → One test
will almost always be solved by a strong single agent and therefore fail to create meaningful differentiation.
The key insight from both research and practice is simple:
Multi-agent systems outperform only when the task is inherently decomposable.

Core Design Principle: Breadth Under Budget
The central objective is to design tasks where success depends on breadth, not just intelligence.
This means:
Many artifacts must be processed
Multiple constraints must be tracked
Outputs must be reconciled
Work must fit within a fixed time budget
This creates natural pressure on single agents:
They lose track of coverage
They miss edge cases
They exceed time limits
They forget secondary requirements
Multi-agent systems succeed because they:
Divide ownership
Work in parallel
Maintain structured outputs
Use a reducer to verify and merge results

1. Start With Natural Parallelism
Before building any task, validate:
Can this be split into 4–10 independent subproblems?
Can outputs be merged without ambiguity?
Will a single agent struggle with coverage or time?
If the answer is no, discard the task.
Good Task Shape
Many files, reports, or datasets
Independent processing per unit
Final aggregation step
Bad Task Shape
Single dependency chain
One core insight
Sequential reasoning only

2. Use Timeout as a Valid Failure Mode
Single-agent failure does not need to be incorrect output.
Timeout is a valid and important failure signal.
Workflow:
Run oracle → must score 1.0
Run multi-agent with generous timeout
Record runtime
Set benchmark timeout close to that runtime
Run single-agent under same conditions
Valid Outcome:
Multi-agent finishes in 9 minutes
Single-agent still exploring at 10 minutes
→ This is a valid gap

3. Design for Coverage Failure (Not Just Difficulty)
Single agents are strong at:
Solving one core problem
Finding one key insight
They are weak at:
Exhaustive coverage across many items
Strong Task Patterns:
Fix all deprecated usages across 30+ files
Extract obligations across multiple contracts
Reconcile inconsistencies across reports
Process all rows across multiple datasets
Scoring Principle:
Partial completion must give partial score
Example:
Single-agent: 60% coverage → 0.60 score
Multi-agent: 100% coverage → 1.00 score

4. Use Context Overload via Environment (Not Prompt)
Do not overload the prompt.
Instead:
Place artifacts in files, folders, repos
Force traversal and extraction
Example Inputs:
/input/reports/report_01.txt … report_20.txt
/input/contracts/*.txt
/src/module_a … module_z
/docs/topic_01 … topic_20
Why this works:
Single-agent struggles with:
Attention degradation
Constraint loss
Missed items
Multi-agent:
Assigns artifacts per worker
Maintains local context
Avoids context pollution

5. Require Reconciled Deliverables
This is one of the strongest strategies.
Do not ask for just one output.
Require multiple outputs that must agree.
Example:
Update source code
Update tests
Generate CHANGES.md
Generate MIGRATION.md
Generate REMOVED_SYMBOLS.json
Verify all outputs match system state
Why it works:
Single-agent:
Completes main task
Misses secondary outputs
Multi-agent:
Splits ownership
Uses reducer to verify consistency

6. Optimize Decomposition (Before Increasing Difficulty)
If multi-agent fails, the issue is usually bad decomposition, not task difficulty.
Bad Decomposition:
Agent 1: solve task
Agent 2: solve task
Good Decomposition:
Agent 1: inspect source files
Agent 2: update tests
Agent 3: update docs
Agent 4: generate manifest
Reducer: verify consistency
Key Rule:
Assign clear ownership
Define expected outputs
Avoid duplication of work

7. Handle High Single-Agent Scores Carefully
If single-agent scores > 60% early:
The task is only valid if:
Multi-agent ≈ 100%
Gap ≥ 23 points
OR single-agent requires much longer time
If not:
Fix using:
More artifacts
Stronger reconciliation
Tighter timeout
Or discard the task

8. Prefer Read-Heavy Over Write-Heavy Tasks
Parallelism works best when tasks are:
Inspection
Classification
Extraction
Analysis
Parallelism fails when:
Multiple agents modify the same output
Best Strategy:
Parallelize reading + planning
Centralize writing via reducer

9. Source Selection Strategy
Choose datasets that naturally provide shards.
Good Sources:
Multi-file codebases (SWE tasks)
Contract bundles (legal)
Financial reports (finance)
Multiple CSV datasets (data analysis)
Research paper collections (science)
Avoid:
Single-file problems
Puzzle-style tasks
Sequential reasoning chains

10. Anti-Patterns to Avoid
❌ Difficulty without decomposition
Hard ≠ multi-agent suitable
❌ Vague agent roles
Leads to duplication and confusion
❌ Over-reliance on prompt tricks
Single agents can simulate workflows
❌ Parallel write conflicts
Creates noise, not signal

11. Practical Acceptance Rubric
Use this checklist:
Task Design
≥ 5 independent subproblems
Clear reducer logic
No hidden merge assumptions
Environment
Real artifacts (files, repos, datasets)
Not just large prompts
Verification
Deterministic or structured
Partial scoring supported
Evaluation Flow
Oracle → 1.0
Multi-agent → 0.95–1.0
Single-agent → ≤ 0.72 OR timeout
Retention Criteria
Keep task only if:
Gap ≥ 23 points
Multi-agent succeeds cleanly
Single-agent fails under same budget

Final Principle
The entire strategy can be summarized as:
Break the single-agent with breadth, coverage, reconciliation, and time constraints.
Then make the multi-agent succeed through structured decomposition and strong reduction.
This is the only reliable way to create tasks that remain meaningful even as single-agent models continue to improve.




How to Build Good Tasks Faster and Smarter

1. Purpose of this guide
This guide explains how trainers should:
build valid SwarmBench tasks
manage time well
debug in the correct order
improve task quality without wasting runs
finish work within AHT

2. What is a valid task?
A task is valid when:
multi-agent passes
single-agent fails
the score gap is 23 points or more
There are two valid ways this can happen.
Valid Type 1: Normal fail vs pass
A single agent gets a low score
The multi-agent gets a high score
The gap is 23+ points
Valid Type 2: Timeout fail vs pass
The multi-agent finishes and passes within the time limit
The single-agent fails because it times out within the same time limit, so the reward is 0
The gap is 23+ points - make sure the multi-agent passes with a 23 point gap.
This is also valid.


Important fairness rule
If a multi-agent system is given 20 minutes, then a single agent must also be given 20 minutes.
Use:
same task
same evaluation
same environment
same time budget
Only then is it a fair comparison.

3. Important note about single-agent tool calls
Sometimes trainers may think:
“If a single agent uses many tool calls, maybe the task is no longer valid.”
That is not true.
Even if a single agent uses many tool calls, the task is still valid if:
It still fails
Or it still times out
And multi-agent still passes
and the gap is 23+ points
So the rule is not “single-agent must do less work.”
The rule is:
A single agent must still fail under the fair setup
The multi-agent must still succeed under the same fair setup
Making the agents make many calls to tools will also push their context limit, and their accuracy degrades. 
For example, we created a task where we asked a single agent to read 16 research papers using a web call tool, but it failed with the same task, multi agent was able to solve it by decomposing it into sub-agents, where each takes care of one research paper.
If a single agent makes many tool calls and still cannot finish, that is still a valid failure.

4. Main rule for trainers
Do not sit idle during agent runs
A single-agent run and a multi-agent run can take a long time.
While they are running, you should already be working on the next task.
Correct working style
Think like this:
Task 1 is running
You prepare Task 2
Task 1 results come back
You decide: package it, improve it, or drop it
Then Task 2 moves forward
This is how you reduce wasted time and control AHT.

5. Full trainer workflow
Follow this order for every task.
Step 1: Prepare the task
Before running agents, do these first:
Choose a good dataset
Write the problem statement
Write Oracle Solution
Write test cases
Check if the task really needs decomposition
Check if the task is not too easy for one agent


Step 2: Run draft LLM review first
Before expensive agent runs, run the draft LLM reviewer.
This helps catch:
weak prompt design
unclear instructions
low-quality task setup
avoidable mistakes
This saves reruns later.
Step 3: Run both agents in parallel
Run:
single-agent in one terminal
multi-agent in another terminal
Do not wait for one to finish before starting the other unless needed.
Step 4: While runs are happening
Start working on the next task:
Find the next dataset
Draft the next problem
Think about decomposition
Prepare the next test cases
Do not waste time watching the terminal.

6. Best kind of tasks to choose
The best SwarmBench tasks are not just “hard.”
They should be split-friendly for multi-agent and heavy for single-agent.
Good tasks often have:
many files
many records
many shards or chunks
Repeated work across parts
a clear merge or synthesis step
a need for cross-checking
a need for a summary across many sub-results
Pushes the agent to do multiple tool calls, which degrades the quality of a single agent. 
These task types are usually better than small tasks with tricky wording.

7. What to do after results come back
There are a few common cases.

Case 1: Single-agent fails, multi-agent passes
This is the best case.
What to do
Check that the gap is 23+ points
Check that the result is stable
package the task
Do not keep changing a task that is already good.

Case 2: Single-agent fails, multi-agent also fails
This means the task idea may still be good, but the multi-agent setup is weak.
First action: check the multi-agent trajectory
your_task_id/execution_logs/multi-kimi-agent/your_task_id/agent/trajectory.json
Look for:
where failure starts
which sub-agent got confused
whether the work split is too large
whether the instructions are too vague
whether the synthesis step is weak
First fix: improve decomposition.yaml
This should usually be the first fix.
Try to:
split the work into smaller parts
give each sub-agent a clear job
reduce confusion
improve the final merge step
guide the work without giving the answer
This is usually the fastest way to improve multi-agent performance.
Second fix: improve instruction.md
If decomposition fixes are still not enough, then improve instruction.md.
Do this carefully:
add open hints
clarify the task
remove ambiguity
Do not:
give the exact solution
make the task too easy
help both agents too much
After changes, rerun both agents.

Case 3: Single-agent passes above 70%
This is a danger sign.
But do not stop thinking at:
“This task is bad.”
Your next question should be:
Can this become a timeout task?
This is an important strategy.
If single-agent passes above 70%, think:

Estimate time, you can refer to your multi-agent run logs to see how much time it took, and see how much time the single agent took -if the single agent took more time than the multi-agent, then cap it by adding a timeout in task.toml-
[agent]
timeout_sec = 10
and run the single agent again to see if it fails.
If yes, the task may still be valid.
Timeout strategy
A task is still valid when:
multi-agent passes within the time limit
single-agent times out in the same time limit
gap is 23+ points
This is allowed by the client rule.
Important extra point
Even if the single-agent uses many tool calls, this is still okay.
If it still fails or times out under the same fair time budget, the task is valid.
Good ways to make timeout happen
Use changes like:
larger dataset
more files
more records
more chunks
more search work
more compare work
more merge work
more synthesis work after parallel steps
These changes help multi-agent because it can split the work.
Bad ways to make timeout happen
Do not use:
confusing wording only
unclear instructions
random noise
broken evaluation
tricks that make both agents fail equally
If the timeout strategy does not work, then the task is probably not a good fit. Drop it.
Where both agent solves it in the same amount of time. 

Case 4: Both agents pass
This usually means the task is too easy.
What to do
do not package it
check if the prompt gives away too much
check if the dataset is too small
check if decomposition is not really needed
redesign it or drop it

Case 5: Multi-agent is better, but the gap is below 23
This means the task may be closed, but not ready yet.
What to do
improve decomposition
increase parallel work
increase synthesis burden
test again
This is often easier to fix than a task where both agents fail badly.

8. Best order for debugging
When a task is not working, do not change everything at once.
Use this order:
1. Check if the task itself is good
Ask:
does this task really need decomposition?
can one strong agent solve it alone?
is the dataset too easy?
is the task naturally parallel?
If the answer is bad here, stop early.
2. Check trajectories
Look at where failure starts and debug based on the single agent trajectory, how it’s able to pass, and the multi-agent trajectory, how it's failing, and improve your task from there.
3. Improve decomposition.yaml
This is usually the safest and fastest fix.
4. Run again
5. Improve instruction.md only if needed
6. Run again
7. If still weak, drop the task
Do not spend too much time trying to save a weak task.

9. Best strategies to reduce AHT
These are the main work habits every trainer should follow.
Strategy 1: Work in pipeline mode
Do not work on only one task from start to finish.
Correct way:
one task running
one task being prepared
one task being reviewed
Strategy 2: Use draft review early

Catch obvious problems before expensive runs.


Strategy 3: Fix decomposition before fixing the prompt
This usually improves multi-agent faster and protects the gap better.
Strategy 4: Use a timeout strategy when the single agent is too strong
If single-agent passes, ask:
Can this become a valid timeout task?
Strategy 5: Choose split-friendly tasks
Pick tasks with:
many parts
repeated work
parallel steps
strong final merge step
Strategy 6: Do not rerun blindly
Every rerun should have a reason:
What failed?
What changed?
Why should this new run be better?
Strategy 7: Drop weak tasks early
A weak task wastes more time than starting a better one.
Strategy 8: Fair comparison always matters
If using timeout:
same task
same time budget
same scoring
same environment
Strategy 9: More tool calls by single-agent do not make the task invalid
If single-agent still fails or times out, it is still a valid failure.

10. Quick decision guide
Use this after each run.
If single-agent fails and multi-agent passes
Package it
If single-agent fails and multi-agent fails
Improve decomposition first
If single-agent passes above 70%
Try timeout strategy next
If both pass
Task is too easy, redesign or drop
If gap is below 23
Improve structure and decomposition, then rerun


11. Things trainers must not do
Do not:
sit idle during runs
rerun without understanding the failure
change prompt and decomposition randomly
make the task easier for both agents
keep pushing a weak task for too long
use unfair timing between single and multi-agent
assume many tool calls by single-agent means the task is invalid

12. Final expectation
A good trainer does not only “make a task.”
A good trainer:
manages time well
works on the next task while one task is running
knows what to debug first
improves decomposition before making the prompt easier
knows timeout is a valid strategy
knows single-agent can still fail even with many tool calls
knows when to stop and drop a weak task
The final goal is:
multi-agent pass
single-agent fail or timeout
23+ point gap
fair comparison
good quality
completed within AHT

13. One-line reminder for trainers
Do not wait during runs. Do not rerun blindly. Build tasks that split well for multi-agent, stay hard for single-agent, and use timeout strategy when needed.


Section 5 — Writing instruction.md
instruction.md is the only thing the agent reads. It is the task. Everything the agent does — every file it opens, every decision it makes, every field it writes — is a consequence of what you write here. A weak instruction produces a weak agent response, and a weak response produces a noisy reward signal that cannot be used for training.
This section covers how to write an instruction that is unambiguous, fair, and evaluable.

5.1 — Universal Rules (All Task Types)
Rule 1: Human-authored. No exceptions.
The task prompt must be written by you — a domain expert — not generated by an LLM. An LLM-generated prompt sounds generic, lacks real constraints, and often underspecifies the task in ways that are invisible until agents start producing wrong answers. Reviewers can identify LLM-generated prompts and will reject them.
Rule 2: Give the agent the same briefing a human expert would receive.
Imagine you are handing this task to a brilliant but newly onboarded professional. They are smart, but they do not know your domain defaults. Write the instruction at that level — specific enough to be actionable, not so detailed that you are doing the work for them.
Rule 3: Neither underspecified nor overspecified.
Underspecified
Overspecified
Right level
"Analyze these log files and find issues."
"In line 8,432 of server-01.log, find the 429 error from IP 192.168.1.1 at 14:32:07."
"Across all 3 server logs, identify the top 5 slowest endpoints by average response time and any IPs with >50% error rate across 1,000+ requests."
"Review these vendor reports."
"On page 4 of Vendor A's report, there is a contradiction with page 7 of Vendor B's report about…"
"Identify all contradictions between the 10 vendor reports, categorized by domain (financial, technical, security, market)."

Rule 4: Every constraint your oracle or verifier enforces must appear in the prompt.
If your oracle.json requires verbatim excerpts, the prompt must say so. If your verify.py checks that a specific function returns a specific type, the prompt must specify that function and type. If the agent does not know a rule exists, scoring them on it is a false failure — and false failures corrupt the training signal.
Rule 5: State all file paths and working directories explicitly.
The input files are at:
/input_artifacts/server-01.log
/input_artifacts/server-02.log

Your working directory is /workspace.
Agents should never have to guess where files are.
Rule 6: Do not hint at the answer.
If your oracle answer is "the top 5 slowest endpoints are X, Y, Z…", do not mention X, Y, or Z in the prompt. The prompt should describe the task; the oracle should contain the answer.

5.2 — LLM-Judge Tasks: Output Format Requirement
For verifier_type = "llm-judge", the agent's output goes to /logs/agent/output.json — and your judge.py compares it against oracle.json. This means the output format you specify in the prompt must exactly match the structure of your oracle.
Every key in oracle.json must appear in the output format section of your prompt. Every type must match. If your oracle has "error_rate_pct": 20.77 (a float), your prompt should say "error_rate_pct": <float> — not <int>. If your oracle has nested structures, your prompt must show exactly that nested structure.
The output format block is mandatory at the end of every llm-judge instruction.md:
---

## Output Instructions

Write your final answer to `/logs/agent/output.json` in this exact JSON format:

```json
{
  "field_1": <int>,
  "field_2": <float>,
  "field_3": {
    "sub_field": <str>
  },
  "field_4": [
    {
      "item_key": <str>,
      "item_value": <int>
    }
  ]
}
Do not write anything else to that file.

Common mistakes that produce false failures:
Mistake
What happens
Output format keys do not match oracle keys
judge.py compares different keys and scores 0 even if values are correct
Prompt says <int> but oracle has a float
Agent writes wrong type, judge marks mismatch
Prompt shows flat structure but oracle is nested
Structural mismatch → score 0
Missing a field in output format
Agent does not produce it → score 0
Output format not at the end
Agent may miss or ignore it

The format block must use the exact same key names as your oracle.json.

5.3 — Code-Execution Tasks: Specification Completeness
For verifier_type = "executable", your verify.py defines correctness. If your test expects a specific function, signature, or behavior and the prompt does not specify it, an otherwise correct solution can fail. That is a false failure caused by underspecification.
Everything your verifier checks must be specified in the prompt:
What verify.py checks
What your prompt must say
from auth import validate_token
Fix the validate_token function in auth.py
validate_token(token, expiry=...)
The function signature must remain validate_token(token, expiry)
assert result == True
The function should return True for valid tokens

Rules for code-execution prompts:
Name the file explicitly
Name the function if referenced in tests
Specify the interface if required
Name the test for self-verification
State what must NOT be modified
Specify return types if enforced
State the working directory (/testbed)
False failures are treated as trainer errors.

5.4 — RL Training Signal Considerations
This benchmark produces training data for reinforcement learning. The reward signal is only useful when:
A capable agent can succeed
An incapable agent fails
Partial credit reflects real progress
If a prompt causes false failures, capable agents get reward = 0 — bad training signal.
If a prompt is overspecified, weak agents get reward = 1 — also bad signal.
Write prompts where correct work leads to high reward and incorrect work leads to low reward.

5.5 — Quick Checklist Before Submitting
Written by me, not generated by an LLM
All input file paths are explicit
Working directory is stated
Every oracle/verifier constraint is mentioned
For llm-judge: output format matches oracle exactly and is at the end
For executable: function names, signatures, path and other details if i don’t give it then multi agent can’t pass 100 percent should be given here and specified
The agent is told what NOT to modify
No hints about the correct answer
A domain expert could clearly execute the task

5.6 — False Failures: When the Agent Was Right but Scored Zero
A false failure is when the agent produced a correct answer but your verifier rejects it due to prompt gaps.
Common causes and fixes:
Field name mismatch → use exact oracle keys
Type mismatch → specify <int>, <float>, etc.
Sort order ambiguity → explicitly define ordering
Floating precision → define rounding rules
Case sensitivity → specify lowercase/uppercase rules
Structure mismatch → show exact JSON structure
Verbatim excerpt ambiguity → define exact length/format
ID format mismatch → define format (e.g., PMC123456)
Wrong module path → specify exact import path
Missing required field → include in output format
Golden rule: If a correct answer can be rejected, fix the prompt so to test this easily make sure to run your multi agent and see if it’s passing 100 percent or not. 


5.7 — Reward Hacking: How Agents Game the Verifier
Reward hacking occurs when agents achieve high scores without solving the task.
Common vulnerabilities:
Oracle exposed in input_artifacts/ → agent copies it
decomposition.yaml leaks answers → agent skips computation
Weak judge prompt → rewards plausibility instead of correctness
Keyword checks → agent inserts keywords without solving
Round numbers → agent guesses values
Placeholder/null values → agent fills structure without content
No proof-of-read fields → agent reads partial data
Prompt leaks answer → agent infers solution
Design principles to prevent hacking:
Include at least one field requiring real input reading
Use non-guessable values (precise floats, IDs)
Keep oracle.json and verifier only in tests/
Ensure decomposition.yaml contains no answers
Judge must evaluate field-by-field correctness

Section 6 — Building the Environment (environment/)
The environment/ folder contains your Dockerfile — the blueprint for the Docker container your agent will work inside. Everything the agent needs — input files, source code, installed packages, language runtimes — must be in this container. If it is not in the Dockerfile, the agent cannot use it.
This is the foundation. A broken Dockerfile means a broken task. Get this right first.

6.1 — For LLM-Judge Tasks (Knowledge / Research / Data Analysis)
These tasks give the agent input files to read and analyse. The Dockerfile copies those files in and installs minimal tooling.
Template:
FROM python:3.12-slim

RUN apt-get update && apt-get install -y curl git
RUN pip install openai

COPY input_artifacts/ /input_artifacts/

WORKDIR /workspace
What to put in environment/input_artifacts/:
Log files, JSONL databases, CSV data, text documents — anything the agent must read
Place them inside environment/input_artifacts/ (not at the task root) because Docker COPY is relative to the Dockerfile's directory
Your folder structure:
your-task/
├── environment/
│   ├── Dockerfile
│   └── input_artifacts/
│       ├── server-01.log
│       ├── server-02.log
│       └── server-03.log
The Dockerfile copies them to /input_artifacts/ inside the container. Your instruction.md should reference them as /input_artifacts/server-01.log.
Common mistakes:
Putting input_artifacts/ at the task root instead of inside environment/
Forgetting pip install openai, which causes judge.py to fail during verification

6.2 — For Code-Execution Tasks (SWE / Code)
These tasks give the agent a real codebase to fix, modify, or extend. The Dockerfile clones the repo at the correct commit and installs dependencies.
Template:
FROM python:3.12-slim

RUN apt-get update && apt-get install -y git curl patch
RUN curl -LsSf https://astral.sh/uv/0.7.13/install.sh | sh
RUN mkdir -p /logs

RUN git clone https://github.com/your-org/your-repo.git /testbed
WORKDIR /testbed
RUN git checkout <base_commit_hash>
RUN rm -rf .git

RUN pip install -r requirements.txt
RUN pip install -e .

6.3 — Understanding the Base Commit
The base commit is the commit immediately before the fix was introduced. It represents the broken state.
Commit timeline example:
... → abc123 → def456 → ghi789 (fix merged)
              ↑
        This is the base commit
How to find it:
Locate the PR that fixed the bug
Identify the merge point
Use the commit just before the fix
What goes wrong if incorrect:
After fix → bug does not exist → agent passes → invalid task
Too early → code mismatch → tests fail incorrectly
Wrong branch → environment inconsistency
Validation:
Run test on base commit → must fail
Apply solution/solve.sh → test must pass

6.4 — Installing Dependencies
The agent operates entirely within your container. Missing dependencies lead to incorrect failures.
Best practices:
Pin versions explicitly (python:3.12-slim)
Install project dependencies
Examples:
RUN pip install -r requirements.txt
RUN pip install -e .
Additional tools if needed:
RUN apt-get install -y build-essential
RUN apt-get install -y default-jdk
RUN pip install pytest mypy
Always include dependencies required by verify.py and test.sh.

6.5 — Using LLM to Generate the Dockerfile
You may use an LLM to assist with Dockerfile generation for complex repos.
Provide:
Repository URL
Base commit
Language and build system
Dependency constraints
Example instruction:
Create a Dockerfile using python:3.12-slim
Clone repo at commit abc123
Install dependencies
Install pytest and mypy
Set working directory to /testbed
Create /logs directory
Always validate manually:
Build image
Verify repo checkout
Confirm imports work
Ensure test fails before patch
Ensure test passes after patch
Never submit an unverified Dockerfile.

6.6 — Where Things Go Wrong
Wrong base commit
Bug does not exist → task invalid
Missing system dependencies
Build fails due to missing libraries
Invalid requirements.txt
Pinned packages unavailable
Incorrect build context
Docker cannot find files
Large repository clone
Use shallow cloning where possible
Missing tools (pip, curl)
Agent cannot install dependencies
Python version mismatch
Repo incompatible with chosen version
Example fix:
FROM python:3.12-slim
RUN apt-get update && apt-get install -y python3.9 python3.9-venv

Section 7 — Writing Tests (tests/)
The tests/ folder is uploaded into the container at /tests/ after the agent finishes. Harbor runs /tests/test.sh and reads the reward file it produces. This is the only mechanism Harbor uses to score a trial.
Use the templates below as your starting point. Do not invent a new structure — adapt to your task. The reward write at the end of test.sh is non-negotiable.

7.1 — For LLM-Judge Tasks
Files required: tests/test.sh, tests/judge.py, tests/oracle.json
tests/test.sh — use unchanged:
#!/bin/bash
set -euo pipefail
mkdir -p /logs/verifier
python3 /tests/judge.py \
  --agent-output /logs/agent/output.json \
  --oracle /tests/oracle.json \
  --reward-out /logs/verifier/reward.json
tests/judge.py — use the template from Section 1.1. What you customize is only the judge prompt string if your task needs domain-specific scoring.
For example, if multiple answers are acceptable for a field:
# Add to the prompt string inside judge.py:
"Note: For the 'weakest_domain' field, accept both 'vascular' and 'systemic' as correct. "
"For 'final_diagnosis', accept any of: intramural haematoma, intramural hematoma, "
"coronary intramural haematoma — these are the same diagnosis."
Best practices:
Ask the judge to score fields independently. “Is the overall answer correct?” loses resolution — an agent that gets 8/10 fields right should not score 0 because field 9 was wrong.
For fields with multiple valid answers, list them explicitly in the judge prompt. Without this, the judge will mark a correct agent wrong.
Keep strict scoring for exact fields (PMCIDs, counts, verbatim excerpts). Add tolerance only for floats and multi-valid-answer fields.
Where things go wrong:
output.json missing — agent timed out or wrote to wrong path. The template’s try/except catches FileNotFoundError and writes reward=0.0 with a message in judge_justification.txt. Read that to diagnose.
FIREWORKS_API_KEY not passed — judge.py crashes on the first API call. Always pass --ve FIREWORKS_API_KEY=$FIREWORKS_API_KEY in your run command.
Judge returns empty response — API timeout or rate limit. raw will be "", the except block fires, reward=0.0 is written. Check verifier/test-stdout.txt for the error.

7.2 — For Code-Execution Tasks
Files required: tests/test.sh, tests/verify.py
tests/test.sh — use unchanged:
#!/bin/bash
set -euo pipefail
mkdir -p /logs/verifier

cd /testbed

set +e
python3 /tests/verify.py 2>&1 | tee /logs/verifier/test-output.log
exit_code=$?
set -e

# MANDATORY — Harbor reads this. Without it: RewardFileNotFoundError.
if [ "${exit_code}" -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi

exit "${exit_code}"
The set +e / exit_code pattern is critical. It prevents a failing assertion from exiting the script before reward.txt is written. Never remove it.
tests/verify.py — you write this. Here is a realistic example for a task that asks the agent to fix a discount calculation bug.
The prompt said:
“Fix calculate_discount() in pricing/calculator.py. For account_type='premium', the discount should be 15%, not 20%. For account_type='standard', keep 10%. The function signature is calculate_discount(price, account_type) and must return a float.”
#!/usr/bin/env python3
"""
Verify: calculate_discount() applies correct discount rates.
Every check here corresponds to an explicit requirement in instruction.md.
"""
import sys
import importlib.util
from pathlib import Path

TESTBED = Path("/testbed")
passed = 0
total = 0


def check(name, fn):
    global passed, total
    total += 1
    try:
        fn()
        print(f"  PASS  {name}")
        passed += 1
    except Exception as e:
        print(f"  FAIL  {name}: {e}")


# Import defensively — agent may have put the file in the wrong location
try:
    spec = importlib.util.spec_from_file_location(
        "calculator", TESTBED / "pricing/calculator.py"
    )
    if spec is None:
        print("IMPORT ERROR: pricing/calculator.py not found at /testbed/pricing/calculator.py")
        sys.exit(1)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    calc = module.calculate_discount
except Exception as e:
    print(f"IMPORT ERROR: {e}")
    sys.exit(1)

# Check 1: premium account gets 15% (the bug that was reported)
def test_premium_discount():
    result = calc(100.0, account_type="premium")
    assert abs(result - 85.0) < 0.01, \
        f"premium 15% discount: expected 85.0, got {result}"

# Check 2: standard account still gets 10% (regression)
def test_standard_discount():
    result = calc(100.0, account_type="standard")
    assert abs(result - 90.0) < 0.01, \
        f"standard 10% discount: expected 90.0, got {result}"

# Check 3: return type is float (specified in prompt)
def test_return_type():
    result = calc(50.0, account_type="premium")
    assert isinstance(result, float), \
        f"return type must be float, got {type(result).__name__}"

# Check 4: zero price edge case (not undefined behavior)
def test_zero_price():
    result = calc(0.0, account_type="premium")
    assert result == 0.0, \
        f"zero price should return 0.0, got {result}"

check("premium 15% discount", test_premium_discount)
check("standard 10% regression", test_standard_discount)
check("return type is float", test_return_type)
check("zero price edge case", test_zero_price)

print(f"\nResult: {passed}/{total} checks passed")

# Write fractional reward for partial credit
with open("/logs/verifier/reward.txt", "w") as f:
    f.write(str(passed / total))

sys.exit(0 if passed == total else 1)
Rules for writing verify.py:
Rule 1: Every check must trace back to a line in instruction.md.
Before finalizing, read both files side by side. For every check(...) call, find the sentence in the prompt that justifies it. If you cannot find it, remove the check or add the requirement to the prompt.
Rule 2: Import defensively with a clear error message.
If the agent put the file in the wrong location, a bare ImportError tells you nothing. Print the expected path before exiting. This makes test-output.log immediately useful for debugging.
Rule 3: Use abs(result - expected) < tolerance for floats, never ==.
assert result == 85.0 fails for result = 84.99999999 due to floating point precision. Use abs(result - 85.0) < 0.01. Match the tolerance to the precision your prompt specifies.
Rule 4: Test behavior, not implementation.
Do not check how the agent solved it — check that it works correctly. If the agent replaced a function with a class that has a __call__ method, your test should still pass. Test the public interface specified in the prompt.
Rule 5: Include at least one regression check.
The fix must not break existing behavior. If you only check the reported bug, an agent that deletes the function body and hardcodes return 85.0 passes your primary check. A regression check catches it.
Rule 6: Use the partial credit pattern.
The check() helper above lets multiple assertions run independently and writes a fractional reward.txt. This produces a meaningful training signal — an agent that fixes 3 out of 4 requirements scores 0.75, not 0.
Rule 7: Print diagnostics on every check.
PASS premium 15% discount and FAIL standard 10% regression: expected 90.0, got 80.0 makes test-output.log readable by both you and QA reviewers. Silent pass/fail is useless for debugging.
Rule 8: Write reward.txt yourself when using partial credit.
The test.sh template writes reward.txt based on exit_code (1 or 0). If you want fractional scores, write reward.txt inside verify.py directly and always sys.exit(0) so test.sh does not overwrite it with binary 1/0. Or adapt test.sh to not overwrite it.
Where things go wrong:
Agent writes to wrong path.
Agent puts output in /workspace/result.py instead of /testbed/pricing/calculator.py. Your import fails. Prevention: state the exact expected file path in the prompt.
Test assumes installed packages.
verify.py imports pytest or numpy but neither is in the Dockerfile. Test crashes before running any checks. Prevention: test your Dockerfile and verify.py combination before submitting.
Agent modifies tests/.
Agent edits verify.py or deletes its checks to make them pass. Prevention: add to prompt: “Do not modify any files in the tests/ directory.”
reward.txt not written due to crash.
If verify.py raises an unhandled exception outside the check() wrapper, the script exits before writing reward.txt. Harbor sees no reward file and raises RewardFileNotFoundError. Use the check() pattern to wrap all assertions so exceptions are caught.
Test too tightly coupled to implementation.
You check assert hasattr(module, '_internal_cache') — an internal detail never mentioned in the prompt. The agent’s valid implementation does not use caching and fails. Test only what the prompt specifies.
Fixture file missing.
Your test reads a fixture from /testbed/tests/fixtures/config.json but the agent deleted it while refactoring. Your test fails for the wrong reason. Prevention: put fixtures in tests/ (which agents cannot modify) or in input_artifacts/ (baked into Dockerfile).

7.3 — The Rule Both Types Share
Tests must not be stricter than the prompt.
If verify.py or oracle.json checks something the agent was never told in instruction.md, that is a false failure — and false failures are trainer errors. Before submitting, read both files side by side. For every check, ask:
“Did the prompt tell the agent this?”
If no, add it to the prompt or remove it from the test.

Section 8 — Writing solution/solve.sh
The solution/ folder contains the gold solution — the script that proves your task is solvable and your verifier works. Harbor only runs solve.sh when you use -a oracle. No LLM is called. No kimi. Just your bash script.
If the oracle agent scores 1.0, your task pipeline is valid. If it scores anything else, something is broken in your Dockerfile, tests, or oracle. Fix it before running real agents.

8.1 — For LLM-Judge Tasks
Your gold answer is oracle.json. The oracle agent solves the task by copying it to the agent output path.
solution/solve.sh:
#!/bin/bash
set -euo pipefail
cp /solution/oracle.json /logs/agent/output.json
solution/oracle.json — a copy of the same oracle.json in tests/.
During oracle runs, Harbor uploads solution/ to /solution/ inside the container. solve.sh copies it to /logs/agent/output.json. Then verification runs — judge.py reads /logs/agent/output.json and /tests/oracle.json, finds them identical, and fires the exact match shortcut, which returns reward = 1.0.
Make sure solution/oracle.json and tests/oracle.json are identical. If they differ, the oracle run will produce a score below 1.0 and create confusion during debugging.

8.2 — For Code-Execution Tasks
Your gold solution is the actual fix — the git diff from the PR that resolved the issue.
solution/solve.sh:
#!/bin/bash
set -euo pipefail

cat > /testbed/solution_patch.diff << '__SOLUTION__'
diff --git a/pricing/calculator.py b/pricing/calculator.py
index abc1234..def5678 100644
--- a/pricing/calculator.py
+++ b/pricing/calculator.py
@@ -12,7 +12,7 @@ def calculate_discount(price, account_type):
     if account_type == "standard":
         return price * 0.90
     elif account_type == "premium":
-        return price * 0.80    # bug: 20% discount instead of 15%
+        return price * 0.85    # fix: 15% discount
     return price
__SOLUTION__

cd /testbed
patch --fuzz=5 -p1 -i /testbed/solution_patch.diff
How to get the diff:
On GitHub, open the PR that fixed the issue. Append .diff to the PR URL:
https://github.com/your-org/your-repo/pull/42.diff
Copy the diff content into solve.sh between the __SOLUTION__ markers.
Verify it works:
Build your Docker image, start a container, run solve.sh, then run verify.py. If it passes, your gold solution is valid.

8.3 — Validating Your Pipeline
After all files are ready, run the oracle to validate your entire pipeline end to end.
From inside the harbor/ directory:
export FIREWORKS_API_KEY=your_key

uv run harbor run \
  -p /path/to/your-task \
  -a oracle \
  --ve FIREWORKS_API_KEY=$FIREWORKS_API_KEY \
  --job-name "oracle" \
  --jobs-dir /path/to/your-task/execution_logs \
  --ae FIREWORKS_API_KEY=$FIREWORKS_API_KEY \
  --quiet
Expected result: reward = 1.0.
If you get anything else, read trial_dir/verifier/test-stdout.txt for the error.
Once the oracle passes, run the single agent 1 times to confirm it fails. 
uv run harbor run \
  -p /path/to/your-task \
  -a swarm-kimi-single \
  -m fireworks_ai/accounts/fireworks/models/kimi-k2p5 \
  -k 1 \
  -n 1 \
  --job-name "single-kimi-agent" \
  --jobs-dir /path/to/your-task/execution_logs \
  --ve FIREWORKS_API_KEY=$FIREWORKS_API_KEY \
  --ae FIREWORKS_API_KEY=$FIREWORKS_API_KEY \
  --quiet
This run 1 trial concurrently and saves results inside your task directory at:
execution_logs/single-kimi-agent/
Check the mean reward in the output table. If the single agent scores above 30% consistently, your task is too easy — the context is not large enough, the reasoning is not deep enough, or the decomposition is not necessary. The gap matters a lot here. Scoring above 30 with a single agent isn’t necessarily a bad thing but your chances of having a large enough gap may reduce.

Section 9 — Writing decomposition.yaml
The decomposition guide is the blueprint for multi-agent coordination. It tells the orchestrator how to split the work, what each sub-agent is responsible for, what depends on what, and how results are aggregated. This file is what separates your task from a simple single-agent prompt.
The orchestrator reads this at runtime and uses it to spawn sub-agents. If the decomposition is wrong — too many agents, unclear responsibilities, missing dependencies — the multi-agent run fails even on tasks that are inherently solvable.

9.1 — Structure
sub_tasks:
  - id: unique-short-name
    description: "Exactly what this sub-agent must do, what files to read, what to produce"
    depends_on: []
    parallel_group: map

  - id: another-task
    description: "..."
    depends_on: [unique-short-name]
    parallel_group: reduce
Every sub-task has 4 fields:
id — short, unique, descriptive. Used by depends_on references and by the orchestrator in its logs.
description — the complete briefing for that sub-agent. Remember: sub-agents run in isolated context. They cannot see each other’s output. They cannot see your instruction.md. Everything they need must be in this description.
depends_on — list of sub-task IDs that must complete before this one starts. Empty means it can start immediately.
parallel_group — groups that run at the same time. All sub-tasks in the same parallel group run concurrently.

9.2 — Principles of Good Decomposition
Minimal agents, maximum coverage.
Every sub-agent must be necessary. If you can remove a sub-agent and the task is still solvable at the same quality, remove it. Extra agents waste tokens, increase coordination overhead, and slow the run. Reviewers will flag tasks where the sub-agent count is inflated to hit a difficulty target.
Clear, non-overlapping responsibilities.
Each sub-agent should own a distinct piece of work. If two sub-agents both read the same file for the same purpose, one is redundant. If a sub-agent’s description says “assist with” or “help analyse,” it does not have a clear enough role.
Self-contained descriptions.
Sub-agents see only their description. They do not see the main instruction.md, they do not see other sub-agents’ descriptions, and they do not see the overall task goal. If a sub-agent needs to know the expected output format, the file path, or the analysis criteria, put it in the description.
Correct dependency chains.
If reduce depends on all mappers finishing, list every mapper ID in depends_on. If a synthesizer depends on all thread results, list every thread. Missing a dependency means the synthesizer runs before results are available.
Match the coordination pattern.
Map-reduce: all mappers in one parallel group, reducer depends on all mappers.
Fan-out: all threads in one parallel group, synthesizer depends on all threads.
Do not mix patterns within one decomposition unless the task genuinely requires it.

9.3 — Real Example: Fan-Out / Synthesize
Task: survey 11 AI benchmark papers, extract 6 fields per paper.
sub_tasks:
  - id: research-api-bank
    description: >
      Search the web for 'API-Bank (Li et al., 2023)'. Read the full paper.
      Extract: benchmark_name, num_domains, num_tasks, has_human_task_curation,
      has_refusal_ability, has_human_plans. For each field, provide 1-3
      verbatim quotes as evidence. Return structured JSON.
    depends_on: []
    parallel_group: research

  - id: research-acebench
    description: >
      Search the web for 'ACEBench (Chen et al., 2025)'. Read the full paper.
      Extract the same 6 fields with verbatim quote evidence. Return JSON.
    depends_on: []
    parallel_group: research

  - id: cross-validate
    description: >
      Read each research agent's extracted data. For each paper, verify
      benchmark_name matches the actual paper title. Flag any extraction
      where the verbatim quote does not support the claimed value. Produce
      a validated dataset with confidence flags.
    depends_on: [research-api-bank, research-acebench]
    parallel_group: validate

  - id: synthesize
    description: >
      Merge all validated extractions into a single JSON array of 11 objects.
      Resolve any flagged discrepancies. Produce the final output matching
      the required format and write to /logs/agent/output.json.
    depends_on: [cross-validate]
    parallel_group: synthesize
11 research agents + 1 validator + 1 synthesizer = 13 total. Not 23. Not 5. Each agent has exactly one paper, one job, complete context.

9.4 — Real Example: Map-Reduce
Task: security audit across 3 server logs.
sub_tasks:
  - id: map-server-01
    description: >
      Read /input_artifacts/api-server-01.log entirely. For every log entry,
      extract: client IP, HTTP method, endpoint path, status code, bytes,
      response time. Compute: total requests, requests per status code,
      average response time per endpoint, per-IP total and error counts,
      total bytes. Return all metrics as JSON.
    depends_on: []
    parallel_group: map

  - id: map-server-02
    description: >
      Read /input_artifacts/api-server-02.log entirely. Compute the same
      metrics as map-server-01. Return JSON.
    depends_on: []
    parallel_group: map

  - id: map-server-03
    description: >
      Read /input_artifacts/api-server-03.log entirely. Same metrics. JSON.
    depends_on: []
    parallel_group: map

  - id: reduce-aggregate
    description: >
      Take all 3 mapper outputs. Sum status codes across servers. Compute
      weighted average response times per endpoint. Merge IP stats. Sum bytes.
      Identify top 5 slowest endpoints globally, suspicious IPs (>=5 requests
      AND >50% error rate), overall error rate, global avg response time.
      Write final answer to /logs/agent/output.json.
    depends_on: [map-server-01, map-server-02, map-server-03]
    parallel_group: reduce
3 mappers + 1 reducer = 4 total. Clean, minimal, no redundancy.

9.5 — The Iterative Loop: Build, Test, Debug, Improve
Writing the decomposition is not a one-shot exercise. It is an iterative loop.
Step 1: Write the initial decomposition.
Start with the minimal number of sub-agents. One per independent shard (map-reduce) or one per independent thread (fan-out). One aggregator or synthesizer. Count them. That is your estimated_sub_agents.
Step 2: Run single agent 1 time.
uv run harbor run \
  -p /path/to/your-task \
  -a swarm-kimi-single \
  -m fireworks_ai/accounts/fireworks/models/kimi-k2p5 \
  -k 1 -n 1 \
  --job-name "single-kimi-agent" \
  --jobs-dir /path/to/your-task/execution_logs \
  --ve FIREWORKS_API_KEY=$FIREWORKS_API_KEY \
  --ae FIREWORKS_API_KEY=$FIREWORKS_API_KEY \
  --quiet
Step 3: Run multi agent 1 time.
uv run harbor run \
  -p /path/to/your-task \
  -a swarm-kimi-multi \
  -m fireworks_ai/accounts/fireworks/models/kimi-k2p5 \
  -k 1 -n 1 \
  --job-name "multi-kimi-agent" \
  --jobs-dir /path/to/your-task/execution_logs \
  --ve FIREWORKS_API_KEY=$FIREWORKS_API_KEY \
  --ae FIREWORKS_API_KEY=$FIREWORKS_API_KEY \
  --quiet
Results are saved to execution_logs/multi-kimi-agent/. Check the reward.
Step 4: Evaluate the gap.
Single and Multi with ≥ 23-point value gap → task is valid. Ship it.
Single and Multi with <23 point value gap  → the decomposition needs improvement. Go to Step 5.
Step 5: Debug multi-agent failure.
When multi-agent does not reach 0.7, debug systematically. Do not assume the task is unsolvable.
Read execution_logs/multi-kimi-agent/*/agent/trajectory.json to see what the orchestrator actually did.
Common issues:
Issue: Sub-agent received incomplete context.
The orchestrator spawned a sub-agent but did not pass enough information. The sub-agent could not find the file, did not know the output format, or did not know the analysis criteria.
Fix: make the sub-task descriptions in decomposition.yaml more explicit and self-contained.
Issue: Too many sub-agents.
The orchestrator spawned 15 agents when 5 would suffice. Each agent did minimal work, the coordination overhead dominated, and the synthesizer drowned in noisy partial results.
Fix: reduce estimated_sub_agents and merge related sub-tasks.
Issue: Too few sub-agents.
One sub-agent was assigned 500 cases when it should have been split into 5 agents of 100 each. That sub-agent failed for the same reason the single agent fails — context overload.
Fix: split large sub-tasks further.
Issue: Missing dependency.
The reducer ran before all mappers finished, synthesized incomplete data, and scored low.
Fix: verify depends_on lists every prerequisite.
Issue: False failure from the verifier.
Multi-agent produced the correct answer but judge.py scored it low because of a format mismatch, field name difference, or precision issue. This is not a decomposition problem — it is a verifier problem. Read agent/judge_justification.txt to diagnose.
Fix: correct the prompt output format block or the oracle.
Issue: True incapability.
The multi-agent approach genuinely cannot solve the task — the coordination is too complex, the sub-agents hallucinate despite isolated context, or the synthesis step is itself beyond single-agent capacity. This is rare.
Step 6: Re-run and compare.
After each improvement to the decomposition, re-run both single and multi agent. The gap must be at least 38 points on the reward across a single trial run. A 40-point gap is ideal.

9.6 — What Reviewers Check in Your Decomposition
QA reviewers and annotators evaluate decomposition on these criteria. They do not try to derive a better decomposition — they assess whether yours is sound.
Redundancy.
Can any sub-agent be removed without losing coverage? If yes, the task is flagged for rework.
Coverage.
Does every part of the input get processed? If the task has 3 log files and your decomposition only maps 2, that is a gap.
Clear responsibilities.
Can you read one sub-task description and know exactly what it produces, what it reads, and what format it returns? If a sub-task says “help with analysis,” it is too vague.
Necessary dependencies.
Does every depends_on make logical sense? Does the reducer actually need all mapper outputs, or could it start with partial data? Are there unnecessary sequential bottlenecks?
Estimated sub-agent count matches.
If task.toml says estimated_sub_agents = 13, your decomposition.yaml should also contain 13 sub-tasks. If these do not match, one of them is wrong.

After validation, your task directory contains everything:
your-task/
├── instruction.md
├── task.toml
├── decomposition.yaml
├── environment/
│   ├── Dockerfile
│   └── input_artifacts/
├── tests/
│   ├── test.sh
│   ├── judge.py (or verify.py)
│   └── oracle.json
├── solution/
│   ├── solve.sh
│   └── oracle.json (for llm-judge tasks)
└── execution_logs/
    ├── single-kimi-agent/
    └── multi-kimi-agent/

Section 10 — Task Metadata (task.toml)
Once you have chosen verifier type, coordination pattern, domain, and difficulty, fill in task.toml. The [metadata] section is required for every task.
Every task must have a task.toml file. The [metadata] section defines how the task is classified and used by the benchmark harness.

Full Example
[task]
name = "swarmbench/{task_id}"
description = "One sentence describing what the task requires."

[metadata]
verifier_type = "llm-judge"
domain = "knowledge-research"
coordination_pattern = "fan-out-synthesize"
human_solving_hours_estimate = 14.0
human_solving_hours_justification = "Requires reading all 10 vendor reports (~33K tokens), manually tracking contradictions across 4 domains with strict boundary rules, and producing a structured cross-reference report. A domain expert would need ~2h per domain (8h total) plus ~6h for synthesis and verification."
estimated_sub_agents = 5
input_token_estimate = 33000
why_multi_agent = "Explain why a single agent fails and why multi-agent coordination is necessary."
reference_link = "https://github.com/your-org/issue-or-paper-or-dataset"

[agent]
timeout_sec = 3600

[verifier]
timeout_sec = 600

[environment]
cpus = 2
memory_mb = 4096
build_timeout_sec = 600

Field Definitions
verifier_type — Required
How the agent’s output is evaluated.
Value
When to use
llm-judge
Output is text or JSON graded by an LLM. Used for knowledge, research, and data analysis tasks where there is no single deterministic answer.
executable
Output is verified by running tests (for example: code compiles, tests pass). Used for SWE and coding tasks.


domain — Required
The primary subject area of the task. Pick the closest match.
Value
Description
code-swe
Software engineering, debugging, code generation, repo navigation
knowledge-research
Literature review, fact extraction, scientific reasoning, synthesis
data-analysis
Processing structured or semi-structured data, statistics, aggregation
planning-operations
Multi-step planning, scheduling, resource allocation
reasoning-math
Logical reasoning, mathematical problem solving


coordination_pattern — Required
The multi-agent decomposition strategy this task is designed for.
Value
Description
map-reduce
Split input into shards → parallel processing → aggregate results
fan-out-synthesize
Explore multiple independent threads in parallel → synthesize findings
specialist-routing
Route sub-tasks to domain specialists → merge outputs
pipeline
Sequential stages where each stage feeds the next
hierarchical
Tree of manager agents delegating to specialist sub-agents
debate
Multiple independent agents solve the same problem → consensus


human_solving_hours_estimate — Required
Estimated hours for a human domain expert to solve this task from scratch, without AI assistance.
This is the primary difficulty signal aligned with client requirements:
Hours
Difficulty
10 – 99
Medium
100+
Hard

Rules:
Be conservative — estimate for a knowledgeable human, not a novice
Must be justified by the nature of the task (data volume, reasoning depth, number of sources)
Not automatable by simple scripts or keyword matching
Examples:
Reading and clinically analyzing 1500 medical case files → 120.0 (Hard)
Cross-referencing 10 vendor reports across 4 domains → 14.0 (Medium)
Synthesizing findings from 11 research papers → 32.0 (Medium)

human_solving_hours_justification — Required
A sentence or two explaining how you arrived at human_solving_hours_estimate. Break down the work: reading time + analysis time + synthesis time.
Example:
“Requires reading all 10 vendor reports (~33K tokens), manually tracking contradictions across 4 domains, and producing a structured report. ~2h per domain (8h total) + ~6h for synthesis and verification.”
This field is used by QA reviewers to validate the difficulty rating. Tasks where the justification does not support the hours estimate will be flagged for revision.

reference_link — Required
A URL pointing to the source of the task. This gives reviewers and future trainers context for where the task came from.
For knowledge and research tasks: link to the paper, dataset, or report the task is based on.
For data analysis tasks: link to the data source or a relevant real-world system.
For SWE tasks: link to the GitHub issue or PR the task is derived from.
# Research task
reference_link = "https://arxiv.org/abs/2310.12123"

# SWE task from a real GitHub issue
reference_link = "https://github.com/django/django/issues/12345"

# Data analysis from a public dataset
reference_link = "https://www.kaggle.com/datasets/some-dataset"

estimated_sub_agents — Required
The number of sub-agents the multi-agent solution is expected to spawn. Used to inject ${ESTIMATED_SUB_AGENTS} into the coordination prompt at runtime.
Set this to the number of agents in your gold decomposition.

input_token_estimate — Required
Approximate total tokens in all input artifacts (files the agent must read). Used to verify context pressure — this is why multi-agent is necessary.
Calculate as:
total file sizes in bytes ÷ 4
This is a rough token estimate.

why_multi_agent — Required
A clear, specific explanation of:
Why a single agent fails on this task
What specifically breaks (context overload, attention degradation, confusion, etc.)
How multi-agent decomposition solves it
This must be specific. Do not write generic statements like “it’s too complex for one agent.” Quantify where possible using token counts, number of documents, or number of comparisons.
Good example:
“Three domain databases (~500K tokens total) require clinical reasoning on 1500 cases. Single agent context overflows, causing truncated reads and hallucinated PMCIDs. 15 chunk-reader sub-agents (5 per domain, ~33K tokens each) process within manageable windows, 3 domain synthesizers merge, and 1 final synthesizer diagnoses.”
Bad example:
“This task is too large for a single agent.”

[agent], [verifier], [environment] Defaults
Use these defaults unless your task has specific requirements:
[agent]
timeout_sec = 3600

[verifier]
timeout_sec = 600

[environment]
cpus = 2
memory_mb = 4096
build_timeout_sec = 600

timeout_sec = 3600 under [agent] gives the agent 1 hour to complete the task
timeout_sec = 600 under [verifier] gives the verifier 10 minutes to score the output
IMPORTANT
If your multi-agent run solves the task in X minutes, set the agent timeout to that same value for both runs:

[agent]
timeout_sec = 1800   # e.g. 30 min if multi-agent solved in ~30 min

Then run the single-agent with the same timeout. 
If single-agent fails within that window where multi-agent passes — that's a valid, time-constrained failure and counts as strong evidence of multi-agent necessity.
memory_mb = 4096 gives the environment 4 GB RAM
Increase timeout_sec for very large tasks. Increase memory_mb if the task requires loading large files into memory.
Note: Do not add env under [verifier]. The FIREWORKS_API_KEY is passed at runtime via the --ve flag. Do not hardcode API keys in task.toml.

