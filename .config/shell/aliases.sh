#!/bin/sh

alias \
	ordm="ollama run dolphin-mistral" \
	ls="eza --icons --group-directories-first" \
	ll="eza --color=always -lah --git --no-filesize --icons=always --no-user --no-permissions --group-directories-first" \
	tree="eza --tree" \
	cat="bat -p"

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
	update="sudo pacman -Syu --noconfirm && yay -Syu --noconfirm" \
	clean="sudo pacman -Sc --noconfirm; yay -Sc --noconfirm"
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

# directories
alias ..="cd .." \
      ...="cd ../.." \
      ....="cd ../../.." \
      .....="cd ../../../.." \
      ......="cd ../../../../.."

alias glog="git log --graph --topo-order --pretty='%w(100,0,6)%C(yellow)%h%C(bold)%C(black)%d %C(cyan)%ar %C(green)%an%n%C(bold)%C(white)%s %N' --abbrev-commit"
