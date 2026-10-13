import { describe, expect, test } from "bun:test"
import type { ModelInfo, SessionMessageInfo } from "@opencode/client"
import { activity, colorOption, compact, contextUsage, meter } from "../dot_config/opencode/cli-plugins/sidebar-dashboard/metrics"
import { quotaBar, quotaBand, styleColor } from "../dot_config/opencode/cli-plugins/codex-quota-sidebar/style"
import { treeContext } from "../dot_config/opencode/cli-plugins/dir-tree-bottom/context.js"

const model = { providerID: "test", id: "model", limit: { context: 1000 } } as ModelInfo
const assistant = (id: string, input: number) => ({
  id, type: "assistant", model: { providerID: "test", id: "model" }, content: [],
  tokens: { input, output: 10, reasoning: 5, cache: { read: 20, write: 5 } },
}) as unknown as SessionMessageInfo

describe("sidebar metrics", () => {
  test("tree wrapper moves only tree sidebar content and defaults panel to collapsed", () => {
    const context = {
      storage: { memory: (key: string, options: unknown) => ({ key, options }) },
      ui: { slot: (options: unknown) => options },
    }
    const wrapped = treeContext(context)
    const render = () => null
    expect(wrapped.ui.slot({ append: "sidebar.content", render })).toEqual({ after: "sidebar.content", render })
    expect(wrapped.ui.slot({ append: "app", render })).toEqual({ append: "app", render })
    expect(wrapped.storage.memory("dir-tree.panel", { initial: { collapsed: false } })).toEqual({
      key: "dir-tree.panel", options: { initial: { collapsed: true } },
    })
    expect(wrapped.storage.memory("other", { initial: { collapsed: false } })).toEqual({
      key: "other", options: { initial: { collapsed: false } },
    })
  })

  test("meters clamp percentages without losing width", () => {
    for (const percent of [-10, 0, 1, 53, 90, 100, 200]) expect(quotaBar(percent)).toHaveLength(12)
    expect(quotaBar(0)).toBe("░".repeat(12))
    expect(quotaBar(100)).toBe("█".repeat(12))
    expect(meter(-10)).toBe("────────────")
    expect(meter(200)).toBe("━━━━━━━━━━━━")
    expect(meter(50)).toBe("━━━━━━──────")
    expect(compact(1500)).toBe("1.5K")
  })

  test("context includes input/output/reasoning/cache and resolves model budget", () => {
    expect(contextUsage([assistant("first", 100), assistant("last", 160)], [model])).toEqual({ tokens: 200, percent: 20 })
    expect(contextUsage([assistant("last", 160)], [])).toEqual({ tokens: 200, percent: undefined })
  })

  test("context respects reverts, compaction, missing usage and unknown boundaries", () => {
    const compacted = { id: "compact", type: "compaction", status: "completed" } as SessionMessageInfo
    expect(contextUsage([assistant("old", 100), compacted], [model])).toBeUndefined()
    expect(contextUsage([assistant("old", 100), compacted, assistant("new", 60)], [model])).toEqual({ tokens: 100, percent: 10 })
    expect(contextUsage([assistant("old", 100), assistant("new", 60)], [model], "new")).toEqual({ tokens: 140, percent: 14 })
    expect(contextUsage([assistant("old", 100)], [model], "unknown")).toBeUndefined()
    expect(contextUsage([], [model])).toBeUndefined()
  })

  test("activity counts only loaded user messages and actual tool parts", () => {
    const messages = [
      { id: "user", type: "user" },
      { id: "assistant", type: "assistant", content: [
        { type: "text", text: "hello" },
        ...["completed", "running", "streaming", "error"].map(status => ({ type: "tool", state: { status } })),
      ] },
    ] as unknown as SessionMessageInfo[]
    expect(activity(messages)).toEqual({ prompts: 1, completed: 1, running: 2 })
  })

  test("color options reject invalid values and quota warnings have precise boundaries", () => {
    expect(colorOption("#5394ee", "#ffffff")).toBe("#5394ee")
    expect(colorOption("invalid", "#ffffff")).toBe("#ffffff")
    expect(styleColor(undefined, "#ffffff")).toBe("#ffffff")
    expect(quotaBand(10)).toBe("critical")
    expect(quotaBand(11)).toBe("warning")
    expect(quotaBand(25)).toBe("warning")
    expect(quotaBand(26)).toBe("positive")
  })
})
