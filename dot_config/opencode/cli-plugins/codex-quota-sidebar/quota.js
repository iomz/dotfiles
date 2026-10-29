// Read-only endpoint: no model probes, reset-credit redemption, or credential files.
export class QuotaError extends Error {
  constructor(message, permanent = false, code) {
    super(message)
    this.permanent = permanent
    this.code = code
  }
}

export function parseQuota(body, modelID, now = Date.now()) {
  // Spark has an independent bucket. Never infer its availability from Codex's bucket.
  const spark = /spark/i.test(modelID)
  const bucket = spark
    ? body.additional_rate_limits?.find(item => /spark/i.test(`${item.limit_name ?? ""} ${item.metered_feature ?? ""}`))?.rate_limit
    : body.rate_limit
  if (!bucket || typeof bucket.allowed !== "boolean" || typeof bucket.limit_reached !== "boolean") {
    throw new QuotaError("Quota response is missing availability fields.")
  }
  const windows = [bucket.primary_window, bucket.secondary_window].filter(Boolean)
  const exhausted = windows.filter(window => typeof window.used_percent === "number" && window.used_percent >= 100)
  const resetAt = exhausted.map(window => {
    if (Number.isFinite(window.reset_at)) return window.reset_at * 1000
    if (Number.isFinite(window.reset_after_seconds)) return now + window.reset_after_seconds * 1000
    return null
  })
  return {
    allowed: bucket.allowed === true && bucket.limit_reached === false && exhausted.length === 0,
    // Missing reset timestamps mean poll conservatively, not assume quota is ready.
    resetAt: resetAt.length && resetAt.every(value => value !== null) ? Math.max(...resetAt) : null,
  }
}

function percent(value) {
  return Number.isFinite(value) ? Math.round(Math.max(0, Math.min(100, value))) : null
}

function durationText(seconds) {
  const total = Math.max(0, Math.floor(seconds))
  const days = Math.floor(total / 86400)
  const hours = Math.floor(total % 86400 / 3600)
  const minutes = Math.floor(total % 3600 / 60)
  if (days > 0) return `${days}d${hours}h`
  if (hours > 0) return `${hours}h${minutes}m`
  return `${minutes}m`
}

function resetText(window, now) {
  if (Number.isFinite(window?.reset_after_seconds)) return durationText(window.reset_after_seconds)
  if (Number.isFinite(window?.reset_at)) return durationText(window.reset_at - now / 1000)
  return null
}

// Sidebar snapshot. Exhausted windows still report usage here, unlike model-probe headers.
export function parseUsage(body, now = Date.now()) {
  const bucket = body?.rate_limit
  if (!bucket || typeof bucket !== "object") throw new QuotaError("Quota response is missing rate limits.")
  const windows = { primary: bucket.primary_window, secondary: bucket.secondary_window }
  const pair = read => ({ primary: read(windows.primary), secondary: read(windows.secondary) })
  const usage = {
    status: "ok",
    used: pair(window => percent(window?.used_percent)),
    reset: pair(window => resetText(window, now)),
    windowMinutes: pair(window => Number.isFinite(window?.limit_window_seconds) ? Math.round(window.limit_window_seconds / 60) : null),
  }
  if (typeof body.plan_type === "string" && body.plan_type) usage.plan = body.plan_type
  return usage
}

async function fetchUsage(ctx, expectedConnection, fetchImpl) {
  const connection = await ctx.integration.connection.active("openai")
  if (connection?.type !== "credential" || connection.method !== "oauth") {
    throw new QuotaError("Connect an OpenAI OAuth account before scheduling recovery.", true)
  }
  if (expectedConnection && connection.id !== expectedConnection) {
    throw new QuotaError("OpenAI account changed. Run /codex-resume again.", true)
  }
  const credential = await ctx.integration.connection.resolve(connection)
  if (credential?.type !== "oauth") throw new QuotaError("OpenAI OAuth credential unavailable.", true)
  // Token-sharing credentials target api.openai.com, not the legacy ChatGPT
  // usage endpoint. A fresh token still receives 401 there; reauth cannot fix it.
  if (credential.methodID === "chatgpt-token-sharing") {
    throw new QuotaError(
      "Codex usage requires legacy Codex OAuth. Run /connect > OpenAI > Codex device code (legacy).",
      true, "legacy_oauth_required",
    )
  }
  const headers = { Authorization: `Bearer ${credential.access}` }
  const accountID = credential.metadata?.accountID ?? credential.metadata?.accountId
  if (typeof accountID === "string") headers["ChatGPT-Account-Id"] = accountID
  let response
  try {
    response = await fetchImpl("https://chatgpt.com/backend-api/wham/usage", {
      headers, signal: AbortSignal.timeout(15_000),
    })
  } catch {
    throw new QuotaError("Quota check failed; retrying in 10 seconds.")
  }
  if (!response.ok) {
    throw new QuotaError(`Quota check returned HTTP ${response.status}.`, [401, 403].includes(response.status))
  }
  let body
  try { body = await response.json() } catch { throw new QuotaError("Invalid quota response.") }
  return { body, connectionID: connection.id }
}

export async function readQuota(ctx, modelID, expectedConnection, fetchImpl = fetch) {
  const { body, connectionID } = await fetchUsage(ctx, expectedConnection, fetchImpl)
  return { ...parseQuota(body, modelID), connectionID }
}

export async function readUsage(ctx, fetchImpl = fetch, now = Date.now) {
  try {
    return parseUsage((await fetchUsage(ctx, undefined, fetchImpl)).body, now())
  } catch (error) {
    return {
      status: "error", error: error instanceof QuotaError ? error.message : "Quota check failed.",
      ...(error instanceof QuotaError && error.code ? { code: error.code } : {}),
    }
  }
}
