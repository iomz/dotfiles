-- ~/.hammerspoon/modules/00_window_layout_snapshot.lua
--
-- Window layout snapshot/recovery.
local M = {}

local settingsKey = "window-layout-snapshot"

local function windowKey(window)
  local app = window:application()
  if not app then
    return nil
  end

  return table.concat({
    app:bundleID() or app:name() or "",
    window:title() or "",
  }, "\0")
end

local function findScreenByUUID(uuid)
  for _, screen in ipairs(hs.screen.allScreens()) do
    if screen:getUUID() == uuid then
      return screen
    end
  end

  return nil
end

local function countEntries(tbl)
  local count = 0

  for _ in pairs(tbl) do
    count = count + 1
  end

  return count
end

local function saveLayout()
  local snapshot = {}

  for _, window in ipairs(hs.window.allWindows()) do
    local app = window:application()
    local screen = window:screen()
    local key = windowKey(window)

    if
      key
      and app
      and screen
      and window:isStandard()
      and not window:isMinimized()
    then
      local screenFrame = screen:frame()
      local windowFrame = window:frame()

      snapshot[key] = {
        appName = app:name(),
        bundleID = app:bundleID(),
        title = window:title(),
        screenUUID = screen:getUUID(),
        frame = {
          x = (windowFrame.x - screenFrame.x) / screenFrame.w,
          y = (windowFrame.y - screenFrame.y) / screenFrame.h,
          w = windowFrame.w / screenFrame.w,
          h = windowFrame.h / screenFrame.h,
        },
      }
    end
  end

  hs.settings.set(settingsKey, snapshot)

  hs.alert.show(
    string.format("Saved layout: %d windows", countEntries(snapshot))
  )
end

local function restoreLayout()
  local snapshot = hs.settings.get(settingsKey)

  if not snapshot then
    hs.alert.show("No saved window layout")
    return
  end

  local restored = 0
  local missingScreens = 0

  for _, window in ipairs(hs.window.allWindows()) do
    local key = windowKey(window)
    local saved = key and snapshot[key] or nil

    if saved then
      local screen = findScreenByUUID(saved.screenUUID)

      if screen then
        local screenFrame = screen:frame()

        window:setFrame({
          x = screenFrame.x + saved.frame.x * screenFrame.w,
          y = screenFrame.y + saved.frame.y * screenFrame.h,
          w = saved.frame.w * screenFrame.w,
          h = saved.frame.h * screenFrame.h,
        }, 0)

        restored = restored + 1
      else
        missingScreens = missingScreens + 1
      end
    end
  end

  local message = string.format("Restored: %d", restored)

  if missingScreens > 0 then
    message = message
      .. string.format(" / missing screens: %d", missingScreens)
  end

  hs.alert.show(message)
end

function M.start()
  hs.hotkey.bind(
    { "ctrl", "alt", "cmd" },
    "S",
    saveLayout
  )

  hs.hotkey.bind(
    { "ctrl", "alt", "cmd" },
    "R",
    restoreLayout
  )
end

return M
