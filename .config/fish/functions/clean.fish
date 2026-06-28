function clean
    if type -q uv
        echo -e "\e[1;35mPruning uv cache\e[0m"
        uv cache prune
    end

    if type -q pnpm
        echo -e "\e[1;35mPruning pnpm store\e[0m"
        pnpm store prune
    end

    if type -q npm
        echo -e "\e[1;35mVerifying npm cache\e[0m"
        npm cache verify
    end

    if type -q go
        echo -e "\e[1;35mCleaning go build cache\e[0m"
        go clean -cache
    end

    if type -q paru
        echo -e "\e[1;35mRemoving orphan packages\e[0m"
        set -l orphans (paru -Qtdq)

        if test (count $orphans) -gt 0
            paru -Rns $orphans
        else
            echo "No orphan packages found"
        end

        echo -e "\e[1;35mCleaning pacman and AUR cache\e[0m"
        paru -Sc
    end
end
