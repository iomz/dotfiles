import { test } from "node:test"
import assert from "node:assert/strict"
import { ResumeController, POLL_MS, describeResume, isQuotaError } from "../dot_config/opencode/cli-plugins/codex-quota-sidebar/resume.js"
import { parseQuota, parseUsage, readQuota, readUsage, QuotaError } from "../dot_config/opencode/cli-plugins/codex-quota-sidebar/quota.js"

const model = { providerID: "openai", id: "gpt-5.4", variant: "high" }
const failure = () => ({ model, agent: "build", failed: true, fingerprint: "original", outcome: "failed" })
const blocked = resetAt => ({ allowed: false, resetAt, connectionID: "account" })
const ready = { allowed: true, resetAt: null, connectionID: "account" }
const deferred = () => {
  let resolve
  const promise = new Promise(done => { resolve = done })
  return { promise, resolve }
}

function fixture(durable = new Map()) {
  const f = { now: 100_000, snapshot: failure(), quota: blocked(200_000), calls: 0, prompts: [], notices: [] }
  const io = {
    now: () => f.now,
    load: async () => [...durable],
    save: async (id, value) => durable.set(id, structuredClone(value)),
    remove: async id => durable.delete(id),
    snapshot: async () => structuredClone(f.snapshot),
    quota: async () => { f.calls++; return typeof f.quota === "function" ? f.quota() : f.quota },
    prompt: async (sessionID, id) => {
      f.prompts.push({ sessionID, id })
      f.snapshot = { ...failure(), failed: false, outcome: undefined, fingerprint: "resume", resumeID: id }
    },
    changed: async (id, message) => f.notices.push({ id, message }),
    wake: async due => { f.wake = due },
  }
  f.io = io
  f.durable = durable
  f.controller = new ResumeController(io)
  return f
}

test("once is opt-in and sends nothing until quota is explicitly available", async () => {
  const f = fixture()
  await f.controller.tick()
  assert.equal(f.calls, 0)
  await f.controller.command("s")
  assert.equal(f.calls, 1)
  assert.equal(f.prompts.length, 0)
  f.now = 201_000
  await f.controller.tick()
  assert.equal(f.calls, 1) // reset + two-second buffer
  f.now = 202_000
  await f.controller.tick()
  assert.equal(f.calls, 2)
  assert.equal(f.prompts.length, 0)
  f.now += POLL_MS - 1
  f.quota = ready
  await f.controller.tick()
  assert.equal(f.calls, 2)
  f.now++
  await f.controller.tick()
  assert.equal(f.prompts.length, 1)
  await Promise.all([f.controller.tick(), f.controller.tick()])
  assert.equal(f.prompts.length, 1)
  await f.controller.succeeded("s")
  assert.equal(f.controller.states.has("s"), false)
  await f.controller.failure("s")
  assert.equal(f.controller.states.has("s"), false)
})

test("repeat re-arms only after subsequent confirmed quota failure", async () => {
  const f = fixture()
  f.snapshot.failed = false
  await f.controller.command("s", "--repeat")
  assert.deepEqual(f.controller.states.get("s"), { repeat: true })
  assert.equal(f.calls, 0)
  f.snapshot = failure()
  await f.controller.failure("s")
  const first = f.controller.states.get("s").pending.id
  await f.controller.failure("s")
  assert.equal(f.controller.states.get("s").pending.id, first)
  f.now = 202_000
  f.quota = ready
  await f.controller.tick()
  await f.controller.succeeded("s")
  assert.deepEqual(f.controller.states.get("s"), { repeat: true })
  f.snapshot = failure()
  f.quota = blocked(400_000)
  await f.controller.failure("s")
  assert.notEqual(f.controller.states.get("s").pending.id, first)
})

test("manual continuation cancels current timer but keeps repeat; cancel disables both", async () => {
  const f = fixture()
  await f.controller.command("s", "--repeat")
  await f.controller.manual("s")
  assert.deepEqual(f.controller.states.get("s"), { repeat: true })
  await f.controller.command("s", "--cancel")
  assert.equal(f.controller.states.has("s"), false)
  f.now = 1_000_000
  await f.controller.tick()
  assert.equal(f.prompts.length, 0)
})

test("manual takeover during network check cannot queue a resume", async () => {
  const f = fixture()
  const request = deferred()
  const entered = deferred()
  f.quota = () => { entered.resolve(); return request.promise }
  const command = f.controller.command("s")
  await entered.promise
  const cancel = f.controller.manual("s")
  request.resolve(ready)
  await Promise.all([command, cancel])
  assert.equal(f.prompts.length, 0)
  assert.equal(f.controller.states.has("s"), false)
})

test("model, variant, agent, transcript, and deletion changes invalidate pending resume", async () => {
  for (const change of [
    { model: { ...model, id: "different" } },
    { model: { ...model, variant: "low" } },
    { agent: "plan" }, { fingerprint: "manual" }, { failed: false }, null,
  ]) {
    const f = fixture()
    await f.controller.command("s")
    f.snapshot = change ? { ...f.snapshot, ...change } : null
    f.now = 202_000
    f.quota = ready
    await f.controller.tick()
    assert.equal(f.prompts.length, 0)
    assert.equal(f.controller.states.has("s"), false)
  }
})

test("transient quota failures poll after 10s; authentication failures pause", async () => {
  const f = fixture()
  f.quota = () => { throw new QuotaError("network") }
  await f.controller.command("s")
  assert.equal(f.controller.states.get("s").pending.nextCheck, f.now + POLL_MS)
  f.now += POLL_MS
  f.quota = () => { throw new QuotaError("Sign in again", true) }
  await f.controller.tick()
  assert.equal(f.controller.states.get("s").pending, undefined)
  assert.match(f.controller.status("s"), /Sign in again/)
  f.now += POLL_MS
  await f.controller.tick()
  assert.equal(f.calls, 2)
})

test("durable recovery survives restart and laptop sleep", async () => {
  const f = fixture()
  await f.controller.command("s")
  const id = f.controller.states.get("s").pending.id
  await f.controller.close()
  const restarted = fixture(f.durable)
  restarted.now = 9_000_000
  restarted.quota = ready
  await restarted.controller.restore()
  await restarted.controller.tick()
  assert.equal(restarted.prompts[0].id, id)
})

test("restored repeat opt-in reconciles a failure whose event was missed during restart", async () => {
  const f = fixture(new Map([["s", { repeat: true }]]))
  await f.controller.restore()
  await f.controller.tick()
  assert.ok(f.controller.states.get("s").pending)
  assert.equal(f.calls, 1)
})

test("restart reconciles a submitted resume that failed for a non-quota reason", async () => {
  const f = fixture()
  f.quota = ready
  await f.controller.command("s")
  const restarted = fixture(f.durable)
  restarted.snapshot = { ...f.snapshot, failed: false, outcome: "failed" }
  await restarted.controller.restore()
  await restarted.controller.tick()
  assert.equal(restarted.controller.states.has("s"), false)
  assert.equal(restarted.prompts.length, 0)
})

test("retry ambiguous admission with stable ID; crash after admission does not duplicate", async () => {
  const f = fixture()
  const submitted = []
  f.io.prompt = async (_, id) => { submitted.push(id); throw new Error("lost response") }
  f.quota = ready
  await f.controller.command("s")
  f.now += POLL_MS
  await f.controller.tick()
  assert.equal(submitted.length, 2)
  assert.equal(submitted[0], submitted[1])
  const restarted = fixture(f.durable)
  restarted.snapshot.resumeID = submitted[0]
  restarted.snapshot.failed = false
  restarted.now += POLL_MS * 2
  await restarted.controller.restore()
  await restarted.controller.tick()
  assert.equal(restarted.prompts.length, 0)
  assert.equal(restarted.controller.states.get("s").awaiting, true)
})

test("quota rejection immediately after admission continues same once recovery", async () => {
  const f = fixture()
  f.quota = ready
  await f.controller.command("s")
  f.snapshot = { ...f.snapshot, failed: true, outcome: "failed" }
  f.quota = blocked(200_000)
  await f.controller.failure("s")
  assert.ok(f.controller.states.get("s").pending)
  assert.equal(f.controller.states.get("s").repeat, false)
  assert.equal(f.controller.states.get("s").pending.nextCheck, f.now + POLL_MS)
  assert.equal(f.calls, 1)
})

test("repeated commands preserve one timer and one stable admission ID", async () => {
  const f = fixture()
  await f.controller.command("s")
  const id = f.controller.states.get("s").pending.id
  await f.controller.command("s", "--repeat")
  assert.equal(f.controller.states.get("s").pending.id, id)
  assert.equal(f.controller.states.get("s").repeat, true)
  assert.equal(f.calls, 1)
  f.now = 202_000
  f.quota = ready
  await f.controller.tick()
  await f.controller.command("s")
  assert.equal(f.prompts.length, 1)
  assert.equal(f.controller.states.get("s").repeat, false)
})

test("status is read-only; healthy and non-OpenAI sessions cannot arm once", async () => {
  const f = fixture()
  await f.controller.command("s", "--status")
  assert.equal(f.calls, 0)
  assert.equal(f.controller.states.size, 0)
  f.snapshot.failed = false
  await assert.rejects(f.controller.command("s"), /no interrupted/)
  f.snapshot.model = { providerID: "anthropic", id: "claude" }
  await assert.rejects(f.controller.command("s", "--repeat"), /Select an OpenAI/)
  assert.throws(() => f.controller.command("s", "--bogus"), /Usage:/)
  assert.equal(isQuotaError({ message: "429 Too many requests" }), false)
  assert.equal(isQuotaError({ message: "insufficient_quota: billing limit" }), false)
  assert.equal(isQuotaError({ type: "usage_limit_reached" }), true)
})

test("quota parser waits for latest exhausted window and fails closed", () => {
  const rate_limit = {
    allowed: false, limit_reached: true,
    primary_window: { used_percent: 100, reset_at: 200 },
    secondary_window: { used_percent: 100, reset_at: 400 },
  }
  assert.deepEqual(parseQuota({ rate_limit }, "gpt-5.4"), { allowed: false, resetAt: 400_000 })
  assert.throws(() => parseQuota({}, "gpt-5.4"), /missing availability/)
  assert.throws(() => parseQuota({ rate_limit }, "gpt-5.3-codex-spark"), /missing availability/)
  assert.deepEqual(parseQuota({ rate_limit: { allowed: true, limit_reached: false } }, "gpt-5.4"), { allowed: true, resetAt: null })
  const spark = { limit_name: "GPT-5.3-Codex-Spark", rate_limit: { ...rate_limit, secondary_window: undefined } }
  assert.equal(parseQuota({ additional_rate_limits: [spark] }, "gpt-5.3-codex-spark").resetAt, 200_000)
  assert.equal(parseQuota({ rate_limit: { ...rate_limit, primary_window: { used_percent: 100 }, secondary_window: undefined } }, "gpt").resetAt, null)
})

test("quota reader uses active credentials, read-only endpoint, and never exposes response body", async () => {
  const ctx = { integration: { connection: {
    active: async () => ({ type: "credential", method: "oauth", id: "account" }),
    resolve: async () => ({ type: "oauth", access: "secret", metadata: { accountID: "id" } }),
  } } }
  const fetchImpl = async (url, options) => {
    assert.equal(url, "https://chatgpt.com/backend-api/wham/usage")
    assert.equal(options.headers.Authorization, "Bearer secret")
    assert.equal(options.headers["ChatGPT-Account-Id"], "id")
    return new Response(JSON.stringify({ rate_limit: { allowed: true, limit_reached: false } }))
  }
  assert.equal((await readQuota(ctx, "gpt", "account", fetchImpl)).allowed, true)
  await assert.rejects(readQuota(ctx, "gpt", "other", fetchImpl), /account changed/)
  await assert.rejects(readQuota(ctx, "gpt", "account", async () => new Response("secret body", { status: 401 })), error => error.permanent && !error.message.includes("secret"))
})

test("usage snapshot keeps reporting both windows after one is exhausted", async () => {
  const body = {
    plan_type: "plus",
    rate_limit: {
      allowed: false, limit_reached: true,
      primary_window: { used_percent: 100, limit_window_seconds: 18_000, reset_after_seconds: 7_980 },
      secondary_window: { used_percent: 42.4, limit_window_seconds: 604_800, reset_at: 1_000 + 3 * 86_400 + 7_200 },
    },
  }
  assert.deepEqual(parseUsage(body, 1_000_000), {
    status: "ok", plan: "plus",
    used: { primary: 100, secondary: 42 },
    reset: { primary: "2h13m", secondary: "3d2h" },
    windowMinutes: { primary: 300, secondary: 10_080 },
  })
  assert.deepEqual(parseUsage({ rate_limit: {} }).used, { primary: null, secondary: null })
  assert.throws(() => parseUsage({}), /missing rate limits/)
  const ctx = { integration: { connection: {
    active: async () => ({ type: "credential", method: "oauth", id: "account" }),
    resolve: async () => ({ type: "oauth", access: "secret", metadata: {} }),
  } } }
  assert.equal((await readUsage(ctx, async () => new Response(JSON.stringify(body)), () => 1_000_000)).used.primary, 100)
  const failed = await readUsage(ctx, async () => new Response("secret body", { status: 429 }))
  assert.equal(failed.status, "error")
  assert.ok(!JSON.stringify(failed).includes("secret"))
})

test("pending resume shows local 24-hour time only", () => {
  const resetAt = new Date(2099, 0, 2, 17, 5, 6).getTime()
  assert.equal(describeResume({ repeat: false, pending: { resetAt } }), "Codex resume (once): 17:05")
})

test("wake time tracks the earliest pending check and clears when none remain", async () => {
  const f = fixture()
  await f.controller.command("s", "")
  assert.equal(f.wake, f.controller.states.get("s").pending.nextCheck)
  await f.controller.command("s", "--cancel")
  assert.equal(f.wake, null)
  const restored = fixture(new Map([["a", { repeat: true }], ["b", { repeat: false, pending: { nextCheck: 500 } }]]))
  await restored.controller.restore()
  assert.equal(restored.wake, 500)
})
