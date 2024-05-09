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

# killall xcape 2>/dev/null ; xcape -e 'Super_L=Escape'

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

lfcd () {
    tmp="$(mktemp -uq)"
    trap 'rm -f $tmp >/dev/null 2>&1 && trap - HUP INT QUIT TERM PWR EXIT' HUP INT QUIT TERM PWR EXIT
    lf -last-dir-path="$tmp" "$@"
    if [ -f "$tmp" ]; then
        dir="$(cat "$tmp")"
        [ -d "$dir" ] && [ "$dir" != "$(pwd)" ] && cd "$dir"
    fi
}
bindkey -s '^o' '^ulfcd\n'

# Aliases
[ -f "${XDG_CONFIG_HOME}/shell/aliases.sh" ] && source "${XDG_CONFIG_HOME}/shell/aliases.sh"

# plugins
source /usr/share/zsh/plugins/zsh-vi-mode/zsh-vi-mode.plugin.zsh
ZVM_INIT_MODE=sourcing
ZVM_VI_INSERT_ESCAPE_BINDKEY=jk
ZVM_VI_VISUAL_ESCAPE_BINDKEY=jk
zvm_after_init_commands+=('[ -f /usr/share/fzf/key-bindings.zsh ] && source /usr/share/fzf/key-bindings.zsh')

source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

source "$HOME/.env"
export PATH="$HOME/.local/bin:$PATH"

eval "$(starship init zsh)"
# eval "$(fzf --zsh)"
#
# # --- setup fzf theme ---
# fg="#a9b1d6"
# bg="#10111c"
# bg_highlight="#143652"
# purple="#B388FF"
# blue="#06BCE4"
# cyan="#2CF9ED"
#
# export FZF_DEFAULT_OPTS="--color=fg:${fg},bg:${bg},hl:${purple},fg+:${fg},bg+:${bg_highlight},hl+:${purple},info:${blue},prompt:${cyan},pointer:${cyan},marker:${cyan},spinner:${cyan},header:${cyan}"
#
# # -- use fd instead of fzf
# export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
# export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
# export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"
#
# _fzf_compgen_path() {
#     fd --hidden --exclude .git . "$1"
# }
#
# _fzf_compgen_dir() {
#     fd --type=d --hidden --exclude .git . "$1"
# }
#
# source ~/git/fzf-git.sh/fzf-git.sh
#
#
# show_file_or_dir_preview="if [ -d {} ]; then eza --tree --color=always {} | head -200; else bat -n --color=always --line-range :500 {}; fi"
#
# export FZF_CTRL_T_OPTS="--preview '$show_file_or_dir_preview"
# export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"
#
# _fzf_comprun() {
#     local command=$1
#     shift
#
#     case "$command" in
#         cd)           fzf --preview 'eza --tree --color=always {} | head -200' "$@" ;;
#         export|unset) fzf --preview "eval 'echo ${}'" "$@" ;;
#         ssh)          fzf --preview 'dig {}' "$@" ;;
#         *)            fzf --preview "$show_file_or_dir_preview" "$@" ;;
#     esac
# }
#

# Bat theme
export BAT_THEME=tokyonight_night

eval "$(zoxide init zsh)"

alias cd="z"

fastfetch

# toilet -f univers -F metal "spencer" | sed '1,4 d; s/^/ /'
