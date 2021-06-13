#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <dhooks>

public Plugin myinfo =
{
	name = "[L4D2] Hunter Roll Anim",
	author = "BHaType",
	description = "Overrides hunter animation",
	version = "0.1",
	url = ""
}

Handle hSequence;

static const int g_iSequesec[] =
{
	767,
	765,
	768,
	624,
	623,
	622,
	621
};

public void OnPluginStart()
{
	Handle hConf = LoadGameConfigFile("l4d_hunter_roll");
	
	hSequence = DHookCreate(GameConfGetOffset(hConf, "Sequence"), HookType_Entity, ReturnType_Int, ThisPointer_CBaseEntity, OnSequenceSelect);
	DHookAddParam(hSequence, HookParamType_Int);
	
	delete hConf;
}

public MRESReturn OnSequenceSelect(int client, Handle hReturn, Handle hParams)
{
	if (!IsClientInGame(client) || GetClientTeam(client) != 3 || !IsPlayerAlive(client) || GetEntProp(client, Prop_Send, "m_zombieClass") != 3)
		return MRES_Ignored;
	
	int iSequence = DHookGetParam(hParams, 1);
	
	for (int i; i < sizeof g_iSequesec; i++)
	{
		if (g_iSequesec[i] == iSequence)
		{
			DHookSetParam(hParams, 1, 39);
			DHookSetReturn(hReturn, 39);

			return MRES_ChangedOverride;
		}
	}

	return MRES_Ignored;
}
 
public void OnClientPutInServer(int client)
{
	DHookEntity(hSequence, false, client);
}
 
public void OnAllPluginsLoaded()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && GetClientTeam(client) == 3)
			DHookEntity(hSequence, false, client);
	}
}