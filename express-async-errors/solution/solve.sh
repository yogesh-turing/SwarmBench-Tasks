#!/bin/bash
set -euo pipefail

cd /testbed

# Gold solution includes:
# A) Async error propagation hardening (layer.js + router/index.js)
# B) CRLF header injection hardening (utils.js + response.js + request.js)
# C) Node 22 compatibility cleanup (request.js)

python3 - << 'EOF'
def replace_once(src, old, new, label):
    if old not in src:
        raise RuntimeError('Patch target not found: ' + label)
    return src.replace(old, new, 1)

# ── Patch lib/router/layer.js ────────────────────────────────────────────────
with open('/testbed/lib/router/layer.js', 'r') as f:
    src = f.read()

# Patch handle_error: called-once guard + promise detection
src = replace_once(
    src,
    '  try {\n    fn(error, req, res, next);\n  } catch (err) {',
    '  var _called = false;\n'
    '  var _next = next;\n'
    '  next = function() { _called = true; return _next.apply(this, arguments); };\n'
    '  try {\n'
    '    var ret = fn(error, req, res, next);\n'
    '    if (ret && typeof ret.then === \'function\') {\n'
    '      ret.then(undefined, function(err) { if (!_called) _next(err); });\n'
    '    }\n'
    '  } catch (err) {',
    'layer.handle_error'
)

# Patch handle_request: called-once guard + promise detection
src = replace_once(
    src,
    '  try {\n    fn(req, res, next);\n  } catch (err) {',
    '  var _called = false;\n'
    '  var _next = next;\n'
    '  next = function() { _called = true; return _next.apply(this, arguments); };\n'
    '  try {\n'
    '    var ret = fn(req, res, next);\n'
    '    if (ret && typeof ret.then === \'function\') {\n'
    '      ret.then(undefined, function(err) { if (!_called) _next(err); });\n'
    '    }\n'
    '  } catch (err) {',
    'layer.handle_request'
)

with open('/testbed/lib/router/layer.js', 'w') as f:
    f.write(src)

print('Patched lib/router/layer.js successfully')

# ── Patch lib/router/index.js ────────────────────────────────────────────────
with open('/testbed/lib/router/index.js', 'r') as f:
    src = f.read()

# Patch paramCallback() in proto.process_params: async app.param() handlers
# are called directly here, bypassing layer.handle_request.
src = replace_once(
    src,
    '    try {\n      fn(req, res, paramCallback, paramVal, key.name);\n    } catch (e) {\n      paramCallback(e);\n    }',
    '    var _cbCalled = false;\n'
    '    var _origCb = paramCallback;\n'
    '    var _safeCb = function() { _cbCalled = true; return _origCb.apply(this, arguments); };\n'
    '    try {\n'
    '      var ret = fn(req, res, _safeCb, paramVal, key.name);\n'
    '      if (ret && typeof ret.then === \'function\') {\n'
    '        ret.then(undefined, function(e) { if (!_cbCalled) _origCb(e); });\n'
    '      }\n'
    '    } catch (e) {\n'
    '      _origCb(e);\n'
    '    }',
    'router.index process_params paramCallback'
)

with open('/testbed/lib/router/index.js', 'w') as f:
    f.write(src)

print('Patched lib/router/index.js successfully')

# ── Patch lib/utils.js (shared CRLF helper) ──────────────────────────────────
with open('/testbed/lib/utils.js', 'r') as f:
    src = f.read()

src = replace_once(
    src,
    "var querystring = require('querystring');\n",
    "var querystring = require('querystring');\n"
    "var INVALID_HEADER_CHAR_REGEXP = /[\\r\\n]|\\\\r|\\\\n/;\n",
    'utils invalid header regex'
)

src = replace_once(
    src,
    "exports.wetag = createETagGenerator({ weak: true })\n",
    "exports.wetag = createETagGenerator({ weak: true })\n\n"
    "/**\n"
    " * Check for CRLF characters in header names/values.\n"
    " *\n"
    " * @param {string|string[]|number|boolean|null|undefined} value\n"
    " * @return {boolean}\n"
    " * @private\n"
    " */\n"
    "exports.containsInvalidHeaderChar = function containsInvalidHeaderChar(value) {\n"
    "  if (value == null) return false;\n"
    "  if (Array.isArray(value)) {\n"
    "    for (var i = 0; i < value.length; i++) {\n"
    "      if (exports.containsInvalidHeaderChar(value[i])) return true;\n"
    "    }\n"
    "    return false;\n"
    "  }\n"
    "\n"
    "  return INVALID_HEADER_CHAR_REGEXP.test(String(value));\n"
    "}\n",
    'utils containsInvalidHeaderChar export'
)

with open('/testbed/lib/utils.js', 'w') as f:
    f.write(src)

print('Patched lib/utils.js successfully')

# ── Patch lib/response.js (CRLF validation) ─────────────────────────────────
with open('/testbed/lib/response.js', 'r') as f:
    src = f.read()

src = replace_once(
    src,
    "var setCharset = require('./utils').setCharset;\n",
    "var setCharset = require('./utils').setCharset;\n"
    "var containsInvalidHeaderChar = require('./utils').containsInvalidHeaderChar;\n",
    'response import containsInvalidHeaderChar'
)

src = replace_once(
    src,
    "    this.setHeader(field, value);",
    "    if (containsInvalidHeaderChar(field) || containsInvalidHeaderChar(value)) {\n"
    "      throw new TypeError('Invalid header value contains CRLF characters');\n"
    "    }\n"
    "\n"
    "    this.setHeader(field, value);",
    'response header validation'
)

src = replace_once(
    src,
    "  if (opts.path == null) {\n    opts.path = '/';\n  }\n\n  this.append('Set-Cookie', cookie.serialize(name, String(val), opts));",
    "  if (opts.path == null) {\n    opts.path = '/';\n  }\n\n  if (containsInvalidHeaderChar(name) || containsInvalidHeaderChar(val)) {\n    throw new TypeError('Invalid cookie name or value contains CRLF characters');\n  }\n\n  this.append('Set-Cookie', cookie.serialize(name, String(val), opts));",
    'response cookie validation'
)

src = replace_once(
    src,
    "  var m = schemaAndHostRegExp.exec(loc);",
    "  if (containsInvalidHeaderChar(loc)) {\n    throw new TypeError('Invalid redirect URL contains CRLF characters');\n  }\n\n  var m = schemaAndHostRegExp.exec(loc);",
    'response location validation'
)

with open('/testbed/lib/response.js', 'w') as f:
    f.write(src)

print('Patched lib/response.js successfully')

# ── Patch lib/request.js (CRLF + Node22 compatibility) ──────────────────────
with open('/testbed/lib/request.js', 'r') as f:
    src = f.read()

src = replace_once(
    src,
    "var proxyaddr = require('proxy-addr');\n",
    "var proxyaddr = require('proxy-addr');\n"
    "var containsInvalidHeaderChar = require('./utils').containsInvalidHeaderChar;\n",
    'request import containsInvalidHeaderChar'
)

src = replace_once(
    src,
    "  switch (lc) {\n    case 'referer':\n    case 'referrer':\n      return this.headers.referrer\n        || this.headers.referer;\n    default:\n      return this.headers[lc];\n  }",
    "  switch (lc) {\n    case 'referer':\n    case 'referrer':\n      var ref = this.headers.referrer\n        || this.headers.referer;\n      return containsInvalidHeaderChar(ref) ? undefined : ref;\n    default:\n      var value = this.headers[lc];\n      return containsInvalidHeaderChar(value) ? undefined : value;\n  }",
    'request.get CRLF sanitization'
)

src = replace_once(
    src,
    "  var proto = this.connection.encrypted\n    ? 'https'\n    : 'http';",
    "  var proto = this.socket.encrypted\n    ? 'https'\n    : 'http';",
    'request protocol socket.encrypted'
)

src = replace_once(
    src,
    "  if (!trust(this.connection.remoteAddress, 0)) {",
    "  if (!trust(this.socket.remoteAddress, 0)) {",
    'request protocol socket.remoteAddress'
)

src = replace_once(
    src,
    "  if (!host || !trust(this.connection.remoteAddress, 0)) {",
    "  if (!host || !trust(this.socket.remoteAddress, 0)) {",
    'request hostname socket.remoteAddress'
)

src = replace_once(
    src,
    "  var host = this.get('X-Forwarded-Host');\n\n  if (!host || !trust(this.socket.remoteAddress, 0)) {",
    "  var host = this.get('X-Forwarded-Host');\n  var trusted = trust(this.socket.remoteAddress, 0);\n\n  if (trusted && containsInvalidHeaderChar(this.headers['x-forwarded-host'])) {\n    return;\n  }\n\n  if (!host || !trusted) {",
    'request hostname trusted tainted x-forwarded-host guard'
)

src = replace_once(
    src,
    "  } else if (host.indexOf(',') !== -1) {\n    // Note: X-Forwarded-Host is normally only ever a\n    //       single value, but this is to be safe.\n    host = host.substring(0, host.indexOf(',')).trimRight()\n  }\n\n  if (!host) return;",
    "  } else if (host.indexOf(',') !== -1) {\n    // Note: X-Forwarded-Host is normally only ever a\n    //       single value, but this is to be safe.\n    host = host.substring(0, host.indexOf(',')).trimEnd()\n  }\n\n  if (!host || containsInvalidHeaderChar(host)) return;",
    'request hostname trimEnd and CRLF hardening'
)

with open('/testbed/lib/request.js', 'w') as f:
    f.write(src)

print('Patched lib/request.js successfully')
EOF
