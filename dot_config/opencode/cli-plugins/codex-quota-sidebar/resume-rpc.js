import { Rpc } from "@opencode/plugin"
import { z } from "zod"

export const ResumeRpc = Rpc.define({
  id: "personal.codex-resume",
  methods: {
    status: { input: z.object({ sessionID: z.string() }).strict(), output: z.string() },
    usage: { input: z.object({}).strict(), output: z.unknown() },
  },
  events: {
    changed: { schema: z.object({ sessionID: z.string(), message: z.string() }) },
    notice: { schema: z.object({ sessionID: z.string(), message: z.string() }) },
  },
})
