local mod = "SUPER"
local terminal = "kitty"

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

local function execr(cmd)
	return hl.dsp.exec_raw(cmd)
end

local function dispatch(name, arg)
	local command = "hyprctl dispatch " .. name

	if arg ~= nil and arg ~= "" then
		command = command .. " " .. arg
	end

	return exec(command)
end

-- Hyprland utility binds
bind(mod .. " + Return", exec(terminal), "Open terminal")
bind(mod .. " + Escape", exec(terminal), "Open terminal")
bind(mod .. " + Q", hl.dsp.window.close(), "Close window")
bind("SHIFT + " .. mod .. " + Q", execr([[hyprctl -j activewindow | jq '.pid' | xargs -r kill]]), "Force kill window")
bind(mod .. " + T", hl.dsp.window.float({ action = "toggle" }), "Toggle floating")
bind(mod .. " + SHIFT + G", exec("~/.config/hypr/scripts/gamemode.sh"), "Toggle game mode")
bind(mod .. " + G", hl.dsp.focus({ workspace = "name:steam" }), "Steam workspace")
bind(mod .. " + G", execr([[fish -c "kill (pgrep swww)"]]), "Stop wallpaper daemon")
bind("SHIFT + " .. mod .. " + R", hl.dsp.force_renderer_reload(), "Reload renderer")
bind(mod .. " + F", hl.dsp.window.fullscreen(0), "Toggle fullscreen")
bind(mod .. " + P", exec("hyprpicker -a"), "Pick color")
bind(mod .. " + E", execr([[wl-copy $(cut -d ';' -f1 ~/.config/hypr/scripts/*.txt | tofi | sed "s/ .*//")]]), "Copy symbol")
bind(mod .. " + B", exec("~/.config/hypr/modules/toggleblur.sh"), "Toggle blur")
bind(
	"SHIFT + " .. mod .. " + C",
	exec([[kill $(pgrep cava) || kitty +kitten panel --edge=background --class=cava --name=cava -o background_opacity=0 -o font_size=7 sh -c 'cava']]),
	"Toggle cava"
)
bind("SHIFT + " .. mod .. " + B", exec("killall -SIGUSR1 waybar"), "Reload waybar")

bind("F11", hl.dsp.window.fullscreen(0), "Toggle fullscreen")

bind(mod .. " + O", exec([[fish -c 'grim -g "$(slurp)" - | mocr | wl-copy && notify-send "Finished"']]), "OCR selection")
bind(mod .. " + SHIFT + D", hl.dsp.focus({ workspace = "name:discord" }), "Discord workspace")

-- DMS
bind(mod .. " + N", exec("dms ipc call notifications toggle"), "Notifications")
bind(mod .. " + SHIFT + N", exec("dms ipc call night toggle"), "Night mode")
bind(mod .. " + C", exec("dms ipc call control-center toggle"), "Control center")
bind(mod .. " + SHIFT + W", exec("dms ipc call hypr toggleOverview"), "Overview")
bind(mod .. " + W", exec("dms ipc call wallpaper next"), "Next wallpaper")
bind(mod .. " + D", exec([[dms ipc call dash toggle ""]]), "Dash")
bind(mod .. " + V", exec("dms ipc call clipboard toggle"), "Clipboard")
bind(mod .. " + R", exec("dms ipc call spotlight toggle"), "Spotlight")
bind(
	mod .. " + S",
	exec([[dms screenshot --stdout | satty --font-family "Berkeley Mono" --filename - --output-filename ~/screenshots/satty-$(date '+%Y%m%d-%H:%M:%S').png --copy-command wl-copy]]),
	"Screenshot"
)
bind(mod .. " + SHIFT + S", exec("dms ipc call settings toggle"), "Settings")
bind(mod .. " + Backspace", exec("dms ipc call lock lock"), "Lock")

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
bind("SHIFT + CTRL + Space", dispatch("movetoworkspace", "special"), "Move to scratchpad")
bind("SHIFT + " .. mod .. " + Space", dispatch("movetoworkspace", "special"), "Move to scratchpad")

-- Laptop keys
bind("XF86AudioMute", exec("dms ipc call audio mute"), "Mute audio")
bind("XF86AudioLowerVolume", exec("pactl set-sink-volume 0 -1%"), "Volume down", { repeating = true })
bind("XF86AudioRaiseVolume", exec("pactl set-sink-volume 0 +1%"), "Volume up", { repeating = true })
bind("XF86AudioPrev", exec("playerctl previous"), "Previous track")
bind("XF86AudioPlay", exec("playerctl play-pause"), "Play/pause")
bind("XF86AudioNext", exec("playerctl next"), "Next track")
bind("XF86MonBrightnessDown", exec([[dms ipc call brightness decrement 1 ""]]), "Brightness down", { repeating = true })
bind("XF86MonBrightnessUp", exec([[dms ipc call brightness increment 1 ""]]), "Brightness up", { repeating = true })
bind("switch:Lid Switch", exec("sleep 1 && hyprctl dpms toggle"), "Toggle DPMS", { locked = true })

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
bind(mod .. " + Tab", hl.dsp.layout("rollnext"), "Roll master")
bind("SHIFT + " .. mod .. " + Tab", hl.dsp.layout("orientationnext"), "Rotate master")
bind(mod .. " + mouse_down", hl.dsp.layout("mfact +0.01"), "Expand master")
bind(mod .. " + mouse_up", hl.dsp.layout("mfact -0.01"), "Shrink master")
bind(mod .. " + code:34", hl.dsp.layout("mfact -0.01"), "Shrink master", { repeating = true })
bind(mod .. " + code:35", hl.dsp.layout("mfact +0.01"), "Expand master", { repeating = true })
bind("SHIFT + " .. mod .. " + h", dispatch("movewindow", "l"), "Move window left")
bind("SHIFT + " .. mod .. " + j", dispatch("movewindow", "d"), "Move window down")
bind("SHIFT + " .. mod .. " + k", dispatch("movewindow", "u"), "Move window up")
bind("SHIFT + " .. mod .. " + l", dispatch("movewindow", "r"), "Move window right")

-- Switch workspaces and move active windows.
for workspace = 1, 10 do
	local key = workspace % 10

	bind(mod .. " + " .. key, hl.dsp.focus({ workspace = workspace }), "Workspace " .. workspace)
	bind(
		"SHIFT + " .. mod .. " + " .. key,
		dispatch("movetoworkspacesilent", tostring(workspace)),
		"Move to workspace " .. workspace
	)
end
