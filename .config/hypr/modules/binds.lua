local mod = "SUPER"
local programs = require("modules.programs")

local function bind(keys, dispatcher, desc, opts)
	if type(desc) == "table" and opts == nil then
		opts = desc
		desc = nil
	end

	opts = opts or {}

	if desc and opts.desc == nil and opts.description == nil then
		opts.desc = desc
	end

	hl.bind(keys, dispatcher, opts)
end

local function exec(cmd)
	return hl.dsp.exec_cmd(cmd)
end

local function move_to_workspace(workspace)
	return hl.dsp.window.move({ workspace = workspace, follow = false })
end

local function adjust_gaps(delta)
	return function()
		local gaps_in = hl.get_config("general.gaps_in").top
		local gaps_out = hl.get_config("general.gaps_out").top

		hl.config({
			general = {
				gaps_in = math.max(0, gaps_in + delta),
				gaps_out = math.max(0, gaps_out + delta),
			},
		})
	end
end

local function toggle_performance_mode()
	local performance_mode = hl.get_config("animations.enabled") == false

	if performance_mode then
		hl.notification.create({ text = "Performance mode disabled", timeout = 2000, icon = "ok" })
		hl.exec_cmd("hyprctl reload config-only")
		return
	end

	hl.config({
		animations = {
			enabled = false,
		},
		decoration = {
			shadow = { enabled = false },
			blur = { enabled = false },
			glow = { enabled = false },
			rounding = 0,
		},
	})

	hl.notification.create({ text = "Performance mode enabled", timeout = 2000, icon = "ok" })
end

-- Hyprland utility binds
bind(mod .. " + Return", exec(programs.terminal), "Open terminal")
bind(mod .. " + Escape", exec(programs.terminal), "Open terminal")
bind(mod .. " + Q", hl.dsp.window.close(), "Close window")
bind("SHIFT + " .. mod .. " + Q", hl.dsp.window.kill(), "Force kill window")
bind(mod .. " + T", hl.dsp.window.float({ action = "toggle" }), "Toggle floating")
bind(mod .. " + SHIFT + G", toggle_performance_mode, "Toggle performance mode")
bind(mod .. " + G", hl.dsp.focus({ workspace = "name:steam" }), "Steam workspace")
bind("SHIFT + " .. mod .. " + R", hl.dsp.force_renderer_reload(), "Reload renderer")
bind(mod .. " + F", hl.dsp.window.fullscreen(0), "Toggle fullscreen")
bind(mod .. " + P", exec("hyprpicker -a"), "Pick color")
bind(
	mod .. " + E",
	exec([[wl-copy $(cut -d ';' -f1 ~/.config/hypr/scripts/*.txt | tofi | sed "s/ .*//")]]),
	"Copy symbol"
)
bind(
	"SHIFT + " .. mod .. " + C",
	exec(
		[[kill $(pgrep cava) || kitty +kitten panel --edge=background --class=cava --name=cava -o background_opacity=0 -o font_size=7 sh -c 'cava']]
	),
	"Toggle cava"
)
bind("SHIFT + " .. mod .. " + B", exec("killall -SIGUSR1 waybar"), "Reload waybar")

bind("F11", hl.dsp.window.fullscreen(0), "Toggle fullscreen")

bind(
	mod .. " + O",
	exec([[fish -c 'grim -g "$(slurp)" - | mocr | wl-copy && notify-send "Finished"']]),
	"OCR selection"
)
bind(mod .. " + SHIFT + D", hl.dsp.focus({ workspace = "name:discord" }), "Discord workspace")
bind(mod .. " + comma", adjust_gaps(2), "Increase Gaps", { repeating = true })
bind(mod .. " + period", adjust_gaps(-2), "Decrease Gaps", { repeating = true })

-- DMS
-- bind(mod .. " + N", exec("dms ipc call notifications toggle"), "Notifications")
bind(mod .. " + N", exec("noctalia msg panel-toggle control-center notifications"), "Notifications")

bind(mod .. " + SHIFT + N", exec("dms ipc call night toggle"), "Night mode")
bind(mod .. " + C", exec("noctalia msg panel-toggle control-center"), "Control center")
bind(mod .. " + SHIFT + W", exec("dms ipc call hypr toggleOverview"), "Overview")
-- bind(mod .. " + W", exec("dms ipc call wallpaper next"), "Next wallpaper")
bind(mod .. " + W", exec("noctalia msg wallpaper-next"), "Next wallpaper")
bind(mod .. " + SHIFT + W", exec("noctalia msg panel-toggle noctalia/wallhaven:browser"), "Next wallpaper")
bind(mod .. " + D", exec([[dms ipc call dash toggle ""]]), "Dash")

-- bind(mod .. " + V", exec("dms ipc call clipboard toggle"), "Clipboard")
bind(mod .. " + V", exec("noctalia msg panel-toggle clipboard"), "Clipboard")

-- bind(mod .. " + R", exec("dms ipc call spotlight toggle"), "Spotlight")
bind(mod .. " + R", exec("noctalia msg panel-toggle launcher"), "Launcher")
-- bind(
-- 	mod .. " + S",
-- 	exec(
-- 		[[dms screenshot --stdout | satty --font-family "Berkeley Mono" --filename - --output-filename ~/screenshots/satty-$(date '+%Y%m%d-%H:%M:%S').png --copy-command wl-copy]]
-- 	),
-- 	"Screenshot"
-- )
bind(mod .. " + S", exec([[noctalia msg screenshot-region]]), "Screenshot")
-- bind(mod .. " + SHIFT + S", exec("dms ipc call settings toggle"), "Settings")
bind(mod .. " + SHIFT + S", exec("noctalia msg settings-toggle"), "Settings")
-- bind(mod .. " + Backspace", exec("dms ipc call lock lock"), "Lock")
bind(mod .. " + Backspace", exec("noctalia msg session lock"), "Lock")

-- Flexible bind
bind(mod .. " + Z", exec("/home/sthom/projects/my-resume/scripts/quick_paste"), "Quick paste")

-- Mouse media keys
bind(mod .. " + mouse:274", exec("playerctl play-pause"), "Play/pause")
bind(mod .. " + mouse:275", exec("playerctl previous"), "Previous track")
bind(mod .. " + mouse:276", exec("playerctl next"), "Next track")

-- Move/resize windows with mainMod + LMB/RMB and dragging
bind(mod .. " + mouse:272", hl.dsp.window.drag(), "Move window", { mouse = true })
bind(mod .. " + mouse:273", hl.dsp.window.resize(), "Resize window", { mouse = true })

-- Special workspaces
bind("CTRL + Space", hl.dsp.workspace.toggle_special(), "Toggle scratchpad")
bind(mod .. " + Space", hl.dsp.workspace.toggle_special(), "Toggle scratchpad")
bind("SHIFT + CTRL + Space", move_to_workspace("special"), "Move to scratchpad")
bind("SHIFT + " .. mod .. " + Space", move_to_workspace("special"), "Move to scratchpad")

-- Laptop keys
bind("XF86AudioMute", exec("noctalia msg volume-mute"), "Mute audio")
bind("XF86AudioLowerVolume", exec("pactl set-sink-volume @DEFAULT_SINK@ -1%"), "Volume down", { repeating = true })
bind("XF86AudioRaiseVolume", exec("pactl set-sink-volume @DEFAULT_SINK@ +1%"), "Volume up", { repeating = true })
bind("XF86AudioPrev", exec("playerctl previous"), "Previous track")
bind("XF86AudioPlay", exec("playerctl play-pause"), "Play/pause")
bind("XF86AudioNext", exec("playerctl next"), "Next track")
-- bind("XF86MonBrightnessDown", exec([[dms ipc call brightness decrement 1 ""]]), "Brightness down", { repeating = true })
bind("XF86MonBrightnessDown", exec([[noctalia msg brightness-down]]), "Brightness down", { repeating = true })
-- bind("XF86MonBrightnessUp", exec([[dms ipc call brightness increment 1 ""]]), "Brightness up", { repeating = true })
bind("XF86MonBrightnessUp", exec([[noctalia msg brightness-up]]), "Brightness up", { repeating = true })

-- Move focus with mainMod + arrow keys
bind(mod .. " + left", hl.dsp.focus({ direction = "left" }), "Focus left")
bind(mod .. " + right", hl.dsp.focus({ direction = "right" }), "Focus right")
bind(mod .. " + up", hl.dsp.focus({ direction = "up" }), "Focus up")
bind(mod .. " + down", hl.dsp.focus({ direction = "down" }), "Focus down")

-- Vim focus binds
bind(mod .. " + h", hl.dsp.focus({ direction = "left" }), "Focus left")
bind(mod .. " + j", hl.dsp.focus({ direction = "down" }), "Focus down")
bind(mod .. " + k", hl.dsp.focus({ direction = "up" }), "Focus up")
bind(mod .. " + l", hl.dsp.focus({ direction = "right" }), "Focus right")

-- Master layout controls
bind(mod .. " + Tab", hl.dsp.layout("rollnext"), "Roll windows right")
bind("SHIFT + " .. mod .. " + Tab", hl.dsp.layout("rollprev"), "Roll windows left")
bind(mod .. " + mouse_down", hl.dsp.layout("mfact +0.01"), "Expand master")
bind(mod .. " + mouse_up", hl.dsp.layout("mfact -0.01"), "Shrink master")
bind(mod .. " + bracketleft", hl.dsp.layout("mfact -0.01"), "Shrink master", { repeating = true })
bind(mod .. " + bracketright", hl.dsp.layout("mfact +0.01"), "Expand master", { repeating = true })
bind("SHIFT + " .. mod .. " + h", hl.dsp.window.swap({ direction = "left" }), "Swap window left")
bind("SHIFT + " .. mod .. " + j", hl.dsp.window.swap({ direction = "down" }), "Swap window down")
bind("SHIFT + " .. mod .. " + k", hl.dsp.window.swap({ direction = "up" }), "Swap window up")
bind("SHIFT + " .. mod .. " + l", hl.dsp.window.swap({ direction = "right" }), "Swap window right")

-- Switch workspaces and move active windows.
for workspace = 1, 10 do
	local key = workspace % 10

	bind(mod .. " + " .. key, hl.dsp.focus({ workspace = workspace }), "Workspace " .. workspace)
	bind("SHIFT + " .. mod .. " + " .. key, move_to_workspace(workspace), "Move to workspace " .. workspace)
end
