local busy = false
local lastDnd = nil
local binary = noctalia.getenv("HOME") .. "/.local/bin/audio-policy"

local function refresh()
  if busy then return end
  busy = true
  local started = noctalia.runAsync({ binary, "status", "--json" }, function(result)
    busy = false
    if result.exitCode ~= 0 then
      noctalia.state.set("error", result.stderr or "Could not read audio state")
      return
    end
    local ok, state = pcall(noctalia.json.decode, result.stdout)
    if not ok or type(state) ~= "table" then return end
    noctalia.state.set("snapshot", state)
    if state.ready then
      noctalia.runAsync({ "noctalia", "msg", "notification-dnd-status" }, function(dnd)
        if dnd.exitCode ~= 0 then return end
        local value = noctalia.string.trim(dnd.stdout)
        if value ~= "on" and value ~= "off" then return end
        if value ~= lastDnd or state.state.dnd ~= (value == "on") then
          noctalia.runAsync({ binary, "dnd", value }, function(r)
            if r.exitCode == 0 then lastDnd = value end
          end)
        end
      end)
    else
      lastDnd = nil
    end
  end)
  if not started then busy = false end
end

noctalia.state.watch("command", function(command)
  if type(command) ~= "table" then return end
  local args = { binary, command.action }
  if command.value ~= nil then table.insert(args, command.value) end
  noctalia.runAsync(args, function(result)
    noctalia.state.set("error", result.exitCode == 0 and "" or (result.stderr or "Command failed"))
    refresh()
  end)
end)

function update() refresh() end
noctalia.setUpdateInterval(2000)
refresh()
