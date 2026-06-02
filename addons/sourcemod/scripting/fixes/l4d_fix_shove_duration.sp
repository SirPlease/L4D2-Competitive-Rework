#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <dhooks>
#include <left4dhooks>

#define PLUGIN_VERSION "1.0"

public Plugin myinfo =
{
    name = "[L4D & 2] Fix Shove Duration",
    author = "Forgetest",
    description = "Fix SI getting shoved by \"nothing\".",
    version = PLUGIN_VERSION,
    url = "https://github.com/Target5150/MoYu_Server_Stupid_Plugins"
};

#define GAMEDATA_FILE "l4d_fix_shove_duration"
#define KEY_FUNCTION "CTerrorPlayer::OnShovedByLunge"

ConVar z_gun_swing_duration;

public void OnPluginStart()
{
    GameData conf = new GameData(GAMEDATA_FILE);
    if ( !conf )
        SetFailState("Missing gamedata \""...GAMEDATA_FILE..."\"");
	
    DynamicDetour hDetour = DynamicDetour.FromConf(conf, KEY_FUNCTION);
    if ( !hDetour )
        SetFailState("Missing detour setup \""...KEY_FUNCTION..."\"");
    if ( !hDetour.Enable(Hook_Pre, DTR_OnShovedByLunge) || !hDetour.Enable(Hook_Post, DTR_OnShovedByLunge_Post) )
        SetFailState("Failed to detour \""...KEY_FUNCTION..."\"");
	
    delete hDetour;
    delete conf;
	
    z_gun_swing_duration = FindConVar("z_gun_swing_duration");
}

/*
bool CTerrorPlayer::IsShoving()
{
    if ( !m_shovingTimer.HasStarted() )
        return false;
	
    return m_shovingTimer.IsLessThen( 1.0 );
}
*/

MRESReturn DTR_OnShovedByLunge(DHookReturn hReturn, DHookParam hParams)
{
    int client = hParams.Get(1);
    ITimer_OffsetTimestamp(GetShovingTimer(client), z_gun_swing_duration.FloatValue - 1.0);
	
    return MRES_Ignored;
}

MRESReturn DTR_OnShovedByLunge_Post(DHookReturn hReturn, DHookParam hParams)
{
    int client = hParams.Get(1);
    ITimer_OffsetTimestamp(GetShovingTimer(client), 1.0 - z_gun_swing_duration.FloatValue);
	
    return MRES_Ignored;
}

public Action L4D2_OnJockeyRide(int victim, int attacker)
{
    ITimer_OffsetTimestamp(GetShovingTimer(victim), z_gun_swing_duration.FloatValue - 1.0);
	
    return Plugin_Continue;
}

public void L4D2_OnJockeyRide_Post(int victim, int attacker)
{
    ITimer_OffsetTimestamp(GetShovingTimer(victim), 1.0 - z_gun_swing_duration.FloatValue);
}

void ITimer_OffsetTimestamp(IntervalTimer timer, float offset)
{
    if ( ITimer_HasStarted(timer) )
    {
        float timestamp = __ITimer_GetTimestamp(timer);
        ITimer_SetTimestamp(timer, timestamp + offset);
    }
}

// wait for left4dhooks update to fix this one
/*
any Direct_ITimer_GetTimestamp(Handle plugin, int numParams) // Native "ITimer_GetTimestamp"
{
    CountdownTimer timer = GetNativeCell(1); // CountdownTimer
    return Stock_CTimer_GetTimestamp(timer); // ctimer
}
*/
float __ITimer_GetTimestamp(IntervalTimer timer)
{
    return LoadFromAddress(view_as<Address>(timer) + view_as<Address>(4), NumberType_Int32);
}

IntervalTimer GetShovingTimer(int client)
{
    static int s_iOffs_ShovingTimer = -1;
    if ( s_iOffs_ShovingTimer == -1 )
        s_iOffs_ShovingTimer = FindSendPropInfo("CTerrorPlayer", "m_customAbility") + 164;
	
    return view_as<IntervalTimer>(GetEntityAddress(client) + view_as<Address>(s_iOffs_ShovingTimer));
}