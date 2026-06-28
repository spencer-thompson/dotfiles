function deep_clean
    if type -q npm
        echo -e "\e[1;35mForce-cleaning npm cache\e[0m"
        npm cache clean --force
    end

    if type -q go
        echo -e "\e[1;35mCleaning go build and module caches\e[0m"
        go clean -cache -modcache
    end

    if type -q docker
        echo -e "\e[1;35mPruning docker images, containers, and networks\e[0m"
        docker system prune

        echo -e "\e[1;35mPruning docker volumes\e[0m"
        docker volume prune
    end

    if type -q paru
        echo -e "\e[1;35mRemoving orphan packages\e[0m"
        set -l orphans (paru -Qtdq)

        if test (count $orphans) -gt 0
            paru -Rns $orphans
        else
            echo "No orphan packages found"
        end

        echo -e "\e[1;35mDeep-cleaning pacman and AUR cache\e[0m"
        paru -Scc
    end
end
