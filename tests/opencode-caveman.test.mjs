import assert from "node:assert/strict"
import fs from "node:fs"
import test from "node:test"
import plugin from "../dot_config/opencode/plugins/caveman.js"

test("caveman injects full-mode instructions without frontmatter and disposes hook", async t => {
  t.mock.method(fs, "readFileSync", () => "---\nname: caveman\n---\nKeep technical terms exact.\n")
  let listener
  let disposed = false
  const cleanup = await plugin.setup({ session: { hook: async (name, fn) => {
    assert.equal(name, "context")
    listener = fn
    return { dispose: () => { disposed = true } }
  } } })
  const event = { system: [] }
  listener(event)
  assert.equal(event.system.length, 1)
  assert.equal(event.system[0].text, "CAVEMAN MODE ACTIVE — level: full\n\nKeep technical terms exact.\n")
  cleanup()
  assert.equal(disposed, true)
})

test("missing APM skill fails visibly instead of pretending caveman is active", async t => {
  t.mock.method(fs, "readFileSync", () => { throw new Error("ENOENT") })
  await assert.rejects(plugin.setup({ session: { hook: () => assert.fail("must not register empty instructions") } }),
    /Restore pinned skills with apm install -g --target agent-skills/)
})
