// Read-only endpoint: no model probes, reset-credit redemption, or credential files.
export class QuotaError extends Error {
  constructor(message, permanent = false) {
    super(message)
    this.permanent = permanent
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

export async function readQuota(ctx, modelID, expectedConnection, fetchImpl = fetch) {
  const connection = await ctx.integration.connection.active("openai")
  if (connection?.type !== "credential" || connection.method !== "oauth") {
    throw new QuotaError("Connect an OpenAI OAuth account before scheduling recovery.", true)
  }
  if (expectedConnection && connection.id !== expectedConnection) {
    throw new QuotaError("OpenAI account changed. Run /codex-resume again.", true)
  }
  const credential = await ctx.integration.connection.resolve(connection)
  if (credential?.type !== "oauth") throw new QuotaError("OpenAI OAuth credential unavailable.", true)
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
  return { ...parseQuota(body, modelID), connectionID: connection.id }
}
