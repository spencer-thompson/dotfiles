---
name: hyprland
description: >-
  Operate desktop apps on Hyprland Wayland Linux using screenshots, keyboard and
  pointer input, and compositor control. Use for GUI tasks, window and workspace
  management, or Hyprland rendering, input, and log investigations.
---

# Hyprland

Complete the requested desktop task using the simplest effective interface. Prefer application APIs, CLI, IPC,
D-Bus, or accessibility actions when they fit; use screenshots and GUI input when the task needs them.
For desktop control, use `wdotool` for input, `hyprctl` for windows and compositor state, and `grim` for screenshots.

## Observe, act, verify

- Inspect relevant compositor state with `hyprctl -j activewindow`, `activeworkspace`, `clients`, `workspaces`,
  `monitors`, or `layers`. Use screenshots for visual details that state alone cannot answer.
- For window operations, retain an exact target: prefer `stableId`, with address as a fallback. Re-resolve after
  the window closes or is replaced; do not silently send an action intended for it to a different window.
- Perform a short, coherent group of actions, then check the result. Refresh observations when focus, layout,
  or content changes could invalidate the next action. Verify outcomes, not just command success.

Use the inherited `HYPRLAND_INSTANCE_SIGNATURE`, `WAYLAND_DISPLAY`, and `XDG_RUNTIME_DIR`. If sandboxing blocks a
socket, use the normal approval mechanism for that command rather than guessing replacement environment values.

For Lua dispatchers, targeting examples, or IPC failures, consult [hyprctl-lua.md](references/hyprctl-lua.md).
This installation uses the Hyprland 0.55+ Lua API; check installed stubs for unfamiliar calls instead of trying
legacy dispatcher syntax. For logs, crashes, rendering, or latency, consult [log-triage.md](references/log-triage.md).

## Capture and input

Use `grim` for screenshots. Check `grim -h` for `-T` support, then capture a window without changing workspaces:

```bash
hyprland_shot_path="$(mktemp --suffix=.png -p /tmp hyprland-window-XXXXXX)"
grim -T "$hyprland_stable_id" "$hyprland_shot_path"
```

Use the raw stable ID for `grim -T` and `stableid:<ID>` for dispatchers. Inspect captures with `view_image`.
If window capture is unavailable or the target has no stable ID, capture a visible output with `grim -o <output>`
or a region with `grim -g 'X,Y WIDTHxHEIGHT'`. Derive output names and geometry from current state.
Off-workspace windows may throttle rendering; corroborate stale-looking captures with application or compositor state.
Remove temporary captures when finished unless they are task deliverables.

Choose input according to what it can actually target:

- Application interfaces and AT-SPI can operate controls without focus when supported.
- Targeted Hyprland dispatchers suit window operations and discrete shortcuts. `send_shortcut` can reach an inactive
  native Wayland window, but briefly redirects seat keyboard focus; XWayland behavior may differ.
- Use `wdotool` for focused keyboard input and visible pointer interaction. Its `wlr-protocols` backend works on this
  Hyprland installation without a separate daemon. Use `wdotool info` or `diag` when troubleshooting.

Common input commands, after observing the target:

```bash
wdotool key ctrl+a
wdotool type 'Text with Unicode: café ✓'
wdotool mousemove "$hyprland_pointer_x" "$hyprland_pointer_y"
wdotool click 1
wdotool key Escape
```

Pointer coordinates are desktop coordinates. Account for screenshot resizing, window origin, and output scale;
do not use coordinates from a resized window capture directly. Use `hyprctl cursorpos` when verifying pointer placement:
wdotool's current Hyprland backend cannot read pointer position or window geometry.

Keep `wtype` and `ydotool` as fallbacks. For observed compatibility issues and daemon requirements, consult
[input troubleshooting](references/input-troubleshooting.md). Stop any temporary daemon after use.

Pair `send_key_state` key-down with key-up. A hidden workspace or virtual output does not provide independent input
focus; use application interfaces for background interaction, or bring the target forward when the task requires it.

## Share the desktop

The user's task authorizes ordinary focus changes, typing, clicks, and launches needed to complete it. Do not ask
again for each mechanism. Ask when the target or consequences are materially unclear, or an action exceeds existing
authorization. Inspecting an app does not by itself authorize submitting its content or discarding unsaved work.

Prefer background operations when practical. Before taking over foreground input, briefly tell the user in chat;
desktop notifications are optional. If user activity changes the target or focus during input, pause and re-observe.
Avoid fighting the user's keyboard or pointer.

Restore prior workspace and focus after temporary interaction when useful, but only if they still match the state
left by the automation. Leave the requested final layout intact and never overwrite newer user activity.
