#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PYEOF'
import re
import sys


def patch(filepath, description, fn):
    with open(filepath, 'r', encoding='utf-8') as f:
        src = f.read()
    result = fn(src)
    if result is None:
        print(f"WARNING: {description} (no change)", file=sys.stderr)
        return
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(result)
    print(f"OK: {description}")


# 1) fastify.js exposeHeadRoutes default false -> true
def fix_expose_head(src):
    old = "options.exposeHeadRoutes != null ? options.exposeHeadRoutes : false"
    new = "options.exposeHeadRoutes != null ? options.exposeHeadRoutes : true"
    if old not in src:
        return None
    return src.replace(old, new, 1)


# 2) errors.js add FST_ERR_SCH_BODY_GET_HEAD
def fix_errors(src):
    if "FST_ERR_SCH_BODY_GET_HEAD" in src:
        return src
    anchor = "  FST_ERR_SCH_SERIALIZATION_BUILD: createError("
    idx = src.find(anchor)
    if idx == -1:
        return None
    insert = (
        "  FST_ERR_SCH_BODY_GET_HEAD: createError(\n"
        "    'FST_ERR_SCH_BODY_GET_HEAD',\n"
        "    'Body validation schema for %s method is not allowed!',\n"
        "    400\n"
        "  ),\n\n"
    )
    return src[:idx] + insert + src[idx:]


# 3) route.js import + body-schema check

def fix_route(src):
    out = src

    # import list
    import_pat = re.compile(
        r"const \{(?P<body>[\s\S]*?)\} = require\('\./errors'\)",
        re.MULTILINE,
    )
    m = import_pat.search(out)
    if not m:
        return None
    body = m.group('body')
    if "FST_ERR_SCH_BODY_GET_HEAD" not in body:
        body2 = body.replace(
            "  FST_ERR_SCH_SERIALIZATION_BUILD,",
            "  FST_ERR_SCH_SERIALIZATION_BUILD,\n  FST_ERR_SCH_BODY_GET_HEAD,",
            1,
        )
        out = out[:m.start('body')] + body2 + out[m.end('body'):]

    if "throw new FST_ERR_SCH_BODY_GET_HEAD(opts.method)" not in out:
        schema_anchor = "if (opts.schema) {"
        pos = out.find(schema_anchor)
        if pos == -1:
            return None
        insert_pos = pos + len(schema_anchor)
        check = (
            "\n          if (opts.schema.body && (opts.method === 'GET' || opts.method === 'HEAD')) {\n"
            "            throw new FST_ERR_SCH_BODY_GET_HEAD(opts.method)\n"
            "          }\n"
        )
        out = out[:insert_pos] + check + out[insert_pos:]

    return out


# 4) reply.js sent setter always throws

def fix_reply(src):
    lines = src.split('\n')
    setter_start = None
    for i, line in enumerate(lines):
        if re.search(r"^\s*set \(value\) \{", line):
            # ensure this belongs to sent property area
            window = "\n".join(lines[max(0, i - 8): i + 1])
            if "sent:" in window or "return this[kReplySent]" in window:
                setter_start = i
                break
    if setter_start is None:
        return None

    depth = 0
    setter_end = None
    for i in range(setter_start, len(lines)):
        depth += lines[i].count('{') - lines[i].count('}')
        if depth == 0:
            setter_end = i
            break
    if setter_end is None:
        return None

    indent = re.match(r"^(\s*)", lines[setter_start]).group(1)
    replacement = [
        f"{indent}set (value) {{",
        f"{indent}  throw new FST_ERR_REP_SENT_VALUE()",
        f"{indent}}}",
    ]
    lines = lines[:setter_start] + replacement + lines[setter_end + 1:]
    return "\n".join(lines)


# 5) wrapThenable rewrite
NEW_WRAP = """'use strict'

const {
  kReplyIsError,
  kReplySent
} = require('./symbols')

function wrapThenable (thenable, reply) {
  thenable.then(function (payload) {
    if (reply[kReplySent] === true) {
      return
    }

    try {
      reply.send(payload)
    } catch (err) {
      reply[kReplySent] = false
      reply[kReplyIsError] = true
      reply.send(err)
    }
  }, function (err) {
    if (reply[kReplySent] === true) {
      return
    }

    reply[kReplySent] = false
    if (!(err instanceof Error)) {
      err = new Error(String(err))
    }
    reply[kReplyIsError] = true
    reply.send(err)
  })
}

module.exports = wrapThenable
"""


# 6) handleRequest.js catch wraps non-Error

def fix_handle_request(src):
    marker = "reply.context.handler(request, reply)"
    m = src.find(marker)
    if m == -1:
        return None
    catch_pos = src.find("} catch (err) {", m)
    if catch_pos == -1:
        return None
    block_end = src.find("\n  }", catch_pos)
    if block_end == -1:
        return None

    old_block = src[catch_pos:block_end + 4]
    if "new Error(String(err))" in old_block:
        return src

    new_block = (
        "} catch (err) {\n"
        "    if (!(err instanceof Error)) {\n"
        "      err = new Error(String(err))\n"
        "    }\n"
        "    reply[kReplyIsError] = true\n"
        "    reply.send(err)\n"
        "    return\n"
        "  }"
    )
    return src[:catch_pos] + new_block + src[block_end + 4:]


# 7) hooks.js wrap non-Error in next and handleReject

def fix_hooks(src):
    out = src

    next_pat = re.compile(
        r"if \(err \|\| i === functions.length\) \{\n(\s*)cb\(err,\s*request,\s*reply\)",
        re.MULTILINE,
    )
    m = next_pat.search(out)
    if m and "err && !(err instanceof Error)" not in out[m.start(): m.end() + 200]:
        ind = m.group(1)
        repl = (
            "if (err || i === functions.length) {\n"
            f"{ind}if (err && !(err instanceof Error)) {{\n"
            f"{ind}  err = new Error(String(err))\n"
            f"{ind}}}\n"
            f"{ind}cb(err, request, reply)"
        )
        out = out[:m.start()] + repl + out[m.end():]

    reject_pat = re.compile(
        r"else if \(!\(err instanceof Error\)\) \{\n(\s*)reply\[kReplyIsError\] = true",
        re.MULTILINE,
    )
    m2 = reject_pat.search(out)
    if m2 and "new Error(String(err))" not in out[m2.start(): m2.end() + 120]:
        ind = m2.group(1)
        repl2 = (
            "else if (!(err instanceof Error)) {\n"
            f"{ind}err = new Error(String(err))\n"
            f"{ind}reply[kReplyIsError] = true"
        )
        out = out[:m2.start()] + repl2 + out[m2.end():]

    return out


patch('/testbed/fastify.js', 'fastify.js exposeHeadRoutes', fix_expose_head)
patch('/testbed/lib/errors.js', 'errors.js add FST_ERR_SCH_BODY_GET_HEAD', fix_errors)
patch('/testbed/lib/route.js', 'route.js add GET/HEAD schema.body guard', fix_route)
patch('/testbed/lib/reply.js', 'reply.js make sent setter throw', fix_reply)

with open('/testbed/lib/wrapThenable.js', 'w', encoding='utf-8') as f:
    f.write(NEW_WRAP)
print('OK: wrapThenable.js rewritten')

patch('/testbed/lib/handleRequest.js', 'handleRequest.js wrap non-Error throws', fix_handle_request)
patch('/testbed/lib/hooks.js', 'hooks.js wrap non-Error hook errors', fix_hooks)

print('Oracle patching complete.')
PYEOF
