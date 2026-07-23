-- ~/.hammerspoon/modules/return_guard.lua
-- Accidental return guard

local M = {}

local eventtap = require("hs.eventtap")
local keycodes = require("hs.keycodes")
local application = require("hs.application")
local window = require("hs.window")
local alert = require("hs.alert")
local timer = require("hs.timer")

local event = eventtap.event

local RETURN = keycodes.map["return"]
local ABC_SOURCE_ID = "com.apple.keylayout.ABC"
local INPUT_SOURCE_SETTLE_SECONDS = 0.05

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

local function has_only_cmd(flags)
  return flags.cmd and not (flags.alt or flags.ctrl or flags.shift or flags.fn)
end

local function has_no_modifiers(flags)
  return not (flags.cmd or flags.alt or flags.ctrl or flags.shift or flags.fn)
end

local function plain_return_events()
  return {
    event.newKeyEvent({}, "return", true),
    event.newKeyEvent({}, "return", false),
  }
end

local function send_plain_return_with_ime_bypass()
  local original_source = keycodes.currentSourceID()
  local target_app = application.frontmostApplication()

  if not keycodes.currentSourceID(ABC_SOURCE_ID) then
    return false
  end

  timer.doAfter(INPUT_SOURCE_SETTLE_SECONDS, function()
    local guard_was_enabled = guard and guard:isEnabled()

    if guard_was_enabled then
      guard:stop()
    end

    eventtap.keyStroke({}, "return", 0, target_app)

    if guard_was_enabled then
      guard:start()
    end

    timer.doAfter(INPUT_SOURCE_SETTLE_SECONDS, function()
      if keycodes.currentSourceID() == ABC_SOURCE_ID then
        keycodes.currentSourceID(original_source)
      end
    end)
  end)

  return true
end

function M.start()
  if guard then
    guard:stop()
    guard = nil
  end

  guard = eventtap.new({ eventtap.event.types.keyDown }, function(e)
    if e:getKeyCode() ~= RETURN then
      return false
    end

    -- Do nothing in ignored apps such as Raycast.
    if is_ignored_app() then
      return false
    end

    -- Only guard Return in AI chat apps.
    if not is_target_app() then
      return false
    end

    local flags = e:getFlags()

    -- Cmd+Return => send plain Return to the target app.
    if has_only_cmd(flags) then
      if is_google_japanese() and send_plain_return_with_ime_bypass() then
        return true
      end

      return true, plain_return_events()
    end

    -- Keep plain Return available for Japanese composition confirmation.
    if is_google_japanese() then
      return false
    end

    -- Plain Return => block accidental send.
    if has_no_modifiers(flags) then
      alert.show("Blocked Return: use Cmd+Return", 0.6)
      return true
    end

    -- Other modified Returns pass through.
    return false
  end)

  guard:start()
end

function M.stop()
  if guard then
    guard:stop()
    guard = nil
  end
end

function M.setTargetApps(apps)
  TARGET_APPS = {}

  for _, name in ipairs(apps) do
    TARGET_APPS[name] = true
  end
end

return M
