-- ~/.hammerspoon/modules/force_abc.lua
-- Force ABC input source for selected apps and panels.

local M = {}

local application = require("hs.application")
local appwatcher = require("hs.application.watcher")
local keycodes = require("hs.keycodes")
local hotkey = require("hs.hotkey")
local eventtap = require("hs.eventtap")
local timer = require("hs.timer")
local window = require("hs.window")
local windowfilter = require("hs.window.filter")

local ABC_SOURCE_ID = "com.apple.keylayout.ABC"

local watcher = nil
local wf = nil
local emoji_hotkey = nil

local TARGET_APPS = {
  ["cmux"] = true,
}

local function force_abc()
  if keycodes.currentSourceID() ~= ABC_SOURCE_ID then
    keycodes.currentSourceID(ABC_SOURCE_ID)
  end
end

local function focused_window_app_name()
  local win = window.focusedWindow()
  if not win then
    return nil
  end

  local app = win:application()
  return app and app:name() or nil
end

local function frontmost_app_name()
  local app = application.frontmostApplication()
  return app and app:name() or nil
end

local function active_app_name()
  return focused_window_app_name() or frontmost_app_name()
end

local function should_force_for_active_app()
  local name = active_app_name()
  return name and TARGET_APPS[name] == true
end

local function check_active_app()
  if should_force_for_active_app() then
    -- Retry once shortly after focus, because input source switching can lose
    -- the race against app/window activation.
    force_abc()
    timer.doAfter(0.05, force_abc)
  end
end

local function bind_emoji_hotkey()
  emoji_hotkey = hotkey.bind({ "ctrl", "cmd" }, "space", function()
    -- Switch to ABC before opening the emoji picker.
    force_abc()

    -- Temporarily disable this hotkey to avoid recursively triggering itself.
    emoji_hotkey:disable()

    timer.doAfter(0.02, function()
      eventtap.keyStroke({ "ctrl", "cmd" }, "space", 0)

      timer.doAfter(0.1, function()
        if emoji_hotkey then
          emoji_hotkey:enable()
        end
      end)
    end)
  end)
end

function M.start()
  if watcher then
    watcher:stop()
    watcher = nil
  end

  if wf then
    wf:unsubscribeAll()
    wf = nil
  end

  if emoji_hotkey then
    emoji_hotkey:delete()
    emoji_hotkey = nil
  end

  watcher = appwatcher.new(function(_, event_type)
    if event_type == appwatcher.activated then
      timer.doAfter(0.05, check_active_app)
    end
  end)

  watcher:start()

  wf = windowfilter.default
  wf:subscribe(windowfilter.windowFocused, function()
    timer.doAfter(0.05, check_active_app)
  end)

  bind_emoji_hotkey()

  check_active_app()
end

function M.stop()
  if watcher then
    watcher:stop()
    watcher = nil
  end

  if wf then
    wf:unsubscribeAll()
    wf = nil
  end

  if emoji_hotkey then
    emoji_hotkey:delete()
    emoji_hotkey = nil
  end
end

function M.setTargetApps(apps)
  TARGET_APPS = {}

  for _, name in ipairs(apps) do
    TARGET_APPS[name] = true
  end
end

return M

