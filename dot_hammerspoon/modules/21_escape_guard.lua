-- ~/.hammerspoon/modules/21_escape_guard.lua
-- Accidental escape guard
--
-- In AI chat apps, a stray Escape aborts a running job. Plain Escape is
-- swallowed; pressing Escape twice within DOUBLE_TAP_SECONDS forwards a single
-- real Escape, so deliberate interrupts still work.

local M = {}

local eventtap = require("hs.eventtap")
local keycodes = require("hs.keycodes")
local application = require("hs.application")
local window = require("hs.window")
local alert = require("hs.alert")
local timer = require("hs.timer")

local event = eventtap.event

local ESCAPE = keycodes.map["escape"]
local DOUBLE_TAP_SECONDS = 0.4

local TARGET_APPS = {
  ["ChatGPT Classic"] = true,
  ["ChatGPT"] = true,
  ["Claude"] = true,
  ["Antigravity"] = true,
}

local IGNORED_APPS = {
  ["Raycast"] = true,
  ["Hammerspoon"] = true,
}

local GOOGLE_JAPANESE_SOURCES = {
  ["com.google.inputmethod.Japanese.base"] = true,
  ["com.google.inputmethod.Japanese.Roman"] = true,
}

local guard = nil
local last_blocked_at = nil

local function frontmost_app_name()
  local app = application.frontmostApplication()
  return app and app:name() or nil
end

local function focused_window_app_name()
  local win = window.focusedWindow()
  if not win then
    return nil
  end

  local app = win:application()
  return app and app:name() or nil
end

local function active_app_name()
  -- Floating widgets such as Raycast can be represented more accurately by the
  -- focused window than by frontmostApplication(), so prefer focusedWindow().
  return focused_window_app_name() or frontmost_app_name()
end

local function is_ignored_app()
  local name = active_app_name()
  return name and IGNORED_APPS[name] == true
end

local function is_target_app()
  local name = active_app_name()
  return name and TARGET_APPS[name] == true
end

local function is_google_japanese()
  local source = keycodes.currentSourceID()
  return GOOGLE_JAPANESE_SOURCES[source] == true
end

local function has_no_modifiers(flags)
  return not (flags.cmd or flags.alt or flags.ctrl or flags.shift or flags.fn)
end

local function plain_escape_events()
  return {
    event.newKeyEvent({}, "escape", true),
    event.newKeyEvent({}, "escape", false),
  }
end

local function is_double_tap()
  local now = timer.secondsSinceEpoch()
  return last_blocked_at ~= nil and (now - last_blocked_at) <= DOUBLE_TAP_SECONDS
end

function M.start()
  if guard then
    guard:stop()
    guard = nil
  end

  last_blocked_at = nil

  guard = eventtap.new({ eventtap.event.types.keyDown }, function(e)
    if e:getKeyCode() ~= ESCAPE then
      return false
    end

    -- Do nothing in ignored apps such as Raycast.
    if is_ignored_app() then
      return false
    end

    -- Only guard Escape in AI chat apps.
    if not is_target_app() then
      return false
    end

    local flags = e:getFlags()

    -- Modified Escape passes through untouched.
    if not has_no_modifiers(flags) then
      return false
    end

    -- Keep plain Escape available for Japanese composition cancellation.
    if is_google_japanese() then
      return false
    end

    -- Second Escape in quick succession => forward one real Escape.
    if is_double_tap() then
      last_blocked_at = nil
      return true, plain_escape_events()
    end

    last_blocked_at = timer.secondsSinceEpoch()
    alert.show("Blocked Escape: press Escape twice to stop", 0.6)
    return true
  end)

  guard:start()
end

function M.stop()
  if guard then
    guard:stop()
    guard = nil
  end

  last_blocked_at = nil
end

function M.setTargetApps(apps)
  TARGET_APPS = {}

  for _, name in ipairs(apps) do
    TARGET_APPS[name] = true
  end
end

return M
