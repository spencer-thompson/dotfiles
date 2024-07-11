#!/bin/sh

alias \
	ordm="ollama run dolphin-mistral" \
	ls="eza --icons --group-directories-first" \
	ll="eza --color=always -lah --git --no-filesize --icons=always --no-user --no-permissions --group-directories-first" \
	tree="eza --tree" \

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
	update="sudo pacman -Syu && yay -Syu"

# Colorize commands when possible.
alias \
	ls="ls -hN --color=auto --group-directories-first" \
	grep="grep --color=auto" \
	diff="diff --color=auto" \
	ccat="highlight --out-format=ansi" \
	ip="ip -color=auto"

alias killbg='kill ${${(v)jobstates##*:*:}%=*}'

