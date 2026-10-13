/** @jsxImportSource @opentui/solid */
import { Plugin } from "@opencode/plugin/tui"
import type { Context } from "@opencode/plugin/tui/plugin"
import { Rpc } from "@opencode/plugin"
import { createSignal, onCleanup } from "solid-js"
import { z } from "zod"
import { quotaBar, quotaBand, styleColor } from "./style"

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
    return `${label}  ${quotaBar(0)} ${"--".padStart(3)}% left / ${failed ? "unavailable" : "checking…"}`
  }
  const left = Math.max(0, Math.min(100, Math.round(100 - used)))
  return `${label}  ${quotaBar(left)} ${String(left).padStart(2)}% left / ${reset ?? "unknown"}`
}

export function SidebarQuota(props: { context: Context }) {
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
    const used = usage()?.used?.[key]
    if (used == null) return <text height={1} wrapMode="none" truncate fg={context.theme.text.muted}>{windowLabel(usage()?.windowMinutes?.[key], fallback)}  {quotaBar(0)} --% left</text>
    const left = Math.max(0, Math.min(100, Math.round(100 - used)))
    const band = quotaBand(left)
    const fallbackColor = band === "critical" ? "#ff4747" : band === "warning" ? "#e5c07b" : "#32cd99"
    return <text height={1} wrapMode="none" truncate fg={context.theme.text.muted}>
      {windowLabel(usage()?.windowMinutes?.[key], fallback)}{"  "}
      <span style={{ fg: styleColor(context.options[band], fallbackColor) }}>{quotaBar(left)}</span>
      <span style={{ fg: context.theme.text.base }}> {left}% left</span>
    </text>
  }

  return (
    <box gap={0} height={6} flexShrink={0} overflow="hidden">
      <text height={1} wrapMode="none" truncate fg={styleColor(context.options.heading, "#5394ee")}>
        <b>Usage</b>
      </text>
      <text height={1} wrapMode="none" truncate fg={context.theme.text.muted}>Codex{usage()?.plan ? ` (${usage()?.plan})` : " (checking…)"}</text>
      {row("primary", "5h")}
      <text height={1} wrapMode="none" truncate fg={context.theme.text.muted}>Reset: {usage()?.reset?.primary ?? (failed() ? "unavailable" : "checking…")}</text>
      {row("secondary", "7d")}
      <text height={1} wrapMode="none" truncate fg={context.theme.text.muted}>Reset: {usage()?.reset?.secondary ?? (failed() ? "unavailable" : "checking…")}</text>
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
