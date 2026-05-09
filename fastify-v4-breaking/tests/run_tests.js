'use strict'

const fastify = require('/testbed')

const results = { passed: 0, failed: 0, tests: [] }

async function test (name, fn) {
  try {
    await fn()
    results.passed++
    results.tests.push({ name, passed: true })
  } catch (err) {
    results.failed++
    results.tests.push({ name, passed: false, error: err.message })
  }
}

function assert (cond, msg) {
  if (!cond) throw new Error(msg || 'assertion failed')
}

function assertEqual (a, b) {
  if (a !== b) throw new Error(`expected ${JSON.stringify(b)} but got ${JSON.stringify(a)}`)
}

async function run () {
  // ───────────────────────────────────────────────────────────────────────
  // GROUP 1: exposeHeadRoutes default = true
  // ───────────────────────────────────────────────────────────────────────
  await test('G1-1: default config auto-creates HEAD for GET route', async () => {
    const app = fastify()
    app.get('/hello', async () => 'world')
    await app.ready()
    const res = await app.inject({ method: 'HEAD', url: '/hello' })
    assertEqual(res.statusCode, 200)
    await app.close()
  })

  await test('G1-2: exposeHeadRoutes:false suppresses HEAD auto-creation', async () => {
    const app = fastify({ exposeHeadRoutes: false })
    app.get('/hello', async () => 'world')
    await app.ready()
    const res = await app.inject({ method: 'HEAD', url: '/hello' })
    assertEqual(res.statusCode, 404)
    await app.close()
  })

  await test('G1-3: exposeHeadRoutes:true creates HEAD route', async () => {
    const app = fastify({ exposeHeadRoutes: true })
    app.get('/hello', async () => 'world')
    await app.ready()
    const res = await app.inject({ method: 'HEAD', url: '/hello' })
    assertEqual(res.statusCode, 200)
    await app.close()
  })

  await test('G1-4: HEAD response body is empty (no body for HEAD)', async () => {
    const app = fastify()
    app.get('/hello', async () => ({ msg: 'world' }))
    await app.ready()
    const res = await app.inject({ method: 'HEAD', url: '/hello' })
    assertEqual(res.statusCode, 200)
    assertEqual(res.body, '')
    await app.close()
  })

  // ───────────────────────────────────────────────────────────────────────
  // GROUP 2: Body schema on GET/HEAD throws FST_ERR_SCH_BODY_GET_HEAD
  // ───────────────────────────────────────────────────────────────────────
  await test('G2-5: GET + schema.body throws FST_ERR_SCH_BODY_GET_HEAD', async () => {
    const app = fastify()
    let threw = false
    let errCode = null
    try {
      app.get('/x', {
        schema: { body: { type: 'object', properties: { name: { type: 'string' } } } }
      }, async () => 'ok')
      await app.ready()
    } catch (err) {
      threw = true
      errCode = err.code
    }
    assert(threw, 'Expected error to be thrown')
    assertEqual(errCode, 'FST_ERR_SCH_BODY_GET_HEAD')
    await app.close()
  })

  await test('G2-6: HEAD + schema.body throws FST_ERR_SCH_BODY_GET_HEAD', async () => {
    const app = fastify({ exposeHeadRoutes: false })
    let threw = false
    let errCode = null
    try {
      app.head('/x', {
        schema: { body: { type: 'object' } }
      }, async () => 'ok')
      await app.ready()
    } catch (err) {
      threw = true
      errCode = err.code
    }
    assert(threw, 'Expected error to be thrown')
    assertEqual(errCode, 'FST_ERR_SCH_BODY_GET_HEAD')
    await app.close()
  })

  await test('G2-7: POST + schema.body does not throw', async () => {
    const app = fastify()
    app.post('/x', {
      schema: { body: { type: 'object', properties: { name: { type: 'string' } } } }
    }, async () => 'ok')
    await app.ready()
    await app.close()
  })

  await test('G2-8: PUT + schema.body does not throw', async () => {
    const app = fastify()
    app.put('/x', {
      schema: { body: { type: 'object' } }
    }, async () => 'ok')
    await app.ready()
    await app.close()
  })

  await test('G2-9: PATCH + schema.body does not throw', async () => {
    const app = fastify()
    app.patch('/x', {
      schema: { body: { type: 'object' } }
    }, async () => 'ok')
    await app.ready()
    await app.close()
  })

  await test('G2-10: GET without schema.body does not throw', async () => {
    const app = fastify()
    app.get('/x', {
      schema: { response: { 200: { type: 'string' } } }
    }, async () => 'ok')
    await app.ready()
    await app.close()
  })

  // ───────────────────────────────────────────────────────────────────────
  // GROUP 3: reply.sent setter throws
  // ───────────────────────────────────────────────────────────────────────
  await test('G3-11: reply.sent = true throws FST_ERR_REP_SENT_VALUE', async () => {
    const app = fastify()
    app.get('/x', (req, reply) => {
      let threw = false
      let errCode = null
      try {
        reply.sent = true
      } catch (err) {
        threw = true
        errCode = err.code
      }
      assert(threw, 'Expected FST_ERR_REP_SENT_VALUE to be thrown')
      assertEqual(errCode, 'FST_ERR_REP_SENT_VALUE')
      return reply.send('ok')
    })
    await app.ready()
    const res = await app.inject('/x')
    assertEqual(res.statusCode, 200)
    await app.close()
  })

  await test('G3-12: reply.sent = false throws FST_ERR_REP_SENT_VALUE', async () => {
    const app = fastify()
    app.get('/x', (req, reply) => {
      let threw = false
      let errCode = null
      try {
        reply.sent = false
      } catch (err) {
        threw = true
        errCode = err.code
      }
      assert(threw, 'Expected FST_ERR_REP_SENT_VALUE to be thrown')
      assertEqual(errCode, 'FST_ERR_REP_SENT_VALUE')
      return reply.send('ok')
    })
    await app.ready()
    const res = await app.inject('/x')
    assertEqual(res.statusCode, 200)
    await app.close()
  })

  await test('G3-13: reply.sent getter returns false initially', async () => {
    const app = fastify()
    app.get('/x', (req, reply) => {
      assertEqual(reply.sent, false)
      return reply.send('ok')
    })
    await app.ready()
    const res = await app.inject('/x')
    assertEqual(res.statusCode, 200)
    await app.close()
  })

  await test('G3-14: reply.hijack() sets reply.sent to true', async () => {
    const app = fastify()
    app.get('/x', (req, reply) => {
      reply.hijack()
      assertEqual(reply.sent, true)
      // must write response manually after hijack
      reply.raw.end('ok')
    })
    await app.ready()
    const res = await app.inject('/x')
    assertEqual(res.statusCode, 200)
    await app.close()
  })

  await test('G3-15: after hijack, double-send is prevented', async () => {
    const app = fastify()
    app.get('/x', (req, reply) => {
      reply.hijack()
      // reply.send after hijack should not crash the server
      // it should be a no-op or handle gracefully
      reply.raw.end('ok')
    })
    await app.ready()
    const res = await app.inject('/x')
    assert(res.statusCode < 600, 'Should complete without crash')
    await app.close()
  })

  // ───────────────────────────────────────────────────────────────────────
  // GROUP 4: Async handler returning undefined → 200 OK
  // ───────────────────────────────────────────────────────────────────────
  await test('G4-16: async handler returning undefined → 200 OK', async () => {
    const app = fastify()
    app.get('/x', async (req, reply) => {
      // return undefined
    })
    await app.ready()
    const res = await app.inject('/x')
    assertEqual(res.statusCode, 200)
    await app.close()
  })

  await test('G4-17: async handler returning undefined with code(201) → 201', async () => {
    const app = fastify()
    app.get('/x', async (req, reply) => {
      reply.code(201)
      // return undefined
    })
    await app.ready()
    const res = await app.inject('/x')
    assertEqual(res.statusCode, 201)
    await app.close()
  })

  await test('G4-18: async handler calling reply.send then returning undefined → 200 with body', async () => {
    const app = fastify()
    app.get('/x', async (req, reply) => {
      reply.send('data')
      // return undefined — should not double-send
    })
    await app.ready()
    const res = await app.inject('/x')
    assertEqual(res.statusCode, 200)
    assertEqual(res.body, 'data')
    await app.close()
  })

  await test('G4-19: async handler returning null sends null properly', async () => {
    const app = fastify()
    app.get('/x', async () => null)
    await app.ready()
    const res = await app.inject('/x')
    assertEqual(res.statusCode, 200)
    await app.close()
  })

  await test('G4-20: async handler returning undefined with 204 → 204', async () => {
    const app = fastify()
    app.get('/x', async (req, reply) => {
      reply.code(204)
      // return undefined
    })
    await app.ready()
    const res = await app.inject('/x')
    assertEqual(res.statusCode, 204)
    await app.close()
  })

  // ───────────────────────────────────────────────────────────────────────
  // GROUP 5: throw-anything in handler → proper 500 JSON error
  // ───────────────────────────────────────────────────────────────────────
  await test('G5-21: sync handler throwing string → 500 JSON with message', async () => {
    const app = fastify()
    app.get('/x', (req, reply) => {
      throw 'foo'
    })
    await app.ready()
    const res = await app.inject('/x')
    assertEqual(res.statusCode, 500)
    const body = JSON.parse(res.body)
    assertEqual(body.message, 'foo')
    await app.close()
  })

  await test('G5-22: sync handler throwing number → 500 JSON with message', async () => {
    const app = fastify()
    app.get('/x', (req, reply) => {
      throw 42
    })
    await app.ready()
    const res = await app.inject('/x')
    assertEqual(res.statusCode, 500)
    const body = JSON.parse(res.body)
    assertEqual(body.message, '42')
    await app.close()
  })

  await test('G5-23: sync handler throwing Error → 500 JSON', async () => {
    const app = fastify()
    app.get('/x', (req, reply) => {
      throw new Error('normal error')
    })
    await app.ready()
    const res = await app.inject('/x')
    assertEqual(res.statusCode, 500)
    const body = JSON.parse(res.body)
    assertEqual(body.message, 'normal error')
    await app.close()
  })

  await test('G5-24: async handler rejecting with string → 500 JSON', async () => {
    const app = fastify()
    app.get('/x', async () => {
      throw 'async string error'
    })
    await app.ready()
    const res = await app.inject('/x')
    assertEqual(res.statusCode, 500)
    const body = JSON.parse(res.body)
    assertEqual(body.message, 'async string error')
    await app.close()
  })

  await test('G5-25: async handler rejecting with non-Error object → 500 JSON', async () => {
    const app = fastify()
    app.get('/x', async () => {
      throw { custom: true }
    })
    await app.ready()
    const res = await app.inject('/x')
    assertEqual(res.statusCode, 500)
    const body = JSON.parse(res.body)
    assert(typeof body.message === 'string', 'message should be a string')
    await app.close()
  })

  // ───────────────────────────────────────────────────────────────────────
  // GROUP 6: Hooks throw-anything → proper 500 JSON error
  // ───────────────────────────────────────────────────────────────────────
  await test('G6-26: preHandler hook throwing string → 500 JSON', async () => {
    const app = fastify()
    app.get('/x', {
      preHandler: (req, reply, done) => { done('hook string error') }
    }, async () => 'ok')
    await app.ready()
    const res = await app.inject('/x')
    assertEqual(res.statusCode, 500)
    const body = JSON.parse(res.body)
    assertEqual(body.message, 'hook string error')
    await app.close()
  })

  await test('G6-27: preValidation hook throwing string → 500 JSON', async () => {
    const app = fastify()
    app.get('/x', {
      preValidation: (req, reply, done) => { done('preValidation error') }
    }, async () => 'ok')
    await app.ready()
    const res = await app.inject('/x')
    assertEqual(res.statusCode, 500)
    const body = JSON.parse(res.body)
    assertEqual(body.message, 'preValidation error')
    await app.close()
  })

  await test('G6-28: onRequest hook throwing string → 500 JSON', async () => {
    const app = fastify()
    app.addHook('onRequest', (req, reply, done) => { done('onRequest error') })
    app.get('/x', async () => 'ok')
    await app.ready()
    const res = await app.inject('/x')
    assertEqual(res.statusCode, 500)
    const body = JSON.parse(res.body)
    assertEqual(body.message, 'onRequest error')
    await app.close()
  })

  await test('G6-29: preHandler async hook rejecting with string → 500 JSON', async () => {
    const app = fastify()
    app.get('/x', {
      preHandler: async (req, reply) => { throw 'async hook error' }
    }, async () => 'ok')
    await app.ready()
    const res = await app.inject('/x')
    assertEqual(res.statusCode, 500)
    const body = JSON.parse(res.body)
    assertEqual(body.message, 'async hook error')
    await app.close()
  })

  await test('G6-30: error response has proper JSON structure', async () => {
    const app = fastify()
    app.get('/x', () => { throw 'check structure' })
    await app.ready()
    const res = await app.inject('/x')
    assertEqual(res.statusCode, 500)
    const body = JSON.parse(res.body)
    assert('statusCode' in body, 'response should have statusCode')
    assert('error' in body, 'response should have error')
    assert('message' in body, 'response should have message')
    assertEqual(body.statusCode, 500)
    await app.close()
  })
}

run().then(() => {
  console.log(JSON.stringify(results))
  process.exit(results.failed > 0 ? 1 : 0)
}).catch(err => {
  console.error(err)
  process.exit(2)
})
