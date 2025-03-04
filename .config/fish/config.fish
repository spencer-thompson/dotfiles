# GREETING
function fish_greeting
    clear
    toilet -f univers -F metal -t "arch btw" | sed '1,1 d; s/^/ /'
    fastfetch
end

# VIM BINDS
set -g fish_key_bindings fish_vi_key_bindings
bind --mode insert \cy forward-char

fzf --fish         | source
starship init fish | source
direnv hook fish   | source
atuin init fish    | source
zoxide init fish   | source

abbr --add cd z
abbr --add ci zi
abbr --add ll eza --color=always -lah --git --no-filesize --icons=always --no-user --no-permissions --group-directories-first
abbr --add ... cd ../..
abbr --add .... cd ../../..
abbr --add ..... cd ../../../..
abbr --add ...... cd ../../../../..

# YAZI
function y
	set tmp (mktemp -t "yazi-cwd.XXXXXX")
	yazi $argv --cwd-file="$tmp"
	if set cwd (command cat -- "$tmp"); and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
		builtin cd -- "$cwd"
	end
	rm -f -- "$tmp"
end

# UPDATE
function update
    echo -e "\e[1;35mUpdating Mirror List\e[0m"
    sudo reflector --age 2 --connection-timeout 1 --download-timeout 1 --country US \
        --fastest 12 --latest 10 --number 12 --save /etc/pacman.d/mirrorlist

    echo -e "\e[1;35mUpdating Pacman Packages\e[0m"
    sudo pacman -Syu --noconfirm

    echo -e "\e[1;35mUpdating AUR Packages\e[0m"
    yay -Syu --noconfirm
end

# PYTHON VIRTUAL ENVIRONMENT
function venv
    # Check if already activated
    if test -n "$VIRTUAL_ENV"
        echo -e "\e[1;34mDeactivating current virtual environment...\e[0m"
        deactivate
        return
    end

    # Check if the venv directory exists
    if test -d ".venv"
        echo -e "\e[1;32mActivating virtual environment...\e[0m"
        source .venv/bin/activate.fish
    else
        echo -e "\e[1;33mCreating and activating virtual environment...\e[0m"
        python3 -m venv .venv
        source .venv/bin/activate.fish
    end
end
