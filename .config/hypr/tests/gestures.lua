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

assert(#gestures == 11, "registered the expected gesture map")

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

local pinch = find_gesture(4, "pinch", "SUPER")
assert(type(pinch.action) == "table", "registered centered pinch resize as a live gesture")

local function assert_geometry(width, height, x, y, message, offset)
	offset = offset or 0

	local resize = dispatches[offset + 1]
	local move_window = dispatches[offset + 2]

	assert(resize and resize.kind == "resize", message .. " resized the window")
	assert(resize.spec.x == width and resize.spec.y == height, message .. " used the expected size")
	assert(move_window and move_window.kind == "move", message .. " repositioned the window")
	assert(move_window.spec.x == x and move_window.spec.y == y, message .. " used the expected position")
end

local function begin_resize()
	active_window.floating = true
	reset_effects()
	pinch.action.start({ scale = 1 })
end

local function update_resize(scale, delta_x, delta_y)
	pinch.action.update({
		scale = scale,
		delta = { x = delta_x, y = delta_y },
	})
end

begin_resize()
update_resize(1, 0, 0)
assert(#dispatches == 0, "ignored the pinch's original geometry")

update_resize(1.25, 99, -99)
assert_geometry(1000, 750, 0, 125, "centered pinch")

update_resize(1.2501, -99, 99)
assert(#dispatches == 2, "ignored a pinch update with unchanged rounded geometry")

pinch.action.finish({ cancelled = true })
assert(dispatches[3].spec.x == 800 and dispatches[3].spec.y == 600, "restored the original size after cancellation")
assert(dispatches[4].spec.x == 100 and dispatches[4].spec.y == 200, "restored the original position after cancellation")

active_window.floating = false
reset_effects()
pinch.action.start({ scale = 1.1 })
update_resize(1.25, 8, 0)
pinch.action.finish({ cancelled = false })
assert(#dispatches == 0, "left tiled windows unchanged during pinch resize")

print("gesture tests passed")
