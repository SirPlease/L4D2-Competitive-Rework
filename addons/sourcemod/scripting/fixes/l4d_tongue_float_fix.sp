#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#define PLUGIN_VERSION "2.0"

public Plugin myinfo =
{
	name = "[L4D & 2] Tongue Float Fix",
	author = "Forgetest",
	description = "Fix tongue instant choking survivors.",
	version = PLUGIN_VERSION,
	url = "https://github.com/Target5150/MoYu_Server_Stupid_Plugins"
};

public void OnPluginStart()
{
	HookEvent("tongue_grab", Event_TongueGrab);
}

/**
 * ```cpp
 * void CTongue::UpdateAirChoke(CTongue *this)
 * {
 *   ...
 *
 *   if ( gpGlobals->curtime - m_tongueVictimLastOnGroundTime <= tongue_vertical_choke_time_off_ground.GetFloat() )
 *   {
 *     if ( ground height within cvar value )
 *     {
 *       pVictim->OnStopHangingFromTongue();
 *       return;
 *     }
 *   }
 *
 *   if ( pVictim->IsHangingFromLedge() )
 *   {
 *     pVictim->OnStopHangingFromTongue();
 *     return;
 *   }
 *
 *   pVictim->OnStartHangingFromTongue();
 *   ...
 * }
 * ```
 */

void Event_TongueGrab(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client || !IsClientInGame(client))
		return;
	
	int ability = GetEntPropEnt(client, Prop_Send, "m_customAbility");
	if (!IsValidEdict(ability))
		return;
	
	if (!HasEntProp(ability, Prop_Send, "m_tongueVictimLastOnGroundTime"))
		return;
	
	SetEntPropFloat(ability, Prop_Send, "m_tongueVictimLastOnGroundTime", GetGameTime());
}
