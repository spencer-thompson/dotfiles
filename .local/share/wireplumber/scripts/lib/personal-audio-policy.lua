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

function M.decide(s, runtime, p)
  if p["media.class"] ~= "Stream/Output/Audio" or p["node.link-group"] then return nil end
  local id = M.identity(p)
  local role = (p["media.role"] or ""):lower()
  local call = role == "communication" or role == "phone"
    or (p["application.process.binary"] or ""):lower() == "discord"
  if runtime.phone then return "Released for phone" end
  if s.blocked[id] then return "Blocked by you" end
  if runtime.allowed and runtime.allowed[id] then return nil end
  if s.mode == "game" or s.mode == "focus" then
    if id == s.owner then return nil end
    if s.mode == "game" and s.mix and (p["application.name"] or ""):lower() == "spotify" then return nil end
    if s.mode == "focus" and call then return nil end
    return s.mode == "game" and "Game protected; allow to join this session" or "Another app has focus"
  end
  if runtime.dnd and (role == "notification" or role == "event") and not call then
    return "Do not disturb"
  end
  return nil
end

return M
