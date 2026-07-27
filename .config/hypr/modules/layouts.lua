local MAX_COLUMNS = 5
local MIN_COLUMN_RATIO = 0.1
local OVERFLOW_COLUMNS = { 4, 2, 5, 1 }

local workspace_states = {}
local pending_insertions = {}
local M = {}

local function clamp(value, minimum, maximum)
	return math.max(minimum, math.min(value, maximum))
end

local function window_id(window)
	if not window or not window.stable_id then
		return nil
	end

	return "window:" .. tostring(window.stable_id)
end

local function target_id(target)
	return window_id(target.window) or "target:" .. tostring(target.index)
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

local function flatten_columns(columns)
	local values = {}

	for column_index, column in ipairs(columns) do
		for row_index, id in ipairs(column) do
			table.insert(values, {
				column = column_index,
				id = id,
				row = row_index,
			})
		end
	end

	return values
end

local function flatten_ids(columns)
	local ids = {}

	for _, slot in ipairs(flatten_columns(columns)) do
		table.insert(ids, slot.id)
	end

	return ids
end

local function build_columns(ids)
	local columns = {}

	for index = 1, math.min(#ids, MAX_COLUMNS) do
		columns[index] = { ids[index] }
	end

	for index = MAX_COLUMNS + 1, #ids do
		local fill_index = (index - MAX_COLUMNS - 1) % #OVERFLOW_COLUMNS + 1
		local column_index = OVERFLOW_COLUMNS[fill_index]

		table.insert(columns[column_index], ids[index])
	end

	return columns
end

local function find_slot(columns, id)
	if not id then
		return nil, nil
	end

	for column_index, column in ipairs(columns) do
		for row_index, candidate in ipairs(column) do
			if candidate == id then
				return column_index, row_index
			end
		end
	end

	return nil, nil
end

local function shortest_column(columns, column_indices)
	local best = column_indices[1]

	for _, column_index in ipairs(column_indices) do
		if #columns[column_index] < #columns[best] then
			best = column_index
		end
	end

	return best
end

local function shortest_side_column(columns)
	return shortest_column(columns, OVERFLOW_COLUMNS)
end

local function longest_side_column(columns, minimum_size)
	local best = nil

	for _, column_index in ipairs(OVERFLOW_COLUMNS) do
		if #columns[column_index] >= minimum_size and (not best or #columns[column_index] > #columns[best]) then
			best = column_index
		end
	end

	return best
end

local function normalize_columns(columns)
	local ids = flatten_ids(columns)

	if #ids <= MAX_COLUMNS then
		return build_columns(ids)
	end

	for column_index = #columns + 1, MAX_COLUMNS do
		columns[column_index] = {}
	end

	while #columns > MAX_COLUMNS do
		local extra = table.remove(columns)

		for _, id in ipairs(extra) do
			table.insert(columns[shortest_side_column(columns)], id)
		end
	end

	if #columns[3] == 0 then
		local donor = longest_side_column(columns, 1)

		if donor then
			table.insert(columns[3], table.remove(columns[donor], 1))
		end
	end

	while #columns[3] > 1 do
		table.insert(columns[shortest_side_column(columns)], table.remove(columns[3]))
	end

	for _, column_index in ipairs(OVERFLOW_COLUMNS) do
		if #columns[column_index] == 0 then
			local donor = longest_side_column(columns, 2)

			if donor then
				table.insert(columns[column_index], table.remove(columns[donor]))
			end
		end
	end

	return columns
end

local function target_center_x(target)
	return target.box.x + target.box.w / 2
end

local function nearest_column(columns, column_indices, center_x, targets_by_id)
	local nearest = column_indices[1]
	local nearest_distance = math.huge

	for _, column_index in ipairs(column_indices) do
		local target = targets_by_id[columns[column_index][1]]

		if target then
			local distance = math.abs(target_center_x(target) - center_x)

			if distance < nearest_distance then
				nearest = column_index
				nearest_distance = distance
			end
		end
	end

	return nearest
end

local function insertion_index_for_x(columns, center_x, targets_by_id)
	for column_index, column in ipairs(columns) do
		local target = targets_by_id[column[1]]

		if target and center_x <= target_center_x(target) then
			return column_index
		end
	end

	return #columns + 1
end

local function insert_target(state, id, pending, ctx, targets_by_id)
	local columns = state.columns
	local target_count = #flatten_ids(columns)
	local anchor_column, anchor_row = find_slot(columns, pending and pending.anchor_id)

	if target_count < MAX_COLUMNS then
		local column_index = #columns + 1

		if anchor_column then
			local anchor = targets_by_id[pending.anchor_id]
			local insert_before_anchor =
				target_count > 1 and anchor and target_center_x(anchor) <= ctx.area.x + ctx.area.w / 2

			column_index = insert_before_anchor and anchor_column or anchor_column + 1
		elseif pending and pending.center_x then
			column_index = insertion_index_for_x(columns, pending.center_x, targets_by_id)
		end

		table.insert(columns, column_index, { id })
		return
	end

	state.columns = normalize_columns(columns)
	columns = state.columns

	if anchor_column then
		local candidates

		if anchor_column == 3 then
			candidates = { 2, 1 }
		elseif anchor_column < 3 then
			candidates = { anchor_column, anchor_column == 1 and 2 or 1 }
		else
			candidates = { anchor_column, anchor_column == 4 and 5 or 4 }
		end

		local column_index = shortest_column(columns, candidates)

		if column_index == anchor_column then
			table.insert(columns[column_index], anchor_row + 1, id)
		else
			table.insert(columns[column_index], id)
		end

		return
	end

	if pending and pending.center_x then
		local left_side = pending.center_x <= ctx.area.x + ctx.area.w / 2
		local candidates = left_side and { 1, 2 } or { 4, 5 }
		local column_index = nearest_column(columns, candidates, pending.center_x, targets_by_id)

		table.insert(columns[column_index], id)
		return
	end

	table.insert(columns[shortest_side_column(columns)], id)
end

local function sync_targets(ctx)
	local key = workspace_key(ctx)
	local state = workspace_states[key]

	if not state then
		state = {
			columns = {},
			mfact_adjustment = 0,
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
		state.columns = build_columns(raw_order)
	elseif same_members(state.raw_order, raw_order) then
		-- A spatial swap permutes Hyprland's target list. Mirror that
		-- permutation in the visual slots without undoing a prior roll.
		local replacements = {}

		for index, id in ipairs(state.raw_order) do
			replacements[id] = raw_order[index]
		end

		for _, slot in ipairs(flatten_columns(state.columns)) do
			state.columns[slot.column][slot.row] = replacements[slot.id]
		end
	else
		local present = {}

		for _, id in ipairs(raw_order) do
			present[id] = true
		end

		for _, column in ipairs(state.columns) do
			for row_index = #column, 1, -1 do
				if not present[column[row_index]] then
					table.remove(column, row_index)
				end
			end
		end

		state.columns = normalize_columns(state.columns)

		local retained = {}
		for _, id in ipairs(flatten_ids(state.columns)) do
			retained[id] = true
		end

		for _, id in ipairs(raw_order) do
			if not retained[id] then
				insert_target(state, id, pending_insertions[id], ctx, targets_by_id)
				retained[id] = true
			end
		end

		state.columns = normalize_columns(state.columns)
	end

	for _, id in ipairs(raw_order) do
		pending_insertions[id] = nil
	end

	state.raw_order = copy(raw_order)
	return state, targets_by_id
end

local function place_stack(column, area, targets_by_id)
	local y = area.y
	local remaining_height = area.h

	for row_index, id in ipairs(column) do
		local remaining_count = #column - row_index + 1
		local height = remaining_height / remaining_count
		local target = targets_by_id[id]

		if target then
			target:place({
				x = area.x,
				y = y,
				w = area.w,
				h = height,
			})
		end

		y = y + height
		remaining_height = remaining_height - height
	end
end

local function mfact_column(state)
	local column_count = #state.columns

	if column_count % 2 == 1 then
		return (column_count + 1) / 2
	end

	return clamp(state.mfact_column or math.floor(column_count / 2), 1, column_count)
end

local function column_ratios(state)
	local column_count = #state.columns

	if column_count <= 1 then
		return { 1 }
	end

	local base_ratio = 1 / column_count
	local target_column = mfact_column(state)
	local maximum_ratio = 1 - (column_count - 1) * MIN_COLUMN_RATIO
	local target_ratio = clamp(base_ratio + state.mfact_adjustment, MIN_COLUMN_RATIO, maximum_ratio)
	local other_ratio = (1 - target_ratio) / (column_count - 1)
	local ratios = {}

	for column_index = 1, column_count do
		ratios[column_index] = column_index == target_column and target_ratio or other_ratio
	end

	return ratios
end

local function place_columns(state, ctx, targets_by_id)
	local ratios = column_ratios(state)
	local x = ctx.area.x
	local remaining_width = ctx.area.w

	for column_index, column in ipairs(state.columns) do
		local width = column_index == #state.columns and remaining_width or ctx.area.w * ratios[column_index]

		place_stack(column, {
			x = x,
			y = ctx.area.y,
			w = width,
			h = ctx.area.h,
		}, targets_by_id)

		x = x + width
		remaining_width = remaining_width - width
	end
end

local function roll_columns(state, direction, focused_id)
	local slots = flatten_columns(state.columns)
	local occupants = {}
	local focused_position = nil

	for position, slot in ipairs(slots) do
		occupants[position] = slot.id

		if slot.id == focused_id then
			focused_position = position
		end
	end

	if direction == "right" then
		table.insert(occupants, 1, table.remove(occupants))
	else
		table.insert(occupants, table.remove(occupants, 1))
	end

	for position, slot in ipairs(slots) do
		state.columns[slot.column][slot.row] = occupants[position]
	end

	if not focused_position then
		local center_column = math.floor((#state.columns + 1) / 2)

		for position, slot in ipairs(slots) do
			if slot.column == center_column then
				focused_position = position
				break
			end
		end
	end

	return focused_position and occupants[focused_position] or nil
end

local function same_workspace(left, right)
	return left and right and left.workspace and right.workspace and left.workspace.id == right.workspace.id
end

hl.on("window.open_early", function(window)
	if not window or window.floating then
		return
	end

	local id = window_id(window)
	local focused = hl.get_active_window()

	if not id or not same_workspace(window, focused) then
		return
	end

	if focused.floating then
		pending_insertions[id] = {
			center_x = focused.at.x + focused.size.x / 2,
		}
	else
		pending_insertions[id] = {
			anchor_id = window_id(focused),
		}
	end
end)

hl.layout.register("equal_columns", {
	recalculate = function(ctx)
		local state, targets_by_id = sync_targets(ctx)

		if #state.columns == 0 then
			return
		end

		place_columns(state, ctx, targets_by_id)
	end,
	layout_msg = function(ctx, message)
		local state, targets_by_id = sync_targets(ctx)
		local command, argument = message:match("^(%S+)%s*(.-)%s*$")

		if command == "rollnext" or command == "rollprev" then
			if #flatten_ids(state.columns) > 1 then
				local direction = command == "rollnext" and "right" or "left"
				local focus_id = roll_columns(state, direction, window_id(hl.get_active_window()))
				local target = focus_id and targets_by_id[focus_id]

				if target and target.window then
					hl.dispatch(hl.dsp.focus({ window = target.window }))
				end
			end

			return true
		end

		if command == "mfact" then
			local delta = tonumber(argument)
			local column_count = #state.columns

			if not delta then
				return nil
			end

			if column_count <= 1 then
				return true
			end

			if column_count % 2 == 1 then
				state.mfact_column = (column_count + 1) / 2
			else
				local focused_column = find_slot(state.columns, window_id(hl.get_active_window()))

				if not focused_column then
					return true
				end

				state.mfact_column = focused_column
			end

			local base_ratio = 1 / column_count
			local maximum_ratio = 1 - (column_count - 1) * MIN_COLUMN_RATIO
			local current_ratio = clamp(base_ratio + state.mfact_adjustment, MIN_COLUMN_RATIO, maximum_ratio)

			state.mfact_adjustment = clamp(current_ratio + delta, MIN_COLUMN_RATIO, maximum_ratio) - base_ratio

			return true
		end

		return nil
	end,
})

function M.prepare_spatial_tile(window)
	local id = window_id(window)

	if not id then
		return
	end

	pending_insertions[id] = {
		center_x = window.at.x + window.size.x / 2,
	}
end

return M
