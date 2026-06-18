-- ~/.hammerspoon/modules/ai_return_guard.lua

local M = {}

local eventtap = require("hs.eventtap")
local keycodes = require("hs.keycodes")
local application = require("hs.application")
local alert = require("hs.alert")

local event = eventtap.event

local RETURN = keycodes.map["return"]

local TARGET_APPS = {
  ["ChatGPT"] = true,
  ["Codex"] = true,
  ["Claude"] = true,
  ["Antigravity"] = true,
}

local guard = nil

local function frontmost_app_name()
  local app = application.frontmostApplication()
  return app and app:name() or nil
end

local function is_target_app()
  local name = frontmost_app_name()
  return name and TARGET_APPS[name] == true
end

local function has_only_cmd(flags)
  return flags.cmd and not (flags.alt or flags.ctrl or flags.shift or flags.fn)
end

local function has_no_modifiers(flags)
  return not (flags.cmd or flags.alt or flags.ctrl or flags.shift or flags.fn)
end

function M.start()
  if guard then
    guard:stop()
    guard = nil
  end

  guard = eventtap.new({ eventtap.event.types.keyDown }, function(e)
    if not is_target_app() then return false end
    if e:getKeyCode() ~= RETURN then return false end

    local flags = e:getFlags()

    -- Cmd+Return => send plain Return to the target app.
    -- This intentionally turns Cmd+Return into Return because these apps usually
    -- use Return as "send".
    if has_only_cmd(flags) then
      return true, {
        event.newKeyEvent({}, "return", true),
        event.newKeyEvent({}, "return", false),
      }
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