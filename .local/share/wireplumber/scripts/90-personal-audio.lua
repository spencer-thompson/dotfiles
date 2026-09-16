local policy = require("personal-audio-policy")
local linking = require("linking-utils")
local log = Log.open_topic("s-personal-audio")
local state = State("personal-audio-policy")
local saved = state:load()
local choice = policy.defaults()
if saved.policy then
  local ok, parsed = pcall(function() return Json.Raw(saved.policy):parse() end)
  if ok and policy.validate(parsed) then choice = parsed
  else log:warning("Ignoring invalid saved policy; using normal playback") end
end
local runtime = { phone = saved.phone == "true", dnd = false, allowed = {}, discord = false, playback = {} }
local metadata = ImplMetadata("personal-audio")

local function persist_choice()
  saved = { phone = tostring(runtime.phone), policy = Json.Object {
    version = 1, mode = choice.mode, owner = choice.owner, mix = choice.mix,
    blocked = Json.Object(choice.blocked),
  }:to_string() }
  state:save_after_timeout(saved)
end

local function publish()
  metadata:set(0, "state", "Spa:String:JSON", Json.Object {
    version = 1, mode = choice.mode, owner = choice.owner, mix = choice.mix,
    blocked = Json.Object(choice.blocked), phone = runtime.phone, dnd = runtime.dnd,
    allowed = Json.Object(runtime.allowed), discord = runtime.discord or false,
    playback = Json.Object(runtime.playback or {}), tracker = (runtime.tracker_ttl or 0) > 0,
    capabilities = Json.Array { "playback", "discord" },
  }:to_string())
end

-- Separate telemetry from commands: the observer never overwrites command acknowledgements.
SimpleEventHook {
  name = "personal-audio/playback",
  interests = { EventInterest {
    Constraint { "event.type", "=", "metadata-changed" },
    Constraint { "metadata.name", "=", "personal-audio" },
    Constraint { "event.subject.key", "=", "playback" },
  } },
  execute = function(event)
    local raw = event:get_properties()["event.subject.value"]
    local ok, update = pcall(function() return Json.Raw(raw or ""):parse() end)
    if not ok or type(update) ~= "table" or update.version ~= 1 or type(update.apps) ~= "table" then return end
    for id, status in pairs(update.apps) do
      if type(id) ~= "string" or (status ~= "Playing" and status ~= "Paused" and status ~= "Stopped") then return end
    end
    local signature = Json.Object { apps = Json.Object(update.apps), spotify = update.spotify or "",
      exempt = Json.Object(type(update.exempt) == "table" and update.exempt or {}) }:to_string()
    local changed = signature ~= runtime.playback_signature or (runtime.tracker_ttl or 0) == 0
    runtime.playback_signature = signature
    runtime.playback = update.apps
    runtime.exempt = type(update.exempt) == "table" and update.exempt or {}
    runtime.spotify = type(update.spotify) == "string" and update.spotify ~= "" and update.spotify or nil
    -- A new observer or a telemetry gap establishes a baseline; it is not a Play action.
    local generation = tonumber(update.generation) or 0
    if update.session ~= runtime.observer_session or (runtime.tracker_ttl or 0) == 0 then
      runtime.phone_generation = generation
    end
    runtime.observer_session, runtime.generation = update.session, generation
    if runtime.phone and type(update.starts) == "table" then
      for id, started in pairs(update.starts) do
        if type(started) == "number" and started > (runtime.phone_generation or generation)
            and update.apps[id] == "Playing" and not choice.blocked[id]
            and (choice.mode == "normal" or choice.owner == id or runtime.allowed[id]
              or (choice.mode == "game" and choice.mix and id:lower():match("spotify$"))) then
          runtime.phone = false
          persist_choice()
          log:info("Returned to PC: tracked media started (" .. id .. ")")
          changed = true
          break
        end
      end
    end
    runtime.tracker_ttl = 6
    if changed then
      publish()
      event:get_source():call("schedule-rescan", "linking")
    end
  end,
}:register()

-- Expired observer data becomes unknown, never a permanent automatic block.
playback_watchdog = Core.timeout_add(2000, function()
  if (runtime.tracker_ttl or 0) > 0 then
    runtime.tracker_ttl = runtime.tracker_ttl - 1
    if runtime.tracker_ttl == 0 then
      runtime.playback, runtime.spotify, runtime.exempt = {}, nil, {}
      publish()
      local source = Plugin.find("standard-event-source")
      if source then source:call("schedule-rescan", "linking") end
    end
  end
  return true
end)

-- This sink consumes blocked playback without keeping a physical device busy.
-- Policy routing never writes target.object/target.node, so it cannot poison
-- WirePlumber's saved per-application device preferences.
-- Keep an exported node alive for the lifetime of this script.
hold_sink = LocalNode("adapter", {
  ["node.name"] = "personal_audio_hold",
  ["node.description"] = "Audio held by your policy",
  ["media.class"] = "Audio/Sink",
  ["factory.name"] = "support.null-audio-sink",
  ["audio.position"] = "FL,FR", ["audio.channels"] = 2,
  ["node.virtual"] = true, ["wireplumber.is-fallback"] = true,
  ["priority.session"] = 0,
})
hold_sink:activate(Feature.Proxy.BOUND)
metadata:activate(Features.ALL, function(_, err)
  if err then log:warning(tostring(err)) else publish() end
end)

-- A holding output and its monitor must never become a default device.
SimpleEventHook {
  name = "personal-audio/filter-defaults",
  before = { "default-nodes/find-best-default-node", "default-nodes/find-selected-default-node",
    "default-nodes/find-stored-default-node" },
  interests = { EventInterest { Constraint { "event.type", "=", "select-default-node" } } },
  execute = function(event)
    local nodes = event:get_data("available-nodes"):parse()
    local filtered = {}
    for _, p in ipairs(nodes) do
      if p["node.name"] ~= "personal_audio_hold" then filtered[#filtered + 1] = Json.Object(p) end
    end
    event:set_data("available-nodes", Json.Array(filtered))
  end,
}:register()

SimpleEventHook {
  name = "personal-audio/select-target",
  before = "linking/find-defined-target",
  interests = { EventInterest { Constraint { "event.type", "=", "select-target" } } },
  execute = function(event)
    local _, om, si, props, flags = linking:unwrap_select_target_event(event)
    local node = si:get_associated_proxy("node")
    if not node then return end
    local p = node.properties
    if p["media.class"] ~= "Stream/Output/Audio" then return end
    local reason = policy.decide(choice, runtime, p)
    metadata:set(tonumber(props["node.id"]), "decision", "Spa:String:JSON", Json.Object {
      app = policy.identity(p), blocked = reason ~= nil, reason = policy.explain(choice, runtime, p),
    }:to_string())
    if not reason then return end
    local target = om:lookup { type = "SiLinkable", Constraint { "node.name", "=", "personal_audio_hold" } }
    if target and linking.canLink(props, target) then
      flags.has_defined_target = true
      flags.has_node_defined_target = false
      flags.can_passthrough = false
      event:set_data("target", target)
    end
  end,
}:register()

-- Guard the final target too: a missing holding sink must not let blocked
-- playback fall through to speakers, or become an allowed stream's fallback.
SimpleEventHook {
  name = "personal-audio/check-target",
  after = { "linking/find-best-target", "linking/get-filter-from-target" },
  before = "linking/prepare-link",
  interests = { EventInterest { Constraint { "event.type", "=", "select-target" } } },
  execute = function(event)
    local _, _, si, _, _, target = linking:unwrap_select_target_event(event)
    local node = si:get_associated_proxy("node")
    if not node or node.properties["media.class"] ~= "Stream/Output/Audio" then return end
    local blocked = policy.decide(choice, runtime, node.properties) ~= nil
    local held = target and target.properties["node.name"] == "personal_audio_hold"
    if (blocked and not held) or (not blocked and held) then event:set_data("target", nil) end
  end,
}:register()

SimpleEventHook {
  name = "personal-audio/commands",
  interests = { EventInterest {
    Constraint { "event.type", "=", "metadata-changed" },
    Constraint { "metadata.name", "=", "personal-audio" },
    Constraint { "event.subject.key", "=", "command" },
  } },
  execute = function(event)
    local raw = event:get_properties()["event.subject.value"]
    if not raw then return end
    local ok, cmd = pcall(function() return Json.Raw(raw):parse() end)
    if not ok or type(cmd) ~= "table" then return end
    local action, app = cmd.action, cmd.app
    local error_message
    local persist = false
    if action == "normal" then
      choice.mode, choice.owner = "normal", ""
      runtime.phone, runtime.allowed = false, {}
      persist = true
    elseif (action == "focus" or action == "game") and type(app) == "string" and app ~= "" then
      choice.mode, choice.owner = action, app
      choice.blocked[app] = nil
      runtime.phone, runtime.allowed = false, {}
      persist = true
    elseif action == "mix" and type(cmd.enabled) == "boolean" then
      choice.mix = cmd.enabled
      persist = true
    elseif action == "block" and type(app) == "string" and app ~= "" then
      choice.blocked[app], runtime.allowed[app] = true, nil
      persist = true
    elseif action == "allow" and type(app) == "string" and app ~= "" then
      choice.blocked[app], runtime.allowed[app] = nil, true
      persist = true
    elseif action == "release" then
      runtime.phone, runtime.phone_generation = true, runtime.generation or 0
      persist = true
    elseif action == "resume" then runtime.phone = false; persist = true
    elseif action == "discord" and type(cmd.enabled) == "boolean" then runtime.discord = cmd.enabled
    elseif action == "dnd" and type(cmd.enabled) == "boolean" then runtime.dnd = cmd.enabled
    elseif action == "reset" then
      choice, runtime = policy.defaults(), { phone = false, dnd = false, allowed = {}, discord = false, playback = {} }
      persist = true
    else error_message = "Unknown or invalid command" end
    if not error_message then
      if persist then
        persist_choice()
      end
      publish()
      event:get_source():call("schedule-rescan", "linking")
    end
    metadata:set(0, "result", "Spa:String:JSON", Json.Object {
      id = cmd.id or "", ok = error_message == nil, error = error_message or "",
    }:to_string())
  end,
}:register()

SimpleEventHook {
  name = "personal-audio/forget-node",
  interests = { EventInterest { Constraint { "event.type", "=", "node-removed" } } },
  execute = function(event)
    local id = tonumber(event:get_subject().properties["object.id"])
    if id then metadata:set(id, "decision", nil, nil) end
  end,
}:register()
