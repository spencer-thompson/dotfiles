#!/usr/bin/env bash
set -euo pipefail
umask 077

selection=$(slurp) || exit 0
[[ -n "$selection" ]] || exit 0
capture=$(mktemp "${XDG_RUNTIME_DIR:-/tmp}/hypr-ocr.XXXXXX.png")
trap 'rm -f -- "$capture"' EXIT

if ! grim -g "$selection" "$capture" || ! text=$(tesseract "$capture" stdout); then
	notify-send -a OCR "OCR failed" "Could not read text from the selected area."
	exit 1
fi

if [[ -z "$text" ]]; then
	notify-send -a OCR "No text found"
	exit 0
fi

if ! printf '%s' "$text" | wl-copy; then
	notify-send -a OCR "OCR failed" "Could not copy the text."
	exit 1
fi
notify-send -a OCR "Text copied"
