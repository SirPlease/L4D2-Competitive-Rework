#pragma newdecls required

#include <sourcemod>

/******************************************************************
*
* v1.0
* ------------------------
* ------- Details: -------
* ------------------------
* - Establishes Server Commands for the following:
* --> Unloading Plugins with the argument being the folder you want to unload the plugins from, leave the argument empty if you wish to unload just the main folder.
* --> Reserving Plugins, meaning these plugins will not be unloaded when the previously mentioned Plugin Unload is unloading the folder these plugins reside in.
* --> Unloading Reserved Plugins, this function will unload the reserved plugins in the order from "Last Reserved" to "First Reserved".

* v1.1
* ------------------------
* ------- Details: -------
* ------------------------
* - Overhauled it with keyCat's feedback in mind.
* --> Unloading Plugins with the pred_unload_plugins will push all currently loaded plugins to the Array and unloads them from Last loaded to First loaded. This way, dependencies should'nt be an issue.
* --> Removed the possibility of just Unloading Reserved Plugins... as there's no need for it?
*
* ------------------------
* -------- NOTES: --------
* ------------------------
* - The plugin doesn't currently care about capitalization other than the Directory of the plugin, not sure if I can be bothered adding this :P
*
******************************************************************/

ConVar hRefresh;
Handle aReservedPlugins;

public Plugin myinfo = 
{
	name = "Predictable Plugin Unloader",
	author = "Sir (heavily influenced by keyCat)",
	version = "1.1",
	description = "Allows for unloading plugins from last to first, with reservation support."
}

public void OnPluginStart()
{
	RegServerCmd("pred_unload_plugins", UnloadPlugins, "Unload Plugins!");
	RegServerCmd("pred_reserve_plugin", ReservePlugin, "Reserve Plugin to prevent from being unloaded when .");
	hRefresh = CreateConVar("pred_restart", "1", "To prevent order issues due to ServerCommands, do we use the plugin to load_unlock and refresh when finished as its final task?")

	// Reserved Plugins
	aReservedPlugins = CreateArray(PLATFORM_MAX_PATH);

	// Gotta reserve ourself of course.
	// - Support for moving it elsewhere/renaming it by using INVALID_HANDLE as it's the calling plugin.
	char sBuffer[PLATFORM_MAX_PATH];
	GetPluginFilename(INVALID_HANDLE, sBuffer, sizeof(sBuffer))

	PushArrayString(aReservedPlugins, sBuffer);
}

public void OnPluginEnd()
{
	if (GetConVarBool(hRefresh))
	{
		ServerCommand("sm plugins load_unlock");
		ServerCommand("sm plugins refresh");
	}
}

public Action UnloadPlugins(int args) 
{
	char stockpluginname[64];
	Handle pluginIterator = GetPluginIterator();
	Handle currentPlugin;
	while (MorePlugins(pluginIterator))
	{
		currentPlugin = ReadPlugin(pluginIterator);
		GetPluginFilename(currentPlugin, stockpluginname, sizeof(stockpluginname));

		// Prevent double pushing.
		if (FindStringInArray(aReservedPlugins, stockpluginname) == -1) 
		  PushArrayString(aReservedPlugins, stockpluginname);
	}

	CloseHandle(currentPlugin); // This one I probably don't have to close, but whatevs.
	CloseHandle(pluginIterator);

	for (int iSize = GetArraySize(aReservedPlugins); iSize > 0; iSize--)
	{
		char sReserved[PLATFORM_MAX_PATH];
		GetArrayString(aReservedPlugins, iSize - 1, sReserved, sizeof(sReserved)); // -1 because of how arrays work. :)
		ServerCommand("sm plugins unload %s", sReserved);
	}
}

public Action ReservePlugin(int args) 
{
	// Gotta provide a plugin to reserve.
	if (args != 1)
	{
		PrintToServer("[PREDICTABLE UNLOADER]: pred_reserve_plugin <plugin> (ending with .smx)");
		return;
	}

	char sPluginName[32];

	// Get Plugin..
	GetCmdArg(1, sPluginName, sizeof(sPluginName));

	// Check if provided Plugin is actually loaded
	if (FindPluginByFile(sPluginName) == INVALID_HANDLE)
	{
		PrintToServer("[PREDICTABLE UNLOADER]: pred_reserve_plugin <plugin> (Make sure the plugin is loaded)");
		PrintToServer("[PREDICTABLE UNLOADER]: Don't forget adding the folder if it's outside of the main plugins folder (and ending with .smx)");
		return;
	}

	// Push Plugin into Reserved Array.
	PushArrayString(aReservedPlugins, sPluginName);
}