local programs = require("modules.programs")
local laptop_monitor = "desc:Samsung Display Corp. 0x4165"
local work_external_monitor = "desc:CSF HDMI"
local home_external_monitor = "desc:Samsung Electric Company Odyssey G75F HNTL201148"

local function monitor_is_connected(selector)
	local description = selector:match("^desc:(.+)$")

	for _, monitor in ipairs(hl.get_monitors()) do
		if monitor.description == description then
			return true
		end
	end

	return false
end

local external_monitor
for _, selector in ipairs({ work_external_monitor, home_external_monitor }) do
	if monitor_is_connected(selector) then
		external_monitor = selector
		break
	end
end

local main_monitor = external_monitor or laptop_monitor

local workspaces = {
	{
		workspace = "name:laptop",
		monitor = laptop_monitor,
		default = true,
	},
}

for workspace = 1, 5 do
	workspaces[#workspaces + 1] = {
		workspace = tostring(workspace),
		monitor = main_monitor,
		default = external_monitor ~= nil and workspace == 1,
	}
end

return {
	main_monitor = main_monitor,
	secondary_monitor = main_monitor,
	laptop_monitor = laptop_monitor,

	monitors = {
		{
			output = laptop_monitor,
			mode = "3840x2400@60",
			position = "0x0",
			scale = 1.5,
		},
		{
			output = work_external_monitor,
			mode = "modeline 594.00 5120 5168 5200 5280 2160 2163 2173 2250 +hsync -vsync",
			position = "-640x-2160",
			scale = 1,
		},
		{
			output = home_external_monitor,
			mode = "5120x2160@60",
			position = "2560x0",
			scale = 1.5,
		},
	},

	devices = {
		{
			name = "elan0683:00-04f3:320b-touchpad",
			sensitivity = 0.5,
			scroll_factor = 1.0,
		},
	},

	workspaces = workspaces,

	startup = {
		{
			command = programs.browser,
			rules = { workspace = "1 silent" },
		},
	},

	binds = {
		{
			keys = "SUPER + grave",
			dispatcher = hl.dsp.focus({ workspace = "name:laptop" }),
			desc = "Laptop workspace",
		},
		{
			keys = "SUPER + SHIFT + grave",
			dispatcher = hl.dsp.window.move({ workspace = "name:laptop", follow = false }),
			desc = "Move to laptop workspace",
		},
	},
}
