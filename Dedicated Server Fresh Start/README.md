# < 0 > | **Dedicated Server Fresh Start Guide**

<== IMPORTANT NOTICE DON'T IGNORE THIS OKAY?! ===>  
<------------------ **LINUX SUPPORT ONLY** ------------------>  
< This means Windows is not Supported, so don't ask~ :smile: >
> **Document's Purpose:**

This purpose of this document is to make it very easy to get Optimized Servers ready for people interested in hosting their own servers for L4D2.  Most (if not all) server hosts will refuse to assist with the installation of 3rd party software so this document aims to help you do everything from start to finish without needing outside assistance.  

> **Recommended Server Specifications:**
* **OS:** Ubuntu **18.04 or earlier**.  Newer versions of Ubuntu appear to have blood splatter on your screen if you shoot a zombie that is far away.
* A Dedicated Server Space, do not use shared resources. (A proper VDS will work just fine)
* 1 core per server, 1GB Memory per server
  * Gameservers are usually hosted in a Shared Environment, thus not recommended. 
* A modern CPU, if you're planning on increasing the tickrate I would aim for a solid 3GHz CPU at minimum.
* DDoS Protection to absorb volume attacks and to filter out malicious traffic.

> **Solid Server Hosts (In My Experience):**
* NFOServers (**for US**, mostly)
* OVH (**for EU**, mostly)

The initial part of the guide is written with a random provder (Gcorelabs) in mind to ensure no part of the process of setting up a server is overlooked no matter how small.  Other providers should have an inuitive admin panel to perform the initial steps.
- - - -
# | **Dedicated Server: Fresh Start**

This part of the Project will focus on preparing your dedicated Server/VDS for L4D2.  
For this you will need to make use of an SSH Client such as [Putty](http://www.putty.org/).

> **L4D2 Prerequisites:**  
> Simply enter these commands into your Terminal after connecting and logging in to your Dedicated Server with your SSH Client.

**dpkg --add-architecture i386 # enable multi-arch  
apt-get update && apt-get upgrade  
apt-get install libc6:i386 # install base 32bit libraries  
apt-get install lib32z1**

> **Creating a User to run the Servers on**  
> You don't want to be running these services on root, do you?!  
> We'll call the account Steam and allow it to run certain Root commands so that you won't have to log into Root all the time.  
> After that, we'll login to the user. (login will ask you which user to log in to, simply log in to your new user)

**adduser steam**  
**adduser steam sudo**  
**login**

> **Installing Steam and L4D2 Files**  
> We're no longer logged in to our Root user, we'll be logged in to our user "Steam".  
> By entering these commands in order you'll have your files installed in "**/home/steam/Steam/steamapps/common/l4d2**"

**wget http://media.steampowered.com/installer/steamcmd_linux.tar.gz  
tar -xvzf steamcmd_linux.tar.gz  
./steamcmd.sh  
login anonymous  
force_install_dir ./Steam/steamapps/common/l4d2  
app_update 222860 validate  
quit**

> **Setup the Server Start/Restart/Stop Files**  
> Now we'll be using the srcds1 file provided with the README.  
> I recommend having [Notepad++](https://notepad-plus-plus.org/download/v7.5.1.html) in order to make this as smooth as possible.

The srcds1 file provided has all the information you need inside it.  
After setting up your server cfgs and properly editing the srcds files, put them into your **/etc/init.d** folder.
To do this you will need to use of an FTP Client such as [FileZilla](https://filezilla-project.org/) or [WinSCP](https://winscp.net/eng/download.php).  
Simply login to your root user as you would through SSH, I recommend using SFTP. (Port 23)

> **Starting, Restarting or Stopping your Servers**  
> First we'll have to allow the system to actually run the files, which we'll do by entering the following command(s) into the Terminal, run the command for every srcds file you have placed into the folder.

**sudo chmod +x /etc/init.d/srcds1**

> **All set!**  
>Now you can simply Start/Restart/Stop servers individually with simple commands.  
>Start your command with the file location and then the action.

Example: **/etc/init.d/srcds1 restart**

- - - -
# < 2 > | **F.A.Q.**

> **I'd like to make a suggestion for the Project!**

> **Something isn't working and the F.A.Q. doesn't provide answers either!**

Both of these can be requested/reported in Github's issue tracker for this Project.  
You can do this [**here**](https://github.com/SirPlease/Server4Dead-Project/issues).

> **I've installed the Tickrate Enabler and set my tickrate to 128 or higher, but on the net_graph the bottom value will still be 100!**

This is because it's a hardcoded limit in the client, but don't worry, it's only a visual thing.  
The two middle values on net_graph show you what you're actually getting from the Server.

> **I've installed the Tickrate Enabler, but one or both the middle values aren't reaching the Tickrate set**.

First, make sure that you've properly adjusted your rates in the server.cfg as well.  
If everything is set correctly check if the "**sv**" (check the net_graph) isn't struggling to stay above the Tickrate's value, as this will decrease the amount of updates clients are getting from the Server.  
Regarding updaterate, this will only be a client problem if the client has a laggy connection to the Server and is dropping packets.  

The amount of commands a client can send to the Server is limited to the client framerate.  
If you're only getting 60fps, you'll never have an actual cmdrate of above 60.
