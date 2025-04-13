# PYTHON VIRTUAL ENVIRONMENT
function venv
    # Check if already activated
    if test -n "$VIRTUAL_ENV"
        echo -e "\e[1;34mDeactivating current virtual environment...\e[0m"
        deactivate
        return
    end

    # Check if the venv directory exists
    if test -d ".venv"
        echo -e "\e[1;32mActivating virtual environment...\e[0m"
        source .venv/bin/activate.fish
    else
        echo -e "\e[1;33mCreating and activating virtual environment...\e[0m"
        python3 -m venv .venv
        source .venv/bin/activate.fish
    end
end
