# UPDATE
function update
    echo -e "\e[1;35mUpdating Mirror List\e[0m"
    sudo reflector --age 2 --connection-timeout 1 --download-timeout 1 --country US \
        --fastest 12 --latest 10 --number 12 --save /etc/pacman.d/mirrorlist

    echo -e "\e[1;35mUpdating Packages\e[0m"
    paru -Syu

    echo -e "\e[1;35mUpdating Completions\e[0m"
    fish_update_completions
end
