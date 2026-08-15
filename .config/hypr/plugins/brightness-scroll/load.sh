#!/usr/bin/env bash

set -euo pipefail

plugin_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly plugin_dir
readonly loader_file="${BASH_SOURCE[0]}"
readonly source_file="${plugin_dir}/brightness-scroll.cpp"
readonly plugin_name="brightness-scroll"
readonly cache_base="${BRIGHTNESS_SCROLL_BUILD_ROOT:-${XDG_CACHE_HOME:-${HOME}/.cache}/hyprland/brightness-scroll}"
readonly version_header="/usr/include/hyprland/src/version.h"
abi_hash="$(hyprctl -j version | jq -er '.abiHash')"
readonly abi_hash
installed_commit="$(sed -n 's/^#define GIT_COMMIT_HASH[[:space:]]*"\([^"]*\)"/\1/p' "${version_header}")"
readonly installed_commit
readonly build_dir="${cache_base}/${abi_hash}"
readonly output_file="${build_dir}/brightness-scroll.so"

notify_failure() {
	notify-send -a Hyprland -u critical "Brightness scroll failed" "Could not build or load the Hyprland input plugin." || true
}
trap notify_failure ERR

if [[ "${abi_hash%%_aq_*}" != "${installed_commit}" ]]; then
	notify-send -a Hyprland -u critical "Restart Hyprland first" "Installed headers do not match the running compositor; brightness scroll was not loaded."
	exit 1
fi

mkdir -p -- "${build_dir}"
exec 9>"${build_dir}/load.lock"
flock 9

plugin_loaded=false
if hyprctl -j plugin list | jq -e --arg name "${plugin_name}" 'any(.[]; .name == $name)' >/dev/null; then
	plugin_loaded=true
fi

build_only=false
if [[ "${1:-}" == "--build-only" ]]; then
	build_only=true
fi

plugin_rebuilt=false
if [[ ! -f "${output_file}" || "${loader_file}" -nt "${output_file}" || "${source_file}" -nt "${output_file}" || "${version_header}" -nt "${output_file}" ]]; then
	readonly next_output="${output_file}.new.$$"
	read -r -a hyprland_cflags <<<"$(pkg-config --cflags hyprland)"

	c++ \
		-std=c++23 \
		-O2 \
		-fPIC \
		-shared \
		-pthread \
		-Wall \
		-Wextra \
		-Wpedantic \
		-Wno-missing-field-initializers \
		-Wno-unused-parameter \
		"${hyprland_cflags[@]}" \
		"${source_file}" \
		-o "${next_output}"

	if [[ "${plugin_loaded}" == true && "${build_only}" == false ]]; then
		hyprctl plugin unload "${output_file}"
		plugin_loaded=false
	fi

	mv -- "${next_output}" "${output_file}"
	plugin_rebuilt=true
fi

if [[ "${build_only}" == true ]]; then
	exit 0
fi

if [[ "${plugin_loaded}" == false || "${plugin_rebuilt}" == true ]]; then
	hyprctl plugin load "${output_file}"
fi
