#!/usr/bin/env bash
set -euo pipefail
umask 077

# Keep the snapshot out of dotfiles and separate for each compositor session.
state_dir="${XDG_RUNTIME_DIR:?}/dotfiles-game-dnd/${HYPRLAND_INSTANCE_SIGNATURE:?}"
mkdir -p "$state_dir"
exec 9>"$state_dir/lock"
flock -w 10 9

# Read after taking the lock: old queued children must honor the newest mode.
enabled=$(timeout 5s hyprctl repl 'return require("modules.binds").performance_mode_enabled()')
snapshot="$state_dir/previous"

case "$enabled" in

true)
	# Repeated events/reloads must not replace the original preference.
	[[ ! -f "$snapshot" ]] || exit 0
	previous=$(timeout 5s noctalia msg notification-dnd-status)
	[[ "$previous" == on || "$previous" == off ]] || exit 1
	printf '%s\n' "$previous" >"$snapshot"
	timeout 5s noctalia msg notification-dnd-set on
	;;
false)
	[[ -f "$snapshot" ]] || exit 0
	read -r previous <"$snapshot"
	[[ "$previous" == on || "$previous" == off ]] || exit 1
	current=$(timeout 5s noctalia msg notification-dnd-status)
	[[ "$current" == on || "$current" == off ]] || exit 1
	# Respect an explicit DND-off action made during the game.
	if [[ "$current" == on ]]; then
		timeout 5s noctalia msg notification-dnd-set "$previous"
	fi
	rm -- "$snapshot"
	;;
*) exit 1 ;;
esac
