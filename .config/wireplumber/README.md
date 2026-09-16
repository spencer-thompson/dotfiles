# Personal audio policy

Personal audio controls for this desktop, Sony WH-1000XM5 headphones, and phone handoff.
Status: first implementation installed and activated September 13; Noctalia controls enabled.
Real routing tests passed on a separate hardware-free audio server. Initial activation disconnected the Sonys and
playback fell back to unused S/PDIF. Reconnecting restored Discord; Spencer confirmed audio returned.
Activation now skips restarts when already active, checks for idle as well as running call/capture streams,
and reconnects/restores the selected devices before reporting success. Recovery logic has regression tests;
do not restart during a call to retest it on hardware.

## Use the first version

Click the new headphones widget or run `audio-policy panel`. On a fresh installation, after calls end, run
`audio-policy activate` once. It restarts WirePlumber and restores selected output/mic, refusing when a call or
non-monitor capture stream exists. If already active, it returns without restarting.
WirePlumber owns routing. The `audio-policy-watch` user service observes media-player state using the existing
Python GObject bindings (`python-gobject`); it does not record audio or manage Bluetooth connections.

Automatic Bluetooth headset-profile switching is disabled in `90-personal-audio.conf`.
Use the DJI microphone while the Sonys stay in music mode; using the Sony microphone requires
manually selecting a headset profile. This setting applies to all Bluetooth headsets.
LDAC remains unchanged while evaluating whether avoiding profile switches improves reliability.

| Control | Behavior |
|---|---|
| Output / Microphone | Select the native WirePlumber default; remember the choice using existing device state |
| Normal | Give locally playing Spotify priority over browser/other media; hold confirmed paused media; preserve explicit blocks and DND |
| Focus, beside an app | Give that app playback focus; recognized calls remain permitted |
| Protect game, beside an app | Hold other apps silently, including incoming call audio; existing visual call UI stays available |
| Spotify mix | Permit Spotify alongside the selected game |
| Discord alongside | Permit Discord through focus/game protection until switched off or WirePlumber restarts; also permits Discord alerts |
| Block / Allow | Remember explicit blocks; Allow removes a block and admits the app to the current focus/game session |
| Release for phone / Return to PC | Hold all ordinary PC playback until manual return or a new tracked PC media start; survives restarts |
| Apps & block reasons | Expand to see active/idle streams, explicit controls, and explanations |
| Reset policy choices | Clear custom choices and blocks; preserve native device and volume preferences |

Pause music before releasing for the phone if you want to keep your place. Held apps continue playback silently.
Open the panel with `audio-policy panel`, then choose **Release for phone**. Phone mode stays selected through
pauses, notification sounds, observer restarts, and WirePlumber restarts. A tracked PC player changing to Playing
with a running local stream returns to PC automatically, provided your saved focus/game rules admit it. Existing
Playing state does not count; pause and play again if the player was already playing when you released for phone.
Spotify and supported browser media can trigger return; untracked sounds and games cannot. Browser autoplay can
also count as Playing because MPRIS does not identify whether you pressed Play. Manual **Return to PC** always works.
This is routing policy for ordinary autoconnecting desktop playback, not an application security boundary;
applications that manage their own PipeWire links and linked audio filters are outside this first version.
Current owners means active, allowed streams, not verified audible sound.

Terminal controls accept stable IDs from `audio-policy status --json`:

```sh
audio-policy status
audio-policy focus 'application.name:Spotify'
audio-policy game 'application.name:Stardew Valley'
audio-policy mix on
audio-policy discord on
audio-policy discord off
audio-policy block 'application.name:Firefox'
audio-policy allow 'application.name:Firefox'
audio-policy release
audio-policy resume
audio-policy normal
audio-policy reset
```

Calls are recognized by the communication/phone media role or Discord identity. Game mode does not distinguish
ringing from an already joined call: turn on Discord alongside when choosing to talk while gaming, and off afterward.
This permission survives focus/game changes and quiet/muted calls. Explicit blocks and Release for phone still win.
Other call apps can use the existing Allow control. No automatic joined-call detection is claimed.
DND is mirrored by the Noctalia service every two seconds and suppresses only streams tagged notification/event.
Unlabelled notification sounds inside a browser cannot be distinguished from that browser's other playback.

Still to iterate: automatic switch-by-pressing-play handoff; identify/test the real speaker fallback; additional
call-app identities; physical-device reconnect and microphone-fallback testing. Existing WirePlumber fallback/pause
behavior is retained. DJI is given a fallback priority boost without overriding manually saved mic choices. No DSP
is added; automatic Bluetooth headset-profile switching is disabled as described above.

### Automatic playback tracking

`audio-policy-watch` listens for MPRIS player appearance, disappearance, and playback-status changes on the session
bus. It matches Spotify, Firefox, Chromium, and Google Chrome identities and sends temporary observations through
the policy's `playback` metadata key. A two-second heartbeat also checks live streams. WirePlumber applies these rules:

- Spotify gets automatic priority in Normal mode only when MPRIS says Playing and a local Spotify stream is running.
  Explicit Focus/game choices win; games and recognized calls are not displaced by normal media priority.
- Confirmed Paused/Stopped media streams move to the holding output after a 1.5-second grace period, observed on
  the next refresh (normally within about 3.5 seconds). Playing restores eligibility without overriding explicit rules.
- Browser players are aggregated per application: any Playing player wins over paused tabs. A failed or missing
  status is unknown. This is not per-tab routing or silence detection, and autoplay is not proof of user intent.
- Browser capture exempts that browser from automatic media suppression, protecting unlabelled web calls. Game
  protection can still require explicitly allowing the browser. Protected games and recognized calls ignore paused
  media observations; silence and microphone mute never end their permission.
- Explicit Allow overrides automatic holding. Block and Release for phone override all playback and call permissions.
- If the observer stops reporting for roughly 12 seconds, its restrictions expire. Manual choices remain intact.

Firefox can keep an audio stream without exposing an MPRIS player, as observed on September 15. Such streams remain
unknown; Spotify priority can hold them while Spotify plays, but pausing Spotify alone cannot guarantee phone handoff.
Use Release for phone in that case. Reliable phone intent and complete browser activity tracking need additional
integration. These routing rules do not repair Bluetooth packet/firmware failures.

The panel and `audio-policy status` show tracking availability and reasons such as “Spotify is playing,”
“Media player paused,” “Discord allowed alongside other audio,” and “playback state unknown.” Automatic state and
Discord permission are temporary; they do not overwrite saved focus, mixing, device, or app-block preferences.

## Install / verify / undo

Stow supplies the matching home paths. To register the personal panel on a fresh installation:

```sh
noctalia msg plugins source add personal-audio path "$HOME/dotfiles/.config/noctalia/plugins"
noctalia msg plugins enable sthom/audio-policy
audio-policy activate  # after calls/recordings, not during one
systemctl --user daemon-reload
systemctl --user enable --now audio-policy-watch.service
```

After updating an already active Lua policy, use `audio-policy activate --reload` after calls and recordings end.
It checks for capture/call streams and restores the selected devices. The observer reconnects after a policy restart.
For a fresh checkout, Stow must link the new service unit and executable before enabling the service.

Tests create a private PipeWire socket, state directory and D-Bus session; hardware monitors are disabled:

```sh
lua .config/wireplumber/tests/policy.lua "$PWD"
python .config/wireplumber/tests/activation.py
dbus-run-session -- python .config/wireplumber/tests/integration.py
noctalia plugins lint .config/noctalia/plugins/audio-policy
```

For ordinary recovery, `audio-policy reset` clears custom choices and returns to Normal mode. Automatic playback
rules resume when the observer next reports; stop the observer too if diagnosing those rules.
To remove the policy completely, rename `wireplumber.conf.d/90-personal-audio.conf` to end in `.conf.disabled`
and restart WirePlumber after calls end. Disable the panel with `noctalia msg plugins disable sthom/audio-policy`.
Stop the observer with `systemctl --user disable --now audio-policy-watch.service`.
The microphone priority boost is removed with that fragment; native saved preferences remain.

## Troubleshoot dropouts and phone handoff

Start with read-only checks. Note the symptom and approximate local time, then compare audio, Bluetooth,
and kernel events at that time. `-b` selects the current boot; `-o short-iso` includes the date and timezone.
Run these commands as your desktop user so the audio commands reach the correct session.

```sh
# Audio services
journalctl --user -b -u wireplumber -u pipewire -u pipewire-pulse --no-pager -o short-iso

# Bluetooth service
journalctl -b -u bluetooth --no-pager -o short-iso

# Kernel Bluetooth events
journalctl -b -k --no-pager -o short-iso | rg -i 'bluetooth|btusb|hci0'

# Current policy, selected devices, and automatic headset-profile switching
audio-policy status
wpctl status
wpctl settings bluetooth.autoswitch-to-headset-profile
systemctl --user status audio-policy-watch.service
journalctl --user -b -u audio-policy-watch.service --no-pager -o short-iso

# Example: narrow an audio-log query to the time of a dropout (local time)
journalctl --user -b -u wireplumber -u pipewire -u pipewire-pulse \
  --since '2026-09-15 13:00:00' --until '2026-09-15 13:05:00' --no-pager -o short-iso
```

Use the same `--since` and `--until` window for Bluetooth and kernel queries. If the journal reports insufficient
permissions, use `sudo` for the system Bluetooth/kernel queries; keep `--user` audio queries under your own user.

Interpret the evidence before changing settings:

- Bluetooth transport failures or an unexpectedly terminated connection confirm an audio connection failure.
  They do not identify whether the trigger was the adapter, headset, interference, or device switching.
- Missing packet-completion reports suggest a Bluetooth transport/controller problem. A log message asking
  “Bluetooth adapter firmware bug?” is a hypothesis, not proof of faulty firmware.
- `wp_properties_get: assertion 'self != NULL' failed` needs separate investigation. The message alone does
  not establish that the custom policy caused the dropout, or that the warning is harmless.
- `audio-policy status` describes the current state, not the state at an earlier failure. If it shows phone
  release, use Return to PC or `audio-policy resume` when you want PC playback again.

The WH-1000XM6 supports switching playback to the second device through its own multipoint behavior; the custom
policy does not implement automatic phone-intent detection. Phone notification sounds can also trigger unwanted
switches. See [Sony's multipoint guide](https://helpguide.sony.net/mdr/2984/v1/en/contents/TP1001863603.html).

### Example investigation: September 15, 2026

On `outrival`, momentary dropouts and phone-to-PC handoff trouble coincided with these logged events (Eastern time):

| Time | Evidence |
|---|---|
| 12:38 p.m. | Missing Bluetooth packet-completion reports |
| 1:01–1:03 p.m. | Repeated Sony audio transport failures; kernel reported an unknown voice connection handle |
| 1:03 p.m. | DJI receiver disconnected and reappeared; plugging in or powering on could explain this |
| 1:41 p.m. | Sony audio connection terminated unexpectedly |

The audio services stayed running. Recurring property warnings were not traced to a cause. Automatic Bluetooth
headset-profile switching was subsequently disabled in `90-personal-audio.conf` and applied live with
`wpctl settings bluetooth.autoswitch-to-headset-profile false`. The Sony output and DJI input remained selected;
LDAC was left unchanged. This is a trial to avoid profile-switch interruptions, not a confirmed fix for the
dropouts. Compare behavior after each change before trying another codec or changing controller settings.
Avoid restarting WirePlumber during a call or recording.

## Version-one scope

Spencer selected all three areas for version one:

- PC ↔ phone handoff.
- Control over which applications may play.
- Predictable output and microphone selection.

Build and verify these incrementally as one coherent system. App admission policy remains undecided; preserve existing
playback permissions during prototyping rather than introducing an unchosen allowlist or permission prompts.

## Design principle

Spencer decides intent. The software should enforce explicit choices, show what currently owns an audio route, and
explain changes. Silence, background status, or an open stream alone must not be treated as permission to interrupt an
application. A persistent preference can authorize automatic behavior; repeated confirmation is unnecessary.

## Requested behavior

| Area | Spencer's preference | Unresolved detail |
|---|---|---|
| Scope | Same policy for Bluetooth and speakers | Identify the intended physical speaker output |
| Music | Spotify usually takes precedence | Automatic priority in Normal mode; explicit Focus/game choices win |
| Games | Uninterrupted gaming; optionally mix Spotify with game audio; incoming calls appear visually without changing game audio | Explicit Protect game / Spotify mix controls implemented; test with real sessions |
| Interruptions | Calls are an exception outside gaming; otherwise consider Noctalia DND | Which apps qualify as calls or important alerts |
| Browser | Treat Firefox as one app initially | App admission policy remains undecided |
| Phone handoff | Prefer switching by pressing play on the desired device | Manual release proved useful; automatic phone intent is not directly observable |
| Reconnect/reboot | Restore last choice, with carefully bounded state | Exact lifetime of temporary overrides |
| Headphone loss | Move to available speakers, otherwise pause | Non-pausable apps and inaccurate availability reporting |
| Microphone | DJI Mic 3 over the tower's top USB port; capture and listening verified, saved as preferred input | Future priority list and Sony fallback remain undecided |
| Interface | Noctalia panel plus terminal commands for optional Hyprland bindings | Integrate with existing audio-switcher where practical |

Panel hierarchy: output and microphone first, current audio owner(s) next, then a button or expander for allowed
applications and any blocked applications with reasons. Show multiple owners when music and a game are intentionally
mixed.

Success means a working microphone, good audio, and a pleasant listening experience Spencer controls. An enumerated
input is not automatically a working microphone. Confirm actual recording before assigning priority; do not infer
quality from names or silently enable the Sony hands-free profile.

Microphone verified September 13 after Spencer plugged in/powered on the receiver and confirmed its meter moved:
DJI `2ca3:4015` re-enumerated as high-speed USB with an ALSA audio device. Earlier, it exposed only vendor-specific
interfaces while apparently off. Device power/state is the leading explanation for the missing input; replacing
the microphone or connection type is not indicated by this test.

An eight-second capture process received 286720 stereo frames with equal left/right levels (peak 0.029176,
RMS 0.002074) and no clipped samples. Audio was processed in memory for levels, not saved. This verifies signal
delivery, not subjective speech quality; subsequent listening results are recorded below.
The default was saved through `pactl` and verified in WirePlumber's native state. Stable source name:
`alsa_input.usb-DJI_Technology_Co.__Ltd._Wireless_Mic_Rx_XSP12345678-00.analog-stereo`.

Follow-up voice test: 3.94 seconds of room noise averaged -55.4 dBFS; 12 seconds of speech peaked at -9.8 dBFS
and averaged -31.1 dBFS, with zero clipped samples on either channel. No gain changes applied. Sample playback
through the Sony headphones was offered from memory. Spencer found playback a little quiet and requested louder,
cleaner call audio with background noise reduction. Raised the raw DJI source from 0 dB to +3 dB.
Spencer then enabled DJI noise cancellation, adjusted settings on the device, and approved the final playback test
as sounding good. The final quiet interval included speech, so its room-noise measurement is invalid. Exact final
DJI settings were not recorded; preserve the current device settings as the accepted listening baseline. No software
noise suppressor was installed. Avoid stacking processing without a comparison.

## State ownership

| Data | Location | Lifetime |
|---|---|---|
| Policy definitions and approved device priorities | Dotfiles WirePlumber configuration | Version-controlled preferences |
| Last manually selected output/mic and native route/profile/volume state | `~/.local/state/wireplumber/` | Existing WirePlumber persistence; do not duplicate |
| Explicit mode, owner app, Spotify mixing, app blocks | `~/.local/state/wireplumber/personal-audio-policy` | Version 1 JSON inside WirePlumber's native atomic state file; no second state writer |
| Phone mode | `~/.local/state/wireplumber/personal-audio-policy` | Saved until manual return or a fresh permitted PC media start |
| Discord permission, temporary grants, DND, playback observations and reasons | `personal-audio` PipeWire metadata / script memory | Runtime only; observations expire without heartbeats; other temporary choices clear on restart |

Use stable device/application identifiers, not session numeric IDs. WirePlumber restores native device preferences.
Custom focus/game choice stays selected if its app disappears, so background apps do not unexpectedly take over;
select Normal to clear focus. Unsupported or malformed saved policy falls back to Normal with a journal warning.
`audio-policy status --json` inspects current choices; `reset` clears them. The custom state file replaces the earlier
proposed separate `audio-policy/state.json`, avoiding a second persistence implementation.

## Dotfiles layout

| Repository path | Purpose |
|---|---|
| `.config/wireplumber/wireplumber.conf.d/` | Declare and load custom components; define settings |
| `.local/share/wireplumber/scripts/` | Lua policy and event hooks |
| `.local/bin/` | Optional terminal controls for selecting policy |
| `.config/noctalia/` | Existing desktop controls; add audio actions here when useful |

The repository's `install.sh` uses GNU Stow to link files into the matching paths under the home directory.
Deploy and validate the specific new paths during development; review a Stow dry run before restowing the whole repo.
WirePlumber scripts need a component declaration and an enabled profile feature; merely placing Lua files in the
scripts directory does not activate them. Use WirePlumber 0.5 configuration, not the old 0.4 Lua configuration format.

Keep code and declared preferences in Git. Runtime state, logs, and Bluetooth pairing keys stay outside the repository.
The adapter's root-owned udev power rule is separate system configuration; it is not installed by home-directory Stow.

## Implementation approach

Use WirePlumber's existing event and target-selection machinery. Define the precedence of explicit choices over
automatic routing, including how a choice is cleared. Do not add a competing session manager or restart-loop daemon.
The first implementation uses Lua target-selection hooks, a virtual holding output, a small Python terminal client,
and a Noctalia Luau panel/service. It never writes per-stream target metadata, so temporary holding routes cannot be
saved as permanent application device preferences. Native output and microphone selection use `wpctl set-default`.

Phone-handoff isolation test succeeded on September 13: with Spotify confirmed paused, moving Firefox's active
stream to a temporary null output made the Sony sink SUSPENDED while Bluetooth stayed connected. Spencer then
played YouTube on the phone successfully, with no reported weirdness. This strongly implicates the PC's continued
Firefox stream in this specific failed handoff; it does not diagnose every earlier controller/transport error.

After the trial, Firefox was restored to its original Sony route, its temporary `target.node` and `target.object`
metadata were deleted, and the null output module and runtime restoration file were removed. WirePlumber's existing
stream-state hook clears the saved application target on metadata deletion. Permanent app permissions are still
undecided; do not implement blanket Firefox blocking based on this test.

Per-tab permissions may require browser integration. PC routing policy cannot directly control phone playback or
repair Bluetooth controller firmware. Report those boundaries accurately.

Reference: [WirePlumber custom scripts](https://pipewire.pages.freedesktop.org/wireplumber/scripting/custom_scripts.html).
