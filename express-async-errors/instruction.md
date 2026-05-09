# Task: Express Security + Reliability + Compatibility Hardening Sweep

## Background

You are a Node.js platform engineer responsible for a comprehensive hardening sweep on an Express 4.x fork used by multiple internal services.

The baseline branch has three critical security and reliability issues:

1. **HTTP Header Injection (CRLF)** — The response and request pipelines lack explicit CRLF validation. Request-side trust boundaries do not sanitize tainted headers. Response-side APIs do not reject header names/values with `\r` or `\n` characters. This enables header injection attacks across cookies, redirects, and custom headers. **This is the primary security concern.**
2. **Async Error Propagation** — Rejected promises from handlers are not consistently forwarded to error middleware. A handler that calls `next(err)` synchronously and also returns a rejected promise can invoke the error handler twice, or the error may be swallowed entirely. This reduces observability and can hide failures in production.
3. **Node.js 22 Compatibility Cleanup** — Legacy APIs and patterns remain in `lib/request.js` (e.g., `this.connection` instead of `this.socket`, `trimRight()` instead of `trimEnd()`). While functionality is preserved, modern Node.js versions deprecate these patterns.

You need to deliver a single coherent patch that addresses all three classes without breaking existing synchronous behavior.

## Scope

Work in the Express source at `/testbed/lib/`.

Primary files:

- `lib/utils.js` — Shared validation utilities
- `lib/response.js` — Response-side header/cookie/redirect validation
- `lib/request.js` — Request-side trust boundary and compatibility cleanup
- `lib/router/layer.js` — Async error propagation in handler execution
- `lib/router/index.js` — Async error propagation in param pipeline

## Requirements

### A) HTTP Header Injection Hardening (Primary — 40% of verifier weight)

1. **Implement a shared CRLF validation utility** in `lib/utils.js`:
   - Detect both literal `\r` and `\n` characters AND escaped sequences `\\r` and `\\n` in strings
   - Export as `containsInvalidHeaderChar(value)` — return `true` if any CRLF is present
   - Handle arrays, strings, numbers, booleans, null, undefined gracefully

2. **Response-side hardening** in `lib/response.js`:
   - Reject CRLF in `res.set()` / `res.header()` for both names and values
   - Reject CRLF in `res.append()` (used for Set-Cookie and multi-value headers)
   - Reject CRLF in `res.cookie()` for cookie names and values
   - Reject CRLF in `res.location()` / `res.redirect()` for the target URL
   - Throw a `TypeError` or similar error for any CRLF-tainted input before reaching the native `setHeader` call. Valid inputs must pass through unchanged.

3. **Request-side hardening** in `lib/request.js`:
   - Sanitize `req.get()` and `req.header()` to return `undefined` for CRLF-tainted header values
   - Sanitize `req.referer` / `req.referrer` property to return `undefined` for CRLF-tainted values
   - **Critical trust boundary:** When computing `req.hostname`, reject any CRLF in the trusted `X-Forwarded-Host` header
   - Do not fall through to the `Host` header if `X-Forwarded-Host` contains CRLF — return `undefined`

### B) Async Error Handling (Secondary — 35% of verifier weight)

4. Async route/middleware errors must propagate to Express error handlers.
5. If a handler calls `next(err)` synchronously and the returned promise later rejects, error handling must run once only (called-once guard).
6. `next('route')` / `next('router')` behavior must remain correct.
7. Async `app.param()` handlers in `router/index.js` must be handled (they bypass `layer.handle_request`).

### C) Node.js 22 Compatibility Cleanup (Tertiary — 15% of verifier weight)

8. Replace deprecated/legacy request internals in `lib/request.js`:
   - use `this.socket` instead of `this.connection`
   - replace `trimRight()` with `trimEnd()`
9. Preserve behavior while removing those legacy usages.

### General Constraints

10. Keep synchronous behavior unchanged where not explicitly part of this task.
11. Do not add new dependencies.
12. Modify only files under `lib/`.
13. All CRLF validation must use the shared utility from `lib/utils.js` — consistency is required for correctness.

## Deliverable

A patch that satisfies all verifier checks for CRLF injection prevention (primary), async error propagation (secondary), and Node 22 compatibility (tertiary).

## Acceptance Criteria

- Verifier passes all 43 tests (32 runtime + 11 static checks).
- CRLF validation is implemented via shared utility exported from `lib/utils.js`.
- Both request and response paths use the same utility consistently.
- No legacy `this.connection` / `trimRight()` usage remains in `lib/request.js`.
- All CRLF entry points (res.set, res.append, res.cookie, res.location, req.get, req.header, req.referer, req.hostname) are hardened.
- Async error propagation works correctly for nested routers, array handlers, param callbacks, and mixed sync/async middleware.
