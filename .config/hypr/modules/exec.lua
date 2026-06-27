local M = {}

M.once = {
	"dms run",
	"wl-paste --type text --watch cliphist store",
	"wl-paste --type image --watch cliphist store",
	"systemctl --user start hyprpolkitagent",
	"~/.config/hypr/scripts/weather_notification.sh",
	"~/.config/hypr/scripts/updates_notification.sh",
}

hl.on("hyprland.start", function()
	for _, command in ipairs(M.once) do
		hl.exec_cmd(command)
	end
end)

return M
