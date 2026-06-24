-- ~/.hammerspoon/modules/30_window_layout.lua
--
-- Window layout hotkeys.

local M = {}

local hotkey = hs.hotkey
local window = hs.window

local MODS = { "ctrl", "alt" }

local function moveTo(unit)
  local win = window.focusedWindow()
  if not win then
    return
  end

  win:moveToUnit(unit)
end

function M.start()
  hotkey.bind(MODS, "H", function()
    moveTo({ x = 0, y = 0, w = 0.5, h = 1 })
  end)

  hotkey.bind(MODS, "L", function()
    moveTo({ x = 0.5, y = 0, w = 0.5, h = 1 })
  end)

  hotkey.bind(MODS, "K", function()
    moveTo({ x = 0, y = 0, w = 1, h = 0.5 })
  end)

  hotkey.bind(MODS, "J", function()
    moveTo({ x = 0, y = 0.5, w = 1, h = 0.5 })
  end)

  hotkey.bind(MODS, "F", function()
    moveTo({ x = 0, y = 0, w = 1, h = 1 })
  end)

  return M
end

return M

