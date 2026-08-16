#!/usr/bin/env bash

set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")"

agents_dir="$HOME/.agents"
agents_source="$PWD/.agents"

if [[ -L "$agents_dir" ]]; then
	agents_link_target="$(readlink -f -- "$agents_dir")"
	if [[ "$agents_link_target" != "$agents_source" ]]; then
		printf 'Refusing to replace %s; it points to %s, not %s\n' \
			"$agents_dir" "$agents_link_target" "$agents_source" >&2
		exit 1
	fi
	unlink -- "$agents_dir"
fi

mkdir -p -- "$agents_dir"
exec stow --restow --target="$HOME" .
