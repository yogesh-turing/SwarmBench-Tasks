# Gap Strategy

## Why Single-Agent Should Struggle

- Number of artifacts:
    - ~8–12 files spanning core (lodash.js), multiple test suites, and vendor code (underscore, firebug-lite)
- Estimated input size:
    - ~8k–12k tokens (core library + multiple test files + bug descriptions)
- Coverage pressure:
    - The agent must:
        - Scan entire repo for typo patterns (global search problem)
        - Understand cloning internals (_.clone, _.cloneDeep)
        - Debug numeric HTML entity decoding (_.unescape)
        - Diagnose type coercion issue in _.sumBy
        - Modify vendor/test files without breaking expectations
    - These are orthogonal problem spaces, not a single coherent flow.
- Reconciliation pressure:
    - Fixes interact across layers:
        - Changing clone behavior affects tests and possibly other utilities
        - Fixing unescape impacts string utilities globally
        - Vendor code changes must not introduce regressions
- Expected failure mode:
    - Misses at least 1–2 bug categories (commonly typo sweep or vendor-related bug)
    - Partial fixes (e.g., fixes clone but ignores frozen prototype edge case)
    - Regression introduction (e.g., incorrect sumBy NaN handling)
    - Incomplete repository-wide typo coverage
    - Incorrect fix for numeric HTML entities (common parsing mistake)


## Why Multi-Agent Should Succeed

- Natural subproblems:
    - The task decomposes cleanly into independent domains:
        - Typo normalization (Bug 1) → large-scale text correction
        - Prototype + cloning semantics (Bug 2) → deep JS behavior
        - HTML entity decoding (Bug 3) → parsing logic
        - Aggregation/type handling (Bug 4) → numeric correctness + coercion
- Sub-agent ownership plan:
    - Agent A (Static Sweep Agent): Handles typo detection & correction across repo
    - Agent B (Prototype/Clone Specialist): Fixes _.clone and _.cloneDeep edge case with frozen prototypes
    - Agent C (String Parsing Agent): Fixes _.unescape numeric entity decoding
    - Agent D (Numeric Semantics Agent): Fixes _.sumBy mixed-type behavior
    - Final Synthesizer Agent: Runs tests, resolves conflicts, ensures consistency
- Reducer strategy:
    - Merge patches per file (avoid conflicting edits)
    - Run test suite after integration
    - Validate no regression in:
        - object cloning behavior
        - string escaping/unescaping
        - numeric utilities
    - Ensure vendor/test expectations remain intact
- Why final synthesis is verifiable:
    - Deterministic outputs:
        - Test suite pass/fail
        - Known expected outputs for _.unescape, _.sumBy
    - Bug fixes are locally testable and globally verifiable
    - Clear correctness criteria (no subjective judgment)

## Expected Score Pattern

- Oracle expected score:
    - 1.0 (all 4 bugs fully fixed, no regressions)
- Single-agent expected score:
    - 0.4 – 0.6
- Multi-agent expected score:
    - 0.8 – 1.0
- Target gap:
    - ~0.4+ score gap

## Oracle Validation

- Oracle run completed: Yes
- Oracle reward: 1.0
- Notes:
    - All typo instances corrected without breaking tests
    - _.clone / _.cloneDeep correctly handle frozen prototype collisions
    - _.unescape('&#38;') returns "&" as expected
    - _.sumBy returns NaN for mixed-type arrays instead of string concatenation
    - Full test suite passes with no regressions
