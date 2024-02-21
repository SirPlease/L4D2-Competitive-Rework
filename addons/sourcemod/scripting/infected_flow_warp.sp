#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#define L4D2UTIL_STOCKS_ONLY 1
#include <l4d2util> //String_ToLower & IsValidSurvivor

StringMap
	hNameToCharIDTrie = null;

public Plugin myinfo =
{
	name = "Infected Flow Warp",
	author = "CanadaRox, A1m`",
	description = "Allows infected to warp to survivors based on their flow",
	version = "1.4",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	SaveCharacter();

	RegConsoleCmd("sm_warpto", WarpTo_Cmd, "Warps to the specified survivor");
}

void SaveCharacter()
{
	hNameToCharIDTrie = new StringMap();
	hNameToCharIDTrie.SetValue("bill", 0);
	hNameToCharIDTrie.SetValue("zoey", 1);
	hNameToCharIDTrie.SetValue("louis", 2);
	hNameToCharIDTrie.SetValue("francis", 3);
	
	hNameToCharIDTrie.SetValue("nick", 0);
	hNameToCharIDTrie.SetValue("rochelle", 1);
	hNameToCharIDTrie.SetValue("coach", 2);
	hNameToCharIDTrie.SetValue("ellis", 3);
}

public Action WarpTo_Cmd(int client, int args)
{
	if (client == 0 || !IsGhostInfected(client)) {
		return Plugin_Handled;
	}

	if (args == 0) {
		int fMaxFlowSurvivor = L4D_GetHighestFlowSurvivor(); //left4dhooks functional or left4downtown2 by A1m`
		if (!IsValidSurvivor(fMaxFlowSurvivor)) {
			PrintToChat(client, "No survivor player could be found!");
			return Plugin_Handled;
		}
		
		TeleportToClient(client, fMaxFlowSurvivor);
		return Plugin_Handled;
	}

	char arg[12];
	GetCmdArg(1, arg, sizeof(arg));
	StripQuotes(arg);
	String_ToLower(arg, sizeof(arg));
	
	int characterID;
	if (GetTrieValue(hNameToCharIDTrie, arg, characterID)) {
		int target = GetClientOfCharID(characterID);
		if (target > 0) {
			TeleportToClient(client, target);
		}
	}

	return Plugin_Handled;
}

void TeleportToClient(int client, int target)
{
	float origin[3];
	GetClientAbsOrigin(target, origin);
	TeleportEntity(client, origin, NULL_VECTOR, NULL_VECTOR);
}

int GetClientOfCharID(int characterID)
{
	for (int client = 1; client <= MaxClients; client++) {
		if (IsSurvivor(client)) {
			if (GetEntProp(client, Prop_Send, "m_survivorCharacter") == characterID) {
				return client;
			}
		}
	}

	return 0;
}

bool IsGhostInfected(int client)
{
	return (GetClientTeam(client) == L4D2Team_Infected
		&& IsPlayerAlive(client) 
		&& GetEntProp(client, Prop_Send, "m_isGhost", 1));
}
