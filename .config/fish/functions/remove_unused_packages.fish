function remove_unused_packages
    sudo pacman -R $(pacman -Qtdq)
end
