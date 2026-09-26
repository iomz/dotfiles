import fs from "node:fs"
import path from "node:path"

const skillPath = path.join(
  process.env.HOME || "",
  ".agents/skills/caveman/SKILL.md",
)

export const Caveman = async () => ({
  "experimental.chat.system.transform": async (_input, output) => {
    try {
      const skill = fs.readFileSync(skillPath, "utf8")
      const body = skill.replace(/^---[\s\S]*?---\s*/, "")
      output.system.push(
        `CAVEMAN MODE ACTIVE — level: full\n\n${body}`,
      )
    } catch (error) {
      console.error(`[caveman] Could not load ${skillPath}:`, error)
    }
  },
})
