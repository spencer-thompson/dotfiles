local gestures = {}
local dispatches = {}
local commands = {}
local prepared_window = nil
local active_window = nil

package.loaded["modules.layouts"] = {
	prepare_spatial_tile = function(window)
		prepared_window = window
	end,
}

_G.hl = {
	dispatch = function(dispatcher)
		dispatches[#dispatches + 1] = dispatcher
	end,
	dsp = {
		layout = function(message)
			return { kind = "layout", message = message }
		end,
		window = {
			float = function(spec)
				return { kind = "float", spec = spec }
			end,
			move = function(spec)
				return { kind = "move", spec = spec }
			end,
			resize = function(spec)
				return { kind = "resize", spec = spec }
			end,
		},
	},
	exec_cmd = function(command)
		commands[#commands + 1] = command
	end,
	gesture = function(spec)
		gestures[#gestures + 1] = spec
	end,
	get_active_window = function()
		return active_window
	end,
}

require("modules.gestures")

local function find_gesture(fingers, direction, mods)
	for _, gesture in ipairs(gestures) do
		if
			gesture.fingers == fingers
			and gesture.direction == direction
			and (gesture.mods or "") == (mods or "")
		then
			return gesture
		end
	end

	error(string.format("missing %d-finger %s gesture with mods %s", fingers, direction, mods or "none"))
end

local function reset_effects()
	dispatches = {}
	prepared_window = nil
end

assert(#gestures == 12, "registered the expected gesture map")

find_gesture(3, "left").action()
assert(dispatches[1].kind == "layout" and dispatches[1].message == "rollprev", "rolled the tape left")

reset_effects()
find_gesture(3, "right").action()
assert(dispatches[1].kind == "layout" and dispatches[1].message == "rollnext", "rolled the tape right")

active_window = {
	floating = false,
	at = { x = 100, y = 200 },
	size = { x = 800, y = 600 },
}
reset_effects()
find_gesture(3, "up").action()
assert(dispatches[1].kind == "float", "floated the focused window")
assert(dispatches[1].spec.action == "enable", "forced floating on")
assert(dispatches[1].spec.window == active_window, "floated the captured window")

active_window.floating = true
reset_effects()
find_gesture(3, "down").action()
assert(prepared_window == active_window, "prepared the floating window for spatial tiling")
assert(dispatches[1].kind == "float", "tiled the focused window")
assert(dispatches[1].spec.action == "disable", "forced floating off")

local fullscreen = find_gesture(3, "up", "SUPER")
assert(fullscreen.action == "fullscreen", "mapped Super plus three-finger up to fullscreen")

local special = find_gesture(3, "down", "SUPER")
assert(special.action == "special" and special.workspace_name == "special", "mapped Super plus down to scratchpad")

local move = find_gesture(4, "swipe", "SUPER")
assert(move.action == "move", "mapped Super plus four-finger swipe to native window movement")

local resize = find_gesture(4, "swipe", "SUPER SHIFT")
assert(resize.action == "resize", "mapped Super+Shift plus four-finger swipe to native window resizing")

local centered_pinch = find_gesture(4, "pinch", "SUPER")
assert(type(centered_pinch.action) == "table", "registered centered pinch resize as a live gesture")

local twist_pinch = find_gesture(4, "pinch")
assert(type(twist_pinch.action) == "table", "registered twist pinch resize as a live gesture")

local function assert_geometry(width, height, x, y, message, offset)
	offset = offset or 0

	local resize = dispatches[offset + 1]
	local move_window = dispatches[offset + 2]

	assert(resize and resize.kind == "resize", message .. " resized the window")
	assert(resize.spec.x == width and resize.spec.y == height, message .. " used the expected size")
	assert(move_window and move_window.kind == "move", message .. " repositioned the window")
	assert(move_window.spec.x == x and move_window.spec.y == y, message .. " used the expected position")
end

local function begin_resize(pinch)
	active_window.floating = true
	reset_effects()
	pinch.action.start({ scale = 1 })
end

local function update_resize(pinch, scale, delta_x, delta_y, rotation)
	pinch.action.update({
		scale = scale,
		delta = { x = delta_x, y = delta_y },
		rotation = rotation or 0,
	})
end

begin_resize(centered_pinch)
update_resize(centered_pinch, 1, 0, 0)
assert(#dispatches == 0, "ignored the pinch's original geometry")

update_resize(centered_pinch, 1.25, 99, -99)
assert_geometry(1000, 750, 0, 125, "centered pinch")

update_resize(centered_pinch, 1.2501, -99, 99)
assert(#dispatches == 2, "ignored a pinch update with unchanged rounded geometry")

centered_pinch.action.finish({ cancelled = true })
assert(dispatches[3].spec.x == 800 and dispatches[3].spec.y == 600, "restored the original size after cancellation")
assert(dispatches[4].spec.x == 100 and dispatches[4].spec.y == 200, "restored the original position after cancellation")

begin_resize(twist_pinch)
update_resize(twist_pinch, 1.2, 20, -10, 0.5)
assert_geometry(1000, 750, 28, 111, "amplified pinch inside rotation dead zone")

update_resize(twist_pinch, 1.4, -5, 30, 10.5)
assert_geometry(1440, 720, -199, 168, "clockwise twist widened and shortened", 2)

update_resize(twist_pinch, 1.4, 0, 0, -22)
assert_geometry(960, 1080, 41, -12, "counterclockwise twist narrowed and lengthened", 4)

twist_pinch.action.finish({ cancelled = true })
assert(dispatches[7].spec.x == 800 and dispatches[7].spec.y == 600, "restored twist pinch size after cancellation")
assert(dispatches[8].spec.x == 100 and dispatches[8].spec.y == 200, "restored twist pinch position after cancellation")

active_window.floating = false
reset_effects()
twist_pinch.action.start({ scale = 1.1 })
update_resize(twist_pinch, 1.25, 8, 0)
twist_pinch.action.finish({ cancelled = false })
assert(#dispatches == 0, "left tiled windows unchanged during pinch resize")

print("gesture tests passed")
