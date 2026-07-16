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

function M.setup(device)
	local laptop_monitor = device.laptop_monitor
	if type(laptop_monitor) ~= "string" or laptop_monitor == "" then
		return
	end

	hl.exec_cmd(
		[[flock -w 2 "$XDG_RUNTIME_DIR/hyprland-lid-inhibitor.lock" systemd-inhibit --what=handle-lid-switch --who=Hyprland --why="Hyprland handles laptop lid events" --mode=block tail --pid="$PPID" --sleep-interval=0.1 -f /dev/null]]
	)

	local lid_closed = lid_is_closed()

	local function external_monitors()
		local monitors = {}

		for _, monitor in ipairs(hl.get_monitors()) do
			if not selector_matches_monitor(laptop_monitor, monitor) then
				monitors[#monitors + 1] = monitor
			end
		end

		return monitors
	end

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
		local monitors = external_monitors()

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

		hl.monitor({ output = laptop_monitor, disabled = true })
		hl.notification.create({ text = "Clamshell mode enabled", timeout = 2000, icon = "ok" })
	end

	local function handle_lid_opened()
		lid_closed = false

		for _, rule in ipairs(device.monitors or {}) do
			hl.monitor(rule)
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
			if lid_closed and #external_monitors() == 0 then
				suspend_for_closed_lid()
			end
		end, { timeout = 500, type = "oneshot" })
	end)

	if lid_closed then
		hl.timer(handle_lid_closed, { timeout = 250, type = "oneshot" })
	end
end

return M
