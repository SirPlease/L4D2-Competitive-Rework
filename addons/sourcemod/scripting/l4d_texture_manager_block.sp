#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

public Plugin myinfo =
{
	name = "Mathack Block",
	author = "Sir, Visor",
	description = "Kicks out clients who are potentially attempting to enable mathack",
	version = "1.1",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	float fRand = GetRandomFloat(2.5, 3.5);
	CreateTimer(fRand, CheckClients, _, TIMER_REPEAT);
}

public Action CheckClients(Handle hTimer)
{
	if (!IsServerProcessing()) {
		return Plugin_Continue;
	}
	
	for (int client = 1; client <= MaxClients; client++) {
		if (IsClientInGame(client) && !IsFakeClient(client)) {
			if (GetClientTeam(client) > 1) {// Only query clients on survivor or infected team, ignore spectators.
				QueryClientConVar(client, "mat_texture_list", ClientQueryCallback);
			}
		}
	}

	return Plugin_Continue;
}

public void ClientQueryCallback(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue, any value)
{
	switch (result) {
		case ConVarQuery_Okay: {
			int mathax = StringToInt(cvarValue);
			if (mathax > 0) {
				char t_name[MAX_NAME_LENGTH], t_ip[32], t_steamid[32], path[256];
				//gets client name
				GetClientName(client, t_name, sizeof(t_name));
				//gets steam id
				GetClientAuthId(client, AuthId_Steam2, t_steamid, sizeof(t_steamid));
				//checks to see if client is conncted -  also checks to see if client is a bot
				if (IsFakeClient(client)) {
					return;
				}
				
				//gets clients ip	
				GetClientIP(client,t_ip,31);
				
				BuildPath(Path_SM, path, 256, "logs/mathack_cheaters.txt");
				LogToFile(path, ".:[Name: %s | STEAMID: %s | IP: %s]:.", t_name, t_steamid, t_ip);
				PrintToChatAll("\x04[\x01Mathack Detector\x04] \x03%s \x01has been kicked for using mathack!", t_name);
				KickClient(client, "You have been kicked for using hacks. No rest for the wicked.");
			}
		}
		case ConVarQuery_NotFound: {
			KickClient(client, "ConVarQuery_NotFound");
		}
		case ConVarQuery_NotValid: {
			KickClient(client, "ConVarQuery_NotValid");
		}
		case ConVarQuery_Protected: {
			KickClient(client, "ConVarQuery_Protected");
		}
	}
}
