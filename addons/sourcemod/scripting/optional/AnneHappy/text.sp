#pragma semicolon 1
#pragma newdecls required
#pragma tabsize 0
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>
#include <steamworks>
#define IsValidClient(%1)		(1 <= %1 <= MaxClients && IsClientInGame(%1))

//#include <smlib>
//#define PLUGIN_VERSION	"2022-08"
ConVar
	g_hCvarInfectedTime,
	g_hCvarInfectedLimit,
	g_hCvarTankBhop,
	g_hCvarWeapon,
	g_hCvarCoop,
	g_hAutoSpawnTimeControl,
	g_hCvarPluginVersion,
	g_hCvarAiDynamicEnable,
	g_hCvarAiCurrentLevel,
	g_hCvarAiCurrentMode,
	g_hCvarAiFixedLevel;

int 
	CommonLimit,
	CommonTime,
	TankBhop,
	Weapon,
	MaxPlayers;
char PLUGIN_VERSION[32];

public void OnPluginStart()
{
	g_hCvarInfectedTime = FindConVar("versus_special_respawn_interval");
	g_hCvarInfectedLimit = FindConVar("l4d_infected_limit");
	g_hCvarTankBhop = FindConVar("ai_Tank_Bhop");
	g_hAutoSpawnTimeControl = FindConVar("inf_EnableAutoSpawnTime");
	RefreshDynamicAiCvars();
	g_hCvarWeapon = CreateConVar("ZonemodWeapon", "0", "", 0, false, 0.0, false, 0.0);
	g_hCvarPluginVersion = CreateConVar("AnnePluginVersion", "Latest", "Anne插件版本");
	HookConVarChange(g_hCvarInfectedTime, Cvar_InfectedTime);
	if(g_hCvarInfectedLimit != null)
		HookConVarChange(g_hCvarInfectedLimit, Cvar_InfectedLimit);
	if(g_hCvarTankBhop != null)
		HookConVarChange(g_hCvarTankBhop, CvarTankBhop);
	HookConVarChange(g_hCvarWeapon, CvarWeapon);
	HookConVarChange(g_hCvarPluginVersion, CvarPluginVersion);
	CommonTime = GetConVarInt(g_hCvarInfectedTime);
	CommonLimit = GetConVarInt(g_hCvarInfectedLimit);
	if(g_hCvarTankBhop != null)
		TankBhop = GetConVarInt(g_hCvarTankBhop);
	Weapon = GetConVarInt(g_hCvarWeapon);
	RegConsoleCmd("sm_xx",InfectedStatus);
	g_hCvarCoop = CreateConVar("coopmode", "0");
	HookEvent("player_incapacitated_start", Incap_Event, EventHookMode_Post);
	HookEvent("player_incapacitated", Incap_Event, EventHookMode_Post);
	HookEvent("round_start", event_RoundStart);
	HookEvent("player_death", player_death, EventHookMode_Post);
	RegAdminCmd("sm_killall", killall, ADMFLAG_BAN, "处死所有玩家");
}

public void OnAllPluginsLoaded()
{
	RefreshDynamicAiCvars();
}

public void OnPluginEnd()
{
	g_hCvarWeapon.RestoreDefault();
}

public Action player_death(Handle event, char[] name, bool dontBroadcast)
{
	if(IsTeamImmobilised())
	{
		SlaySurvivors();
	}
	return Plugin_Continue;
}

public Action killall(int client, int args)
{
	if(IsValidClient(client) && GetClientTeam(client) == 2)
		SlaySurvivors();
	return Plugin_Handled;
}

public void SlaySurvivors() { //incap everyone
	for(int i=1; i<=MaxClients ; i++)
		if(IsValidPlayer(i,true,false) && GetClientTeam(i)==2)
			ForcePlayerSuicide(i);
}

public void Incap_Event(Handle event, char[] name, bool dontBroadcast)
{
	int  Incap = GetClientOfUserId(GetEventInt(event, "userid"));
	if(GetConVarBool(g_hCvarCoop))
	{
		ForcePlayerSuicide(Incap);
	}
	if(IsTeamImmobilised())
	{
		SlaySurvivors();
	}
}


//离开安全门重新加载插件（理论上不应该在此插件完成）
public Action L4D_OnFirstSurvivorLeftSafeArea(int client)
{
	ServerCommand("sm_startspawn");
	return Plugin_Continue;
}
public void Cvar_InfectedTime(ConVar convar, const char[] oldValue, const char[] newValue)
{
	CommonTime = GetConVarInt(g_hCvarInfectedTime);
}
public void Cvar_InfectedLimit(ConVar convar, const char[] oldValue, const char[] newValue)
{
	CommonLimit = GetConVarInt(g_hCvarInfectedLimit);
	char tags[64];
	GetConVarString(FindConVar("l4d_ready_cfg_name"), tags, sizeof(tags));
	if (Weapon == 2 && CommonLimit< 10 && ( StrContains(tags, "WitchParty", false) != -1 || StrContains(tags, "AllCharger", false) != -1 || StrContains(tags, "AnneHappy", false) != -1))
	{
		ServerCommand("sm_cvar ZonemodWeapon 0");
		PrintToChatAll("\x03因为不超过10特，AnneHappy+武器已经自动切换为AnneHappy武器");
	}
}
public void CvarTankBhop(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if(g_hCvarTankBhop != null)
		TankBhop = GetConVarInt(g_hCvarTankBhop);
}

public void CvarPluginVersion(ConVar convar, const char[] oldValue, const char[] newValue)
{
	Format(PLUGIN_VERSION, sizeof(PLUGIN_VERSION), "%s", newValue);
	//strcopy(PLUGIN_VERSION, sizeof(PLUGIN_VERSION), newValue);
}


public void CvarWeapon(ConVar convar, const char[] oldValue, const char[] newValue)
{
	Weapon = GetConVarInt(g_hCvarWeapon);
	char tags[64];
	GetConVarString(FindConVar("l4d_ready_cfg_name"), tags, sizeof(tags));
	if (Weapon == 1)
	{
		ServerCommand("exec vote/weapon/zonemod.cfg");
	}
	else if (Weapon == 0)
	{
		ServerCommand("exec vote/weapon/AnneHappy.cfg");
	}
	else if (Weapon == 2)
	{
		if(CommonLimit >= 10 || (StrContains(tags, "Alone", false) != -1) || (StrContains(tags, "1vHunters", false) != -1))
			ServerCommand("exec vote/weapon/AnneHappyPlus.cfg");
		else
		{
			PrintToChatAll("\x03因为不超过10特，无法使用AnneHappyPlus武器");
			ServerCommand("sm_cvar ZonemodWeapon 0");
		}
			
	}
}


void printinfo(int client = 0, bool All = true){
	//FormatTime(sBuffer, sizeof(sBuffer), "%Y/%m/%d");
	char buffer[256];
	char buffer2[256];
	char aiBuffer[64];
	if(g_hCvarTankBhop != null){
		Format(buffer, sizeof(buffer), "\x03Tank连跳\x05[\x04%s\x05]", TankBhop > 0?"开启":"关闭");
		Format(buffer, sizeof(buffer), "%s \x03武器\x05[\x04%s\x05]", buffer, Weapon > 0?(Weapon > 1?"Anne+":"Zone"):"Anne");
	}else
	{
		Format(buffer, sizeof(buffer), "\x03武器\x05[\x04%s\x05]",  Weapon > 0?(Weapon > 1?"Anne+":"Zone"):"Anne");
	}

	if(BuildAiDifficultyText(aiBuffer, sizeof(aiBuffer)))
		Format(buffer, sizeof(buffer), "%s %s", buffer, aiBuffer);
		
	if(PLUGIN_VERSION[0] == '\0')
	GetConVarString(g_hCvarPluginVersion, PLUGIN_VERSION, sizeof(PLUGIN_VERSION));
	Format(buffer, sizeof(buffer), "%s \x03特感\x05[\x04%s%i特%i秒\x05] \x03电信服\x05[\x04%s\x05]", buffer, (g_hAutoSpawnTimeControl != null && g_hAutoSpawnTimeControl.BoolValue)?"自动":"固定", CommonLimit, CommonTime, PLUGIN_VERSION);
	int max_dist = GetConVarInt(FindConVar("inf_SpawnDistanceMin"));
	Format(buffer2, sizeof(buffer2), "\x03特感最近生成距离\x05[\x04%d\x05]", max_dist);
	if(FindConVar("inf_TeleportCheckTime")){
		int Teleport_CheckTime = GetConVarInt(FindConVar("inf_TeleportCheckTime"));
		Format(buffer2, sizeof(buffer2), "%s \x03特感传送条件\x05[\x04%d秒不可见\x05]", buffer2, Teleport_CheckTime);
	}
	if(FindConVar("ReturnBlood") && GetConVarInt(FindConVar("ReturnBlood")) > 0)
		Format(buffer2, sizeof(buffer2), "%s \x03回血\x05[\x04开启\x05]", buffer2);
	if(FindConVar("ai_TankConsume") && GetConVarInt(FindConVar("ai_TankConsume")) > 0)
		Format(buffer2, sizeof(buffer2), "%s \x03坦克消耗\x05[\x04开启\x05]", buffer2);
	else if(FindConVar("ai_TankSneakTime") && GetConVarFloat(FindConVar("ai_TankSneakTime")) > 0.0)
	{
		Format(buffer2, sizeof(buffer2), "%s \x03狡猾坦克\x05[\x04开启\x05]", buffer2);
	}
	if(All){
		PrintToChatAll(buffer);
		PrintToChatAll(buffer2);
	}else
	{
		PrintToChat(client, buffer);
		PrintToChat(client, buffer2);
	}
}

void RefreshDynamicAiCvars()
{
	if(g_hCvarAiDynamicEnable == null)
		g_hCvarAiDynamicEnable = FindConVar("ah_ai_dynamic_enable");
	if(g_hCvarAiCurrentLevel == null)
		g_hCvarAiCurrentLevel = FindConVar("ah_ai_dynamic_current_level");
	if(g_hCvarAiCurrentMode == null)
		g_hCvarAiCurrentMode = FindConVar("ah_ai_dynamic_current_mode");
	if(g_hCvarAiFixedLevel == null)
		g_hCvarAiFixedLevel = FindConVar("ah_ai_dynamic_fixed_level");
}

bool BuildAiDifficultyText(char[] buffer, int maxlen)
{
	RefreshDynamicAiCvars();

	if(g_hCvarAiCurrentLevel == null)
		return false;
	if(g_hCvarAiDynamicEnable != null && !g_hCvarAiDynamicEnable.BoolValue)
		return false;

	int level = g_hCvarAiCurrentLevel.IntValue;
	int mode = g_hCvarAiCurrentMode != null ? g_hCvarAiCurrentMode.IntValue : 0;
	int fixedLevel = g_hCvarAiFixedLevel != null ? g_hCvarAiFixedLevel.IntValue : 0;

	if(level <= 0 && fixedLevel > 0)
	{
		level = fixedLevel;
		mode = 1;
	}

	char levelName[16];
	GetAiLevelName(level, levelName, sizeof(levelName));
	Format(buffer, maxlen, "\x03动态难度\x05[\x04%s-%s\x05]", mode > 0 ? "固定" : "自动", levelName);
	return true;
}

void GetAiLevelName(int level, char[] buffer, int maxlen)
{
	switch(level)
	{
		case 1:
		{
			strcopy(buffer, maxlen, "简单");
		}
		case 2:
		{
			strcopy(buffer, maxlen, "普通");
		}
		case 3:
		{
			strcopy(buffer, maxlen, "困难");
		}
		case 4:
		{
			strcopy(buffer, maxlen, "专家");
		}
		case 5:
		{
			strcopy(buffer, maxlen, "极限");
		}
		default:
		{
			strcopy(buffer, maxlen, "待定");
		}
	}
}

public Action InfectedStatus(int Client, int args)
{ 
	printinfo(Client);
	return Plugin_Handled;
}
public void event_RoundStart(Handle event, char[] name, bool dontBroadcast)
{
	printinfo();
}
public void OnClientPutInServer(int Client)
{
	//FormatTime(sBuffer, sizeof(sBuffer), "%Y/%m/%d");
	if (IsValidPlayer(Client, false))
	{
		MaxPlayers ++ ;
		if(MaxPlayers == getBotLimit())
		{
			ConVar gjrj = FindConVar("sb_fix_enabled");
			if(gjrj != null && gjrj.BoolValue)
				SetConVarInt(gjrj, false);
		}
		printinfo(Client, false);
	}
}
stock bool IsValidPlayer(int Client, bool AllowBot = true, bool AllowDeath = true)
{
	if (Client < 1 || Client > MaxClients)
		return false;
	if (!IsClientConnected(Client) || !IsClientInGame(Client))
		return false;
	if (!AllowBot)
	{
		if (IsFakeClient(Client))
			return false;
	}

	if (!AllowDeath)
	{
		if (!IsPlayerAlive(Client))
			return false;
	}	
	return true;
}



bool IsTeamImmobilised() {
	//Check if there is still an upright survivor
	bool bIsTeamImmobilised = true;
	for (int client = 1; client < MaxClients; client++) {
		// If a survivor is found to be alive and neither pinned nor incapacitated
		// team is not immobilised.
		if (Survivor(client) && IsPlayerAlive(client) ) 
		{		
			if (!Incapacitated(client) ) 
			{		
				bIsTeamImmobilised = false;				
			} 
		}
	}
	return bIsTeamImmobilised;
}
stock bool Survivor(int i)
{
    return i > 0 && i <= MaxClients && IsClientInGame(i) && GetClientTeam(i) == 2;
}
stock bool Incapacitated(int client)
{
    bool bIsIncapped = false;
    if (Survivor(client)) 
	{
		if (GetEntProp(client, Prop_Send, "m_isIncapacitated") > 0) bIsIncapped = true;
		if (!IsPlayerAlive(client)) bIsIncapped = true;
	}
    return bIsIncapped;
}

stock int getBotLimit()
{
	return FindConVar("survivor_limit").IntValue;
}
