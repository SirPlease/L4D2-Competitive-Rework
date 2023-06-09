FROM altairsossai/l4d2-server:latest

# Copy local files to the container
COPY . /home/steam/l4d2/left4dead2

# Start the Left 4 Dead 2 server
CMD ["./srcds_run", "-game", "left4dead2", "-port", "27015", "+sv_clockcorrection_msecs", "25", "-timeout", "10", "-tickrate", "100", "+map", "c2m1_highway", "-maxplayers", "32", "+servercfgfile", "server.cfg"]
