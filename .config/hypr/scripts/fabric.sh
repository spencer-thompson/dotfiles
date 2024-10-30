#!/bin/bash

vipe --suffix md | fabric -m gpt-4o --pattern="$(fabric -l | fzf --preview 'bat --style=plain --language=markdown --color=always ~/.config/fabric/patterns/{}/system.md' --preview-window=right:70%)"
    # | xargs -I {} fabric -m gpt-4o -p {} $(vipe)
