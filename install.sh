#!/bin/sh

while IFS= read -r line; do
    printf '%s\n' "$line"
done < "$HOME/dotfiles/README.md"
