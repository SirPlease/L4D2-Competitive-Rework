#include <sourcemod>
#include <sdktools>
#include <basecomm>
#include <clients>

public Plugin myinfo =
{
	name		= "[L4D2] Silence",
	author		= "Altair Sossai",
	description = "Let your server have peace.",
	version		= "1.0",
	url			= "http://www.sourcemod.net/"
};

public void OnPluginStart()
{
	CreateTimer(5.0, SilenceTick, _, TIMER_REPEAT);
}

public Action SilenceTick(Handle timer)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client) || IsFakeClient(client))
			continue;

		new String:communityId[25];
		GetClientAuthId(client, AuthId_SteamID64, communityId, sizeof(communityId));

		if(StrEqual(communityId, "76561199157667941") /* hard */
		   || StrEqual(communityId, "76561199416635277") /* silence */
		   || StrEqual(communityId, "76561198016922491") /* amarok */)
		{
			BaseComm_SetClientGag(client, true);
			BaseComm_SetClientMute(client, true);
		}
	}

	return Plugin_Continue;
}