#pragma semicolon 1
//強制1.7以後的新語法
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

char clientName[32];

int l4d2_dooropen_kick[MAXPLAYERS+1];

ConVar EnableHandle_a, EnableHandle_b, EnableHandle_c, EnableHandle_d, EnableHandle_e, EnableHandle_f;

int g_EnableHandle_a, g_EnableHandle_b, g_EnableHandle_c, g_EnableHandle_e;

float g_EnableHandle_d, g_EnableHandle_f;

float g_fDoorDelayTimes[MAXPLAYERS + 1];

public void OnPluginStart()
{
	EnableHandle_a	= CreateConVar("l4d2_enabled_safeRoomDoor_a", "1", "启用幸存者开关安全门提示+开关安全门次数限制? 0=禁用, 1=启用, 2=禁用限制,只显示幸存者开关安全门.", FCVAR_NOTIFY);
	EnableHandle_b	= CreateConVar("l4d2_enabled_safeRoomDoor_b", "1", "设置玩门超过次数后的处理方式. 1=处死, 2=踢出, 3=封禁(由于盗版没有唯一的64位ID所以使用永久封禁是无效的).", FCVAR_NOTIFY);
	EnableHandle_c	= CreateConVar("l4d2_enabled_safeRoomDoor_c", "5", "设置玩门达到次数的封禁时间/分钟. 0=永久封禁(删除文件  banned_user.cfg  里的对应玩家ID然后重启服务器即可解封).", FCVAR_NOTIFY);
	EnableHandle_d	= CreateConVar("l4d2_enabled_safeRoomDoor_d", "1", "设置开局时延迟多久提示玩门的后果(秒).(必须大于1)", FCVAR_NOTIFY);
	EnableHandle_e	= CreateConVar("l4d2_enabled_safeRoomDoor_e", "5", "设置每个章节幸存者开关安全门的次数.", FCVAR_NOTIFY);
	EnableHandle_f	= CreateConVar("l4d2_enabled_safeRoomDoor_f", "2.0", "设置每次开关安全门后的冷却时间(秒).", FCVAR_NOTIFY);
	
	EnableHandle_a.AddChangeHook(CVARDoorChanged);
	EnableHandle_b.AddChangeHook(CVARDoorChanged);
	EnableHandle_c.AddChangeHook(CVARDoorChanged);
	EnableHandle_d.AddChangeHook(CVARDoorChanged);
	EnableHandle_e.AddChangeHook(CVARDoorChanged);
	EnableHandle_f.AddChangeHook(CVARDoorChanged);
	
	HookEvent("round_end", Event_RoundEnd);//回合结束.
	HookEvent("door_open", Event_DoorOpen);//打开安全门.
	HookEvent("door_close", Event_DoorClose);//关上安全门.
	
	HookEvent("door_open", Event_DoorAction, EventHookMode_Pre);
	HookEvent("door_close", Event_DoorAction, EventHookMode_Pre);
	
	AddCommandListener(DoorIntercept, "choose_opendoor");
	AddCommandListener(DoorIntercept, "choose_closedoor");
	
	AutoExecConfig(true, "l4d2_saferoomdoor");//生成指定文件名的CFG.
}

public void OnMapStart()
{
	l4d2_DoorGetCvars();
}

public void CVARDoorChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	l4d2_DoorGetCvars();
}

void l4d2_DoorGetCvars()
{
	g_EnableHandle_a = EnableHandle_a.IntValue;
	g_EnableHandle_b = EnableHandle_b.IntValue;
	g_EnableHandle_c = EnableHandle_c.IntValue;
	g_EnableHandle_d = EnableHandle_d.FloatValue;
	g_EnableHandle_e = EnableHandle_e.IntValue;
	g_EnableHandle_f = EnableHandle_f.FloatValue;
}

public Action DoorIntercept(int client, const char[] command, int args)
{
	if(client == 0 || !IsClientInGame(client) || IsFakeClient(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client))
		return Plugin_Continue;
	
	if(GetEngineTime() - g_fDoorDelayTimes[client] < g_EnableHandle_f)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;	
}

public void Event_DoorAction(Event event, const char[] name, bool dontBroadcast)
{
	if(!event.GetBool("checkpoint"))
		return;

	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client <= 0 || client > MaxClients || !IsClientInGame(client) || IsFakeClient(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client))
		return;

	if(GetEngineTime() - g_fDoorDelayTimes[client] >= g_EnableHandle_f)
		g_fDoorDelayTimes[client] = GetEngineTime();
}

//玩家连接成功.
public void OnClientPostAdminCheck(int client)
{
	if(IsFakeClient(client))
		return;
		
	if(g_EnableHandle_a == 0)
		return;
		
	if(g_EnableHandle_a == 1)
	{
		l4d2_dooropen_kick[client] = 0;//开局时重置幸存者开关安全门次数.
		CreateTimer(g_EnableHandle_d, l4d2_EnableHandle, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);//显示玩门的处罚方式.
	}
}

//回合结束.
public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if(g_EnableHandle_a == 0)
		return;
	
	if(g_EnableHandle_a == 1)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && !IsFakeClient(i))
			{
				l4d2_dooropen_kick[i] = 0;
			}
		}
	}
}

public Action l4d2_EnableHandle(Handle timer, any client) 
{
	if ((client = GetClientOfUserId(client)) && IsClientInGame(client) && !IsFakeClient(client))
	{
		if (GetClientTeam(client) == 3)
			return Plugin_Continue;
		
		switch(g_EnableHandle_b)
		{
			case 1:
			{
				PrintToChat(client, "\x04[提示]\x05玩门达到\x03%d\x05次将被处死.", g_EnableHandle_e);//聊天窗提示.
			}
			case 2:
			{
				PrintToChat(client, "\x04[提示]\x05玩门达到\x03%d\x05次将被踢出.", g_EnableHandle_e);//聊天窗提示.
			}
			case 3:
			{
				if (g_EnableHandle_c <= 0)
					PrintToChat(client, "\x04[提示]\x05玩门达到\x03%d\x05次将被永久封禁.", g_EnableHandle_e);//聊天窗提示.
				else
					PrintToChat(client, "\x04[提示]\x05玩门达到\x03%d\x05次将被封禁\x03%d\x05分钟.", g_EnableHandle_e, g_EnableHandle_c);//聊天窗提示.
			}
		}
	}
	return Plugin_Continue;
}

//打开安全门.
public void Event_DoorOpen(Event event, const char[] name, bool dontBroadcast)
{
	if(g_EnableHandle_a == 0)
		return;
	
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if(IsValidClient(client))
	{
		GetTrueName(client, clientName);
		if (GetEventBool(event, "checkpoint"))
		{
			if(IsFakeClient(client))
			{
				PrintToChatAll("\x04[提示]\x03%s\x05打开了安全门.", clientName);//聊天窗提示.
			}
			else
			{
				switch(g_EnableHandle_a)
				{
					case 1:
					{
						l4d2_dooropen_kick[client]++;
						if (l4d2_dooropen_kick[client] > g_EnableHandle_e)
						{
							switch(g_EnableHandle_b)
							{
								case 1:
								{
									ForcePlayerSuicide(client);
									PrintToChatAll("\x04[提示]\x03%s\x05玩门达到限制\x03%d\x05次而被处死.", clientName, g_EnableHandle_e);//聊天窗提示.
								}
								case 2:
								{
									KickClient(client, "[提示]服务器自动踢出玩门达到 %d 次的玩家", g_EnableHandle_e);
									PrintToChatAll("\x04[提示]\x03%s\x05玩门达到限制\x03%d\x05次而被踢出.", clientName, g_EnableHandle_e);//聊天窗提示.
								}
								case 3:
								{
									if (g_EnableHandle_c <= 0)
									{
										BanClient(client, g_EnableHandle_c, BANFLAG_AUTO, "", "[提示]服务器自动永久封禁玩门的玩家");
										PrintToChatAll("\x04[提示]\x03%s\x05玩门达到限制\x03%d\x05次而被永久封禁.", clientName, g_EnableHandle_e);//聊天窗提示.
									}
									else
									{
										BanClient(client, g_EnableHandle_c, BANFLAG_AUTO, "", "[提示]服务器自动临时封禁玩门的玩家");
										PrintToChatAll("\x04[提示]\x03%s\x05玩门达到限制\x03%d\x05次而被封禁\x03%d\x05分钟.", clientName, g_EnableHandle_e, g_EnableHandle_c);//聊天窗提示.
									}
								}
							}
							l4d2_dooropen_kick[client] = 0;
						}
						else
							PrintToChatAll("\x04[提示]\x03%s\x05打开了安全门\x04(\x03%d\x05/\x03%d\x04)\x05.", clientName, g_EnableHandle_e - l4d2_dooropen_kick[client], g_EnableHandle_e);//聊天窗提示.
					}
					case 2:
					{
						PrintToChatAll("\x04[提示]\x03%s\x05打开了安全门.", clientName);//聊天窗提示.
					}
				}
			}
		}
	}
}

//关上安全门.
public void Event_DoorClose(Event event, const char[] name, bool dontBroadcast)
{
	if(g_EnableHandle_a == 0)
		return;
	
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if(IsValidClient(client))
	{
		GetTrueName(client, clientName);
		if (GetEventBool(event, "checkpoint"))
		{
			if(IsFakeClient(client))
			{
				PrintToChatAll("\x04[提示]\x03%s\x05关上了安全门.", clientName);//聊天窗提示.
			}
			else
			{
				switch(g_EnableHandle_a)
				{
					case 1:
					{
						l4d2_dooropen_kick[client]++;
						if (l4d2_dooropen_kick[client] > g_EnableHandle_e)
						{
							switch(g_EnableHandle_b)
							{
								case 1:
								{
									ForcePlayerSuicide(client);
									PrintToChatAll("\x04[提示]\x03%s\x05玩门达到限制\x03%d\x05次而被处死.", clientName, g_EnableHandle_e);//聊天窗提示.
								}
								case 2:
								{
									KickClient(client, "[提示]服务器自动踢出玩门达到 %d 次的玩家", g_EnableHandle_e);
									PrintToChatAll("\x04[提示]\x03%s\x05玩门达到限制\x03%d\x05次而被踢出.", clientName, g_EnableHandle_e);//聊天窗提示.
								}
								case 3:
								{
									if (g_EnableHandle_c <= 0)
									{
										BanClient(client, g_EnableHandle_c, BANFLAG_AUTO, "", "[提示]服务器自动永久封禁玩门的玩家");
										PrintToChatAll("\x04[提示]\x03%s\x05玩门达到限制\x03%d\x05次而被永久封禁.", clientName, g_EnableHandle_e);//聊天窗提示.
									}
									else
									{
										BanClient(client, g_EnableHandle_c, BANFLAG_AUTO, "", "[提示]服务器自动临时封禁玩门的玩家");
										PrintToChatAll("\x04[提示]\x03%s\x05玩门达到限制\x03%d\x05次而被封禁\x03%d\x05分钟.", clientName, g_EnableHandle_e, g_EnableHandle_c);//聊天窗提示.
									}
								}
							}
							l4d2_dooropen_kick[client] = 0;
						}
						else
							PrintToChatAll("\x04[提示]\x03%s\x05关上了安全门\x04(\x03%d\x05/\x03%d\x04)\x05.", clientName, g_EnableHandle_e - l4d2_dooropen_kick[client], g_EnableHandle_e);//聊天窗提示.
					}
					case 2:
					{
						PrintToChatAll("\x04[提示]\x03%s\x05关上了安全门.", clientName);//聊天窗提示.
					}
				}
			}
		}
	}
}

bool IsValidClient(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2);
}

void GetTrueName(int bot, char[] savename)
{
	int tbot = IsClientIdle(bot);
	
	if(tbot != 0)
	{
		Format(savename, 32, "★闲置:%N★", tbot);
	}
	else
	{
		GetClientName(bot, savename, 32);
	}
}

int IsClientIdle(int bot)
{
	if(IsClientInGame(bot) && GetClientTeam(bot) == 2 && IsFakeClient(bot))
	{
		char sNetClass[12];
		GetEntityNetClass(bot, sNetClass, sizeof(sNetClass));

		if(strcmp(sNetClass, "SurvivorBot") == 0)
		{
			int client = GetClientOfUserId(GetEntProp(bot, Prop_Send, "m_humanSpectatorUserID"));			
			if(client > 0 && IsClientInGame(client))
			{
				return client;
			}
		}
	}
	return 0;
}