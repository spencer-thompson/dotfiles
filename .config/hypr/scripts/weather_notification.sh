#!/bin/bash

sleep 5
notify-send -a Weather -i weather "Today's Weather" "$(curl -s 'wttr.in/?format=%l:\n+%c+%t%20|+%f' | cut -d ":" - -f 1-2)"
