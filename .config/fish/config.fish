# GREETING
function fish_greeting
    clear
    # toilet -f univers -F metal -t "arch btw" | sed '1,1 d; s/^/ /' | boxes -d ansi-rounded -p a2
    # fortune
    printf "\n"
    fastfetch
end

# VIM BINDS
set -g fish_key_bindings fish_vi_key_bindings
bind --mode insert \cy forward-char
bind --mode insert up ctrl-r
bind --mode command k history-pager

fzf --fish                         | source
starship init fish                 | source
direnv hook fish                   | source
atuin init fish                    | source
atuin gen-completions --shell fish | source
zoxide init fish                   | source

bind -M insert up _atuin_search

set -gx STARSHIP_CONFIG ~/.config/starship/starship.toml
set -gx EDITOR nvim
set -gx BROWSER firefox
set -gx ZDOTDIR "$HOME/.config/zsh"


set -gx XDG_CONFIG_HOME "$HOME/.config"
set -gx XDG_DATA_HOME "$HOME/.local/share"
set -gx XDG_CACHE_HOME "$HOME/.cache"
set -gx STARSHIP_CONFIG "$XDG_CONFIG_HOME/starship/starship.toml"
set -gx STARSHIP_CACHE "$XDG_CACHE_HOME/starship/cache"
set -gx R_HOME_USER "$XDG_CONFIG_HOME/R"
set -gx R_PROFILE_USER "$XDG_CONFIG_HOME/R/profile"
set -gx MOZ_ENABLE_WAYLAND 1
set -gx HOSTNAME $(hostname)
set -gx SHELL fish

source env.fish

# ABBREVIATIONS
abbr --add cd z
abbr --add ci zi
abbr --add ll eza --color=always -lah --git --no-filesize --icons=always --no-user --no-permissions --group-directories-first
abbr --add off systemctl poweroff
abbr --add ... cd ../..
abbr --add .... cd ../../..
abbr --add ..... cd ../../../..
abbr --add ...... cd ../../../../..
abbr --add ai aichat

# YAZI
function y
	set tmp (mktemp -t "yazi-cwd.XXXXXX")
	yazi $argv --cwd-file="$tmp"
	if set cwd (command cat -- "$tmp"); and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
		builtin cd -- "$cwd"
	end
	rm -f -- "$tmp"
end

# AI HELP
function _aichat_fish
    set -l _old (commandline)
    if test -n $_old
        echo -n "⌛"
        commandline -f repaint
        commandline (aichat -e $_old)
    end
end
bind --mode insert ctrl-h _aichat_fish
