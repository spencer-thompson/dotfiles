local function read_first_line(path)
	local file = io.open(path, "r")
	if not file then
		return nil
	end

	local line = file:read("*l")
	file:close()
	return line
end

local function trim(value)
	return (value or ""):match("^%s*(.-)%s*$")
end

local function normalize_module_name(value)
	return trim(value):gsub("[^%w_-]", "_")
end

local function with_desc(desc, opts)
	opts = opts or {}

	if desc and opts.desc == nil and opts.description == nil then
		opts.desc = desc
	end

	return opts
end

local function apply_startup(commands)
	if not commands or #commands == 0 then
		return
	end

	hl.on("hyprland.start", function()
		for _, item in ipairs(commands) do
			if type(item) == "string" then
				hl.exec_cmd(item)
			else
				hl.exec_cmd(item.command, item.rules)
			end
		end
	end)
end

local function apply_binds(binds)
	for _, item in ipairs(binds or {}) do
		local dispatcher = item.dispatcher

		if item.command then
			dispatcher = hl.dsp.exec_cmd(item.command)
		end

		hl.bind(item.keys, dispatcher, with_desc(item.desc, item.opts))
	end
end

local function apply_profile(profile)
	for _, monitor in ipairs(profile.monitors or {}) do
		hl.monitor(monitor)
	end

	for _, device in ipairs(profile.devices or {}) do
		hl.device(device)
	end

	for _, workspace in ipairs(profile.workspaces or {}) do
		hl.workspace_rule(workspace)
	end

	for _, rule in ipairs(profile.window_rules or {}) do
		hl.window_rule(rule)
	end

	for _, rule in ipairs(profile.layer_rules or {}) do
		hl.layer_rule(rule)
	end

	apply_startup(profile.startup)
	apply_binds(profile.binds)
end

local hostname = trim(read_first_line("/proc/sys/kernel/hostname") or os.getenv("HOSTNAME") or "")
local profile_name = normalize_module_name(hostname)

if profile_name == "" then
	profile_name = "default"
end

local module_name = "device." .. profile_name
local ok, profile = pcall(require, module_name)

if not ok then
	local missing_module = tostring(profile):find("module '" .. module_name .. "' not found", 1, true) ~= nil
	if not missing_module then
		error(profile)
	end

	profile = require("device.default")
	profile_name = "default"
end

profile.hostname = hostname
profile.profile_name = profile_name

apply_profile(profile)

return profile
