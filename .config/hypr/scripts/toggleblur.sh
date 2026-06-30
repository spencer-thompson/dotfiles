#!/bin/bash

input=$(hyprctl getoptions decoration:blur:enabled | awk '/^int/ {print $2}' - )

if [ $input == "0" ]; then

    hyprctl keyword decoration:blur:enabled true
    # hyprctl reload

elif [ $input == "1" ]; then

    hyprctl keyword decoration:blur:enabled false
    # hyprctl reload

else

    echo "Invalid Input"

fi
