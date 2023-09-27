#!/bin/bash

# Check if the number of arguments is sufficient
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <port> <map>"
    exit 1
fi

# Extract the arguments
port=$1
map=$2

# Check if a screen with the same name is already running
if sudo screen -list | sudo grep -P "\d+\.$port"; then
    echo "A screen with the name '$port' is already running."
    exit 1
fi

# Command to start the server
command="/home/steam/l4d2/srcds_run -game left4dead2 -port $port +sv_clockcorrection_msecs 25 -timeout 10 -tickrate 100 +map $map -maxplayers 32 +servercfgfile server.cfg"

# Start the screen with the command
sudo screen -d -m -S "$port" $command
