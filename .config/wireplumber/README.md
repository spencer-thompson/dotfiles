# Personal audio policy

Design for this desktop, Sony WH-1000XM5 headphones, and phone handoff.
Status: design only; custom routing scripts are not implemented or enabled yet.

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
| Music | Spotify usually takes precedence | Define precedence over other permitted media |
| Games | Uninterrupted gaming; optionally mix Spotify with game audio; incoming calls appear visually without changing game audio | How gaming/mix mode is selected |
| Interruptions | Calls are an exception outside gaming; otherwise consider Noctalia DND | Which apps qualify as calls or important alerts |
| Browser | Treat Firefox as one app initially | App admission policy remains undecided |
| Phone handoff | Prefer switching by pressing play on the desired device | Prove PC stream release works; phone intent is not directly observable |
| Reconnect/reboot | Restore last choice, with carefully bounded state | Exact lifetime of temporary overrides |
| Headphone loss | Move to available speakers, otherwise pause | Non-pausable apps and inaccurate availability reporting |
| Microphone | DJI Mic 3 over the tower's top USB port; USB capture verified and saved as the preferred input | Normal speaking-level/quality check; future priority list and Sony fallback remain undecided |
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

## State ownership (proposed implementation)

| Data | Location | Lifetime |
|---|---|---|
| Policy definitions and approved device priorities | Dotfiles WirePlumber configuration | Version-controlled preferences |
| Last manually selected output/mic and native route/profile/volume state | `~/.local/state/wireplumber/` | Existing WirePlumber persistence; do not duplicate |
| Last explicitly selected custom mode, if needed | `~/.local/state/audio-policy/state.json` | Minimal versioned state outside Git |
| Active streams, current owner(s), block reasons, DND mirror, temporary grants | Runtime memory / PipeWire metadata | Recomputed; not restored as stale facts |

Use stable device/application identifiers, not session numeric IDs. Restore a saved selection only if the target still
exists and the current policy permits it; otherwise follow the approved fallback. Store a small schema version and use
atomic writes for custom state. Expose inspect/reset commands. Read DND from Noctalia rather than keeping a second
persistent DND preference. Configuration is authoritative; stale runtime state cannot override it.

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
Prototype one behavior, verify restoration of normal routing, then expose it through terminal or Noctalia controls.

First unresolved test: temporarily remove Firefox's stream from the Sony route without closing the tab, then retry
YouTube on the phone. The first trace showed a successful deliberate power-cycle reconnect and an active PC stream;
it did not establish why the phone paused. Confirm the interference before building policy around it.

Active isolation test: after Spencer paused Spotify, Firefox stream 7246 (PipeWire node 98) was temporarily moved
to `spencer_handoff_test`, a null output. Restoration details live in `/run/user/1000/spencer-audio-handoff.json`.
Restore Firefox to its original Sony route and remove the temporary routing metadata/module after the phone trial;
do not treat the test destination as a permanent application preference.

Per-tab permissions may require browser integration. PC routing policy cannot directly control phone playback or
repair Bluetooth controller firmware. Report those boundaries accurately.

Reference: [WirePlumber custom scripts](https://pipewire.pages.freedesktop.org/wireplumber/scripting/custom_scripts.html).
