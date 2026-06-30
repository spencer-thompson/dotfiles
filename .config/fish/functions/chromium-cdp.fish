function chromium-cdp --description "Launch Chromium with CDP using the default profile"
    set -l port 9222
    set -l user_data_dir "$HOME/.config/chromium"
    set -l profile Default

    set -l state_home "$HOME/.local/state"
    set -q XDG_STATE_HOME; and set state_home $XDG_STATE_HOME
    set -l log_dir "$state_home/chromium-cdp"
    set -l log_file "$log_dir/chromium.log"

    if pgrep -u (id -u) -x chromium >/dev/null
        echo "Chromium is already running. Close it first so CDP flags and the profile lock behave correctly."
        return 1
    end

    mkdir -p $log_dir

    command /usr/bin/chromium \
        --ozone-platform-hint=auto \
        --remote-debugging-address=127.0.0.1 \
        --remote-debugging-port=$port \
        --user-data-dir="$user_data_dir" \
        --profile-directory="$profile" \
        $argv >$log_file 2>&1 &

    disown $last_pid

    echo "Chromium CDP started on http://127.0.0.1:$port"
    echo "Logs: $log_file"
end
