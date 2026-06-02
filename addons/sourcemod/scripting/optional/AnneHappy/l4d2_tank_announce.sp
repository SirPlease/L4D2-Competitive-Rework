#pragma semicolon 1
#pragma newdecls required

// 头文件
#include <sourcemod>
#include <sdktools>
#include <colors>

#define SOUNDEFFECT "ui/pickup_secret01.wav"

// ConVar
ConVar g_hPlaySound, g_hMessageType;
// Ints
int g_iPlaySound, g_iMessageType;
// Chars
char sTankName[MAX_NAME_LENGTH];

public Plugin myinfo = 
{
	name 			= "Tank刷新提示",
	author 			= "夜羽真白",
	description 	= "当Tank生成时，进行提示",
	version 		= "1.0.1.0",
	url 			= "https://steamcommunity.com/id/saku_ra/"
}

public void OnPluginStart()
{
	// CreateConVar
	g_hPlaySound = CreateConVar("l4d2_tankannounce_playsound", "1", "是否在Tank生成时播放声音", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hMessageType = CreateConVar("l4d2_tankannounce_messagetype", "1", "Tank生成提示的类型：0=不提示，1=聊天框提示，2=中央提示框提示，3=中央文字提示", FCVAR_NOTIFY, true, 0.0, true, 3.0);
	// HookEvent
	HookEvent("player_spawn", evt_PlayerSpawn);
	// AddChangeHook
	g_hPlaySound.AddChangeHook(ConVarChanged_Cvars);
	g_hMessageType.AddChangeHook(ConVarChanged_Cvars);
	// GetValue
	g_iPlaySound = g_hPlaySound.IntValue;
	g_iMessageType = g_hMessageType.IntValue;
}

public void OnMapStart()
{
	PrecacheSound(SOUNDEFFECT, false);
}

public void evt_PlayerSpawn(Event event, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	char sGameMod[32];	GetConVarString(FindConVar("mp_gamemode"), sGameMod, sizeof(sGameMod));
	// 判断是否玩家Tank
	if (IsAiTank(client))
	{
		switch (g_iMessageType)
		{
			case 1:
			{
				// 非对抗模式下无法使用红色
				if (StrEqual(sGameMod, "versus", false))
				{
					CPrintToChatAll("{default}[{red}!{default}] {green}Tank {default}({red}控制者：%s{default}) 已经生成！", sTankName);
				}
				else
				{
					CPrintToChatAll("{default}[{blue}!{default}] {green}Tank {default}({blue}控制者：%s{default}) 已经生成！", sTankName);
				}
			}
			case 2:
			{
				PrintHintTextToAll("[Tank] 控制者：%s 已经生成！", sTankName);
			}
			case 3:
			{
				PrintCenterTextAll("[Tank] 控制者：%N 已经生成！", sTankName);
			}
		}
		if (g_iPlaySound == 1)
		{
			EmitSoundToAll(SOUNDEFFECT); // Selected Sound
		}
	}
}

bool IsAiTank(int tank)
{
	// 是否玩家Tank
	if (!IsFakeClient(tank) && IsClientInGame(tank) && GetClientTeam(tank) == 3 && GetEntProp(tank, Prop_Send, "m_zombieClass") == 8)
	{
		FormatEx(sTankName, sizeof(sTankName), "(玩家) %N", tank);
		return true;
	}
	else if (tank != 0 && GetClientTeam(tank) == 3 && GetEntProp(tank, Prop_Send, "m_zombieClass") == 8)
	{
		FormatEx(sTankName, sizeof(sTankName), "(AI) %N", tank);
		return true;
	}
	return false;
}

void ConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iPlaySound = g_hPlaySound.IntValue;
	g_iMessageType = g_hMessageType.IntValue;
}

public void OnPluginEnd()
{
	UnhookEvent("player_spawn", evt_PlayerSpawn);
}