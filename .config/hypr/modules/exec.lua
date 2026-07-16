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

local function start_session()
	os.execute("dbus-update-activation-environment --systemd " .. session_env)
	os.execute("systemctl --user import-environment " .. session_env)
	os.execute("systemctl --user start hyprland-session.target")
end

M.once = {
	-- "dms run",
	"noctalia",
	"wl-paste --type text --watch cliphist store",
	"wl-paste --type image --watch cliphist store",
	"~/.config/hypr/scripts/weather_notification.sh",
	"~/.config/hypr/scripts/updates_notification.sh",
}

hl.on("hyprland.start", function()
	start_session()

	for _, command in ipairs(M.once) do
		hl.exec_cmd(command)
	end
end)

hl.on("hyprland.shutdown", function()
	os.execute("systemctl --user stop hyprland-session.target && sleep 0.1")
end)

return M
