local M = {}

local function layer(namespace, props)
	props.match = { namespace = namespace }
	hl.layer_rule(props)
end

local function window(class, props)
	props.match = { class = class }
	hl.window_rule(props)
end

local function workspace(name, props)
	props.workspace = name
	hl.workspace_rule(props)
end

local function has_monitor(monitor)
	return type(monitor) == "string" and monitor ~= ""
end

function M.setup(opts)
	opts = opts or {}

	local main_monitor = opts.main_monitor or opts.mainMonitor
	local secondary_monitor = opts.secondary_monitor or opts.secondaryMonitor

	layer("launcher", {
		blur = true,
		xray = false,
		dim_around = true,
	})

	window("nwg-look", {
		float = true,
		size = "800 500",
	})

	window("org.pulseaudio.pavucontrol", {
		float = true,
		size = "800 500",
	})

	window("xdg-desktop-portal-gtk", {
		center = true,
		float = true,
		size = "900 600",
	})

	hl.window_rule({
		name = "imv",
		match = { class = "^imv$" },
		center = true,
		float = true,
	})

	hl.window_rule({
		name = "termfilechooser",
		match = {
			class = "^kitty$",
			title = "^termfilechooser$",
		},
		center = true,
		float = true,
		size = { "(monitor_w*0.4)", "(monitor_h*0.8)" },
	})

	hl.window_rule({
		name = "screenshots",
		match = { class = "com.gabm.satty" },
		min_size = "800 500",
		border_size = 2,
		rounding = 0,
		dim_around = true,
		float = true,
	})

	hl.window_rule({
		name = "special-kitty",
		match = { class = "kitty" },
		rounding = 0,
		scroll_touchpad = 5,
	})

	hl.window_rule({
		name = "special-ghostty",
		match = { class = "com.mitchellh.ghostty" },
		rounding = 4,
		scroll_touchpad = 2.5,
	})

	hl.window_rule({
		name = "codex-pet-overlay",
		match = {
			class = "^codex-desktop$",
			title = "^Codex$",
			float = true,
		},

		pin = true,
		no_initial_focus = true,
		no_follow_mouse = true,
		decorate = false,
		no_shadow = true,
		no_blur = true,
	})

	local steam_workspace = { on_created_empty = "steam" }
	if has_monitor(main_monitor) then
		steam_workspace.monitor = main_monitor
		window("steam", { monitor = main_monitor })
	end
	workspace("name:steam", steam_workspace)

	for number = 2, 5 do
		workspace(tostring(number), { on_created_empty = "kitty" })
	end

	local steam_game = {
		name = "steam-games",
		content = "game",
		fullscreen = true,
	}
	if has_monitor(main_monitor) then
		steam_game.monitor = main_monitor
	end
	window("^steam_app_[0-9]+$", steam_game)

	local discord = { no_initial_focus = true }
	if has_monitor(secondary_monitor) then
		workspace("name:discord", { monitor = secondary_monitor })
		discord.monitor = secondary_monitor
	end
	window("discord", discord)
	window("^chromium$", { no_initial_focus = true })

	hl.layer_rule({
		name = "noctalia",
		match = {
			namespace = "^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd)$",
		},
		no_anim = true,
		ignore_alpha = 0.5,
		blur = true,
		blur_popups = true,
	})

	hl.window_rule({
		name = "noctalia-settings",
		match = { class = "dev.noctalia.Noctalia" },
		float = true,
		size = { 1080, 1280 },
	})

	window("org.quickshell", {
		center = true,
		float = true,
		size = "900 1100",
	})
end

return M
