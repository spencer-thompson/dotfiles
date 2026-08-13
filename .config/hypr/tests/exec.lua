local handlers = {}

_G.hl = {
	exec_cmd = function() end,
	on = function(event, callback)
		handlers[event] = callback
	end,
}

local startup = require("modules.exec")
local found_brightness_plugin = false

for _, command in ipairs(startup.once) do
	if command == "bash ~/.config/hypr/plugins/brightness-scroll/load.sh" then
		found_brightness_plugin = true
		break
	end
end

assert(found_brightness_plugin, "registered the live brightness-scroll plugin")
assert(handlers["hyprland.start"], "registered the startup handler")
assert(handlers["hyprland.shutdown"], "registered the shutdown handler")

print("exec tests passed")
