/** @jsxImportSource @opentui/solid */
import { Plugin } from "@opencode/plugin/tui"
import type { Context } from "@opencode/plugin/tui/context"
import { createMemo, Show } from "solid-js"
import { activity, colorOption, compact, contextUsage, meter } from "./metrics"
import { SidebarQuota } from "../codex-quota-sidebar/tui"

export function SidebarDashboard(props: { context: Context; sessionID: string }) {
  const { context } = props
  const styles = context.options.colors as Record<string, unknown> | undefined
  const heading = colorOption(styles?.heading, "#5394ee")
  const muted = colorOption(styles?.muted, "#a6b2c0")
  const positive = colorOption(styles?.positive, "#32cd99")
  const warning = colorOption(styles?.warning, "#e5c07b")
  const critical = colorOption(styles?.critical, "#ff4747")
  const session = createMemo(() => context.data.session.get(props.sessionID))
  const location = () => session()?.location ?? context.data.location.default()
  const messages = createMemo(() => context.data.session.message.list(props.sessionID))
  const models = () => context.data.location.model.list(location()) ?? []
  const usage = createMemo(() => contextUsage(messages(), models(), session()?.revert?.messageID))
  const work = createMemo(() => activity(messages()))
  const children = createMemo(() => context.data.session.list().filter(child => child.parentID === props.sessionID))
  const shells = createMemo(() => context.data.shell.list(location()).filter(shell => shell.status === "running"))
  const tokens = () => session()?.tokens
  const modelName = () => models().find(model => model.id === session()?.model?.id && model.providerID === session()?.model?.providerID)?.name ?? session()?.model?.id ?? "Not selected"
  const usageColor = () => (usage()?.percent ?? 0) >= 85 ? critical : (usage()?.percent ?? 0) >= 65 ? warning : positive
  const enabled = (panel: string) => context.options[panel] !== false
  const quotaContext = { ...context, options: { heading, positive, warning, critical } }

  return (
    <box gap={1} flexShrink={0}>
      <Show when={enabled("context")}>
        <box height={3} flexShrink={0} overflow="hidden">
          <text fg={heading}><b>Context window</b></text>
          <Show when={usage()} fallback={<><text fg={muted}>Waiting for token usage</text><text fg={muted}>──────────── --%</text></>}>
            {value => <>
              <text fg={muted}>{compact(value().tokens)} tokens</text>
              <text fg={usageColor()}>{meter(value().percent ?? 0)} {value().percent ?? "--"}%</text>
            </>}
          </Show>
        </box>
      </Show>
      <Show when={enabled("usage")}><SidebarQuota context={quotaContext} sessionID={props.sessionID} /></Show>
      <Show when={enabled("session")}>
        <box height={5} flexShrink={0} overflow="hidden">
          <text fg={heading}><b>Session</b></text>
          <text height={1} wrapMode="none" truncate fg={context.data.session.status(props.sessionID) === "running" ? positive : muted}>
            {context.data.session.status(props.sessionID) === "running" ? "● working" : "○ idle"} · {session()?.agent ?? "build"}
          </text>
          <text height={1} fg={muted} wrapMode="none" truncate>{modelName()}</text>
          <text height={1} fg={muted} wrapMode="none" truncate>{session()?.model?.variant ?? "Default variant"}</text>
          <text fg={muted}>API estimate ${context.data.session.cost(props.sessionID).toFixed(3)}</text>
        </box>
      </Show>
      <Show when={enabled("tokens")}>
        <box height={5} flexShrink={0} overflow="hidden">
          <text fg={heading}><b>Tokens · session total</b></text>
          <text fg={muted}>In {compact(tokens()?.input ?? 0)} · Out {compact(tokens()?.output ?? 0)}</text>
          <text fg={muted}>Reasoning {compact(tokens()?.reasoning ?? 0)}</text>
          <text fg={muted}>Cache read {compact(tokens()?.cache.read ?? 0)}</text>
          <text fg={muted}>Cache write {compact(tokens()?.cache.write ?? 0)}</text>
        </box>
      </Show>
      <Show when={enabled("activity")}>
        <box height={3} flexShrink={0} overflow="hidden">
          <text fg={heading}><b>Activity · loaded transcript</b></text>
          <text height={1} wrapMode="none" truncate fg={muted}>{work().prompts} prompts · {work().completed} tools done</text>
          <text fg={work().running > 0 ? positive : muted}>{work().running} tools active</text>
        </box>
      </Show>
      <Show when={enabled("workers")}>
        <box height={2} flexShrink={0} overflow="hidden">
          <text fg={heading}><b>Workers</b></text>
          <text height={1} wrapMode="none" truncate fg={muted}>{children().filter(child => context.data.session.status(child.id) === "running").length} subagents · {shells().length} shells active</text>
        </box>
      </Show>
    </box>
  )
}

export function SidebarVersion(props: { context: Context }) {
  const { context } = props
  const styles = context.options.colors as Record<string, unknown> | undefined
  const muted = colorOption(styles?.muted, "#a6b2c0")
  return <text height={1} flexShrink={0} wrapMode="none" truncate fg={muted}>OpenCode v{context.app.version.replace(/^v/, "")}</text>
}

export default Plugin.define({
  id: "personal.sidebar-dashboard",
  setup(context) {
    const dashboard = context.ui.slot({
      prepend: "sidebar.content",
      render: ({ sessionID }) => <SidebarDashboard context={context} sessionID={sessionID} />,
    })
    const version = context.ui.slot({
      append: "sidebar.footer",
      render: () => <SidebarVersion context={context} />,
    })
    return () => {
      version()
      dashboard()
    }
  },
})
