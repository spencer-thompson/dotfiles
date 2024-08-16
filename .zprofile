# Profile file, runs on login

# Default programs
export EDITOR="nvim"
# export BROWSER="chromium"

# export ZDOTDIR="$HOME/.config/zsh"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
# export XINITRC="$XDG_CONFIG_HOME/x11/xinitrc"
#export XAUTHORITY="$XDG_RUNTIME_DIR/Xauthority" # This line will break some DMs.
#export NOTMUCH_CONFIG="$XDG_CONFIG_HOME/notmuch-config"
#export GTK2_RC_FILES="$XDG_CONFIG_HOME/gtk-2.0/gtkrc-2.0"
#export WGETRC="$XDG_CONFIG_HOME/wget/wgetrc"
#export INPUTRC="$XDG_CONFIG_HOME/shell/inputrc"
##export GNUPGHOME="$XDG_DATA_HOME/gnupg"
#export WINEPREFIX="$XDG_DATA_HOME/wineprefixes/default"
#export KODI_DATA="$XDG_DATA_HOME/kodi"
#export PASSWORD_STORE_DIR="$XDG_DATA_HOME/password-store"
#export TMUX_TMPDIR="$XDG_RUNTIME_DIR"
#export ANDROID_SDK_HOME="$XDG_CONFIG_HOME/android"
#export CARGO_HOME="$XDG_DATA_HOME/cargo"
#export GOPATH="$XDG_DATA_HOME/go"
#export GOMODCACHE="$XDG_CACHE_HOME/go/mod"
#export ANSIBLE_CONFIG="$XDG_CONFIG_HOME/ansible/ansible.cfg"
#export UNISON="$XDG_DATA_HOME/unison"
#export HISTFILE="$XDG_DATA_HOME/history"
#export MBSYNCRC="$XDG_CONFIG_HOME/mbsync/config"
#export ELECTRUMDIR="$XDG_DATA_HOME/electrum"
#export PYTHONSTARTUP="$XDG_CONFIG_HOME/python/pythonrc"
#export SQLITE_HISTORY="$XDG_DATA_HOME/sqlite_history"


# Map the caps lock key to super, and map the menu key to right super.
# setxkbmap -option caps:super,altwin:menu_win
# When caps lock is pressed only once, treat it as escape.
# killall xcape 2>/dev/null ; xcape -e 'Super_L=Escape'
# Turn off caps lock if on since there is no longer a key for it.
# xset -q | grep -q "Caps Lock:\s*on" && xdotool key Caps_Lock
# ==> Source [/home/sthom/.cache/yay/google-cloud-cli/pkg/google-cloud-cli/opt/google-cloud-cli/completion.zsh.inc] in your profile to enable shell command completion for gcloud.
# ==> Source [/home/sthom/.cache/yay/google-cloud-cli/pkg/google-cloud-cli/opt/google-cloud-cli/path.zsh.inc] in your profile to add the Google Cloud SDK command line tools to your $PATH.


xdg-user-dirs-update --set DESKTOP ~/desk
xdg-user-dirs-update --set DOWNLOAD ~/dl
xdg-user-dirs-update --set TEMPLATES ~/templates
xdg-user-dirs-update --set PUBLICSHARE ~/public
xdg-user-dirs-update --set DOCUMENTS ~/docs
xdg-user-dirs-update --set MUSIC ~/music
xdg-user-dirs-update --set PICTURES ~/pics
xdg-user-dirs-update --set VIDEOS ~/vids

# export WLR_NO_HARDWARE_CURSORS=1
export XDG_CURRENT_DESKTOP=Hyprland
export XDG_SESSION_TYPE=wayland
export XDG_SESSION_DESKTOP=Hyprland
# exec Hyprland

# [[ "$(tty)" = "/dev/tty1" ]] && exec Hyprland
