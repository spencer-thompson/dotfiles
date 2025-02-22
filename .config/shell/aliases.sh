#!/bin/sh

# global aliases
alias -g NV=' |& nvim - +"setlocal buftype=nofile"'
alias -g LL=' |& less'

alias n="nvim"

alias f="fzf"

alias \
	ordm="ollama run dolphin-mistral" \
	ls="eza --icons=auto --group-directories-first" \
	ll="eza --color=always -lah --git --no-filesize --icons=always --no-user --no-permissions --group-directories-first" \
	tree="eza --tree" \
	vim="nvim"
# cat="bat" \

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
	ffmpeg="ffmpeg -hide_banner" \
	clean="sudo pacman -Sc --noconfirm; yay -Sc --noconfirm"
# update="sudo reflector -c US -f 6 -l 5 -n 6 --save /etc/pacman.d/mirrorlist && sudo pacman -Syu --noconfirm && yay -Syu --noconfirm" \
# update="sudo pacman -Syu && yay -Syu"

# Colorize commands when possible.
alias \
	grep="grep --color=auto" \
	diff="diff --color=auto" \
	ccat="highlight --out-format=ansi" \
	ip="ip -color=auto"
# ls="ls -hN --color=auto --group-directories-first" \

alias killbg='kill ${${(v)jobstates##*:*:}%=*}'

alias cd="z"

alias q="qalc"

# not working need to look into zsh
alias fman="apropos \"^\w\" | awk '{print $1;}' | fzf --preview \"man {1} | bat -l man\" --preview-window=right:70% | xargs man"

# directories
alias ..="cd .." \
	...="cd ../.." \
	....="cd ../../.." \
	.....="cd ../../../.." \
	......="cd ../../../../.."

alias glog="git log --graph --topo-order --pretty='%w(100,0,6)%C(yellow)%h%C(bold)%C(black)%d %C(cyan)%ar %C(green)%an%n%C(bold)%C(white)%s %N' --abbrev-commit"
