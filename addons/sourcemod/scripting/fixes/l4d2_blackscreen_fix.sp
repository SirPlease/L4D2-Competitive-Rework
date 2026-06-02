#pragma semicolon 1
#pragma newdecls required
 
#include <sourcemod>
#include <sdktools>
#include <stringtables_data>

#define Config		"data/restrict_strings.cfg"
#define MaxString	128

char g_sItems[8192][PLATFORM_MAX_PATH], g_sRestricted[MaxString][PLATFORM_MAX_PATH];
int g_iItemsTotal;
bool g_bEmpty;

public Plugin myinfo =
{
	name = "[L4D & L4D2] Black Screen Fix",
	author = "BHaType & Dragokas",
	description = "Fixes blacksreen while file downloading"
};

public void OnPluginStart()
{
	RegAdminCmd("sm_get_restricted_strings",	CMD_GetStringRestricted, 	ADMFLAG_ROOT, 	"Get strings from restrict_strings");
	RegAdminCmd("sm_restore_st",	CMD_RestoreDownloadables, 	ADMFLAG_ROOT, 	"Restore downloadables stringtable items");
	
	HookEvent("player_disconnect", eDiconnect, EventHookMode_Pre);
	HookEvent("map_transition", eStart, EventHookMode_Pre);
}

public void OnMapStart()
{
	CreateTimer(1.0, Timer_SaveDownloadables, .flags = TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_SaveDownloadables(Handle timer)
{
	SaveDownloadables();
}

void SaveDownloadables()
{
	int iTable = FindStringTable("downloadables");
	if(iTable == INVALID_STRING_TABLE) 
	{
		LogError("Cannot find 'downloadables' string table!");
		return;
	}
	
	g_iItemsTotal = 0;
	int iNum = GetStringTableNumStrings(iTable);
 
	for (int i; i < iNum; i++)
	{
		ReadStringTable(iTable, i, g_sItems[g_iItemsTotal], sizeof(g_sItems[]));
		g_iItemsTotal++;
	}
	
	PrintToServer("[FixScreen] All strings has been saved and deleted from stringtable");
	
	INetworkStringTable table = INetworkStringTable(iTable);
	table.DeleteStrings();
	
	int index = ReadRestrictedFiles();
		
	if ( index != -1 )
		for (int i; i <= index; i++)
			if ( strlen(g_sRestricted[i]) )
				AddFileToDownloadsTable(g_sRestricted[i]);
}

public void eStart(Event event, const char[] name, bool dontBroadcast)
{
	if (g_iItemsTotal == 0 || g_bEmpty)
		return;
	
	for (int i = 0; i < g_iItemsTotal; i++)
		if ( strlen(g_sItems[i]) )
			AddFileToDownloadsTable(g_sItems[i]);
	
	PrintToServer("[FixScreen] All strings has been restored to downloadables");
}

public void eDiconnect (Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if ( (client == 0 || !IsFakeClient(client)) && !RealPlayerExist(client) ) 
		CreateTimer(6.3, tPlayers);
}

public Action tPlayers(Handle timer)
{
	if ( !RealPlayerExist() )
	{
		g_bEmpty = true;
		
		INetworkStringTable table = INetworkStringTable(FindStringTable("downloadables"));
		table.DeleteStrings();
		
		ReadRestrictedFiles();
	}
}

public Action CMD_RestoreDownloadables(int client, int args)
{
	if ( g_iItemsTotal == 0 ) 
	{
		ReplyToCommand(client, "Cannot restore. Downloadables string table is not saved");
		return Plugin_Handled;
	}
	
	for (int i; i < g_iItemsTotal; i++)
		if ( strlen(g_sItems[i]) )
			AddFileToDownloadsTable(g_sItems[i]);
			
	return Plugin_Handled;
}

public Action CMD_GetStringRestricted (int client, int args)
{
	int index = ReadRestrictedFiles();
	
	if ( index == -1 )
	{
		ReplyToCommand(client, "No config \"%s\" has been found", Config);
		return Plugin_Handled;
	}
	
	for (int i; i <= index; i++)
		if ( strlen(g_sRestricted[i]) )
			ReplyToCommand(client, "%i. %s", i, g_sRestricted[i]);
			
	return Plugin_Handled;
}

int ReadRestrictedFiles ()
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), Config);
	
	if ( FileExists(sPath) )
	{
		int index;
		
		char szBuffer[MaxString];
		File hFile = OpenFile(sPath, "r");
		
		while ( ReadFileLine(hFile, szBuffer, MaxString) )
		{
			if ( szBuffer[0] != '/' && szBuffer[1] != '/' )
			{
				TrimString(szBuffer);
				
				Format(g_sRestricted[index], MaxString, "%s", szBuffer);
				index++;
			}
		}
		
		delete hFile;
		return index;
	}
	
	return -1;
}

bool RealPlayerExist (int iExclude = 0)
{
	for (int client = 1; client < MaxClients; client++)
	{
		if ( client != iExclude && IsClientConnected(client) )
		{
			if ( !IsFakeClient(client) ) 
			{
				return true;
			}
		}
	}
	return false;
}