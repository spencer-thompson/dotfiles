local programs = require("modules.programs")
local laptop_monitor = "eDP-1"
local mirrored_monitor = "HDMI-A-1"

return {
	main_monitor = laptop_monitor,
	secondary_monitor = laptop_monitor,
	laptop_monitor = laptop_monitor,

	monitors = {
		{
			output = laptop_monitor,
			mode = "2560x1440@165",
			position = "0x0",
			scale = 1,
		},
		{
			output = mirrored_monitor,
			mode = "preferred",
			position = "auto",
			scale = 1,
			mirror = laptop_monitor,
		},
	},

	devices = {
		{
			name = "1a582014:00-06cb:cda3-touchpad",
			sensitivity = 0.4,
			scroll_factor = 0.7,
		},
	},

	startup = {
		programs.browser,
		{
			command = programs.terminal,
			rules = { workspace = "2 silent" },
		},
	},
}
