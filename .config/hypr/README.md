# Hyprland Lua Config

This directory is the Lua-based Hyprland config for these dotfiles.

Hyprland starts from `hyprland.lua`. The old `.conf` files are still here as legacy/reference material, but the active
compositor config is the Lua path.

## Load Order

`hyprland.lua` is the entrypoint:

1. Apply one central `hl.config({ ... })` call for tracked compositor options.
2. Register the shared `ydotoold-virtual-device` keyboard settings.
3. Load shared environment, animation, and startup behavior.
4. Load the hostname-specific device profile with `require("device")`.
5. Load shared binds, laptop lid behavior, gestures, and rules:

```lua
require("modules.env")
require("modules.looks")
require("modules.exec")
local device = require("device")
require("modules.binds")
require("modules.lid").setup(device)
require("modules.gestures")
require("modules.rules").setup(device)
```

The intent is that `hyprland.lua` owns tracked config values, while modules register behavior through the dedicated
Hyprland Lua APIs. The ignored generated `dms/colors.lua` file is loaded with `pcall` when present so local Matugen
colors can override the fallback tracked colors without breaking clean checkouts.

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

`modules/binds.lua`
: Registers shared keybinds through `hl.bind(...)`. Binds have short `desc`
labels so Hyprland can expose readable descriptions.

`modules/lid.lua`
: Owns lid and clamshell behavior on profiles that define `laptop_monitor`.

`modules/gestures.lua`
: Registers touch gestures with `hl.gesture(...)`.

`modules/rules.lua`
: Registers shared layer, window, and workspace rules. It receives the loaded
device profile so monitor-specific rules can use `device.main_monitor` and
`device.secondary_monitor` when they exist.

`modules/plugins.lua`
: Returns plugin config data. It is not required by default because the old
plugin config was commented out too.

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
- `startup`
- `binds`

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

The current `outrival` profile uses real `desc:` selectors for its laptop panel and external display. Other device
profiles may still use port names until their monitor descriptions are captured while connected.

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

`~/.config/hypr/noctalia.lua` is generated by Noctalia's enabled Hyprland template. `hyprland.lua` loads it with
`require("noctalia").apply_theme()` after the tracked config is applied.

The generated theme overrides the fallback border and group colors and is rewritten when Noctalia's theme changes.
Because the loader is strict, keep the template enabled and ensure the generated file exists before reloading Hyprland.

## Legacy Files

The `.conf` files are retained as references while the migration settles:

- `hyprland.conf`
- `modules/*.conf`
- `device/*.conf`

They are not the source of truth for the active Lua config.

## Validation

Useful checks after editing:

```sh
luac -p hyprland.lua modules/*.lua device/*.lua
lua-language-server --check=. --checklevel=Error --check_format=pretty --logpath=/tmp/hypr-lua-language-server
hyprctl reload
hyprctl configerrors
```

`hyprctl configerrors` should print nothing when the config is clean.
