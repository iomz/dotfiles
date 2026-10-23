import { Plugin } from "@opencode/plugin"
import { ResumeRpc } from "./resume-rpc.js"
import { ResumeController, RESUME_TEXT, isQuotaError } from "./resume.js"
import { readQuota } from "./quota.js"

export default Plugin.define({
  id: "personal.codex-quota-sidebar",
  async setup(ctx) {
    const prefix = `resume/${encodeURIComponent(ctx.location.directory)}/${encodeURIComponent(ctx.location.workspaceID ?? "local")}/`
    const owns = session => session.location.directory === ctx.location.directory &&
      session.location.workspaceID === ctx.location.workspaceID
    const snapshot = async sessionID => {
      let session
      try { session = await ctx.session.get({ sessionID }) }
      catch (error) {
        if (error.status === 404 || [error.type, error._tag, error.name].includes("SessionNotFoundError")) return null
        throw error
      }
      if (!owns(session) || session.time.archived) return null
      const messages = await ctx.session.context({ sessionID })
      const userIndex = messages.findLastIndex(message => message.type === "user")
      const user = messages[userIndex]
      const assistant = messages.slice(userIndex + 1).findLast(message => message.type === "assistant")
      const model = session.model ?? (await ctx.model.default({ location: session.location })).data
      return {
        model, agent: session.agent,
        outcome: assistant?.time.completed ? session.outcome : undefined,
        failed: session.outcome === "failed" && isQuotaError(assistant?.error) && assistant?.model.providerID === "openai",
        fingerprint: JSON.stringify([user?.id, assistant?.id, session.revert ?? null]),
        resumeID: user?.metadata?.codexResume,
      }
    }
    let registration
    const controller = new ResumeController({
      now: Date.now,
      snapshot,
      quota: (model, connection) => readQuota(ctx, model, connection),
      prompt: (sessionID, id) => ctx.session.prompt({
        sessionID, id, text: RESUME_TEXT, delivery: "queue", metadata: { codexResume: id },
      }),
      save: (id, state) => ctx.storage.set(prefix + id, state),
      remove: id => ctx.storage.remove(prefix + id),
      load: async () => {
        const entries = []
        let after
        do {
          const page = await ctx.storage.scan({ prefix, limit: 100, after })
          for (const entry of page.entries) entries.push([entry.key.slice(prefix.length), entry.value])
          after = page.next
        } while (after)
        return entries
      },
      changed: async (sessionID, message) => {
        // A disconnected TUI must not affect recovery or its persisted state.
        try { await registration?.events.emit("changed", { sessionID, message }) } catch {}
      },
    })
    const disposers = []
    const abort = new AbortController()
    let timer
    const cleanup = async () => {
      clearInterval(timer)
      abort.abort()
      await controller.close()
      await Promise.allSettled(disposers.map(dispose => dispose()))
    }
    try {
      registration = await ctx.rpc.register(ResumeRpc, {
        status: async ({ sessionID }) => controller.status(sessionID),
      })
      disposers.push(() => registration.dispose())
      await controller.restore()
      const command = await ctx.command.transform(editor => editor.add({
        name: "codex-resume",
        description: "Resume after Codex quota resets: --repeat, --cancel, --status",
        execute: async ({ sessionID, prompt }) => {
          let message
          try {
            await controller.command(sessionID, prompt.text)
            message = controller.status(sessionID)
          } catch (error) { message = error.message }
          await registration.events.emit("notice", { sessionID, message })
        },
      }))
      disposers.push(() => command.dispose())
      const prompt = await ctx.session.hook("prompt", event => {
        const pending = controller.states.get(event.sessionID)?.pending
        if (event.metadata?.codexResume === pending?.id && pending) return
        return controller.manual(event.sessionID)
      })
      disposers.push(() => prompt.dispose())
      const retry = await ctx.session.hook("retry", event => {
        const state = controller.states.get(event.sessionID)
        if (!state?.error && event.model.providerID === "openai" && (state?.repeat || state?.awaiting) && isQuotaError(event.error)) {
          event.decision = { retry: false }
        }
      })
      disposers.push(() => retry.dispose())
      void (async () => {
        for await (const event of ctx.event.subscribe({ signal: abort.signal })) {
          if (event.location?.directory !== ctx.location.directory ||
              event.location?.workspaceID !== ctx.location.workspaceID) continue
          const id = event.data?.sessionID
          if (!id || !controller.states.has(id)) continue
          try {
            if (event.type === "session.execution.failed") await controller.failure(id)
            if (event.type === "session.step.ended" || event.type === "session.execution.succeeded") await controller.succeeded(id)
            if (["session.deleted", "session.model.selected", "session.agent.selected", "session.moved"].includes(event.type)) await controller.manual(id, true)
            if (event.type === "session.execution.interrupted") await controller.manual(id)
          } catch { /* Retry persisted pending work on the next scheduler tick. */ }
        }
      })().catch(() => {})
      timer = setInterval(() => void controller.tick(), 1000)
      return cleanup
    } catch (error) {
      await cleanup()
      throw error
    }
  },
})
