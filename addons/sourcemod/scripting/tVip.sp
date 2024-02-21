#pragma semicolon 1

#define PLUGIN_AUTHOR "Totenfluch"
#define PLUGIN_VERSION "2.2"

#include <sourcemod>
#include <sdktools>
#include <multicolors>
#include <autoexecconfig>

#pragma newdecls required

char dbconfig[] = "tVip";
Database g_DB;

/*
	https://wiki.alliedmods.net/Checking_Admin_Flags_(SourceMod_Scripting)
	19 -> Custom5
	20 -> Custom6
*/

Handle g_hTestVipDuration;
int g_iTestVipDuration;

Handle g_hFlag;
int g_iFlags[20];
int g_iFlagCount = 0;

Handle g_hForward_OnClientLoadedPre;
Handle g_hForward_OnClientLoadedPost;

bool g_bIsVip[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "tVip", 
	author = PLUGIN_AUTHOR, 
	description = "Add time based VIPs ingame", 
	version = PLUGIN_VERSION, 
	url = "https://totenfluch.de"
};


public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	//Create natives
	CreateNative("tVip_GrantVip", NativeGrantVip);
	CreateNative("tVip_DeleteVip", NativeDeleteVip);
	CreateNative("tVip_isVip", _Native_IsVip);
	return APLRes_Success;
}


public void OnPluginStart() {
	char error[255];
	g_DB = SQL_Connect(dbconfig, true, error, sizeof(error));
	
	if (!g_DB)
	{
		SetFailState("Error connecting to database: \"%s\"", error);
	}
	
	SQL_SetCharset(g_DB, "utf8");
	
	char createTableQuery[4096];
	Format(createTableQuery, sizeof(createTableQuery), 
		"CREATE TABLE IF NOT EXISTS `tVip` ( \
 		`Id` bigint(20) NOT NULL AUTO_INCREMENT, \
  		`timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP, \
  		`playername` varchar(36) COLLATE utf8_bin NOT NULL, \
  		`playerid` varchar(20) COLLATE utf8_bin NOT NULL, \
  		`enddate` timestamp NOT NULL DEFAULT '2023-10-1 23:59:59', \
  		`admin_playername` varchar(36) COLLATE utf8_bin NOT NULL, \
  		`admin_playerid` varchar(20) COLLATE utf8_bin NOT NULL, \
 		 PRIMARY KEY (`Id`), \
  		 UNIQUE KEY `playerid` (`playerid`)  \
  		 ) ENGINE = InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=utf8 COLLATE=utf8_bin;"
		);
	SQL_TQuery(g_DB, SQLErrorCheckCallback, createTableQuery);
	
	AutoExecConfig_SetFile("tVip");
	AutoExecConfig_SetCreateFile(true);
	
	g_hFlag = AutoExecConfig_CreateConVar("tVip_flag", "19 0 1 2 3 5 6 9 10 13", "20=Custom6, 19=Custom5 etc. Numeric Flag See: 'https://wiki.alliedmods.net/Checking_Admin_Flags_(SourceMod_Scripting)' for Definitions ---- Multiple flags seperated with Space: '16 17 18 19' !!");
	g_hTestVipDuration = AutoExecConfig_CreateConVar("tVip_testVipDuration", "15", "Test Vip duration in minutes");
	
	AutoExecConfig_CleanFile();
	AutoExecConfig_ExecuteFile();
	
	RegAdminCmd("sm_tvip", cmdtVIP, ADMFLAG_ROOT, "Opens the tVIP menu");
	RegAdminCmd("sm_addvip", cmdAddVip, ADMFLAG_ROOT, "Adds a VIP Usage: sm_addvip \"<SteamID>\" <Duration in Month> \"<Name>\" [0=Month,1=Minutes]");
	RegAdminCmd("sm_removevip", removeVip, ADMFLAG_ROOT, "Removes a VIP Usage: sm_removevip \"<SteamID>\"");
	RegConsoleCmd("sm_vips", cmdListVips, "Shows all VIPs");
	RegConsoleCmd("sm_vip", openVipPanel, "Opens the Vip Menu");
	
	g_hForward_OnClientLoadedPre = CreateGlobalForward( "tVip_OnClientLoadedPre", ET_Event, Param_Cell);
	g_hForward_OnClientLoadedPost = CreateGlobalForward( "tVip_OnClientLoadedPost", ET_Event, Param_Cell);
	
	reloadVIPs();
}

public void OnConfigsExecuted() {
	g_iFlagCount = 0;
	g_iTestVipDuration = GetConVarInt(g_hTestVipDuration);
	char cFlags[256];
	GetConVarString(g_hFlag, cFlags, sizeof(cFlags));
	char cSplinters[20][6];
	for (int i = 0; i < 20; i++)
	strcopy(cSplinters[i], 6, "");
	ExplodeString(cFlags, " ", cSplinters, 20, 6);
	for (int i = 0; i < 20; i++) {
		if (StrEqual(cSplinters[i], ""))
			break;
		g_iFlags[g_iFlagCount++] = StringToInt(cSplinters[i]);
	}
}

public Action openVipPanel(int client, int args) {
	if (g_bIsVip[client]) {
		char playerid[20];
		GetClientAuthId(client, AuthId_Steam2, playerid, sizeof(playerid));
		if (StrContains(playerid, "STEAM_") != -1)
			strcopy(playerid, sizeof(playerid), playerid[8]);
		
		char getDatesQuery[1024];
		Format(getDatesQuery, sizeof(getDatesQuery), "SELECT timestamp,enddate,DATEDIFF(enddate, NOW()) as timeleft FROM tVip WHERE playerid = '%s';", playerid);
		
		SQL_TQuery(g_DB, getDatesQueryCallback, getDatesQuery, client);
	}
	return Plugin_Handled;
	
}

public void getDatesQueryCallback(Handle owner, Handle hndl, const char[] error, any data) {
	int client = data;
	char ends[128];
	char started[128];
	char left[64];
	while (SQL_FetchRow(hndl)) {
		SQL_FetchString(hndl, 0, started, sizeof(started));
		SQL_FetchString(hndl, 1, ends, sizeof(ends));
		SQL_FetchString(hndl, 2, left, sizeof(left));
	}
	
	Menu VipPanelMenu = CreateMenu(VipPanelMenuHandler);
	char m_started[256];
	char m_ends[256];
	Format(m_started, sizeof(m_started), "开始于: %s", started);
	Format(m_ends, sizeof(m_ends), "结束于: %s (%s 天)", ends, left);
	SetMenuTitle(VipPanelMenu, ">>VIP 面板");
	AddMenuItem(VipPanelMenu, "x", m_started, ITEMDRAW_DISABLED);
	AddMenuItem(VipPanelMenu, "x", m_ends, ITEMDRAW_DISABLED);
	DisplayMenu(VipPanelMenu, client, 60);
}

public int VipPanelMenuHandler(Handle menu, MenuAction action, int client, int item) {
	char cValue[32];
	GetMenuItem(menu, item, cValue, sizeof(cValue));
	if (action == MenuAction_Select) {
		// TODO ?
		
	}
	return 0;
}

public Action removeVip(int client, int args) {
	if (args != 1) {
		if (client != 0)
			CPrintToChat(client, "{olive}[-T-] {lightred}Invalid Params Usage: sm_removevip \"<SteamID>\"");
		else
			PrintToServer("[-T-] Invalid Params Usage: sm_removevip \"<SteamID>\"");
		return Plugin_Handled;
	}
	
	char playerid[20];
	GetCmdArg(1, playerid, sizeof(playerid));
	StripQuotes(playerid);
	if (StrContains(playerid, "STEAM_") != -1)
		strcopy(playerid, sizeof(playerid), playerid[8]);
	
	deleteVip(playerid);
	
	if (client != 0)
		CPrintToChat(client, "{green}Deleted {orange}%s{green} from the Database", playerid);
	else
		PrintToServer("Deleted %s from the Database", playerid);
	
	return Plugin_Handled;
}

public Action cmdAddVip(int client, int args) {
	if (args < 3) {
		if (client != 0)
			CPrintToChat(client, "{olive}[-T-] {lightred}Invalid Params Usage: sm_addvip \"<SteamID>\" <Duration in Month> \"<Name>\" [0=Month,1=Minutes]");
		else
			PrintToServer("[-T-] Invalid Params Usage: sm_addvip \"<SteamID>\" <Duration in Month> \"<Name>\"");
		return Plugin_Handled;
	}
	
	char input[22];
	GetCmdArg(1, input, sizeof(input));
	StripQuotes(input);
	if (StrContains(input, "STEAM_") != -1)
		strcopy(input, sizeof(input), input[8]);
	
	char duration[8];
	GetCmdArg(2, duration, sizeof(duration));
	int d1 = StringToInt(duration);
	
	char input2[20];
	strcopy(input2, sizeof(input2), input);
	StripQuotes(input2);
	
	char name[MAX_NAME_LENGTH + 8];
	GetCmdArg(3, name, sizeof(name));
	StripQuotes(name);
	char clean_name[MAX_NAME_LENGTH * 2 + 16];
	SQL_EscapeString(g_DB, name, clean_name, sizeof(clean_name));
	
	int timeFormat = 0;
	if(args == 4) {
		char timeFormatString[8];
		GetCmdArg(4, timeFormatString, sizeof(timeFormatString));
		timeFormat = StringToInt(timeFormatString);
	}
	
	grantVipEx(client, input2, d1, clean_name, timeFormat);
	return Plugin_Handled;
}

public Action cmdtVIP(int client, int args) {
	Menu mainChooser = CreateMenu(mainChooserHandler);
	SetMenuTitle(mainChooser, "VIP控制菜单");
	AddMenuItem(mainChooser, "add", ">>添加VIP");
	AddMenuItem(mainChooser, "remove", ">>移除VIP");
	AddMenuItem(mainChooser, "extend", ">>延续VIP");
	AddMenuItem(mainChooser, "list", ">>列出当前VIP及信息");
	DisplayMenu(mainChooser, client, 60);
	return Plugin_Handled;
}

public Action cmdListVips(int client, int args) {
	char showOffVIPQuery[1024];
	Format(showOffVIPQuery, sizeof(showOffVIPQuery), "SELECT playername,playerid FROM tVip WHERE NOW() < enddate;");
	SQL_TQuery(g_DB, SQLShowOffVipQuery, showOffVIPQuery, client);
	return Plugin_Handled;
}

public void SQLShowOffVipQuery(Handle owner, Handle hndl, const char[] error, any data) {
	int client = data;
	Menu showOffMenu = CreateMenu(noMenuHandler);
	SetMenuTitle(showOffMenu, ">>> VIP列表 <<<");
	while (SQL_FetchRow(hndl)) {
		char playerid[20];
		char playername[MAX_NAME_LENGTH + 8];
		SQL_FetchString(hndl, 0, playername, sizeof(playername));
		SQL_FetchString(hndl, 1, playerid, sizeof(playerid));
		AddMenuItem(showOffMenu, playerid, playername, ITEMDRAW_DISABLED);
	}
	DisplayMenu(showOffMenu, client, 60);
}

public int noMenuHandler(Handle menu, MenuAction action, int client, int item) { return 0;}

public int mainChooserHandler(Handle menu, MenuAction action, int client, int item) {
	char cValue[32];
	GetMenuItem(menu, item, cValue, sizeof(cValue));
	if (action == MenuAction_Select) {
		if (StrEqual(cValue, "add")) {
			showDurationSelect(client, 1);
		} else if (StrEqual(cValue, "remove")) {
			showAllVIPsToAdmin(client);
		} else if (StrEqual(cValue, "extend")) {
			extendSelect(client);
		} else if (StrEqual(cValue, "list")) {
			listUsers(client);
		}
	}
	return 0;
}

int g_iReason[MAXPLAYERS + 1];
public void showDurationSelect(int client, int reason) {
	Menu selectDuration = CreateMenu(selectDurationHandler);
	SetMenuTitle(selectDuration, ">>选择授予VIP的时间");
	AddMenuItem(selectDuration, "testVip", "测试VIP");
	AddMenuItem(selectDuration, "1", "1个月");
	AddMenuItem(selectDuration, "2", "2个月");
	AddMenuItem(selectDuration, "3", "3个月");
	AddMenuItem(selectDuration, "4", "4个月");
	AddMenuItem(selectDuration, "5", "5个月");
	AddMenuItem(selectDuration, "6", "6个月");
	AddMenuItem(selectDuration, "9", "9个月");
	AddMenuItem(selectDuration, "12", "12个月");
	g_iReason[client] = reason;
	DisplayMenu(selectDuration, client, 60);
}

int g_iDurationSelected[MAXPLAYERS + 1];
public int selectDurationHandler(Handle menu, MenuAction action, int client, int item) {
	char cValue[32];
	GetMenuItem(menu, item, cValue, sizeof(cValue));
	if (action == MenuAction_Select) {
		if (StrEqual(cValue, "testVip")) {
			g_iDurationSelected[client] = g_iTestVipDuration;
			g_iReason[client] = 3;
			showPlayerSelectMenu(client, g_iReason[client]);
		} else {
			g_iDurationSelected[client] = StringToInt(cValue);
			showPlayerSelectMenu(client, g_iReason[client]);
		}
	}
	return 0;
}

public void showPlayerSelectMenu(int client, int reason) {
	Handle menu;
	char menuTitle[255];
	if (reason == 1) {
		menu = CreateMenu(targetChooserMenuHandler);
		Format(menuTitle, sizeof(menuTitle), ">>选择授予 %i 月的玩家", g_iDurationSelected[client]);
	} else if (reason == 2) {
		menu = CreateMenu(extendChooserMenuHandler);
		Format(menuTitle, sizeof(menuTitle), ">>选择延长 %i 月的玩家", g_iDurationSelected[client]);
	} else if (reason == 3) {
		menu = CreateMenu(targetChooserMenuHandler);
		Format(menuTitle, sizeof(menuTitle), ">>选择授予测试VIP的玩家 (%i 分钟)", g_iDurationSelected[client]);
	}
	if (menu == INVALID_HANDLE)
		return;
	SetMenuTitle(menu, menuTitle);
	int pAmount = 0;
	for (int i = 1; i <= MAXPLAYERS; i++) {
		if (i == client)
			continue;
		
		if (!isValidClient(i))
			continue;
		
		if (IsFakeClient(i))
			continue;
		
		if (reason == 2) {
			if (!g_bIsVip[i])
				continue;
		} else if (reason == 1) {
			if (g_bIsVip[i])
				continue;
		}
		
		char Id[64];
		IntToString(i, Id, sizeof(Id));
		
		char targetName[MAX_NAME_LENGTH + 1];
		GetClientName(i, targetName, sizeof(targetName));
		
		AddMenuItem(menu, Id, targetName);
		pAmount++;
	}
	if (pAmount == 0)
		CPrintToChat(client, "{red}No matching clients found (Noone there or everyone is already VIP/Admin)");
	
	DisplayMenu(menu, client, 30);
}

public int targetChooserMenuHandler(Handle menu, MenuAction action, int client, int item) {
	if (action == MenuAction_Select) {
		char info[64];
		GetMenuItem(menu, item, info, sizeof(info));
		
		int target = StringToInt(info);
		if (!isValidClient(target) || !IsClientInGame(target)) {
			CPrintToChat(client, "{red}Invalid Target");
			return 0;
		}
		
		grantVip(client, target, g_iDurationSelected[client], g_iReason[client]);
	}
	if (action == MenuAction_End) {
		delete menu;
	}
	return 0;
}

public void grantVip(int admin, int client, int duration, int reason) {
	char admin_playerid[20];
	char admin_playername[MAX_NAME_LENGTH + 8];
	if (admin != 0)
	{
		GetClientAuthId(admin, AuthId_Steam2, admin_playerid, sizeof(admin_playerid));
		GetClientName(admin, admin_playername, sizeof(admin_playername));
		if (StrContains(admin_playerid, "STEAM_") != -1)
			strcopy(admin_playerid, sizeof(admin_playerid), admin_playerid[8]);
	}
	else
	{
		strcopy(admin_playerid, sizeof(admin_playername), "SERVER-CONSOLE");
		strcopy(admin_playerid, sizeof(admin_playerid), "SERVER-CONSOLE");
	}
	char clean_admin_playername[MAX_NAME_LENGTH * 2 + 16];
	SQL_EscapeString(g_DB, admin_playername, clean_admin_playername, sizeof(clean_admin_playername));
	
	
	char playerid[20];
	GetClientAuthId(client, AuthId_Steam2, playerid, sizeof(playerid));
	if (StrContains(playerid, "STEAM_") != -1)
		strcopy(playerid, sizeof(playerid), playerid[8]);
	char playername[MAX_NAME_LENGTH + 8];
	GetClientName(client, playername, sizeof(playername));
	char clean_playername[MAX_NAME_LENGTH * 2 + 16];
	SQL_EscapeString(g_DB, playername, clean_playername, sizeof(clean_playername));
	
	
	char addVipQuery[4096];
	Format(addVipQuery, sizeof(addVipQuery), "INSERT IGNORE INTO `tVip` (`Id`, `timestamp`, `playername`, `playerid`, `enddate`, `admin_playername`, `admin_playerid`) VALUES (NULL, CURRENT_TIMESTAMP, '%s', '%s', CURRENT_TIMESTAMP, '%s', '%s');", clean_playername, playerid, clean_admin_playername, admin_playerid);
	SQL_TQuery(g_DB, SQLErrorCheckCallback, addVipQuery);
	
	char updateTime[1024];
	if (reason != 3)
		Format(updateTime, sizeof(updateTime), "UPDATE tVip SET enddate = DATE_ADD(enddate, INTERVAL %i MONTH) WHERE playerid = '%s';", duration, playerid);
	else
		Format(updateTime, sizeof(updateTime), "UPDATE tVip SET enddate = DATE_ADD(enddate, INTERVAL %i MINUTE) WHERE playerid = '%s';", duration, playerid);
	SQL_TQuery(g_DB, SQLErrorCheckCallback, updateTime);
	
	CPrintToChat(admin, "{green}Added {orange}%s{green} as VIP for {orange}%i{green} %s", playername, duration, reason == 3 ? "Minutes":"Month");
	CPrintToChat(client, "{green}You've been granted {orange}%i{green} %s of {orange}VIP{green} by {orange}%N", duration, reason == 3 ? "Minutes":"Month", admin);
	setFlags(client);
}
public int _Native_IsVip(Handle plugin, int numParams){
    int client = GetNativeCell(1);
    return g_bIsVip[client];
}
public void grantVipEx(int admin, char playerid[20], int duration, char[] pname, int timeFormat) {
	char admin_playerid[20];
	if (admin != 0) {
		GetClientAuthId(admin, AuthId_Steam2, admin_playerid, sizeof(admin_playerid));
		if (StrContains(admin_playerid, "STEAM_") != -1)
			strcopy(admin_playerid, sizeof(admin_playerid), admin_playerid[8]);
	} else
		strcopy(admin_playerid, sizeof(admin_playerid), "SERVER-CONSOLE");
	char admin_playername[MAX_NAME_LENGTH + 8];
	
	if (admin != 0)
		GetClientName(admin, admin_playername, sizeof(admin_playername));
	else
		strcopy(admin_playername, sizeof(admin_playername), "SERVER-CONSOLE");
	char clean_admin_playername[MAX_NAME_LENGTH * 2 + 16];
	SQL_EscapeString(g_DB, admin_playername, clean_admin_playername, sizeof(clean_admin_playername));
	
	char addVipQuery[4096];
	Format(addVipQuery, sizeof(addVipQuery), "INSERT IGNORE INTO `tVip` (`Id`, `timestamp`, `playername`, `playerid`, `enddate`, `admin_playername`, `admin_playerid`) VALUES (NULL, CURRENT_TIMESTAMP, '%s', '%s', CURRENT_TIMESTAMP, '%s', '%s');", pname, playerid, clean_admin_playername, admin_playerid);
	SQL_TQuery(g_DB, SQLErrorCheckCallback, addVipQuery);
	
	char updateTime[1024];
	if(timeFormat == 1) {
		Format(updateTime, sizeof(updateTime), "UPDATE tVip SET enddate = DATE_ADD(enddate, INTERVAL %i MINUTE) WHERE playerid = '%s';", duration, playerid);
	} else {
		Format(updateTime, sizeof(updateTime), "UPDATE tVip SET enddate = DATE_ADD(enddate, INTERVAL %i MONTH) WHERE playerid = '%s';", duration, playerid);
	}
	SQL_TQuery(g_DB, SQLErrorCheckCallback, updateTime);
	
	if (admin != 0)
		CPrintToChat(admin, "{green}Added {orange}%s{green} as VIP for {orange}%i{green} Month", playerid, duration);
	else
		PrintToServer("Added %s as VIP for %i Month", playerid, duration);
}

public void OnClientPostAdminCheck(int client) {
	g_bIsVip[client] = false;
	char cleanUp[256];
	Format(cleanUp, sizeof(cleanUp), "DELETE FROM tVip WHERE enddate < NOW();");
	SQL_TQuery(g_DB, SQLErrorCheckCallback, cleanUp);
	
	loadVip(client);
}

public void loadVip(int client) {
	char playerid[20];
	GetClientAuthId(client, AuthId_Steam2, playerid, sizeof(playerid));
	if (StrContains(playerid, "STEAM_") != -1)
		strcopy(playerid, sizeof(playerid), playerid[8]);
	char isVipQuery[1024];
	Format(isVipQuery, sizeof(isVipQuery), "SELECT * FROM tVip WHERE playerid = '%s' AND enddate > NOW();", playerid);
	
	//Pass the userid to prevent assigning flags to a wrong client
	SQL_TQuery(g_DB, SQLCheckVIPQuery, isVipQuery, GetClientUserId(client));
}

public void SQLCheckVIPQuery(Handle owner, Handle hndl, const char[] error, any data) {
	int client = GetClientOfUserId(data);
	
	Action result = Plugin_Continue;
	Call_StartForward(g_hForward_OnClientLoadedPre);
	Call_PushCell(client);
	Call_Finish(result);
	
	if(result != Plugin_Continue && result != Plugin_Changed)
	{
		return;
	}
	
	//Check if the user is still ingame
	if (isValidClient(client)) {
		while (SQL_FetchRow(hndl)) {
			setFlags(client);
		}
	}
	
	Call_StartForward(g_hForward_OnClientLoadedPost);
	Call_PushCell(client);
	Call_Finish();
	
}

public void setFlags(int client) {
	g_bIsVip[client] = true;
	for (int i = 0; i < g_iFlagCount; i++)
		SetUserFlagBits(client, GetUserFlagBits(client) | (1 << g_iFlags[i]));
}

public void OnRebuildAdminCache(AdminCachePart part) {
	if (part == AdminCache_Admins)
		reloadVIPs();
}

public void reloadVIPs() {
	for (int i = 1; i < MAXPLAYERS; i++) {
		if (!isValidClient(i))
			continue;
		loadVip(i);
	}
}

public void showAllVIPsToAdmin(int client) {
	char selectAllVIPs[1024];
	Format(selectAllVIPs, sizeof(selectAllVIPs), "SELECT playername,playerid FROM tVip WHERE NOW() < enddate;");
	SQL_TQuery(g_DB, SQLListVIPsForRemoval, selectAllVIPs, client);
}

public void SQLListVIPsForRemoval(Handle owner, Handle hndl, const char[] error, any data) {
	int client = data;
	Menu menuToRemoveClients = CreateMenu(menuToRemoveClientsHandler);
	SetMenuTitle(menuToRemoveClients, ">>删除一个VIP");
	while (SQL_FetchRow(hndl)) {
		char playerid[20];
		char playername[MAX_NAME_LENGTH + 8];
		SQL_FetchString(hndl, 0, playername, sizeof(playername));
		SQL_FetchString(hndl, 1, playerid, sizeof(playerid));
		AddMenuItem(menuToRemoveClients, playerid, playername);
	}
	DisplayMenu(menuToRemoveClients, client, 60);
}

public int menuToRemoveClientsHandler(Handle menu, MenuAction action, int client, int item) {
	if (action == MenuAction_Select) {
		char info[20];
		char display[MAX_NAME_LENGTH + 8];
		int flags;
		GetMenuItem(menu, item, info, sizeof(info), flags, display, sizeof(display));
		deleteVip(info);
		showAllVIPsToAdmin(client);
		CPrintToChat(client, "{green}Removed {orange}%ss{green} VIP Status {green}({orange}%s{green})", display, info);
	}
	return 0;
}

public void deleteVip(char[] playerid) {
	char deleteVipQuery[512];
	Format(deleteVipQuery, sizeof(deleteVipQuery), "DELETE FROM tVip WHERE playerid = '%s';", playerid);
	SQL_TQuery(g_DB, SQLErrorCheckCallback, deleteVipQuery);
}

public void extendSelect(int client) {
	showDurationSelect(client, 2);
}

public int extendChooserMenuHandler(Handle menu, MenuAction action, int client, int item) {
	if (action == MenuAction_Select) {
		char info[64];
		GetMenuItem(menu, item, info, sizeof(info));
		
		int target = StringToInt(info);
		if (!isValidClient(target) || !IsClientInGame(target)) {
			CPrintToChat(client, "{red}Invalid Target");
			return 0;
		}
		
		int userTarget = GetClientUserId(target);
		extendVip(client, userTarget, g_iDurationSelected[client]);
	}
	if (action == MenuAction_End) {
		delete menu;
	}
	return 0;
}

public void extendVip(int client, int userTarget, int duration) {
	int theUserTarget = GetClientOfUserId(userTarget);
	char playerid[20];
	GetClientAuthId(theUserTarget, AuthId_Steam2, playerid, sizeof(playerid));
	if (StrContains(playerid, "STEAM_") != -1)
		strcopy(playerid, sizeof(playerid), playerid[8]);
	char playername[MAX_NAME_LENGTH + 8];
	GetClientName(theUserTarget, playername, sizeof(playername));
	char clean_playername[MAX_NAME_LENGTH * 2 + 16];
	SQL_EscapeString(g_DB, playername, clean_playername, sizeof(clean_playername));
	
	char updateQuery[1024];
	Format(updateQuery, sizeof(updateQuery), "UPDATE tVip SET enddate = DATE_ADD(enddate, INTERVAL %i MONTH) WHERE playerid = '%s';", duration, playerid);
	SQL_TQuery(g_DB, SQLErrorCheckCallback, updateQuery);
	
	Format(updateQuery, sizeof(updateQuery), "UPDATE tVip SET playername = '%s' WHERE playerid = '%s';", clean_playername, playerid);
	SQL_TQuery(g_DB, SQLErrorCheckCallback, updateQuery);
	
	CPrintToChat(client, "{green}Extended {orange}%s{green} VIP Status by {orange}%i{green} Month", playername, duration);
}

public void listUsers(int client) {
	char listVipsQuery[1024];
	Format(listVipsQuery, sizeof(listVipsQuery), "SELECT playername,playerid FROM tVip WHERE enddate > NOW();");
	SQL_TQuery(g_DB, SQLListVIPsQuery, listVipsQuery, client);
}

public void SQLListVIPsQuery(Handle owner, Handle hndl, const char[] error, any data) {
	int client = data;
	Menu menuToRemoveClients = CreateMenu(listVipsMenuHandler);
	SetMenuTitle(menuToRemoveClients, ">>所有VIP");
	while (SQL_FetchRow(hndl)) {
		char playerid[20];
		char playername[MAX_NAME_LENGTH + 8];
		SQL_FetchString(hndl, 0, playername, sizeof(playername));
		SQL_FetchString(hndl, 1, playerid, sizeof(playerid));
		AddMenuItem(menuToRemoveClients, playerid, playername);
	}
	DisplayMenu(menuToRemoveClients, client, 60);
}

public int listVipsMenuHandler(Handle menu, MenuAction action, int client, int item) {
	if (action == MenuAction_Select) {
		char cValue[20];
		GetMenuItem(menu, item, cValue, sizeof(cValue));
		char detailsQuery[512];
		Format(detailsQuery, sizeof(detailsQuery), "SELECT playername,playerid,enddate,timestamp,admin_playername,admin_playerid FROM tVip WHERE playerid = '%s';", cValue);
		SQL_TQuery(g_DB, SQLDetailsQuery, detailsQuery, client);
	}
	return 0;
}

public void SQLDetailsQuery(Handle owner, Handle hndl, const char[] error, any data) {
	int client = data;
	Menu detailsMenu = CreateMenu(detailsMenuHandler);
	bool hasData = false;
	while (SQL_FetchRow(hndl) && !hasData) {
		char playerid[20];
		char playername[MAX_NAME_LENGTH + 8];
		char startDate[128];
		char endDate[128];
		char adminname[MAX_NAME_LENGTH + 8];
		char adminplayerid[20];
		SQL_FetchString(hndl, 0, playername, sizeof(playername));
		SQL_FetchString(hndl, 1, playerid, sizeof(playerid));
		SQL_FetchString(hndl, 2, endDate, sizeof(endDate));
		SQL_FetchString(hndl, 3, startDate, sizeof(startDate));
		SQL_FetchString(hndl, 4, adminname, sizeof(adminname));
		SQL_FetchString(hndl, 5, adminplayerid, sizeof(adminplayerid));
		
		char title[64];
		Format(title, sizeof(title), ">>VIP: %s", playername);
		SetMenuTitle(detailsMenu, title);
		
		char playeridItem[64];
		Format(playeridItem, sizeof(playeridItem), "Steam id: %s", playerid);
		AddMenuItem(detailsMenu, "x", playeridItem, ITEMDRAW_DISABLED);
		
		char endItem[64];
		Format(endItem, sizeof(endItem), "过期于: %s", endDate);
		AddMenuItem(detailsMenu, "x", endItem, ITEMDRAW_DISABLED);
		
		char startItem[64];
		Format(startItem, sizeof(startItem), "开始于: %s", startDate);
		AddMenuItem(detailsMenu, "x", startItem, ITEMDRAW_DISABLED);
		
		char adminNItem[64];
		Format(adminNItem, sizeof(adminNItem), "添加人: %s", adminname);
		AddMenuItem(detailsMenu, "x", adminNItem, ITEMDRAW_DISABLED);
		
		char adminIItem[64];
		Format(adminIItem, sizeof(adminIItem), "添加人Steam id: %s", adminplayerid);
		AddMenuItem(detailsMenu, "x", adminIItem, ITEMDRAW_DISABLED);
		
		hasData = true;
	}
	DisplayMenu(detailsMenu, client, 60);
}

public int detailsMenuHandler(Handle menu, MenuAction action, int client, int item) {
	if (action == MenuAction_Select) {
		
	} else if (action == MenuAction_Cancel) {
		listUsers(client);
	}
	return 0;
}

stock bool isValidClient(int client) {
	return (1 <= client <= MaxClients && IsClientInGame(client));
}
/*
stock bool isVipCheck(int client) {
	AdminId id = GetUserAdmin(client);
	for (int i = 0; i < g_iFlagCount; i++){
		if (!GetAdminFlag(id, view_as<AdminFlag>(g_iFlags[i]))) {
			return false;
		}
	}
	return true;
}
*/
public void SQLErrorCheckCallback(Handle owner, Handle hndl, const char[] error, any data) {
	if (!StrEqual(error, ""))
		LogError(error);
}



//Natives

public int NativeGrantVip(Handle myplugin, int argc)
{
	int client = GetNativeCell(1);
	int admin = GetNativeCell(2);
	int duration = GetNativeCell(3);
	int format = GetNativeCell(4);
	if (format == 1)
		format = 3;
	else if (format == 0)
		format = 1;
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid time format (%d)", format);
		return 0;
	}
	if (admin < 1 || admin > MaxClients)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid admin index (%d)", admin);
		return 0;
	}
	if (!IsClientConnected(admin))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Admin %d is not connected", admin);
		return 0;
	}
	if (client < 1 || client > MaxClients)
	{
		
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
		return 0;
	}
	if (!IsClientConnected(client))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not connected", client);
		return 0;
	}
	grantVip(admin, client, duration, format);
	return 0;
}


public int NativeDeleteVip(Handle myplugin, int argc)
{
	char playerid[20];
	GetNativeString(1, playerid, sizeof(playerid));
	StripQuotes(playerid);
	if (StrContains(playerid, "STEAM_") != -1)
		strcopy(playerid, sizeof(playerid), playerid[8]);
	
	deleteVip(playerid);
	return 0;
} 