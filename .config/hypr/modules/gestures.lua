local MIN_RESIZE_SCALE = 0.25
local MAX_RESIZE_SCALE = 4
local MIN_WINDOW_WIDTH = 160
local MIN_WINDOW_HEIGHT = 100
local PINCH_SCALE_SENSITIVITY = 1.25
local MOVE_SENSITIVITY = 1.4
local TWIST_DEADZONE_DEGREES = 1
local TWIST_ASPECT_BIAS_PER_DEGREE = 0.02
local MAX_TWIST_ASPECT_BIAS = 0.75

local layouts = require("modules.layouts")
local resize_state = nil

local function clamp(value, minimum, maximum)
	return math.max(minimum, math.min(value, maximum))
end

local function round(value)
	if value < 0 then
		return math.ceil(value - 0.5)
	end

	return math.floor(value + 0.5)
end

local function run(command)
	return function()
		hl.exec_cmd(command)
	end
end

local function dispatch_layout(message)
	return function()
		hl.dispatch(hl.dsp.layout(message))
	end
end

local function set_active_floating(enabled)
	return function()
		local window = hl.get_active_window()

		if not window or window.floating == enabled then
			return
		end

		if not enabled then
			layouts.prepare_spatial_tile(window)
		end

		hl.dispatch(hl.dsp.window.float({
			action = enabled and "enable" or "disable",
			window = window,
		}))
	end
end

local function apply_resize(state, width_scale, height_scale, center_delta_x, center_delta_y)
	local minimum_width_scale = math.max(MIN_RESIZE_SCALE, MIN_WINDOW_WIDTH / state.width)
	local minimum_height_scale = math.max(MIN_RESIZE_SCALE, MIN_WINDOW_HEIGHT / state.height)
	local effective_width_scale = clamp(width_scale, minimum_width_scale, MAX_RESIZE_SCALE)
	local effective_height_scale = clamp(height_scale, minimum_height_scale, MAX_RESIZE_SCALE)
	local width = round(state.width * effective_width_scale)
	local height = round(state.height * effective_height_scale)
	local x = round(state.center_x + center_delta_x - width / 2)
	local y = round(state.center_y + center_delta_y - height / 2)
	local last = state.last_geometry

	if last and last.width == width and last.height == height and last.x == x and last.y == y then
		return
	end

	hl.dispatch(hl.dsp.window.resize({
		x = width,
		y = height,
		window = state.window,
	}))
	hl.dispatch(hl.dsp.window.move({
		x = x,
		y = y,
		window = state.window,
	}))

	state.last_geometry = { width = width, height = height, x = x, y = y }
end

local function start_resize()
	local window = hl.get_active_window()

	if not window or not window.floating or window.size.x <= 0 or window.size.y <= 0 then
		resize_state = nil
		return
	end

	resize_state = {
		window = window,
		width = window.size.x,
		height = window.size.y,
		center_x = window.at.x + window.size.x / 2,
		center_y = window.at.y + window.size.y / 2,
		center_delta_x = 0,
		center_delta_y = 0,
		rotation = 0,
		last_geometry = {
			x = window.at.x,
			y = window.at.y,
			width = window.size.x,
			height = window.size.y,
		},
	}
end

local function update_centered_resize(event)
	if not resize_state or not resize_state.window.floating or type(event.scale) ~= "number" then
		return
	end

	apply_resize(resize_state, event.scale, event.scale, 0, 0)
end

local function update_twist_resize(event)
	if
		not resize_state
		or not resize_state.window.floating
		or type(event.scale) ~= "number"
		or type(event.delta) ~= "table"
		or type(event.delta.x) ~= "number"
		or type(event.delta.y) ~= "number"
	then
		return
	end

	resize_state.center_delta_x = resize_state.center_delta_x + event.delta.x * MOVE_SENSITIVITY
	resize_state.center_delta_y = resize_state.center_delta_y + event.delta.y * MOVE_SENSITIVITY
	resize_state.rotation = resize_state.rotation + (type(event.rotation) == "number" and event.rotation or 0)
	local scale = 1 + (event.scale - 1) * PINCH_SCALE_SENSITIVITY

	local effective_rotation = 0
	if resize_state.rotation > TWIST_DEADZONE_DEGREES then
		effective_rotation = resize_state.rotation - TWIST_DEADZONE_DEGREES
	elseif resize_state.rotation < -TWIST_DEADZONE_DEGREES then
		effective_rotation = resize_state.rotation + TWIST_DEADZONE_DEGREES
	end

	local aspect_bias = clamp(
		effective_rotation * TWIST_ASPECT_BIAS_PER_DEGREE,
		-MAX_TWIST_ASPECT_BIAS,
		MAX_TWIST_ASPECT_BIAS
	)
	apply_resize(
		resize_state,
		scale * (1 + aspect_bias),
		scale * (1 - aspect_bias),
		resize_state.center_delta_x,
		resize_state.center_delta_y
	)
end

local function finish_resize(event)
	if resize_state and resize_state.window.floating and event.cancelled then
		apply_resize(resize_state, 1, 1, 0, 0)
	end

	resize_state = nil
end

---@type any
local centered_resize = {
	start = start_resize,
	update = update_centered_resize,
	finish = finish_resize,
}

---@type any
local twist_resize = {
	start = start_resize,
	update = update_twist_resize,
	finish = finish_resize,
}

-- Three-finger layout and floating controls.
hl.gesture({
	fingers = 3,
	direction = "left",
	action = dispatch_layout("rollprev"),
})

hl.gesture({
	fingers = 3,
	direction = "right",
	action = dispatch_layout("rollnext"),
})

hl.gesture({
	fingers = 3,
	direction = "up",
	action = set_active_floating(true),
})

hl.gesture({
	fingers = 3,
	direction = "down",
	action = set_active_floating(false),
})

hl.gesture({
	fingers = 3,
	direction = "up",
	mods = "SUPER",
	action = "fullscreen",
})

hl.gesture({
	fingers = 3,
	direction = "down",
	mods = "SUPER",
	action = "special",
	workspace_name = "special",
})

-- Four-finger shell shortcuts.
hl.gesture({
	fingers = 4,
	direction = "up",
	action = run("noctalia msg panel-toggle launcher"),
})

hl.gesture({
	fingers = 4,
	direction = "down",
	action = run("noctalia msg panel-toggle control-center notifications"),
})

-- Hold Super to move; add Shift to resize. Pinch resizing stays centered.
hl.gesture({
	fingers = 4,
	direction = "swipe",
	mods = "SUPER",
	action = "move",
})

hl.gesture({
	fingers = 4,
	direction = "swipe",
	mods = "SUPER SHIFT",
	action = "resize",
})

hl.gesture({
	fingers = 4,
	direction = "pinch",
	mods = "SUPER",
	action = centered_resize,
})

-- Unmodified four-finger pinch moves, scales, and twists the window aspect ratio.
hl.gesture({
	fingers = 4,
	direction = "pinch",
	action = twist_resize,
})
