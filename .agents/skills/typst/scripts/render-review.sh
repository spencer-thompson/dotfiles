#!/usr/bin/env bash

set -euo pipefail

usage() {
	echo "usage: render-review.sh INPUT.typ [NEW_OUTPUT_DIRECTORY]" >&2
}

if (($# < 1 || $# > 2)); then
	usage
	exit 2
fi

input=$1
if [[ ! -f $input ]]; then
	echo "render-review.sh: input file not found: $input" >&2
	exit 1
fi

for dependency in typst pdftoppm pdfinfo pdffonts; do
	if ! command -v "$dependency" >/dev/null 2>&1; then
		echo "render-review.sh: missing dependency: $dependency" >&2
		exit 1
	fi
done

if (($# == 2)); then
	review_dir=$2
	if [[ -e $review_dir ]]; then
		echo "render-review.sh: output path already exists: $review_dir" >&2
		exit 1
	fi
	mkdir -p "$review_dir"
else
	review_dir=$(mktemp -d /tmp/typst-review.XXXXXX)
fi

pdf=$review_dir/output.pdf
typst compile "$input" "$pdf"
pdftoppm -png -r 144 "$pdf" "$review_dir/page"

if command -v montage >/dev/null 2>&1; then
	pages=("$review_dir"/page-*.png)
	page_count=${#pages[@]}
	if ((page_count <= 5)); then
		tile="${page_count}x1"
	elif ((page_count <= 12)); then
		tile="4x"
	else
		tile="5x"
	fi

	montage "${pages[@]}" \
		-thumbnail 360x \
		-tile "$tile" \
		-geometry +12+12 \
		"$review_dir/contact.png"
else
	echo "render-review.sh: montage not found; contact sheet was not created" >&2
fi

pdfinfo "$pdf" | sed -n \
	-e '/^Tagged:/p' \
	-e '/^Pages:/p' \
	-e '/^Page size:/p' \
	-e '/^File size:/p' \
	-e '/^PDF version:/p'
pdffonts "$pdf"
printf 'Review directory: %s\n' "$review_dir"
