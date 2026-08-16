---
name: hyprland
description: >-
  Observe and control a live Hyprland desktop. 
  Use when the user asks to inspect or interact with windows or workspaces.
---

# Hyprland

Operate the user's live desktop with an observe-act-verify loop. Preserve the active workspace and focus whenever the
task allows it. Use screenshots when appearance, layout, transient UI, or visual confirmation matters; use compositor
state alone when it fully answers the task.

## Set up safely

Use only the tools the task needs: `hyprctl` for compositor state and dispatchers, the orchestration layer or `jq` for
JSON, `grim` for screenshots, `wtype` for focused keyboard input, `ydotool` for visible pointer input, `slurp` for
interactive selection, and `socat` for compositor events.

Use the inherited `HYPRLAND_INSTANCE_SIGNATURE`, `WAYLAND_DISPLAY`, and `XDG_RUNTIME_DIR`. Request compositor or input
socket approval when sandboxing blocks access; never invent replacement values.

Run `hyprctl -j` reads as standalone tool calls, then parse their returned JSON. If a pipeline reports
`Couldn't set socket timeout (2)`, rerun the standalone `hyprctl` call with the required approval instead of changing
the filter.

Before using Lua dispatchers, diagnosing Hyprctl failures, discovering dispatcher names, or waiting on compositor
events, read [references/hyprctl-lua.md](references/hyprctl-lua.md) completely.

## Follow one workflow

1. Observe only the relevant state with `activewindow`, `activeworkspace`, `clients`, `workspaces`, `monitors`, or
   `layers`. Keep sensitive titles and metadata out of output unless needed.
2. Resolve exactly one mapped target. Retain its `stableId`, address, PID, class or initial class, and workspace ID.
3. Preserve workspace and focus. Never record or restore cursor position; query it only when the task needs coordinates.
4. Act through the least disruptive semantic interface and an exact target whenever one is accepted.
5. Verify in proportion to the action. Revalidate the retained identity before consequential actions or when it may be
   stale; stop on mismatch instead of repeating a broad match or silently choosing another window.

Use the raw `stableId` with `grim -T`. Use lowercase `stableid:<ID>` with dispatchers, falling back to
`address:<ADDRESS>` only when no stable ID exists.

## Choose the least disruptive control path

Use this order:

1. Prefer an application API, connector, CLI, IPC socket, D-Bus method, or AT-SPI action. These can often invoke
   controls or send arbitrary text without compositor focus.
2. Use a Hyprland targeted dispatcher for a discrete shortcut or window operation.
3. Use `wtype` only for the currently keyboard-focused surface.
4. Use `ydotool` or pointer dispatchers only for visible, coordinate-verified surfaces.

Respect these limits:

- `grim -T <stableId>` can capture an inactive-workspace window when foreign-toplevel capture is supported.
- `send_shortcut` can target an inactive native Wayland window without activating it or switching workspaces, but
  Hyprland briefly redirects seat keyboard focus internally. The target may observe transient focus events, and XWayland
  applications may behave differently.
- Pair every targeted `send_key_state` key-down with key-up.
- `wtype`, `ydotool`, and generic pointer input cannot target arbitrary hidden windows. Use application IPC or semantic
  accessibility actions instead.

Never focus, reveal, or switch to a hidden window merely to inspect it.

## Capture without switching workspaces

Confirm support with `grim -h | rg -q -- '-T <identifier>'`, then capture a retained stable ID:

```bash
hyprland_shot_path="$(mktemp --suffix=.png -p /tmp hyprland-window-XXXXXX)"
grim -T "$hyprland_stable_id" "$hyprland_shot_path"
```

Inspect the file with `view_image` and recapture after visual changes when useful. Omit `-c` unless the cursor matters.
An off-workspace client may throttle rendering, so corroborate a stale-looking image with compositor or application
state. Remove temporary screenshots when finished.

For content without a client stable ID, capture the smallest useful visible output or region:

```bash
grim -o DP-1 "$hyprland_shot_path"
grim -g 'X,Y WIDTHxHEIGHT' "$hyprland_shot_path"
```

If foreign-toplevel capture is unavailable, explain the limitation instead of revealing the window as a workaround.

## Handle disruptive operations

Treat focus or workspace changes, `slurp`, `wtype`, pointer movement, clicks, and ordinary launches as disruptive.
Perform them only when explicitly requested or after explaining why they are unavoidable and obtaining approval.

Immediately before disruption, notify the user without exposing task data or window titles:

```bash
notify-send -a Codex -u normal "Codex desktop automation starting" \
  "I need to temporarily change focus and use pointer input."
```

Fall back to `hyprctl notify 1 5000 0 "Codex desktop automation starting: temporarily changing focus."`. If both methods
fail, do not begin.

Re-observe immediately before coordinate or keyboard input after any visual change. Restore workspace and focus only if
the current state still matches what the automation produced; never overwrite newer user activity.

Once disruption begins, always send a completion notification, even on failure. State accurately whether prior focus and
workspace context was restored, intentionally changed, or could not be restored. Use `notify-send` first and fall back
to `hyprctl notify 5 5000 0 "Codex desktop automation finished."`; report if both fail.

## Guardrails

- Pause for confirmation before sending, submitting, purchasing, deleting, exposing private data, or closing possibly
  unsaved work. Prefer graceful close over kill.
- Avoid session exit, DPMS, compositor reload, configuration changes, and forced termination unless explicitly
  requested.
