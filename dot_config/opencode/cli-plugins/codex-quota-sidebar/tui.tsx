/** @jsxImportSource @opentui/solid */
import { Plugin } from "@opencode/plugin/tui"
import type { Context } from "@opencode/plugin/tui/plugin"
import { Rpc } from "@opencode/plugin"
import { createSignal, onCleanup } from "solid-js"
import { z } from "zod"

export type Usage = {
  status: string
  used?: { primary: number | null; secondary: number | null }
  reset?: { primary: string | null; secondary: string | null }
  windowMinutes?: { primary: number | null; secondary: number | null }
  plan?: string
}

const CodexUsageRpc = Rpc.define({
  id: "opencode-codex-usage",
  methods: {
    usage: {
      input: z.object({ retryCount: z.number().int().min(0).max(2).optional() }).strict(),
      output: z.unknown(),
    },
  },
  events: {},
})

function windowLabel(minutes: number | null | undefined, fallback: string) {
  if (!minutes) return fallback
  if (minutes % 1440 === 0) return `${minutes / 1440}d`
  if (minutes % 60 === 0) return `${minutes / 60}h`
  return `${minutes}m`
}

function quotaBar(percentLeft: number) {
  const fractionGlyph = ["", "▏", "▎", "▍", "▌", "▋", "▊", "▉", "█"]
  const cells = Math.max(0, Math.min(5, percentLeft / 20))
  const whole = Math.floor(cells)
  const fraction = Math.round((cells - whole) * 8)
  const partial = fraction > 0 && whole < 5 ? fractionGlyph[fraction] : ""
  const filled = whole + (partial ? 1 : 0)
  return "█".repeat(whole) + partial + "░".repeat(5 - filled)
}

export function formatQuotaRow(
  usage: Usage | undefined,
  key: "primary" | "secondary",
  fallback: string,
  failed = false,
) {
  const label = windowLabel(usage?.windowMinutes?.[key], fallback)
  const used = usage?.used?.[key]
  const reset = usage?.reset?.[key]
  if (used == null) {
    return `${label}  ░░░░░ ${"--".padStart(3)}% left / ${failed ? "unavailable" : "checking…"}`
  }
  const left = Math.max(0, Math.min(100, Math.round(100 - used)))
  return `${label}  ${quotaBar(left)} ${String(left).padStart(2)}% left / ${reset ?? "unknown"}`
}

function SidebarQuota(props: { context: Context }) {
  const { context } = props
  const [usage, setUsage] = createSignal<Usage>()
  const [failed, setFailed] = createSignal(false)
  let refreshing = false

  const refresh = async () => {
    if (refreshing) return
    refreshing = true
    try {
      const result = await context.client.rpc(CodexUsageRpc).usage({})
      setUsage(result as Usage)
      setFailed(false)
    } catch (error) {
      const detail = error instanceof Error ? error.message : String(error)
      console.error(`[personal.codex-quota-sidebar] quota RPC failed: ${detail}`)
      setFailed(true)
    } finally {
      refreshing = false
    }
  }

  void refresh()
  const timer = setInterval(() => void refresh(), 5 * 60_000)
  onCleanup(() => clearInterval(timer))

  const row = (key: "primary" | "secondary", fallback: string) => {
    return formatQuotaRow(usage(), key, fallback, failed())
  }

  return (
    <box gap={0}>
      <text fg={context.theme.text.base}>
        Codex{usage()?.plan ? ` (${usage()?.plan})` : ""}
      </text>
      <text fg={context.theme.text.base}>{row("primary", "5h")}</text>
      <text fg={context.theme.text.base}>{row("secondary", "7d")}</text>
    </box>
  )
}

export default Plugin.define({
  id: "personal.codex-quota-sidebar",
  setup(context) {
    return context.ui.slot({
      append: "sidebar.content",
      render: () => <SidebarQuota context={context} />,
    })
  },
})
