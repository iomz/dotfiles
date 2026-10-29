/** @jsxImportSource @opentui/solid */
import { Plugin } from "@opencode/plugin/tui"
import type { Context } from "@opencode/plugin/tui/plugin"
import { createEffect, createSignal, on, onCleanup, Show } from "solid-js"
import { quotaBar, quotaBand, styleColor } from "./style"
import { ResumeRpc } from "./resume-rpc.js"
import { CHATGPT_USAGE_URL } from "./quota.js"

export type Usage = {
  status: string
  code?: string
  used?: { primary: number | null; secondary: number | null }
  reset?: { primary: string | null; secondary: string | null }
  windowMinutes?: { primary: number | null; secondary: number | null }
  plan?: string
}

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

export function SidebarQuota(props: { context: Context; sessionID?: string }) {
  const { context } = props
  const [usage, setUsage] = createSignal<Usage>()
  const [failed, setFailed] = createSignal(false)
  const [resume, setResume] = createSignal("")
  const sharingQuotaUnavailable = () => usage()?.code === "token_sharing_quota_unavailable"
  createEffect(on(() => props.sessionID, sessionID => {
    if (!sessionID) return
    const location = context.data.session.get(sessionID)?.location ?? context.location ?? context.data.location.default()
    const rpc = context.client.rpc(ResumeRpc)
    let active = true
    let changed = false
    setResume("")
    const unsubscribe = rpc.events.on("changed", event => {
      if (event.data.sessionID === sessionID) {
        changed = true
        setResume(event.data.message)
      }
    })
    void rpc.status({ sessionID }, { location }).then(message => {
      if (active && !changed) setResume(message)
    }).catch(() => {})
    onCleanup(() => { active = false; unsubscribe() })
  }))
  let refreshing = false

  const refresh = async () => {
    if (refreshing) return
    refreshing = true
    try {
      const location = context.location ?? context.data.location.default()
      // Read-only usage endpoint keeps reporting both windows after one is exhausted.
      const result = await context.client.rpc(ResumeRpc).usage({}, { location })
      setUsage(result as Usage)
      setFailed((result as Usage).status !== "ok")
    } catch (error) {
      const detail = error && typeof error === "object" && "message" in error
        ? String(error.message) : String(error)
      console.error(`[personal.codex-quota-sidebar] quota RPC failed: ${detail}`)
      setUsage(undefined)
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
    <box gap={0} height={resume() && resume() !== "Codex resume: off" ? 7 : 6} flexShrink={0} overflow="hidden">
      <text height={1} wrapMode="none" truncate fg={styleColor(context.options.heading, "#5394ee")}>
        <b>Usage</b>
      </text>
      <Show when={sharingQuotaUnavailable()} fallback={<>
        <text height={1} wrapMode="none" truncate fg={context.theme.text.muted}>Codex{usage()?.plan ? ` (${usage()?.plan})` : failed() ? " (unavailable)" : " (checking…)"}</text>
        {row("primary", "5h")}
        <text height={1} wrapMode="none" truncate fg={context.theme.text.muted}>Reset: {usage()?.reset?.primary ?? (failed() ? "unavailable" : "checking…")}</text>
        {row("secondary", "7d")}
        <text height={1} wrapMode="none" truncate fg={context.theme.text.muted}>Reset: {usage()?.reset?.secondary ?? (failed() ? "unavailable" : "checking…")}</text>
      </>}>
        <text height={1} wrapMode="none" truncate fg={context.theme.text.muted}>Using ChatGPT plan</text>
        <text height={1} wrapMode="none" truncate fg={context.theme.text.muted}>Quota unavailable</text>
        <text height={1} wrapMode="none" truncate fg={context.theme.text.muted}>for this sign-in method</text>
        <text height={1} wrapMode="none" truncate fg={styleColor(context.options.heading, "#5394ee")}><a href={CHATGPT_USAGE_URL}>Manage usage</a></text>
        <text height={1} wrapMode="none" truncate fg={context.theme.text.muted}>Model access unaffected</text>
      </Show>
      <Show when={resume() && resume() !== "Codex resume: off"}>
        <text height={1} wrapMode="none" truncate fg={context.theme.text.muted}>{resume()}</text>
      </Show>
    </box>
  )
}

export default Plugin.define({
  id: "personal.codex-quota-sidebar",
  setup(context) {
    return context.client.rpc(ResumeRpc).events.on("notice", event => {
      context.ui.toast.show({ sessionID: event.data.sessionID, title: "Codex resume", message: event.data.message, duration: 8000 })
    })
  },
})
