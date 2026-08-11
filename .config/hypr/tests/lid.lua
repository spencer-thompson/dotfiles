local monitors = {}
local applied_monitor_rules = {}
local timers = {}
local lid_state = "open"

local original_io_open = io.open

io.open = function(path, mode)
	if path == "/proc/acpi/button/lid/LID/state" then
		return {
			read = function()
				return "state:      " .. lid_state
			end,
			close = function() end,
		}
	end

	if path:match("^/proc/acpi/button/lid/") then
		return nil
	end

	return original_io_open(path, mode)
end

_G.hl = {
	bind = function() end,
	dispatch = function() end,
	dsp = {
		dpms = function(spec)
			return spec
		end,
	},
	exec_cmd = function() end,
	get_monitors = function()
		return monitors
	end,
	monitor = function(rule)
		applied_monitor_rules[#applied_monitor_rules + 1] = rule
	end,
	notification = {
		create = function() end,
	},
	on = function() end,
	timer = function(callback, opts)
		timers[#timers + 1] = { callback = callback, opts = opts }
	end,
}

local lid = require("modules.lid")
local laptop_monitor = "desc:Laptop"
local external_monitor = "desc:External"
local profile = {
	laptop_monitor = laptop_monitor,
	monitors = {
		{
			output = laptop_monitor,
			mode = "preferred",
			position = "0x0",
			scale = 1.5,
		},
		{
			output = external_monitor,
			mode = "preferred",
			position = "auto",
			scale = 1,
		},
	},
}

local laptop = { name = "eDP-1", description = "Laptop", disabled = true }
local external = { name = "DP-1", description = "External", disabled = false }

lid_state = "closed"
monitors = { laptop, external }

local effective_rules = lid.effective_monitor_rules(profile)

assert(effective_rules[1].disabled == true, "kept the laptop disabled while reloading in clamshell mode")
assert(effective_rules[1] ~= profile.monitors[1], "copied the laptop rule before overriding it")
assert(profile.monitors[1].disabled == nil, "left the device profile unchanged")

lid_state = "open"
effective_rules = lid.effective_monitor_rules(profile)
assert(effective_rules[1].disabled == nil, "kept the laptop enabled while the lid was open")

lid_state = "closed"
monitors = { laptop }
effective_rules = lid.effective_monitor_rules(profile)
assert(effective_rules[1].disabled == nil, "left the laptop enabled until closed-lid suspension without an external")

monitors = { laptop, external }
lid.setup(profile)
assert(#timers == 1, "scheduled closed-lid reconciliation")
timers[1].callback()
assert(#applied_monitor_rules == 0, "did not disable an already-disabled laptop panel again")

laptop.disabled = false
timers = {}
lid.setup(profile)
assert(#timers == 1, "scheduled closed-lid reconciliation for an enabled laptop panel")
timers[1].callback()
assert(#applied_monitor_rules == 1, "disabled an enabled laptop panel")
assert(applied_monitor_rules[1].output == laptop_monitor, "disabled the configured laptop panel")
assert(applied_monitor_rules[1].disabled == true, "applied the disabled monitor rule")

io.open = original_io_open

print("lid tests passed")
