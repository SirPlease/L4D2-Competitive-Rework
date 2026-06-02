#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>

bool 
    bDebug = false,
    bAnim = false;

ConVar 
    convarDebug,
    convarAnim = null;

float
    g_flIncapTime[MAXPLAYERS+1];

public Plugin myinfo =
{
    name = "[L4D2] Flying Incap - Tank Punch",
    author = "Sir, Forgetest",
    description = "Sends Survivors flying on the incapping punch.",
    version = "2.0",
    url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
    convarDebug = CreateConVar("l4d2_tank_flying_incap_debug", "0", "Are we debugging?");
    convarAnim = CreateConVar("l4d2_tank_flying_incap_anim_fix", "0", "Remove the getting-up animation at the end of fly. (NOTE: Survivors will be able to shoot as soon as they land.)");
    bDebug = convarDebug.BoolValue;
    bAnim = convarAnim.BoolValue;
    convarDebug.AddChangeHook(CvarsChanged);
    convarAnim.AddChangeHook(CvarsChanged);

    HookEvent("player_incapacitated", Event_player_incapacitated);
}

// also serves as late-loader
public void OnMapStart()
{
    for (int i = 1; i <= MaxClients; ++i)
    {
        g_flIncapTime[i] = 0.0;
    }
}

void Event_player_incapacitated(Event event, const char[] name, bool dontBroadcast)
{
    int userid = event.GetInt("userid");

	// Doesn't matter it's valid or not, has a minimum of 0.
    g_flIncapTime[GetClientOfUserId(userid)] = GetGameTime();

	// punch fly animation is applied this frame, 
    RequestFrame(NextFrame_HookAnimation, userid);
}

void NextFrame_HookAnimation(int userid)
{
    if (!bAnim)
        return;

    int client = GetClientOfUserId(userid);
    if (!client || !IsClientInGame(client))
        return;

    if (GetClientTeam(client) != 2 || !IsPlayerAlive(client))
        return;

    if (!GetEntProp(client, Prop_Send, "m_isIncapacitated"))
        return;

    AnimHookEnable(client, AnimHook_PunchFly);
}

Action AnimHook_PunchFly(int client, int &activity)
{
    static int last = 0;

    if (bDebug && last != activity)
    {
        if (activity < 0) activity = 0;

        char curActName[64], lastActName[64];
        AnimGetActivity(activity, curActName, sizeof(curActName));
        AnimGetActivity(last, lastActName, sizeof(lastActName));
        PrintToChatAll("\x01[FlyingIncap]: (%.1f) (%N) [\x05%s\x01] [\x04%s\x01]", GetGameTime(), client, curActName, lastActName);

        last = activity;
    }

    switch (activity)
    {
    case L4D2_ACT_TERROR_HIT_BY_TANKPUNCH,
            L4D2_ACT_TERROR_IDLE_FALL_FROM_TANKPUNCH,
            L4D2_ACT_TERROR_JUMP_LANDING,
            L4D2_ACT_TERROR_JUMP_LANDING_HARD,
	        L4D2_ACT_DEPLOY_PISTOL:
        {
            return Plugin_Continue;
        }

    // Skip the getting up from ground animation
    case L4D2_ACT_TERROR_TANKPUNCH_LAND:
        {
            PlayerAnimState.FromPlayer(client).m_bIsPunchedByTank = false;  // no longer in punched animation

            activity = L4D2_ACT_DIESIMPLE;  // incap animation intro
        }
    }

    AnimHookDisable(client, AnimHook_PunchFly);
    return Plugin_Changed;
}

int g_iIncap;
public Action L4D_TankClaw_OnPlayerHit_Pre(int tank, int claw, int player)
{
    g_iIncap = GetEntProp(player, Prop_Send, "m_isIncapacitated");

    if (GetGameTime() == g_flIncapTime[player])
    {
        SetEntProp(player, Prop_Send, "m_isIncapacitated", 0);
    }

    return Plugin_Continue;
}

public void L4D_TankClaw_OnPlayerHit_Post(int tank, int claw, int player)
{
    SetEntProp(player, Prop_Send, "m_isIncapacitated", g_iIncap);
}

public void L4D_TankClaw_OnPlayerHit_PostHandled(int tank, int claw, int player)
{
    SetEntProp(player, Prop_Send, "m_isIncapacitated", g_iIncap);
}

void CvarsChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    bDebug = convarDebug.BoolValue;
    bAnim = convarAnim.BoolValue;
}