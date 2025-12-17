# Dotfiles

These are the config files for my Arch Linux machines.

They probably will not work on your computer, but are good reference regardless 😄

## How to use

```bash
git clone --recurse-submodules
```

## Most Used Applications

My most used, _and most recommended_, applications are:

- **Neovim**: `.config/nvim/`
- **Fish**: `.config/fish/`
- **Yazi**: `.config/yazi/`
- **Starship**: `.config/starship/`
- **Atuin**: `.config/atuin/`
- **AIchat**: `.config/aichat/`
- **Keyd**: `.config/keyd/`
  - Requires some setup

## Desktop UI

- **Hyprland**: `.config/hypr/`
- **Waybar**: `.config/waybar/`
- **Swaync**: `.config/swaync/`
- **FastFetch**: `.config/fastfetch/`
- **Kitty**: `.config/kitty/`
- **Tofi**: `.config/tofi/`

## Gaming

Steam launch options for: 

**The Finals**:

```
PROTON_ENABLE_FSYNC=1 PROTON_USE_EAC_LINUX=1 PROTON_ENABLE_NVAPI=1 PROTON_USE_NTSYNC=1 PROTON_ENABLE_WAYLAND=1 gamemoderun %command% -useallavailablecores
```

**Arc Raiders**:

```
PROTON_ENABLE_FSYNC=1 PROTON_ENABLE_NVAPI=1 PROTON_USE_NTSYNC=1 PROTON_USE_EAC_LINUX=1 PROTON_ENABLE_WAYLAND=1 gamemoderun %command% -useallavailablecores
```

