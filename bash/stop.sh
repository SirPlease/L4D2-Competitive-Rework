#!/bin/bash

# Check if the number of arguments is sufficient
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <port>"
    exit 1
fi

# Extract the argument
port=$1

# Check if any screen sessions are running for the port
screen_sessions=$(sudo screen -list | sudo grep -P "\.$port\b" | awk '{print $1}')

if [ -z "$screen_sessions" ]; then
    echo "No screen sessions found for port $port."
else
    while read -r session; do
        sudo screen -S "$session" -X quit
        echo "Screen session $session with port $port terminated."
    done <<< "$screen_sessions"
fi
