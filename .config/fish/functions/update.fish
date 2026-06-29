# UPDATE
function update --description "Update system packages, global npm packages, and fish completions"
    if type -q paru
        echo -e "\e[1;35mUpdating Packages\e[0m"
        paru -Syu
    else
        echo "paru not found; skipping system packages"
    end

    if type -q npm
        echo -e "\e[1;35mUpdating global npm packages\e[0m"
        npm update -g
    end

    echo -e "\e[1;35mUpdating Completions\e[0m"
    fish_update_completions
end
