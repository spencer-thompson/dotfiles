local M = {}

local lid_state_paths = {
	"/proc/acpi/button/lid/LID/state",
	"/proc/acpi/button/lid/LID0/state",
	"/proc/acpi/button/lid/LID1/state",
}

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

local function lid_is_closed()
	for _, path in ipairs(lid_state_paths) do
		local file = io.open(path, "r")
		if file then
			local state = file:read("*a")
			file:close()
			return state:find("closed", 1, true) ~= nil
		end
	end

	return false
end

local function external_monitors(laptop_monitor)
	local monitors = {}

	for _, monitor in ipairs(hl.get_monitors()) do
		if not selector_matches_monitor(laptop_monitor, monitor) then
			monitors[#monitors + 1] = monitor
		end
	end

	return monitors
end

local function monitor_is_enabled(selector)
	for _, monitor in ipairs(hl.get_monitors()) do
		if selector_matches_monitor(selector, monitor) then
			return monitor.disabled ~= true
		end
	end

	return false
end

function M.effective_monitor_rules(device)
	local rules = device.monitors or {}
	local laptop_monitor = device.laptop_monitor

	if type(laptop_monitor) ~= "string"
		or laptop_monitor == ""
		or not lid_is_closed()
		or #external_monitors(laptop_monitor) == 0
	then
		return rules
	end

	local effective_rules = {}
	local laptop_rule_found = false

	for _, rule in ipairs(rules) do
		if rule.output == laptop_monitor then
			local effective_rule = {}

			for key, value in pairs(rule) do
				effective_rule[key] = value
			end

			effective_rule.disabled = true
			effective_rules[#effective_rules + 1] = effective_rule
			laptop_rule_found = true
		else
			effective_rules[#effective_rules + 1] = rule
		end
	end

	if not laptop_rule_found then
		effective_rules[#effective_rules + 1] = { output = laptop_monitor, disabled = true }
	end

	return effective_rules
end

function M.setup(device)
	local laptop_monitor = device.laptop_monitor
	if type(laptop_monitor) ~= "string" or laptop_monitor == "" then
		return
	end

	hl.exec_cmd(
		[[flock -w 2 "$XDG_RUNTIME_DIR/hyprland-lid-inhibitor.lock" systemd-inhibit --what=handle-lid-switch --who=Hyprland --why="Hyprland handles laptop lid events" --mode=block tail --pid="$PPID" --sleep-interval=0.1 -f /dev/null]]
	)

	local lid_closed = lid_is_closed()

	local function profile_rule_for(monitor)
		for _, rule in ipairs(device.monitors or {}) do
			if selector_matches_monitor(rule.output, monitor) then
				return rule
			end
		end
	end

	local function make_standalone_rule(monitor)
		local profile_rule = profile_rule_for(monitor)
		local rule = {}

		if profile_rule then
			for key, value in pairs(profile_rule) do
				rule[key] = value
			end
		else
			rule = {
				output = monitor.name,
				mode = "preferred",
				position = "auto",
				scale = monitor.scale,
			}
		end

		rule.mirror = ""
		return rule
	end

	local function suspend_for_closed_lid()
		hl.notification.create({ text = "Lid closed without an external display; suspending", timeout = 2000, icon = "info" })
		hl.exec_cmd("loginctl lock-session && systemctl suspend")
	end

	local function handle_lid_closed()
		lid_closed = true
		local monitors = external_monitors(laptop_monitor)

		if #monitors == 0 then
			suspend_for_closed_lid()
			return
		end

		for _, monitor in ipairs(monitors) do
			hl.dispatch(hl.dsp.dpms({ action = "enable", monitor = monitor.name }))

			local profile_rule = profile_rule_for(monitor)
			if monitor.is_mirror or (profile_rule and profile_rule.mirror) then
				hl.monitor(make_standalone_rule(monitor))
			end
		end

		if monitor_is_enabled(laptop_monitor) then
			hl.monitor({ output = laptop_monitor, disabled = true })
		end
		hl.notification.create({ text = "Clamshell mode enabled", timeout = 2000, icon = "ok" })
	end

	local function handle_lid_opened()
		lid_closed = false
		local laptop_monitor_restored = false

		for _, rule in ipairs(device.monitors or {}) do
			if rule.output == laptop_monitor then
				local enabled_rule = {}

				for key, value in pairs(rule) do
					enabled_rule[key] = value
				end

				enabled_rule.disabled = false
				hl.monitor(enabled_rule)
				laptop_monitor_restored = true
			else
				hl.monitor(rule)
			end
		end

		if not laptop_monitor_restored then
			hl.monitor({ output = laptop_monitor, disabled = false })
		end

		hl.dispatch(hl.dsp.dpms({ action = "enable", monitor = laptop_monitor }))
		hl.notification.create({ text = "Laptop display restored", timeout = 2000, icon = "ok" })
	end

	hl.bind("switch:on:Lid Switch", handle_lid_closed, { locked = true, desc = "Close laptop lid" })
	hl.bind("switch:off:Lid Switch", handle_lid_opened, { locked = true, desc = "Open laptop lid" })

	hl.on("monitor.removed", function()
		if not lid_closed then
			return
		end

		hl.timer(function()
			if lid_closed and #external_monitors(laptop_monitor) == 0 then
				suspend_for_closed_lid()
			end
		end, { timeout = 500, type = "oneshot" })
	end)

	if lid_closed then
		hl.timer(handle_lid_closed, { timeout = 250, type = "oneshot" })
	end
end

return M
