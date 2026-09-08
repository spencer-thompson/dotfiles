local layer_rules = {}
local window_rules = {}
local workspace_rules = {}

_G.hl = {
	layer_rule = function(spec)
		layer_rules[#layer_rules + 1] = spec
	end,
	window_rule = function(spec)
		window_rules[#window_rules + 1] = spec
	end,
	workspace_rule = function(spec)
		workspace_rules[#workspace_rules + 1] = spec
	end,
}

require("modules.rules").setup({
	main_monitor = "DP-1",
	secondary_monitor = "HDMI-A-1",
})

local function matching(rules, field, value)
	local matches = {}

	for _, rule in ipairs(rules) do
		if rule[field] == value or (rule.match and rule.match[field] == value) then
			matches[#matches + 1] = rule
		end
	end

	return matches
end

local launcher = matching(layer_rules, "namespace", "launcher")
assert(#launcher == 1, "registered one launcher layer rule")
assert(launcher[1].blur and launcher[1].xray == false and launcher[1].dim_around, "kept all launcher effects")

local nwg_look = matching(window_rules, "class", "nwg-look")
assert(#nwg_look == 1 and nwg_look[1].float and nwg_look[1].size == "800 500", "consolidated nwg-look effects")

local portal = matching(window_rules, "class", "xdg-desktop-portal-gtk")
assert(#portal == 1 and portal[1].center and portal[1].float and portal[1].size == "900 600", "consolidated portal effects")

local steam = matching(workspace_rules, "workspace", "10")
assert(#steam == 1, "registered one Steam workspace rule")
assert(steam[1].monitor == "DP-1" and steam[1].on_created_empty == "steam", "kept all Steam workspace effects")
assert(#matching(workspace_rules, "workspace", "name:steam") == 0, "removed the named Steam workspace")

local steam_client = matching(window_rules, "class", "steam")
assert(#steam_client == 1 and steam_client[1].workspace == "10 silent", "routed Steam to workspace 10")
assert(steam_client[1].monitor == "DP-1", "kept Steam on the main monitor")

local steam_game = matching(window_rules, "class", "^steam_app_[0-9]+$")
assert(#steam_game == 1 and steam_game[1].workspace == "10 silent", "routed games to workspace 10")
assert(steam_game[1].fullscreen and steam_game[1].content == "game", "kept fullscreen game behavior")

local discord = matching(window_rules, "class", "discord")
assert(#discord == 1, "registered one Discord window rule")
assert(discord[1].monitor == "HDMI-A-1" and discord[1].no_initial_focus, "kept all Discord effects")

local operator = matching(window_rules, "class", "^outrival-operator$")
assert(#operator == 1, "registered one OutRival Operator window rule")
assert(operator[1].float and operator[1].no_initial_focus, "kept Operator floating without initial focus")
assert(
	operator[1].center
		and operator[1].size[1] == "(monitor_w*0.6)"
		and operator[1].size[2] == "(monitor_h*0.6)",
	"centered Operator at 60 percent of the monitor"
)
assert(operator[1].border_size == 2 and operator[1].border_color == "rgb(ff0000)", "gave Operator a red 2px border")
assert(operator[1].no_blur, "disabled blur behind Operator's Wayland surface")
assert(operator[1].focus_on_activate == false, "prevented Operator activation requests from taking focus")
assert(operator[1].suppress_event == "maximize", "suppressed Operator maximize requests")

local quickshell = matching(window_rules, "class", "org.quickshell")
assert(#quickshell == 1, "registered one Quickshell window rule")
assert(quickshell[1].center and quickshell[1].float and quickshell[1].size == "900 1100", "kept all Quickshell effects")


print("rule tests passed")
