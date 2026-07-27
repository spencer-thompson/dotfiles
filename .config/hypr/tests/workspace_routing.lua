local monitors = {}
local workspaces = {}
local event_handlers = {}
local moves = {}

_G.hl = {
	dispatch = function(dispatcher)
		moves[#moves + 1] = dispatcher
	end,
	dsp = {
		workspace = {
			move = function(spec)
				return spec
			end,
		},
	},
	get_monitors = function()
		return monitors
	end,
	get_workspaces = function()
		return workspaces
	end,
	on = function(event, callback)
		event_handlers[event] = callback
	end,
}

local laptop = { name = "eDP-1", description = "Laptop" }
local work_external = { name = "HDMI-A-1", description = "Work" }
local home_external = { name = "DP-1", description = "Home" }

monitors = { laptop }
workspaces = {
	{ name = "1", monitor = laptop },
	{ name = "laptop", monitor = laptop },
}

require("modules.workspace_routing").setup({
	workspace_routing = {
		monitors = { "desc:Work", "desc:Home" },
		workspaces = { "1", "2", "3" },
	},
})

assert(event_handlers["monitor.added"], "registered monitor-added handler")
assert(event_handlers["monitor.removed"], "registered monitor-removed handler")
assert(event_handlers["config.reloaded"], "registered config-reloaded handler")
assert(event_handlers["workspace.created"], "registered workspace-created handler")
event_handlers["config.reloaded"]()
assert(#moves == 0, "kept workspaces on the laptop without an external monitor")

monitors = { laptop, work_external }
event_handlers["monitor.added"](work_external)
assert(#moves == 1, "moved an existing managed workspace when the external monitor appeared")
assert(moves[1].workspace == workspaces[1], "moved the expected existing workspace")
assert(moves[1].monitor == work_external, "moved the existing workspace to the work monitor")

event_handlers["workspace.created"]({ name = "2", monitor = laptop })
assert(#moves == 2, "moved a newly created managed workspace")
assert(moves[2].monitor == work_external, "routed a new workspace to the connected external monitor")

event_handlers["workspace.created"]({ name = "3", monitor = work_external })
assert(#moves == 2, "kept a managed workspace already on the preferred monitor")

event_handlers["workspace.created"]({ name = "4", monitor = laptop })
assert(#moves == 2, "ignored unmanaged workspaces")

monitors = { laptop, home_external }
workspaces = { { name = "3", monitor = work_external } }
event_handlers["monitor.removed"](work_external)
assert(#moves == 3, "moved a managed workspace to the remaining preferred monitor")
assert(moves[3].monitor == home_external, "used the remaining home monitor")

monitors = { laptop, home_external, work_external }
event_handlers["workspace.created"]({ name = "1", monitor = laptop })
assert(#moves == 4, "moved a managed workspace when both external monitors were present")
assert(moves[4].monitor == work_external, "respected configured external-monitor priority")

print("workspace routing tests passed")
