function __write_shell_cache --argument-names destination
    set --erase argv[1]
    set -l temporary (mktemp "$destination.XXXXXX")

    if command $argv >"$temporary"; and test -s "$temporary"
        command mv -- "$temporary" "$destination"
        return 0
    end

    command rm -f -- "$temporary"
    return 1
end

function refresh_shell_cache --description "Refresh cached Fish integrations"
    set -l completion_dir "$XDG_CACHE_HOME/fish/completions"
    set -l init_dir "$XDG_CACHE_HOME/fish/init"
    set -l failed 0

    mkdir -p -- "$completion_dir" "$init_dir"

    if type -q codex
        __write_shell_cache "$completion_dir/codex.fish" codex completion fish
        or set failed 1
    end

    if type -q atuin
        __write_shell_cache "$completion_dir/atuin.fish" atuin gen-completions --shell fish
        or set failed 1
        __write_shell_cache "$init_dir/atuin.fish" atuin init fish
        or set failed 1
    end

    if type -q fzf
        __write_shell_cache "$init_dir/fzf.fish" fzf --fish
        or set failed 1
    end

    if type -q mise
        __write_shell_cache "$init_dir/mise.fish" mise activate fish
        or set failed 1
    end

    if type -q starship
        __write_shell_cache "$init_dir/starship.fish" starship init fish --print-full-init
        or set failed 1
    end

    if type -q zoxide
        __write_shell_cache "$init_dir/zoxide.fish" zoxide init fish
        or set failed 1
    end

    return $failed
end
