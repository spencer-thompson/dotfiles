local M = {}

local function selector_matches_monitor(selector, monitor)
	if type(selector) ~= "string" or selector == "" then
		return false
	end

	local description = selector:match("^desc:(.+)$")
	if description then
		return monitor.description == description or monitor.description:sub(1, #description) == description
	end

	return monitor.name == selector
end

function M.setup(device)
	local routing = device.workspace_routing
	if type(routing) ~= "table" then
		return
	end

	local managed_workspaces = {}
	for _, workspace in ipairs(routing.workspaces or {}) do
		managed_workspaces[tostring(workspace)] = true
	end

	if next(managed_workspaces) == nil then
		return
	end

	local function preferred_monitor()
		local monitors = hl.get_monitors()

		for _, selector in ipairs(routing.monitors or {}) do
			for _, monitor in ipairs(monitors) do
				if selector_matches_monitor(selector, monitor) then
					return monitor
				end
			end
		end
	end

	local function move_workspace(workspace, monitor)
		if not workspace or not managed_workspaces[workspace.name] or not monitor then
			return
		end

		if workspace.monitor and workspace.monitor.name == monitor.name then
			return
		end

		hl.dispatch(hl.dsp.workspace.move({ workspace = workspace, monitor = monitor }))
	end

	local function sync_workspaces()
		local monitor = preferred_monitor()
		if not monitor then
			return
		end

		for _, workspace in ipairs(hl.get_workspaces()) do
			move_workspace(workspace, monitor)
		end
	end

	local function move_created_workspace(workspace)
		if not workspace or not managed_workspaces[workspace.name] then
			return
		end

		hl.timer(function()
			move_workspace(workspace, preferred_monitor())
		end, { timeout = 1, type = "oneshot" })
	end

	hl.on("monitor.added", sync_workspaces)
	hl.on("monitor.removed", sync_workspaces)
	hl.on("config.reloaded", sync_workspaces)
	hl.on("workspace.created", move_created_workspace)
end

return M
