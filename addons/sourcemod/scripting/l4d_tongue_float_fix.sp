#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <dhooks>

#define PLUGIN_VERSION "1.1"

public Plugin myinfo =
{
	name = "[L4D & 2] Tongue Float Fix",
	author = "Forgetest",
	description = "Fix tongue instant choking survivors.",
	version = PLUGIN_VERSION,
	url = "https://github.com/Target5150/MoYu_Server_Stupid_Plugins"
};

#define GAMEDATA_FILE "l4d_tongue_float_fix"

public void OnPluginStart()
{
	Handle conf = LoadGameConfigFile(GAMEDATA_FILE);
	if (!conf)
		SetFailState("Missing gamedata \"" ... GAMEDATA_FILE ... "\"");
	
	Handle hDetour = DHookCreateFromConf(conf, "UpdateAirChoke");
	if (!hDetour)
		SetFailState("Missing detour setup \"UpdateAirChoke\"");
	
	if (!DHookEnableDetour(hDetour, false, OnUpdateAirChoke))
		SetFailState("Failed to enable detour \"UpdateAirChoke\"");
		
	delete conf;
}

public MRESReturn OnUpdateAirChoke(int pThis)
{
	int owner = GetEntPropEnt(pThis, Prop_Send, "m_owner");
	if (owner == -1)
		return MRES_Ignored;
	
	int victim = GetEntPropEnt(owner, Prop_Send, "m_tongueVictim");
	if (victim == -1)
		return MRES_Ignored;
	
	if (GetEntProp(victim, Prop_Send, "m_isHangingFromTongue"))
		return MRES_Ignored;
	
	float fNow = GetGameTime();
	float fElasped = fNow - GetEntPropFloat(pThis, Prop_Send, "m_tongueHitTimestamp");
	
	// choke generally doesn't happen in the first one second.
	if (fElasped > 0.0 && fElasped <= 1.0)
	{
		// Update this value to avoid issues afterwards.
		if (GetEntPropEnt(victim, Prop_Send, "m_hGroundEntity") != -1)
			SetEntPropFloat(pThis, Prop_Send, "m_tongueVictimLastOnGroundTime", fNow);
		
		return MRES_Supercede;
	}
	
	return MRES_Ignored;
}