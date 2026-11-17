#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#define UNLOAD_BATCH 32

ArrayList
	g_aProtected,
	g_aUnloadQueue;

bool g_bRefresh;

public Plugin myinfo =
{
	name = "Plugin Manager",
	author = "Sir (heavily influenced by keyCat)",
	version = "1.0",
	description = "Unloads plugins from last to first loaded while keeping a protected list loaded at all times.",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
}

public void OnPluginStart()
{
	g_aProtected = new ArrayList(ByteCountToCells(PLATFORM_MAX_PATH));
	g_aUnloadQueue = new ArrayList(ByteCountToCells(PLATFORM_MAX_PATH));

	// Gotta protect ourself of course.
	char sSelf[PLATFORM_MAX_PATH];
	GetPluginFilename(null, sSelf, sizeof(sSelf));
	Protect(sSelf);

	RegServerCmd("pm_unload_plugins", Cmd_UnloadPlugins, "pm_unload_plugins [refresh] - Unloads every unprotected plugin from last to first loaded, then reloads the auto-load plugins if \"refresh\" is given.");
	RegServerCmd("pm_protect", Cmd_Protect, "pm_protect <plugin> - Keeps a plugin loaded through pm_unload_plugins.");
	RegServerCmd("pm_protect_list", Cmd_ProtectList, "Lists the protected plugins.");

	// Check out the .cfg file for instructions
	ServerCommand("exec protectedplugins.cfg");
}

Action Cmd_UnloadPlugins(int args)
{
	char sArg[16];
	GetCmdArg(1, sArg, sizeof(sArg));

	// "continue" is our own call for the next batch.
	if (StrEqual(sArg, "continue", false))
		UnloadNextBatch();
	else
		StartUnload(StrEqual(sArg, "refresh", false));

	return Plugin_Handled;
}

Action Cmd_Protect(int args)
{
	if (args < 1)
	{
		PrintToServer("[Plugin Manager] Usage: pm_protect <plugin>");
		return Plugin_Handled;
	}

	char sArg[PLATFORM_MAX_PATH];
	GetCmdArg(1, sArg, sizeof(sArg));
	Protect(sArg);

	return Plugin_Handled;
}

Action Cmd_ProtectList(int args)
{
	PrintToServer("[Plugin Manager] %d protected plugin(s):", g_aProtected.Length);

	char sEntry[PLATFORM_MAX_PATH];
	for (int i = 0; i < g_aProtected.Length; i++)
	{
		g_aProtected.GetString(i, sEntry, sizeof(sEntry));
		PrintToServer("- %s", sEntry);
	}

	return Plugin_Handled;
}

void StartUnload(bool bRefresh)
{
	g_aUnloadQueue.Clear();
	g_bRefresh = bRefresh;

	char sFilename[PLATFORM_MAX_PATH];
	Handle hIterator = GetPluginIterator();

	while (MorePlugins(hIterator))
	{
		Handle hPlugin = ReadPlugin(hIterator);
		GetPluginFilename(hPlugin, sFilename, sizeof(sFilename));

		// A protected plugin that errored is unloaded too, so it'll load fresh again.
		if (!IsProtected(sFilename) || GetPluginStatus(hPlugin) > Plugin_Paused)
			g_aUnloadQueue.PushString(sFilename);
	}

	delete hIterator;

	ServerCommand("sm plugins load_unlock");
	UnloadNextBatch();
}

void UnloadNextBatch()
{
	char sFilename[PLATFORM_MAX_PATH];

	for (int i = 0; i < UNLOAD_BATCH && g_aUnloadQueue.Length > 0; i++)
	{
		int iLast = g_aUnloadQueue.Length - 1;
		g_aUnloadQueue.GetString(iLast, sFilename, sizeof(sFilename));
		g_aUnloadQueue.Erase(iLast);

		ServerCommand("sm plugins unload %s", sFilename);
	}

	if (g_aUnloadQueue.Length > 0)
		ServerCommand("pm_unload_plugins continue");
	else if (g_bRefresh)
		ServerCommand("sm plugins refresh");
}

void Protect(const char[] sPlugin)
{
	char sPath[PLATFORM_MAX_PATH];
	NormalizePath(sPlugin, sPath, sizeof(sPath));

	if (sPath[0] == '\0' || IsProtected(sPath))
		return;

	g_aProtected.PushString(sPath);
}

bool IsProtected(const char[] sPlugin)
{
	char sPath[PLATFORM_MAX_PATH], sEntry[PLATFORM_MAX_PATH];
	NormalizePath(sPlugin, sPath, sizeof(sPath));

	for (int i = 0; i < g_aProtected.Length; i++)
	{
		g_aProtected.GetString(i, sEntry, sizeof(sEntry));

		if (StrEqual(sEntry, sPath, false))
			return true;
	}

	return false;
}

/*
	Plugins are matched by their path inside 'plugins/'
	to prevent possible issues with server owners having the plugin in multiple folders.
*/
void NormalizePath(const char[] sPath, char[] sOut, int iLen)
{
	strcopy(sOut, iLen, sPath);
	TrimString(sOut);
	ReplaceString(sOut, iLen, "\\", "/");

	int iPathLen = strlen(sOut);
	if (iPathLen > 0 && (iPathLen < 4 || !StrEqual(sOut[iPathLen - 4], ".smx", false)))
		StrCat(sOut, iLen, ".smx");
}
