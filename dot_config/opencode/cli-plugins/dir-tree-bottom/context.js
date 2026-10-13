// Adapt only the pinned tree's panel state and sidebar placement.
export function treeContext(context) {
  return {
    ...context,
    storage: {
      ...context.storage,
      memory(key, options) {
        return context.storage.memory(key, key === "dir-tree.panel"
          ? { ...options, initial: { ...options.initial, collapsed: true } }
          : options)
      },
    },
    ui: {
      ...context.ui,
      slot(options) {
        if (options.append !== "sidebar.content") return context.ui.slot(options)
        const { append, ...rest } = options
        return context.ui.slot({ ...rest, after: "sidebar.content" })
      },
    },
  }
}
