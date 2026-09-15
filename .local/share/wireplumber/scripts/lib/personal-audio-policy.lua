-- Pure decisions: explicit choices, never inferred from foreground or silence.
local M = {}

function M.defaults()
  return { version = 1, mode = "normal", owner = "", mix = false, blocked = {} }
end

function M.identity(p)
  -- Wine's binary is shared by different games; application.name distinguishes them.
  for _, key in ipairs({ "application.id", "application.name", "application.process.binary", "node.name" }) do
    if type(p[key]) == "string" and p[key] ~= "" then
      return key .. ":" .. p[key]
    end
  end
  return "unknown"
end

function M.validate(s)
  if type(s) ~= "table" or s.version ~= 1 then return false end
  if s.mode ~= "normal" and s.mode ~= "focus" and s.mode ~= "game" then return false end
  if type(s.owner) ~= "string" or type(s.mix) ~= "boolean" or type(s.blocked) ~= "table" then return false end
  if s.mode ~= "normal" and s.owner == "" then return false end
  for k, v in pairs(s.blocked) do
    if type(k) ~= "string" or v ~= true then return false end
  end
  return true
end

function M.is_discord(p)
  return (p["application.process.binary"] or ""):lower() == "discord"
    or (p["application.name"] or ""):lower() == "discord"
end

function M.is_call(p)
  local role = (p["media.role"] or ""):lower()
  return role == "communication" or role == "phone" or M.is_discord(p)
end

function M.is_spotify(p)
  return (p["application.name"] or ""):lower() == "spotify"
    or (p["application.process.binary"] or ""):lower() == "spotify"
end

function M.is_media(p)
  local name = (p["application.name"] or ""):lower()
  local binary = (p["application.process.binary"] or ""):lower()
  local role = (p["media.role"] or ""):lower()
  return name == "firefox" or name == "chromium" or name == "google chrome"
    or binary == "firefox" or binary == "chromium" or binary == "google-chrome"
    or role == "music" or role == "movie"
end

function M.decide(s, runtime, p)
  if p["media.class"] ~= "Stream/Output/Audio" or p["node.link-group"] then return nil end
  local id = M.identity(p)
  local role = (p["media.role"] or ""):lower()
  local call = M.is_call(p)
  if runtime.phone then return "Released for phone" end
  if s.blocked[id] then return "Blocked by you" end
  if runtime.discord and M.is_discord(p) then return nil end
  if runtime.allowed and runtime.allowed[id] then return nil end
  -- A game or call stays admitted through silence, mute, and media-player events.
  local protected = call or (runtime.exempt or {})[id] or (s.mode == "game" and id == s.owner)
  local playback = (runtime.playback or {})[id]
  if not protected and (playback == "Paused" or playback == "Stopped") then
    return "Media player " .. playback:lower()
  end
  if s.mode == "game" or s.mode == "focus" then
    if id == s.owner then return nil end
    if s.mode == "game" and s.mix and (p["application.name"] or ""):lower() == "spotify" then return nil end
    if s.mode == "focus" and call then return nil end
    return s.mode == "game" and "Game protected; allow to join this session" or "Another app has focus"
  end
  if runtime.dnd and (role == "notification" or role == "event") and not call then
    return "Do not disturb"
  end
  if s.mode == "normal" and runtime.spotify and not s.blocked[runtime.spotify] and not protected and not M.is_spotify(p)
      and (M.is_media(p) or playback ~= nil) then
    return "Spotify is playing"
  end
  return nil
end

function M.explain(s, runtime, p)
  local blocked = M.decide(s, runtime, p)
  if blocked then return blocked end
  if runtime.discord and M.is_discord(p) then return "Discord allowed alongside other audio" end
  if s.mode == "game" and M.identity(p) == s.owner then return "Protected game" end
  if M.is_call(p) then return "Call app allowed" end
  local playback = (runtime.playback or {})[M.identity(p)]
  return playback and ("Allowed · media player " .. playback:lower()) or "Allowed · playback state unknown"
end

return M
