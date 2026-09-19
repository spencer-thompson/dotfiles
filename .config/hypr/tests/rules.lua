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

local nwg_look = matching(window_rules, "name", "appearance-settings")
assert(#nwg_look == 1 and nwg_look[1].float and nwg_look[1].center, "centered appearance settings")
assert(nwg_look[1].size[1] == "(monitor_w*0.4)" and nwg_look[1].size[2] == "(monitor_h*0.7)", "proportional utilities")

local portal = matching(window_rules, "name", "file-chooser")
assert(#portal == 1 and portal[1].center and portal[1].float, "centered floating file chooser")
assert(portal[1].size[1] == nwg_look[1].size[1] and portal[1].size[2] == nwg_look[1].size[2], "shared utility size")

local modal = matching(window_rules, "name", "modal-dialogs")
assert(#modal == 1 and modal[1].match.modal and modal[1].float and modal[1].dim_around, "modal dialogs float visibly")
assert(modal[1].size[1] == "(monitor_w*0.25)" and modal[1].size[2] == "(monitor_h*0.3)", "compact proportional dialogs")

local vault = matching(window_rules, "name", "1password")
local quick_access = matching(window_rules, "name", "1password-quick-access")
assert(#vault == 1 and #quick_access == 1, "separate main vault and Quick Access rules")
assert(quick_access[1].match.initial_title and quick_access[1].size[1] ~= vault[1].size[1], "Quick Access stays compact")
assert(#matching(window_rules, "name", "xwayland-border") == 0, "XWayland windows inherit the theme")

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
		and operator[1].size[2] == "(monitor_h*0.7)",
	"kept Operator at its existing 60 by 70 percent size"
)
assert(operator[1].border_size == 2 and operator[1].border_color == "rgb(ff0000)", "gave Operator a red 2px border")
assert(operator[1].no_blur, "disabled blur behind Operator's Wayland surface")
assert(operator[1].focus_on_activate == false, "prevented Operator activation requests from taking focus")
assert(operator[1].suppress_event == "maximize", "suppressed Operator maximize requests")

local quickshell = matching(window_rules, "name", "quickshell-settings")
assert(#quickshell == 1, "registered one Quickshell window rule")
assert(quickshell[1].center and quickshell[1].float, "centered floating Quickshell settings")
assert(quickshell[1].size[1] == nwg_look[1].size[1] and quickshell[1].size[2] == nwg_look[1].size[2], "shared settings size")


print("rule tests passed")
