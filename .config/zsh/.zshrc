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

# Verbosity and settings that you pretty much just always are going to want.
alias \
	cp="cp -iv" \
	mv="mv -iv" \
	rm="rm -vI" \
	bc="bc -ql" \
	rsync="rsync -vrPlu" \
	mkd="mkdir -pv" \
	yt="yt-dlp --embed-metadata -i" \
	yta="yt -x -f bestaudio/best" \
	ytt="yt --skip-download --write-thumbnail" \
	ffmpeg="ffmpeg -hide_banner"

# Colorize commands when possible.
alias \
	ls="ls -hN --color=auto --group-directories-first" \
	grep="grep --color=auto" \
	diff="diff --color=auto" \
	ccat="highlight --out-format=ansi" \
	ip="ip -color=auto"

# plugins
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh
source /usr/share/zsh/plugins/zsh-vi-mode/zsh-vi-mode.plugin.zsh
ZVM_INIT_MODE=sourcing
ZVM_VI_INSERT_ESCAPE_BINDKEY=jk
ZVM_VI_VISUAL_ESCAPE_BINDKEY=jk

bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

eval "$(starship init zsh)"

neofetch
