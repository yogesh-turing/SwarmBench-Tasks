# body-parser: multipart, generic parser, charset hardening, and parser consistency migration
- invalid charsets must fail consistently
- unsupported JSON encodings must fail cleanly
- charset handling must follow RFC-compatible behavior
- all parser types must share consistent normalization semantics

## 4. Secure JSON parsing

Protect JSON parsing against prototype poisoning.

Requirements:
- dangerous prototype mutation payloads must be rejected or neutralized
- protection must apply recursively
- protection must not break valid JSON parsing behavior
- existing parser behavior and error semantics must remain stable

## 5. Request lifecycle consistency

Ensure all parsers behave consistently regarding:
- consumed streams
- verification callbacks
- request body assignment
- middleware ordering
- empty body handling
- invalid encoding handling
- limit enforcement

Parsers must not introduce inconsistent request mutation behavior.

## 6. Error handling consistency

All parsers must:
- preserve stack traces correctly
- expose meaningful parser errors
- preserve status code behavior
- preserve existing middleware compatibility

## 7. Performance and memory behavior

The urlencoded parser parameter counting logic must avoid unnecessary allocation behavior.

The implementation should:
- avoid full-array allocation for large parameter sets
- terminate early when limits are exceeded
- preserve compatibility with existing parsing behavior

## Constraints

- Maintain backward compatibility where possible.
- Do not introduce new external parsing dependencies.
- Preserve existing parser architecture patterns.
- Preserve existing middleware invocation semantics.
- Maintain compatibility with the existing test suite.

## Important Behavioral Guarantees

The verifier checks:
- multipart parsing behavior
- malformed multipart handling
- duplicate multipart field accumulation
- charset normalization consistency
- parser interoperability
- consumed stream handling
- secure JSON parsing behavior
- verification callback execution
- request lifecycle consistency
- parser export correctness
- integration test behavior
- middleware compatibility
- performance-sensitive parameter counting behavior

A partial implementation that only patches isolated files without preserving cross-parser consistency will not pass.