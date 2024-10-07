#!/bin/bash


echo -e "\e[1;35mUpdating Mirror List\e[0m"
sudo reflector --connection-timeout 1 --download-timeout 1 --country US \
	--fastest 12 --latest 10 --number 12 --save /etc/pacman.d/mirrorlist

echo -e "\e[1;35mUpdating Pacman Packages\e[0m"
sudo pacman -Syu --noconfirm

echo -e "\e[1;35mUpdating AUR Packages\e[0m"
yay -Syu --noconfirm
