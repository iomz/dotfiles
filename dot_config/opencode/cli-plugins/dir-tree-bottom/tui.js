import { existsSync } from "node:fs"
import { treeContext } from "./context.js"

export default {
  id: "opencode-dir-tree-tui",
  async setup(context) {
    // Chezmoi writes sources before its dependency hook. A live TUI may reload
    // during that gap, or while npm ci replaces node_modules.
    const entry = new URL("./node_modules/opencode-dir-tree-tui/dist/tui.js", import.meta.url)
    for (let attempt = 0; !existsSync(entry) && attempt < 60; attempt++) {
      await new Promise(resolve => setTimeout(resolve, 500))
    }
    if (!existsSync(entry)) throw new Error("Dir Tree dependencies missing; run chezmoi apply to install them")
    const { default: tree } = await import(entry.href)
    return tree.setup(treeContext(context))
  },
}
