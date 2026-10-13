import type { ModelInfo, SessionMessageInfo } from "@opencode/client"

export function meter(percent: number, width = 12) {
  const filled = Math.round(Math.max(0, Math.min(100, percent)) * width / 100)
  return "━".repeat(filled) + "─".repeat(width - filled)
}

export function compact(value: number) {
  return new Intl.NumberFormat("en", { notation: "compact", maximumFractionDigits: 1 }).format(value)
}

export function contextUsage(messages: readonly SessionMessageInfo[], models: readonly ModelInfo[], boundary?: string) {
  const boundaryIndex = boundary ? messages.findIndex(message => message.id === boundary) : messages.length
  if (boundaryIndex === -1) return undefined
  const visible = messages.slice(0, boundaryIndex)
  const compaction = visible.findLastIndex(message => message.type === "compaction" && message.status === "completed")
  const last = visible.slice(compaction + 1).findLast(message => message.type === "assistant" && message.tokens)
  if (last?.type !== "assistant" || !last.tokens) return undefined
  const tokens = last.tokens.input + last.tokens.output + last.tokens.reasoning + last.tokens.cache.read + last.tokens.cache.write
  if (tokens <= 0) return undefined
  const model = models.find(model => model.providerID === last.model.providerID && model.id === last.model.id)
  return { tokens, percent: model?.limit.context ? Math.round(tokens / model.limit.context * 100) : undefined }
}

export function activity(messages: readonly SessionMessageInfo[]) {
  const tools = messages.flatMap(message => message.type === "assistant" ? message.content.filter(part => part.type === "tool") : [])
  return {
    prompts: messages.filter(message => message.type === "user").length,
    completed: tools.filter(tool => tool.state.status === "completed").length,
    running: tools.filter(tool => tool.state.status === "running" || tool.state.status === "streaming").length,
  }
}

export function colorOption(value: unknown, fallback: string) {
  return typeof value === "string" && /^#[0-9a-f]{6}$/i.test(value) ? value : fallback
}
