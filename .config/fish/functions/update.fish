# UPDATE
function update
    echo -e "\e[1;35mUpdating Packages\e[0m"
    paru -Syu

    echo -e "\e[1;35mUpdating Completions\e[0m"
    fish_update_completions
end
