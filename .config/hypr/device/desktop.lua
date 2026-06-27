local main_monitor = "DP-1"
local secondary_monitor = "HDMI-A-1"

return {
	main_monitor = main_monitor,
	secondary_monitor = secondary_monitor,

	monitors = {
		{
			output = main_monitor,
			mode = "3440x1440@100",
			position = "0x0",
			scale = "auto",
		},
		{
			output = secondary_monitor,
			mode = "1920x1080@60",
			position = "-1080x0",
			scale = "auto",
			transform = 1,
		},
	},

	workspaces = {
		{
			workspace = "name:vertical",
			monitor = main_monitor,
			default = true,
		},
		{
			workspace = "name:discord",
			monitor = main_monitor,
			default = false,
			on_created_empty = "discord",
		},
	},

	startup = {
		{
			command = "firefox",
			rules = { workspace = "name:vertical silent" },
		},
		{
			command = "kitty",
			rules = { workspace = "1 silent" },
		},
		"hyprctl dispatch focusmonitor DP-1",
	},

	window_rules = {
		{
			match = { class = "xdg-desktop-portal-gtk" },
			monitor = main_monitor,
		},
		{
			match = { class = "com.gabm.satty" },
			monitor = main_monitor,
		},
	},

	binds = {
		{
			keys = "SUPER + code:49",
			dispatcher = hl.dsp.focus({ workspace = "name:vertical" }),
			desc = "Vertical workspace",
		},
		{
			keys = "SUPER + SHIFT + code:49",
			command = "hyprctl dispatch movetoworkspacesilent name:vertical",
			desc = "Move to vertical workspace",
		},
	},
}
