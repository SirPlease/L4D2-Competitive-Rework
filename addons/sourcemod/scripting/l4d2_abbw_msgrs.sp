#pragma semicolon 1
//強制1.7以後的新語法
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

ConVar hPutInKill, hPutInDefault, hPutInSwitch, hPutInTime;
int PutInKill, PutInDefault, PutInSwitch;
float PutInTime;

bool l4d2_client_kill, l4d2_client_kill_Switch;

public void OnPluginStart()
{
	RegConsoleCmd("sm_zs", Client_kill_Me, "幸存者自杀指令.");
	RegConsoleCmd("sm_kill", Client_kill_Me, "幸存者自杀指令.");
	RegConsoleCmd("sm_since", Client_since_Me, "管理员开启或关闭幸存者自杀插件和开局提示.");
	
	hPutInKill		= CreateConVar("l4d2_abbw_msgrs_enabled_PutIn_Kill", "1", "启用幸存者自杀指令? 0=禁用, 1=启用(只限倒地或挂边的), 2=启用(无条件使用).");
	hPutInDefault		= CreateConVar("l4d2_abbw_msgrs_enabled_PutIn_default", "1", "设置默认开启或关闭幸存者自杀指令. (输入指令 !since 开启或关闭,指令更改后这里的值失效) 0=关闭, 1=开启.");
	hPutInSwitch		= CreateConVar("l4d2_abbw_msgrs_enabled_PutIn_Switch", "1", "开局时提示幸存者自杀指令 !zs 可用? 0=禁用, 1=启用.");
	hPutInTime		= CreateConVar("l4d2_abbw_msgrs_enabled_PutIn_time", "7.0", "设置开局提示自杀指令的延迟显示时间/秒.");
	
	hPutInKill.AddChangeHook(hKillConVarChanged);
	hPutInDefault.AddChangeHook(hKillConVarChanged);
	hPutInSwitch.AddChangeHook(hKillConVarChanged);
	hPutInTime.AddChangeHook(hKillConVarChanged);
	
	AutoExecConfig(true, "l4d2_abbw_msgrs");
}

//地图开始
public void OnMapStart()
{	
	l4d2MsgrsKill();
}

public void hKillConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	l4d2MsgrsKill();
}

void l4d2MsgrsKill()
{
	PutInKill		= hPutInKill.IntValue;
	PutInDefault	= hPutInDefault.IntValue;
	PutInSwitch	= hPutInSwitch.IntValue;
	PutInTime		= hPutInTime.FloatValue;
}

public void OnConfigsExecuted()
{
	if(!l4d2_client_kill_Switch)
	{
		switch (PutInDefault)
		{
			case 0:
				l4d2_client_kill = false;
			case 1:
				l4d2_client_kill = true;
		}
	}
}

public Action Client_since_Me(int client, int args)
{
	if(bCheckClientAccess(client))
	{
		switch (PutInKill)
		{
			case 0:
				PrintToChat(client, "\x04[提示]\x05幸存者自杀指令已禁用,请在CFG中设为1启用.");
			case 1,2:
			{
				if (l4d2_client_kill)
				{
					l4d2_client_kill = false;
					l4d2_client_kill_Switch = true;
					PrintToChatAll("\x04[提示]\x03已关闭\x05幸存者自杀指令.");
				}
				else
				{
					l4d2_client_kill = true;
					l4d2_client_kill_Switch = true;
					PrintToChatAll("\x04[提示]\x03已开启\x05幸存者自杀指令.");
				}
			}
		}
	}
	else
		PrintToChat(client, "\x04[提示]\x05你无权使用此指令.");
	return Plugin_Handled;
}

bool bCheckClientAccess(int client)
{
	if(GetUserFlagBits(client) & ADMFLAG_ROOT)
		return true;
	return false;
}

//幸存者自杀代码.
public Action Client_kill_Me(int client, int args)
{
	if(PutInKill == 0)
	{
		PrintToChat(client,"\x04[提示]\x05幸存者自杀指令未启用.");	
		return Plugin_Handled;
	}
	if(l4d2_client_kill && IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client))
	{
		if (IsPlayerAlive(client) && GetClientTeam(client) == 2)
		{
			switch (PutInKill)
			{
				case 1:
					if (IsPlayerFallen(client) || IsPlayerFalling(client))
						hForcePlayerSuicide(client);//幸存者自杀代码.
					else
						PrintToChat(client,"\x04[提示]\x05自杀指令只限倒地或挂边的幸存者使用.");
						
				case 2:
					hForcePlayerSuicide(client);//幸存者自杀代码.
			}
		}
		else if(GetClientTeam(client) == 1)
			PrintToChat(client,"\x04[提示]\x05旁观者无权使用自杀指令.");
		else if(!IsPlayerAlive(client))
			PrintToChat(client,"\x04[提示]\x05你当前是死亡状态,无需自杀.");
		else if(GetClientTeam(client) == 3)
			PrintToChat(client,"\x04[提示]\x05此指令只限幸存者使用.");	
	}
	return Plugin_Handled;
}

//挂边的
bool IsPlayerFalling(int client)
{
	return GetEntProp(client, Prop_Send, "m_isIncapacitated") && GetEntProp(client, Prop_Send, "m_isHangingFromLedge");
}

//倒地的.
bool IsPlayerFallen(int client)
{
	return GetEntProp(client, Prop_Send, "m_isIncapacitated") && !GetEntProp(client, Prop_Send, "m_isHangingFromLedge");
}

void hForcePlayerSuicide(int client)
{
	ForcePlayerSuicide(client);//幸存者自杀代码.
	PrintToChatAll("\x04[提示]\x03%N\x05突然失去了梦想.", client);//聊天窗提示.
}

public void OnClientPutInServer(int client)
{
	if (IsFakeClient(client))
		return;
		
	if (PutInKill == 0)
		return;
	
	if(PutInSwitch == 0)
		return;
	
	CreateTimer(PutInTime, TimerAnnounce, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

public Action TimerAnnounce(Handle timer, any client)
{
	if ((client = GetClientOfUserId(client)))
	{
		if (IsClientInGame(client) && GetClientTeam(client) != 3 && l4d2_client_kill)
		{
			switch (PutInKill)
			{
				case 0:{}
				case 1:
					PrintToChat(client, "\x04[提示]\x05倒地或挂边时输入\x03!zs\x05或\x03!kill\x05可以自杀.");//聊天窗提示.
				case 2:
					PrintToChat(client, "\x04[提示]\x05聊天窗输入指令\x03!zs\x05或\x03!kill\x05可以自杀.");//聊天窗提示.
			}
		}
	}
	return Plugin_Continue;
}