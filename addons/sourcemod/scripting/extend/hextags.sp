/*
 * HexTags Plugin.
 * by: Hexah
 * https://github.com/Hexer10/HexTags
 *
 * Copyright (C) 2017-2020 Mattia (Hexah|Hexer10|Papero)
 *
 * This file is part of the HexTags SourceMod Plugin.
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 */
//#define DEBUG 0

#include <sourcemod>
#include <sdktools>
#include <chat-processor>
#include <geoip>
#include <hexstocks>
#include <hextags>
#include <clientprefs>
#include <dbi>


#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#include <l4dstats>
#include <mostactive>
#include <cstrike>
#include <kento_rankme/rankme>
#include <warden>
#include <myjbwarden>
#include <hl_gangs>
#include <SteamWorks>
#define REQUIRE_EXTENSIONS
#define REQUIRE_PLUGIN


#define PLUGIN_AUTHOR         "Hexah"
#define PLUGIN_VERSION        "<TAG>"

#pragma semicolon 1
#pragma newdecls required


// EVENTS
PrivateForward pfCustomSelector;
Handle fTagsUpdated;
Handle fMessageProcess;
Handle fMessageProcessed;
Handle fMessagePreProcess;

// COOKIES
Handle hVibilityCookie;
Handle hSelTagCookie;
Handle hVibilityAdminsCookie;
Handle hIsAnonymousCookie;

Handle hRoundStatusTimer;

ConVar cv_sDefaultGang;
ConVar cv_bParseRoundEnd;
ConVar cv_bEnableTagsList;

bool bCSGO;
//bool bLate;
bool bRankme;
bool bWarden;
bool bMyJBWarden;
bool bGangs;
bool bSteamWorks = true;
bool bCanUseClanTags;
bool bHideTag[MAXPLAYERS + 1];
bool bHasRoundEnded;
bool bIsAnonymous[MAXPLAYERS + 1];

int iRank[MAXPLAYERS + 1] = { -1, ... };
int iNextDefTag;
int iSelTagId[MAXPLAYERS + 1];

char sUserTag[MAXPLAYERS + 1][64];
char sTagConf[PLATFORM_MAX_PATH];

ArrayList userTags[MAXPLAYERS + 1];
CustomTags selectedTags[MAXPLAYERS + 1];
KeyValues tagsKv;


//Plugin info
public Plugin myinfo = 
{
	name = "hextags", 
	author = PLUGIN_AUTHOR, 
	description = "Edit Tags & Colors!", 
	version = PLUGIN_VERSION, 
	url = "github.com/Hexer10/HexTags"
};

//Startup
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	//API
	RegPluginLibrary("hextags");
	CreateNative("HexTags_GetClientTag", Native_GetClientTag);
	CreateNative("HexTags_SetClientTag", Native_SetClientTag);
	CreateNative("HexTags_ResetClientTag", Native_ResetClientTags);
	CreateNative("HexTags_AddCustomSelector", Native_AddCustomSelector);
	CreateNative("HexTags_RemoveCustomSelector", Native_RemoveCustomSelector);
	
	fTagsUpdated = new GlobalForward("HexTags_OnTagsUpdated", ET_Ignore, Param_Cell);
	
	fMessageProcess = new GlobalForward("HexTags_OnMessageProcess", ET_Single, Param_Cell, Param_String, Param_String);
	fMessageProcessed = new GlobalForward("HexTags_OnMessageProcessed", ET_Ignore, Param_Cell, Param_String, Param_String);
	fMessagePreProcess = new GlobalForward("HexTags_OnMessagePreProcess", ET_Single, Param_Cell, Param_String, Param_String);
	
	pfCustomSelector = new PrivateForward(ET_Single, Param_Cell, Param_String);
	
	EngineVersion engine = GetEngineVersion();
	bCSGO = (engine == Engine_CSGO || engine == Engine_CSS);
	bCanUseClanTags = bCSGO && GetFeatureStatus(FeatureType_Native, "CS_SetClientClanTag") == FeatureStatus_Available;
	
	//LateLoad
	//bLate = late;
	
	return APLRes_Success;
}


public void OnPluginStart()
{
	LoadTranslations("hextags.phrases");
	//ConVars
	CreateConVar("sm_hextags_version", PLUGIN_VERSION, "HexTags plugin version", FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
	cv_sDefaultGang = CreateConVar("sm_hextags_nogang", "", "Text to use if user has no tag - needs hl_gangs.");
	cv_bParseRoundEnd = CreateConVar("sm_hextags_roundend", "0", "If 1 the tags will be reloaded even on round end - Suggested to be used with plugins like mostactive or rankme.");
	cv_bEnableTagsList = CreateConVar("sm_hextags_enable_tagslist", "1", "Set to 1 to enable the sm_tagslist command.");
	
	//AutoExecConfig();
	
	//Reg Cmds
	RegAdminCmd("sm_reloadtags", Cmd_ReloadTags, ADMFLAG_GENERIC, "Reload HexTags plugin config.");
	RegAdminCmd("sm_toggletags", Cmd_ToggleTags, ADMFLAG_GENERIC, "Toggle the visibility of your tags.");
	RegAdminCmd("sm_anonymous", Cmd_Anonymous, ADMFLAG_GENERIC, "Toggle the user-specific tags (SteamID, admin groups/flags will be ignored).");
	RegConsoleCmd("sm_cz", Cmd_ReloadTags, "Reload HexTags plugin config.");
	RegConsoleCmd("sm_tagslist", Cmd_TagsList, "Select your tag!");
	RegConsoleCmd("sm_chenghao", Cmd_TagsList, "Select your tag!");
	RegConsoleCmd("sm_ch", Cmd_TagsList, "Select your tag!");
	RegConsoleCmd("sm_getteam", Cmd_GetTeam, "Get current team name");
	
	
	//Event hooks
	if (!HookEventEx("round_end", Event_RoundEnd))
		LogError("Failed to hook \"round_end\", \"sm_hextags_roundend\" won't produce any effect.");
	
	HookEvent("round_start", Event_RoundStart);
	
	hVibilityCookie = RegClientCookie("HexTags_Visibility", "Show or hide the tags.", CookieAccess_Private);
	hSelTagCookie = RegClientCookie("HexTags_SelectedTag", "Selected Tag", CookieAccess_Private);
	hVibilityAdminsCookie = RegClientCookie("HexTags_Visibility_Admins", "Show or hide the admin tags.", CookieAccess_Private);
	hIsAnonymousCookie = RegClientCookie("HexTags_AnonymousCookie", "Plugin that defines wether or not an admin is anonymous.", CookieAccess_Protected);
	
	#if defined DEBUG
	RegConsoleCmd("sm_gettagvars", Cmd_GetVars);
	RegConsoleCmd("sm_firesel", Cmd_FireSel);
	#endif
}


public void OnAllPluginsLoaded()
{
	Debug_Print("Called OnAllPlugins!");
	
	if (FindPluginByFile("custom-chatcolors-cp.smx") || LibraryExists("ccc"))
		LogMessage("[HexTags] Found Custom Chat Colors running!\n	Please avoid running it with this plugin!");

	bRankme = LibraryExists("rankme");
	bWarden = LibraryExists("warden");
	bMyJBWarden = LibraryExists("myjbwarden");
	bGangs = LibraryExists("hl_gangs");
	bSteamWorks = LibraryExists("SteamWorks");

	LoadKv();
	/*
	if (bLate)for (int i = 1; i <= MaxClients; i++)if (IsClientInGame(i))
	{
		OnClientPutInServer(i);
		if (AreClientCookiesCached(i))
			OnClientCookiesCached(i);
		
		OnClientPostAdminCheck(i);
	}*/
	
	//Timers
	if (bCSGO)
		CreateTimer(5.0, Timer_ForceTag, _, TIMER_REPEAT);
}

public void OnLibraryAdded(const char[] name)
{
	Debug_Print("Called OnLibraryAdded %s", name);
	if (StrEqual(name, "rankme"))
	{
		bRankme = true;
	}
	else if (StrEqual(name, "warden"))
	{
		bWarden = true;
	}
	else if (StrEqual(name, "myjbwarden"))
	{
		bMyJBWarden = true;
	}
	else if (StrEqual(name, "hl_gangs"))
	{
		bGangs = true;
	}
	else if (StrEqual(name, "SteamWorks", false))
	{
		bSteamWorks = true;
	}
}


public void OnLibraryRemoved(const char[] name)
{
	Debug_Print("Called OnLibraryRemoved %s", name);
	if (StrEqual(name, "rankme"))
	{
		bRankme = false;
		LoadKv();
	}
	else if (StrEqual(name, "warden"))
	{
		bWarden = false;
		LoadKv();
	}
	else if (StrEqual(name, "myjbwarden"))
	{
		bMyJBWarden = false;
		LoadKv();
	}
	else if (StrEqual(name, "hl_gangs"))
	{
		bGangs = false;
		LoadKv();
	}
	else if (StrEqual(name, "SteamWorks", false))
	{
		bSteamWorks = false;
		LoadKv();
	}
}

//Thanks to https://forums.alliedmods.net/showpost.php?p=2573907&postcount=6
public Action OnClientCommandKeyValues(int client, KeyValues kv)
{
	if (bHideTag[client])
		return Plugin_Continue;
	
	char sKey[64];
	
	if (!bCSGO || !kv.GetSectionName(sKey, sizeof(sKey)))
		return Plugin_Continue;
	
	#if defined DEBUG
	char sKV[256];
	kv.ExportToString(sKV, sizeof(sKV));
	Debug_Print("Called ClientCmdKv: %s\n%s\n", sKey, sKV);
	#endif
	
	if (StrEqual(sKey, "ClanTagChanged"))
	{
		kv.GetString("tag", sUserTag[client], sizeof(sUserTag[]));
		LoadTags(client);
		
		if (selectedTags[client].ScoreTag[0] == '\0')
			return Plugin_Continue;
		
		kv.SetString("tag", selectedTags[client].ScoreTag);
		Debug_Print("[ClanTagChanged] Setted tag: %s ", selectedTags[client].ScoreTag);
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

public void OnClientDisconnect(int client)
{
	ResetTags(client);
	iRank[client] = -1;
	bHideTag[client] = false;
	sUserTag[client][0] = '\0';
	delete userTags[client];
}

public void warden_OnWardenCreated(int client)
{
	RequestFrame(Frame_LoadTag, client);
}

public void warden_OnWardenRemoved(int client)
{
	SetClientScoreTag(client, sUserTag[client]);
	
	RequestFrame(Frame_LoadTag, client);
	
}

public Action Cmd_Anonymous(int client, int args)
{
	if (!AreClientCookiesCached(client))
	{
		ReplyToCommand(client, "[SM] Cookie还没有加载，请稍等片刻.");
		return Plugin_Handled;
	}
	
	bIsAnonymous[client] = !bIsAnonymous[client];
	
	char sCookieValue[4];
	IntToString(bIsAnonymous[client], sCookieValue, sizeof(sCookieValue));
	SetClientCookie(client, hVibilityAdminsCookie, sCookieValue);
	LoadTags(client);
	
	
	if (bIsAnonymous[client])
	{
		ReplyToCommand(client, "[SM] 你现在是匿名的. 你的分数称号是 %s", selectedTags[client].ScoreTag);
	}
	else
	{
		ReplyToCommand(client, "[SM] 你现在已经不在匿名模式了. 你的分数称号是 %s", selectedTags[client].ScoreTag);
	}
	
	return Plugin_Handled;
}

public void warden_OnDeputyCreated(int client)
{
	RequestFrame(Frame_LoadTag, client);
}

public void warden_OnDeputyRemoved(int client)
{
	SetClientScoreTag(client, sUserTag[client]);
	
	RequestFrame(Frame_LoadTag, client);
}

//Commands
public Action Cmd_ReloadTags(int client, int args)
{
	LoadKv();
	for (int i = 1; i <= MaxClients; i++)if (IsClientInGame(i))LoadTags(i);
	
	ReplyToCommand(client, "[SM] 称号成功被加载!");
	return Plugin_Handled;
}

public Action Cmd_ToggleTags(int client, int args)
{
	if (bHideTag[client])
	{
		bHideTag[client] = false;
		LoadTags(client);
		ReplyToCommand(client, "[SM] 你的称号已经能被看见.");
	}
	else
	{
		bHideTag[client] = true;
		SetClientScoreTag(client, sUserTag[client]);
		ReplyToCommand(client, "[SM] 你的称号已经不可见.");
	}
	
	SetClientCookie(client, hVibilityCookie, bHideTag[client] ? "0" : "1");
	return Plugin_Handled;
}

public Action Cmd_TagsList(int client, int args)
{
	LoadTags(client);
	if (!client)
	{
		ReplyToCommand(client, "[SM] 这命令只能在游戏中使用.");
		return Plugin_Handled;
	}
	
	if (userTags[client] == null)
	{
		ReplyToCommand(client, "[SM] 称号还没有加载.");
		return Plugin_Handled;
	}
	
	if (!cv_bEnableTagsList.BoolValue)
	{
		ReplyToCommand(client, "[SM] 这项功能没有启用.");
		return Plugin_Handled;
	}
	
	if (userTags[client].Length == 0)
	{
		ReplyToCommand(client, "[SM] 没有获得任何称号.");
		return Plugin_Handled;
	}
	
	Menu menu = new Menu(Handler_TagsMenu);
	menu.SetTitle("选择你的称号:");
	static char sIndex[16];
	int len = userTags[client].Length;
	CustomTags tags;
	for (int i = 0; i < len; i++)
	{
		userTags[client].GetArray(i, tags, sizeof(tags));
		IntToString(i, sIndex, sizeof(sIndex));
		menu.AddItem(sIndex, tags.TagName);
	}
	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public int Handler_TagsMenu(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	else if (action == MenuAction_Select)
	{
		static char sIndex[16];
		menu.GetItem(param2, sIndex, sizeof(sIndex));
		userTags[param1].GetArray(StringToInt(sIndex), selectedTags[param1], sizeof(CustomTags));
		if(StrContains(selectedTags[param1].ScoreTag, "<自定义称号>", false) != -1)
		{
			ClientCommand(param1,"sm_applytags");
			return 1;
		}
		else if (selectedTags[param1].ScoreTag[0] != '\0')
		{
			SetClientScoreTag(param1, selectedTags[param1].ScoreTag);
		}
		iSelTagId[param1] = selectedTags[param1].SectionId;
		
		static char sValue[32];
		IntToString(iSelTagId[param1], sValue, sizeof(sValue));
		SetClientCookie(param1, hSelTagCookie, sValue);
		PrintToChat(param1, "%t", "Hextags_SMTitleSetSuccessfully", selectedTags[param1].TagName);
	}
	return 0;
}

public Action Cmd_GetTeam(int client, int args)
{
	if (!client)
	{
		ReplyToCommand(client, "[SM] 必须在游戏中才能使用.");
		return Plugin_Handled;
	}
	
	char sTeam[32];
	GetTeamName(GetClientTeam(client), sTeam, sizeof(sTeam));
	ReplyToCommand(client, "[SM] 当前队伍名字是: %s", sTeam);
	return Plugin_Handled;
}

#if defined DEBUG
public Action Cmd_GetVars(int client, int args)
{
	ReplyToCommand(client, selectedTags[client].ScoreTag);
	ReplyToCommand(client, selectedTags[client].ChatTag);
	ReplyToCommand(client, selectedTags[client].ChatColor);
	ReplyToCommand(client, selectedTags[client].NameColor);
	return Plugin_Handled;
}

public Action Cmd_FireSel(int client, int args)
{
	int count = pfCustomSelector.FunctionCount;
	int res;
	
	Call_StartForward(pfCustomSelector);
	Call_PushCell(client);
	Call_PushString("thistoggle");
	Call_Finish(res);
	ReplyToCommand(client, "[SM] Fire %i functions, res: %i!", count, res);
	return Plugin_Handled;
}
#endif

//Events
public void OnClientPutInServer(int client)
{
	delete userTags[client];
	userTags[client] = new ArrayList(sizeof(CustomTags));
}

public void OnClientPostAdminCheck(int client)
{
	LoadTags(client);
}

public void OnClientCookiesCached(int client)
{
	if (!IsValidClient(client, false, true))
		return;
	
	// HideTag cookie
	static char sValue[32];
	GetClientCookie(client, hVibilityCookie, sValue, sizeof(sValue));
	
	bHideTag[client] = sValue[0] == '\0' ? false : !StringToInt(sValue);
	
	// Selected tag Cookie
	GetClientCookie(client, hSelTagCookie, sValue, sizeof(sValue));
	if (sValue[0] != '\0')
	{
		int id = StringToInt(sValue);
		if (!id)
		{
			LogError("Invalid id: %s", sValue);
		}
		iSelTagId[client] = id;
	}
	
	
	// Anonymous cookie
	GetClientCookie(client, hVibilityAdminsCookie, sValue, sizeof(sValue));
	int cookieValue = StringToInt(sValue);
	bIsAnonymous[client] = cookieValue == 1;

	LoadTags(client);
	return;
}

public Action RankMe_OnPlayerLoaded(int client)
{
	RankMe_GetRank(client, RankMe_LoadTags);
	return Plugin_Continue;
}

public Action RankMe_OnPlayerSaved(int client)
{
	RankMe_GetRank(client, RankMe_LoadTags);
	return Plugin_Continue;
}

public Action RankMe_LoadTags(int client, int rank, any data)
{
	Debug_Print("Callback load rankme-tags");
	if (IsValidClient(client, true, true))
	{
		iRank[client] = rank;
		Debug_Print("Callback valid rank %L - %i", client, rank);
		char sRank[16];
		IntToString(iRank[client], sRank, sizeof(sRank));
		
		if (selectedTags[client].ScoreTag[0] == '\0')
			return Plugin_Continue;
		
		ReplaceString(selectedTags[client].ScoreTag, sizeof(CustomTags::ScoreTag), "{rmRank}", sRank);
		SetClientScoreTag(client, selectedTags[client].ScoreTag); //Instantly load the score-tag
	}
	return Plugin_Continue;
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	bHasRoundEnded = true;
	if (!cv_bParseRoundEnd.BoolValue)
		return;
	
	for (int i = 1; i <= MaxClients; i++)if (IsClientInGame(i))OnClientPostAdminCheck(i);
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	delete hRoundStatusTimer;
	hRoundStatusTimer = CreateTimer(5.0, ChangeRoundStatus);
}

public Action ChangeRoundStatus(Handle timer)
{
	bHasRoundEnded = false;
	hRoundStatusTimer = null;
	return Plugin_Stop;
}

public void OnMapEnd() // required, because forcible change level doesn't fire "round_end" event
{
	delete hRoundStatusTimer;
}

public Action CP_OnChatMessage(int & author, ArrayList recipients, char[] flagstring, char[] name, char[] message, bool & processcolors, bool & removecolors)
{
	Debug_Setup(true, false, false, true); // Disable chat.
	if (bHideTag[author])
	{
		return Plugin_Continue;
	}
	
	Action result = Plugin_Continue;
	//Call the forward
	Call_StartForward(fMessagePreProcess);
	Call_PushCell(author);
	Call_PushStringEx(name, MAXLENGTH_NAME, SM_PARAM_STRING_UTF8 | SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_PushStringEx(message, MAXLENGTH_MESSAGE, SM_PARAM_STRING_UTF8 | SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_Finish(result);
	
	if (result >= Plugin_Handled)
	{
		return Plugin_Continue;
	}
	
	//Add colors & tags
	char sNewName[MAXLENGTH_NAME];
	char sNewMessage[MAXLENGTH_MESSAGE];
	// Rainbow name
	if (StrEqual(selectedTags[author].NameColor, "{rainbow}"))
	{
		Debug_Print("Rainbow name");
		char sTemp[MAXLENGTH_MESSAGE];
		
		int color;
		int len = strlen(name);
		for (int i = 0; i < len; i++)
		{
			if (IsCharSpace(name[i]))
			{
				Format(sTemp, sizeof(sTemp), "%s%c", sTemp, name[i]);
				continue;
			}
			
			int bytes = GetCharBytes(name[i]) + 1;
			char[] c = new char[bytes];
			strcopy(c, bytes, name[i]);
			Format(sTemp, sizeof(sTemp), "%s%c%s", sTemp, GetColor(++color), c);
			if (IsCharMB(name[i]))
				i += bytes - 2;
		}
		Format(sNewName, MAXLENGTH_NAME, "%s%s{default}", selectedTags[author].ChatTag, sTemp);
	}
	else if (StrEqual(selectedTags[author].NameColor, "{random}")) //Random name
	{
		Debug_Print("Random name");
		char sTemp[MAXLENGTH_MESSAGE];
		
		int len = strlen(name);
		for (int i = 0; i < len; i++)
		{
			if (IsCharSpace(name[i]))
			{
				Format(sTemp, sizeof(sTemp), "%s%c", sTemp, name[i]);
				continue;
			}
			
			int bytes = GetCharBytes(name[i]) + 1;
			char[] c = new char[bytes];
			strcopy(c, bytes, name[i]);
			Format(sTemp, sizeof(sTemp), "%s%c%s", sTemp, GetRandomColor(), c);
			if (IsCharMB(name[i]))
				i += bytes - 2;
		}
		Format(sNewName, MAXLENGTH_NAME, "%s%s{default}", selectedTags[author].ChatTag, sTemp);
	}
	else
	{
		Debug_Print("Default name");
		Format(sNewName, MAXLENGTH_NAME, "%s%s%s{default}", selectedTags[author].ChatTag, selectedTags[author].NameColor, name);
	}
	Format(sNewMessage, MAXLENGTH_MESSAGE, "%s%s", selectedTags[author].ChatColor, message);
	
	//Update the params
	static char sTime[16];
	FormatTime(sTime, sizeof(sTime), "%H:%M");
	ReplaceString(sNewName, sizeof(sNewName), "{time}", sTime);
	ReplaceString(sNewMessage, sizeof(sNewMessage), "{time}", sTime);
	
	
	static char sIP[32];
	static char sCountry[3];
	GetClientIP(author, sIP, sizeof(sIP));
	GeoipCode2(sIP, sCountry);
	ReplaceString(sNewName, sizeof(sNewName), "{country}", sCountry);
	ReplaceString(sNewMessage, sizeof(sNewMessage), "{country}", sCountry);
	
	if (bGangs)
	{
		Debug_Print("Apply gans");
		static char sGang[32];
		Gangs_HasGang(author) ? Gangs_GetGangName(author, sGang, sizeof(sGang)) : cv_sDefaultGang.GetString(sGang, sizeof(sGang));
		
		ReplaceString(sNewName, sizeof(sNewName), "{gang}", sGang);
		ReplaceString(sNewMessage, sizeof(sNewMessage), "{gang}", sGang);
	}
	
	if (bRankme)
	{
		Debug_Print("Apply rankme");
		static char sPoints[16];
		IntToString(RankMe_GetPoints(author), sPoints, sizeof(sPoints));
		ReplaceString(sNewName, sizeof(sNewName), "{rmPoints}", sPoints);
		ReplaceString(sNewMessage, sizeof(sNewMessage), "{rmPoints}", sPoints);
		
		static char sRank[16];
		IntToString(iRank[author], sRank, sizeof(sRank));
		ReplaceString(sNewName, sizeof(sNewName), "{rmRank}", sRank);
		ReplaceString(sNewMessage, sizeof(sNewMessage), "{rmRank}", sRank);
	}
	
	//Rainbow Chat
	if (StrEqual(selectedTags[author].ChatColor, "{rainbow}", false))
	{
		Debug_Print("Rainbow chat");
		ReplaceString(sNewMessage, sizeof(sNewMessage), "{rainbow}", "");
		char sTemp[MAXLENGTH_MESSAGE];
		
		int color;
		int len = strlen(sNewMessage);
		for (int i = 0; i < len; i++)
		{
			if (IsCharSpace(sNewMessage[i]))
			{
				Format(sTemp, sizeof(sTemp), "%s%c", sTemp, sNewMessage[i]);
				continue;
			}
			
			int bytes = GetCharBytes(sNewMessage[i]) + 1;
			char[] c = new char[bytes];
			strcopy(c, bytes, sNewMessage[i]);
			Format(sTemp, sizeof(sTemp), "%s%c%s", sTemp, GetColor(++color), c);
			if (IsCharMB(sNewMessage[i]))
				i += bytes - 2;
		}
		Format(sNewMessage, MAXLENGTH_MESSAGE, "%s", sTemp);
	}
	
	//Random Chat
	if (StrEqual(selectedTags[author].ChatColor, "{random}", false))
	{
		Debug_Print("Random chat");
		ReplaceString(sNewMessage, sizeof(sNewMessage), "{random}", "");
		char sTemp[MAXLENGTH_MESSAGE];
		
		int len = strlen(sNewMessage);
		for (int i = 0; i < len; i++)
		{
			if (IsCharSpace(sNewMessage[i]))
			{
				Format(sTemp, sizeof(sTemp), "%s%c", sTemp, sNewMessage[i]);
				continue;
			}
			
			int bytes = GetCharBytes(sNewMessage[i]) + 1;
			char[] c = new char[bytes];
			strcopy(c, bytes, sNewMessage[i]);
			Format(sTemp, sizeof(sTemp), "%s%c%s", sTemp, GetRandomColor(), c);
			if (IsCharMB(sNewMessage[i]))
				i += bytes - 2;
		}
		Format(sNewMessage, MAXLENGTH_MESSAGE, "%s", sTemp);
	}
	
	static char sPassedName[MAXLENGTH_NAME];
	static char sPassedMessage[MAXLENGTH_NAME];
	sPassedName = sNewName;
	sPassedMessage = sNewMessage;
	
	
	result = Plugin_Continue;
	//Call the forward
	Call_StartForward(fMessageProcess);
	Call_PushCell(author);
	Call_PushStringEx(sPassedName, sizeof(sPassedName), SM_PARAM_STRING_UTF8 | SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_PushStringEx(sPassedMessage, sizeof(sPassedMessage), SM_PARAM_STRING_UTF8 | SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_Finish(result);
	
	if (result == Plugin_Continue)
	{
		//Update the name & message
		strcopy(name, MAXLENGTH_NAME, sNewName);
		strcopy(message, MAXLENGTH_MESSAGE, sNewMessage);
	}
	else if (result == Plugin_Changed)
	{
		//Update the name & message
		strcopy(name, MAXLENGTH_NAME, sPassedName);
		strcopy(message, MAXLENGTH_MESSAGE, sPassedMessage);
	}
	else
	{
		Debug_Setup();
		return Plugin_Continue;
	}
	
	processcolors = true;
	removecolors = false;
	
	//Call the (post)forward
	Call_StartForward(fMessageProcessed);
	Call_PushCell(author);
	Call_PushString(sPassedName);
	Call_PushString(sPassedMessage);
	Call_Finish();
	
	
	Debug_Print("Message sent");
	Debug_Setup();
	return Plugin_Changed;
}

//Functions
void LoadKv()
{
	static char sConfig[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sConfig, sizeof(sConfig), "configs/hextags.cfg"); //Get cfg file
	
	if (OpenFile(sConfig, "rt") == null)
		SetFailState("Couldn't find: \"%s\"", sConfig); //Check if cfg exist
	
	KeyValues kv = new KeyValues("HexTags"); //Create the kv
	
	if (!kv.ImportFromFile(sConfig))
		SetFailState("Couldn't import: \"%s\"", sConfig); //Check if file was imported properly
	
	if (!kv.GotoFirstSubKey())
		LogMessage("No entries found in: \"%s\"", sConfig); //Notify that there aren't any entries
	
	delete kv;
	strcopy(sTagConf, sizeof(sTagConf), sConfig);
	delete tagsKv;
}
public Action LoadTags1(Handle Timer,int client){
	LoadTags(client);
	return Plugin_Stop;
}
void LoadTags(int client)
{
	if (bHideTag[client])
		return;
	
	if (!IsValidClient(client, false, true))
		return;
	
	//Clear the tags when re-checking
	ResetTags(client);
	
	if (tagsKv == null)
	{
		tagsKv = new KeyValues("HexTags");
		tagsKv.ImportFromFile(sTagConf);
		Debug_Print("KeyValue handle: %i", tagsKv);
	}
	tagsKv.Rewind();
	if (userTags[client] == null)
	{
		userTags[client] = new ArrayList(sizeof(CustomTags));
	}
	ParseConfig(tagsKv, client);
	
	if (userTags[client].Length > 0)
	{
		if (iSelTagId[client] == 0 || !cv_bEnableTagsList.BoolValue)
		{
			userTags[client].GetArray(0, selectedTags[client], sizeof(CustomTags));
			SetClientScoreTag(client, selectedTags[client].ScoreTag);
			return;
		}
		tagsKv.Rewind();
		if (!tagsKv.JumpToKeySymbol(iSelTagId[client]))
		{
			SetClientCookie(client, hSelTagCookie, "");
			userTags[client].GetArray(0, selectedTags[client], sizeof(CustomTags));
			SetClientScoreTag(client, selectedTags[client].ScoreTag);
			return;
		}
		// Key found
		int len = userTags[client].Length;
		CustomTags tags;
		
		for (int i = 0; i < len; i++)
		{
			userTags[client].GetArray(i, tags, sizeof(CustomTags));
			if (tags.SectionId == iSelTagId[client])
			{
				selectedTags[client] = tags;
				if (selectedTags[client].ScoreTag[0] == '\0')
					return;
				
				SetClientScoreTag(client, selectedTags[client].ScoreTag);
				return;
			}
		}
	}
}

void ParseConfig(KeyValues kv, int client)
{
	userTags[client].Clear();
	static char sSectionName[64];
	do
	{
		if (kv.GotoFirstSubKey())
		{
			kv.GetSectionName(sSectionName, sizeof(sSectionName));
			Debug_Print("Current key: %s", sSectionName);
			
			if (CheckSelector(sSectionName, client))
			{
				Debug_Print("*******FOUND VALID SELECTOR -> %s.", sSectionName);
				ParseConfig(kv, client);
			}
		}
		else
		{
			kv.GetSectionName(sSectionName, sizeof(sSectionName));
			if (!CheckSelector(sSectionName, client))
			{
				continue;
			}
			Debug_Print("***********SETTINGS TAGS", sSectionName);
			GetTags(client, kv);
		}
	} while (kv.GotoNextKey());
	Debug_Print("-- Section end --");
}

bool CheckSelector(const char[] selector, int client)
{
	char sCookieValue[12];
	GetClientCookie(client, hIsAnonymousCookie, sCookieValue, sizeof(sCookieValue));
	int cookieValue = StringToInt(sCookieValue);
	/* CHECK DEFAULT */
	if (StrEqual(selector, "default", false))
	{
		return true;
	}
	
	/* CHECK HUMAN */
	if (StrEqual(selector, "human", false) && !IsFakeClient(client))
	{
		return true;
	}
	
	/* CHECK BOT */
	if (StrEqual(selector, "bot", false) && IsFakeClient(client))
	{
		return true;
	}
	
	/* CHECK STEAMID */
	if (strlen(selector) > 11 && StrContains(selector, "STEAM_", true) == 0 && !bIsAnonymous[client])
	{
		char steamid[32];
		if ((!GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid))) || (cookieValue == 1))
			return false;
		
		if (StrEqual(steamid, selector))
		{
			return true;
		}
		
		//Replace the STEAM_1 to STEAM_0 or viceversa
		(steamid[6] == '1') ? (steamid[6] = '0') : (steamid[6] = '1');
		if (StrEqual(steamid, selector))
		{
			return true;
		}
	}
	
	
	/* PERMISSIONS RELATED CHECKS */
	AdminId admin = GetUserAdmin(client);
	if (admin != INVALID_ADMIN_ID)
	{
		Debug_Print("Found as admin! %N", client);
		/* CHECK ADMIN GROUP */
		if (selector[0] == '@' && !bIsAnonymous[client])
		{
			Debug_Print("Check group: %s", selector);
			static char sGroup[32];
			
			GroupId group = admin.GetGroup(0, sGroup, sizeof(sGroup));
			if (group != INVALID_GROUP_ID)
			{
				if (cookieValue == 1)
				{
					return false;
				}
				if (StrEqual(selector[1], sGroup))
				{
					return true;
				}
			}
		}
		
		/* CHECK ADMIN FLAGS (1)*/
		if (strlen(selector) == 1 && !bIsAnonymous[client])
		{
			Debug_Print("Check for flag (1char): ", selector);
			AdminFlag flag;
			if (FindFlagByChar(CharToLower(selector[0]), flag))
			{
				if (cookieValue == 1)
				{
					return false;
				}
				if (admin.HasFlag(flag))
				{
					return true;
				}
			}
		}
		
		/* CHECK ADMIN FLAGS (2)*/
		if (selector[0] == '&' && !bIsAnonymous[client])
		{
			Debug_Print("Check group: %s", selector);
			for (int i = 1; i < strlen(selector); i++)
			{
				AdminFlag flag;
				if (FindFlagByChar(selector[i], flag))
				{
					
					if (cookieValue == 1)
					{
						return false;
					}
					if (admin.HasFlag(flag))
					{
						return true;
					}
				}
			}
		}
		Debug_Print("Unmatched admin: %s", selector);
	}
	
	/* CHECK PLAYER TEAM */
	int team = GetClientTeam(client);
	static char sTeam[32];
	
	GetTeamName(team, sTeam, sizeof(sTeam));
	if (StrEqual(sTeam, selector))
	{
		return true;
	}
	
	/* CHECK playerpoints */
	if (selector[0] == '#' && !IsFakeClient(client))
	{
		int iPlayPoints = l4dstats_GetClientScore(client);
		//int iPlayPoints = GetPlayTotalpoints(client);
		Debug_Print("当前分数为: %i", iPlayPoints);
		if (iPlayPoints >= StringToInt(selector[1]))
		{
			return true;
		}
	}
	
	/* CHECK WARDEN */
	if (bWarden && StrEqual(selector, "warden", false) && warden_iswarden(client))
	{
		return true;
	}
	
	/* CHECK DEPUTY */
	if (bMyJBWarden && StrEqual(selector, "deputy", false) && warden_deputy_isdeputy(client))
	{
		return true;
	}
	
	/* CHECK PRIME */
	if (bSteamWorks && StrEqual(selector, "NoPrime", false))
	{
		if (k_EUserHasLicenseResultDoesNotHaveLicense == SteamWorks_HasLicenseForApp(client, 624820))
		{
			return true;
		}
	}
	
	/* CHECK GANG */
	if (bGangs && StrEqual(selector, "Gang", false) && Gangs_HasGang(client))
	{
		return true;
	}
	
	/* CHECK RANKME */
	if (bRankme && selector[0] == '!')
	{
		int iPoints = RankMe_GetPoints(client);
		if (iPoints >= StringToInt(selector[1]))
		{
			return true;
		}
	}
	
	/* CHECK STEAM GROUP */
	if (bSteamWorks && selector[0] == '$')
	{
		if (SteamWorks_GetUserGroupStatus(client, selector[1]))
		{
			return true;
		}
	}
	
	
	bool res = false;
	
	Call_StartForward(pfCustomSelector);
	Call_PushCell(client);
	Call_PushString(selector);
	Call_Finish(res);
	
	return res;
}


//Timers
public Action Timer_ForceTag(Handle timer)
{
	if (!bCanUseClanTags)
		return Plugin_Continue;
	
	for (int i = 1; i <= MaxClients; i++)if (IsClientInGame(i) && selectedTags[i].ForceTag && selectedTags[i].ScoreTag[0] != '\0' && !bHideTag[i])
	{
		char sTag[32];
		CS_GetClientClanTag(i, sTag, sizeof(sTag));
		if (StrEqual(sTag, selectedTags[i].ScoreTag))
			continue;
		
		if (!bHasRoundEnded) {
			LogMessage("%L was changed by an external plugin, forcing him back to the HexTags' default one!", i, sTag);
		}
		
		SetClientScoreTag(i, selectedTags[i].ScoreTag);
	}
	return Plugin_Continue;
}

//Frames
public void Frame_LoadTag(any client)
{
	LoadTags(client);
}



//Stocks
void GetTags(int client, KeyValues kv)
{
	static char sSection[64];
	static char sDef[8];
	IntToString(iNextDefTag++, sDef, sizeof(sDef));
	
	kv.GetSectionName(sSection, sizeof(sSection));
	Debug_Print("Section: %s", sSection);
	int id;
	if (!kv.GetSectionSymbol(id))
	{
		LogError("Unable to get section symbol.");
	}
	
	CustomTags tags;
	
	tags.SectionId = id;
	kv.GetString("TagName", tags.TagName, sizeof(CustomTags::TagName), sDef);
	kv.GetString("ScoreTag", tags.ScoreTag, sizeof(CustomTags::ScoreTag), "");
	kv.GetString("ChatTag", tags.ChatTag, sizeof(CustomTags::ChatTag), "");
	kv.GetString("ChatColor", tags.ChatColor, sizeof(CustomTags::ChatColor), "");
	kv.GetString("NameColor", tags.NameColor, sizeof(CustomTags::NameColor), "{teamcolor}");
	tags.ForceTag = kv.GetNum("ForceTag", 1) == 1;
	
	
	Call_StartForward(fTagsUpdated);
	Call_PushCell(client);
	Call_Finish();
	
	if (tags.ScoreTag[0] != '\0' && bCanUseClanTags)
	{
		//Update params
		if (StrContains(tags.ScoreTag, "{country}") != -1)
		{
			static char sIP[32];
			static char sCountry[3];
			if (!GetClientIP(client, sIP, sizeof(sIP)))
				LogError("Unable to get %L ip!", client);
			GeoipCode2(sIP, sCountry);
			ReplaceString(tags.ScoreTag, sizeof(CustomTags::ScoreTag), "{country}", sCountry);
		}
		if (bGangs && StrContains(tags.ScoreTag, "{gang}") != -1)
		{
			static char sGang[32];
			Gangs_HasGang(client) ? Gangs_GetGangName(client, sGang, sizeof(sGang)) : cv_sDefaultGang.GetString(sGang, sizeof(sGang));
			ReplaceString(tags.ScoreTag, sizeof(CustomTags::ScoreTag), "{gang}", sGang);
		}
		if (bRankme && StrContains(tags.ScoreTag, "{rmPoints}") != -1)
		{
			static char sPoints[16];
			IntToString(RankMe_GetPoints(client), sPoints, sizeof(sPoints));
			ReplaceString(tags.ScoreTag, sizeof(CustomTags::ScoreTag), "{rmPoints}", sPoints);
		}
		if (bRankme && StrContains(tags.ScoreTag, "{rmRank}") != -1)
		{
			Debug_Print("Contains rmRank");
			RankMe_GetRank(client, RankMe_LoadTags);
		}
		
		Debug_Print("Setted tag: %s", tags.ScoreTag);
		SetClientScoreTag(client, tags.ScoreTag); //Instantly load the score-tag
	}
	if (StrContains(tags.ChatTag, "{rainbow}") == 0)
	{
		Debug_Print("Found {rainbow} in ChatTag");
		ReplaceString(tags.ChatTag, sizeof(CustomTags::ChatTag), "{rainbow}", "");
		char sTemp[MAXLENGTH_MESSAGE];
		
		int color;
		int len = strlen(tags.ChatTag);
		for (int i = 0; i < len; i++)
		{
			if (IsCharSpace(tags.ChatTag[i]))
			{
				Format(sTemp, sizeof(sTemp), "%s%c", sTemp, tags.ChatTag[i]);
				continue;
			}
			
			int bytes = GetCharBytes(tags.ChatTag[i]) + 1;
			char[] c = new char[bytes];
			strcopy(c, bytes, tags.ChatTag[i]);
			Format(sTemp, sizeof(sTemp), "%s%c%s", sTemp, GetColor(++color), c);
			if (IsCharMB(tags.ChatTag[i]))
				i += bytes - 2;
		}
		strcopy(tags.ChatTag, sizeof(CustomTags::ChatTag), sTemp);
		Debug_Print("Replaced ChatTag with %s", tags.ChatTag);
	}
	if (StrContains(tags.ChatTag, "{random}") == 0)
	{
		ReplaceString(tags.ChatTag, sizeof(CustomTags::ChatTag), "{random}", "");
		char sTemp[MAXLENGTH_MESSAGE];
		int len = strlen(tags.ChatTag);
		for (int i = 0; i < len; i++)
		{
			if (IsCharSpace(tags.ChatTag[i]))
			{
				Format(sTemp, sizeof(sTemp), "%s%c", sTemp, tags.ChatTag[i]);
				continue;
			}
			
			int bytes = GetCharBytes(tags.ChatTag[i]) + 1;
			char[] c = new char[bytes];
			strcopy(c, bytes, tags.ChatTag[i]);
			Format(sTemp, sizeof(sTemp), "%s%c%s", sTemp, GetRandomColor(), c);
			if (IsCharMB(tags.ChatTag[i]))
				i += bytes - 2;
		}
		strcopy(tags.ChatTag, sizeof(CustomTags::ChatTag), sTemp);
	}
	Debug_Print("Succesfully setted tags");
	userTags[client].PushArray(tags, sizeof(tags));
}

void ResetTags(int client)
{
	strcopy(selectedTags[client].ScoreTag, sizeof(CustomTags::ScoreTag), "");
	strcopy(selectedTags[client].ChatTag, sizeof(CustomTags::ChatTag), "");
	strcopy(selectedTags[client].ChatColor, sizeof(CustomTags::ChatColor), "");
	strcopy(selectedTags[client].NameColor, sizeof(CustomTags::NameColor), "");
	selectedTags[client].ForceTag = true;
}

int GetRandomColor()
{
	switch (GetRandomInt(1, 16))
	{
		case 1:return '\x01';
		case 2:return '\x02';
		case 3:return '\x03';
		case 4:return '\x03';
		case 5:return '\x04';
		case 6:return '\x05';
		case 7:return '\x06';
		case 8:return '\x07';
		case 9:return '\x08';
		case 10:return '\x09';
		case 11:return '\x10';
		case 12:return '\x0A';
		case 13:return '\x0B';
		case 14:return '\x0C';
		case 15:return '\x0E';
		case 16:return '\x0F';
	}
	return '\x01';
}

int GetColor(int color)
{
	switch (color % 7)
	{
		case 0:return '\x02';
		case 1:return '\x10';
		case 2:return '\x09';
		case 3:return '\x06';
		case 4:return '\x0B';
		case 5:return '\x0C';
		case 6:return '\x0E';
	}
	return '\x01';
}

//API
public int Native_GetClientTag(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	if (client < 1 || client > MaxClients)
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
	}
	if (!IsClientConnected(client))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not connected", client);
	}
	
	eTags tag = view_as<eTags>(GetNativeCell(2));
	switch (tag)
	{
		case (ScoreTag):
		{
			SetNativeString(3, selectedTags[client].ScoreTag, GetNativeCell(4));
		}
		case (ChatTag):
		{
			SetNativeString(3, selectedTags[client].ChatTag, GetNativeCell(4));
		}
		case (ChatColor):
		{
			SetNativeString(3, selectedTags[client].ChatColor, GetNativeCell(4));
		}
		case (NameColor):
		{
			SetNativeString(3, selectedTags[client].NameColor, GetNativeCell(4));
		}
	}
	return 0;
}

public int Native_SetClientTag(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	if (client < 1 || client > MaxClients)
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
	}
	if (!IsClientConnected(client))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not connected", client);
	}
	
	char sTag[64];
	eTags tag = view_as<eTags>(GetNativeCell(2));
	
	GetNativeString(3, sTag, sizeof(sTag));
	ReplaceString(sTag, sizeof(sTag), "{darkgray}", "{gray2}");
	
	switch (tag)
	{
		case (ScoreTag):
		{
			strcopy(selectedTags[client].ScoreTag, sizeof(CustomTags::ScoreTag), sTag);
			SetClientScoreTag(client, selectedTags[client].ScoreTag);
		}
		case (ChatTag):
		{
			strcopy(selectedTags[client].ChatTag, sizeof(CustomTags::ChatTag), sTag);
		}
		case (ChatColor):
		{
			strcopy(selectedTags[client].ChatColor, sizeof(CustomTags::ChatColor), sTag);
		}
		case (NameColor):
		{
			strcopy(selectedTags[client].NameColor, sizeof(CustomTags::NameColor), sTag);
		}
	}
	
	
	Debug_Print("Called Native_SetClientTag(%i, %i, %s)", client, tag, sTag);
	
	//	strcopy(selectedTags[client][Tag], sizeof(sTags[][]), sTag);
	return 0;
}

public int Native_ResetClientTags(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	if (client < 1 || client > MaxClients)
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
	}
	if (!IsClientConnected(client))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not connected", client);
	}
	
	LoadTags(client);
	return 0;
}

public int Native_AddCustomSelector(Handle plugin, int numParams)
{
	return pfCustomSelector.AddFunction(plugin, GetNativeFunction(1));
}

public int Native_RemoveCustomSelector(Handle plugin, int numParams)
{
	return pfCustomSelector.RemoveFunction(plugin, GetNativeFunction(1));
}

void SetClientScoreTag(int client, const char[] tag)
{
	if (!bCanUseClanTags || !IsValidClient(client, true, true))
		return;

	CS_SetClientClanTag(client, tag);
}


/* From smlib */
stock void String_ToLower(const char[] input, char[] output, int size)
{
	size--;
	
	int x = 0;
	while (input[x] != '\0' && x < size) {
		
		output[x] = CharToLower(input[x]);
		
		x++;
	}
	
	output[x] = '\0';
}
