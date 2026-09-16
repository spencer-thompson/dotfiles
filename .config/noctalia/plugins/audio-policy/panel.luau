local snapshot = noctalia.state.get("snapshot") or { outputs = {}, inputs = {}, apps = {}, owners = {}, state = {} }
local expanded = false
local errorText = ""
local sequence = 0
local render

local function command(action, value)
  sequence = sequence + 1
  noctalia.state.set("command", { action = action, value = value, sequence = sequence })
end

local function button(text, action, value, enabled)
  return ui.button({ text = text, controlSize = "sm", variant = "outline", enabled = enabled ~= false,
    onClick = function() command(action, value) end })
end

local function devices(label, list, action)
  local names = {}
  local selected = 0
  for i, device in ipairs(list or {}) do
    names[i] = device.name
    if device.active then selected = i - 1 end
  end
  if #names == 0 then names = { "No device available" } end
  return ui.column({ gap = 6, flexGrow = 1 }, {
    ui.label({ text = label, fontWeight = "bold" }),
    ui.select({ options = names, selectedIndex = selected, enabled = #(list or {}) > 0,
      onChange = function(index)
        local device = list[math.floor(tonumber(index) or -1) + 1]
        if device and not device.active then command(action, device.id) end
      end }),
  })
end

render = function()
  local state = snapshot.state or {}
  local ready = snapshot.ready == true
  local children = {
    ui.row({ gap = 10, align = "center" }, {
      ui.glyph({ name = "headphones", size = 24, color = "primary" }),
      ui.label({ text = "Your audio", fontSize = 18, fontWeight = "bold", flexGrow = 1 }),
      ui.button({ glyph = "close", variant = "ghost", onClick = function() panel.close() end }),
    }),
    devices("Output", snapshot.outputs, "output"),
    devices("Microphone", snapshot.inputs, "mic"),
    ui.button({ text = "Volume & device details", variant = "ghost", onClick = function()
      noctalia.runAsync({ "noctalia", "msg", "panel-toggle", "blackbartblues/audio-switcher:audio-switcher" })
    end }),
    ui.label({ text = ready and (state.phone and "Phone mode · Return to PC or start tracked PC media to return"
      or ("Mode: " .. (state.mode or "normal") .. (state.dnd and "  ·  Do not disturb" or "")))
      or "Ready to activate after your call: audio-policy activate", maxLines = 2, color = "primary" }),
    ui.row({ gap = 8 }, {
      button("Normal", "normal", nil, ready),
      button(state.phone and "Return to PC" or "Release for phone", state.phone and "resume" or "release", nil, ready),
      button(state.mix and "Spotify mix: on" or "Spotify mix: off", "mix", state.mix and "off" or "on", ready),
    }),
    ui.row({ gap = 8 }, {
      button(state.discord and "Discord alongside: on" or "Discord alongside: off", "discord",
        state.discord and "off" or "on", ready and state.capabilities ~= nil),
    }),
    ui.label({ text = state.tracker and "Playback tracking connected · Spotify priority in Normal mode"
      or "Playback tracking unavailable · automatic media rules inactive",
      fontSize = 11, color = "on_surface_variant", maxLines = 2 }),
    ui.label({ text = "Current audio owners", fontWeight = "bold" }),
    ui.label({ text = #(snapshot.owners or {}) > 0 and table.concat(snapshot.owners, ", ") or "No active playback streams",
      maxLines = 3 }),
    ui.label({ text = "Unknown streams can contain silence. Explicit Focus and game protection override Spotify priority.",
      fontSize = 11, color = "on_surface_variant", maxLines = 2 }),
    ui.button({ text = (expanded and "Hide" or "Show") .. " apps & block reasons", variant = "outline",
      onClick = function() expanded = not expanded; render() end }),
  }
  if expanded then
    for _, app in ipairs(snapshot.apps or {}) do
      local actions = { button(app.blocked and "Allow" or "Block", app.blocked and "allow" or "block", app.id, ready) }
      table.insert(actions, button("Focus", "focus", app.id, ready))
      table.insert(actions, button("Protect game", "game", app.id, ready))
      table.insert(children, ui.column({ gap = 6, padding = 10, radius = 9, fill = "surface_variant/0.4" }, {
        ui.label({ text = app.name, fontWeight = "bold" }),
        ui.label({ text = app.reason .. (app.active and " · active stream" or " · idle"),
          fontSize = 11, color = app.blocked and "tertiary" or "on_surface_variant", maxLines = 2 }),
        ui.row({ gap = 6 }, actions),
      }))
    end
    table.insert(children, ui.label({ text = "Discord alongside allows Discord, including its alerts, through focus/game protection until switched off or WirePlumber restarts. Phone release and explicit blocks still win. It does not detect joined calls.",
      fontSize = 11, color = "on_surface_variant", maxLines = 3 }))
    table.insert(children, button("Reset policy choices", "reset", nil, ready))
  end
  if errorText ~= "" then table.insert(children, ui.label({ text = errorText, color = "error", maxLines = 3 })) end
  panel.render(ui.scroll({ flexGrow = 1 }, { ui.column({ gap = 12, align = "stretch" }, children) }))
end

function onOpen() render() end
noctalia.state.watch("snapshot", function(s) if type(s) == "table" then snapshot = s; render() end end)
noctalia.state.watch("error", function(s) errorText = tostring(s or ""); render() end)
render()
