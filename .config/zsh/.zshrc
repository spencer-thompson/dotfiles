# Zoomer shell

# Enable colors and change prompt
# autoload -U colors && colors	# Load colors
# PS1="%B%{$fg[red]%}[%{$fg[yellow]%}%n%{$fg[green]%}@%{$fg[blue]%}%M %{$fg[magenta]%}%~%{$fg[red]%}]%{$reset_color%}$%b "
setopt autocd		# Automatically cd into typed directory.
stty stop undef		# Disable ctrl-s to freeze terminal.
setopt interactive_comments

# History in cache directory:
HISTSIZE=10000000
SAVEHIST=10000000
HISTFILE="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/history"


# Basic auto/tab complete:
autoload -U compinit
zstyle ':completion:*' menu select
zmodload zsh/complist
compinit
_comp_options+=(globdots)		# Include hidden files.

# environment
# export HOSTNAME=$(hostname)

# vi mode
bindkey -v
bindkey -M viins 'jk' vi-cmd-mode
export KEYTIMEOUT=10

# Use vim keys in tab complete menu:
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'j' vi-down-line-or-history
bindkey -v '^?' backward-delete-char


function yy() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}


function update() {
    echo -e "\e[1;35mUpdating Mirror List\e[0m"
    sudo reflector --connection-timeout 1 --download-timeout 1 --country US \
        --fastest 12 --latest 10 --number 12 --save /etc/pacman.d/mirrorlist

    echo -e "\e[1;35mUpdating Pacman Packages\e[0m"
    sudo pacman -Syu --noconfirm

    echo -e "\e[1;35mUpdating AUR Packages\e[0m"
    yay -Syu --noconfirm
}

function venv() {
    # Check if already activated
    if [[ "$VIRTUAL_ENV" != "" ]]; then
        echo -e "\e[1;34mDeactivating current virtual environment...\e[0m"
        deactivate
        return
    fi

    # Check if the venv directory exists
    if [ -d ".venv" ]; then
        echo -e "\e[1;32mActivating virtual environment...\e[0m"
        source .venv/bin/activate
    else
        echo -e "\e[1;33mCreating and activating virtual environment...\e[0m"
        python3 -m venv .venv
        source .venv/bin/activate
    fi
}

function goto_dir_open_nvim() {
    zi; nvim
    zle reset-prompt
}

zle -N goto_dir_open_nvim

# custom binds
bindkey '^n' goto_dir_open_nvim
# bindkey '^n' nushell_oneshot

function ide() {
    neovide
}

# Functions
function pkill() {
    ps aux | fzf --height 40% --layout=reverse --prompt="Select process to kill: " | awk '{print $2}' | xargs -r sudo kill
}

function aiclip() {
    printf "Context: [%s]\n\nUsing the context, %s concisely and effectively\n" "$(wl-paste)" "$1" | ollama run llama3.1
}

function ai() {
    # input="$([ ! -t 0 ] && cat | vipe --suffix md || vipe --suffix md)"
    [ ! -t 0 ] && cat | vipe --suffix md | { read input; } || vipe --suffix md | { read input; }
    pattern="$(fabric -l | fzf --preview 'bat --style=plain --language=markdown --color=always ~/.config/fabric/patterns/{}/system.md' --preview-window=right:70%)"
    fabric -m gpt-4o -s --pattern=$pattern $input
}

# Aliases
[ -f "${XDG_CONFIG_HOME}/shell/aliases.sh" ] && source "${XDG_CONFIG_HOME}/shell/aliases.sh"

# plugins


# source /usr/share/zsh/plugins/zsh-vi-mode/zsh-vi-mode.plugin.zsh
# ZVM_INIT_MODE=sourcing
#
# ZVM_VI_INSERT_ESCAPE_BINDKEY=jk
# ZVM_VI_VISUAL_ESCAPE_BINDKEY=jk
# # zvm_after_init_commands+=('[ -f /usr/share/fzf/key-bindings.zsh ] && source /usr/share/fzf/key-bindings.zsh')
#
# function zvm_config() {
#     ZVM_LINE_INIT_MODE=$ZVM_MODE_INSERT
#     # ZVM_VI_INSERT_ESCAPE_BINDKEY=\;\;
#     ZVM_VI_INSERT_ESCAPE_BINDKEY=jk
#     ZVM_VI_VISUAL_ESCAPE_BINDKEY=jk
#     ZVM_CURSOR_STYLE_ENABLED=false
#     ZVM_VI_EDITOR=nvim
#     # export KEYTIMEOUT=1
# }
#
# zvm_after_init_commands+=(eval "$(atuin init zsh)")


source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh


# source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh
# bindkey '^[[A' history-substring-search-up
# bindkey '^[[B' history-substring-search-down

# toilet -f univers -F metal "spencer" | sed '1,4 d; s/^/ /'

# fzf stuff
export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"
export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS'
  --color=fg:#d0d0d0,fg+:#d0d0d0,bg:-1,bg+:-1
  --color=hl:#5f87af,hl+:#5fd7ff,info:#afaf87,marker:#87ff00
  --color=prompt:#d7005f,spinner:#af5fff,pointer:#af5fff,header:#87afaf
  --color=border:#262626,label:#aeaeae,query:#d9d9d9
  --preview-window="border-rounded" --prompt="-> " --marker="<>" --pointer="=>"
  --separator="─" --scrollbar="│" --layout="reverse" --info="right"'
export FZF_CTRL_T_OPTS="--preview 'bat -n --color=always --line-range :500 {}'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"

# Advanced customization of fzf options via _fzf_comprun function
# - The first argument to the function is the name of the command.
# - You should make sure to pass the rest of the arguments to fzf.
_fzf_comprun() {
  local command=$1
  shift

  case "$command" in
    cd)           fzf --preview 'eza --tree --color=always {} | head -200' "$@" ;;
    export|unset) fzf --preview "eval 'echo $'{}"         "$@" ;;
    ssh)          fzf --preview 'dig {}'                   "$@" ;;
    *)            fzf --preview "bat -n --color=always --line-range :500 {}" "$@" ;;
  esac
}

# Use fd (https://github.com/sharkdp/fd) for listing path candidates.
# - The first argument to the function ($1) is the base path to start traversal
# - See the source code (completion.{bash,zsh}) for the details.
_fzf_compgen_path() {
  fd --hidden --exclude .git . "$1"
}

# Use fd to generate the list for directory completion
_fzf_compgen_dir() {
  fd --type=d --hidden --exclude .git . "$1"
}

source "$HOME/.env"
export PATH="$HOME/.local/bin:$PATH"

# Bat theme
export BAT_THEME=tokyonight_night

eval "$(starship init zsh)"
eval "$(fzf --zsh)"
eval "$(zoxide init zsh)"
eval "$(atuin init zsh)"
eval "$(direnv hook zsh)"

toilet -f univers -F metal "spencer" | sed '1,4 d; s/^/ /'
fastfetch
