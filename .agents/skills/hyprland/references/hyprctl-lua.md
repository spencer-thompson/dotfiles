# Hyprctl and Lua Reference

Read this reference completely before using Lua dispatchers, diagnosing Hyprctl failures, discovering dispatcher names,
or waiting on compositor events. Target Hyprland 0.55+ and its Lua dispatcher API.

## Contents

- [Inspect the installed API](#inspect-the-installed-api)
- [Use each command for its actual role](#use-each-command-for-its-actual-role)
- [Preflight and validate dispatchers](#preflight-and-validate-dispatchers)
- [Target windows atomically](#target-windows-atomically)
- [Wait for compositor events](#wait-for-compositor-events)

## Inspect the installed API

Check `hyprctl version`, `hyprctl -j instances`, and monitor state only when relevant. Treat the installed
`/usr/share/hypr/stubs/hl.meta.lua` and the matching Hyprland tag's source or example config as authoritative. Never
guess a namespace, argument table, or legacy dispatcher translation.

`hyprctl dispatchers` does not exist on Hyprland 0.56, and `hyprctl dispatch --help` returns only generic CLI help.
Discover names locally:

```bash
hyprctl repl 'local o={} for k,v in pairs(hl.dsp) do o[#o+1]=k..":"..type(v) end table.sort(o) return table.concat(o,",")'
hyprctl repl 'local o={} for k,v in pairs(hl.dsp.window) do o[#o+1]=k..":"..type(v) end table.sort(o) return table.concat(o,",")'
```

On 0.56, focus is `hl.dsp.focus`, shortcuts are `hl.dsp.send_shortcut`, and window operations such as float, move, and
resize are under `hl.dsp.window`.

## Use each command for its actual role

- `hyprctl dispatch 'hl.dsp...(...)'` constructs and executes one Lua dispatcher.
- `hyprctl eval '...'` executes arbitrary Lua. Wrap a dispatcher with `hl.dispatch(hl.dsp...(...))`; evaluating only the
  constructor does not dispatch it.
- `hyprctl repl '...'` evaluates Lua and prints returned values. Keep it read-only unless mutation is intended.

Keep REPL snippets on one line. Each interactive line is a separate IPC request: locals do not cross requests, although
globals can persist in the configuration Lua state. The compositor watchdog is short, so never sleep, block, perform
shell-heavy work, or run long loops there.

Run JSON reads as standalone calls before filtering:

```bash
hyprctl -j activewindow
hyprctl -j clients
hyprctl -j activeworkspace
```

Under segmented sandboxing, a pipeline can leave `hyprctl` without compositor-socket access. The resulting
`Couldn't set socket timeout (2)` text can resemble a JSON-filter failure. Rerun the same standalone command with socket
approval, then parse the returned JSON; do not change the filter or invent environment values.

## Preflight and validate dispatchers

Preflight unfamiliar Lua without performing the intended action:

```bash
hyprctl dispatch 'hl.dsp.no_op()'
hyprctl eval 'hl.dispatch(hl.dsp.no_op())'
hyprctl repl 'return type(hl.dsp.focus({window="stableid:18000008"}))'
hyprctl repl 'return type(hl.get_window("stableid:18000008"))'
```

On Hyprland 0.56.2, a valid constructor and resolved window are `userdata`; a stale or malformed selector resolves to
`nil`. Constructor success proves syntax and argument construction, not execution. Inspect the dispatch result:

```bash
hyprctl repl 'local r=hl.dispatch(hl.dsp.no_op()); if not r.ok then error(r.error or "dispatch failed") end; return r.ok'
```

Useful result fields include `ok`, `error`, `level`, `code`, and `pass_event`. Treat false `ok` as failure even when Lua
evaluation succeeded.

## Target windows atomically

Resolve the retained stable ID, dispatch, and validate in one request to narrow the stale-target race:

```bash
hyprctl repl 'local w=hl.get_window("stableid:18000008"); if not w then error("stale target") end; local r=hl.dispatch(hl.dsp.send_shortcut({mods="CTRL",key="L",window=w})); if not r.ok then error(r.error or "dispatch failed") end; return r.ok'
```

Replace the example ID. This avoids activation and workspace switching but briefly redirects seat keyboard focus. Prefer
application IPC for arbitrary text or multi-step interaction.

Use exact selectors and `follow = false` for window operations:

```bash
hyprctl dispatch "hl.dsp.window.float({action=\"enable\",window=\"${hyprland_window_selector}\"})"
hyprctl dispatch "hl.dsp.window.move({workspace=\"3\",follow=false,window=\"${hyprland_window_selector}\"})"
hyprctl dispatch "hl.dsp.window.resize({x=1200,y=800,window=\"${hyprland_window_selector}\"})"
```

For quiet launches, use `exec_cmd` with `no_initial_focus = true` and a workspace or monitor suffixed with `silent`.
Verify the result because process forking can prevent rules from matching.

## Wait for compositor events

Use the event socket for bounded waits instead of polling:

```bash
hyprland_event_socket="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
timeout 10s socat -u UNIX-CONNECT:"$hyprland_event_socket" -
```

Stop on the expected `EVENT>>DATA` line, then re-query authoritative state. Do not wait on the synchronous request
socket. Avoid ad hoc `hl.on` subscriptions because callbacks can remain registered unless their handles are retained and
removed.
