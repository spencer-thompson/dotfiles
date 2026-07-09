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
fish_add_path --global "$HOME/.local/bin"
fish_add_path --global "$HOME/.cargo/bin"

function starship_transient_prompt_func
    starship module directory
    starship module character
end

function starship_transient_rprompt_func
    starship module cmd_duration
    starship module time
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
    bind --mode insert \cy forward-char
    bind --mode command k history-pager

    set -gx fish_cursor_replace_one underscore
    set fish_emoji_width 2

    if type -q fzf
        fzf --fish | source
    end

    if type -q starship
        starship init fish | source
        enable_transience
    end

    # type -q direnv; and direnv hook fish | source

    if type -q atuin
        atuin init fish | source
        atuin gen-completions --shell fish | source

        # Use Atuin's wrapper so completion/search paging can keep handling Up.
        bind -M insert up _atuin_bind_up
    end

    if type -q zoxide
        zoxide init fish | source
    end

    # type -q hcloud; and hcloud completion fish | source

    if type -q codex
        codex completion fish | source
    end

    # type -q jj; and jj util completion fish | source

    if type -q mise
        mise activate fish | source
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
    abbr --add ultradark hyprsunset --temperature 3000 --gamma 40

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

# Added by codebase-memory-mcp install
fish_add_path /home/sthom/.local/bin
