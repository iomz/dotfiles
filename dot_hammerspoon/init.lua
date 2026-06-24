-- ~/.hammerspoon/init.lua

hs.hotkey.bind({ "ctrl", "alt" }, "R", function()
  hs.reload()
end)

hs.alert.show("Hammerspoon loaded")

-- Modules are loaded in lexical order.
-- Prefix module filenames with numbers when startup order matters.
-- Any *.lua file under modules/ is expected to return a table with start().
local fs = hs.fs

local function start_all_modules()
  local modules_dir = hs.configdir .. "/modules"
  local module_names = {}

  for file in fs.dir(modules_dir) do
    local module_name = file:match("^(.*)%.lua$")
    if module_name then
      table.insert(module_names, module_name)
    end
  end

  table.sort(module_names)

  for _, module_name in ipairs(module_names) do
    local require_name = "modules." .. module_name

    local ok, mod = pcall(require, require_name)
    if not ok then
      hs.printf("[modules] failed to require %s: %s", require_name, mod)
      goto continue
    end

    if type(mod.start) == "function" then
      local started, err = pcall(mod.start)
      if not started then
        hs.printf("[modules] failed to start %s: %s", require_name, err)
      else
        hs.printf("[modules] started %s", require_name)
      end
    else
      hs.printf("[modules] skipped %s: no start()", require_name)
    end

    ::continue::
  end
end

start_all_modules()

