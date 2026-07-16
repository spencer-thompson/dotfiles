local programs = require("modules.programs")
local laptop_monitor = "desc:Samsung Display Corp. 0x4165"
local work_external_monitor = "desc:CSF HDMI"
local home_external_monitor = "desc:Samsung Electric Company Odyssey G75F HNTL201148"

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
		monitor = work_external_monitor,
		default = workspace == 1,
	}
end

return {
	main_monitor = work_external_monitor,
	secondary_monitor = work_external_monitor,
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
		{
			keys = "SUPER + A",
			command = "dms ipc plugins toggle realtimeWhisper",
			desc = "Toggle realtime whisper",
		},
	},
}
