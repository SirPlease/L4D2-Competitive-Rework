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


* ------------------------
* -------- NOTES: --------
* ------------------------
* - The plugin doesn't currently care about capitalization other than the Directory of the plugin, not sure if I can be bothered adding this :P
* - This plugin is intended for L4D2 Competitive Rework functionality, but can be easily converted to work with different setups outside of Competitive.
*
******************************************************************/

ConVar hRefresh;
char g_sFilePath[PLATFORM_MAX_PATH];
Handle aReservedPlugins;

public Plugin myinfo = 
{
	name = "Confogl Plugin Unloader",
	author = "Sir",
	version = "1.0",
	description = "Allows for unloading plugins in the way you want them to."
};

public void OnPluginStart()
{
	RegServerCmd("confogl_unload_plugins", UnloadPlugins, "Unload Plugins in the folder: argument = folder name. (Won't unload reserved Plugins) - No argument if you're unloading the main folder");
	RegServerCmd("confogl_unload_reserved", UnloadReservedPlugins, "Unload Reserved Plugins in following order: Last Reserved -> First Reserved");
	RegServerCmd("confogl_reserve_plugin", ReservePlugin, "Reserve Plugin to prevent from being unloaded when .");
	hRefresh = CreateConVar("confogl_restart", "1", "To prevent order issues due to ServerCommands, do we use the plugin to load_unlock and refresh when finished as its final task?")

	// Reserved Plugins
	aReservedPlugins = CreateArray(32);

	// Gotta reserve ourself of course.
	ServerCommand("confogl_reserve_plugin optional/confogl_unloader.smx");
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
	// Gotta provide ONE folder to unload, just in case the client make an error we return an error. (Not supporting whitespace folders, silly)
	if (args > 1)
	{
		PrintToServer("[CONFOGL UNLOADER]: confogl_unload_plugins <folder>");
		return;
	}

	char sFolderName[32];

	if (args == 1)
	{
		// Get Folder name.
		GetCmdArg(1, sFolderName, sizeof(sFolderName));

		if (StrEqual(sFolderName, "plugins", false)) 
		{
			PrintToServer("[CONFOGL UNLOADER]: If you wish to unload the main folder, don't provide an argument.");
			return;
		}

		// Check if provided Directory actually exists
		if (!DoesDirectoryExist(sFolderName))
		{
			PrintToServer("[CONFOGL UNLOADER]: Make sure the folder you provide actually exists (case sensitive!)");
			return;
		}
	}

	char stockpluginname[64];
	Handle pluginIterator = GetPluginIterator();
	Handle currentPlugin;
	while (MorePlugins(pluginIterator))
	{
		currentPlugin = ReadPlugin(pluginIterator);
		GetPluginFilename(currentPlugin, stockpluginname, sizeof(stockpluginname));

		// Check if the foldername is in there and at the start
		if (StrContains(stockpluginname, sFolderName) == 0)
		{
			if (args == 0 && StrContains(stockpluginname, "/") != -1)
			  continue; // Just in case you're unloading the main folder before the others.. for some reason? Just for consistency. xD

			// Prevent Reserved Plugins from unloading
			if (FindStringInArray(aReservedPlugins, stockpluginname) != -1) continue;

			 // Unload the plugin.
			ServerCommand("sm plugins unload %s", stockpluginname);
			// PrintToChatAll("%s UNLOADED", stockpluginname);
		}
	}

	CloseHandle(currentPlugin); // This one I probably don't have to close, but whatevs.
	CloseHandle(pluginIterator);
}

public Action UnloadReservedPlugins(int args) 
{
	if (args)
	{
		PrintToServer("[CONFOGL UNLOADER]: confogl_unload_reserved does not like arguments.")
		return;
	}

	for (int iSize = GetArraySize(aReservedPlugins); iSize > 0; iSize--)
	{
		char sReserved[64];
		GetArrayString(aReservedPlugins, iSize - 1, sReserved, sizeof(sReserved)); // -1 because of how arrays work. :)
		ServerCommand("sm plugins unload %s", sReserved);
	}
}

public Action ReservePlugin(int args) 
{
	// Gotta provide a plugin to reserve.
	if (args != 1)
	{
		PrintToServer("[CONFOGL UNLOADER]: confogl_reserve_plugin <plugin> (Don't forget ending with .smx)");
		return;
	}

	char sPluginName[32];

	// Get Plugin..
	GetCmdArg(1, sPluginName, sizeof(sPluginName));

	// Check if provided Plugin is actually loaded
	if (FindPluginByFile(sPluginName) == INVALID_HANDLE)
	{
		PrintToServer("[CONFOGL UNLOADER]: confogl_reserve_plugin <plugin> (Make sure the plugin is loaded)");
		PrintToServer("[CONFOGL UNLOADER]: Don't forget adding the folder if it's outside of the main plugins folder (and ending with .smx)");
		return;
	}

	// Push Plugin into Reserved Array.
	PushArrayString(aReservedPlugins, sPluginName);
}

bool DoesDirectoryExist(char[] sFolderName)
{
	char UpdatedFolderStructure[64];
	Format(UpdatedFolderStructure, sizeof(UpdatedFolderStructure), "plugins/%s", sFolderName)
	BuildPath(Path_SM, g_sFilePath, sizeof(g_sFilePath), UpdatedFolderStructure);
	return DirExists(g_sFilePath);
}