export function quotaBand(percentLeft: number) {
  return percentLeft <= 10 ? "critical" : percentLeft <= 25 ? "warning" : "positive"
}

export function styleColor(value: unknown, fallback: string) {
  return typeof value === "string" && /^#[0-9a-f]{6}$/i.test(value) ? value : fallback
}
export function quotaBar(percentLeft: number, width = 12) {
  const fractionGlyph = ["", "▏", "▎", "▍", "▌", "▋", "▊", "▉", "█"]
  const cells = Math.max(0, Math.min(width, percentLeft * width / 100))
  const whole = Math.floor(cells)
  const fraction = Math.round((cells - whole) * 8)
  const partial = fraction > 0 && whole < width ? fractionGlyph[fraction] : ""
  const filled = whole + (partial ? 1 : 0)
  return "█".repeat(whole) + partial + "░".repeat(width - filled)
}
