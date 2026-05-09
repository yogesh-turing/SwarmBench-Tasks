PR Choosing Workflow for SwarmBench Code/SWE Tasks
Objective
Create a repeatable workflow for selecting GitHub PRs and converting them into strong SwarmBench Code/SWE executable tasks.
The goal is to choose PRs where:
* single-agent is likely to struggle
* multi-agent has a real advantage
* the task passes reviewer expectations for complexity and decomposition
________________


Recommended Approach
Use a hybrid process:
1. search for candidate PRs using LLMs
2. manually review and shortlist them
3. build a task from the best candidate
4. validate with oracle, single-agent, and multi-agent runs
5. move on quickly if the PR does not produce a good score pattern
This is not purely direct selection and not purely trial-and-error. It is shortlist → review → validate.
________________


________________
Step 1: Search for Candidate PRs
Use LLMs to search for PRs with strict constraints.
Minimum filters
A candidate PR should be:
* merged / closed
* real SWE/code work
* at least 20 files changed
* not mostly docs, screenshots, fixtures, or UI polish
* broad enough to support real multi-agent decomposition
* spread across interacting subsystems, not just 1–2 isolated files
Good technical patterns
Prefer PRs involving:
* ORM / query / compiler / schema
* backend-specific behavior
* migrations / serialization
* concurrency / locking / state consistency
* cross-module refactors
* algorithmic rewrites with regression impact
Avoid
Avoid PRs that are:
* open
* too small
* mostly repetitive file edits
* mainly template/docs/fixture churn
* broad in file count but shallow in technical depth
________________


________________
Step 2: Use a Strong Search Prompt
Recommended prompt:
I need you to search for a GitHub PR that is suitable for building a SwarmBench Code/SWE executable task.
Hard requirements:
* merged / closed
* real SWE/code task
* at least 20 files changed
* plausibly multi-agent-worthy
* broad enough for multiple meaningful sub-problems
* not already suggested earlier
Prefer PRs touching interacting subsystems such as ORM/query/compiler/schema, backend-specific behavior, migrations/serialization, concurrency/locking/state consistency, or large cross-module refactors.
Exclude open PRs, small PRs, and PRs that are mostly docs/templates/screenshots.
Return ranked candidates with: repo, PR number, title, link, merged status, approximate files changed, why it is multi-agent-worthy, why a single agent might struggle, best decomposition pattern, and any caveats.
Best practice
* run this on multiple models if possible
* compare overlap in responses
* build a shortlist from the strongest repeated candidates
________________


________________
Step 3: Manually Review the Shortlist
Do not trust the PR list blindly. Manually inspect each candidate.
Review checklist
For each PR, check:
* how many files changed
* how many are real code files
* whether the change spans multiple subsystems
* whether the logic is interdependent
* whether a single agent could probably solve it easily
* whether decomposition would be real coordination, not just parallel file editing
Core question
Ask:
Does this PR require synthesis across multiple technical threads, or can one agent solve it comfortably in one pass?
If it looks like “one file per agent,” reject it.
________________


________________
Step 4: Decide the Task Shape Early
Before writing task files, decide:
* is this definitely a code-swe executable task?
* does it fit fan-out-synthesize or map-reduce?
* what exactly should the verifier test?
* why should single-agent fail?
* why should multi-agent succeed?
Pattern selection
Use fan-out-synthesize when:
* the PR has multiple distinct technical threads
* each thread needs focused work
* the final result requires integration
Use map-reduce when:
* the PR has many similar units of work
* each unit can be handled in the same way
* correctness depends on aggregation
For most strong SWE PRs, fan-out-synthesize is usually the better fit.
________________


________________
Step 5: Build Fast, Validate Early
Once a PR is selected:
1. create the task structure
2. build the environment
3. write the verifier
4. write the gold solution
5. write the decomposition
6. run oracle immediately
Do not over-invest before validating.
Validation order
1. oracle
2. single-agent
3. multi-agent
________________


________________
Step 6: Judge the PR by Results
A PR may look good on paper and still fail as a SwarmBench task.
Good outcome
* oracle passes
* single-agent performs poorly
* multi-agent performs clearly better
Bad outcomes
* both single and multi fail
* both single and multi pass
* single passes and multi fails
* multi-agent advantage is too small
If the score pattern is weak, switch PRs instead of forcing a bad one.
________________


________________
Common Blockers
1. Large PR, weak task
Some PRs have 20+ files but are still easy for one agent.
2. Artificial decomposition
If the split is just “agent A handles file 1, agent B handles file 2,” reviewers may reject it.
3. Too much time spent rescuing a weak PR
Sometimes the fastest move is to abandon the PR and choose a better one.
4. Misleading file count
A PR may look big because of docs, fixtures, or generated outputs rather than real code complexity.
5. Weak multi-agent story
If the only argument is “different domains” or “context switching,” that is usually not enough.
________________


Lessons Learned
* LLMs are useful for discovery, not final judgment.
* Repeated PR suggestions across models can help identify stronger candidates.
* File count alone is not enough.
* The best PRs have multiple interacting technical threads.
* Multi-agent suitability must be genuine, not forced.
* Early oracle/single/multi runs are the best filter.
* If a PR keeps producing weak task results, move on.
________________


________________
Team Standard for PR Selection
Before investing in task creation, a PR should pass this screen:
* merged / closed
* 20+ files changed
* code-heavy
* multiple interacting subsystems
* believable multi-agent decomposition
* believable reason single-agent may miss cross-cutting interactions
* not obviously easy for one agent
If it fails this screen, reject it early.
________________


Final Recommendation
Use this workflow:
1. search broadly with strict prompts
2. manually shortlist the best PRs
3. choose only PRs with real cross-subsystem complexity
4. validate fast with oracle/single/multi
5. drop weak PRs early
6. prioritize technically deep PRs over superficially large ones
________________


Short Summary
Best workflow:
 LLM search → manual shortlist → task build → oracle/single/multi validation → keep or discard.
Best PRs:
 Merged, 20+ files, code-heavy, cross-subsystem, genuinely multi-agent-worthy.
Main mistake to avoid:
 Choosing PRs that are large in file count but shallow in real technical coordination.
________________


________________


Prompt Idea




I need you to search for a GitHub PR that is suitable for building a SwarmBench Code/SWE executable task.


You must follow these constraints strictly.


## Hard requirements


Find a PR that is:


1. Merged / closed
2. A real SWE/code task, not docs-only and not mostly UI polish
3. At least 20 files changed
4. Complex enough that it is plausibly multi-agent-worthy
5. Broad enough that the work can be split into multiple meaningful sub-problems, not just "one file per agent"
6. Based on a repo where the change touches multiple interacting subsystems, such as:
   - ORM / query / compiler / schema
   - backend-specific behavior
   - migrations / serialization
   - concurrency / locking / state consistency
   - large cross-module refactors
   - algorithmic rewrites with regressions across outputs/tests
7. Not any PR already suggested earlier in this conversation


## What I mean by "multi-agent-worthy"


Do not just optimize for file count.


I only want PRs where a multi-agent decomposition would be believable, for example:
- one agent handles core semantics
- one handles backend-specific behavior
- one handles validation / checks / migration / serialization
- one handles tests / integration / regressions
- one synthesizer reconciles everything


Bad candidates:
- mostly docs
- mostly screenshots / snapshots / generated fixtures
- mostly repetitive template edits
- broad but shallow compatibility bumps
- "two files, two independent fixes"


Good candidates:
- many interacting invariants
- multiple subsystems
- integration risk if solved partially
- single agent could realistically miss cross-cutting interactions


## Search instructions


Search deeply across any ecosystem:
- Python
- Rails / Ruby
- JavaScript / TypeScript
- Go
- Java
- infrastructure / orchestration
- database / ORM / framework repos


You may use older PRs too, including 2023 or 2024.


## Output format


Return exactly 3 candidate PRs ranked best to worst.


For each candidate, provide:


1. Repo and PR number
2. PR title
3. Link
4. Merged or closed status
5. Approximate number of files changed
6. Why it is multi-agent-worthy
7. Why a single agent might struggle
8. What decomposition pattern fits best
   - fan-out-synthesize
   - map-reduce
9. Any caveat
   - e.g. too UI-heavy, too many fixtures, too much docs, maybe too easy, etc.


## Important filtering rules


- Exclude any PR that is still open
- Exclude PRs under 20 files changed
- Exclude PRs that are mainly docs/templates/screenshots unless there is real code complexity
- Exclude PRs already suggested earlier in this chat
- Be skeptical: do not recommend something just because it is large
- Prefer technically deep, cross-cutting changes over superficial breadth


## Final ranking requirement


After listing the 3 candidates, add:


### Best overall pick
Choose the single best PR and explain why it is the strongest SwarmBench candidate.


### Best backup pick
Choose one safer alternative in case the best overall pick is too hard operationally.


Do not give me vague suggestions. I want specific verified PRs only.


