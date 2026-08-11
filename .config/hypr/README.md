# Hyprland Lua Config

This directory is the Lua-based Hyprland config for these dotfiles.

Hyprland starts from `hyprland.lua`. The old `.conf` files are still here as legacy/reference material, but the active
compositor config is the Lua path.

## Load Order

`hyprland.lua` is the entrypoint:

1. Apply one central `hl.config({ ... })` call for tracked compositor options.
2. Register the shared `ydotoold-virtual-device` keyboard settings.
3. Load shared environment, animation, and startup behavior.
4. Register the custom equal-column layout.
5. Load the hostname-specific device profile with `require("device")`.
6. Load shared binds, laptop lid behavior, gestures, and rules:

```lua
require("modules.env")
require("modules.looks")
require("modules.exec")
require("modules.layouts")
local device = require("device")
require("modules.binds")
require("modules.lid").setup(device)
require("modules.gestures")
require("modules.rules").setup(device)
```

The intent is that `hyprland.lua` owns tracked config values, while modules register behavior through the dedicated
Hyprland Lua APIs. The generated `~/.config/hypr/noctalia.lua` theme is loaded with `pcall` when present so it can
override the fallback tracked colors without breaking clean checkouts.

## Central Config

Keep tracked compositor options in the single `hl.config({ ... })` call in `hyprland.lua`.

That includes:

- `input`
- `general`
- `dwindle`
- `master`
- `scrolling`
- `misc`
- `cursor`
- `render`
- `binds`
- `decoration`
- `animations`
- fallback color values, including glow color

Avoid adding new tracked `hl.config()` calls in modules unless there is a deliberate reason. The generated
`~/.config/hypr/noctalia.lua` file is the intentional local exception.

## Modules

`modules/env.lua`
: Applies environment variables with `hl.env(...)`.

`modules/programs.lua`
: Defines shared app command names used by binds and device startup entries.

`modules/looks.lua`
: Registers animation curves and animation rules with `hl.curve(...)` and
`hl.animation(...)`.

`modules/exec.lua`
: Registers shared startup commands through `hl.on("hyprland.start", ...)`.

`modules/layouts.lua`
: Registers the `equal_columns` tiled layout. It uses up to five columns, keeps
the center column full-height when side columns overflow, and owns the layout
rotation and column-width controls.

`modules/binds.lua`
: Registers shared keybinds through `hl.bind(...)`. Binds have short `desc`
labels so Hyprland can expose readable descriptions.

`modules/lid.lua`
: Owns lid and clamshell behavior on profiles that define `laptop_monitor`.

`modules/workspace_routing.lua`
: Routes profile-managed workspaces to the first connected preferred monitor when monitors appear, disappear, or the
  config reloads, and when those workspaces are created later.

`modules/gestures.lua`
: Registers touch gestures with `hl.gesture(...)`.

`modules/rules.lua`
: Registers shared layer, window, and workspace rules. It receives the loaded
device profile so monitor-specific rules can use `device.main_monitor` and
`device.secondary_monitor` when they exist.

## Equal-Column Layout

The `equal_columns` Lua layout gives one through five tiled windows equal, full-height columns. Additional windows stack
in the side columns while the third column remains full-height.

- The second tiled window opens to the right of the first. Through five windows, later windows open immediately left of
  a focused window in the left half and immediately right in the right half.
- Overflow uses the shorter column on the focused side and stacks below. A centered focus breaks left.
- `SUPER + Tab` and `SUPER + SHIFT + Tab` rotate occupants while keeping focus in the same physical slot.
- `mfact` adjusts the center column when one exists; with an even number of columns, it adjusts the focused window's
  column.

## Steam Gaming

`Super+G` focuses the named `steam` workspace. Steam game windows matching `^steam_app_[0-9]+$` open fullscreen and are
marked as game content, allowing `render.direct_scanout = 2` to attempt direct scanout whenever compositor conditions
permit it. Direct scanout can reduce compositor work and latency by presenting an eligible fullscreen game directly.

While the Steam workspace is visible and occupied on any monitor, performance mode disables animations, blur, motion
blur, shadows, glow, and rounding. Leaving or emptying the workspace restores the settings captured when automation
enabled the mode. `Super+Shift+G` remains the manual toggle and can suppress automation for the current Steam session.

## Device Profiles

Device selection is handled by `device/init.lua`.

It reads the hostname from:

```text
/proc/sys/kernel/hostname
```

Then it tries to load:

```lua
require("device.<hostname>")
```

If no matching file exists, it falls back to:

```lua
require("device.default")
```

Profiles are data tables. They should not directly call `hl.monitor`, `hl.device`, `hl.workspace_rule`, or `hl.on`. The
loader applies the data.

Supported profile fields:

- `main_monitor`
- `secondary_monitor`
- `laptop_monitor`
- `monitors`
- `devices`
- `workspaces`
- `window_rules`
- `layer_rules`
- `workspace_routing`
- `startup`
- `binds`

`workspace_routing` accepts ordered `monitors` and a list of `workspaces`. Managed workspaces follow the first connected
preferred monitor. Without one, Hyprland leaves them on the remaining or focused monitor.

## Lid And Clamshell Behavior

Laptop profiles opt in by defining `laptop_monitor`. While Hyprland is running, `modules/lid.lua` takes logind's
low-level lid-switch inhibitor so only this config handles lid events; logind's normal fallback behavior remains intact
outside Hyprland.

- Closing with an active external display enables clamshell mode and removes the internal panel from the layout.
- A mirrored external display is made standalone before the internal panel is removed.
- Closing without an external display locks and suspends the laptop.
- Disconnecting the last external display while the lid is closed locks and suspends the laptop.
- Opening the lid reapplies the active device profile's monitor rules.

Example:

```lua
local laptop_monitor = "desc:Samsung Display Corp. 0x4165"
local external_monitor = "desc:CSF HDMI"

return {
    main_monitor = external_monitor,
    secondary_monitor = external_monitor,
    laptop_monitor = laptop_monitor,

    monitors = {
        {
            output = laptop_monitor,
            mode = "3840x2400@60",
            position = "0x0",
            scale = 1.5,
        },
        {
            output = external_monitor,
            mode = "preferred",
            position = "auto",
            scale = 1,
        },
    },

    devices = {
        {
            name = "elan0683:00-04f3:320b-touchpad",
            sensitivity = 0.5,
            scroll_factor = 1.0,
        },
    },

    workspaces = {
        {
            workspace = "name:laptop",
            monitor = laptop_monitor,
            default = true,
        },
    },

    startup = {
        {
            command = "firefox",
            rules = { workspace = "1 silent" },
        },
    },

    binds = {
        {
            keys = "SUPER + grave",
            dispatcher = hl.dsp.focus({ workspace = "name:laptop" }),
            desc = "Laptop workspace",
        },
    },
}
```

## Monitor Selectors

Prefer `desc:` monitor selectors when the monitor description is known. They are more stable than output names like
`eDP-1`, `HDMI-A-1`, or `DP-1`.

Get monitor descriptions with:

```sh
hyprctl -j monitors all
```

Then use the `description` field:

```lua
local laptop_monitor = "desc:Samsung Display Corp. 0x4165"
```

The current `outrival` profile uses real `desc:` selectors for its laptop panel and external displays. Other device
profiles may still use port names until their monitor descriptions are captured while connected.

For its main monitor, `outrival` selects the connected external display in this order: work display, home display, then
the laptop panel as a fallback. Numeric workspaces 1 through 10 use the same external-display priority at runtime and
stay on the laptop when neither external is connected.

## Adding A New Device

- Check the hostname:

```sh
cat /proc/sys/kernel/hostname
```

- Create `device/<hostname>.lua`.

- Start with `device/default.lua` or an existing profile.

- Add monitor descriptions from:

```sh
hyprctl -j monitors all
```

- Validate and reload:

```sh
luac -p hyprland.lua modules/*.lua device/*.lua
lua-language-server --check=. --checklevel=Error --check_format=pretty --logpath=/tmp/hypr-lua-language-server
hyprctl reload
hyprctl configerrors
```

## Noctalia Colors

`~/.config/hypr/noctalia.lua` is generated by Noctalia's enabled Hyprland template. `hyprland.lua` attempts to load it
with `pcall(require, "noctalia")` after the tracked config is applied.

When present, the generated theme overrides the fallback border and group colors. Noctalia rewrites it when the theme
changes. When absent, Hyprland keeps the tracked fallback colors.

## Legacy Files

The `.conf` files are retained as references while the migration settles:

- `hyprland.conf`
- `modules/*.conf`
- `device/*.conf`

They are not the source of truth for the active Lua config.

## Validation

Useful checks after editing:

```sh
lua tests/binds.lua
lua tests/gestures.lua
lua tests/layouts.lua
lua tests/lid.lua
lua tests/rules.lua
lua tests/workspace_routing.lua
luac -p hyprland.lua modules/*.lua device/*.lua
lua-language-server --check=. --checklevel=Error --check_format=pretty --logpath=/tmp/hypr-lua-language-server
hyprctl reload
hyprctl configerrors
```

`hyprctl configerrors` should print nothing when the config is clean.
