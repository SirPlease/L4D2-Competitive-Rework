#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <l4d2_direct>

public Plugin:myinfo =
{
	name = "Infected Flow Warp",
	author = "CanadaRox",
	description = "Allows infected to warp to survivors based on their flow",
	version = "1",
	url = "htts://github.com/CanadaRox/sourcemod-plugins/tree/master/infected_flow_warp"
};

enum survFlowEnum
{
	surv,
	Float:flow
};

new Handle:hNameToCharIDTrie;
new Handle:hFlowArray;

public OnPluginStart()
{
	PrepTries();
	hFlowArray = CreateArray(2);

	RegConsoleCmd("sm_warpto", WarpTo_Cmd, "Warps to the specified survivor");
}

PrepTries()
{
	hNameToCharIDTrie = CreateTrie();
	SetTrieValue(hNameToCharIDTrie, "bill", 0);
	SetTrieValue(hNameToCharIDTrie, "zoey", 1);
	SetTrieValue(hNameToCharIDTrie, "louis", 2);
	SetTrieValue(hNameToCharIDTrie, "francis", 3);
	
	SetTrieValue(hNameToCharIDTrie, "nick", 0);
	SetTrieValue(hNameToCharIDTrie, "rochelle", 1);
	SetTrieValue(hNameToCharIDTrie, "coach", 2);
	SetTrieValue(hNameToCharIDTrie, "ellis", 3);
}

public Action:WarpTo_Cmd(client, args)
{
	if (!IsGhostInfected(client))
	{
		return Plugin_Handled;
	}

	if (args != 1)
	{
		ReplyToCommand(client, "Usage: sm_warpto <#|name> (name must be lowercase)");
		return Plugin_Handled;
	}

	decl String:arg[12];
	decl survivorFlowRank;
	GetCmdArg(1, arg, sizeof(arg));
	survivorFlowRank = StringToInt(arg);

	if (survivorFlowRank)
	{
		decl Float:origin[3];
		GetClientAbsOrigin(GetSurvivorOfFlowRank(survivorFlowRank), origin);
		TeleportEntity(client, origin, NULL_VECTOR, NULL_VECTOR);
	}
	else
	{
		decl target;
		if (GetTrieValue(hNameToCharIDTrie, arg, target))
		{
			target = GetClientOfCharID(target);
			decl Float:origin[3];
			GetClientAbsOrigin(target, origin);
			TeleportEntity(client, origin, NULL_VECTOR, NULL_VECTOR);
		}
	}
	return Plugin_Handled;
}

stock GetSurvivorOfFlowRank(rank)
{
	decl survFlowEnum:currentSurv[survFlowEnum];
	for (new client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
		{
			currentSurv[surv] = client;
			currentSurv[flow] = L4D2Direct_GetFlowDistance(client);
			PushArrayArray(hFlowArray, currentSurv[0]);
		}
	}
	SortADTArrayCustom(hFlowArray, sortFunc);
	new arraySize = GetArraySize(hFlowArray);
	if (rank - 1 > arraySize)
		rank = arraySize;
	GetArrayArray(hFlowArray, rank - 1, currentSurv);
	ClearArray(hFlowArray);

	return currentSurv[0];
}

public sortFunc(index1, index2, Handle:array, Handle:hndl)
{
	decl item1[2];

	decl item2[2];

	if (Float:item1[1] > Float:item2[1])
		return -1;
	else if (Float:item1[1] < Float:item2[1])
		return 1;
	else
		return 0;
}

stock GetClientOfCharID(characterID)
{
	for (new client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && GetClientTeam(client) == 2)
		{
			if (GetEntProp(client, Prop_Send, "m_survivorCharacter") == characterID)
				return client;
		}
	}
	return 0;
}
stock IsGhostInfected(client)
{
	return GetClientTeam(client) == 3 && IsPlayerAlive(client) && GetEntProp(client, Prop_Send, "m_isGhost");
}
