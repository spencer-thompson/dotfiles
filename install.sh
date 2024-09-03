#!/bin/bash


function ask() {
    read -p "$1 (y/n): " response
    [ -z "$response" ] || [ "$response" = "y" ]
}


