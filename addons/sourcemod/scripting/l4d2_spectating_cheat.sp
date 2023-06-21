#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>

#define ENTITY_SAFE_LIMIT 2000 //don't create model glow when entity index is above this
#define ZC_SMOKER		1
#define ZC_BOOMER		2
#define ZC_HUNTER		3
#define ZC_SPITTER		4
#define ZC_JOCKEY		5
#define ZC_CHARGER		6

bool g_bLateLoad;
int ZC_TANK;
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) 
{
	EngineVersion test = GetEngineVersion();
	
	if( test != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}
	
	ZC_TANK = 8;
	g_bLateLoad = late;
	return APLRes_Success; 
}

ConVar g_hCvarColorGhost, g_hCvarColorAlive, g_hCommandAccess, g_hDefaultValue;

int g_iCvarColorGhost, g_iCvarColorAlive;
bool g_bDefaultValue;

char g_sCommandAccesslvl[16];

bool g_bMapStarted;
static bool g_bSpecCheatActive[MAXPLAYERS + 1]; //spectatpr open watch
int g_iModelIndex[MAXPLAYERS+1];			// Player Model entity reference
Handle DelayWatchGlow_Timer[MAXPLAYERS+1] ; //prepare to disable player spec glow
int g_iRoundStart, g_iPlayerSpawn;

public Plugin myinfo = 
{
    name = "l4d2 specating cheat",
    author = "Harry Potter",
    description = "A spectator who watching the survivor at first person view would see the infected model glows though the wall",
    version = "2.8-2023/6/19",
    url = "https://steamcommunity.com/profiles/76561198026784913"
}

public void OnPluginStart()
{
	g_hCvarColorGhost =	CreateConVar(	"l4d2_specting_cheat_ghost_color",		"255 255 255",		"灵魂状态特感颜色 RGB值", FCVAR_NOTIFY);
	g_hCvarColorAlive =	CreateConVar(	"l4d2_specting_cheat_alive_color",		"255 0 0",			"实体状态特感颜色 RGB值", FCVAR_NOTIFY);
	g_hCommandAccess = 	CreateConVar(	"l4d2_specting_cheat_use_command_flag", "0", 				"变更指令需要的级别(无内容=所有人,-1:，没有人)", FCVAR_NOTIFY);
	g_hDefaultValue = 	CreateConVar(	"l4d2_specting_cheat_default_value", 	"1", 				"是否默认启用插件效果[1-启用/0-关闭]", FCVAR_NOTIFY, true, 0.0, true, 1.0);

	GetCvars();
	g_hCvarColorGhost.AddChangeHook(ConVarChanged_Glow_Ghost);
	g_hCvarColorAlive.AddChangeHook(ConVarChanged_Glow_Alive);
	g_hCommandAccess.AddChangeHook(ConVarChanged_Access);
	g_hDefaultValue.AddChangeHook(ConVarChanged_Cvars);

	//Autoconfig for plugin
	AutoExecConfig(true, "l4d2_specting_cheat");

	HookEvent("round_start",            Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_spawn", 			Event_PlayerSpawn);
	HookEvent("round_end",				Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("map_transition", 		Event_RoundEnd, EventHookMode_PostNoCopy); //戰役模式下過關到下一關的時候 (沒有觸發round_end)
	HookEvent("mission_lost", 			Event_RoundEnd, EventHookMode_PostNoCopy); //戰役模式下滅團重來該關卡的時候 (之後有觸發round_end)
	HookEvent("finale_vehicle_leaving", Event_RoundEnd, EventHookMode_PostNoCopy); //救援載具離開之時  (沒有觸發round_end)
	HookEvent("tank_spawn", Event_TankSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_team",	Event_PlayerTeam);

	HookEvent("player_disconnect", Event_PlayerDisconnect);
	HookEvent("tank_frustrated", OnTankFrustrated, EventHookMode_Post);
	
	RegConsoleCmd("sm_speccheat", ToggleSpecCheatCmd, "Toggle Speatator watching cheat");
	RegConsoleCmd("sm_watchcheat", ToggleSpecCheatCmd, "Toggle Speatator watching cheat");
	RegConsoleCmd("sm_lookcheat", ToggleSpecCheatCmd, "Toggle Speatator watching cheat");
	RegConsoleCmd("sm_seecheat", ToggleSpecCheatCmd, "Toggle Speatator watching cheat");
	RegConsoleCmd("sm_meetcheat", ToggleSpecCheatCmd, "Toggle Speatator watching cheat");
	RegConsoleCmd("sm_starecheat", ToggleSpecCheatCmd, "Toggle Speatator watching cheat");
	RegConsoleCmd("sm_hellocheat", ToggleSpecCheatCmd, "Toggle Speatator watching cheat");
	RegConsoleCmd("sm_areyoucheat", ToggleSpecCheatCmd, "Toggle Speatator watching cheat");
	RegConsoleCmd("sm_fuckyoucheat", ToggleSpecCheatCmd, "Toggle Speatator watching cheat");
	RegConsoleCmd("sm_zzz", ToggleSpecCheatCmd, "Toggle Speatator watching cheat");

	for(int i = 1; i <= MaxClients; i++)
	{
		g_bSpecCheatActive[i] = g_bDefaultValue;
	}
	
	if(g_bLateLoad)
	{
		g_bMapStarted = true;
		CreateAllModelGlow();
	}
}

public void OnPluginEnd() //unload插件的時候
{
	RemoveAllModelGlow();
	ResetTimer();
	ClearDefault();
}

public void OnMapStart()
{
	g_bMapStarted = true;
}

public void OnMapEnd()
{
	g_bMapStarted = false;
	ResetTimer();
	ClearDefault();
}

public void OnClientDisconnect(int client)
{
	RemoveInfectedModelGlow(client);

	delete DelayWatchGlow_Timer[client];
} 

Action ToggleSpecCheatCmd(int client, int args) 
{
	if(client == 0 || GetClientTeam(client)!= L4D_TEAM_SPECTATOR)
		return Plugin_Handled;
	
	if(HasAccess(client, g_sCommandAccesslvl))
	{
		if(g_bSpecCheatActive[client])
		{
			g_bSpecCheatActive[client] = false;
			PrintToChat(client, "\x01[\x04WatchMode\x01]\x03旁观透视系统\x01已\x05关闭\x01.");
			StopAllModelGlow();
			delete DelayWatchGlow_Timer[client];
			DelayWatchGlow_Timer[client] = CreateTimer(0.1, Timer_StopGlowTransmit, client);

			delete DelayWatchGlow_Timer[0];
			DelayWatchGlow_Timer[0] = CreateTimer(0.2, Timer_StartAllGlow);
		}
		else
		{
			g_bSpecCheatActive[client] = true;
			PrintToChat(client, "\x01[\x04WatchMode\x01]\x03旁观透视系统\x01已\x05启动\x01.");
		}
	}
	else
	{
		PrintToChat(client, "\x01[\x04WatchMode\x01]\x03你没有权限使用这个指令");
	}

	return Plugin_Handled;
}

Action Timer_StopGlowTransmit(Handle timer, int client)
{
	DelayWatchGlow_Timer[client] = null;
	return Plugin_Continue;
}

Action Timer_StartAllGlow(Handle timer)
{
	StartAllModelGlow();

	DelayWatchGlow_Timer[0] = null;
	return Plugin_Continue;
}

void Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	g_bSpecCheatActive[client] = g_bDefaultValue;
}

//Tank玩家失去控制權，換人或變成AI
//有插件會將Tank失去控制權時不會換人重新獲得100%控制權，譬如zonemod second pass
void OnTankFrustrated(Event event, const char[] name, bool dontBroadcast)
{
	int userid = event.GetInt("userid");
	RemoveInfectedModelGlow(GetClientOfUserId(userid));
	RequestFrame(OnNextFrame, userid);
}

public void L4D_OnEnterGhostState(int client)
{
	RequestFrame(OnNextFrame, GetClientUserId(client));
}

//有插件在此事件把Tank變成靈魂克的時候不會觸發後續的player_spawn事件，譬如使用confoglcompmod
void Event_TankSpawn(Event event, const char[] name, bool dontBroadcast)
{ 
	int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);
	
	RemoveInfectedModelGlow(client);
	RequestFrame(OnNextFrame, userid);
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast) 
{
	if( g_iPlayerSpawn == 1 && g_iRoundStart == 0 )
		CreateTimer(1.2, Timer_PluginStart, _, TIMER_FLAG_NO_MAPCHANGE);
	g_iRoundStart = 1;
}

Action Timer_PluginStart(Handle timer)
{
	ClearDefault();

	RemoveAllModelGlow();
	CreateAllModelGlow();

	return Plugin_Continue;
}

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{ 
	if( g_iPlayerSpawn == 0 && g_iRoundStart == 1 )
		CreateTimer(1.2, Timer_PluginStart, _, TIMER_FLAG_NO_MAPCHANGE);
	g_iPlayerSpawn = 1;	

	int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);

	RemoveInfectedModelGlow(client); //有可能特感變成坦克復活
	RequestFrame(OnNextFrame, userid);
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{ 
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	RemoveInfectedModelGlow(client);
}

void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int oldteam = event.GetInt("oldteam");
	
	RemoveInfectedModelGlow(client);
	
	if(client && IsClientInGame(client) && !IsFakeClient(client) && oldteam == L4D_TEAM_SPECTATOR && g_bSpecCheatActive[client])
	{
		StopAllModelGlow();
		delete DelayWatchGlow_Timer[client];
		DelayWatchGlow_Timer[client] = CreateTimer(0.1, Timer_StopGlowTransmit, client);

		delete DelayWatchGlow_Timer[0];
		DelayWatchGlow_Timer[0] = CreateTimer(0.2, Timer_StartAllGlow);
	}
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	RemoveAllModelGlow();
	ResetTimer();
	ClearDefault();
}

void OnNextFrame(int userid)
{
	CreateInfectedModelGlow(GetClientOfUserId(userid));
}

void CreateInfectedModelGlow(int client)
{
	if (!client || 
	!IsClientInGame(client) || 
	GetClientTeam(client) != L4D_TEAM_INFECTED || 
	!IsPlayerAlive(client) ||
	g_bMapStarted == false) return;

	if ( IsPlayerGhost(client) && GetZombieClass(client) == ZC_TANK)
	{
		CreateTimer(0.25, Timer_CheckGhostTank, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}

	///////設定發光物件//////////
	// Spawn dynamic prop entity
	int entity = CreateEntityByName("prop_dynamic_ornament");
	
	if (CheckIfEntityMax( entity ) == false)
		return;
		
	// Delete previous glow first just in case
	RemoveInfectedModelGlow(client);
	
	// Get Client Model
	char sModelName[64];
	GetEntPropString(client, Prop_Data, "m_ModelName", sModelName, sizeof(sModelName));
	//PrintToChatAll("%N: %s",client,sModelName);

	// Set new fake model
	//PrecacheModel(sModelName);
	SetEntityModel(entity, sModelName);
	DispatchSpawn(entity);

	// Set outline glow color
	SetEntProp(entity, Prop_Send, "m_CollisionGroup", 0);
	SetEntProp(entity, Prop_Send, "m_nSolidType", 0);
	SetEntProp(entity, Prop_Send, "m_nGlowRange", 4500);
	SetEntProp(entity, Prop_Send, "m_iGlowType", 3);
	if(IsPlayerGhost(client))
		SetEntProp(entity, Prop_Send, "m_glowColorOverride", g_iCvarColorGhost);
	else
		SetEntProp(entity, Prop_Send, "m_glowColorOverride", g_iCvarColorAlive);

	if(DelayWatchGlow_Timer[0] != null)
	{
		AcceptEntityInput(entity, "StopGlowing");
	}
	else
	{
		AcceptEntityInput(entity, "StartGlowing");
	}

	// Set model invisible
	SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
	SetEntityRenderColor(entity, 0, 0, 0, 0);
	
	// Set model attach to client, and always synchronize
	SetVariantString("!activator");
	AcceptEntityInput(entity, "SetParent", client);
	SetVariantString("!activator");
	AcceptEntityInput(entity, "SetAttached", client);
	///////發光物件完成//////////
	
	g_iModelIndex[client] = EntIndexToEntRef(entity);
		
	//model 只能給誰看?
	SDKHook(entity, SDKHook_SetTransmit, Hook_SetTransmit);
}

void RemoveInfectedModelGlow(int client)
{
	int entity = g_iModelIndex[client];
	g_iModelIndex[client] = 0;

	if( IsValidEntRef(entity) )
		AcceptEntityInput(entity, "kill");
}

Action Hook_SetTransmit(int entity, int client)
{
	if(DelayWatchGlow_Timer[client] != null) return Plugin_Continue;

	if( g_bSpecCheatActive[client] && GetClientTeam(client) == L4D_TEAM_SPECTATOR)
	{
	 	return Plugin_Continue;
	}
	
	return Plugin_Handled;
}

int GetColor(char[] sTemp)
{
	if( StrEqual(sTemp, "") )
		return 0;

	char sColors[3][4];
	int color = ExplodeString(sTemp, " ", sColors, 3, 4);

	if( color != 3 )
		return 0;

	color = StringToInt(sColors[0]);
	color += 256 * StringToInt(sColors[1]);
	color += 65536 * StringToInt(sColors[2]);

	return color;
}

void ConVarChanged_Glow_Ghost(Handle convar, const char[] oldValue, const char[] newValue) {
	GetCvars();

	int entity;
	for(int i=1; i<=MaxClients ; ++i)
	{
		if(IsClientInGame(i) && GetClientTeam(i)==L4D_TEAM_INFECTED && IsPlayerGhost(i))
		{
			entity = g_iModelIndex[i];
			if( entity && (entity = EntRefToEntIndex(entity)) != INVALID_ENT_REFERENCE )
			{
				SetEntProp(entity, Prop_Send, "m_iGlowType", 3);
				SetEntProp(entity, Prop_Send, "m_glowColorOverride", g_iCvarColorGhost);
			}
		}
	}
}

void ConVarChanged_Glow_Alive(Handle convar, const char[] oldValue, const char[] newValue) {
	GetCvars();
	
	int entity;
	for(int i=1; i<=MaxClients ; ++i)
	{
		if(IsClientInGame(i) && GetClientTeam(i)==L4D_TEAM_INFECTED && IsPlayerAlive(i) && !IsPlayerGhost(i))
		{
			entity = g_iModelIndex[i];
			if( entity && (entity = EntRefToEntIndex(entity)) != INVALID_ENT_REFERENCE )
			{
				SetEntProp(entity, Prop_Send, "m_iGlowType", 3);
				SetEntProp(entity, Prop_Send, "m_glowColorOverride", g_iCvarColorAlive);
			}
		}
	}
}

void ConVarChanged_Access(Handle convar, const char[] oldValue, const char[] newValue) {
	GetCvars();

	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			if(HasAccess(i, g_sCommandAccesslvl) == false) g_bSpecCheatActive[i] = false;
			
			
			RemoveAllModelGlow();
			CreateAllModelGlow();
		}
	}
}

void ConVarChanged_Cvars(Handle convar, const char[] oldValue, const char[] newValue) {
	GetCvars();
}

void GetCvars()
{
	char sColor[16],sColor2[16];
	g_hCvarColorGhost.GetString(sColor, sizeof(sColor));
	g_iCvarColorGhost = GetColor(sColor);
	g_hCvarColorAlive.GetString(sColor2, sizeof(sColor2));
	g_iCvarColorAlive = GetColor(sColor2);
	g_hCommandAccess.GetString(g_sCommandAccesslvl,sizeof(g_sCommandAccesslvl));
	g_bDefaultValue = g_hDefaultValue.BoolValue;
}

bool IsPlayerGhost(int client)
{
	return view_as<bool>(GetEntProp(client, Prop_Send, "m_isGhost"));
}

bool IsValidEntRef(int entity)
{
	if( entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE)
		return true;
	return false;
}

void RemoveAllModelGlow()
{
	for (int i = 1; i <= MaxClients; i++) 
	{
		RemoveInfectedModelGlow(i);
	}
}

void CreateAllModelGlow()
{
	if (g_bMapStarted == false) return;
	
	for (int client = 1; client <= MaxClients; client++) 
	{
		if(!IsClientInGame(client)) continue;

		RequestFrame(OnNextFrame, GetClientUserId(client));
	}
}

Action Timer_CheckGhostTank(Handle timer, int userid)
{
	int tank = GetClientOfUserId(userid);
	
	CreateInfectedModelGlow(tank);

	return Plugin_Continue;
}

void StopAllModelGlow()
{
	int glow;
	for (int i = 1; i <= MaxClients; i++) 
	{
		glow = g_iModelIndex[i];
		if( IsValidEntRef(glow) )
		{
			AcceptEntityInput(glow, "StopGlowing");
		}
	}
}

void StartAllModelGlow()
{
	int glow;
	for (int i = 1; i <= MaxClients; i++) 
	{
		glow = g_iModelIndex[i];
		if( IsValidEntRef(glow) )
		{
			AcceptEntityInput(glow, "StartGlowing");
		}
	}
}

bool CheckIfEntityMax(int entity)
{
	if(entity == -1) return false;

	if(	entity > ENTITY_SAFE_LIMIT)
	{
		AcceptEntityInput(entity, "Kill");
		return false;
	}
	return true;
}

bool HasAccess(int client, char[] g_sAcclvl)
{
	// no permissions set
	if (strlen(g_sAcclvl) == 0)
		return true;

	else if (StrEqual(g_sAcclvl, "-1"))
		return false;

	// check permissions
	int userFlags = GetUserFlagBits(client);
	if ( (userFlags & ReadFlagString(g_sAcclvl)) || (userFlags & ADMFLAG_ROOT))
	{
		return true;
	}

	return false;
}

int GetZombieClass(int client) 
{
	return GetEntProp(client, Prop_Send, "m_zombieClass");
}

void ResetTimer()
{
	for (int i = 0; i <= MaxClients; i++)
	{
		delete DelayWatchGlow_Timer[i];
	}
}

void ClearDefault()
{
	g_iRoundStart = 0;
	g_iPlayerSpawn = 0;
}

//-------------------------------Other API Forward-------------------------------

// https://github.com/fbef0102/Game-Private_Plugin/tree/main/Plugin_%E6%8F%92%E4%BB%B6/Versus_%E5%B0%8D%E6%8A%97%E6%A8%A1%E5%BC%8F/l4d_zcs
// from l4d_zcs.smx by Harry, player can change Zombie Class during ghost state
public void L4D2_OnClientChangeZombieClass(int client, int new_zombieclass)
{
	RequestFrame(OnNextFrame, GetClientUserId(client));
}