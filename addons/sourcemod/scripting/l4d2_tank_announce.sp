#pragma semicolon 1
#pragma newdecls required

#define L4D2Team_Infected 3
#define L4D2Infected_Tank 8

#include <sourcemod>
#include <sdktools_sound>
#include <colors>
#undef REQUIRE_PLUGIN
#include <l4d_tank_control_eq>
#define REQUIRE_PLUGIN

#define PLUGIN_VERSION "1.4"
#define DANG "ui/pickup_secret01.wav"

public Plugin myinfo = 
{
	name = "L4D2 Tank Announcer",
	author = "Visor, Forgetest, xoxo",
	description = "Announce in chat and via a sound when a Tank has spawned",
	version = PLUGIN_VERSION,
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnMapStart()
{
	PrecacheSound(DANG);
}

public void L4D_OnSpawnTank_Post(int client, const float vecPos[3], const float vecAng[3])
{
	int tankClient = client;
	char nameBuf[MAX_NAME_LENGTH];
	
	if (IsTankSelection())
	{
		if (IsTank(tankClient) && !IsFakeClient(tankClient)) 
		{
			FormatEx(nameBuf, sizeof(nameBuf), "%N", tankClient);
		} 
		else 
		{
			tankClient = GetTankSelection();
			if (tankClient > 0 
			&& IsClientInGame(tankClient)) 
			{
				FormatEx(nameBuf, sizeof(nameBuf), "%N", tankClient);
			} 
			else 
			{
				FormatEx(nameBuf, sizeof(nameBuf), "AI");
			}
		}
	}
	else
	{
		HookEvent("player_spawn", Event_PlayerSpawn);
		return;
	}
	
	CPrintToChatAll("{red}[{default}!{red}] {olive}Tank {default}({red}Control: %s{default}) has spawned!", nameBuf);
	EmitSoundToAll(DANG);
}

public void Event_PlayerSpawn(Event event, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	// Tanky Client?
	if (IsTank(client) && !IsFakeClient(client))
	{
		CPrintToChatAll("{red}[{default}!{red}] {olive}Tank {default}({red}Control: %N{default}) has spawned!", client);
		EmitSoundToAll(DANG);
		UnhookEvent("player_spawn", Event_PlayerSpawn);
	}
}

/**
 * Is the player the tank? 
 *
 * @param client client ID
 * @return bool
 */
bool IsTank(int client)
{
	return (IsClientInGame(client)
		&& GetClientTeam(client) == L4D2Team_Infected
		&& GetEntProp(client, Prop_Send, "m_zombieClass") == L4D2Infected_Tank);
}

/*
 * @return			true if GetTankSelection exist false otherwise.
 */
bool IsTankSelection()
{
	return (GetFeatureStatus(FeatureType_Native, "GetTankSelection") != FeatureStatus_Unknown);
}
