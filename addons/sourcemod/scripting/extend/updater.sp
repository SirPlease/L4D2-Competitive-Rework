#pragma semicolon 1
#pragma newdecls required

/* SM Includes */
#if !defined REQUIRE_EXTENSIONS
#define REQUIRE_EXTENSIONS
#endif
#include <SteamWorks>

/* Plugin Info */
#define PLUGIN_VERSION "1.3.4"

/*
 *	Changelogs:
 *
 *	Version 1.3.0
 *		> Updated to new syntax throughout.
 *		> Removed SteamTools Support due to it being superceeded by SteamWorks and broken.
 *		> Removed cURL Support due to it being very old and not supported.
 *		> Added Force-Check Command.
 *		> Updated the command descriptions.
 *		> Minor code 'cleanup'.
 *		> Added support for 'Include' files.
 *
 *	Version 1.3.1
 *		> Removed Socket support since it has no HTTPS Support (Thanks Dr. McKay).
 *
 *	Version 1.3.2
 *		> Redone the code.
 *
 *	Version 1.3.3
 *		> Removed ReloadPlugin() from updater.inc.
 *		> Added Updater_ReloadPlugin() native to replace 'ReloadPlugin()'
 *
 *	Version 1.3.4
 *		> Added Updater_OnLoaded() forward
 */

public Plugin myinfo = {
	name		= "Updater",
	author		= "GoD-Tony, Tk /id/Teamkiller324",
	description	= "Automatically updates SourceMod plugins and files",
	version		= PLUGIN_VERSION,
	url			= "http://forums.alliedmods.net/showthread.php?t=169095"
}

enum UpdateStatus {
	Status_Idle,		
	Status_Checking,		// Checking for updates.
	Status_Downloading,		// Downloading an update.
	Status_Updated,			// Update is complete.
	Status_Error,			// An error occured while downloading.
}

/* Globals */
//#define DEBUG		// This will enable verbose logging. Useful for developers testing their updates.

#define STEAMWORKS_AVAILABLE()	(GetFeatureStatus(FeatureType_Native, "SteamWorks_WriteHTTPResponseBodyToFile") == FeatureStatus_Available)
#define EXTENSION_ERROR			"This plugin requires SteamWorks extensions to function."
#define TEMP_FILE_EXT			"temp"		// All files are downloaded with this extension first.
#define MAX_URL_LENGTH			256
#define UPDATE_URL				"https://raw.githubusercontent.com/Teamkiller324/Updater/main/Updater.txt"

bool g_bGetDownload, g_bGetSource;

GlobalForward g_OnLoaded = null;
ArrayList g_hPluginPacks = null;
ArrayList g_hDownloadQueue = null;
ArrayList g_hRemoveQueue = null;
bool g_bDownloading = false;

static Handle _hUpdateTimer = null;
static float _fLastUpdate = 0.0;
static char _sDataPath[PLATFORM_MAX_PATH];

/* Core Includes */
#include "updater/plugins.sp"
#include "updater/filesys.sp"
#include "updater/download.sp"
#include "updater/api.sp"

/* Plugin Functions */
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)	{
	API_Init();
	RegPluginLibrary("updater");
	return APLRes_Success;
}

public void OnPluginStart()	{
	if(!STEAMWORKS_AVAILABLE())
		SetFailState(EXTENSION_ERROR);
	
	LoadTranslations("common.phrases");
	
	g_OnLoaded = new GlobalForward("Updater_OnLoaded", ET_Event);
	
	// Convars.
	ConVar hCvar = null;
	
	(hCvar = CreateConVar("sm_updater_version", PLUGIN_VERSION, "Updater - version", FCVAR_NOTIFY|FCVAR_DONTRECORD)).AddChangeHook(OnVersionChanged);
	OnVersionChanged(hCvar, "", "");
	
	(hCvar = CreateConVar("sm_updater", "2", "Updater - Determines update functionality. (1 = Notify, 2 = Download, 3 = Include source code)", _, true, 1.0, true, 3.0)).AddChangeHook(OnSettingsChanged);
	OnSettingsChanged(hCvar, "", "");
	
	// Commands.
	RegAdminCmd("sm_updater_check", Command_Check, ADMFLAG_RCON, "Updater - Forces Updater to check for updates.");
	RegAdminCmd("sm_updater_forcecheck", Command_ForceCheck, ADMFLAG_RCON, "Updater - Forces updater to check for updates without limits");
	RegAdminCmd("sm_updater_status", Command_Status, ADMFLAG_RCON, "Updater - View the status of Updater.");
	
	// Initialize arrays.
	g_hPluginPacks = new ArrayList();
	g_hDownloadQueue = new ArrayList();
	g_hRemoveQueue = new ArrayList();
	
	// Temp path for checking update files.
	BuildPath(Path_SM, _sDataPath, sizeof(_sDataPath), "data/updater.txt");
	
	#if !defined DEBUG
	// Add this plugin to the autoupdater.
	Updater_AddPlugin(GetMyHandle(), UPDATE_URL);
	#endif

	// Check for updates every 24 hours.
	_hUpdateTimer = CreateTimer(86400.0, Timer_CheckUpdates, _, TIMER_REPEAT);
}

public void OnAllPluginsLoaded()	{
	// Check for updates on startup.
	TriggerTimer(_hUpdateTimer, true);
	
	Call_StartForward(g_OnLoaded);
	Call_Finish();
}

Action Timer_CheckUpdates(Handle timer)	{
	Updater_FreeMemory();
	
	// Update everything!
	int maxPlugins = GetMaxPlugins();
	for(int i = 0; i < maxPlugins; i++)	{		
		if(Updater_GetStatus(i) == Status_Idle)
			Updater_Check(i);
	}
	
	_fLastUpdate = GetTickedTime();
}

Action Command_Check(int client, int args)	{
	float fNextUpdate = _fLastUpdate + 3600.0;
	
	switch(fNextUpdate > GetTickedTime())	{
		case true: ReplyToCommand(client, "[Updater] Updates can only be checked once per hour. %.1f minutes remaining.", (fNextUpdate - GetTickedTime()) / 60.0);
		case false:	{
			ReplyToCommand(client, "[Updater] Checking for updates.");
			TriggerTimer(_hUpdateTimer, true);
		}
	}
}

Action Command_ForceCheck(int client, int args)	{
	ReplyToCommand(client, "[Updater] Force-checking for updates.");
	CreateTimer(0.1, Timer_CheckUpdates);
}

Action Command_Status(int client, int args)	{
	char sFilename[64];
	Handle hPlugin = null;
	int maxPlugins = GetMaxPlugins();
	
	ReplyToCommand(client, "[Updater] -- Status Begin --");
	ReplyToCommand(client, "Plugins being monitored for updates:");
	
	for(int i = 0; i < maxPlugins; i++)	{
		hPlugin = IndexToPlugin(i);
		
		if(IsValidPlugin(hPlugin))	{
			GetPluginFilename(hPlugin, sFilename, sizeof(sFilename));
			ReplyToCommand(client, "  [%i]  %s", i, sFilename);
		}
	}
	
	ReplyToCommand(client, "Last update check was %.1f minutes ago.", (GetTickedTime() - _fLastUpdate) / 60.0);
	ReplyToCommand(client, "[Updater] --- Status End ---");
}

void OnVersionChanged(ConVar cvar, const char[] oldvalue, const char[] newvalue) { if(!StrEqual(newvalue, PLUGIN_VERSION)) cvar.SetString(PLUGIN_VERSION); }

void OnSettingsChanged(ConVar cvar, const char[] oldvalue, const char[] newvalue)	{
	switch(cvar.IntValue)	{
		case 1:	{ // Notify only.
			g_bGetDownload = false;
			g_bGetSource = false;
		}
		
		case 2:	{ // Download updates.
			g_bGetDownload = true;
			g_bGetSource = false;
		}
		
		case 3:	{ // Download with source code.
			g_bGetDownload = true;
			g_bGetSource = true;
		}
	}
}

#if !defined DEBUG
public void Updater_OnPluginUpdated() {
	Updater_Log("Reloading Updater plugin... updates will resume automatically.");
	
	// Reload this plugin.
	char filename[64];
	GetPluginFilename(INVALID_HANDLE, filename, sizeof(filename));
	ServerCommand("sm plugins reload %s", filename);
}
#endif

void Updater_Check(int index) {
	if (Fwd_OnPluginChecking(IndexToPlugin(index)) == Plugin_Continue)	{
		char url[MAX_URL_LENGTH];
		Updater_GetURL(index, url, sizeof(url));
		Updater_SetStatus(index, Status_Checking);
		AddToDownloadQueue(index, url, _sDataPath);
	}
}

void Updater_FreeMemory()	{
	// Make sure that no threads are active.
	if(g_bDownloading || g_hDownloadQueue.Length)
		return;
	
	// Remove all queued plugins.	
	int index;
	int maxPlugins = g_hRemoveQueue.Length;
	for(int i = 0; i < maxPlugins; i++)	{
		index = PluginToIndex(g_hRemoveQueue.Get(i));
		
		if (index != -1)
			Updater_RemovePlugin(index);
	}
	
	g_hRemoveQueue.Clear();
	
	// Remove plugins that have been unloaded.
	for(int i = 0; i < GetMaxPlugins(); i++)	{
		if(!IsValidPlugin(IndexToPlugin(i)))	{
			Updater_RemovePlugin(i);
			i--;
		}
	}
}

void Updater_Log(const char[] format, any ...)	{
	char buffer[256], path[PLATFORM_MAX_PATH];
	VFormat(buffer, sizeof(buffer), format, 2);
	BuildPath(Path_SM, path, sizeof(path), "logs/Updater.log");
	LogToFileEx(path, "%s", buffer);
}

#if defined DEBUG
void Updater_DebugLog(const char[] format, any ...)	{
	char buffer[256], path[PLATFORM_MAX_PATH];
	VFormat(buffer, sizeof(buffer), format, 2);
	BuildPath(Path_SM, path, sizeof(path), "logs/Updater_Debug.log");
	LogToFileEx(path, "%s", buffer);
}
#endif
