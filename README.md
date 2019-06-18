# **L4D2 Competitive Rework**

<== IMPORTANT NOTICE DON'T IGNORE THIS OKAY?! ===>  
<------------------ **LINUX SUPPORT ONLY** ------------------>  
< This means Windows is not Supported, so don't ask~ :smile: >

## **About:**

This is mainly a project that focuses on reworking the very outdated platform for competitive L4D2 for **Linux** Servers.
It will contain both much needed fixes that are simply unable to be implemented on the older sourcemod versions as well as incompatible and outdated files being updated to working versions.
Issues and Discussions can be held both on Github and on our [Steam Group](https://steamcommunity.com/groups/srv_rework)

> **Test Server Specifications:**
* **OS:** Ubuntu 64Bit (18.04)
* **IP:** 193.70.81.202:27029
* **Sourcemod:** 1.9 (6281)
* **Metamod:** 1.11 (1127)
* **Stripper Source:** 1.2.2 (hg82)

> **Included & Working Matchmodes:**
* **Zonemod 1.9.3**

---

## **Important Updated/Added Extensions**
* [Left4Downtown](https://github.com/Attano/Left4Downtown2)
  * Required for Latest Sourcemod versions.
* [Modified DHooks](https://github.com/XutaxKamay/dhooks/releases/tag/v2.2.1b)
  * Required for [Bullet Displacement Fix](https://forums.alliedmods.net/showthread.php?t=315405)
	
---

## **Fixes/Changes Integrated into Confogl & Sourcemod:**

> **Plugins/Extensions**
* [Bullet Displacement Fix](https://forums.alliedmods.net/showthread.php?t=315405)
  * Fixes a Source Engine bug that causes bullets to miss targets that they were supposed to hit.
* [L4D2 Changelevel](https://github.com/LuxLuma/Left-4-fix/tree/master/left%204%20fix/l4d2_levelchanging)
  * Resolves memory leaks caused by forced map changes when either using Sourcemod's **!map**, **!votemap**, and Confogl's matchmode loading/unloading.
    * This means you no longer have to restart your Servers after every game to ensure the Servers are on their peak performance.
* [Tank Rock Lag Compensation](https://forums.alliedmods.net/showthread.php?p=2646073)
  * Like the title says, you now simply just aim at the rock. You no longer have to "lead" your shots.

> **Additional Fixes:**
* Fixed **!forcematch** causing the Server to crash if a custom builtinvote was currently active.
* Fixed players being able to duplicate Survivors by using "**jointeam charactername**" when it was already taken.
* Fixed votes taking Spectators into account.

> **Configs/ConVars**
* Every Confogl matchmode will now execute 2 additional files, namely "**sharedplugins.cfg**" and "**generalfixes.cfg**" which are located in your **left4dead2/cfg** folder.
  * "**General Fixes**" simply ensures that all the Fixes discussed in here are loaded by every Matchmode.
  * "**Shared Plugins**" is for you, the Server host. You surely have some plugins that you'd like to be loaded in every matchmode, you can define them here. 
	
## **Credits:**

> **Foundation/Advanced Work:**
* AlliedModders LLC.
* "Confogl Team"
* Dr!fter
* Jahze
* Prodigysim
* XutaxKamay
* Visor

> **Additional Plugins/Extensions:**
* Accelerator74
* Arti 
* AtomicStryker 
* Blade 
* Canadarox 
* CircleSquared 
* Darkid 
* Dcx 
* Die Teetasse 
* Disawar1 
* Don 
* Epilimic 
* Estoopi 
* Griffin 
* Jacob 
* Luckylock 
* Lux
* Powerlord
* Sheo
* Sir
* Stabby 
* Step 
* Tabun
* V10 
* Vintik
* VoiDeD

**NOTE:** If your work is being used and I forgot to credit you, my sincere apologies.  
I've done my best to include everyone on the list, simply create an issue and name the plugin/extension you've made/contributed to and I'll make sure to credit you properly.