#pragma semicolon 1
#pragma newdecls required

// 头文件
#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#include <treeutil>

#define CVAR_FLAG FCVAR_NOTIFY

public Plugin myinfo = 
{
	name 			= "L4d2-Si-Push-When-Spawn",
	author 			= "夜羽真白",
	description 	= "感染者生成时进行推动",
	version 		= "1.0.1.0",
	url 			= "https://steamcommunity.com/id/saku_ra/"
}

ConVar
	g_hAllowPushWhenSpawn,
	g_hAllowPushInfected,
	g_hAllowPlayer,
	g_hPushForce,
	g_hOnlyHighPush,
	g_hPosHeight;
bool
	g_bAllowInfected[9] = { false },
	g_bHasBeenPushed[MAXPLAYERS + 1] = { false };
	
public void OnPluginStart()
{
	g_hAllowPushWhenSpawn = CreateConVar("l4d2_si_push_enable", "1", "是否开启特感刷出时向着生还方向推动效果", CVAR_FLAG, true, 0.0, true, 1.0);
	g_hAllowPushInfected = CreateConVar("l4d2_si_push_infected", "2,4,5,6", "哪些种类的特感允许刷出时推动", CVAR_FLAG);
	g_hAllowPlayer = CreateConVar("l4d2_si_push_allow_player", "0", "是否允许玩家特感刷出时进行推动", CVAR_FLAG, true, 0.0, true, 1.0);
	g_hPushForce = CreateConVar("l4d2_si_push_force", "600", "特感刷出时的推动力度", CVAR_FLAG, true, 0.0);
	g_hOnlyHighPush = CreateConVar("l4d2_si_push_only_high", "0", "是否开启只有在高处刷出的特感才允许推动", CVAR_FLAG, true, 0.0, true, 1.0);
	g_hPosHeight = CreateConVar("l4d2_si_push_height", "200", "特感在高于目标生还者这么高的地方刷出被认为是高处", CVAR_FLAG, true, 0.0);
	// HookEvent
	HookEvent("player_spawn", playerSpawnHandler);
	// HookConVarChange
	g_hAllowPushInfected.AddChangeHook(allowPushInfectedChanged);
	// GetAllowedInfected
	GetAllowedInfected();
}
public void allowPushInfectedChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetAllowedInfected();
}

public void playerSpawnHandler(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_hAllowPushWhenSpawn.BoolValue) { return; }
	static int client, infectedType, target;
	client = GetClientOfUserId(event.GetInt("userid"));
	if (!IsValidInfected(client) || !IsPlayerAlive(client) || GetEntProp(client, Prop_Send, "m_isGhost") == 1) { return; }
	if (!g_hAllowPlayer.BoolValue && !IsFakeClient(client)) { return; }
	g_bHasBeenPushed[client] = false;
	infectedType = GetEntProp(client, Prop_Send, "m_zombieClass");
	if (!g_bAllowInfected[infectedType]) { return; }
	static float selfPos[3], targetPos[3];
	target = getClosestSurvivor(client);
	if (!IsValidSurvivor(target) || !IsPlayerAlive(target)) { return; }
	GetClientAbsOrigin(client, selfPos);
	GetClientAbsOrigin(target, targetPos);
	if (g_hOnlyHighPush.BoolValue && (selfPos[2] - targetPos[2] <= g_hPosHeight.FloatValue)) { return; }
	// 未开启高处推动或开启了高处推动 z 高度大于限制高度，下一帧进行推动
	DataPack pack = new DataPack();
	pack.WriteCell(client);
	pack.WriteCell(target);
	if (!g_bHasBeenPushed[client])
	{
		RequestFrame(nextFramePushToSurvivorHandler, pack);
		g_bHasBeenPushed[client] = true;
	}
}
public void nextFramePushToSurvivorHandler(DataPack pack)
{
	if (pack == null) { return; }
	pack.Reset();
	static int client, target;
	client = pack.ReadCell();
	target = pack.ReadCell();
	delete pack;
	if (!IsValidInfected(client) || !IsPlayerAlive(client) || !IsValidSurvivor(target) || !IsPlayerAlive(target)) { return; }
	static float selfPos[3], targetPos[3], eyeAngle[3], resultPos[3];
	GetClientAbsOrigin(client, selfPos);
	GetClientAbsOrigin(target, targetPos);
	SubtractVectors(targetPos, selfPos, resultPos);
	// 获取 eyeAngle
	GetVectorAngles(resultPos, eyeAngle);
	NormalizeVector(resultPos, resultPos);
	ScaleVector(resultPos, g_hPushForce.FloatValue);
	resultPos[2] = 300.0;
	TeleportEntity(client, NULL_VECTOR, eyeAngle, resultPos);
}

void GetAllowedInfected()
{
	char cvarString[32] = {'\0'}, resultString[6][4];
	g_hAllowPushInfected.GetString(cvarString, sizeof(cvarString));
	ExplodeString(cvarString, ",", resultString, 6, 4);
	for (int i = 0; i < ZC_CHARGER; i++)
	{
		if (strcmp(resultString[i], NULL_STRING) != 0) { g_bAllowInfected[StringToInt(resultString[i])] = true; }
		else { continue; }
	}
}

int getClosestSurvivor(int client)
{
	if (!IsValidClient(client)) { return -1; }
	static float selfPos[3], targetPos[3];
	static int i, target;
	static ArrayList distList;
	distList = new ArrayList(2);
	GetClientAbsOrigin(client, selfPos);
	for (i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i) || GetClientTeam(i) != TEAM_SURVIVOR) { continue; }
		GetClientAbsOrigin(i, targetPos);
		distList.Set(distList.Push(GetVectorDistance(selfPos, targetPos)), i, 1);
	}
	if (distList.Length > 0)
	{
		distList.Sort(Sort_Ascending, Sort_Float);
		target = distList.Get(0, 1);
	}
	delete distList;
	return target;
}