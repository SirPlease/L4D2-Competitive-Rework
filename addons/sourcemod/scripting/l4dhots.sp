#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>

#define PLUGIN_VERSION "2.4"

public Plugin myinfo = 
{
    name = "L4D HOTs",
    author = "ProdigySim, CircleSquared, Forgetest",
    description = "Pills and Adrenaline heal over time",
    version = PLUGIN_VERSION,
    url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
}

ArrayList
	g_aHOTPair;

bool
	g_bLeft4Dead2;

ConVar
	hCvarPillHot,
	hCvarPillInterval,
	hCvarPillIncrement,
	hCvarPillTotal,
	pain_pills_health_value;

ConVar
	hCvarAdrenHot,
	hCvarAdrenInterval,
	hCvarAdrenIncrement,
	hCvarAdrenTotal,
	adrenaline_health_buffer;

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
	g_aHOTPair = new ArrayList(2);
	
	char buffer[16];
	pain_pills_health_value = FindConVar("pain_pills_health_value");
	pain_pills_health_value.GetString(buffer, sizeof(buffer));
	
	hCvarPillHot =			CreateConVar("l4d_pills_hot",				"0",	"Pills heal over time",				FCVAR_NOTIFY|FCVAR_SPONLY, true, 0.0, true, 1.0);
	hCvarPillInterval =		CreateConVar("l4d_pills_hot_interval",		"1.0",	"Interval for pills hot",			FCVAR_NOTIFY|FCVAR_SPONLY, true, 0.00001);
	hCvarPillIncrement =	CreateConVar("l4d_pills_hot_increment",		"10",	"Increment amount for pills hot",	FCVAR_NOTIFY|FCVAR_SPONLY, true, 1.0);
	hCvarPillTotal =		CreateConVar("l4d_pills_hot_total",			buffer,	"Total amount for pills hot",		FCVAR_NOTIFY|FCVAR_SPONLY, true, 0.0);
	
	if (hCvarPillHot.BoolValue) EnablePillHot();	
	hCvarPillHot.AddChangeHook(PillHotChanged);
	
	if (!g_bLeft4Dead2)
		return;
	
	adrenaline_health_buffer = FindConVar("adrenaline_health_buffer");
	adrenaline_health_buffer.GetString(buffer, sizeof(buffer));
	
	hCvarAdrenHot = 		CreateConVar("l4d_adrenaline_hot",				"0",	"Adrenaline heals over time",			FCVAR_NOTIFY|FCVAR_SPONLY, true, 0.0, true, 1.0);
	hCvarAdrenInterval =	CreateConVar("l4d_adrenaline_hot_interval",		"1.0",	"Interval for adrenaline hot",			FCVAR_NOTIFY|FCVAR_SPONLY, true, 0.00001);
	hCvarAdrenIncrement =	CreateConVar("l4d_adrenaline_hot_increment",	"15",	"Increment amount for adrenaline hot",	FCVAR_NOTIFY|FCVAR_SPONLY, true, 1.0);
	hCvarAdrenTotal =		CreateConVar("l4d_adrenaline_hot_total",		buffer,	"Total amount for adrenaline hot",		FCVAR_NOTIFY|FCVAR_SPONLY, true, 0.0);
	
	if (hCvarAdrenHot.BoolValue) EnableAdrenHot();
	hCvarAdrenHot.AddChangeHook(AdrenHotChanged);
}

public void OnPluginEnd()
{
	if (hCvarPillHot.BoolValue) DisablePillHot();
	if (g_bLeft4Dead2 && hCvarAdrenHot.BoolValue) DisableAdrenHot();
}

public void OnMapStart()
{
	g_aHOTPair.Clear();
}

public void Player_BotReplace_Event(Event event, const char[] name, bool dontBroadcast)
{
	HandleSurvivorTakeover(event.GetInt("player"), event.GetInt("bot"));
}

public void Bot_PlayerReplace_Event(Event event, const char[] name, bool dontBroadcast)
{
	HandleSurvivorTakeover(event.GetInt("bot"), event.GetInt("player"));
}

void HandleSurvivorTakeover(int replacee, int replacer)
{
	// There can be multiple HOTs happening at the same time
	// so cannot just use FindValue here.
	int size = g_aHOTPair.Length;
	for (int i = 0; i < size; ++i)
	{
		if (replacee == g_aHOTPair.Get(i, 0))
		{
			g_aHOTPair.Set(i, replacer, 0);
			
			DataPack dp = g_aHOTPair.Get(i, 1);
			dp.Reset();
			dp.WriteCell(replacer);
		}
	}
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
		__HealTowardsMax(client, total, iMaxHP);
	}
	else
	{
		__HealTowardsMax(client, increment, iMaxHP);
		DataPack myDP;
		CreateDataTimer(interval, __HOT_ACTION, myDP,
			TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		myDP.WriteCell(userid);
		myDP.WriteCell(increment);
		myDP.WriteCell(total-increment);
		myDP.WriteCell(iMaxHP);
		
		g_aHOTPair.Set(g_aHOTPair.Push(userid), myDP, 1);
	}
}

public Action __HOT_ACTION(Handle timer, DataPack pack)
{
	pack.Reset();
	
	int userid = pack.ReadCell();
	int client = GetClientOfUserId(userid);
	
	if (client && IsPlayerAlive(client) && !L4D_IsPlayerIncapacitated(client) && !L4D_IsPlayerHangingFromLedge(client))
	{
		int increment = pack.ReadCell();
		DataPackPos pos = pack.Position;
		int remaining = pack.ReadCell();
		int maxhp = pack.ReadCell();
		
		//PrintToChatAll("HOT: %N %d %d %d", client, increment, remaining, maxhp);
		
		if (increment < remaining)
		{
			__HealTowardsMax(client, increment, maxhp);
			pack.Position = pos;
			pack.WriteCell(remaining-increment);
			
			return Plugin_Continue;
		}
		else
		{
			__HealTowardsMax(client, remaining, maxhp);
		}
	}
	
	g_aHOTPair.Erase(g_aHOTPair.FindValue(pack, 1));
	return Plugin_Stop;
}

void __HealTowardsMax(int client, int amount, int max)
{
	float hb = L4D_GetTempHealth(client) + amount;
	float overflow = hb + GetClientHealth(client) - max;
	if (overflow > 0)
	{
		hb -= overflow;
	}
	L4D_SetTempHealth(client, hb);
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