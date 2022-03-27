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


- - - -
# | **Dedicated Server: Fresh Start**
> **Initial Server Install/Connection:**  
> This part of the Project will focus on preparing your dedicated Server/VDS for L4D2.  

Login to your webhosts admin panel and ensure you are using Ubuntu **18.04 or earlier**.  You should have had an option to do this during the order process, but if not most hosts will have an intuitive admin panel to allow you to do this.  I used GCoreLabs to set up a server whilst writing this guide, and they have a 'reinstall' option under "[Management > Virtual Machines](https://imgur.com/A7kRTyO)".

For the next part, you will need to make use of an SSH Client such as [Putty](http://www.putty.org/).

Once Putty is installed and launched, you only need to enter the IP address of your server into the Hostname field.  The port should default to 22 and the connection type to SSH which is correct.  Once you've input the IP address select 'open'.  If you get a security warning select yes.

After this you should get a black screen which says "login as:".  You should enter the username provided by your hosting provider (likely 'root').  After this you'll be prompted for the password.  NB: With the username or password in your clipboard you can simply right click to paste it into putty.  The password will not display on screen but it will paste as long as it's in your clipboard.

> **L4D2 Prerequisites:**  
> Before you can install L4D2, there are a number of items you must install first.  Simply copy and paste each of these commands one by one into the putty terminal.  You won't get any feedback on the first command, but the next 4 will visibily install something, and potentially ask you give permission.  You just need to type 'y' and enter when prompted.

**dpkg --add-architecture i386 # enable multi-arch  
apt-get update && apt-get upgrade  
apt-get install libc6:i386 # install base 32bit libraries  
apt-get install lib32z1  
apt-get install screen**

> **Creating a User to run the Servers on**  
> You don't want to be running these services on root, do you?!  
> We'll call the account Steam and allow it to run certain Root commands so that you won't have to log into Root all the time.  
> After that, we'll login to the user. (when you enter the login comamnd it will ask you which user to log in to, simply log in with the new username (steam) and password you just created seconds ago).

**adduser steam**  
**adduser steam sudo**  
**login**

> **Installing Steam and L4D2 Files**  
> We're no longer logged in to our Root user, we'll be logged in to our user "Steam".  
> By entering these commands one by one in order you'll have all the required files for a L4D2 vanilla server installed in "**/home/steam/Steam/steamapps/common/l4d2**"

**wget http://media.steampowered.com/installer/steamcmd_linux.tar.gz  
tar -xvzf steamcmd_linux.tar.gz  
./steamcmd.sh  
login anonymous  
force_install_dir ./Steam/steamapps/common/l4d2  
app_update 222860 validate  
quit**

> **Setup the Server Start/Restart/Stop Files**  
> Next you'll need to download the srcds1 file provided within this directory.  You can [click here](https://github.com/SirPlease/L4D2-Competitive-Rework/blob/master/Dedicated%20Server%20Install%20Guide/srcds1), select raw, then right click and save.
> I recommend having [Notepad++](https://notepad-plus-plus.org/download/v7.5.1.html) in order to make this as smooth as possible but the notepad within windows works fine.

The srcds1 file provided has all the information you need inside it.  Realistically, if you are hosting one server and you have followed every step in this guide you will only need to change the IP address of your server from 1.3.3.7 to your actual IP.  After this save the file as srcds1.  If it saves as srcds1.txt you should rename it to remove the .txt extension.  

When this file has been edited and correctly saved as srcds1, you need to put it into your **/etc/init.d** folder.  

To do this you will need to use of an FTP Client such as [FileZilla](https://filezilla-project.org/).  

When Filezilla is installed, launch it and select the site manager option at the top left.  Select 'New Site' and give it a name.  Change the Protocol to 'SFTP' and leave the port blank. Enter the same username/password combination you used for Putty and click on 'Connect'.  If the server puts you in the 'root' folder by default, you can use the ".." at the top to go back and help you find the **/etc/init.d** folder.  Once you are in the **/etc/init.d** folder you just need to drag and drop the srcds1 from your computer into this directory on the server.

> **Install the addons/server configuration files**  
> Before starting the server we can install the addons/cfg files and ensure they are configured correctly.  Keep filezilla handy as we will be making use of this again.

Go to the [Competitive Rework](https://github.com/SirPlease/L4D2-Competitive-Rework) github page.  Select the green 'code' option at the top right and choose the 'Download Zip' option from the dropdown.  Unzip the files to somewhere handy on your computer and open up the folder.  Edit 'myhost.txt' and 'mymotd.txt' to whatever you want to display to users who join your server.  Open the 'cfg' folder and rename 'server.cfg' to 'server1.cfg'.  We call it server1 as we already defined it as server1 in the srcds1 file.  Once the file is renamed open it up and edit the options in here as you please.  Everything should be clearly defined but you should probably only touch the hostname, password, and steamgroup options.  After this you can navigate to home/steam/Steam/steamapps/common/l4d2/left4dead2/ on your server through filezilla and upload all the files (including the ones we just edited) from the competitive rework download on top of what is currently there.  With everything uploaded we are now ready to start the server!

> **Starting, Restarting or Stopping your Servers**  
> First we'll have to allow the system to actually run the files, which we'll do by entering the following command into the Terminal.  If you opt to run multiple servers (see the FAQ) you will need to run this command for each server.

**sudo chmod +x /etc/init.d/srcds1**

> **All set!**  
>Now you can simply Start/Restart/Stop servers individually with simple commands.  
>Start your command with the file location and then the action.

Example: **/etc/init.d/srcds1 restart  
/etc/init.d/srcds1 start  
/etc/init.d/srcds1 stop**

>If you receive "-bash: /etc/init.d/srcds1: /bin/sh^M: bad interpreter: No such file or directory" error, it means you have dos line ending file
>You can use dos2unix command on srcds1 file, or use any other method to have this file in unix format

- - - -
# < 2 > | **F.A.Q.**

> **My VDS has multiple cores and lots of RAM, can I run multiple servers simultaneously?!**

Yes.  You just need to not lose the motivation to complete this FAQ.

> **How do I get that super cool mix plugin the SirPlease servers have?!**

You can't as he hasn't made it public.  You can use the one created by LuckyLock though which serves the same purpose with minor differences.  To install this you will need to download the [plugin file](https://github.com/LuckyServ/sourcemod-plugins/raw/master/compiled/l4d2_mix.smx).  Upload the file using filezilla to the addons/sourcemod/plugins/optional/ folder.  Open the cfg/cfgogl/zonemod/confogl_plugins.cfg file and add "sm plugins load optional/l4d2_mix.smx" to the bottom of the file without quotes.  Upload the confogl_plugins.cfg over the top of your current server file using filezilla and restart your server.

> **Left 4 Dead 2 just had an update and I can't connect to my server anymore?!**

You will need to update your server.  
  
./steamcmd.sh  
login anonymous  
force_install_dir ./Steam/steamapps/common/l4d2  
app_update 222860 validate  
quit  

> **I've installed the Tickrate Enabler and set my tickrate to 128 or higher, but on the net_graph the bottom value will still be 100!**

This is because it's a hardcoded limit in the client, but don't worry, it's only a visual thing.  
The two middle values on net_graph show you what you're actually getting from the Server.

> **I've installed the Tickrate Enabler, but one or both the middle values aren't reaching the Tickrate set**.

First, make sure that you've properly adjusted your rates in the server.cfg as well.  
If everything is set correctly check if the "**sv**" (check the net_graph) isn't struggling to stay above the Tickrate's value, as this will decrease the amount of updates clients are getting from the Server.  
Regarding updaterate, this will only be a client problem if the client has a laggy connection to the Server and is dropping packets.  

The amount of commands a client can send to the Server is limited to the client framerate.  
If you're only getting 60fps, you'll never have an actual cmdrate of above 60.
