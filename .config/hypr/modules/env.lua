local M = {}

local config_home = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")

local function read_first_line(path)
	local file = io.open(path, "r")
	if not file then
		return nil
	end

	local line = file:read("*l")
	file:close()
	return line
end

local function has_nvidia_gpu()
	for card = 0, 15 do
		local vendor = read_first_line("/sys/class/drm/card" .. card .. "/device/vendor")
		if vendor == "0x10de" then
			return true
		end
	end

	return false
end

local env = {
	{ "HYPRCURSOR_THEME", "HyprBibataModernClassicSVG" },
	{ "HYPRCURSOR_SIZE", "24" },
	{ "XCURSOR_THEME", "HyprBibataModernClassicSVG" },
	{ "XCURSOR_SIZE", "24" },

	{ "XDG_SESSION_TYPE", "wayland" },

	{ "QT_AUTO_SCREEN_SCALE_FACTOR", "1" },
	{ "QT_WAYLAND_DISABLE_WINDOWDECORATION", "1" },
	{ "QT_QPA_PLATFORM", "wayland;xcb" },
	{ "QT_QPA_PLATFORMTHEME", "qt6ct" },
	{ "QT_QPA_PLATFORMTHEME_QT6", "qt6ct" },

	{ "ELECTRON_OZONE_PLATFORM_HINT", "auto" },
	{ "MOZ_ENABLE_WAYLAND", "1" },
	{ "CODEX_LINUX_RENDERING_MODE", "wayland-gpu" },

	{ "XDG_CURRENT_DESKTOP", "Hyprland" },
	{ "XDG_SESSION_DESKTOP", "Hyprland" },
	{ "STARSHIP_CONFIG", config_home .. "/starship/starship.toml" },
}

if has_nvidia_gpu() then
	env[#env + 1] = { "LIBVA_DRIVER_NAME", "nvidia" }
	env[#env + 1] = { "GBM_BACKEND", "nvidia-drm" }
	env[#env + 1] = { "__GLX_VENDOR_LIBRARY_NAME", "nvidia" }
	env[#env + 1] = { "NVD_BACKEND", "direct" }
end

for _, item in ipairs(env) do
	hl.env(item[1], item[2])
end

return M
