# GREETING
function fish_greeting
    clear
    # toilet -f univers -F metal -t "arch btw" | sed '1,1 d; s/^/ /' | boxes -d ansi-rounded -p a2
    # fortune
    printf "\n"
    type -q fastfetch; and fastfetch
end

set -gx EDITOR nvim
set -gx VISUAL $EDITOR
set -gx SUDO_EDITOR $EDITOR
set -gx BROWSER firefox
set -gx ZDOTDIR "$HOME/.config/zsh"

set -gx XDG_CONFIG_HOME "$HOME/.config"
set -gx XDG_DATA_HOME "$HOME/.local/share"
set -gx XDG_CACHE_HOME "$HOME/.cache"
set -gx PNPM_HOME "$XDG_DATA_HOME/pnpm"
set -gx AICHAT_ENV_FILE "$XDG_CONFIG_HOME/aichat/.env"
set -gx AICHAT_SHELL fish
set -gx STARSHIP_CONFIG "$XDG_CONFIG_HOME/starship/starship.toml"
set -gx STARSHIP_CACHE "$XDG_CACHE_HOME/starship/cache"
set -gx R_HOME_USER "$XDG_CONFIG_HOME/R"
set -gx R_PROFILE_USER "$XDG_CONFIG_HOME/R/profile"
set -gx MOZ_ENABLE_WAYLAND 1
set -gx HOSTNAME $(hostname)
set -gx SHELL /usr/bin/fish

set -gx RESUME_FILE ~/projects/my-resume/resume.toml

set -gx PYTORCH_CUDA_ALLOC_CONF 'max_split_size_mb:256'

set -gx FZF_DEFAULT_COMMAND 'fd --hidden --strip-cwd-prefix --exclude .git'
set -gx FZF_DEFAULT_OPTS '--prompt="-> "'

# colored man pages
set -gx MANPAGER 'less -R --use-color -Dd+r -Du+b'
set -gx GROFF_NO_SGR 1

test -f "$HOME/.env"; and source "$HOME/.env"

fish_add_path --global "$HOME/go/bin"
fish_add_path --global "$HOME/git/whisper.cpp/build/bin"
fish_add_path --global "$HOME/.local/share/npm-global/bin"
fish_add_path --global "$PNPM_HOME/bin"
fish_add_path --global "$HOME/.local/bin"
fish_add_path --global "$HOME/.cargo/bin"

function starship_transient_prompt_func
    starship module directory
    starship module character
end

function starship_transient_rprompt_func
    starship module cmd_duration
    starship module time
    printf " "
end

# YAZI
function y
    set tmp (mktemp -t "yazi-cwd.XXXXXX")
    yazi $argv --cwd-file="$tmp"
    if set cwd (command cat -- "$tmp"); and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
        builtin cd -- "$cwd"
    end
    rm -f -- "$tmp"
end

if status is-interactive
    # VIM BINDS
    set -g fish_key_bindings fish_vi_key_bindings

    set -gx fish_cursor_replace_one underscore
    set fish_emoji_width 2

    set -l shell_init_cache_dir "$XDG_CACHE_HOME/fish/init"
    set -l completion_cache_dir "$XDG_CACHE_HOME/fish/completions"
    set -l shell_cache_missing 0

    for tool in atuin fzf mise starship zoxide
        if type -q "$tool"; and not test -s "$shell_init_cache_dir/$tool.fish"
            set shell_cache_missing 1
        end
    end

    if type -q codex; and not test -s "$completion_cache_dir/codex.fish"
        set shell_cache_missing 1
    end

    if type -q atuin; and not test -s "$completion_cache_dir/atuin.fish"
        set shell_cache_missing 1
    end

    if test "$shell_cache_missing" -eq 1
        refresh_shell_cache >/dev/null
    end

    if type -q fzf; and test -r "$shell_init_cache_dir/fzf.fish"
        source "$shell_init_cache_dir/fzf.fish"
    end

    if type -q starship; and test -r "$shell_init_cache_dir/starship.fish"
        source "$shell_init_cache_dir/starship.fish"
        enable_transience
    end

    # type -q direnv; and direnv hook fish | source

    if type -q atuin; and test -r "$shell_init_cache_dir/atuin.fish"
        source "$shell_init_cache_dir/atuin.fish"

        # Use Atuin's wrapper so completion/search paging can keep handling Up.
        bind -M insert up _atuin_bind_up
    end

    if type -q zoxide; and test -r "$shell_init_cache_dir/zoxide.fish"
        source "$shell_init_cache_dir/zoxide.fish"
    end

    # type -q hcloud; and hcloud completion fish | source

    if not contains -- "$completion_cache_dir" $fish_complete_path
        set --prepend fish_complete_path "$completion_cache_dir"
    end

    # type -q jj; and jj util completion fish | source

    if type -q mise; and test -r "$shell_init_cache_dir/mise.fish"
        source "$shell_init_cache_dir/mise.fish"
    end

    # ABBREVIATIONS
    abbr --add lg lazygit
    abbr --add cd z
    abbr --add ci zi
    abbr --add ll eza --color=always -lah --git --icons=always --no-user --no-permissions --group-directories-first
    abbr --add off "hyprshutdown -t 'Shutting down...' --post-cmd 'systemctl poweroff'"
    abbr --add ... cd ../..
    abbr --add .... cd ../../..
    abbr --add ..... cd ../../../..
    abbr --add ...... cd ../../../../..
    abbr --add ai aichat
    abbr --add oc opencode
    abbr --add ultradark noctalia msg nightlight-force-toggle

    ## git
    abbr --add gs git status --short
    abbr --add gd git diff
    abbr --add gp git pull
    abbr --add gP git push
    abbr --add gc git commit
    abbr --add ga git add
    # abbr --add gl git log --all --graph --pretty=format:'%C(magenta)%h %C(white)| %an | %ar%C(auto)  %D%n%s%n'
    alias gl="git log --all --graph --pretty=format:'%C(magenta)%h %C(white)| %an | %ar%C(auto)  %D%n%s%n'"
    # alias nvim="bob run 0.12.0"

end
