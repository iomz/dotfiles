-- ~/.hammerspoon/init.lua

hs.hotkey.bind({"ctrl", "alt"}, "R", function()
  hs.reload()
end)

hs.alert.show("Hammerspoon loaded")

local function moveTo(unit)
  local win = hs.window.focusedWindow()
  if not win then return end
  win:moveToUnit(unit)
end

-- Window layout
hs.hotkey.bind({"ctrl", "alt"}, "H", function()
  moveTo({x = 0, y = 0, w = 0.5, h = 1})
end)

hs.hotkey.bind({"ctrl", "alt"}, "L", function()
  moveTo({x = 0.5, y = 0, w = 0.5, h = 1})
end)

hs.hotkey.bind({"ctrl", "alt"}, "K", function()
  moveTo({x = 0, y = 0, w = 1, h = 0.5})
end)

hs.hotkey.bind({"ctrl", "alt"}, "J", function()
  moveTo({x = 0, y = 0.5, w = 1, h = 0.5})
end)

hs.hotkey.bind({"ctrl", "alt"}, "F", function()
  moveTo({x = 0, y = 0, w = 1, h = 1})
end)

-- Accidental return guard
require("modules.return_guard").start()

-- Force ABC input source for selected apps and panels.
require("modules.force_abc").start()

-- Debug focused accessibility element.
hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "I", function()
  local inspect = require("hs.inspect")
  local ax = require("hs.axuielement")

  local app = hs.application.frontmostApplication()
  local sys = ax.systemWideElement()
  local el = sys and sys:attributeValue("AXFocusedUIElement")

  print("=== DEBUG ===")
  print("app:", app and app:name())

  if not el then
    print("no focused element")
    return
  end

  local ok_role, role = pcall(function()
    return el:attributeValue("AXRole")
  end)

  local ok_subrole, subrole = pcall(function()
    return el:attributeValue("AXSubrole")
  end)

  local ok_title, title = pcall(function()
    return el:attributeValue("AXTitle")
  end)

  local ok_desc, desc = pcall(function()
    return el:attributeValue("AXDescription")
  end)

  local ok_value, value = pcall(function()
    return el:attributeValue("AXValue")
  end)

  print("role:", ok_role and role or "<unavailable>")
  print("subrole:", ok_subrole and subrole or "<unavailable>")
  print("title:", ok_title and title or "<unavailable>")
  print("description:", ok_desc and desc or "<unavailable>")

  if ok_value then
    print("value:", value)
  else
    print("value: <unavailable>")
  end

  local ok_all, attrs = pcall(function()
    return el:allAttributeValues()
  end)

  if ok_all then
    print(inspect(attrs))
  else
    print("allAttributeValues: <unavailable>")
  end
end)

