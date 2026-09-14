local root = assert(arg[1])
package.path = root .. "/.local/share/wireplumber/scripts/lib/?.lua;" .. package.path
local p = require("personal-audio-policy")
local s, r = p.defaults(), { allowed = {} }
local function stream(name, role)
  return { ["media.class"] = "Stream/Output/Audio", ["application.name"] = name, ["media.role"] = role }
end
local game, spotify, firefox = stream("Stardew Valley"), stream("Spotify"), stream("Firefox")
local call = stream("WEBRTC VoiceEngine")
call["application.process.binary"] = "Discord"
assert(p.validate(s))
assert(not p.validate({ version = 2 }))
assert(p.decide(s, r, firefox) == nil)
s.mode, s.owner = "game", p.identity(game)
assert(p.decide(s, r, game) == nil)
assert(p.decide(s, r, spotify) ~= nil)
assert(p.decide(s, r, call) ~= nil)
s.mix = true
assert(p.decide(s, r, spotify) == nil)
r.allowed[p.identity(call)] = true
assert(p.decide(s, r, call) == nil)
s.blocked[p.identity(spotify)] = true
assert(p.decide(s, r, spotify) == "Blocked by you")
r.phone = true
assert(p.decide(s, r, game) == "Released for phone")
assert(p.decide(s, r, { ["media.class"] = "Stream/Input/Audio" }) == nil)
r.phone, s.mode, r.allowed = false, "focus", {}
assert(p.decide(s, r, call) == nil)
s.mode, r.dnd = "normal", true
assert(p.decide(s, r, stream("Alert", "Notification")) == "Do not disturb")
assert(p.decide(s, r, call) == nil)
assert(p.identity(game) ~= p.identity(stream("Another Wine game")))
print("Policy precedence checks passed")
