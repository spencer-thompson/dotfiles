function clean
    echo -e "\e[1;35mCleaning uv cache\e[0m"
    uv cache prune

    echo -e "\e[1;35mCleaning pnpm store\e[0m"
    pnpm store prune

    echo -e "\e[1;35mCleaning npm cache\e[0m"
    npm cache clean --force

    echo -e "\e[1;35mCleaning go cache\e[0m"
    go clean -cache -modcache

    echo -e "\e[1;35mCleaning removing orphan packages\e[0m"
    paru -R $(paru -Qtdq)

    echo -e "\e[1;35mCleaning pacman and aur cache\e[0m"
    paru -Scc
end
