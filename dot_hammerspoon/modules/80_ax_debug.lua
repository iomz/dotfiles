-- ~/.hammerspoon/modules/80_ax_debug.lua
--
-- Debug focused accessibility element.

local M = {}

local hotkey = hs.hotkey
local application = hs.application
local inspect = require("hs.inspect")
local ax = require("hs.axuielement")

local MODS = { "cmd", "alt", "ctrl" }

local function safeAttributeValue(el, name)
  local ok, value = pcall(function()
    return el:attributeValue(name)
  end)

  if ok then
    return value
  end

  return "<unavailable>"
end

local function debugFocusedAccessibilityElement()
  local app = application.frontmostApplication()
  local sys = ax.systemWideElement()
  local el = sys and sys:attributeValue("AXFocusedUIElement")

  print("=== DEBUG ===")
  print("app:", app and app:name())

  if not el then
    print("no focused element")
    return
  end

  print("role:", safeAttributeValue(el, "AXRole"))
  print("subrole:", safeAttributeValue(el, "AXSubrole"))
  print("title:", safeAttributeValue(el, "AXTitle"))
  print("description:", safeAttributeValue(el, "AXDescription"))
  print("value:", safeAttributeValue(el, "AXValue"))

  local ok_all, attrs = pcall(function()
    return el:allAttributeValues()
  end)

  if ok_all then
    print(inspect(attrs))
  else
    print("allAttributeValues: <unavailable>")
  end
end

function M.start()
  hotkey.bind(MODS, "I", debugFocusedAccessibilityElement)
  return M
end

return M

