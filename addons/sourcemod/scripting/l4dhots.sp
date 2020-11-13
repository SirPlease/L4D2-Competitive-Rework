#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = 
{
    name = "L4D HOTs",
    author = "ProdigySim, CircleSquared",
    description = "Pills and Adrenaline heal over time",
    version = "0.5",
    url = "https://bitbucket.org/ProdigySim/misc-sourcemod-plugins"
}

#define MAX(%0,%1) (((%0) > (%1)) ? (%0) : (%1))

#define WEPID_PAIN_PILLS 15
#define WEPID_ADRENALINE 23

enum struct hBuffer
{
	float fHBuffer;
	float fHBTime;
	
	void Clear() {
		this.fHBuffer = 0.0;
		this.fHBTime = 0.0;
	}
	
	void Record(int client) {
		this.fHBuffer = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
		this.fHBTime = GetEntPropFloat(client, Prop_Send, "m_healthBufferTime");
	}
	
	void Refresh(int client) {
		float fNewHBuffer = MAX(0.0, this.fHBuffer - ((GetGameTime() - this.fHBTime) * GetConVarFloat(FindConVar("pain_pills_decay_rate"))));
		float fNewHBTime = GetGameTime();
		
		SetEntPropFloat(client, Prop_Send, "m_healthBuffer", fNewHBuffer);
		SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", fNewHBTime);
		
		this.Record(client);
	}
}

hBuffer g_stctStoredHB[MAXPLAYERS+1];

bool IsL4D2;

ConVar pillhot;
ConVar hCvarPillInterval;
ConVar hCvarPillIncrement;
ConVar hCvarPillTotal;

ConVar adrenhot;
ConVar hCvarAdrenInterval;
ConVar hCvarAdrenIncrement;
ConVar hCvarAdrenTotal;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test == Engine_Left4Dead ) IsL4D2 = false;
	else if( test == Engine_Left4Dead2 ) IsL4D2 = true;
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	
	return APLRes_Success;
}

public void OnPluginStart()
{
    pillhot = CreateConVar("l4d_pills_hot", "0", "Pills heal over time");
    hCvarPillInterval = CreateConVar("l4d_pills_hot_interval", "1.0", "Interval for pills hot");
    hCvarPillIncrement = CreateConVar("l4d_pills_hot_increment", "10", "Increment amount for pills hot");
    hCvarPillTotal = CreateConVar("l4d_pills_hot_total", "50", "Total amount for pills hot");
    
    if (GetConVarBool(pillhot)) EnablePillHot();
    HookConVarChange(pillhot, PillHotChanged);
    
    if (IsL4D2)
    {
        adrenhot = CreateConVar("l4d_adrenaline_hot", "0", "Adrenaline heals over time");
        hCvarAdrenInterval = CreateConVar("l4d_adrenaline_hot_interval", "1.0", "Interval for adrenaline hot");
        hCvarAdrenIncrement = CreateConVar("l4d_adrenaline_hot_increment", "15", "Increment amount for adrenaline hot");
        hCvarAdrenTotal = CreateConVar("l4d_adrenaline_hot_total", "25", "Total amount for adrenaline hot");
        
        if (GetConVarBool(adrenhot)) EnableAdrenHot();
        HookConVarChange(adrenhot, AdrenHotChanged);
    }
}

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

void EnablePillHot()	{ SwitchEventHooks(true);	HookEvent("pills_used", PillsUsed_Event); }
void EnableAdrenHot()	{ SwitchEventHooks(true);	HookEvent("adrenaline_used", AdrenalineUsed_Event); }
void DisablePillHot()	{ SwitchEventHooks(false);	UnhookEvent("pills_used", PillsUsed_Event); }
void DisableAdrenHot()	{ SwitchEventHooks(false);	UnhookEvent("adrenaline_used", AdrenalineUsed_Event); }

void SwitchEventHooks(bool hook)
{
	static bool hooked = false;
	
	if (hook && !hooked)
	{
		HookEvent("player_team", PlayerTeam_Event);
		HookEvent("player_hurt", PlayerHurt_Event);
		HookEvent("heal_success", HealSuccess_Event);
		HookEvent("revive_success", ReviveSuccess_Event);
		HookEvent("weapon_fire", WeaponFire_Event);
		
		hooked = true;
	}
	
	if (!hook && hooked)
	{
		if (GetConVarBool(pillhot) || GetConVarBool(adrenhot)) return;
		
		UnhookEvent("player_team", PlayerTeam_Event);
		UnhookEvent("player_hurt", PlayerHurt_Event);
		UnhookEvent("heal_success", HealSuccess_Event);
		UnhookEvent("revive_success", ReviveSuccess_Event);
		UnhookEvent("weapon_fire", WeaponFire_Event);
		
		hooked = false;
	}
}

public void OnClientDisconnect(int client) { g_stctStoredHB[client].Clear(); }

public void DelayRecord(int client)
{
	if (client && IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		g_stctStoredHB[client].Record(client);
	}
}

public void PlayerTeam_Event(Event event, const char[] name, bool dontBroadcast)
{
	if (event.GetBool("disconnect"))
	{
		// Leave it dealt in OnClientDisconnect
		return;
	}
	
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client && IsClientInGame(client))
	{
		int team = event.GetInt("team");
		int oldteam = event.GetInt("oldteam");
		
		if (team == 2 || oldteam == 2) // entering or leaving Survivor Team
		{
			g_stctStoredHB[client].Clear();
			if (team == 2) RequestFrame(DelayRecord, client);
		}
	}
}

public void PlayerHurt_Event(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	RequestFrame(DelayRecord, client);
}

public void HealSuccess_Event(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "subject"));	
	RequestFrame(DelayRecord, client);
}

public void ReviveSuccess_Event(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "subject"));	
	RequestFrame(DelayRecord, client);
}

public void WeaponFire_Event(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client || !IsClientInGame(client) || !IsPlayerAlive(client))
	{
		return;
	}
	
	if (!IsL4D2) // seems WeaponID not work in L4D1, untested.
	{
		char weapon[32];
		event.GetString("weapon", weapon, sizeof(weapon));
		if (strcmp(weapon, "weapon_pain_pills") == 0)
		{
			g_stctStoredHB[client].Record(client);
		}
	}
	else
	{
		int wepid = event.GetInt("weaponid");
		if (wepid == WEPID_PAIN_PILLS || wepid == WEPID_ADRENALINE)
		{
			g_stctStoredHB[client].Record(client);
		}
	}
}

public void PillsUsed_Event(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    float iPillInterval = GetConVarFloat(hCvarPillInterval);
    int iPillIncrement = GetConVarInt(hCvarPillIncrement);
    int iPillTotal = GetConVarInt(hCvarPillTotal);
    HealEntityOverTime(client, iPillInterval, iPillIncrement, iPillTotal);
}

public void AdrenalineUsed_Event(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    float iAdrenInterval = GetConVarFloat(hCvarAdrenInterval);
    int iAdrenIncrement = GetConVarInt(hCvarAdrenIncrement);
    int iAdrenTotal = GetConVarInt(hCvarAdrenTotal);
    HealEntityOverTime(client, iAdrenInterval, iAdrenIncrement, iAdrenTotal);
}

void HealEntityOverTime(int client, float interval, int increment, int total)
{
    int maxhp=GetEntProp(client, Prop_Send, "m_iMaxHealth", 2);
    
    if (!client || !IsClientInGame(client) || !IsPlayerAlive(client))
    {
        return;
    }
    
    g_stctStoredHB[client].Refresh(client);
    
    if (increment >= total)
    {
        HealTowardsMax(client, total, maxhp);
    }
    else
    {
        HealTowardsMax(client, increment, maxhp);
        DataPack myDP;
        CreateDataTimer(interval, __HOT_ACTION, myDP, 
            TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
        WritePackCell(myDP, client);
        WritePackCell(myDP, increment);
        WritePackCell(myDP, total-increment);
        WritePackCell(myDP, maxhp);
    }
}

public Action __HOT_ACTION(Handle timer, DataPack pack)
{
    ResetPack(pack);
    int client = ReadPackCell(pack);
    int increment = ReadPackCell(pack);
    DataPackPos pos = GetPackPosition(pack);
    int remaining = ReadPackCell(pack);
    int maxhp = ReadPackCell(pack);
    
//  PrintToChatAll("HOT: %d %d %d %d", client, increment, remaining, maxhp);
    
    if (!client || !IsClientInGame(client) || IsIncapacitated(client) || !IsPlayerAlive(client))
    {
        return Plugin_Stop;
    }
    
    if (increment >= remaining)
    {
        HealTowardsMax(client, remaining, maxhp);
        return Plugin_Stop;
    }
    HealTowardsMax(client, increment, maxhp);
    SetPackPosition(pack, pos);
    WritePackCell(pack, remaining-increment);
    
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
    
    g_stctStoredHB[client].Record(client);
}


stock bool IsIncapacitated(int client)
{
    return view_as<bool>(GetEntProp(client, Prop_Send, "m_isIncapacitated"));
}
