local binds = {}
local config_updates = {}
local event_handlers = {}
local executed_commands = {}
local angle_updates = {}
local monitors = {}
local dispatched = {}
local active_window = nil
local windows = {}

local config_values = {
	["animations.enabled"] = true,
	["decoration.shadow.enabled"] = true,
	["decoration.blur.enabled"] = false,
	["decoration.motion_blur.enabled"] = true,
	["decoration.glow.enabled"] = true,
	["decoration.rounding"] = 12,
}

package.loaded["modules.layouts"] = {
	prepare_spatial_tile = function() end,
}

local function dispatcher(kind)
	return function(spec)
		return { kind = kind, spec = spec }
	end
end

local function apply_config(spec)
	if spec.animations and spec.animations.enabled ~= nil then
		config_values["animations.enabled"] = spec.animations.enabled
	end

	for _, name in ipairs({ "shadow", "blur", "motion_blur", "glow" }) do
		local decoration = spec.decoration and spec.decoration[name]
		if decoration and decoration.enabled ~= nil then
			config_values["decoration." .. name .. ".enabled"] = decoration.enabled
		end
	end

	if spec.decoration and spec.decoration.rounding ~= nil then
		config_values["decoration.rounding"] = spec.decoration.rounding
	end
end

_G.hl = {
	animation = function(spec)
		if spec.leaf == "borderangle" or spec.leaf == "glowangle" then
			angle_updates[#angle_updates + 1] = spec
		end
	end,
	bind = function(keys, action, opts)
		binds[keys] = { action = action, opts = opts }
	end,
	config = function(spec)
		config_updates[#config_updates + 1] = spec
		apply_config(spec)
	end,
	curve = function() end,
	dispatch = function(action)
		dispatched[#dispatched + 1] = action
	end,
	dsp = {
		exec_cmd = dispatcher("exec"),
		focus = dispatcher("focus"),
		force_renderer_reload = dispatcher("reload-renderer"),
		layout = dispatcher("layout"),
		window = {
			center = dispatcher("center"),
			close = dispatcher("close"),
			cycle_next = dispatcher("cycle-next"),
			drag = dispatcher("drag"),
			float = dispatcher("float"),
			fullscreen = dispatcher("fullscreen"),
			kill = dispatcher("kill"),
			move = dispatcher("move"),
			resize = dispatcher("resize"),
			swap = dispatcher("swap"),
		},
		workspace = {
			toggle_special = dispatcher("toggle-special"),
		},
	},
	exec_cmd = function(command)
		executed_commands[#executed_commands + 1] = command
	end,
	get_active_window = function()
		return active_window
	end,
	get_config = function(key)
		return config_values[key]
	end,
	get_monitors = function()
		return monitors
	end,
	get_windows = function(filters)
		assert(filters.floating == not active_window.floating, "queried only the opposite focus layer")
		assert(filters.mapped == true, "queried only mapped windows")
		assert(filters.workspace == active_window.workspace, "queried the active workspace")
		return windows
	end,
	on = function(event, callback)
		event_handlers[event] = callback
	end,
}

require("modules.binds")

config_updates = {}
angle_updates = {}

assert(not binds["SUPER + mouse_up"], "reserved Super-modified touchpad motion for the brightness plugin")
assert(not binds["SUPER + mouse_down"], "reserved Super-modified touchpad motion for the brightness plugin")

local tab = assert(binds["SUPER + Tab"], "registered the context-sensitive Tab bind").action
local shift_tab = assert(binds["SHIFT + SUPER + Tab"], "registered the focus-layer toggle").action
local workspace = { id = 3 }

active_window = { floating = false, workspace = workspace }
tab()
assert(dispatched[#dispatched].kind == "layout", "rolled the tiled layout with Super+Tab")
assert(dispatched[#dispatched].spec == "rollnext", "rolled the tiled layout forward")

active_window = {
	floating = true,
	workspace = workspace,
	at = { x = 100, y = 100 },
	size = { x = 100, y = 100 },
}
tab()
assert(dispatched[#dispatched].kind == "cycle-next", "cycled floating windows with Super+Tab")
assert(dispatched[#dispatched].spec.floating == true, "limited the cycle to floating windows")

local far_tiled = {
	floating = false,
	visible = true,
	at = { x = 500, y = 500 },
	size = { x = 100, y = 100 },
}
local hidden_tiled = {
	floating = false,
	visible = false,
	at = { x = 100, y = 100 },
	size = { x = 100, y = 100 },
}
local near_tiled = {
	floating = false,
	visible = true,
	at = { x = 125, y = 125 },
	size = { x = 100, y = 100 },
}
windows = { far_tiled, hidden_tiled, near_tiled }
shift_tab()
assert(dispatched[#dispatched].kind == "focus", "focused a tiled window with Super+Shift+Tab")
assert(dispatched[#dispatched].spec.window == near_tiled, "focused the nearest visible tiled window")

local far_floating = {
	floating = true,
	visible = true,
	at = { x = 600, y = 600 },
	size = { x = 100, y = 100 },
}
local near_floating = {
	floating = true,
	visible = true,
	at = { x = 175, y = 175 },
	size = { x = 100, y = 100 },
}
active_window = {
	floating = false,
	workspace = workspace,
	at = { x = 100, y = 100 },
	size = { x = 100, y = 100 },
}
windows = { far_floating, near_floating }
shift_tab()
assert(dispatched[#dispatched].kind == "focus", "focused a floating window with Super+Shift+Tab")
assert(dispatched[#dispatched].spec.window == near_floating, "focused the nearest visible floating window")

local toggle = assert(binds["SUPER + SHIFT + G"], "registered the performance-mode bind").action
for _, event in ipairs({
	"workspace.active",
	"monitor.layout_changed",
	"window.open",
	"window.destroy",
	"window.move_to_workspace",
	"config.reloaded",
}) do
	assert(event_handlers[event], "registered performance synchronization for " .. event)
end

local steam = { name = "steam", windows = 0 }
monitors = { { active_workspace = steam } }

event_handlers["workspace.active"]()
assert(#config_updates == 0, "ignored an empty Steam workspace")

steam.windows = 1
event_handlers["window.open"]()
assert(#config_updates == 1, "enabled performance mode for an occupied Steam workspace")
assert(config_values["animations.enabled"] == false, "disabled animations")
assert(config_values["decoration.blur.enabled"] == false, "disabled blur")
assert(config_values["decoration.rounding"] == 0, "disabled rounding")
assert(#angle_updates == 2 and angle_updates[1].enabled == false and angle_updates[2].enabled == false, "disabled angle loops")

steam.windows = 0
event_handlers["window.destroy"]()
assert(#config_updates == 2, "restored settings after the Steam workspace emptied")
assert(config_values["animations.enabled"] == true, "restored animations")
assert(config_values["decoration.blur.enabled"] == false, "preserved a pre-existing blur override")
assert(config_values["decoration.rounding"] == 12, "restored the captured rounding")
assert(angle_updates[3].enabled == true and angle_updates[4].enabled == true, "restored angle loops")

steam.windows = 1
event_handlers["window.open"]()
toggle()
assert(config_values["animations.enabled"] == true, "manually disabled automatic performance mode")
local update_count = #config_updates
event_handlers["monitor.layout_changed"]()
assert(#config_updates == update_count, "kept automation suppressed during the current Steam session")

monitors[1].active_workspace = { name = "2", windows = 1 }
event_handlers["workspace.active"]()
monitors[1].active_workspace = steam
event_handlers["workspace.active"]()
assert(config_values["animations.enabled"] == false, "resumed automation for the next Steam session")

steam.windows = 0
event_handlers["window.destroy"]()
toggle()
monitors[1].active_workspace = steam
steam.windows = 1
event_handlers["workspace.active"]()
assert(config_values["animations.enabled"] == false, "kept manually enabled performance mode across workspace changes")
toggle()
assert(config_values["animations.enabled"] == true, "manually disabled performance mode")

for _, command in ipairs(executed_commands) do
	assert(not command:find("hyprctl reload", 1, true), "never reloaded Hyprland to restore performance settings")
end

print("bind tests passed")
