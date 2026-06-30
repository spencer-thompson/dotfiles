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

	layer("launcher", { blur = true })
	layer("launcher", { xray = false })
	layer("launcher", { dim_around = true })
	layer("waybar", { blur = true })
	layer("waybar", { xray = false })
	layer("waybar", { ignore_alpha = 0 })
	layer("swaync.*", { blur = true })
	layer("swaync.*", { xray = false })
	layer("swaync.*", { ignore_alpha = 0 })

	window("nwg-look", { float = true })
	window("nwg-look", { size = "800 500" })

	window("org.pulseaudio.pavucontrol", { float = true })
	window("org.pulseaudio.pavucontrol", { size = "800 500" })

	window("xdg-desktop-portal-gtk", { center = true })
	window("xdg-desktop-portal-gtk", { float = true })
	window("xdg-desktop-portal-gtk", { size = "900 600" })

	hl.window_rule({
		name = "screenshots",
		match = { class = "com.gabm.satty" },
		min_size = "800 500",
		border_size = 2,
		dim_around = true,
		float = true,
	})

	hl.window_rule({
		name = "special-kitty",
		match = { class = "kitty" },
		rounding = 4,
		scroll_touchpad = 2.5,
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

	workspace("name:steam", { on_created_empty = "steam" })
	if has_monitor(main_monitor) then
		workspace("name:steam", { monitor = main_monitor })
		window("steam", { monitor = main_monitor })
	end

	workspace("2", { on_created_empty = "kitty" })
	workspace("3", { on_created_empty = "kitty" })

	window("steam_app_\\d+", { fullscreen = true })
	if has_monitor(main_monitor) then
		window("steam_app_\\d+", { monitor = main_monitor })
	end

	if has_monitor(secondary_monitor) then
		workspace("name:discord", { monitor = secondary_monitor })
		window("discord", { monitor = secondary_monitor })
	end
	window("discord", { no_initial_focus = true })

	layer("^(dms)$", { no_anim = true })

	hl.window_rule({
		name = "dms-settings",
		match = {
			class = "^com\\.danklinux\\.dms$",
			title = "^Settings$",
		},
		center = true,
		float = true,
		size = "950 1400",
	})

	window("org.quickshell", { center = true })
	window("org.quickshell", { float = true })
	window("org.quickshell", { size = "900 1100" })
end

return M
