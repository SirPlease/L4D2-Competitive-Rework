# **L4D2 Competitive Rework**

**IMPORTANT NOTES** - **DON'T IGNORE THESE!**
* The goal for this repo is to work on **Linux**, specifically Ubuntu/Debian.
> There is Windows support in this repo, but not everything is, you are of course welcome to contribute to get Windows fully up to date! 
* This repository only supports Sourcemod **1.11** and up.

## **About:**

This is mainly a project that focuses on reworking the very outdated platform for competitive L4D2 for **Linux** Servers.
It will contain both much needed fixes that are simply unable to be implemented on the older sourcemod versions as well as incompatible and outdated files being updated to working versions.

> **Included Matchmodes:**
* **Zonemod 2.8.2**
* **Zonemod Hunters**
* **Zonemod Retro**
* **NeoMod 0.4a** 
* **NextMod 1.0.5**
* **Promod Elite 1.1**
* **Acemod Revamped 1.2**
* **Equilibrium 3.0c**
* **Apex 1.1.2**

---

## **Important Notes**
* We've added "**mv_maxplayers**" that replaces sv_maxplayers in the Server.cfg, this is used to prevent it from being overwritten every map change.
  * On config unload, the value will be to the value used in the Server.cfg
* Every Confogl matchmode will now execute 2 additional files, namely "**sharedplugins.cfg**" and "**generalfixes.cfg**" which are located in your **left4dead2/cfg** folder.
  * "**General Fixes**" simply ensures that all the Fixes discussed in here are loaded by every Matchmode.
  * "**Shared Plugins**" is for you, the Server host. You surely have some plugins that you'd like to be loaded in every matchmode, you can define them here. 
    * **NOTE:** Plugin load locking and unlocking is no longer handled by the Configs themselves, so if you're using this project do **NOT** define plugin load locks/unlocks within the configs you're adding manually.

---

# Left 4 Dead 2 Zone Server Docker Image

This Docker image allows you to run a Left 4 Dead 2 Zone Server in a containerized environment.

## Build the Image

To build the Docker image, use the following command:

```
docker build -t l4d2-zone-server:latest .
```

This command will build the image based on the Dockerfile in the current directory and tag it as `l4d2-zone-server:latest`.

## Run the Container

To run the container, use the following command:

```
docker run -p 27025:27015/tcp -p 27025:27015/udp --name l4d2-zone-server l4d2-zone-server:latest
```

This command will start a container named `l4d2-zone-server` based on the `l4d2-zone-server:latest` image. It maps the TCP and UDP ports from the host to the container, allowing connections to the Left 4 Dead 2 Zone Server.

Make sure that the required ports (27025 TCP and UDP) are available on the host system before running the container.

Note: You can adjust the host port numbers (`27025` in the example) if necessary. Ensure that the ports are not already in use by other processes on the host.

After running the container, the Left 4 Dead 2 Zone Server should be accessible through the specified ports on the host machine.

---

## **Credits:**

> **Foundation/Advanced Work:**
* A1m`
* AlliedModders LLC.
* "Confogl Team"
* Dr!fter
* Forgetest
* Jahze
* Lux
* Prodigysim
* Silvers
* XutaxKamay
* Visor

> **Additional Plugins/Extensions:**
* Accelerator74
* 
* Arti 
* AtomicStryker 
* Backwards
* BHaType
* Blade 
* Buster
* Canadarox 
* CircleSquared 
* Darkid 
* DarkNoghri
* Dcx 
* Devilesk
* Die Teetasse 
* Disawar1 
* Don 
* Dragokas
* Dr. Gregory House
* Epilimic 
* Estoopi 
* Griffin 
* Harry Potter
* Jacob 
* Luckylock 
* Madcap
* Mr. Zero
* Nielsen
* Powerlord
* Rena
* Sheo
* Sir
* Spoon
* Stabby 
* Step 
* Tabun
* Target
* TheTrick
* V10 
* Vintik
* VoiDeD
* xoxo
* $atanic $pirit


> **Competitive Mapping Rework:**
* Derpduck

> **Testing/Issue Reporting:**
* Too many to list, keep up the great work in reporting issues!

**NOTE:** If your work is being used and I forgot to credit you, my sincere apologies.  
I've done my best to include everyone on the list, simply create an issue and name the plugin/extension you've made/contributed to and I'll make sure to credit you properly.
