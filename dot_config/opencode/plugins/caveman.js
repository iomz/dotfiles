import fs from "node:fs"
import path from "node:path"

const skillPath = path.join(
  process.env.HOME || "",
  ".agents/skills/caveman/SKILL.md",
)

export default {
  id: "caveman",
  async setup(ctx) {
    let body
    try {
      const skill = fs.readFileSync(skillPath, "utf8")
      body = skill.replace(/^---[\s\S]*?---\s*/, "")
    } catch (error) {
      throw new Error(`Caveman skill unavailable at ${skillPath}. Restore pinned skills with apm install -g --target agent-skills, then /reload.`, { cause: error })
    }

    const hook = await ctx.session.hook("context", (event) => {
      event.system.push({
        type: "text",
        text: `CAVEMAN MODE ACTIVE — level: full\n\n${body}`,
      })
    })
    return () => hook.dispose()
  },
}
