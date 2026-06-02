#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <usermessages>

ConVar g_cvGameIdle;
ConVar g_cvCvarChange;
ConVar g_cvSmNotify;
ConVar g_cvGameDisconnect;
ConVar g_cvMaxPlayers;

bool g_bGameIdle;
bool g_bCvarChange;
bool g_bSmNotify;
bool g_bGameDisconnect;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int errMax)
{
	if (GetEngineVersion() != Engine_Left4Dead2)
	{
		strcopy(error, errMax, "Plugin only supports Left 4 Dead 2.");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	HookEvent("server_cvar", Event_ServerCvar);
	HookEvent("player_disconnect", Event_PlayerDisconnect);
	HookUserMessage(GetUserMessageId("TextMsg"), OnTextMsg, true);

	g_cvGameIdle = CreateConVar("sms_game_idle_notify_block", "1", "屏蔽游戏自带的玩家闲置提示.");
	g_cvCvarChange = CreateConVar("sms_cvar_change_notify_block", "1", "屏蔽游戏自带的ConVar更改提示.");
	g_cvSmNotify = CreateConVar("sms_sourcemod_sm_notify_admin", "0", "屏蔽sourcemod平台自带的SM提示？(1-只向管理员显示,0-对所有人屏蔽).");
	g_cvGameDisconnect = CreateConVar("sms_game_disconnect_notify_block", "1", "屏蔽游戏自带的玩家离开提示.");

	g_cvMaxPlayers = FindConVar("sv_maxplayers");
	if (g_cvMaxPlayers != null)
	{
		g_cvMaxPlayers.AddChangeHook(OnConVarChanged);
	}

	g_cvGameIdle.AddChangeHook(OnConVarChanged);
	g_cvCvarChange.AddChangeHook(OnConVarChanged);
	g_cvSmNotify.AddChangeHook(OnConVarChanged);
	g_cvGameDisconnect.AddChangeHook(OnConVarChanged);
}

public void OnConfigsExecuted()
{
	GetCvars();
}

void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_bGameIdle = g_cvGameIdle.BoolValue;
	g_bCvarChange = g_cvCvarChange.BoolValue;
	g_bSmNotify = g_cvSmNotify.BoolValue;
	g_bGameDisconnect = g_cvGameDisconnect.BoolValue;
}

public Action OnTextMsg(UserMsg msgId, BfRead msg, const int[] players, int playersNum, bool reliable, bool init)
{
	char buffer[256];
	msg.ReadString(buffer, sizeof(buffer), false);

	if (g_bGameIdle && StrContains(buffer, "L4D_idle_spectator", false) != -1)
	{
		return Plugin_Handled;
	}

	if (StrContains(buffer, "\x03[SM]", true) != 0)
	{
		return Plugin_Continue;
	}

	if (g_bSmNotify)
	{
		DataPack datapack = new DataPack();
		datapack.WriteCell(playersNum);
		for (int i = 0; i < playersNum; i++)
		{
			datapack.WriteCell(players[i]);
		}
		datapack.WriteString(buffer);
		RequestFrame(DelaySmMessage, datapack);
	}

	return Plugin_Handled;
}

public Action Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
	if (g_bGameDisconnect)
	{
		event.BroadcastDisabled = true;
	}

	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client && IsFakeClient(client))
	{
		return Plugin_Continue;
	}

	return Plugin_Continue;
}

void DelaySmMessage(DataPack datapack)
{
	datapack.Reset();

	int playersNum = datapack.ReadCell();
	int[] players = new int[playersNum];
	int count;

	for (int i = 0; i < playersNum; i++)
	{
		int client = datapack.ReadCell();
		if (IsClientInGame(client) && CheckCommandAccess(client, "", ADMFLAG_ROOT, false))
		{
			players[count++] = client;
		}
	}

	if (!count)
	{
		delete datapack;
		return;
	}

	char buffer[256];
	datapack.ReadString(buffer, sizeof(buffer));
	delete datapack;

	ReplaceStringEx(buffer, sizeof(buffer), "[SM]", "\x04[SM]\x05");

	BfWrite bf = UserMessageToBfWrite(StartMessage("SayText2", players, count, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS));
	bf.WriteByte(-1);
	bf.WriteByte(1);
	bf.WriteString(buffer);
	EndMessage();
}

public Action Event_ServerCvar(Event event, const char[] name, bool dontBroadcast)
{
	if (g_bCvarChange)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
