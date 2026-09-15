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
s, r = p.defaults(), { allowed = {}, playback = {} }
r.playback[p.identity(firefox)] = "Paused"
assert(p.decide(s, r, firefox) == "Media player paused")
r.playback[p.identity(firefox)] = nil
r.spotify = p.identity(spotify)
assert(p.decide(s, r, firefox) == "Spotify is playing")
assert(p.decide(s, r, game) == nil)
assert(p.decide(s, r, call) == nil)
s.blocked[p.identity(spotify)] = true
assert(p.decide(s, r, firefox) == nil)
s.blocked = {}
r.exempt = { [p.identity(firefox)] = true }
r.playback[p.identity(firefox)] = "Paused"
assert(p.decide(s, r, firefox) == nil)
r.exempt, r.playback = {}, {}
s.mode, s.owner = "game", p.identity(game)
r.discord = true
assert(p.decide(s, r, call) == nil)
r.playback[p.identity(call)] = "Paused"
r.playback[p.identity(game)] = "Paused"
assert(p.decide(s, r, call) == nil)
assert(p.decide(s, r, game) == nil)
assert(p.decide(s, r, spotify) ~= nil)
s.mix = true
assert(p.decide(s, r, spotify) == nil)
s.blocked[p.identity(call)] = true
assert(p.decide(s, r, call) == "Blocked by you")
r.phone = true
assert(p.decide(s, r, call) == "Released for phone")
print("Policy precedence checks passed: playback, unknowns, capture, game + Discord + Spotify, overrides")
