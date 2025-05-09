#!/bin/bash

sleep 5
checkupdates && notify-send -a Updates -i updates-notifier "System Updates" "$(checkupdates | wc -l | sed 's/^0$//')"
