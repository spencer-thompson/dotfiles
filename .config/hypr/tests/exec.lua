local handlers = {}
local commands = {}

_G.hl = {
	exec_cmd = function(command)
		commands[#commands + 1] = command
	end,
	on = function(event, callback)
		handlers[event] = callback
	end,
}

local startup = require("modules.exec")
local original_execute = os.execute
os.execute = function()
	error("session callbacks must not execute blocking commands")
end

handlers["hyprland.start"]()
assert(#commands == 1, "launched one ordered bootstrap outside the compositor")
local bootstrap = commands[1]
local environment = assert(bootstrap:find("dbus-update-activation-environment", 1, true))
local import = assert(bootstrap:find("systemctl --user import-environment", 1, true))
local target = assert(bootstrap:find("systemctl --user start hyprland-session.target", 1, true))
assert(environment < import and import < target, "prepared the environment before starting session services")

for _, command in ipairs(startup.once) do
	local position = assert(bootstrap:find(command .. " &", 1, true), "launched autostart apps without waiting for exit")
	assert(position > target, "started apps after session setup")
end

handlers["hyprland.shutdown"]()
assert(commands[2] == "systemctl --user --no-block stop hyprland-session.target", "queued session shutdown without waiting")
os.execute = original_execute

print("exec tests passed")
