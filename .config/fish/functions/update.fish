# UPDATE
function update --description "Update system packages, global npm packages, and shell caches"
    if type -q paru
        echo
        echo -e "\e[1;35m=== Updating Packages ===\e[0m"
        paru -Syu
    else
        echo "paru not found; skipping system packages"
    end

    if type -q codex
        echo
        echo -e "\e[1;35m=== Updating Codex ===\e[0m"
        codex update
    end

    if type -q npm
        echo
        echo -e "\e[1;35m=== Updating global npm packages ===\e[0m"
        npm update -g
    end

    echo
    echo -e "\e[1;35m=== Updating Shell Caches ===\e[0m"
    fish_update_completions
    refresh_shell_cache
end
