local registered_name
local provider
local active_window
local event_handlers = {}

_G.hl = {
	dispatch = function(dispatcher)
		active_window = dispatcher.window
	end,
	dsp = {
		focus = function(spec)
			return { window = spec.window }
		end,
	},
	get_active_window = function()
		return active_window
	end,
	layout = {
		register = function(name, value)
			registered_name = name
			provider = value
		end,
	},
	on = function(event, callback)
		event_handlers[event] = callback
	end,
}

require("modules.layouts")

assert(registered_name == "equal_columns", "registered layout name")
assert(provider, "registered layout provider")
assert(event_handlers["window.open_early"], "registered early-window handler")

local next_workspace_id = 1

local function close_enough(actual, expected, label)
	assert(math.abs(actual - expected) < 0.0001, string.format("%s: expected %.4f, got %.4f", label, expected, actual))
end

local function new_workspace()
	local workspace = {
		id = next_workspace_id,
	}
	next_workspace_id = next_workspace_id + 1

	local context = {
		area = {
			x = 0,
			y = 0,
			w = 1000,
			h = 1000,
		},
		targets = {},
	}

	local function add(id, focused)
		if focused then
			active_window = focused
		end

		local window = {
			at = { x = 0, y = 0 },
			floating = false,
			size = { x = 1000, y = 1000 },
			stable_id = id,
			workspace = workspace,
		}
		local target = {
			box = {
				x = 0,
				y = 0,
				w = 1000,
				h = 1000,
			},
			index = #context.targets + 1,
			window = window,
		}

		function target:place(box)
			self.box = {
				x = box.x,
				y = box.y,
				w = box.w,
				h = box.h,
			}
			self.window.at = { x = box.x, y = box.y }
			self.window.size = { x = box.w, y = box.h }
		end

		event_handlers["window.open_early"](window)
		table.insert(context.targets, target)
		provider.recalculate(context)
		active_window = window

		return target
	end

	return {
		add = function(_, ...)
			return add(...)
		end,
		context = context,
		recalculate = function(_)
			provider.recalculate(context)
		end,
		remove = function(_, target)
			for index, candidate in ipairs(context.targets) do
				if candidate == target then
					table.remove(context.targets, index)
					break
				end
			end

			provider.recalculate(context)
		end,
		set_active = function(_, target)
			active_window = target and target.window or nil
		end,
	}
end

local function physical_order(context)
	local targets = {}

	for _, target in ipairs(context.targets) do
		table.insert(targets, target)
	end

	table.sort(targets, function(left, right)
		if left.box.x == right.box.x then
			return left.box.y < right.box.y
		end

		return left.box.x < right.box.x
	end)

	local ids = {}

	for _, target in ipairs(targets) do
		table.insert(ids, target.window.stable_id)
	end

	return table.concat(ids, ",")
end

local equal = new_workspace()

for count = 1, 5 do
	equal:add(count)

	for _, target in ipairs(equal.context.targets) do
		close_enough(target.box.w, 1000 / count, count .. "-window width")
		close_enough(target.box.h, 1000, count .. "-window height")
	end
end

local first_split = new_workspace()
first_split:add(6)
first_split:add(7)
assert(physical_order(first_split.context) == "6,7", "first split opens right")

local adjacent = new_workspace()
local adjacent_a = adjacent:add(11)
adjacent:add(12)
adjacent:add(13, adjacent_a.window)
assert(physical_order(adjacent.context) == "13,11,12", "left-side opening")

local centered = new_workspace()
local centered_a = centered:add(21)
centered:add(22)
centered:add(23, centered_a.window)
centered:add(24, centered_a.window)
assert(physical_order(centered.context) == "23,24,21,22", "center tie opens left")

local overflow = new_workspace()
local overflow_targets = {}

for id = 31, 35 do
	overflow_targets[id] = overflow:add(id)
end

overflow_targets[36] = overflow:add(36, overflow_targets[33].window)
close_enough(overflow_targets[33].box.h, 1000, "overflow center stays tall")
close_enough(overflow_targets[32].box.h, 500, "overflow upper stack")
close_enough(overflow_targets[36].box.h, 500, "overflow lower stack")
close_enough(overflow_targets[36].box.y, 500, "overflow opens below")

overflow_targets[37] = overflow:add(37, overflow_targets[36].window)
close_enough(overflow_targets[31].box.h, 500, "overflow stack remains balanced")
close_enough(overflow_targets[36].box.h, 500, "overflow focused stack height")
close_enough(overflow_targets[37].box.h, 500, "overflow uses the shorter side column")
close_enough(overflow_targets[37].box.y, 500, "overflow remains below")

overflow:remove(overflow_targets[33])
close_enough(overflow_targets[32].box.h, 1000, "overflow promotes a new tall center")

local rolling = new_workspace()
local rolling_targets = {}

for id = 41, 44 do
	rolling_targets[id] = rolling:add(id)
end

rolling:set_active(rolling_targets[42])
provider.layout_msg(rolling.context, "rollnext")
rolling:recalculate()
assert(physical_order(rolling.context) == "44,41,42,43", "rollnext visual order")
assert(active_window == rolling_targets[41].window, "rollnext keeps focus in its slot")

provider.layout_msg(rolling.context, "rollprev")
rolling:recalculate()
assert(physical_order(rolling.context) == "41,42,43,44", "rollprev visual order")
assert(active_window == rolling_targets[42].window, "rollprev keeps focus in its slot")

local odd_mfact = new_workspace()
local odd_targets = {}

for id = 51, 53 do
	odd_targets[id] = odd_mfact:add(id)
end

odd_mfact:set_active(odd_targets[51])
provider.layout_msg(odd_mfact.context, "mfact +0.1")
odd_mfact:recalculate()
close_enough(odd_targets[51].box.w, 850 / 3, "odd left width")
close_enough(odd_targets[52].box.w, 1300 / 3, "odd center mfact")
close_enough(odd_targets[53].box.w, 850 / 3, "odd right width")

local even_mfact = new_workspace()
local even_targets = {}

for id = 61, 64 do
	even_targets[id] = even_mfact:add(id)
end

even_mfact:set_active(even_targets[64])
provider.layout_msg(even_mfact.context, "mfact +0.1")
even_mfact:recalculate()
close_enough(even_targets[64].box.w, 350, "even focused mfact")

even_mfact:set_active(even_targets[61])
even_mfact:recalculate()
close_enough(even_targets[64].box.w, 350, "even mfact stays in its slot")

provider.layout_msg(even_mfact.context, "mfact +0.01")
even_mfact:recalculate()
close_enough(even_targets[61].box.w, 360, "even mfact transfers on adjustment")

print("layout tests passed")
