# Migrate Fastify v3 to v4: Breaking Changes

You are working with the **Fastify v3.29.5** source code located at `/testbed`. Your task is to implement **six breaking changes** that were introduced in Fastify v4.

## Background

Fastify v4 introduced several significant breaking changes to improve correctness, predictability, and API consistency. You must migrate the source code to implement these changes. The code base lives in `/testbed` and uses `npm install`-installed dependencies.

---

## Required Changes

### Change 1: `exposeHeadRoutes` defaults to `true`

**File:** `fastify.js`

In v3, registering a `GET` route did *not* automatically create a corresponding `HEAD` route (default was `false`). In v4, the default changes to `true`.

Find the line that assigns the `exposeHeadRoutes` option with a fallback default of `false` and change the fallback to `true`.

**Reference:** [PR #2826](https://github.com/fastify/fastify/pull/2826)

---

### Change 2: Body validation schema on GET/HEAD routes is forbidden

**Files:** `lib/errors.js`, `lib/route.js`

In v4, registering a route with `schema.body` on a `GET` or `HEAD` method throws an error immediately (at route registration time), because GET/HEAD requests cannot have a body.

**In `lib/errors.js`:** Add a new error before `FST_ERR_SCH_SERIALIZATION_BUILD`:
```js
FST_ERR_SCH_BODY_GET_HEAD: createError(
  'FST_ERR_SCH_BODY_GET_HEAD',
  'Body validation schema for %s method is not allowed!',
  400
),
```

**In `lib/route.js`:**
1. Import `FST_ERR_SCH_BODY_GET_HEAD` from `./errors`
2. Inside the schema handling block (after `if (opts.schema) {`), add a check:
   ```js
   if (opts.schema.body && (opts.method === 'GET' || opts.method === 'HEAD')) {
     throw new FST_ERR_SCH_BODY_GET_HEAD(opts.method)
   }
   ```

**Reference:** [PR #3274](https://github.com/fastify/fastify/pull/3274)

---

### Change 3: `reply.sent` setter always throws

**File:** `lib/reply.js`

In v3, you could set `reply.sent = true` to manually mark a reply as sent (a common pattern used with `reply.hijack()`). In v4, the setter unconditionally throws `FST_ERR_REP_SENT_VALUE` for any assignment. Use `reply.hijack()` instead.

Replace the `set (value) { ... }` block of the `sent` property to simply:
```js
set (value) {
  throw new FST_ERR_REP_SENT_VALUE()
}
```

**Reference:** [PR #3140](https://github.com/fastify/fastify/pull/3140)

---

### Change 4: Async handlers returning `undefined` send an empty 200 response

**File:** `lib/wrapThenable.js`

In v3, if an async handler returned `undefined` (i.e., did not return anything and did not call `reply.send()`), Fastify logged an error and never sent a response. In v4, returning `undefined` is treated as a valid response and Fastify sends an empty 200 (or whatever status was previously set on the reply).

Rewrite `lib/wrapThenable.js` to:
1. Use `kReplySent` (not `kReplySentOverwritten`) to check if reply is already sent
2. Call `reply.send(payload)` for all resolved values — including `undefined`
3. Wrap non-Error rejections: `if (!(err instanceof Error)) { err = new Error(String(err)) }`

**Reference:** [PR #2702](https://github.com/fastify/fastify/pull/2702)

---

### Change 5: All thrown values in handlers are treated as errors

**File:** `lib/handleRequest.js`

In v3, if a sync handler threw a non-Error value (e.g., a string or number), Fastify would send it as a plain-text response body, not as a JSON error. In v4, any thrown value is wrapped in an `Error`:

In the `} catch (err) {` block inside `preHandlerCallback` (where `reply.context.handler` is called), change:
```js
// v3
if (!(err instanceof Error)) {
  reply[kReplyIsError] = true
}
reply.send(err)
```
to:
```js
// v4
if (!(err instanceof Error)) {
  err = new Error(String(err))
}
reply[kReplyIsError] = true
reply.send(err)
```

**Reference:** [PR #3200](https://github.com/fastify/fastify/pull/3200)

---

### Change 6: All thrown values in hooks are treated as errors

**File:** `lib/hooks.js`

Same principle as Change 5, but applied to hook execution. In the `hookRunner` function:

**In `next(err):`** Before calling `cb(err, request, reply)`, add:
```js
if (err && !(err instanceof Error)) {
  err = new Error(String(err))
}
```

**In `handleReject(err):`** In the `else if (!(err instanceof Error))` branch, add:
```js
err = new Error(String(err))
```
before `reply[kReplyIsError] = true`.

---

## Verification

After making your changes, run the test suite to verify:
```bash
node /testbed/tests/run_tests.js
```

A perfect score requires all 30 tests to pass (6 groups × 5 tests).
