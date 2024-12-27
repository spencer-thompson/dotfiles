#!/usr/bin/env bash

hyprctl activewindow | grep -E "pid: [0-9]+$" | awk '{print $2}' | xargs -r kill
