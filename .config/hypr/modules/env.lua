local M = {}

local env = {
	{ "HYPRCURSOR_THEME", "HyprBibataModernClassicSVG" },
	{ "HYPRCURSOR_SIZE", "24" },
	{ "XCURSOR_THEME", "HyprBibataModernClassicSVG" },
	{ "XCURSOR_SIZE", "24" },

	{ "LIBVA_DRIVER_NAME", "nvidia" },
	{ "XDG_SESSION_TYPE", "wayland" },
	{ "GBM_BACKEND", "nvidia-drm" },
	{ "__GLX_VENDOR_LIBRARY_NAME", "nvidia" },

	{ "QT_AUTO_SCREEN_SCALE_FACTOR", "1" },
	{ "QT_WAYLAND_DISABLE_WINDOWDECORATION", "1" },
	{ "QT_QPA_PLATFORM", "wayland;xcb" },
	{ "QT_QPA_PLATFORMTHEME", "gtk3" },
	{ "QT_QPA_PLATFORMTHEME_QT6", "gtk3" },

	{ "NVD_BACKEND", "direct" },
	{ "ELECTRON_OZONE_PLATFORM_HINT", "auto" },
	{ "MOZ_ENABLE_WAYLAND", "1" },
	{ "CODEX_LINUX_RENDERING_MODE", "wayland-gpu" },

	{ "XDG_CURRENT_DESKTOP", "Hyprland" },
	{ "XDG_SESSION_DESKTOP", "Hyprland" },
}

for _, item in ipairs(env) do
	hl.env(item[1], item[2])
end

return M
