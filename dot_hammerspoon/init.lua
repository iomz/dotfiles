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
