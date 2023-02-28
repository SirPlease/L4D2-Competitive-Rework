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

ConVar g_hCvarColorGhost, g_hCvarColorAlive;

int g_iCvarColorGhost, g_iCvarColorAlive;
bool g_bMapStarted;
int g_iModelIndex[MAXPLAYERS+1];			// Player Model entity reference

public Plugin myinfo = 
{
    name = "l4d2 specating cheat",
    author = "Harry Potter",
    description = "A spectator who watching the survivor at first person view would see the infected model glows though the wall",
    version = "2.6",
    url = "https://steamcommunity.com/profiles/76561198026784913"
}

public void OnPluginStart()
{
	g_hCvarColorGhost =	CreateConVar(	"l4d2_specting_cheat_ghost_color",		"255 255 255",		"Ghost SI glow color, Three values between 0-255 separated by spaces. RGB Color255 - Red Green Blue.", FCVAR_NOTIFY);
	g_hCvarColorAlive =	CreateConVar(	"l4d2_specting_cheat_alive_color",		"255 0 0",			"Alive SI glow color, Three values between 0-255 separated by spaces. RGB Color255 - Red Green Blue.", FCVAR_NOTIFY);

	GetCvars();

	g_hCvarColorGhost.AddChangeHook(ConVarChanged_Glow_Ghost);
	g_hCvarColorAlive.AddChangeHook(ConVarChanged_Glow_Alive);

	HookEvent("tank_spawn", Event_TankSpawn);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_team",	Event_PlayerTeam);
	HookEvent("round_end",			Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("map_transition", Event_RoundEnd, EventHookMode_PostNoCopy); //戰役模式下過關到下一關的時候 (沒有觸發round_end)
	HookEvent("mission_lost", Event_RoundEnd, EventHookMode_PostNoCopy); //戰役模式下滅團重來該關卡的時候 (之後有觸發round_end)
	HookEvent("finale_vehicle_leaving", Event_RoundEnd, EventHookMode_PostNoCopy); //救援載具離開之時  (沒有觸發round_end)
	
	HookEvent("tank_frustrated", OnTankFrustrated, EventHookMode_Post);
	
	if(g_bLateLoad)
	{
		g_bMapStarted = true;
		CreateAllModelGlow();
	}
}

public void OnPluginEnd() //unload插件的時候
{
	RemoveAllModelGlow();
}

public void OnMapStart()
{
	g_bMapStarted = true;
}

public void OnMapEnd()
{
	g_bMapStarted = false;
}

public void OnClientDisconnect(int client)
{
    RemoveInfectedModelGlow(client);
} 

void OnTankFrustrated(Event event, const char[] name, bool dontBroadcast)
{
	RemoveInfectedModelGlow(GetClientOfUserId(event.GetInt("userid"))); //Tank玩家變成AI
}

public void L4D_OnEnterGhostState(int client)
{
	RequestFrame(OnNextFrame, GetClientUserId(client));
}

//有插件在此事件把Tank變成靈魂克的時候不會觸發後續的player_spawn事件，譬如使用confoglcompmod
public void Event_TankSpawn(Event event, const char[] name, bool dontBroadcast)
{ 
	int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);
	
	RemoveInfectedModelGlow(client);
	RequestFrame(OnNextFrame, userid);
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{ 
	int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);
	
	RemoveInfectedModelGlow(client); //有可能特感變成坦克復活
	RequestFrame(OnNextFrame, userid);
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{ 
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	RemoveInfectedModelGlow(client);
}

public void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int oldteam = event.GetInt("oldteam");
	
	RemoveInfectedModelGlow(client);
	
	if(client && IsClientInGame(client) && !IsFakeClient(client) && oldteam == L4D_TEAM_SPECTATOR)
	{
		RemoveAllModelGlow();
		CreateAllModelGlow();
	}
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	RemoveAllModelGlow();
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
	AcceptEntityInput(entity, "StartGlowing");

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

public Action Hook_SetTransmit(int entity, int client)
{
	if(GetClientTeam(client) == L4D_TEAM_SPECTATOR)
		return Plugin_Continue;
	
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

public void ConVarChanged_Glow_Ghost(Handle convar, const char[] oldValue, const char[] newValue) {
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

public void ConVarChanged_Glow_Alive(Handle convar, const char[] oldValue, const char[] newValue) {
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

void GetCvars()
{
	char sColor[16],sColor2[16];
	g_hCvarColorGhost.GetString(sColor, sizeof(sColor));
	g_iCvarColorGhost = GetColor(sColor);
	g_hCvarColorAlive.GetString(sColor2, sizeof(sColor2));
	g_iCvarColorAlive = GetColor(sColor2);
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

void OnNextFrame(int userid)
{
	CreateInfectedModelGlow(GetClientOfUserId(userid));
}

Action Timer_CheckGhostTank(Handle timer, int userid)
{
	int tank = GetClientOfUserId(userid);
	
	CreateInfectedModelGlow(tank);

	return Plugin_Continue;
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

int GetZombieClass(int client) 
{
	return GetEntProp(client, Prop_Send, "m_zombieClass");
}

// from l4d_zcs.smx by Harry, player can change Zombie Class during ghost state
public void L4D2_OnClientChangeZombieClass(int client, int new_zombieclass)
{
	RequestFrame(OnNextFrame, GetClientUserId(client));
}