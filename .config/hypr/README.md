# Hyprland Lua Config

This directory is the Lua-based Hyprland config for these dotfiles.

Hyprland starts from `hyprland.lua`. The old `.conf` files are still here as
legacy/reference material, but the active compositor config is the Lua path.

## Load Order

`hyprland.lua` is the entrypoint:

1. Apply one central `hl.config({ ... })` call for compositor options.
2. Register the shared `ydotoold-virtual-device` keyboard settings.
3. Load shared environment, animation, and startup behavior.
4. Load the hostname-specific device profile with `require("device")`.
5. Load shared binds, gestures, and rules:

```lua
require("modules.env")
require("modules.looks")
require("modules.exec")
local device = require("device")
require("modules.binds")
require("modules.gestures")
require("modules.rules").setup(device)
```

The intent is that `hyprland.lua` owns config values, while modules register
behavior through the dedicated Hyprland Lua APIs.

## Central Config

Keep compositor options in the single `hl.config({ ... })` call in
`hyprland.lua`.

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
- DMS color values currently copied from `dms/colors.lua`

Avoid adding new `hl.config()` calls in modules unless there is a deliberate
reason. This keeps the final state easy to reason about.

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

Profiles are data tables. They should not directly call `hl.monitor`,
`hl.device`, `hl.workspace_rule`, or `hl.on`. The loader applies the data.

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

Prefer `desc:` monitor selectors when the monitor description is known. They
are more stable than output names like `eDP-1`, `HDMI-A-1`, or `DP-1`.

Get monitor descriptions with:

```sh
hyprctl -j monitors all
```

Then use the `description` field:

```lua
local laptop_monitor = "desc:Samsung Display Corp. 0x4165"
```

The current `outrival` profile uses real `desc:` selectors for its laptop panel
and external display. Other device profiles may still use port names until their
monitor descriptions are captured while connected.

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

## DMS Colors

`dms/colors.lua` still exists and may be regenerated by DMS, but it is not
required by `hyprland.lua` right now.

The current DMS color values were copied into the central `hl.config({ ... })`
call so there is only one active config call. If you want DMS to own colors
again, re-enable `require("dms.colors")` in `hyprland.lua` and accept that it
will add another `hl.config()` call.

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
