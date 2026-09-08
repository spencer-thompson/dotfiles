local M = {}

local session_env = table.concat({
	"DISPLAY",
	"WAYLAND_DISPLAY",
	"HYPRLAND_INSTANCE_SIGNATURE",
	"XDG_CURRENT_DESKTOP",
	"XDG_SESSION_DESKTOP",
	"XDG_SESSION_TYPE",
	"XCURSOR_THEME",
	"XCURSOR_SIZE",
	"HYPRCURSOR_THEME",
	"HYPRCURSOR_SIZE",
	"STARSHIP_CONFIG",
	"QT_AUTO_SCREEN_SCALE_FACTOR",
	"QT_WAYLAND_DISABLE_WINDOWDECORATION",
	"QT_QPA_PLATFORM",
	"QT_QPA_PLATFORMTHEME",
	"QT_QPA_PLATFORMTHEME_QT6",
	"MOZ_ENABLE_WAYLAND",
	"ELECTRON_OZONE_PLATFORM_HINT",
}, " ")

M.once = {
	"noctalia",
	"bash ~/.config/hypr/plugins/brightness-scroll/load.sh",
	"~/.config/hypr/scripts/weather_notification.sh",
	"~/.config/hypr/scripts/updates_notification.sh",
}

hl.on("hyprland.start", function()
	-- Keep environment setup ahead of autostart, without waiting in the compositor.
	local commands = {
		"dbus-update-activation-environment --systemd " .. session_env,
		"systemctl --user import-environment " .. session_env,
		"systemctl --user start hyprland-session.target",
	}

	for _, command in ipairs(M.once) do
		commands[#commands + 1] = command .. " &"
	end

	hl.exec_cmd(table.concat(commands, "\n"))
end)

hl.on("hyprland.shutdown", function()
	hl.exec_cmd("systemctl --user --no-block stop hyprland-session.target")
end)

return M
