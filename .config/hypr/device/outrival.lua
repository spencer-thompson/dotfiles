local programs = require("modules.programs")
local laptop_monitor = "desc:Samsung Display Corp. 0x4165"
local work_external_dp_monitor = "desc:CSF DP"
local work_external_hdmi_monitor = "desc:CSF HDMI"
local home_external_monitor = "desc:Samsung Electric Company Odyssey G75F HNTL201148"

local function monitor_is_connected(selector)
	local description = selector:match("^desc:(.+)$")

	for _, monitor in ipairs(hl.get_monitors()) do
		if monitor.description == description then
			return true
		end
	end

	return false
end

local external_monitor
for _, selector in ipairs({ work_external_dp_monitor, work_external_hdmi_monitor, home_external_monitor }) do
	if monitor_is_connected(selector) then
		external_monitor = selector
		break
	end
end

local main_monitor = external_monitor or laptop_monitor

local routed_workspaces = {}
for workspace = 2, 10 do
	routed_workspaces[#routed_workspaces + 1] = tostring(workspace)
end

return {
	main_monitor = main_monitor,
	secondary_monitor = main_monitor,
	laptop_monitor = laptop_monitor,

	monitors = {
		{
			output = laptop_monitor,
			mode = "3840x2400@60",
			position = "0x0",
			scale = 1.5,
		},
		{
			output = work_external_dp_monitor,
			mode = "5120x2160@120",
			position = "-640x-2160",
			scale = 1,
		},
		{
			output = work_external_hdmi_monitor,
			mode = "modeline 594.00 5120 5168 5200 5280 2160 2163 2173 2250 +hsync -vsync",
			position = "-640x-2160",
			scale = 1,
		},
		{
			output = home_external_monitor,
			mode = "5120x2160@60",
			position = "2560x0",
			scale = 1.5,
		},
	},

	devices = {
		{
			name = "elan0683:00-04f3:320b-touchpad",
			sensitivity = 0.5,
			scroll_factor = 1.0,
		},
		{
			name = "apple-inc.-magic-trackpad",
			sensitivity = 0.5,
			clickfinger_behavior = true,
		},
		{
			name = "apple-inc.-magic-trackpad-1",
			sensitivity = 0.5,
			clickfinger_behavior = true,
		},
	},

	workspaces = {
		{
			workspace = "1",
			monitor = laptop_monitor,
			default = true,
		},
	},

	workspace_routing = {
		monitors = { work_external_dp_monitor, work_external_hdmi_monitor, home_external_monitor },
		workspaces = routed_workspaces,
	},

	startup = {
		{
			command = programs.browser,
			rules = { workspace = "1 silent" },
		},
	},
}
