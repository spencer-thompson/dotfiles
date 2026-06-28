function remove_unused_packages
    set -l orphans (pacman -Qtdq)

    if test (count $orphans) -eq 0
        echo "No orphan packages found"
        return
    end

    sudo pacman -Rns $orphans
end
