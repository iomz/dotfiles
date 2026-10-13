import { expect, test } from "bun:test"

// Run with OPENCODE_TUI_SOURCE=/path/to/opencode/packages/tui.
// Uses the same Solid/OpenTUI runtime as the native build, not a JSX stub.
const source = process.env.OPENCODE_TUI_SOURCE
test.skipIf(!source)("sidebar height stays stable across usage, tools, variants and workers", async () => {
  await import(`${source}/src/plugin/runtime-plugin-support.bun.ts`)
  const { testRender } = await import(Bun.resolveSync("@opentui/solid", source!))
  const { createSignal } = await import(Bun.resolveSync("solid-js", source!))
  const { parseThemeDocument, resolveThemeDocument } = await import(Bun.resolveSync("@opencode/theme/tui", source!))
  const { SidebarDashboard } = await import(`${process.env.HOME}/.config/opencode/cli-plugins/sidebar-dashboard/tui.tsx`)
  const { SidebarQuota } = await import(`${process.env.HOME}/.config/opencode/cli-plugins/codex-quota-sidebar/tui.tsx`)
  const theme = resolveThemeDocument(parseThemeDocument(await Bun.file(new URL("../dot_config/opencode/themes/cmux-transparent.json", import.meta.url)).json()), "dark")
  const [busy, setBusy] = createSignal(false)
  const tokens = { input: 100, output: 10, reasoning: 5, cache: { read: 20, write: 5 } }
  const model = { providerID: "test", id: "model" }
  const location = { directory: "/workspace" }
  let reply: (value: unknown) => void = () => {}
  let quotaLocation: unknown
  const context: any = {
    theme, options: {},
    client: { rpc: () => ({ usage: (_input: unknown, options: any) => {
      quotaLocation = options?.location
      return new Promise(resolve => { reply = resolve })
    } }) },
    data: {
      session: {
        get: () => ({ id: "test", location, agent: "build", model: { ...model, variant: busy() ? "Very long variant ".repeat(5) : undefined }, tokens: busy() ? tokens : undefined }),
        list: () => busy() ? [{ id: "child", parentID: "test", title: "Long subagent title ".repeat(5) }] : [],
        status: () => busy() ? "running" : "idle", cost: () => 0,
        message: { list: () => busy() ? [{ id: "message", type: "assistant", model, tokens, content: [{ type: "tool", state: { status: "running" } }] }] : [] },
      },
      shell: { list: () => busy() ? [{ status: "running", command: "Long command ".repeat(8) }] : [] },
      location: { default: () => location, model: { list: () => [{ ...model, name: "Long model name ".repeat(8), limit: { context: 1000 } }] } },
    },
    ui: { router: { navigate() {} } },
  }
  const app = await testRender(() => SidebarDashboard({ context, sessionID: "test" }), { width: 31, height: 60 })
  const headings = (frame: string) => frame.split("\n").flatMap((line, index) => /Context window|Usage|Session|Tokens|Activity|Workers/.test(line) ? [index] : [])
  try {
    await app.renderOnce()
    const initial = headings(app.captureCharFrame())
    expect(initial).toHaveLength(6)
    expect(app.captureCharFrame().split("\n").filter(line => /Context window|Usage|Session/.test(line)).map(line => line.trim())).toEqual(["Context window", "Usage", "Session"])
    setBusy(true)
    await app.renderOnce()
    expect(headings(app.captureCharFrame())).toEqual(initial)
    expect(app.captureCharFrame()).not.toContain("Long command")
    expect(app.captureCharFrame()).not.toContain("Long subagent")
    setBusy(false)
    await app.renderOnce()
    expect(headings(app.captureCharFrame())).toEqual(initial)
  } finally {
    app.renderer.destroy()
  }
  const quota = await testRender(() => SidebarQuota({ context }), { width: 31, height: 10 })
  try {
    await quota.renderOnce()
    expect(quotaLocation).toEqual(location)
    const initial = quota.captureCharFrame().split("\n").map(line => line.trim()).filter(Boolean)
    expect(initial).toHaveLength(6)
    reply({ status: "ok", used: { primary: 25, secondary: 50 }, reset: { primary: "Long reset description ".repeat(4), secondary: "Long reset description ".repeat(4) }, plan: "plus" })
    await Promise.resolve()
    await quota.renderOnce()
    const refreshed = quota.captureCharFrame()
    expect(refreshed.split("\n").map(line => line.trim()).filter(Boolean)).toHaveLength(6)
    expect(refreshed).toContain("Codex (plus)")
    expect(refreshed).toContain("█████████░░░ 75% left")
  } finally {
    quota.renderer.destroy()
  }
  const scoped = { directory: "/other-workspace" }
  const errorContext = {
    ...context, location: scoped,
    client: { rpc: () => ({ usage: async (_input: unknown, options: any) => {
      expect(options.location).toEqual(scoped)
      return { status: "error", statusCode: "auth" }
    } }) },
  }
  const unavailable = await testRender(() => SidebarQuota({ context: errorContext }), { width: 31, height: 10 })
  try {
    await Promise.resolve()
    await unavailable.renderOnce()
    const frame = unavailable.captureCharFrame()
    expect(frame).toContain("Codex (unavailable)")
    expect(frame).not.toContain("checking")
    expect(frame.split("\n").map(line => line.trim()).filter(Boolean)).toHaveLength(6)
  } finally {
    unavailable.renderer.destroy()
  }
})

test.skipIf(!source)("pinned tree setup and real collapsed renderer survive loading and toggling", async () => {
  await import(`${source}/src/plugin/runtime-plugin-support.bun.ts`)
  const { testRender } = await import(Bun.resolveSync("@opentui/solid", source!))
  const { createStore, produce } = await import(Bun.resolveSync("solid-js/store", source!))
  const { parseThemeDocument, resolveThemeDocument } = await import(Bun.resolveSync("@opencode/theme/tui", source!))
  // Applied path tests the installed dependency and exact entrypoint the TUI loads.
  const { default: tree } = await import(`${process.env.HOME}/.config/opencode/cli-plugins/dir-tree-bottom/tui.js`)
  const theme = resolveThemeDocument(parseThemeDocument(await Bun.file(new URL("../dot_config/opencode/themes/cmux-transparent.json", import.meta.url)).json()), "dark")
  const states = new Map<string, any>()
  const store = (key: string, options: any) => {
    if (!states.has(key)) {
      const [state, setState] = createStore(options.initial)
      states.set(key, [state, async (mutation: any) => setState(produce(mutation))])
    }
    return states.get(key)
  }
  let slot: any
  const context = {
    theme, options: {}, storage: { memory: store, store }, location: undefined,
    data: { on: () => () => {} }, keymap: { layer() {} },
    ui: { slot: (options: any) => { slot = options; return () => {} }, toast: { show() {} } },
  }
  const cleanup = await tree.setup(context)
  expect(slot.after).toBe("sidebar.content")
  expect(states.get("dir-tree.panel")[0].collapsed).toBe(true)
  const app = await testRender(() => slot.render({ sessionID: "test" }), { width: 31, height: 15 })
  try {
    await app.renderOnce()
    expect(app.captureCharFrame()).toContain("Dir Tree")
    await states.get("dir-tree.panel")[1]((draft: any) => { draft.collapsed = false })
    await app.renderOnce()
    expect(app.captureCharFrame()).toContain("Dir Tree")
  } finally {
    app.renderer.destroy()
    await cleanup?.()
  }
})
