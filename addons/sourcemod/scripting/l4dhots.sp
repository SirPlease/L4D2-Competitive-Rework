#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <left4dhooks_stocks>

#define PLUGIN_VERSION "2.1"

public Plugin myinfo = 
{
    name = "L4D HOTs",
    author = "ProdigySim, CircleSquared, Forgetest",
    description = "Pills and Adrenaline heal over time",
    version = PLUGIN_VERSION,
    url = "https://bitbucket.org/ProdigySim/misc-sourcemod-plugins"
}

int g_iReplaceClient[MAXPLAYERS+1];
Handle g_hReplaceTimer[MAXPLAYERS+1];

bool g_bLeft4Dead2;

ConVar hCvarPillHot;
ConVar hCvarPillInterval;
ConVar hCvarPillIncrement;
ConVar hCvarPillTotal;
ConVar pain_pills_health_value;

ConVar hCvarAdrenHot;
ConVar hCvarAdrenInterval;
ConVar hCvarAdrenIncrement;
ConVar hCvarAdrenTotal;
ConVar adrenaline_health_buffer;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test == Engine_Left4Dead ) g_bLeft4Dead2 = false;
	else if( test == Engine_Left4Dead2 ) g_bLeft4Dead2 = true;
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	
	return APLRes_Success;
}

public void OnPluginStart()
{
	pain_pills_health_value = FindConVar("pain_pills_health_value");
	hCvarPillHot = CreateConVar("l4d_pills_hot", "0", "Pills heal over time");
	hCvarPillInterval = CreateConVar("l4d_pills_hot_interval", "1.0", "Interval for pills hot");
	hCvarPillIncrement = CreateConVar("l4d_pills_hot_increment", "10", "Increment amount for pills hot");
	hCvarPillTotal = CreateConVar("l4d_pills_hot_total", "50", "Total amount for pills hot");
	
	if (hCvarPillHot.BoolValue) EnablePillHot();
	hCvarPillHot.AddChangeHook(PillHotChanged);
	
	if (g_bLeft4Dead2)
	{
		adrenaline_health_buffer = FindConVar("adrenaline_health_buffer");
		hCvarAdrenHot = CreateConVar("l4d_adrenaline_hot", "0", "Adrenaline heals over time");
		hCvarAdrenInterval = CreateConVar("l4d_adrenaline_hot_interval", "1.0", "Interval for adrenaline hot");
		hCvarAdrenIncrement = CreateConVar("l4d_adrenaline_hot_increment", "15", "Increment amount for adrenaline hot");
		hCvarAdrenTotal = CreateConVar("l4d_adrenaline_hot_total", "25", "Total amount for adrenaline hot");
		
		if (hCvarAdrenHot.BoolValue) EnableAdrenHot();
		hCvarAdrenHot.AddChangeHook(AdrenHotChanged);
	}
}

public void OnPluginEnd()
{
	if (hCvarPillHot.BoolValue) DisablePillHot();
	if (g_bLeft4Dead2 && hCvarAdrenHot.BoolValue) DisableAdrenHot();
}

public void Player_BotReplace_Event(Event event, const char[] name, bool dontBroadcast)
{
	int replacee = GetClientOfUserId(event.GetInt("player"));
	int replacer = GetClientOfUserId(event.GetInt("bot"));
	
	g_iReplaceClient[replacee] = replacer;
	if (g_hReplaceTimer[replacee])
	{
		delete g_hReplaceTimer[replacee];
		g_hReplaceTimer[replacee] = CreateTimer(0.1, Timer_ResetReplace, replacee);
	}
}

public void Bot_PlayerReplace_Event(Event event, const char[] name, bool dontBroadcast)
{
	int replacee = GetClientOfUserId(event.GetInt("bot"));
	int replacer = GetClientOfUserId(event.GetInt("player"));
	
	g_iReplaceClient[replacee] = replacer;
	if (g_hReplaceTimer[replacee])
	{
		delete g_hReplaceTimer[replacee];
		g_hReplaceTimer[replacee] = CreateTimer(0.1, Timer_ResetReplace, replacee);
	}
}

public Action Timer_ResetReplace(Handle timer, int client)
{
	g_hReplaceTimer[client] = null;
	g_iReplaceClient[client] = 0;
}

public void PillsUsed_Event(Event event, const char[] name, bool dontBroadcast)
{
	HealEntityOverTime(
		event.GetInt("userid"),
		hCvarPillInterval.FloatValue,
		hCvarPillIncrement.IntValue,
		hCvarPillTotal.IntValue
	);
}

public void AdrenalineUsed_Event(Event event, const char[] name, bool dontBroadcast)
{
	HealEntityOverTime(
		event.GetInt("userid"),
		hCvarAdrenInterval.FloatValue,
		hCvarAdrenIncrement.IntValue,
		hCvarAdrenTotal.IntValue
	);
}

void HealEntityOverTime(int userid, float interval, int increment, int total)
{
    int client = GetClientOfUserId(userid);
    if (!client || !IsClientInGame(client) || !IsPlayerAlive(client))
        return;
    
    int iMaxHP = GetEntProp(client, Prop_Send, "m_iMaxHealth", 2);
    
    if (increment >= total)
    {
        HealTowardsMax(client, total, iMaxHP);
    }
    else
    {
        HealTowardsMax(client, increment, iMaxHP);
        DataPack myDP;
        CreateDataTimer(interval, __HOT_ACTION, myDP, 
            TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
        myDP.WriteCell(userid);
        myDP.WriteCell(client);
        myDP.WriteCell(increment);
        myDP.WriteCell(total-increment);
        myDP.WriteCell(iMaxHP);
    }
}

public Action __HOT_ACTION(Handle timer, DataPack pack)
{
	pack.Reset();
	DataPackPos pos = pack.Position;
	int userid = pack.ReadCell();
	int lastClient = pack.ReadCell();
	int client = GetClientOfUserId(userid);
	
	if (!client || GetClientTeam(client) != 2)
	{
		if (g_iReplaceClient[lastClient])
		{
			client = g_iReplaceClient[lastClient];
			userid = GetClientUserId(client);
			
			pack.Position = pos;
			pack.WriteCell(userid);
			pack.WriteCell(client);
		}
		else { return Plugin_Stop; }
	}
	
	int increment = pack.ReadCell();
	pos = pack.Position;
	int remaining = pack.ReadCell();
	int maxhp = pack.ReadCell();
	
	//PrintToChatAll("HOT: %d %d %d %d", client, increment, remaining, maxhp);
	
	if (!IsPlayerAlive(client))
		return Plugin_Stop;
	
	if (L4D_IsPlayerIncapacitated(client) || L4D_IsPlayerHangingFromLedge(client))
		return Plugin_Stop;
    
	if (increment >= remaining)
	{
		HealTowardsMax(client, remaining, maxhp);
		return Plugin_Stop;
	}
	HealTowardsMax(client, increment, maxhp);
	pack.Position = pos;
	pack.WriteCell(remaining-increment);
	
	return Plugin_Continue;
}

void HealTowardsMax(int client, int amount, int max)
{
	float hb = float(amount) + GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	float overflow = (hb+GetClientHealth(client))-max;
	if (overflow > 0)
	{
		hb -= overflow;
	}
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", hb);
}


/**
 * ConVar Change
 */

public void PillHotChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	bool newval = StringToInt(newValue)!=0;
	if (newval && StringToInt(oldValue) ==0)
	{
		EnablePillHot();
	}
	else if (!newval && StringToInt(oldValue) != 0)
	{
		DisablePillHot();
	}
}

public void AdrenHotChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	bool newval = StringToInt(newValue)!=0;
	if (newval && StringToInt(oldValue) ==0)
	{
		EnableAdrenHot();
	}
	else if (!newval && StringToInt(oldValue) != 0)
	{
		DisableAdrenHot();
	}
}

void EnablePillHot()
{
	pain_pills_health_value.Flags &= ~FCVAR_REPLICATED;
	pain_pills_health_value.IntValue = 0;
	
	SwitchGeneralEventHooks(true);
	SwitchPillHotEventHook(true);
}

void EnableAdrenHot()
{
	adrenaline_health_buffer.Flags &= ~FCVAR_REPLICATED;
	adrenaline_health_buffer.IntValue = 0;
	
	SwitchGeneralEventHooks(true);
	SwitchAdrenHotEventHook(true);
}

void DisablePillHot()
{
	pain_pills_health_value.Flags &= FCVAR_REPLICATED;
	pain_pills_health_value.RestoreDefault();
	
	SwitchGeneralEventHooks(hCvarAdrenHot.BoolValue);
	SwitchPillHotEventHook(true);
}

void DisableAdrenHot()
{
	adrenaline_health_buffer.Flags &= FCVAR_REPLICATED;
	adrenaline_health_buffer.RestoreDefault();
	
	SwitchGeneralEventHooks(hCvarPillHot.BoolValue);
	SwitchAdrenHotEventHook(true);
}

void SwitchPillHotEventHook(bool hook)
{
	static bool hooked = false;
	
	if (hook && !hooked)
	{
		HookEvent("pills_used", PillsUsed_Event);
		hooked = true;
	}
	else if (!hook && hooked)
	{
		UnhookEvent("pills_used", PillsUsed_Event);
		hooked = false;
	}
}

void SwitchAdrenHotEventHook(bool hook)
{
	static bool hooked = false;
	
	if (hook && !hooked)
	{
		HookEvent("adrenaline_used", AdrenalineUsed_Event);
		hooked = true;
	}
	else if (!hook && hooked)
	{
		UnhookEvent("adrenaline_used", AdrenalineUsed_Event);
		hooked = false;
	}
}

void SwitchGeneralEventHooks(bool hook)
{
	static bool hooked = false;
	
	if (hook && !hooked)
	{
		HookEvent("player_bot_replace", Player_BotReplace_Event);
		HookEvent("bot_player_replace", Bot_PlayerReplace_Event);
		
		hooked = true;
	}
	
	else if (!hook && hooked)
	{
		UnhookEvent("player_bot_replace", Player_BotReplace_Event);
		UnhookEvent("bot_player_replace", Bot_PlayerReplace_Event);
		
		hooked = false;
	}
}