-- ~/.hammerspoon/modules/chatgpt_return_guard.lua

local M = {}

local eventtap = require("hs.eventtap")
local keycodes = require("hs.keycodes")
local application = require("hs.application")
local alert = require("hs.alert")

local event = eventtap.event

local RETURN = keycodes.map["return"]
local ABC = "com.apple.keylayout.ABC"

local guard = nil

local function is_chatgpt()
  local app = application.frontmostApplication()
  return app and app:name() == "ChatGPT"
end

local function is_abc()
  return keycodes.currentSourceID() == ABC
end

function M.start()
  if guard then
    guard:stop()
    guard = nil
  end

  guard = eventtap.new({ eventtap.event.types.keyDown }, function(e)
    if not is_chatgpt() then return false end
    if e:getKeyCode() ~= RETURN then return false end
    if not is_abc() then return false end

    local flags = e:getFlags()

    -- ABC + Cmd+Return => send plain Return to ChatGPT
    if flags.cmd and not (flags.alt or flags.ctrl or flags.shift or flags.fn) then
      return true, {
        event.newKeyEvent({}, "return", true),
        event.newKeyEvent({}, "return", false),
      }
    end

    -- ABC + plain Return => block accidental send
    if not (flags.cmd or flags.alt or flags.ctrl or flags.shift or flags.fn) then
      alert.show("Input source: ABC", 0.6)
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

return M