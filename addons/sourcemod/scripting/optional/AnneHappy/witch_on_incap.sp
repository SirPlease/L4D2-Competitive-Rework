#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <colors>
public Plugin myinfo =
{
	name = "Witch on incap.",
	description = "Spawns a witch anytime someone goes down!",
	author = "epilimic, morzlee",
	version = "1.1",
	url = "http://buttsecs.org"
};

#define TRANSLATION_FILE "witch_on_incap.phrases"
void LoadPluginTranslations()
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "translations/"...TRANSLATION_FILE...".txt");
	if (!FileExists(sPath))
	{
		SetFailState("Missing translation \""...TRANSLATION_FILE..."\"");
	}
	LoadTranslations(TRANSLATION_FILE);
}

public void OnPluginStart()
{
	LoadPluginTranslations();
	HookEvent("player_incapacitated", Event_Incap, EventHookMode_Post);
}

public Action Event_Incap(Handle event, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		int flags = GetCommandFlags("z_spawn_old");
		SetCommandFlags("z_spawn_old", flags & -16385);
		FakeClientCommand(client, "z_spawn_old witch auto");
		CPrintToChatAll("%t", "IncapSurSpawnAWitch", client);
		//PrintToChatAll("\x05%N \x01went down and spawned a witch!", client);
		SetCommandFlags("z_spawn_old", flags);
	}
	return Plugin_Continue;
}