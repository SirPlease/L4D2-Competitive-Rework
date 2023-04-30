#pragma semicolon 1
//強制1.7以後的新語法
#pragma newdecls required
#include <sourcemod>

ConVar Changeplayerkick, Changereturntolobby, Changealltalk, Changerestartgame, Changemission, Changechapter, Changedifficulty;
int g_Changealltalk, g_Changechapter, g_Changedifficulty, g_Changemission, g_Changeplayerkick, g_Changerestartgame, g_Changereturntolobby;

public void OnPluginStart()
{
	Changealltalk		= CreateConVar("l4d2_enabled_change_alltalk", "0", "启用全局通话投票? 0=禁用, 1=启用.");
	Changechapter		= CreateConVar("l4d2_enabled_change_chapter", "0", "启用投票更换章节? 0=禁用, 1=启用.");
	Changedifficulty	= CreateConVar("l4d2_enabled_change_difficulty", "0", "启用投票更换难度? 0=禁用, 1=启用.");
	Changemission		= CreateConVar("l4d2_enabled_change_mission", "0", "启用投票开始新图? 0=禁用, 1=启用.");
	Changeplayerkick	= CreateConVar("l4d2_enabled_change_playerkick", "0", "启用投票踢出玩家? 0=禁用, 1=启用.");
	Changerestartgame	= CreateConVar("l4d2_enabled_change_restartgame", "0", "启用投票重新开始? 0=禁用, 1=启用.");
	Changereturntolobby	= CreateConVar("l4d2_enabled_change_returntolobby", "0", "启用投票返回大厅? 0=禁用, 1=启用.");
	
	Changealltalk.AddChangeHook(gConVarChanged);
	Changechapter.AddChangeHook(gConVarChanged);
	Changedifficulty.AddChangeHook(gConVarChanged);
	Changemission.AddChangeHook(gConVarChanged);
	Changeplayerkick.AddChangeHook(gConVarChanged);
	Changerestartgame.AddChangeHook(gConVarChanged);
	Changereturntolobby.AddChangeHook(gConVarChanged);
	
	AutoExecConfig(true, "l4d2_callvote");//生成指定文件名的CFG.
	AddCommandListener(Listener_CallVote, "callvote");
}

//地图开始.
public void OnMapStart()
{
	l4d2_gChange();
}

public void gConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	l4d2_gChange();
}

void l4d2_gChange()
{
	g_Changealltalk = Changealltalk.IntValue;
	g_Changechapter = Changechapter.IntValue;
	g_Changedifficulty = Changedifficulty.IntValue;
	g_Changemission = Changemission.IntValue;
	g_Changeplayerkick = Changeplayerkick.IntValue;
	g_Changerestartgame = Changerestartgame.IntValue;
	g_Changereturntolobby = Changereturntolobby.IntValue;
}

public Action Listener_CallVote(int client, const char[] command, int args)
{
	char Msg[MAX_NAME_LENGTH];
	// Get the arguments of the callvote command and store them in the global variables
	GetCmdArg(1, Msg, sizeof(Msg)); //Msg
	//踢人时候的对象。
	//GetCmdArg(2, g_sTarget[client], sizeof(g_sTarget[]));
	// Block spectators from voting if the cvar bool is set to true
	if(!IsValidClient(client))
		return Plugin_Continue;
	
	if (g_Changeplayerkick != 1 && g_Changeplayerkick == 0)
	{
		if(strcmp(Msg, "kick", false) == 0)
		{
			PrintToChat(client,"\x04[提示]\x05游戏自带的投票踢出玩家已禁用.");//聊天窗提示.
			return Plugin_Handled;
		}
	}
	if (g_Changereturntolobby != 1 && g_Changereturntolobby == 0)
	{
		if(strcmp(Msg, "returntolobby", false) == 0)
		{
			PrintToChat(client,"\x04[提示]\x05游戏自带的投票返回大厅已禁用.");//聊天窗提示.
			return Plugin_Handled;
		}
	}
	if (g_Changealltalk != 1 && g_Changealltalk == 0)
	{
		if(strcmp(Msg, "changealltalk", false) == 0)
		{
			PrintToChat(client,"\x04[提示]\x05游戏自带的全局通话投票已禁用.");//聊天窗提示.
			return Plugin_Handled;
		}
	}
	if (g_Changerestartgame != 1 && g_Changerestartgame == 0)
	{
		if(strcmp(Msg, "restartgame", false) == 0)
		{
			PrintToChat(client,"\x04[提示]\x05游戏自带的投票重新开始已禁用.");//聊天窗提示.
			return Plugin_Handled;
		}
	}
	if (g_Changemission != 1 && g_Changemission == 0)
	{
		if(strcmp(Msg, "changemission", false) == 0)
		{
			PrintToChat(client,"\x04[提示]\x05游戏自带的投票开始新图已禁用.");//聊天窗提示.
			return Plugin_Handled;
		}
	}
	if (g_Changechapter != 1 && g_Changechapter == 0)
	{
		if(strcmp(Msg, "changechapter", false) == 0)
		{
			PrintToChat(client,"\x04[提示]\x05游戏自带的投票更换章节已禁用.");//聊天窗提示.
			return Plugin_Handled;
		}
	}
	if (g_Changedifficulty != 1 && g_Changedifficulty == 0)
	{
		if(strcmp(Msg, "changedifficulty", false) == 0)
		{
			PrintToChat(client,"\x04[提示]\x05游戏自带的投票更改难度已禁用.");//聊天窗提示.
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

stock bool IsValidClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client);
}
