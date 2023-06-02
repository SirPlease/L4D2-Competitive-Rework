#pragma semicolon 1
//強制1.7以後的新語法
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.2"

int    g_iSuicide, g_iShowTips;
ConVar g_hSuicide, g_hShowTips;

public Plugin myinfo =  
{
	name = "l4d2_player_suicide",
	author = "豆瓣酱な",  
	description = "玩家自杀指令",
	version = PLUGIN_VERSION,
	url = "N/A"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_zs", Command_Suicide, "玩家自杀指令.");
	RegConsoleCmd("sm_kill", Command_Suicide, "玩家自杀指令.");
	
	g_hSuicide	= CreateConVar("l4d2_player_suicide",		"1", "启用玩家自杀指令. 0=禁用, 1=只限倒地或挂边的生还者, 2=无条件使用.");
	g_hShowTips	= CreateConVar("l4d2_suicide_start_tips",	"7", "设置开局提示自杀指令的延迟显示时间/秒. 0=禁用.");
	g_hSuicide.AddChangeHook(IsSuicideConVarChanged);
	g_hShowTips.AddChangeHook(IsSuicideConVarChanged);
	AutoExecConfig(true, "l4d2_player_suicide");
}

public void OnConfigsExecuted()
{	
	IsConVarSuicide();
}

public void IsSuicideConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	IsConVarSuicide();
}

void IsConVarSuicide()
{
	g_iSuicide = g_hSuicide.IntValue;
	g_iShowTips = g_hShowTips.IntValue;
}

public Action OnClientSayCommand(int client, const char[] commnad, const char[] args)
{
	if(strlen(args) <= 1 || strncmp(commnad, "say", 3, false) != 0)
		return Plugin_Continue;

	if (StrEqual(args, "自杀", false))
		RequestFrame(IsFrameSuicide, GetClientUserId(client));
	return Plugin_Continue;
}

//玩家连接成功.
public void OnClientPostAdminCheck(int client)
{
	if (!IsFakeClient(client) && g_iShowTips > 0)
		CreateTimer(float(g_iShowTips), IsShowTipsTimer, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

public Action IsShowTipsTimer(Handle timer, any client)
{
	if ((client = GetClientOfUserId(client)))
	{
		if (IsClientInGame(client))
		{
			switch (GetClientTeam(client))
			{
				case 1,3:
					PrintToChat(client, "\x04[提示]\x05输入指令\x03!zs\x05或\x03!kill\x05或\x03自杀\x05可自杀.");//聊天窗提示.
				case 2,4:
				{
					switch (g_iSuicide)
					{
						case 1:
							PrintToChat(client, "\x04[提示]\x05倒地或挂边时输入指令\x03!zs\x05或\x03!kill\x05或\x03自杀\x05可自杀.");//聊天窗提示.
						case 2:
							PrintToChat(client, "\x04[提示]\x05输入指令\x03!zs\x05或\x03!kill\x05或\x03自杀\x05可自杀.");//聊天窗提示.
						default:
							PrintToChat(client, "\x04[提示]\x05输入指令\x03!zs\x05或\x03!kill\x05或\x03自杀\x05可自杀.");//聊天窗提示.
					}
				}
			}
		}
	}
	return Plugin_Stop;
}

public Action Command_Suicide(int client, int args)
{
	RequestFrame(IsFrameSuicide, GetClientUserId(client));
	return Plugin_Handled;
}

void IsFrameSuicide(int client)
{
	if ((client = GetClientOfUserId(client)))
		if(IsClientInGame(client) && !IsFakeClient(client))
			if(g_iSuicide > 0)
				IsRegSuicide(client);
			else
				PrintToChat(client, "\x04[提示]\x05玩家自杀指令未启用.");
}

void IsRegSuicide(int client)
{
	if(IsValidClient(client) && !IsFakeClient(client))
	{
		switch (GetClientTeam(client))
		{
			case 1:
			{
				int iBot = IsGetBotOfIdlePlayer(client);
				if (iBot != 0)
					IsPlayerSuicide(iBot, client, GetTrueName(client), "生还者");
				else
					PrintToChat(client, "\x04[提示]\x05旁观者无权使用该指令.");
			}
			case 2:
				IsPlayerSuicide(client, client, GetTrueName(client), "生还者");
			case 3:
				IsForceSuicide(client, client, GetTrueName(client), "感染者");//执行玩家死亡代码.
			case 4:
				IsPlayerSuicide(client, client, GetTrueName(client), "生还者");
		}
	}
}

void IsPlayerSuicide(int client, int victim, char[] g_sName, char[] g_sTeam)
{
	if (IsPlayerAlive(client))
	{
		switch (g_iSuicide)
		{
			case 1:
				if (!IsPlayerState(client))
					IsForceSuicide(client, victim, g_sName, g_sTeam);//执行玩家死亡代码.
				else
					PrintToChat(victim, "\x04[提示]\x05该指令只限倒地或挂边的%s使用.", g_sTeam);
			case 2:
				IsForceSuicide(client, victim, g_sName, g_sTeam);//执行玩家死亡代码.
		}
	}
	else
		PrintToChat(victim, "\x04[提示]\x05你当前已是死亡状态.");
}

void IsForceSuicide(int client, int victim, char[] g_sName, char[] g_sTeam)
{
	if (IsPlayerAlive(client))
	{
		ForcePlayerSuicide(client);//幸存者自杀代码.
		PrintToChatAll("\x04[提示]\x05(\x04%s\x05)\x03%s\x05突然失去了梦想.", g_sTeam, g_sName);
	}
	else
		PrintToChat(victim, "\x04[提示]\x05你当前已是死亡状态.");
}

stock bool IsValidClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client);
}

//正常状态.
stock bool IsPlayerState(int client)
{
	return !GetEntProp(client, Prop_Send, "m_isIncapacitated") && !GetEntProp(client, Prop_Send, "m_isHangingFromLedge");
}

//返回对应的内容.
char[] GetTrueName(int client)
{
	char g_sName[32];
	GetClientName(client, g_sName, sizeof(g_sName));
	return g_sName;
}

//返回闲置玩家对应的电脑.
int IsGetBotOfIdlePlayer(int client)
{
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == 2 && IsClientIdle(i) == client)
			return i;

	return 0;
}

//返回电脑幸存者对应的玩家.
int IsClientIdle(int client)
{
	if (!HasEntProp(client, Prop_Send, "m_humanSpectatorUserID"))
		return 0;

	return GetClientOfUserId(GetEntProp(client, Prop_Send, "m_humanSpectatorUserID"));
}