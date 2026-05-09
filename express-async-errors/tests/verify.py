#!/usr/bin/env python3
"""
Verify: Express 4.x async error propagation fix.

Each test creates a minimal Express app, starts an HTTP server on a random port,
makes a request using Node's built-in http module, and checks the response.
No external test-runner dependencies required.

This verifier now checks three areas:
  A) Async error propagation correctness
  B) CRLF header injection hardening
  C) Node.js 22 compatibility cleanup
"""

import os
import subprocess
import re

LOG_DIR = "/logs/verifier"
os.makedirs(LOG_DIR, exist_ok=True)

# ---------------------------------------------------------------------------
# Inline Node.js test script — runs against /testbed (Express 4.x install)
# ---------------------------------------------------------------------------
NODE_TEST = r"""
'use strict';

var express = require('/testbed');
var http = require('http');

var passed = 0;
var failed = 0;
var results = [];
var TOTAL_NODE_TESTS = 32;

function makeRequest(app, path, cb) {
  var server = http.createServer(app);
  server.listen(0, function () {
    var port = server.address().port;
    var req = http.get('http://localhost:' + port + path, function (res) {
      var body = '';
      res.on('data', function (c) { body += c; });
      res.on('end', function () {
        server.close();
        cb(null, { status: res.statusCode, body: body });
      });
    });
    req.on('error', function (err) { server.close(); cb(err); });
  });
}

function test(name, setupApp, check) {
  var app = setupApp();
  makeRequest(app, '/', function (err, resp) {
    if (err) {
      failed++;
      results.push('  FAIL  ' + name + ': ' + err.message);
    } else {
      try {
        check(resp);
        passed++;
        results.push('  PASS  ' + name);
      } catch (e) {
        failed++;
        results.push('  FAIL  ' + name + ': ' + e.message);
      }
    }
    if (passed + failed === TOTAL_NODE_TESTS) finish();
  });
}

function testWithPath(name, path, setupApp, check) {
  var app = setupApp();
  makeRequest(app, path, function (err, resp) {
    if (err) {
      failed++;
      results.push('  FAIL  ' + name + ': ' + err.message);
    } else {
      try {
        check(resp);
        passed++;
        results.push('  PASS  ' + name);
      } catch (e) {
        failed++;
        results.push('  FAIL  ' + name + ': ' + e.message);
      }
    }
    if (passed + failed === TOTAL_NODE_TESTS) finish();
  });
}

function finish() {
  results.forEach(function (r) { console.log(r); });
  console.log('\n' + passed + ' passing, ' + failed + ' failing');
  process.exit(failed > 0 ? 1 : 0);
}

// ── Test 1: async route handler (throw) ──────────────────────────────────────
test(
  'async route throw reaches error handler',
  function () {
    var app = express();
    app.get('/', async function (req, res) {
      throw new Error('async boom');
    });
    app.use(function (err, req, res, next) {
      res.status(500).send('caught:' + err.message);
    });
    return app;
  },
  function (resp) {
    if (resp.status !== 500) throw new Error('expected 500 got ' + resp.status);
    if (resp.body.indexOf('async boom') === -1)
      throw new Error('expected "async boom" in body, got: ' + resp.body);
  }
);

// ── Test 2: handler that returns a rejected Promise ───────────────────────────
test(
  'rejected promise from route reaches error handler',
  function () {
    var app = express();
    app.get('/', function (req, res) {
      return Promise.reject(new Error('promise reject'));
    });
    app.use(function (err, req, res, next) {
      res.status(500).send('caught:' + err.message);
    });
    return app;
  },
  function (resp) {
    if (resp.status !== 500) throw new Error('expected 500 got ' + resp.status);
    if (resp.body.indexOf('promise reject') === -1)
      throw new Error('expected "promise reject" in body, got: ' + resp.body);
  }
);

// ── Test 3: async middleware throws ───────────────────────────────────────────
test(
  'async middleware throw reaches error handler',
  function () {
    var app = express();
    app.use(async function (req, res, next) {
      throw new Error('middleware async error');
    });
    app.get('/', function (req, res) { res.send('ok'); });
    app.use(function (err, req, res, next) {
      res.status(500).send('caught:' + err.message);
    });
    return app;
  },
  function (resp) {
    if (resp.status !== 500) throw new Error('expected 500 got ' + resp.status);
    if (resp.body.indexOf('middleware async error') === -1)
      throw new Error('expected "middleware async error" in body, got: ' + resp.body);
  }
);

// ── Test 4: async error handler propagates its own error ──────────────────────
test(
  'async error handler propagates its own throw',
  function () {
    var app = express();
    app.get('/', function (req, res, next) {
      next(new Error('original'));
    });
    app.use(async function (err, req, res, next) {
      throw new Error('error handler also threw');
    });
    app.use(function (err, req, res, next) {
      res.status(500).send('final:' + err.message);
    });
    return app;
  },
  function (resp) {
    if (resp.status !== 500) throw new Error('expected 500 got ' + resp.status);
    if (resp.body.indexOf('error handler also threw') === -1)
      throw new Error('expected "error handler also threw" in body, got: ' + resp.body);
  }
);

// ── Test 5: multiple async handlers execute in order, error from last ─────────
test(
  'multiple async handlers execute in order with error propagation',
  function () {
    var app = express();
    var order = [];
    app.use(async function (req, res, next) { order.push(1); next(); });
    app.use(async function (req, res, next) { order.push(2); next(); });
    app.get('/', async function (req, res) {
      order.push(3);
      throw new Error('from route');
    });
    app.use(function (err, req, res, next) {
      res.status(500).send(JSON.stringify({ order: order, error: err.message }));
    });
    return app;
  },
  function (resp) {
    if (resp.status !== 500) throw new Error('expected 500 got ' + resp.status);
    var parsed = JSON.parse(resp.body);
    if (JSON.stringify(parsed.order) !== '[1,2,3]')
      throw new Error('expected order [1,2,3] got ' + JSON.stringify(parsed.order));
    if (parsed.error !== 'from route')
      throw new Error('expected "from route" got ' + parsed.error);
  }
);

// ── Test 6: next(err) + rejected promise → error handler invoked exactly once ──
test(
  'next(err) and rejected promise invokes error handler exactly once',
  function () {
    var app = express();
    var invocations = [];
    app.get('/', function (req, res, next) {
      next(new Error('sync-error'));
      return Promise.reject(new Error('promise-error'));
    });
    app.use(function (err, req, res, next) {
      invocations.push(err.message);
      // delay response so any spurious second invocation can arrive first
      if (invocations.length === 1) {
        setTimeout(function () {
          if (!res.headersSent) {
            res.status(500).send(JSON.stringify(invocations));
          }
        }, 50);
      }
    });
    return app;
  },
  function (resp) {
    if (resp.status !== 500) throw new Error('expected 500 got ' + resp.status);
    var inv = JSON.parse(resp.body);
    if (inv.length !== 1)
      throw new Error('expected exactly 1 error handler invocation, got ' + inv.length + ': ' + resp.body);
    if (inv[0] !== 'sync-error')
      throw new Error('expected "sync-error" to win, got: ' + JSON.stringify(inv));
  }
);

// ── Test 7: async error in express.Router() propagates to parent error handler ─
test(
  'async error in express.Router() propagates to parent error handler',
  function () {
    var app = express();
    var router = express.Router();
    router.get('/', async function (req, res) {
      throw new Error('nested-router-error');
    });
    app.use(router);
    app.use(function (err, req, res, next) {
      res.status(500).send('caught:' + err.message);
    });
    return app;
  },
  function (resp) {
    if (resp.status !== 500) throw new Error('expected 500 got ' + resp.status);
    if (resp.body.indexOf('nested-router-error') === -1)
      throw new Error('expected "nested-router-error", got: ' + resp.body);
  }
);

// ── Test 8: async handler calling next("route") skips to next matching route ───
test(
  'async handler calling next("route") skips to next matching route',
  function () {
    var app = express();
    app.get('/', async function (req, res, next) {
      next('route');
    });
    app.get('/', function (req, res) {
      res.status(200).send('second-handler');
    });
    app.use(function (err, req, res, next) {
      res.status(500).send('unexpected-error:' + err.message);
    });
    return app;
  },
  function (resp) {
    if (resp.status !== 200) throw new Error('expected 200 got ' + resp.status);
    if (resp.body !== 'second-handler')
      throw new Error('expected "second-handler", got: ' + resp.body);
  }
);

// ── Test 9: async app.param() handler error propagates to error handler ────────
testWithPath(
  'async app.param() handler throw reaches error handler',
  '/42',
  function () {
    var app = express();
    app.param('id', async function (req, res, next, id) {
      throw new Error('param-error:' + id);
    });
    app.get('/:id', function (req, res) {
      res.status(200).send('ok');
    });
    app.use(function (err, req, res, next) {
      res.status(500).send('caught:' + err.message);
    });
    return app;
  },
  function (resp) {
    if (resp.status !== 500) throw new Error('expected 500 got ' + resp.status);
    if (resp.body.indexOf('param-error:42') === -1)
      throw new Error('expected "param-error:42", got: ' + resp.body);
  }
);

// ── Test 10: async handler that resolves sends response correctly ──────────────
test(
  'async handler that resolves sends response correctly',
  function () {
    var app = express();
    app.get('/', async function (req, res) {
      var value = await Promise.resolve('async-ok');
      res.status(200).send(value);
    });
    app.use(function (err, req, res, next) {
      res.status(500).send('unexpected-error');
    });
    return app;
  },
  function (resp) {
    if (resp.status !== 200) throw new Error('expected 200 got ' + resp.status);
    if (resp.body !== 'async-ok')
      throw new Error('expected "async-ok", got: ' + resp.body);
  }
);

// ── Test 11: array of async route handlers — error from second ────────────────
test(
  'array of async route handlers — error from second handler propagates',
  function () {
    var app = express();
    app.get('/', [
      async function (req, res, next) { next(); },
      async function (req, res, next) { throw new Error('array-second-throw'); }
    ]);
    app.use(function (err, req, res, next) {
      res.status(500).send('caught:' + err.message);
    });
    return app;
  },
  function (resp) {
    if (resp.status !== 500) throw new Error('expected 500 got ' + resp.status);
    if (resp.body.indexOf('array-second-throw') === -1)
      throw new Error('expected "array-second-throw", got: ' + resp.body);
  }
);

// ── Test 12: mixed sync+async handler array — async throws ────────────────────
test(
  'mixed sync and async handler array — async handler throw propagates',
  function () {
    var app = express();
    app.get('/', [
      function (req, res, next) { req.tag = 'sync-ran'; next(); },
      async function (req, res, next) { throw new Error('mixed-async-throw:' + req.tag); }
    ]);
    app.use(function (err, req, res, next) {
      res.status(500).send('caught:' + err.message);
    });
    return app;
  },
  function (resp) {
    if (resp.status !== 500) throw new Error('expected 500 got ' + resp.status);
    if (resp.body.indexOf('mixed-async-throw:sync-ran') === -1)
      throw new Error('expected "mixed-async-throw:sync-ran", got: ' + resp.body);
  }
);

// ── Test 13: sub-path mounted async middleware throw propagates ────────────────
testWithPath(
  'async middleware mounted at sub-path throw propagates to parent error handler',
  '/api/data',
  function () {
    var app = express();
    app.use('/api', async function (req, res, next) {
      throw new Error('sub-path-async-error');
    });
    app.use(function (err, req, res, next) {
      res.status(500).send('caught:' + err.message);
    });
    return app;
  },
  function (resp) {
    if (resp.status !== 500) throw new Error('expected 500 got ' + resp.status);
    if (resp.body.indexOf('sub-path-async-error') === -1)
      throw new Error('expected "sub-path-async-error", got: ' + resp.body);
  }
);

// ── Test 14: async error handler recovery via next() after await ──────────────
test(
  'async error handler that calls next() after await passes to next normal middleware',
  function () {
    var app = express();
    app.get('/', function (req, res, next) {
      next(new Error('initial-error'));
    });
    app.use(async function (err, req, res, next) {
      await Promise.resolve();
      next(); // recovery — no error arg
    });
    app.use(function (req, res) {
      res.status(200).send('recovered-ok');
    });
    app.use(function (err, req, res, next) {
      res.status(500).send('should-not-reach');
    });
    return app;
  },
  function (resp) {
    if (resp.status !== 200) throw new Error('expected 200 got ' + resp.status);
    if (resp.body !== 'recovered-ok')
      throw new Error('expected "recovered-ok", got: ' + resp.body);
  }
);

// ── Test 15: deferred async throw — multiple awaits before throw ──────────────
test(
  'async handler with multiple awaits before throw propagates error correctly',
  function () {
    var app = express();
    app.get('/', async function (req, res) {
      var a = await Promise.resolve('step-a');
      var b = await Promise.resolve('step-b');
      await Promise.resolve();
      throw new Error('deferred-throw:' + a + ':' + b);
    });
    app.use(function (err, req, res, next) {
      res.status(500).send('caught:' + err.message);
    });
    return app;
  },
  function (resp) {
    if (resp.status !== 500) throw new Error('expected 500 got ' + resp.status);
    if (resp.body.indexOf('deferred-throw:step-a:step-b') === -1)
      throw new Error('expected deferred throw body, got: ' + resp.body);
  }
);

// ── Test 16: app.all() with async handler throw ───────────────────────────────
test(
  'app.all() with async handler throw reaches error handler',
  function () {
    var app = express();
    app.all('*', async function (req, res) {
      throw new Error('all-routes-async-error');
    });
    app.use(function (err, req, res, next) {
      res.status(500).send('caught:' + err.message);
    });
    return app;
  },
  function (resp) {
    if (resp.status !== 500) throw new Error('expected 500 got ' + resp.status);
    if (resp.body.indexOf('all-routes-async-error') === -1)
      throw new Error('expected "all-routes-async-error", got: ' + resp.body);
  }
);

// ── Test 17: next("router") from async handler exits sub-router cleanly ───────
test(
  'async handler calling next("router") exits sub-router and app fallback handles request',
  function () {
    var app = express();
    var router = express.Router();
    router.use(async function (req, res, next) { next('router'); });
    router.get('/', function (req, res) { res.status(500).send('should-not-reach'); });
    app.use(router);
    app.use(function (req, res) { res.status(200).send('app-fallback'); });
    app.use(function (err, req, res, next) { res.status(500).send('unexpected-error'); });
    return app;
  },
  function (resp) {
    if (resp.status !== 200) throw new Error('expected 200 got ' + resp.status);
    if (resp.body !== 'app-fallback')
      throw new Error('expected "app-fallback", got: ' + resp.body);
  }
);

// ── Test 18: async middleware enriches req, async route error carries data ─────
test(
  'async middleware that enriches req and async route error preserves req data',
  function () {
    var app = express();
    app.use(async function (req, res, next) {
      req.requestId = await Promise.resolve('req-123');
      next();
    });
    app.get('/', async function (req, res) {
      throw new Error('route-error:' + req.requestId);
    });
    app.use(function (err, req, res, next) {
      res.status(500).send('caught:' + err.message);
    });
    return app;
  },
  function (resp) {
    if (resp.status !== 500) throw new Error('expected 500 got ' + resp.status);
    if (resp.body.indexOf('route-error:req-123') === -1)
      throw new Error('expected "route-error:req-123", got: ' + resp.body);
  }
);

// ── Test 19: async app.param() happy path — resolves and sets req property ────
testWithPath(
  'async app.param() handler that resolves sets req property and route reads it',
  '/user/alice',
  function () {
    var app = express();
    app.param('username', async function (req, res, next, name) {
      req.user = await Promise.resolve({ name: name, role: 'admin' });
      next();
    });
    app.get('/user/:username', function (req, res) {
      res.status(200).send(JSON.stringify(req.user));
    });
    app.use(function (err, req, res, next) {
      res.status(500).send('unexpected-error:' + err.message);
    });
    return app;
  },
  function (resp) {
    if (resp.status !== 200) throw new Error('expected 200 got ' + resp.status);
    var user = JSON.parse(resp.body);
    if (user.name !== 'alice') throw new Error('expected name "alice", got: ' + resp.body);
    if (user.role !== 'admin') throw new Error('expected role "admin", got: ' + resp.body);
  }
);

// ── Test 20: deeply nested routers — error propagates to outermost handler ────
test(
  'async error in deeply nested router propagates to outermost error handler',
  function () {
    var app = express();
    var outerRouter = express.Router();
    var innerRouter = express.Router();
    innerRouter.get('/', async function (req, res) {
      throw new Error('deep-nested-error');
    });
    outerRouter.use(innerRouter);
    app.use(outerRouter);
    app.use(function (err, req, res, next) {
      res.status(500).send('caught:' + err.message);
    });
    return app;
  },
  function (resp) {
    if (resp.status !== 500) throw new Error('expected 500 got ' + resp.status);
    if (resp.body.indexOf('deep-nested-error') === -1)
      throw new Error('expected "deep-nested-error", got: ' + resp.body);
  }
);

// ── Test 21: req.get should not trust CRLF-tainted header values ─────────────
test(
  'req.get sanitizes CRLF-tainted header values',
  function () {
    var app = express();
    app.get('/', function (req, res) {
      req.headers['x-custom'] = 'safe\\r\\nInjected: yes';
      var val = req.get('X-Custom');
      res.status(200).send(String(val));
    });
    return app;
  },
  function (resp) {
    if (resp.status !== 200) throw new Error('expected 200 got ' + resp.status);
    if (resp.body !== 'undefined') {
      throw new Error('expected undefined for CRLF-tainted header, got: ' + resp.body);
    }
  }
);

// ── Test 22: req.hostname should reject CRLF in X-Forwarded-Host ─────────────
test(
  'req.hostname rejects CRLF-tainted X-Forwarded-Host',
  function () {
    var app = express();
    app.set('trust proxy', true);
    app.get('/', function (req, res) {
      req.headers['x-forwarded-host'] = 'example.com\\r\\nInjected: yes';
      res.status(200).send(String(req.hostname));
    });
    return app;
  },
  function (resp) {
    if (resp.status !== 200) throw new Error('expected 200 got ' + resp.status);
    if (resp.body !== 'undefined') {
      throw new Error('expected undefined hostname for CRLF-tainted host, got: ' + resp.body);
    }
  }
);

// ── Test 23: res.set should reject CRLF values early ─────────────────────────
test(
  'res.set rejects CRLF header values',
  function () {
    var app = express();
    app.get('/', function (req, res, next) {
      try {
        res.set('X-Test', 'ok\\r\\nInjected: yes');
        res.status(200).send('unexpected-success');
      } catch (e) {
        next(e);
      }
    });
    app.use(function (err, req, res, next) {
      res.status(500).send('caught:' + err.message);
    });
    return app;
  },
  function (resp) {
    if (resp.status !== 500) throw new Error('expected 500 got ' + resp.status);
    if (resp.body.indexOf('CRLF') === -1 && resp.body.indexOf('Invalid') === -1) {
      throw new Error('expected CRLF/Invalid header rejection message, got: ' + resp.body);
    }
  }
);

// ── Test 24: redirect/location should reject CRLF URLs ───────────────────────
test(
  'res.redirect rejects CRLF-tainted URLs',
  function () {
    var app = express();
    app.get('/', function (req, res, next) {
      try {
        res.redirect('/ok\\r\\nInjected: yes');
      } catch (e) {
        next(e);
      }
    });
    app.use(function (err, req, res, next) {
      res.status(500).send('caught:' + err.message);
    });
    return app;
  },
  function (resp) {
    if (resp.status !== 500) throw new Error('expected 500 got ' + resp.status);
    var b = resp.body.toLowerCase();
    if (b.indexOf('crlf') === -1 && b.indexOf('invalid') === -1 && b.indexOf('illegal') === -1) {
      throw new Error('expected CRLF/invalid rejection message, got: ' + resp.body);
    }
  }
);

// ── Test 25: res.append should reject CRLF values ──────────────────────────────
test(
  'res.append rejects CRLF header values',
  function () {
    var app = express();
    app.get('/', function (req, res, next) {
      try {
        res.append('Set-Cookie', 'session=abc\\r\\nInjected: yes');
        res.status(200).send('unexpected-success');
      } catch (e) {
        next(e);
      }
    });
    app.use(function (err, req, res, next) {
      res.status(500).send('caught:' + err.message);
    });
    return app;
  },
  function (resp) {
    if (resp.status !== 500) throw new Error('expected 500 got ' + resp.status);
    var b = resp.body.toLowerCase();
    if (b.indexOf('crlf') === -1 && b.indexOf('invalid') === -1 && b.indexOf('illegal') === -1) {
      throw new Error('expected CRLF/invalid rejection, got: ' + resp.body);
    }
  }
);

// ── Test 26: res.cookie rejects CRLF in cookie name ─────────────────────────────
test(
  'res.cookie rejects CRLF in cookie name',
  function () {
    var app = express();
    app.get('/', function (req, res, next) {
      try {
        res.cookie('sid\\r\\nInjected', 'value');
        res.status(200).send('unexpected-success');
      } catch (e) {
        next(e);
      }
    });
    app.use(function (err, req, res, next) {
      res.status(500).send('caught:' + err.message);
    });
    return app;
  },
  function (resp) {
    if (resp.status !== 500) throw new Error('expected 500 got ' + resp.status);
    var b = resp.body.toLowerCase();
    if (b.indexOf('crlf') === -1 && b.indexOf('invalid') === -1 && b.indexOf('illegal') === -1) {
      throw new Error('expected CRLF/invalid rejection, got: ' + resp.body);
    }
  }
);

// ── Test 27: res.cookie rejects CRLF in cookie value ────────────────────────────
test(
  'res.cookie rejects CRLF in cookie value',
  function () {
    var app = express();
    app.get('/', function (req, res, next) {
      try {
        res.cookie('session', 'abc\\r\\nInjected: yes');
        res.status(200).send('unexpected-success');
      } catch (e) {
        next(e);
      }
    });
    app.use(function (err, req, res, next) {
      res.status(500).send('caught:' + err.message);
    });
    return app;
  },
  function (resp) {
    if (resp.status !== 500) throw new Error('expected 500 got ' + resp.status);
    var b = resp.body.toLowerCase();
    if (b.indexOf('crlf') === -1 && b.indexOf('invalid') === -1 && b.indexOf('illegal') === -1) {
      throw new Error('expected CRLF/invalid rejection, got: ' + resp.body);
    }
  }
);

// ── Test 28: res.location rejects CRLF URLs ───────────────────────────────────
test(
  'res.location rejects CRLF in URL',
  function () {
    var app = express();
    app.get('/', function (req, res, next) {
      try {
        res.location('/new\\r\\nSet-Cookie: evil=1');
        res.status(200).send('unexpected-success');
      } catch (e) {
        next(e);
      }
    });
    app.use(function (err, req, res, next) {
      res.status(500).send('caught:' + err.message);
    });
    return app;
  },
  function (resp) {
    if (resp.status !== 500) throw new Error('expected 500 got ' + resp.status);
    var b = resp.body.toLowerCase();
    if (b.indexOf('crlf') === -1 && b.indexOf('invalid') === -1 && b.indexOf('illegal') === -1) {
      throw new Error('expected CRLF/invalid rejection, got: ' + resp.body);
    }
  }
);

// ── Test 29: res.set rejects CRLF in header NAME ──────────────────────────────
test(
  'res.set rejects CRLF in header name',
  function () {
    var app = express();
    app.get('/', function (req, res, next) {
      try {
        res.set('X-Custom\\r\\nInjected', 'value');
        res.status(200).send('unexpected-success');
      } catch (e) {
        next(e);
      }
    });
    app.use(function (err, req, res, next) {
      res.status(500).send('caught:' + err.message);
    });
    return app;
  },
  function (resp) {
    if (resp.status !== 500) throw new Error('expected 500 got ' + resp.status);
    var b = resp.body.toLowerCase();
    if (b.indexOf('crlf') === -1 && b.indexOf('invalid') === -1 && b.indexOf('illegal') === -1) {
      throw new Error('expected CRLF/invalid rejection, got: ' + resp.body);
    }
  }
);

// ── Test 30: req.header alias should also sanitize CRLF ─────────────────────────
test(
  'req.header() sanitizes CRLF-tainted header values',
  function () {
    var app = express();
    app.get('/', function (req, res) {
      req.headers['x-data'] = 'ok\\r\\nInjected: yes';
      var val = req.header('X-Data');
      res.status(200).send(String(val));
    });
    return app;
  },
  function (resp) {
    if (resp.status !== 200) throw new Error('expected 200 got ' + resp.status);
    if (resp.body !== 'undefined') {
      throw new Error('expected undefined for CRLF-tainted header via req.header(), got: ' + resp.body);
    }
  }
);

// ── Test 31: req.referer property sanitizes CRLF ──────────────────────────────
test(
  'req.referer property sanitizes CRLF-tainted values',
  function () {
    var app = express();
    app.get('/', function (req, res) {
      req.headers.referer = '/page\\r\\nInjected: yes';
      var ref = req.referer;
      res.status(200).send(String(ref));
    });
    return app;
  },
  function (resp) {
    if (resp.status !== 200) throw new Error('expected 200 got ' + resp.status);
    if (resp.body !== 'undefined') {
      throw new Error('expected undefined for CRLF-tainted referer, got: ' + resp.body);
    }
  }
);

// ── Test 32: Multiple CRLF sequences should be blocked ────────────────────────
test(
  'Multiple CRLF sequences rejected in header value',
  function () {
    var app = express();
    app.get('/', function (req, res, next) {
      try {
        res.set('X-Multi', 'line1\\r\\nline2\\r\\nline3');
        res.status(200).send('unexpected-success');
      } catch (e) {
        next(e);
      }
    });
    app.use(function (err, req, res, next) {
      res.status(500).send('caught:' + err.message);
    });
    return app;
  },
  function (resp) {
    if (resp.status !== 500) throw new Error('expected 500 got ' + resp.status);
    var b = resp.body.toLowerCase();
    if (b.indexOf('crlf') === -1 && b.indexOf('invalid') === -1 && b.indexOf('illegal') === -1) {
      throw new Error('expected CRLF/invalid rejection for multiple sequences, got: ' + resp.body);
    }
  }
);
"""

TEST_PATH = "/tmp/async_verify.js"
with open(TEST_PATH, "w") as f:
    f.write(NODE_TEST)

# ---------------------------------------------------------------------------
# Run the Node.js test script
# ---------------------------------------------------------------------------
result = subprocess.run(
    ["node", TEST_PATH],
    capture_output=True,
    text=True,
    cwd="/testbed",
    timeout=30,
)

output = result.stdout + result.stderr
print(output)

with open(f"{LOG_DIR}/test-output.log", "w") as f:
    f.write(output)

# ---------------------------------------------------------------------------
# Parse results
# ---------------------------------------------------------------------------
NODE_TESTS = 32

def static_check(name, condition):
  if condition:
    print(f"  PASS  {name}")
    return 1
  print(f"  FAIL  {name}")
  return 0

pass_count = len(re.findall(r"^\s+PASS\s+", output, re.MULTILINE))
fail_count = len(re.findall(r"^\s+FAIL\s+", output, re.MULTILINE))

# Fallback: parse "N passing" line from the script's own summary
m_pass = re.search(r"(\d+) passing", output)
if m_pass and pass_count == 0:
    pass_count = int(m_pass.group(1))

if pass_count > NODE_TESTS:
  pass_count = NODE_TESTS

# Static file checks for Option B/C requirements
request_src = open('/testbed/lib/request.js', 'r', encoding='utf-8').read()
response_src = open('/testbed/lib/response.js', 'r', encoding='utf-8').read()
utils_src = open('/testbed/lib/utils.js', 'r', encoding='utf-8').read()

static_pass = 0
static_pass += static_check('utils exports containsInvalidHeaderChar', 'exports.containsInvalidHeaderChar' in utils_src)
static_pass += static_check('response uses containsInvalidHeaderChar', 'containsInvalidHeaderChar' in response_src)
static_pass += static_check('request uses containsInvalidHeaderChar', 'containsInvalidHeaderChar' in request_src)
static_pass += static_check('request uses socket.encrypted', 'this.socket.encrypted' in request_src)
static_pass += static_check('request uses socket.remoteAddress', 'this.socket.remoteAddress' in request_src)
static_pass += static_check('request does not use connection.encrypted', 'this.connection.encrypted' not in request_src)
static_pass += static_check('request does not use connection.remoteAddress', 'this.connection.remoteAddress' not in request_src)
static_pass += static_check('request uses trimEnd and not trimRight', 'trimEnd()' in request_src and 'trimRight()' not in request_src)
static_pass += static_check('response validates res.set headers with CRLF check', 'containsInvalidHeaderChar' in response_src and 'setHeader' in response_src)
static_pass += static_check('response validates res.cookie with CRLF check', 'containsInvalidHeaderChar(name)' in response_src and 'containsInvalidHeaderChar(val)' in response_src)
static_pass += static_check('response validates res.location/redirect with CRLF check', 'containsInvalidHeaderChar(loc)' in response_src)

TOTAL_TESTS = NODE_TESTS + 11
pass_count += static_pass

reward = round(pass_count / TOTAL_TESTS, 4)

with open(f"{LOG_DIR}/reward.txt", "w") as f:
    f.write(str(reward))

print(f"\nReward: {reward:.2f}  ({pass_count}/{TOTAL_TESTS} tests passed)")
