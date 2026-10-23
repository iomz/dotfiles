import { test } from "node:test"
import assert from "node:assert/strict"
import { mkdtemp, copyFile, symlink, rm } from "node:fs/promises"
import { tmpdir } from "node:os"
import { join } from "node:path"
import { pathToFileURL } from "node:url"

// Exercise source entrypoint against the installed SDK without a live service,
// credentials, model calls, or writing plugin state outside this fixture.
test("server entrypoint registers SDK command, RPC, hooks, and cleans up", {
  skip: !process.env.OPENCODE_PLUGIN_NODE_MODULES,
}, async () => {
  const directory = await mkdtemp(join(process.env.TMPDIR ?? tmpdir(), "codex-resume-test-"))
  const originalFetch = globalThis.fetch
  let cleanup
  try {
    for (const file of ["index.js", "resume.js", "resume-rpc.js", "quota.js", "package.json"]) {
      await copyFile(new URL(`../dot_config/opencode/cli-plugins/codex-quota-sidebar/${file}`, import.meta.url), join(directory, file))
    }
    await symlink(process.env.OPENCODE_PLUGIN_NODE_MODULES, join(directory, "node_modules"))
    const { default: plugin } = await import(pathToFileURL(join(directory, "index.js")))
    const hooks = new Map()
    const storage = new Map()
    const notices = []
    const prompts = []
    let command
    let rpc
    let disposed = 0
    const registration = () => ({ dispose: async () => { disposed++ } })
    const model = { providerID: "openai", id: "gpt-5.4", variant: "high" }
    const session = { model, agent: "build", location: { directory: "/workspace" }, time: {}, outcome: "succeeded" }
    const messages = [
      { id: "u", type: "user" },
      { id: "a", type: "assistant", model, time: { completed: 1 }, error: { type: "usage_limit_reached", message: "Usage limit" } },
    ]
    const ctx = {
      location: { directory: "/workspace" },
      storage: {
        scan: async () => ({ entries: [] }),
        set: async (key, value) => storage.set(key, structuredClone(value)),
        remove: async key => storage.delete(key),
      },
      rpc: { register: async (definition, implementation) => {
        assert.equal(definition.id, "personal.codex-resume")
        rpc = implementation
        return { ...registration(), events: { emit: async (type, data) => notices.push({ type, ...data }) } }
      } },
      command: { transform: async callback => { callback({ add: value => { command = value } }); return registration() } },
      session: {
        get: async () => session,
        context: async () => messages,
        hook: async (name, callback) => { hooks.set(name, callback); return registration() },
        prompt: async input => {
          await hooks.get("prompt")({ sessionID: input.sessionID, metadata: input.metadata })
          prompts.push(input)
          return { id: input.id }
        },
      },
      integration: { connection: {
        active: async () => ({ type: "credential", id: "account", method: "oauth" }),
        resolve: async () => ({ type: "oauth", access: "fake" }),
      } },
      event: { subscribe: ({ signal }) => ({
        async *[Symbol.asyncIterator]() {
          await new Promise(resolve => {
            if (signal.aborted) resolve()
            else signal.addEventListener("abort", resolve, { once: true })
          })
        },
      }) },
    }
    cleanup = await plugin.setup(ctx)
    assert.equal(command.name, "codex-resume")
    await command.execute({ sessionID: "s", prompt: { text: "--repeat" } })
    assert.match(await rpc.status({ sessionID: "s" }), /repeat/)
    assert.equal(prompts.length, 0)
    const retry = { sessionID: "s", model, error: messages[1].error, decision: { retry: true, delay: 1000 } }
    hooks.get("retry")(retry)
    assert.deepEqual(retry.decision, { retry: false })
    await command.execute({ sessionID: "s", prompt: { text: "--cancel" } })
    assert.equal(storage.size, 0)
    session.outcome = "failed"
    globalThis.fetch = async () => new Response(JSON.stringify({ rate_limit: { allowed: true, limit_reached: false } }))
    await command.execute({ sessionID: "s", prompt: { text: "" } })
    assert.equal(prompts.length, 1)
    assert.equal(prompts[0].text, "Resume from where you paused.")
    assert.equal(prompts[0].delivery, "queue")
    assert.equal(prompts[0].metadata.codexResume, prompts[0].id)
    assert.equal(session.model, model)
    assert.match(await rpc.status({ sessionID: "s" }), /resuming/)
    await hooks.get("prompt")({ sessionID: "s", metadata: {} })
    assert.equal(storage.size, 0)
    assert.ok(notices.some(notice => notice.type === "notice"))
    await cleanup()
    cleanup = undefined
    assert.equal(disposed, 4)
  } finally {
    await cleanup?.()
    globalThis.fetch = originalFetch
    await rm(directory, { recursive: true, force: true })
  }
})
