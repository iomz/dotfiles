import { randomUUID } from "node:crypto"

export const POLL_MS = 10_000
export const RESUME_TEXT = "Resume from where you paused."
export const isQuotaError = error => /usage_limit_reached|usage limit|quota (?:exceeded|exhausted)|exhausted.*quota/i.test(`${error?.type ?? ""} ${error?.message ?? ""}`)
const same = (a, b) => JSON.stringify(a) === JSON.stringify(b)

export function describeResume(state) {
  if (!state) return "Codex resume: off"
  const mode = state.repeat ? "repeat" : "once"
  if (state.error) return `Codex resume (${mode}): ${state.error}`
  if (state.awaiting) return `Codex resume (${mode}): resuming`
  if (!state.pending) return `Codex resume (${mode}): armed for next quota failure`
  if (state.pending.resetAt > Date.now()) return `Codex resume (${mode}): ${new Date(state.pending.resetAt).toLocaleString()}`
  return `Codex resume (${mode}): waiting for quota`
}

// All durable data lives in OpenCode plugin storage, never the dotfiles source.
// Serialize per session; revisions invalidate network checks when the user takes over.
export class ResumeController {
  constructor(io) {
    this.io = io
    this.states = new Map()
    this.locks = new Map()
    this.revisions = new Map()
    this.inspections = new Map()
    this.closed = false
  }

  serial(id, work) {
    const next = (this.locks.get(id) ?? Promise.resolve()).catch(() => {}).then(work)
    this.locks.set(id, next)
    void next.finally(() => {
      if (this.locks.get(id) !== next) return
      this.locks.delete(id)
      if (!this.states.has(id)) { this.revisions.delete(id); this.inspections.delete(id) }
    }).catch(() => {})
    return next
  }

  async restore() {
    for (const [id, state] of await this.io.load()) this.states.set(id, state)
  }

  async save(id, state) {
    if (state) { await this.io.save(id, state); this.states.set(id, state) }
    else { await this.io.remove(id); this.states.delete(id) }
    await this.io.changed(id, describeResume(state))
  }

  status(id) { return describeResume(this.states.get(id)) }

  invalidate(id) { this.revisions.set(id, (this.revisions.get(id) ?? 0) + 1) }

  manual(id, disable = false) {
    if (!this.states.has(id) && !this.locks.has(id)) return Promise.resolve()
    this.invalidate(id)
    return this.serial(id, async () => {
      const state = this.states.get(id)
      if (state) await this.save(id, !disable && state.repeat ? { repeat: true } : null)
    })
  }

  command(id, argument = "") {
    const flag = argument.trim()
    if (flag === "--status") return this.io.changed(id, this.status(id))
    if (flag === "--cancel") return this.manual(id, true).then(() => this.io.changed(id, "Codex resume: cancelled"))
    if (flag && flag !== "--repeat") throw new Error("Usage: /codex-resume [--repeat | --cancel | --status]")
    this.invalidate(id)
    const revision = this.revisions.get(id)
    return this.serial(id, async () => {
      const repeat = flag === "--repeat"
      const existing = this.states.get(id)
      if (existing?.pending || existing?.awaiting) {
        await this.save(id, { ...existing, repeat })
        return
      }
      const snapshot = await this.io.snapshot(id)
      if (this.revisions.get(id) !== revision) return
      if (!snapshot || snapshot.model?.providerID !== "openai") throw new Error("Select an OpenAI model first.")
      if (!snapshot.failed) {
        if (!repeat) throw new Error("This session has no interrupted OpenAI quota failure to resume.")
        await this.save(id, { repeat: true })
        return
      }
      await this.arm(id, { repeat }, snapshot)
    })
  }

  async arm(id, state, snapshot, delay = 0) {
    const revision = this.revisions.get(id)
    const pending = {
      id: `msg_${randomUUID().replaceAll("-", "")}`,
      model: snapshot.model, agent: snapshot.agent ?? null,
      fingerprint: snapshot.fingerprint,
      nextCheck: this.io.now() + delay, resetAt: null,
    }
    // Save before network I/O, so a failed initial check cannot lose opt-in.
    await this.save(id, { repeat: state.repeat, pending })
    if (!delay) await this.check(id, revision)
  }

  failure(id) {
    return this.serial(id, async () => {
      const state = this.states.get(id)
      if (!state || state.error || state.pending || (!state.repeat && !state.awaiting)) return
      const revision = this.revisions.get(id)
      const snapshot = await this.io.snapshot(id)
      if (this.revisions.get(id) !== revision) return
      if (!snapshot || snapshot.model?.providerID !== "openai") { await this.save(id, null); return }
      if (state.awaiting && snapshot?.resumeID !== state.resumeID) return
      if (snapshot?.failed) await this.arm(id, state, snapshot, state.awaiting ? POLL_MS : 0)
      else if (state.awaiting) await this.save(id, state.repeat ? { repeat: true } : null)
    })
  }

  succeeded(id) {
    return this.serial(id, async () => {
      const state = this.states.get(id)
      if (state?.awaiting) await this.save(id, state.repeat ? { repeat: true } : null)
    })
  }

  async tick() {
    if (this.closed) return
    await Promise.allSettled([...this.states].map(([id, state]) => {
      const inspect = !state.pending && !state.error && (state.awaiting || state.repeat) &&
        (this.inspections.get(id) ?? 0) <= this.io.now()
      if (state.pending?.nextCheck <= this.io.now() || inspect) {
        // Skip rather than queue another tick behind a slow quota request.
        if (!this.locks.has(id)) {
          this.inspections.set(id, this.io.now() + POLL_MS)
          return state.pending || state.awaiting ? this.serial(id, () => this.check(id)) : this.failure(id)
        }
      }
    }))
  }

  async check(id, revision = this.revisions.get(id)) {
    const state = this.states.get(id)
    if (!state || this.closed) return
    const valid = () => !this.closed && this.revisions.get(id) === revision
    if (!valid()) return
    let snapshot
    try { snapshot = await this.io.snapshot(id) } catch { return }
    if (!valid()) return
    if (!snapshot) { await this.save(id, null); return }
    if (state.awaiting) {
      if (snapshot.resumeID !== state.resumeID) {
        if (snapshot.fingerprint !== state.before) await this.save(id, state.repeat ? { repeat: true } : null)
        return
      }
      if (snapshot.failed) await this.arm(id, state, snapshot, POLL_MS)
      else if (["succeeded", "failed", "interrupted"].includes(snapshot.outcome)) await this.save(id, state.repeat ? { repeat: true } : null)
      return
    }
    const pending = state.pending
    if (!pending) return
    if (snapshot.resumeID === pending.id) {
      await this.save(id, { repeat: state.repeat, awaiting: true, resumeID: pending.id, before: pending.fingerprint })
      return
    }
    if (!same(snapshot.model, pending.model) || (snapshot.agent ?? null) !== pending.agent ||
        snapshot.fingerprint !== pending.fingerprint || !snapshot.failed) {
      await this.save(id, state.repeat ? { repeat: true } : null)
      return
    }
    let quota
    try { quota = await this.io.quota(pending.model.id, pending.connectionID) }
    catch (error) {
      if (!valid()) return
      if (error.permanent) {
        await this.save(id, { repeat: state.repeat, error: error.message })
      } else {
        await this.save(id, { ...state, pending: { ...pending, nextCheck: this.io.now() + POLL_MS } })
      }
      return
    }
    if (!valid()) return
    const nextPending = { ...pending, connectionID: quota.connectionID }
    if (!quota.allowed) {
      // After the predicted reset, poll every 10 seconds even if a stale endpoint
      // continues advertising the same reset time.
      const resetAt = pending.resetAt ?? (quota.resetAt ? quota.resetAt + 2000 : null)
      await this.save(id, { ...state, pending: {
        ...nextPending, resetAt, nextCheck: Math.max(this.io.now() + POLL_MS, resetAt ?? 0),
      } })
      return
    }
    // Revalidate after quota I/O: user/model/agent changes must win over timers.
    const current = await this.io.snapshot(id)
    if (!valid()) return
    if (!current || !same(current.model, pending.model) || (current.agent ?? null) !== pending.agent ||
        current.fingerprint !== pending.fingerprint || !current.failed) {
      await this.save(id, state.repeat ? { repeat: true } : null)
      return
    }
    // Stable request ID survives a crash between admission and storage update.
    await this.save(id, { ...state, pending: { ...nextPending, nextCheck: this.io.now() + POLL_MS } })
    if (!valid()) return
    try {
      await this.io.prompt(id, pending.id)
      if (valid()) await this.save(id, { repeat: state.repeat, awaiting: true, resumeID: pending.id, before: pending.fingerprint })
    } catch {
      // Retry admission with the SAME ID; OpenCode deduplicates durable inbox IDs.
    }
  }

  async close() {
    this.closed = true
    await Promise.allSettled(this.locks.values())
  }
}
