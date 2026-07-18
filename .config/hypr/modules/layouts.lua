local workspace_states = {}
local pending_tile_centers = {}
local slave_column_fill_order = { 1, 2, 4, 3 }
local M = {}

local function clamp(value, minimum, maximum)
	return math.max(minimum, math.min(value, maximum))
end

local function target_id(target)
	if target.window and target.window.stable_id then
		return "window:" .. tostring(target.window.stable_id)
	end

	return "target:" .. tostring(target.index)
end

local function workspace_key(ctx)
	for _, target in ipairs(ctx.targets) do
		if target.window and target.window.workspace then
			return tostring(target.window.workspace.id)
		end
	end

	return string.format("area:%s:%s", ctx.area.x, ctx.area.y)
end

local function copy(values)
	local result = {}

	for index, value in ipairs(values) do
		result[index] = value
	end

	return result
end

local function adjacent_slave_index(target_count, side)
	local first_index = side == "left" and 2 or 3

	if target_count < first_index then
		return nil
	end

	local column_count = #slave_column_fill_order
	return first_index + math.floor((target_count - first_index) / column_count) * column_count
end

local function place_pending_target(state, order, id, center_x, targets_by_id)
	if #order == 0 then
		table.insert(order, id)
		return
	end

	local master = targets_by_id[order[1]]
	if not master then
		table.insert(order, id)
		return
	end

	local master_box = master.box
	local side = center_x < master_box.x + master_box.w / 2 and "left" or "right"

	table.insert(order, id)

	if #order == 2 then
		state.two_window_slave_side = side
		return
	end

	local target_index = adjacent_slave_index(#order, side)
	local added_index = #order

	if target_index and target_index ~= added_index then
		order[target_index], order[added_index] = order[added_index], order[target_index]
	end
end

local function same_members(left, right)
	if #left ~= #right then
		return false
	end

	local members = {}

	for _, value in ipairs(left) do
		members[value] = true
	end

	for _, value in ipairs(right) do
		if not members[value] then
			return false
		end
	end

	return true
end

local function sync_targets(ctx)
	local key = workspace_key(ctx)
	local state = workspace_states[key]

	if not state then
		state = {
			mfact_adjustment = 0,
			order = {},
			raw_order = {},
		}
		workspace_states[key] = state
	end

	local raw_order = {}
	local targets_by_id = {}

	for index, target in ipairs(ctx.targets) do
		local id = target_id(target)
		raw_order[index] = id
		targets_by_id[id] = target
	end

	if #state.raw_order == 0 then
		state.order = copy(raw_order)
	elseif same_members(state.raw_order, raw_order) then
		-- Hyprland's spatial swap changes the provider target order. Apply the same
		-- permutation to our visual order without discarding a prior rollnext.
		local replacements = {}

		for index, id in ipairs(state.raw_order) do
			replacements[id] = raw_order[index]
		end

		for index, id in ipairs(state.order) do
			state.order[index] = replacements[id]
		end
	else
		local previous_count = #state.order
		local present = {}
		local retained = {}
		local added = {}

		for _, id in ipairs(raw_order) do
			present[id] = true
		end

		for _, id in ipairs(state.order) do
			if present[id] then
				table.insert(retained, id)
				present[id] = nil
			end
		end

		for _, id in ipairs(raw_order) do
			if present[id] then
				table.insert(added, id)
				present[id] = nil
			end
		end

		local pending_id = #added == 1 and added[1] or nil
		local pending_center = pending_id and pending_tile_centers[pending_id] or nil

		if pending_id and pending_center then
			place_pending_target(state, retained, pending_id, pending_center, targets_by_id)
		elseif previous_count == 2 and #retained == 2 and #added == 1 then
			-- When the center master first appears, put the new window on the left
			-- so the existing right-hand window does not cross the workspace.
			table.insert(retained, 2, added[1])
		else
			for _, id in ipairs(added) do
				table.insert(retained, id)
			end
		end

		state.order = retained
	end

	if #state.order ~= 2 then
		state.two_window_slave_side = nil
	end

	for _, id in ipairs(raw_order) do
		pending_tile_centers[id] = nil
	end

	state.raw_order = copy(raw_order)

	local targets = {}

	for _, id in ipairs(state.order) do
		table.insert(targets, targets_by_id[id])
	end

	return state, targets
end

local function base_master_ratio(slave_count)
	if slave_count <= 1 then
		return 0.5
	elseif slave_count == 2 then
		return 0.4
	elseif slave_count == 3 then
		return 0.33
	end

	return 0.3
end

local function build_slave_columns(values)
	local columns = { {}, {}, {}, {} }

	for index = 2, #values do
		local fill_position = (index - 2) % #slave_column_fill_order + 1
		local column_index = slave_column_fill_order[fill_position]
		table.insert(columns[column_index], values[index])
	end

	return columns
end

local function visual_slots(target_count, two_window_slave_side)
	local slots = {}

	if target_count == 2 and two_window_slave_side == "left" then
		return { 2, 1 }
	end

	if target_count <= 2 then
		for index = 1, target_count do
			table.insert(slots, index)
		end

		return slots
	end

	local logical_indices = {}

	for index = 1, target_count do
		logical_indices[index] = index
	end

	local columns = build_slave_columns(logical_indices)

	-- Traverse physical slots from left to right and top to bottom within a stack.
	for _, column_index in ipairs({ 3, 1 }) do
		for _, logical_index in ipairs(columns[column_index]) do
			table.insert(slots, logical_index)
		end
	end

	table.insert(slots, 1)

	for _, column_index in ipairs({ 2, 4 }) do
		for _, logical_index in ipairs(columns[column_index]) do
			table.insert(slots, logical_index)
		end
	end

	return slots
end

local function roll_visual_order(state, direction)
	local slots = visual_slots(#state.order, state.two_window_slave_side)
	local occupants = {}

	for position, logical_index in ipairs(slots) do
		occupants[position] = state.order[logical_index]
	end

	if direction == "right" then
		table.insert(occupants, 1, table.remove(occupants))
	else
		table.insert(occupants, table.remove(occupants, 1))
	end

	for position, logical_index in ipairs(slots) do
		state.order[logical_index] = occupants[position]
	end
end

local function place_stack(ctx, targets, area)
	local remaining = area

	for position, target in ipairs(targets) do
		local remaining_count = #targets - position + 1

		if remaining_count == 1 then
			target:place(remaining)
		else
			local height = 1 / remaining_count
			target:place(ctx:split(remaining, "top", height))
			remaining = ctx:split(remaining, "bottom", 1 - height)
		end
	end
end

local function place_columns(ctx, columns, area)
	local active_columns = {}

	for _, column in ipairs(columns) do
		if #column > 0 then
			table.insert(active_columns, column)
		end
	end

	local remaining = area

	for position, column in ipairs(active_columns) do
		local remaining_count = #active_columns - position + 1
		local column_area = remaining

		if remaining_count > 1 then
			local width = 1 / remaining_count
			column_area = ctx:split(remaining, "left", width)
			remaining = ctx:split(remaining, "right", 1 - width)
		end

		place_stack(ctx, column, column_area)
	end
end

hl.layout.register("center_columns", {
	recalculate = function(ctx)
		local state, targets = sync_targets(ctx)
		local target_count = #targets

		if target_count == 0 then
			return
		end

		if target_count == 1 then
			targets[1]:place(ctx.area)
			return
		end

		local slave_count = target_count - 1
		local master_ratio = clamp(base_master_ratio(slave_count) + state.mfact_adjustment, 0.1, 0.9)

		if target_count == 2 then
			if state.two_window_slave_side == "left" then
				targets[2]:place(ctx:split(ctx.area, "left", 1 - master_ratio))
				targets[1]:place(ctx:split(ctx.area, "right", master_ratio))
			else
				targets[1]:place(ctx:split(ctx.area, "left", master_ratio))
				targets[2]:place(ctx:split(ctx.area, "right", 1 - master_ratio))
			end

			return
		end

		local side_ratio = (1 - master_ratio) / 2
		local left_area = ctx:split(ctx.area, "left", side_ratio)
		local right_area = ctx:split(ctx.area, "right", side_ratio)
		local center_and_right = ctx:split(ctx.area, "right", 1 - side_ratio)
		local master_area = ctx:split(center_and_right, "left", master_ratio / (1 - side_ratio))
		local columns = build_slave_columns(targets)

		targets[1]:place(master_area)
		place_columns(ctx, { columns[3], columns[1] }, left_area)
		place_columns(ctx, { columns[2], columns[4] }, right_area)
	end,
	layout_msg = function(ctx, message)
		local state, targets = sync_targets(ctx)
		local command, argument = message:match("^(%S+)%s*(.-)%s*$")

		if command == "rollnext" or command == "rollprev" then
			if #targets > 1 then
				local direction = command == "rollnext" and "right" or "left"
				roll_visual_order(state, direction)

				for _, target in ipairs(targets) do
					if target_id(target) == state.order[1] and target.window then
						hl.dispatch(hl.dsp.focus({ window = target.window }))
						break
					end
				end
			end

			return true
		end

		if command == "mfact" then
			local delta = tonumber(argument)

			if not delta then
				return nil
			end

			local base_ratio = base_master_ratio(math.max(#targets - 1, 0))
			local current_ratio = clamp(base_ratio + state.mfact_adjustment, 0.1, 0.9)
			state.mfact_adjustment = clamp(current_ratio + delta, 0.1, 0.9) - base_ratio
			return true
		end

		return nil
	end,
})

function M.prepare_spatial_tile(window)
	if not window or not window.stable_id then
		return
	end

	local position = window.at
	local size = window.size
	local id = "window:" .. tostring(window.stable_id)

	pending_tile_centers[id] = position.x + size.x / 2
end

return M
