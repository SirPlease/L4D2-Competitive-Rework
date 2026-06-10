/*
	SourcePawn is Copyright (C) 2006-2008 AlliedModders LLC.  All rights reserved.
	SourceMod is Copyright (C) 2006-2008 AlliedModders LLC.  All rights reserved.
	Pawn and SMALL are Copyright (C) 1997-2008 ITB CompuPhase.
	Source is Copyright (C) Valve Corporation.
	All trademarks are property of their respective owners.

	This program is free software: you can redistribute it and/or modify it
	under the terms of the GNU General Public License as published by the
	Free Software Foundation, either version 3 of the License, or (at your
	option) any later version.

	This program is distributed in the hope that it will be useful, but
	WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
	General Public License for more details.

	You should have received a copy of the GNU General Public License along
	with this program. If not, see <http://www.gnu.org/licenses/>.
*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <colors>
#undef REQUIRE_PLUGIN
#include <veterans>
#include <updater>
#include <SteamWorks>

#define IsValidClient(%1)		(1 <= %1 <= MaxClients && IsClientInGame(%1))
#define IsValidAliveClient(%1)	(1 <= %1 <= MaxClients && IsClientInGame(%1) && IsPlayerAlive(%1))
#define GETBOTINTERVAL 3.0
#define DONATE_CONFIG_FILE "configs/anne_donate.cfg"
#define DONATE_MAX_OPTIONS 16

public Plugin myinfo =
{
	name = "simple join",
	author = "东",
	description = "A plugin designed CompetitiveWithAnne package change player team.",
	version = "1.2",
	url = "https://github.com/fantasylidong/CompetitiveWithAnne"
};
#define AUTOUPDATE_URL_LENGTH 256
#define UPDATE_URL_PUBLIC "http://anne.trygek.com/plugin_update/Anne_Updater_All.txt"
#define UPDATE_URL_PRIVATE "http://anne.trygek.com/plugin_update/private/Anne_Updater_Private.txt"

bool  
	g_bEnableGetbotCommand[MAXPLAYERS] = { false },
	g_bUpdateSystemAvailable = false, 
	g_bGroupSystemAvailable = false;

char
	g_sDonateAmount[MAXPLAYERS + 1][16],
	g_sDonateMethod[MAXPLAYERS + 1][16],
	g_sDonateNote[MAXPLAYERS + 1][128],
	g_sDonateOptionAmount[DONATE_MAX_OPTIONS][16],
	g_sDonateOptionDisplay[DONATE_MAX_OPTIONS][64];

int
	g_iDonateOptionCount = 0;

ConVar
	hCvarMotdTitle,
	hCvarMotdUrl,
	hCvarEnableAutoupdate,
	hCvarAutoupdatePublicUrl,
	hCvarAutoupdatePrivateUrl,
	hCvarEnableInf,
	hCvarKickFamilyAccount,
	hCvarIPUrl,
	hCvarDonateUrl;


public void OnPluginStart()
{
	LoadTranslations("join.phrases");
	hCvarEnableInf = CreateConVar("join_enable_inf", "1", "是否可以开启加入特感", _, true, 0.0, true, 1.0);
	hCvarKickFamilyAccount = CreateConVar("join_enable_kickfamilyaccount", "1", "是否开启踢出家庭共享账户", _, true, 0.0, true, 1.0);
	hCvarEnableAutoupdate = CreateConVar("join_autoupdate", "0", "是否开启AnneHappy核心插件自动更新：0关闭，1公开核心清单，2/3/4私用清单", _, true, 0.0, true, 4.0);
	hCvarAutoupdatePublicUrl = CreateConVar("join_autoupdate_public_url", UPDATE_URL_PUBLIC, "join_autoupdate为1时使用的公开核心更新清单URL");
	hCvarAutoupdatePrivateUrl = CreateConVar("join_autoupdate_private_url", UPDATE_URL_PRIVATE, "join_autoupdate为2/3/4时使用的私用更新清单URL");
	hCvarMotdTitle = CreateConVar("sm_cfgmotd_title", "AnneHappy电信服");
	hCvarMotdUrl = CreateConVar("sm_cfgmotd_url", "http://anne.trygek.com/l4d2/");  // 主页以后更换为数据库控制
	hCvarIPUrl = CreateConVar("sm_cfgip_url", "http://anne.trygek.com/ip.php");	// 服务器ip页面，以后更换为数据库控制
	hCvarDonateUrl = CreateConVar("sm_donate_url", "http://anne.trygek.com/sponsor/l4d2.php"); //赞助页面
	hCvarEnableAutoupdate.AddChangeHook(UpdateStatuChange);
	hCvarAutoupdatePublicUrl.AddChangeHook(UpdateStatuChange);
	hCvarAutoupdatePrivateUrl.AddChangeHook(UpdateStatuChange);
	AutoExecConfig(true, "join");
	RegConsoleCmd("sm_away", AFKTurnClientToSpe);
	RegConsoleCmd("sm_afk", AFKTurnClientToSpe);
	RegConsoleCmd("sm_spec", AFKTurnClientToSpe);
	RegConsoleCmd("sm_s", AFKTurnClientToSpe);
	RegConsoleCmd("sm_joininfected", TurnClientToInfected);
	RegConsoleCmd("sm_team3", TurnClientToInfected);
	RegConsoleCmd("sm_inf", TurnClientToInfected);
	RegConsoleCmd("sm_infected", TurnClientToInfected);
	RegConsoleCmd("sm_zombie", TurnClientToInfected);
	RegConsoleCmd("sm_join", TurnClientToSurvivors);
	RegConsoleCmd("sm_jg", TurnClientToSurvivors);
	RegConsoleCmd("sm_team2", TurnClientToSurvivors);
	RegConsoleCmd("sm_joingame", TurnClientToSurvivors);
	RegConsoleCmd("sm_survivor", TurnClientToSurvivors);
	RegConsoleCmd("sm_donate", DonateServer);
	RegConsoleCmd("sm_wc", FinishDonatePayment);
	RegConsoleCmd("sm_wanchen", FinishDonatePayment);
	RegConsoleCmd("sm_finish", FinishDonatePayment);
	RegAdminCmd("sm_donate_reload", ReloadDonateConfig, ADMFLAG_CONFIG, "Reload donate amount config");

	AddCommandListener(Command_Setinfo, "jointeam");
	AddCommandListener(Command_Setinfo1, "chooseteam");
	RegConsoleCmd("sm_ip", ShowAnneServerIP);
	RegConsoleCmd("sm_web", ShowAnneServerWeb);
	//RegConsoleCmd("sm_getbot", GetBot);
	RegAdminCmd("sm_restartmap", RestartMap, ADMFLAG_ROOT, "restarts map");
	HookEvent("player_disconnect", PlayerDisconnect_Event, EventHookMode_Pre);
	HookEvent("player_team", Event_PlayerTeam);
	LoadDonateConfig();
}

public void UpdateStatuChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
	RefreshAutoUpdater();
}

void RefreshAutoUpdater()
{
	if (!g_bUpdateSystemAvailable)
	{
		return;
	}

	Updater_RemovePlugin();

	char updateUrl[AUTOUPDATE_URL_LENGTH];
	if (!GetAutoUpdateUrl(updateUrl, sizeof(updateUrl)))
	{
		return;
	}

	Updater_AddPlugin(updateUrl);
	Updater_ForceUpdate();
}

bool GetAutoUpdateUrl(char[] updateUrl, int maxLength)
{
	updateUrl[0] = '\0';

	switch (hCvarEnableAutoupdate.IntValue)
	{
		case 1:
		{
			hCvarAutoupdatePublicUrl.GetString(updateUrl, maxLength);
		}
		case 2, 3, 4:
		{
			hCvarAutoupdatePrivateUrl.GetString(updateUrl, maxLength);
		}
		default:
		{
			return false;
		}
	}

	TrimString(updateUrl);
	return updateUrl[0] != '\0';
}

public void OnAllPluginsLoaded(){
	g_bGroupSystemAvailable = LibraryExists("veterans");
	g_bUpdateSystemAvailable = LibraryExists("updater");
	RefreshAutoUpdater();
}
public void OnLibraryAdded(const char[] name)
{
    if ( StrEqual(name, "veterans") ) { g_bGroupSystemAvailable = true; }
	else if(StrEqual(name, "updater")) { g_bUpdateSystemAvailable = true; RefreshAutoUpdater(); }
}
public void OnLibraryRemoved(const char[] name)
{
    if ( StrEqual(name, "veterans") ) { g_bGroupSystemAvailable = false; }
	else if (StrEqual(name, "updater")){ g_bUpdateSystemAvailable = false; }
}

public void Updater_OnLoaded()
{
	g_bUpdateSystemAvailable = true;
	RefreshAutoUpdater();
}

public void SteamWorks_OnValidateClient(int ownerauthid, int authid)
{
	if (ownerauthid > 0 && ownerauthid != authid && hCvarKickFamilyAccount.BoolValue)
	{
		char SteamID[32];
		Format(SteamID, 32, "STEAM_1:%d:%d", (authid & 1), (authid >> 1));
		int client = GetIndexBySteamID(SteamID);
		if (client != -1)
		{
			KickClient(client, "家庭共享账户无法进入本服务器组");
		}
	}
}

int GetIndexBySteamID(const char[] SteamID)
{
	char AuthStringToCompareWith[32];
	for (int i = 1; i <= MaxClients; i++)
	{ 
		if (IsClientConnected(i) && GetClientAuthId(i, AuthId_Steam2, AuthStringToCompareWith, sizeof(AuthStringToCompareWith)) && StrEqual(AuthStringToCompareWith, SteamID))
		{
			return i;
		}
	}
	return -1;
}

public Action RestartMap(int client,int args)
{
	CrashMap();
	return Plugin_Handled;
}

stock void CrashMap()
{
	char mapname[64];
	GetCurrentMap(mapname, sizeof(mapname));
	ServerCommand("changelevel %s", mapname);
}

//玩家加入游戏
public void OnClientConnected(int client)
{
	if(!IsFakeClient(client))
	{
		CPrintToChatAll("%t", "Join_CrawlingServer", client);
	}
}

public Action PlayerDisconnect_Event(Handle event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event,"userid"));

    if (!(1 <= client <= MaxClients))
        return Plugin_Handled;

    if (!IsClientInGame(client))
        return Plugin_Handled;

    if (IsFakeClient(client))
        return Plugin_Handled;

    char reason[64], message[64];
    GetEventString(event, "reason", reason, sizeof(reason));

    if(StrContains(reason, "connection rejected", false) != -1)
    {
        Format(message,sizeof(message),"连接被拒绝");
    }
    else if(StrContains(reason, "timed out", false) != -1)
    {
        Format(message,sizeof(message),"超时");
    }
    else if(StrContains(reason, "by console", false) != -1)
    {
        Format(message,sizeof(message),"控制台退出");
    }
    else if(StrContains(reason, "by user", false) != -1)
    {
        Format(message,sizeof(message),"自己主动断开连接");
    }
    else if(StrContains(reason, "ping is too high", false) != -1)
    {
        Format(message,sizeof(message),"ping 太高了");
    }
    else if(StrContains(reason, "No Steam logon", false) != -1)
    {
        Format(message,sizeof(message),"no steam logon/ steam验证失败");
    }
    else if(StrContains(reason, "Steam account is being used in another", false) != -1)
    {
        Format(message,sizeof(message),"steam账号被顶");
    }
    else if(StrContains(reason, "Steam Connection lost", false) != -1)
    {
        Format(message,sizeof(message),"steam断线");
    }
    else if(StrContains(reason, "This Steam account does not own this game", false) != -1)
    {
        Format(message,sizeof(message),"没有这款游戏");
    }
    else if(StrContains(reason, "Validation Rejected", false) != -1)
    {
        Format(message,sizeof(message),"验证失败");
    }
    else if(StrContains(reason, "Certificate Length", false) != -1)
    {
        Format(message,sizeof(message),"certificate length");
    }
    else if(StrContains(reason, "Pure server", false) != -1)
    {
        Format(message,sizeof(message),"纯净服务器");
    }
    else
    {
        message = reason;
    }

    CPrintToChatAll("%t", "Join_LeftGameReason", client, message);
    return Plugin_Handled;
} 

public Action Event_PlayerTeam(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetEventInt(event, "userid");
	int target = GetClientOfUserId(client);
	int team = GetEventInt(event, "team");
	bool disconnect = GetEventBool(event, "disconnect");
	if (IsValidPlayer(target) && !disconnect && team == 3 && !hCvarEnableInf.BoolValue)
	{
		if(!IsFakeClient(target))
		{
			CreateTimer(0.5, Timer_CheckDetay2, target, TIMER_FLAG_NO_MAPCHANGE);
		}else{
			return Plugin_Handled;
		}
	}
	//CreateTimer(0.1, Timer_MobChange, 0, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

public Action Timer_CheckDetay2(Handle Timer, int client)
{
	ChangeClientTeam(client, 1); 
	return Plugin_Continue;
}


public void OnClientPutInServer(int client)
{
	if(client > 0 && IsClientConnected(client) && !IsFakeClient(client) && !hCvarEnableInf.BoolValue)
	{
		//ServerCommand("sm_addbot2");
		CreateTimer(3.0, Timer_CheckDetay, client, TIMER_FLAG_NO_MAPCHANGE);
		g_bEnableGetbotCommand[client] = true;
	}

	if(g_bGroupSystemAvailable){
		if(!Veterans_Get(client, view_as<TARGET_OPTION_INDEX>(GOURP_MEMBER)) && !(CheckCommandAccess(client, "", ADMFLAG_SLAY))){
			ShowMotdToPlayer(client);
		}
	}else{
		ShowMotdToPlayer(client);
	}

}

public void OnClientDisconnect(int client)
{
	if(1 <= client <= MaxClients)
	{
		g_sDonateAmount[client][0] = '\0';
		g_sDonateMethod[client][0] = '\0';
		g_sDonateNote[client][0] = '\0';
	}
}

public Action Timer_CheckDetay(Handle Timer, int client)
{
	if(IsValidPlayerInTeam(client, 3))
	{
		ChangeClientTeam(client, 1); 
	}
	return Plugin_Continue;
}

public Action TurnClientToInfected(int client, int args) 
{
	if(!IsInfectTeamFull() && hCvarEnableInf.BoolValue)
	{
		ClientCommand(client, "jointeam infected");
	}
	return Plugin_Handled;
}

void checkbot(){
	int count=0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2)
		{
			count++;
		}
	}
	for(;count < FindConVar("survivor_limit").IntValue; count++){
		ServerCommand("sb_add");
	}	
}

public Action TurnClientToSurvivors(int client, int args)
{ 
	checkbot();
	if(!IsSuivivorTeamFull())
	{
		ClientCommand(client, "jointeam survivor");
	}
	return Plugin_Handled;
}

public Action AFKTurnClientToSpe(int client, int args) 
{
	if(!IsPinned(client))
		CreateTimer(1.0, Timer_CheckDetay2, client, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Handled;
}

public Action Command_Setinfo(int client, const char[] command, int args)
{
	char arg[32];
	GetCmdArg(1, arg, sizeof(arg));
	if (!hCvarEnableInf.BoolValue && (!StrEqual(arg, "survivor") || IsSuivivorTeamFull()))
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
} 

public Action Command_Setinfo1(int client, const char[] command, int args)
{
	if(hCvarEnableInf.BoolValue){
    	return Plugin_Continue;
	}
	else
	{
		return Plugin_Handled;
	}
} 

public Action ShowAnneServerIP(int client, int args) 
{
	char title[64], baseUrl[192], url[768], serverName[192], encodedServerName[576], separator[2];
	GetConVarString(hCvarMotdTitle, title, sizeof(title));
	GetConVarString(hCvarIPUrl, baseUrl, sizeof(baseUrl));

	ConVar hHostname = FindConVar("hostname");
	if(hHostname != null)
	{
		GetConVarString(hHostname, serverName, sizeof(serverName));
	}
	else
	{
		strcopy(serverName, sizeof(serverName), "");
	}

	UrlEncode(serverName, encodedServerName, sizeof(encodedServerName));
	strcopy(separator, sizeof(separator), StrContains(baseUrl, "?", false) == -1 ? "?" : "&");
	Format(url, sizeof(url), "%s%sserver=%s", baseUrl, separator, encodedServerName);

	ShowMOTDPanel(client, title, url, MOTDPANEL_TYPE_URL);
	return Plugin_Handled;
}

public Action ShowAnneServerWeb(int client, int args) 
{
	char title[64], url[192];
	GetConVarString(hCvarMotdTitle, title, sizeof(title));
	GetConVarString(hCvarMotdUrl, url, sizeof(url));
	ShowMOTDPanel(client, title, url, MOTDPANEL_TYPE_URL);	
	return Plugin_Handled;
}

public Action DonateServer(int client, int args)
{
	if(!IsValidClient(client) || IsFakeClient(client))
		return Plugin_Handled;

	if(args >= 2)
	{
		char amount[16], method[16], note[128];
		note[0] = '\0';
		GetCmdArg(1, amount, sizeof(amount));
		GetCmdArg(2, method, sizeof(method));
		if(!IsDonateMethodAllowed(method))
		{
			CPrintToChat(client, "%t", "Join_AnneDonatePaymentMethodOnly");
			ShowDonateMethodMenu(client);
			return Plugin_Handled;
		}
		if(args >= 3)
		{
			GetCmdArg(3, note, sizeof(note));
		}
		strcopy(g_sDonateAmount[client], sizeof(g_sDonateAmount[]), amount);
		strcopy(g_sDonateMethod[client], sizeof(g_sDonateMethod[]), method);
		strcopy(g_sDonateNote[client], sizeof(g_sDonateNote[]), note);
		ShowDonateWebToPlayer(client, amount, method);
		CPrintToChat(client, "%t", "Join_FinishRemindsAdministratorVerify");
		return Plugin_Handled;
	}

	ShowDonateAmountMenu(client);
	return Plugin_Handled;
}

public Action FinishDonatePayment(int client, int args)
{
	if(!IsValidClient(client) || IsFakeClient(client))
		return Plugin_Handled;

	char email[128];
	email[0] = '\0';
	if(args >= 1)
	{
		GetCmdArg(1, email, sizeof(email));
	}

	if(g_sDonateAmount[client][0] == '\0' || g_sDonateMethod[client][0] == '\0')
	{
		CPrintToChat(client, "%t", "Join_AnneDonateSponsorshipConfirmedNot");
		ShowDonateAmountMenu(client);
		return Plugin_Handled;
	}

	SubmitDonateFinishRequest(client, g_sDonateAmount[client], g_sDonateMethod[client], g_sDonateNote[client], email);
	CPrintToChat(client, "%t", "Join_AnneDonateRecordingPaymentCompletion");
	return Plugin_Handled;
}

public Action ReloadDonateConfig(int client, int args)
{
	LoadDonateConfig();
	ReplyToCommand(client, "[AnneDonate] 已重新读取赞助配置，共 %d 个档位。", g_iDonateOptionCount);
	return Plugin_Handled;
}

public void ResetMode()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i) && !IsFakeClient(i))
		{
			CPrintToChat(i, "%t", "Join_AnneDonateCurrentlyPeakPeriod");
			ShowDonateAmountMenu(i);
		}
	}
}

public void ShowMotdToPlayer(int client)
{
	char title[64], url[192];
	GetConVarString(hCvarMotdTitle, title, sizeof(title));
	GetConVarString(hCvarMotdUrl, url, sizeof(url));
	ShowMOTDPanel(client, title, url, MOTDPANEL_TYPE_URL);	
}

void ShowDonateWebToPlayer(int client, const char[] amount, const char[] method)
{
	char steam64[32], name[MAX_NAME_LENGTH], encodedName[MAX_NAME_LENGTH * 3 + 1], encodedAmount[48], encodedMethod[48];
	if(!GetClientAuthId(client, AuthId_SteamID64, steam64, sizeof(steam64), true))
	{
		strcopy(steam64, sizeof(steam64), "");
	}

	GetClientName(client, name, sizeof(name));
	UrlEncode(name, encodedName, sizeof(encodedName));
	UrlEncode(amount, encodedAmount, sizeof(encodedAmount));
	UrlEncode(method, encodedMethod, sizeof(encodedMethod));

	char title[64], baseUrl[192], url[768], separator[2];
	GetConVarString(hCvarMotdTitle, title, sizeof(title));
	GetDonateBaseUrl(baseUrl, sizeof(baseUrl));
	strcopy(separator, sizeof(separator), StrContains(baseUrl, "?", false) == -1 ? "?" : "&");

	if(amount[0] != '\0' && method[0] != '\0')
	{
		Format(url, sizeof(url), "%s%ssteam_id=%s&name=%s&game=1&amount=%s&method=%s", baseUrl, separator, steam64, encodedName, encodedAmount, encodedMethod);
	}
	else
	{
		Format(url, sizeof(url), "%s%ssteam_id=%s&name=%s", baseUrl, separator, steam64, encodedName);
	}

	PrintToConsole(client, "[AnneDonate] Open donate url: %s", url);
	ShowMOTDPanel(client, title, url, MOTDPANEL_TYPE_URL);
}

void ShowDonateAmountMenu(int client)
{
	Menu menu = new Menu(DonateAmountMenuHandler);
	menu.SetTitle("请选择赞助金额：");
	for(int i = 0; i < g_iDonateOptionCount; i++)
	{
		menu.AddItem(g_sDonateOptionAmount[i], g_sDonateOptionDisplay[i]);
	}
	menu.AddItem("web", "只打开赞助网页");
	menu.ExitButton = true;
	menu.Display(client, 20);
}

public int DonateAmountMenuHandler(Menu menu, MenuAction action, int client, int item)
{
	if(action == MenuAction_Select)
	{
		char amount[16];
		menu.GetItem(item, amount, sizeof(amount));
		if(StrEqual(amount, "web"))
		{
			g_sDonateAmount[client][0] = '\0';
			g_sDonateMethod[client][0] = '\0';
			g_sDonateNote[client][0] = '\0';
			ShowDonateWebToPlayer(client, "", "");
		}
		else
		{
			strcopy(g_sDonateAmount[client], sizeof(g_sDonateAmount[]), amount);
			g_sDonateMethod[client][0] = '\0';
			g_sDonateNote[client][0] = '\0';
			ShowDonateMethodMenu(client);
		}
	}
	else if(action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

void ShowDonateMethodMenu(int client)
{
	Menu menu = new Menu(DonateMethodMenuHandler);
	menu.SetTitle("请选择支付方式：");
	menu.AddItem("wechat", "微信支付");
	menu.AddItem("alipay", "支付宝");
	menu.ExitButton = true;
	menu.Display(client, 20);
}

bool IsDonateMethodAllowed(const char[] method)
{
	return StrEqual(method, "wechat", false) || StrEqual(method, "alipay", false);
}

public int DonateMethodMenuHandler(Menu menu, MenuAction action, int client, int item)
{
	if(action == MenuAction_Select)
	{
		char method[16];
		menu.GetItem(item, method, sizeof(method));
		strcopy(g_sDonateMethod[client], sizeof(g_sDonateMethod[]), method);
		ShowDonateWebToPlayer(client, g_sDonateAmount[client], method);
		CPrintToChat(client, "%t", "Join_FinishRemindsAdministratorVerify");
	}
	else if(action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

void SubmitDonateFinishRequest(int client, const char[] amount, const char[] method, const char[] note, const char[] email)
{
	char baseUrl[192], steam64[32], name[MAX_NAME_LENGTH];
	GetDonateBaseUrl(baseUrl, sizeof(baseUrl));
	GetClientName(client, name, sizeof(name));

	if(!GetClientAuthId(client, AuthId_SteamID64, steam64, sizeof(steam64), true))
	{
		CPrintToChat(client, "%t", "Join_AnneDonateUnableObtainSteamID64");
		return;
	}

	if(GetFeatureStatus(FeatureType_Native, "SteamWorks_CreateHTTPRequest") != FeatureStatus_Available)
	{
		CPrintToChat(client, "%t", "Join_AnneDonateSteamWorksNotAvailable");
		return;
	}

	Handle request = SteamWorks_CreateHTTPRequest(k_EHTTPMethodPOST, baseUrl);
	if(request == null)
	{
		CPrintToChat(client, "%t", "Join_AnneDonatePaymentCompletionPrompt");
		return;
	}

	SteamWorks_SetHTTPRequestGetOrPostParameter(request, "direct_steam_id", steam64);
	SteamWorks_SetHTTPRequestGetOrPostParameter(request, "direct_name", name);
	SteamWorks_SetHTTPRequestGetOrPostParameter(request, "amount", amount);
	SteamWorks_SetHTTPRequestGetOrPostParameter(request, "method", method);
	SteamWorks_SetHTTPRequestGetOrPostParameter(request, "note", note);
	SteamWorks_SetHTTPRequestGetOrPostParameter(request, "email", email);
	SteamWorks_SetHTTPRequestGetOrPostParameter(request, "direct_email", email);
	SteamWorks_SetHTTPRequestGetOrPostParameter(request, "game", "1");
	SteamWorks_SetHTTPRequestGetOrPostParameter(request, "game_action", "paid");
	SteamWorks_SetHTTPRequestContextValue(request, GetClientUserId(client));
	SteamWorks_SetHTTPCallbacks(request, DonateFinishCompleted);

	if(!SteamWorks_SendHTTPRequest(request))
	{
		delete request;
		CPrintToChat(client, "%t", "Join_AnneDonatePaymentCompletionPrompt");
		return;
	}
}

public void DonateFinishCompleted(Handle request, bool failure, bool requestSuccessful, EHTTPStatusCode statusCode, any userid)
{
	int client = GetClientOfUserId(userid);
	if(IsValidClient(client) && !IsFakeClient(client))
	{
		if(failure || !requestSuccessful || statusCode < k_EHTTPStatusCode200OK || statusCode >= k_EHTTPStatusCode300MultipleChoices)
		{
			CPrintToChat(client, "%t", "Join_AnneDonatePaymentCompletionPrompts", statusCode);
		}
		else
		{
			CPrintToChat(client, "%t", "Join_AnneDonatePaymentCompletionPromptSynchronized");
		}
	}
	delete request;
}

void GetDonateBaseUrl(char[] baseUrl, int maxlen)
{
	GetConVarString(hCvarDonateUrl, baseUrl, maxlen);
	ReplaceString(baseUrl, maxlen, "/l4d2/sponsor/l4d2.php", "/sponsor/l4d2.php", false);
}

void LoadDonateConfig()
{
	g_iDonateOptionCount = 0;

	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), DONATE_CONFIG_FILE);

	KeyValues kv = new KeyValues("AnneDonate");
	if(kv.ImportFromFile(path) && kv.JumpToKey("items") && kv.GotoFirstSubKey())
	{
		do
		{
			if(g_iDonateOptionCount >= DONATE_MAX_OPTIONS)
				break;

			kv.GetString("amount", g_sDonateOptionAmount[g_iDonateOptionCount], sizeof(g_sDonateOptionAmount[]));
			kv.GetString("display", g_sDonateOptionDisplay[g_iDonateOptionCount], sizeof(g_sDonateOptionDisplay[]));
			if(g_sDonateOptionAmount[g_iDonateOptionCount][0] != '\0' && g_sDonateOptionDisplay[g_iDonateOptionCount][0] != '\0')
			{
				g_iDonateOptionCount++;
			}
		}
		while(kv.GotoNextKey());
	}
	delete kv;

	if(g_iDonateOptionCount == 0)
	{
		AddDefaultDonateOption("20", "20 元 / 30 天");
		AddDefaultDonateOption("100", "100 元 / 180 天");
		AddDefaultDonateOption("168", "168 元 / 365 天");
	}
}

void AddDefaultDonateOption(const char[] amount, const char[] display)
{
	if(g_iDonateOptionCount >= DONATE_MAX_OPTIONS)
		return;

	strcopy(g_sDonateOptionAmount[g_iDonateOptionCount], sizeof(g_sDonateOptionAmount[]), amount);
	strcopy(g_sDonateOptionDisplay[g_iDonateOptionCount], sizeof(g_sDonateOptionDisplay[]), display);
	g_iDonateOptionCount++;
}

stock void UrlEncode(const char[] input, char[] output, int maxlen)
{
	int written = 0;
	for(int i = 0; input[i] != '\0' && written < maxlen - 1; i++)
	{
		int c = input[i];
		if(c < 0)
			c += 256;

		if((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') || c == '-' || c == '_' || c == '.' || c == '~')
		{
			output[written++] = view_as<char>(c);
		}
		else if(written < maxlen - 3)
		{
			Format(output[written], maxlen - written, "%%%02X", c);
			written += 3;
		}
		else
		{
			break;
		}
	}
	output[written] = '\0';
}

public Action GetBot(int client, int args) 
{
	if(!IsValidClient(client))
		return Plugin_Handled;
	if(!g_bEnableGetbotCommand[client]){
		CPrintToChat(client, "%t", "Join_UseCommandsTooFast");
	}
	else if(IsSuivivorTeamFull()){
		CPrintToChat(client, "%t", "Join_SurvivorTeamFullNoOther");
	}else{
		DrawSwitchCharacterMenu(client);
		g_bEnableGetbotCommand[client] = false;
		CreateTimer(GETBOTINTERVAL, ReEnableGetbotCommand, client);
	}
	return Plugin_Handled;
}

public Action ReEnableGetbotCommand(Handle timer, int client)
{
	g_bEnableGetbotCommand[client] = true;
	return Plugin_Stop;
}

public void DrawSwitchCharacterMenu(int client)
{
	Menu menu = new Menu(SwitchCharacterMenuHandler);
	menu.SetTitle("请选择喜欢的人物：");
	// 添加 Bot 到菜单中
	int menuindex = 0;
	for (int bot = 1; bot <= MaxClients; bot++)
	{
		if (IsClientInGame(bot))
		{
			char botid[32], botname[32], menuitem[8];
			GetClientName(bot, botname, sizeof(botname));
			GetClientAuthId(bot, AuthId_Steam2, botid, sizeof(botid));
			if (strcmp(botid, "BOT") == 0 && GetClientTeam(bot) == 2)
			{
				GetClientName(bot, botname, sizeof(botname));
				IntToString(menuindex, menuitem, sizeof(menuitem));
				menu.AddItem(menuitem, botname);
				menuindex++;
			}
		}
	}
	menu.ExitButton = true;
	menu.Display(client, 20);
}

public int SwitchCharacterMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char botname[32];
		GetMenuItem(menu, param2, botname, sizeof(botname), _, botname, sizeof(botname));
		ChangeClientTeam(param1, 1);
		ClientCommand(param1, "jointeam survivor %s", botname);
		//DataPack  dp;
		//dp.WriteCell(param1);
		//dp.WriteString(botname);
		//CreateTimer(1.0, ChangeTeam, dp);
	}
	else if (action == MenuAction_Cancel)
	{
		delete menu;
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}
/*
public Action ChangeTeam(Handle timer, DataPack  dp){
	dp.Reset();
	char botname[32];
	int client = dp.ReadCell();
	dp.ReadString(botname, 32);
	ClientCommand(client, "jointeam survivor %s", botname);
	return Plugin_Continue;
}
*/

//判断特感是否已经满人
stock bool IsInfectTeamFull() 
{
	int count = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 3)
		{
			count ++;
		}
	}
	if(count >= FindConVar("z_max_player_zombies").IntValue){
		return true;
	}		
	else
	{
		return false;
	}
}

//判断生还是否已经满人
stock bool IsSuivivorTeamFull() 
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && IsFakeClient(i))
		{
			return false;
		}
	}
	return true;
}
//判断是否为生还者
stock bool IsSurvivor(int client) 
{
	if(client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2) 
	{
		return true;
	} 
	else 
	{
		return false;
	}
}

//判断是否为玩家再队伍里
stock bool IsValidPlayerInTeam(int client,int team)
{
	if(IsValidPlayer(client))
	{
		if(GetClientTeam(client)==team)
		{
			return true;
		}
	}
	return false;
}

stock bool IsValidPlayer(int client, bool AllowBot = true, bool AllowDeath = true)
{
	if (client < 1 || client > MaxClients)
		return false;
	if (!IsClientConnected(client) || !IsClientInGame(client))
		return false;
	if (!AllowBot)
	{
		if (IsFakeClient(client))
			return false;
	}

	if (!AllowDeath)
	{
		if (!IsPlayerAlive(client))
			return false;
	}	
	
	return true;
}

//判断生还者是否已经被控
stock bool IsPinned(int client) 
{
	bool bIsPinned = false;
	if (IsSurvivor(client)) 
	{
		if( GetEntPropEnt(client, Prop_Send, "m_tongueOwner") > 0 ) bIsPinned = true; // smoker
		if( GetEntPropEnt(client, Prop_Send, "m_pounceAttacker") > 0 ) bIsPinned = true; // hunter
		if( GetEntPropEnt(client, Prop_Send, "m_carryAttacker") > 0 ) bIsPinned = true; // charger carry
		if( GetEntPropEnt(client, Prop_Send, "m_pummelAttacker") > 0 ) bIsPinned = true; // charger pound
		if( GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker") > 0 ) bIsPinned = true; // jockey
	}		
	return bIsPinned;
}
