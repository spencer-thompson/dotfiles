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

fzf --fish                         | source
starship init fish                 | source
direnv hook fish                   | source
atuin init fish                    | source
atuin gen-completions --shell fish | source
zoxide init fish                   | source

bind -M insert up _atuin_search

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
