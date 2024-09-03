# Zoomer shell

# Enable colors and change prompt
autoload -U colors && colors	# Load colors
PS1="%B%{$fg[red]%}[%{$fg[yellow]%}%n%{$fg[green]%}@%{$fg[blue]%}%M %{$fg[magenta]%}%~%{$fg[red]%}]%{$reset_color%}$%b "
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

function nushell_oneshot() {
    nu
    # zle reset-prompt
}

zle -N nushell_oneshot

# custom binds
bindkey '^n' nushell_oneshot


# Functions
function pkill() {
    ps aux | fzf --height 40% --layout=reverse --prompt="Select process to kill: " | awk '{print $2}' | xargs -r sudo kill
}

function aiclip() {
    printf "Context: [%s]\n\nUsing the context, %s concisely and effectively\n" "$(wl-paste)" "$1" | ollama run llama3.1
}

# Aliases
[ -f "${XDG_CONFIG_HOME}/shell/aliases.sh" ] && source "${XDG_CONFIG_HOME}/shell/aliases.sh"

# plugins


source /usr/share/zsh/plugins/zsh-vi-mode/zsh-vi-mode.plugin.zsh
ZVM_INIT_MODE=sourcing

ZVM_VI_INSERT_ESCAPE_BINDKEY=jk
ZVM_VI_VISUAL_ESCAPE_BINDKEY=jk
# zvm_after_init_commands+=('[ -f /usr/share/fzf/key-bindings.zsh ] && source /usr/share/fzf/key-bindings.zsh')

function zvm_config() {
    ZVM_LINE_INIT_MODE=$ZVM_MODE_INSERT
    # ZVM_VI_INSERT_ESCAPE_BINDKEY=\;\;
    ZVM_VI_INSERT_ESCAPE_BINDKEY=jk
    ZVM_VI_VISUAL_ESCAPE_BINDKEY=jk
    ZVM_CURSOR_STYLE_ENABLED=false
    ZVM_VI_EDITOR=nvim
    # export KEYTIMEOUT=1
}

zvm_after_init_commands+=(eval "$(atuin init zsh)")


source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh


# source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh
# bindkey '^[[A' history-substring-search-up
# bindkey '^[[B' history-substring-search-down

# toilet -f univers -F metal "spencer" | sed '1,4 d; s/^/ /'

source "$HOME/.env"
export PATH="$HOME/.local/bin:$PATH"

# Bat theme
export BAT_THEME=tokyonight_night

eval "$(starship init zsh)"
eval "$(zoxide init zsh)"
eval "$(atuin init zsh)"
eval "$(direnv hook zsh)"

fastfetch
