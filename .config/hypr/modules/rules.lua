local M = {}

local function layer(namespace, props)
	props.match = { namespace = namespace }
	hl.layer_rule(props)
end

local function window(class, props)
	props.match = { class = class }
	hl.window_rule(props)
end

local function floating(name, match, width, height, props)
	props = props or {}
	props.name = name
	props.match = match
	props.float = true
	props.center = true
	props.size = {
		("(monitor_w*%g)"):format(width / 100),
		("(monitor_h*%g)"):format(height / 100),
	}
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

	-- Ordinary work windows keep the layout's tiling. Modal dialogs are
	-- compact; named utilities use the same proportions on every display.
	floating("modal-dialogs", { modal = true }, 25, 30, { dim_around = true })
	floating("keyring-prompt", {
		class = "^([Gg]cr-prompter(-4)?|org\\.gnome\\.keyring\\.SystemPrompter|org\\.gnome\\.gcr\\.Prompter)$",
	}, 25, 30, { dim_around = true })

	layer("launcher", {
		blur = true,
		xray = false,
		dim_around = true,
	})

	floating("appearance-settings", { class = "^nwg-look$" }, 40, 70)
	floating("qt-settings", { class = "^qt[56]ct$" }, 40, 70)
	floating("audio-settings", { class = "^org\\.pulseaudio\\.pavucontrol$" }, 40, 70)
	floating("passwords-and-keys", { class = "^org\\.gnome\\.seahorse\\.Application$" }, 40, 70)
	floating("file-chooser", { class = "^xdg-desktop-portal-gtk$" }, 40, 70)
	floating("termfilechooser", { class = "^kitty$", title = "^termfilechooser$" }, 40, 70)
	floating("imv", { class = "^imv$" }, 40, 70)
	floating("screenshots", { class = "^com\\.gabm\\.satty$" }, 70, 80, { dim_around = true })

	local password_manager = "^(1[Pp]assword|com\\.1password\\.1[Pp]assword)$"
	floating("1password", { class = password_manager }, 40, 70)
	-- Quick Access is a separate transient window, not the full vault UI.
	floating("1password-quick-access", {
		class = password_manager,
		initial_title = "^.*Quick Access.*$",
	}, 25, 30)

	hl.window_rule({
		name = "special-kitty",
		match = { class = "kitty" },
		scroll_touchpad = 5,
	})

	hl.window_rule({
		name = "special-ghostty",
		match = { class = "com.mitchellh.ghostty" },
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

	window("^slack$", { workspace = "1 silent" })

	workspace("special:spotify", { on_created_empty = "spotify-launcher" })
	hl.window_rule({
		name = "spotify-scratchpad",
		match = { class = "^[Ss]potify$" },
		workspace = "special:spotify silent",
		float = true,
		center = true,
		size = { "(monitor_w*0.7)", "(monitor_h*0.7)" },
	})

	local steam_workspace = { on_created_empty = "steam" }
	local steam_client = { workspace = "10 silent" }
	if has_monitor(main_monitor) then
		steam_workspace.monitor = main_monitor
		steam_client.monitor = main_monitor
	end
	window("steam", steam_client)
	workspace("10", steam_workspace)

	for number = 2, 5 do
		workspace(tostring(number), { on_created_empty = "kitty" })
	end

	local steam_game = {
		name = "steam-games",
		workspace = "10 silent",
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

	hl.window_rule({
		name = "outrival-operator",
		match = { class = "^outrival-operator$" },
		float = true,
		center = true,
		size = { "(monitor_w*0.6)", "(monitor_h*0.7)" },
		border_size = 2,
		border_color = "rgb(ff0000)",
		no_blur = true,
		no_initial_focus = true,
		focus_on_activate = false,
		suppress_event = "maximize",
	})

	hl.layer_rule({
		name = "noctalia",
		match = {
			namespace = "^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd|window-switcher)$",
		},
		no_anim = true,
		ignore_alpha = 0.5,
		blur = true,
		blur_popups = true,
	})

	floating("noctalia-settings", { class = "^dev\\.noctalia\\.Noctalia$" }, 40, 70)
	floating("quickshell-settings", { class = "^org\\.quickshell$" }, 40, 70)
end

return M
