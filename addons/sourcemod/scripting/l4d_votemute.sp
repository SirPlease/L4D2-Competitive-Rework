#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <geoip>

#define PLUGIN_VERSION "2.5"

#define CVAR_FLAGS		FCVAR_NOTIFY

public Plugin myinfo = 
{
	name = "[L4D] Votemute / Votegag (no black screen)",
	author = "Dragokas",
	description = "Vote for player mute (microphone) or gag (chat) with translucent menu",
	version = PLUGIN_VERSION,
	url = "https://github.com/dragokas"
};

/*
	This plugin is based on "[L4D] Votekick (no black screen)" by Dragokas.
	
	Some forwards and commands used from BaseComm:

	- SetListenOverride(i, client, Listen_No);
	- sm_mute
	- sm_gag
	- sm_silence
	
	- SetClientListeningFlags(client, VOICE_MUTED);
	- SetClientListeningFlags(client, VOICE_NORMAL);
	
	====================================================================================
	
	Description:
	 - This plugin adds ability to vote for voice mute and chat mute.
	
	Features:
	 - translucent vote menu.
	 - mute for 1 hour (adjustable) even if player used trick to quit the game before vote ends.
	 - vote announcement
	 - flexible configuration of access rights
	 - all actions are logged (who mute, whom mute, who tried to mute ...)
	
	Logfile location:
	 - logs/vote_mute.log

	Permissions:
	 - by default, vote can be started by everybody (adjustable) if immunity and player count checks passed.
	 - ability to set minimum time to allow repeat the vote.
	 - ability to set minimum players count to allow starting the vote.
	 - admins cannot target root admin.
	
	Requirements:
	 - GeoIP extension (included in SourceMod).
	 - SourceMod Communication Plugin - Basecomm.smx (included in SourceMod).
	 - (optionally) SM v.1.11.
	
	Languages:
	 - Russian
	 - English
	
	----------------------
	
	ChangeLog:
	
	1.9
	 - Fixed "Invalid client index 0".
	 - Added permanent mute list (see source code - line "OnClientPutInServer").
	 
	1.10
	 - Added permanent mute list (in PRIVATE_STUFF).
	 
	2.0 (23-Mar-2021)
	 - Added ability to see in menu who is currently speaking (available in SM v.1.11 only).
	 - Added ability to see in menu who was already muted / gagged.
	 - Added ability to unmute. Use the same menu.
	 - Added ability to gag/ungag (chat).
	 - New commands: !vg and alias !votegag.
	 - New ConVar "sm_votemute_gagtime" - How long player will be gagged (秒).
	 
	2.1 (28-Mar-2021)
	 - PRIVATE_STUFF is moved from source code to external files:
	  * "data/votemute_permanent_mute.txt" - to specify permanent mute list (STEAM id and player nicknames are allowed).
	  * "data/votemute_permanent_gag.txt" - to specify permanent list to block the chat (STEAM id and player nicknames are allowed).
	  * "data/votemute_vote_block.txt" - for specific players you may want to block the vote ability (STEAM id and player nicknames are allowed).
	 - Added ConVar "sm_votemute_vetoflag" - Admin flag required to veto/votepass the vote.
	
	2.2 (25-Apr-2021)
	 - Improved menu items display when the player's nickname contains bad characters.
	 
	2.2b (29-Apr-2021)
	 - OnClientPostAdminCheck() and OnClientPutInServer() are replaced by OnClientAuthorized() to re-check player as soon as Steam connection will be restored if Steam is down.
	 
	2.3 (22-Nov-2021)
	 - Added repeatable mute-delay check in OnClientAuthorized() since the player could have "not in game" status at the moment yet.
	
	2.4 (01-Jul-2022)
	 - Respect immunity level.
	 - Allowed to vote everybody against clients who located in deny list (regardless of vote access flag).
	 - Added compatibility with Auto-Name-Changer by Exle. "newnames.txt" file will be detected and merged to deny list.
	 - Improved performance on map start.
	 - Fixed compilation warnings on SM 1.11.
	
	2.5 (01-Jul-2022)
	 - Fix for previous update.
	 - Also, support for old version of Auto-Name-Changer with newnames.ini file name, instead of newnames.txt.
	
	TODO:
	 - Added ability to automatically mute player instantly if he joined with microphone on:
	 * Added ConVar "sm_votemute_instant_mute" - Use instant mute when somebody joined with microphone on (1 - Yes / 0 - No).
	 * Added ConVar "sm_votemute_instant_mute_wait" - Grace time in seconds waiting for player to switch off the microphone after he is joined (to prevent false-positives).
	 
*/

char g_sCharMicro[] = "☊";
char g_sCharMuted[] = "☓";

char FILE_PERMANENT_MUTE[PLATFORM_MAX_PATH] = "data/votemute_permanent_mute.txt";
char FILE_PERMANENT_GAG[PLATFORM_MAX_PATH] 	= "data/votemute_permanent_gag.txt";
char FILE_VOTE_BLOCK[PLATFORM_MAX_PATH]		= "data/votemute_vote_block.txt";
char FILE_ANC_BLOCK[PLATFORM_MAX_PATH];
char FILE_ANC_BLOCK_1[PLATFORM_MAX_PATH]	= "cfg/sourcemod/anc/newnames.ini"; // old version naming
char FILE_ANC_BLOCK_2[PLATFORM_MAX_PATH]	= "cfg/sourcemod/anc/newnames.txt";
char FILE_LOG[PLATFORM_MAX_PATH] 			= "logs/vote_mute.log";

enum VOTE_TYPE
{
	VOTE_TYPE_MUTE = 1,
	VOTE_TYPE_UNMUTE,
	VOTE_TYPE_GAG,
	VOTE_TYPE_UNGAG
}

StringMap hMapSteamMute, hMapSteamGag;
ArrayList g_hArrayPermMute, g_hArrayPermGag, g_hArrayVoteBlock;
char g_sIP[32], g_sCountry[4], g_sName[MAX_NAME_LENGTH], g_sLog[PLATFORM_MAX_PATH], g_sSteamId[64];
int g_iVoteTargetUserId, g_iSteamId, iLastTime[MAXPLAYERS+1], g_iMenuPage[MAXPLAYERS+1];
bool g_bVeto, g_bVotepass, g_bVoteInProgress, g_bVoteDisplayed, g_bBaseCommAvail, g_bClientSpeaking[MAXPLAYERS+1];
ConVar g_hCvarDelay, g_hCvarMuteTime, g_hCvarGagTime, g_hCvarHandleAdminMenu, g_hCvarAnnounceDelay, g_hCvarTimeout, g_hCvarLog;
ConVar g_hMinPlayers, g_hCvarAccessFlag, g_hCvarVetoFlag;
//ConVar g_hCvarInstaMute, g_hCvarInstaMuteWait;
Handle g_hTimerMenu[MAXPLAYERS+1];
Menu g_hMenu[MAXPLAYERS+1];
VOTE_TYPE g_eVoteType, g_eCliVoteType[MAXPLAYERS+1];

native bool BaseComm_SetClientMute(int client, bool bState);
native bool BaseComm_SetClientGag(int client, bool bState);
native bool BaseComm_IsClientMuted(int client);
native bool BaseComm_IsClientGagged(int client);

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	MarkNativeAsOptional("BaseComm_SetClientGag");
	MarkNativeAsOptional("BaseComm_SetClientMute");
	MarkNativeAsOptional("BaseComm_IsClientMuted");
	MarkNativeAsOptional("BaseComm_IsClientGagged");
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("core.phrases.txt");
	LoadTranslations("l4d_votemute.phrases");
	
	CreateConVar("l4d_votemute_version", PLUGIN_VERSION, "Version of L4D Votemute on this server", CVAR_FLAGS | FCVAR_DONTRECORD);
	
	g_hCvarDelay = CreateConVar(			"sm_votemute_delay",				"60",		" 投票之间允许的最小延迟(秒)", CVAR_FLAGS );
	g_hCvarTimeout = CreateConVar(			"sm_votemute_timeout",				"10",		"投票菜单持续的时间(秒)", CVAR_FLAGS );
	g_hCvarAnnounceDelay = CreateConVar(	"sm_votemute_announcedelay",		"2.0",		"提示和投票菜单出现的间隔(秒) between announce and vote menu appearing", CVAR_FLAGS );
	g_hCvarMuteTime = CreateConVar(			"sm_votemute_mutetime",				"3600",		"玩家被禁止语音的时间(秒)", CVAR_FLAGS );
	g_hCvarGagTime = CreateConVar(			"sm_votemute_gagtime",				"3600",		"玩家被禁止发言的时间(秒)", CVAR_FLAGS );
	g_hMinPlayers = CreateConVar(			"sm_votemute_minplayers",			"1",		"游戏中允许开始投票决定禁止发言的最低玩家人数", CVAR_FLAGS );
	g_hCvarAccessFlag = CreateConVar(		"sm_votemute_accessflag",			"",			"开始投票所需的管理员标志 (留空允许每个人都有)", CVAR_FLAGS );
	g_hCvarVetoFlag = CreateConVar(			"sm_votemute_vetoflag",				"d",		"否决/通过投票所需的管理员标志", CVAR_FLAGS );
	g_hCvarHandleAdminMenu = CreateConVar(	"sm_votemute_handleadminmenu",		"1",		"这个插件是否应该处理通过管理员菜单进行的静音/禁言? (1 - 是 / 0 - 否)", CVAR_FLAGS );
	g_hCvarLog = CreateConVar(				"sm_votemute_log",					"1",		"使用日志记录? (1 - 是 / 0 - 否)", CVAR_FLAGS );
	//g_hCvarInstaMute = CreateConVar(		"sm_votemute_instant_mute",			"1",		"当有人打开麦克风加入游戏时是否立刻禁止语音 (1 - 是 / 0 - 否)", CVAR_FLAGS );
	//g_hCvarInstaMuteWait = CreateConVar(	"sm_votemute_instant_mute_wait",	"5",		"玩家加入后等待关闭麦克风的宽限时间(秒)", CVAR_FLAGS );
	
	AutoExecConfig(true,				"sm_votemute");
	
	RegConsoleCmd("sm_votemute", 	Command_Votemute, 	"投票禁止/解禁玩家语音");
	RegConsoleCmd("sm_vm", 			Command_Votemute,	"投票禁止/解禁玩家语音");
	RegConsoleCmd("sm_votegag", 	Command_Votegag,	"投票禁止/解禁玩家发言");
	RegConsoleCmd("sm_vg", 			Command_Votegag,	"投票禁止/解禁玩家发言");
	
	RegConsoleCmd("sm_vetovm", 		Command_Veto, 		"管理员强制投票失败");
	RegConsoleCmd("sm_votepassvm", 	Command_Votepass, 	"管理员强制投票通过");
	
	hMapSteamMute = new StringMap();
	hMapSteamGag = new StringMap();
	
	g_hArrayPermMute = new ArrayList(ByteCountToCells(MAX_NAME_LENGTH));
	g_hArrayPermGag = new ArrayList(ByteCountToCells(MAX_NAME_LENGTH));
	g_hArrayVoteBlock = new ArrayList(ByteCountToCells(MAX_NAME_LENGTH));
	
	BuildPath(Path_SM, FILE_PERMANENT_MUTE, sizeof(FILE_PERMANENT_MUTE), FILE_PERMANENT_MUTE);
	BuildPath(Path_SM, FILE_PERMANENT_GAG, sizeof(FILE_PERMANENT_GAG), FILE_PERMANENT_GAG);
	BuildPath(Path_SM, FILE_VOTE_BLOCK, sizeof(FILE_VOTE_BLOCK), FILE_VOTE_BLOCK);
	BuildPath(Path_SM, g_sLog, sizeof(g_sLog), FILE_LOG);
	
	if( FileExists(FILE_ANC_BLOCK_1) )
	{
		FILE_ANC_BLOCK = FILE_ANC_BLOCK_1;
	}
	if( FileExists(FILE_ANC_BLOCK_2) )
	{
		FILE_ANC_BLOCK = FILE_ANC_BLOCK_2;
	}
}

void ReadFileToArrayList(char[] sFile, ArrayList list, bool bClearList = true)
{
	static char str[MAX_NAME_LENGTH];
	File hFile = OpenFile(sFile, "r");
	if( hFile == null )
	{
		SetFailState("Failed to open file: \"%s\". You are missing at installing!", sFile);
	}
	else {
		if( bClearList )
		{
			list.Clear();
		}
		while( !hFile.EndOfFile() && hFile.ReadLine(str, sizeof(str)) )
		{
			TrimString(str);
			list.PushString(str);
		}
		delete hFile;
	}
}

public void OnMapStart()
{
	static int ft_block, ft_anc_block, ft_mute, ft_gag;
	int ft, ft1, ft2;
	
	if( ft_block 		!= (ft1 = GetFileTime(FILE_VOTE_BLOCK, 	FileTime_LastChange)) 
	||	ft_anc_block 	!= (ft2 = GetFileTime(FILE_ANC_BLOCK, 	FileTime_LastChange)) )
	{
		ft_block = ft1;
		ft_anc_block = ft2;
		ReadFileToArrayList(FILE_VOTE_BLOCK, 	g_hArrayVoteBlock);
		if( FILE_ANC_BLOCK[0] != 0 && ft_anc_block != -1 )
		{
			ReadFileToArrayList(FILE_ANC_BLOCK, 	g_hArrayVoteBlock, false); // append
		}
	}
	
	ft = GetFileTime(FILE_PERMANENT_MUTE, FileTime_LastChange);
	if( ft != ft_mute )
	{
		ft_mute = ft;
		ReadFileToArrayList(FILE_PERMANENT_MUTE, g_hArrayPermMute);
	}
	
	ft = GetFileTime(FILE_PERMANENT_GAG, FileTime_LastChange);
	if( ft != ft_gag )
	{
		ft_gag = ft;
		ReadFileToArrayList(FILE_PERMANENT_GAG, g_hArrayPermGag);
	}
}

public void OnClientAuthorized(int client, const char[] auth)
{
	if( strcmp(auth, "BOT") != 0 )
	{
		CreateTimer(1.0, Timer_InGameCheck, GetClientUserId(client), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Timer_InGameCheck(Handle timer, int UserId)
{
	int client = GetClientOfUserId(UserId);
	if( !client || !IsClientConnected(client) )
	{
		return Plugin_Stop;
	}
	if( IsClientInGame(client) )
	{
		if( IsInMuteBase(client) )
		{
			MuteClient(client);
		}
		if( g_bBaseCommAvail )
		{
			if( InDenyFile(client, g_hArrayPermMute) )
			{
				BaseComm_SetClientMute(client, true);
			}
			if( InDenyFile(client, g_hArrayPermGag) )
			{
				BaseComm_SetClientGag(client, true);
			}
		}
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

bool IsInMuteBase(int client, int iSteamId = 0)
{
	// check is available both by client or SteamId (because client could disconnect before vote finished)
	static char auth[32], sTime[32];
	static int iTime;
	
	if( client && IsClientInGame(client) )
	{
		iSteamId = GetSteamAccountID(client, true);
	}
	
	IntToString(iSteamId, auth, sizeof(auth));
	
	if( hMapSteamMute.GetString(auth, sTime, sizeof(sTime)) ) // mute not more than 1 hour
	{
		iTime = StringToInt(sTime);
		if( GetTime() - iTime < g_hCvarMuteTime.IntValue ) {
			return true;
		}
		else {
			hMapSteamMute.Remove(auth);
		}
	}
	return false;
}

bool IsInGagBase(int client, int iSteamId = 0)
{
	// check is available both by client or SteamId (because client could disconnect before vote finished)
	static char auth[32], sTime[32];
	static int iTime;
	
	if( client && IsClientInGame(client) )
	{
		iSteamId = GetSteamAccountID(client, true);
	}
	
	IntToString(iSteamId, auth, sizeof(auth));
	
	if( hMapSteamGag.GetString(auth, sTime, sizeof(sTime)) ) // mute not more than 1 hour
	{
		iTime = StringToInt(sTime);
		if( GetTime() - iTime < g_hCvarGagTime.IntValue ) {
			return true;
		}
		else {
			hMapSteamGag.Remove(auth);
		}
	}
	return false;
}

stock void MuteClient(int client, int iSteamId = 0)
{
	static char sTime[32], sSteam[32];
	
	if( g_bBaseCommAvail ) {
		if( client && IsClientInGame(client) ) {
			BaseComm_SetClientMute(client, true);
		}
	}
	
	if( !IsInMuteBase(client, iSteamId) ) {
		if( client && IsClientInGame(client) )
			iSteamId = GetSteamAccountID(client, true);
		
		IntToString(GetTime(), sTime, sizeof(sTime));
		IntToString(iSteamId, sSteam, sizeof(sSteam));
		hMapSteamMute.SetString(sSteam, sTime, true);
	}
}

stock void UnmuteClient(int client, int iSteamId = 0)
{
	static char sSteam[32];
	
	if( g_bBaseCommAvail ) {
		if( client && IsClientInGame(client) ) {
			BaseComm_SetClientMute(client, false);
		}
	}
	
	if( IsInMuteBase(client, iSteamId) ) {
		if( client && IsClientInGame(client) )
			iSteamId = GetSteamAccountID(client, true);
		
		IntToString(iSteamId, sSteam, sizeof(sSteam));
		hMapSteamMute.Remove(sSteam);
	}
}

stock void GagClient(int client, int iSteamId = 0)
{
	static char sTime[32], sSteam[32];
	
	if( g_bBaseCommAvail ) {
		if( client && IsClientInGame(client) ) {
			BaseComm_SetClientGag(client, true);
		}
	}
	
	if( !IsInGagBase(client, iSteamId) ) {
		if( client && IsClientInGame(client) )
			iSteamId = GetSteamAccountID(client, true);
		
		IntToString(GetTime(), sTime, sizeof(sTime));
		IntToString(iSteamId, sSteam, sizeof(sSteam));
		hMapSteamGag.SetString(sSteam, sTime, true);
	}
}

stock void UngagClient(int client, int iSteamId = 0)
{
	static char sSteam[32];
	
	if( g_bBaseCommAvail ) {
		if( client && IsClientInGame(client) ) {
			BaseComm_SetClientGag(client, false);
		}
	}
	
	if( IsInGagBase(client, iSteamId) ) {
		if( client && IsClientInGame(client) )
			iSteamId = GetSteamAccountID(client, true);
		
		IntToString(iSteamId, sSteam, sizeof(sSteam));
		hMapSteamGag.Remove(sSteam);
	}
}

public void BaseComm_OnClientMute(int client, bool muteState)
{
	if( g_hCvarHandleAdminMenu.BoolValue ) {
		if( muteState ) {
			MuteClient(client);
		}
		else {
			UnmuteClient(client);
		}
	}
}

public void BaseComm_OnClientGag(int client, bool gagState)
{
	if( g_hCvarHandleAdminMenu.BoolValue ) {
		if( gagState ) {
			GagClient(client);
		}
		else {
			UngagClient(client);
		}
	}
}

public Action Command_Veto(int client, int args)
{
	if( g_bVoteInProgress ) { // IsVoteInProgress() is not working here, sm bug?
		if( !HasVetoAccessFlag(client) )
		{
			ReplyToCommand(client, "%t", "no_access");
			return Plugin_Handled;
		}
		g_bVeto = true;
		CPrintToChatAll("%t", "veto", client);
		if( g_bVoteDisplayed ) CancelVote();
		LogVoteAction(client, "[VETO]");
	}
	return Plugin_Handled;
}

public Action Command_Votepass(int client, int args)
{
	if( g_bVoteInProgress ) {
		if( !HasVetoAccessFlag(client) )
		{
			ReplyToCommand(client, "%t", "no_access");
			return Plugin_Handled;
		}
		g_bVotepass = true;
		CPrintToChatAll("%t", "votepass", client);
		if( g_bVoteDisplayed ) CancelVote();
		LogVoteAction(client, "[PASS]");
	}
	return Plugin_Handled;
}

public void OnAllPluginsLoaded()
{
	g_bBaseCommAvail = LibraryExists("basecomm");
	if( !g_bBaseCommAvail ) {
		SetFailState("Required plugin basecomm.smx is not loaded.");
	}
}

public void OnLibraryAdded(const char[] sName)
{
	if( strcmp(sName, "basecomm") == 0 ) {
		g_bBaseCommAvail = true;
	}
}

public void OnLibraryRemoved(const char[] sName)
{
	if( strcmp(sName, "basecomm") == 0 ) {
		g_bBaseCommAvail = false;
	}
}

public Action Command_Votemute(int client, int args)
{
	if( client ) {
		g_eCliVoteType[client] = VOTE_TYPE_MUTE;
		CreateVoteMenu(client);
		if( g_hTimerMenu[client] == null ) { // for updating the microphone icon in menu
			g_hTimerMenu[client] = CreateTimer(0.7, Timer_UpdateMenu, GetClientUserId(client), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	return Plugin_Handled;
}

public void OnMapEnd()
{
	for( int i = 1; i <= MaxClients; i++ )
	{
		g_hTimerMenu[i] = null;
	}
}

public Action Command_Votegag(int client, int args)
{
	if( client ) {
		g_eCliVoteType[client] = VOTE_TYPE_GAG;
		CreateVoteMenu(client);
	}
	return Plugin_Handled;
}

void CreateVoteMenu(int client, int page = 0)
{
	if( !g_bBaseCommAvail )
	{
		PrintToChat(client, "ERROR. basecomm plugin is not available!");
		return;
	}
	int items = 0, mitems = 0;
	static char name[MAX_NAME_LENGTH];
	static char uid[12];
	static char menuItem[64];
	static char ip[32];
	static char code[4];
	
	Menu menu = new Menu(Menu_Vote, MENU_ACTIONS_DEFAULT);
	g_hMenu[client] = menu;
	
	if( g_eCliVoteType[client] == VOTE_TYPE_MUTE || g_eCliVoteType[client] == VOTE_TYPE_UNMUTE )
	{
		menu.SetTitle("%T", "Player To Mute", client);
	}
	else {
		menu.SetTitle("%T", "Player To Gag", client);
	}
	
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && !IsFakeClient(i) )
		{
			++ items;
			
			if( items > (page+1)*7 )
				break;
			
			if( items <= page*7 )
				continue;
			
			Format(uid, sizeof(uid), "%i", GetClientUserId(i));
			if( GetClientName(i, name, sizeof(name)) )
			{
				NormalizeName(name, sizeof(name));
			
				if( GetClientIP(i, ip, sizeof(ip)) )
				{
					if( !GeoipCode3(ip, code) )
						strcopy(code, sizeof(code), "LAN");
					
					if( g_eCliVoteType[client] == VOTE_TYPE_MUTE || g_eCliVoteType[client] == VOTE_TYPE_UNMUTE )
					{
						Format(menuItem, sizeof(menuItem), "%s%s %s (%s)", 
							BaseComm_IsClientMuted(i) ? g_sCharMuted : "", 
							g_bClientSpeaking[i] ? g_sCharMicro : "", 
							name, code);
					}
					else {
						Format(menuItem, sizeof(menuItem), "%s %s (%s)", 
							BaseComm_IsClientGagged(i) ? g_sCharMuted : "", 
							name, code);
					}
					
					menu.AddItem(uid, menuItem);
				}
				else
					menu.AddItem(uid, name);
					
				++ mitems;
				
				// not supported by L4D :(
				//if( items % 7 == 0 ) {
				//	menu.AddItem("", "", ITEMDRAW_IGNORE );
				//}
			}
		}
	}
	
	// Pagination emulator. ^_^
	//
	// Notice for devs:
	// menu.Selection can only be retrieved within Callback's MenuAction_Select. Bad-bad-bad SM (or game) limitation!
	// Also, "Next" and "Back" buttons does not raise a callback.
	// That's why we forced to create our own implementation.
	//
	if( mitems == 0 && page > 0 ) { // if total number of players became less than current pagination
		delete menu;
		CreateVoteMenu(client, -- page);
		return;
	}
	
	if( items > (page+1)*7 )
	{
		if( page )
		{
			menu.AddItem("-2", Translate(client, "%t", "Back"));
		}
		else {
			menu.AddItem("", "", ITEMDRAW_SPACER );
		}
		menu.AddItem("-1", Translate(client, "%t", "Next"));
	}
	else {
		items %= 7;
		if( items == 0 ) items = 7;
		
		for( int i = items; i < (page ? 7 : 9); i++ )
		{
			menu.AddItem("", "", ITEMDRAW_SPACER );
		}
		if( page ) {
			menu.AddItem("-2", Translate(client, "%t", "Back"));
			menu.AddItem("", "", ITEMDRAW_SPACER );
		}
	}
	
	menu.AddItem("-3", Translate(client, "%t", "Exit")); // ITEMDRAW_DISABLED

	menu.Pagination = false;
	menu.Display(client, MENU_TIME_FOREVER);
	
	g_iMenuPage[client] = page;
}

void NullifyTimerHandle(Handle timer)
{
    for( int i = 1; i <= MaxClients; i++ )
    {
        if( timer == g_hTimerMenu[i] )
        {
            g_hTimerMenu[i] = null;
            break;
        }
    }
}

public Action Timer_UpdateMenu(Handle timer, int UserId)
{
	bool bUpdated;
	int client = GetClientOfUserId(UserId);
	if( client && IsClientInGame(client) )
	{
		if( GetClientMenu(client, INVALID_HANDLE ) == MenuSource_Normal && g_hMenu[client] != null )
		{
			CreateVoteMenu(client, g_iMenuPage[client]);
			bUpdated = true;
		}
	}
	if( !bUpdated )
	{
		NullifyTimerHandle(timer);
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public int Menu_Vote(Menu menu, MenuAction action, int param1, int param2)
{
	switch( action )
	{
		case MenuAction_End: {
			for( int i = 1; i <= MaxClients; i++ )
			{
				if( g_hMenu[i] == menu ) {
					g_hMenu[i] = null;
					break;
				}
			}
			delete menu;
		}
		
		case MenuAction_Select:
		{
			char info[16];
			int userid;
			if( menu.GetItem(param2, info, sizeof(info)) )
			{
				userid = StringToInt(info);
				switch( userid )
				{
					case -3: { } // Exit
					case -2: CreateVoteMenu(param1, -- g_iMenuPage[param1]); // Back
					case -1: CreateVoteMenu(param1, ++ g_iMenuPage[param1]); // Next
					default: {
						int target = GetClientOfUserId(userid);
						StartVoteAccessCheck(param1, target);
					}
				}
			}
		}
	}
	return 0;
}

void StartVoteAccessCheck(int client, int target)
{
	if( IsVoteInProgress() || g_bVoteInProgress ) {
		CPrintToChat(client, "%t", "other_vote");
		LogVoteAction(client, "[DENY] Reason: another vote is in progress.");
		return;
	}
	
	if( target == 0 || !IsClientInGame(target) )
	{
		CPrintToChat(client, "%t", "not_in_game"); // "Client is already disconnected."
		return;
	}
	
	// Check if the vote should be reversed
	if( g_eCliVoteType[client] == VOTE_TYPE_MUTE ) 
	{
		if( BaseComm_IsClientMuted(target) )
		{
			g_eCliVoteType[client] = VOTE_TYPE_UNMUTE;
		}
	}
	else if( g_eCliVoteType[client] == VOTE_TYPE_GAG )
	{
		if( BaseComm_IsClientGagged(target) )
		{
			g_eCliVoteType[client] = VOTE_TYPE_UNGAG;
		}
	}
	
	switch( g_eCliVoteType[client] )
	{
		case VOTE_TYPE_MUTE: 	SetListenOverride(client, target, Listen_No); // in case initiator don't want to hear this client (but vote failed)
		case VOTE_TYPE_UNMUTE: 	SetListenOverride(client, target, Listen_Yes);
	}
	
	if( !IsVoteAllowed(client, target) )
	{
		LogVoteAction(client, "[NO ACCESS]");
		
		switch( g_eCliVoteType[client] )
		{
			case VOTE_TYPE_MUTE: {
				CPrintToChatAll("%t", "no_access_mute", client, target);
				LogVoteAction(target, "[TRIED] to mute against:");
			}
			case VOTE_TYPE_UNMUTE: {
				CPrintToChatAll("%t", "no_access_unmute", client, target);
				LogVoteAction(target, "[TRIED] to mute against:");
			}
			case VOTE_TYPE_GAG: {
				CPrintToChatAll("%t", "no_access_gag", client, target);
				LogVoteAction(target, "[TRIED] to mute against:");
			}
			case VOTE_TYPE_UNGAG: {
				CPrintToChatAll("%t", "no_access_ungag", client, target);
				LogVoteAction(target, "[TRIED] to mute against:");
			}
		}
		return;
	}
	
	g_eVoteType = g_eCliVoteType[client];
	StartVote(client, target);
}

int GetRealClientCount() {
	int cnt;
	for( int i = 1; i <= MaxClients; i++ )
		if( IsClientInGame(i) && !IsFakeClient(i) ) cnt++;
	return cnt;
}

bool IsVoteAllowed(int client, int target)
{
	if( target == 0 || !IsClientInGame(target) )
		return false;
	
	if( IsClientRootAdmin(client) )
		return true;
	
	if( IsClientRootAdmin(target) )
		return false;
	
	if( iLastTime[client] != 0 )
	{
		if( iLastTime[client] + g_hCvarDelay.IntValue > GetTime() ) {
			CPrintToChat(client, "%t", "too_often"); // "You can't vote too often!"
			LogVoteAction(client, "[DENY] Reason: too often.");
			return false;
		}
	}
	iLastTime[client] = GetTime();
	
	int iClients = GetRealClientCount();
	
	if( iClients < g_hMinPlayers.IntValue ) {
		CPrintToChat(client, "%t", "not_enough_players", g_hMinPlayers.IntValue); // "Not enough players to start the vote. Required minimum: %i"
		LogVoteAction(client, "[DENY] Reason: Not enough players. Now: %i, required: %i.", iClients, g_hMinPlayers.IntValue);
		return false;
	}
	
	if( HasVoteAccessFlag(target) && !HasVoteAccessFlag(client) && !IsClientRootAdmin(client) )
		return false;
	
	if( GetImmunityLevel(client) < GetImmunityLevel(target) )
	{
		CPrintToChat(client, "%t", "no_access_immunity");
		LogVoteAction(client, "[DENY] Reason: Target immunity (%i) is higher than vote issuer (%i)", GetImmunityLevel(target), GetImmunityLevel(client));
		return false;
	}
	
	if( InDenyFile(client, g_hArrayVoteBlock) )
	{
		LogVoteAction(client, "[DENY] Reason: player is in deny list.");
		return false;
	}
	
	if( InDenyFile(target, g_hArrayVoteBlock) ) // allow to vote everybody against clients who located in deny list (regardless of vote access flag)
	{
		return true;
	}

	if( !HasVoteAccessFlag(client) ) return false;
	
	return true;
}

bool InDenyFile(int client, ArrayList list)
{
	static char sName[MAX_NAME_LENGTH], str[MAX_NAME_LENGTH];
	static char sSteam[64];
	
	GetClientAuthId(client, AuthId_Steam2, sSteam, sizeof(sSteam));
	GetClientName(client, sName, sizeof(sName));
	
	for( int i = 0; i < list.Length; i++ )
	{
		list.GetString(i, str, sizeof(str));
	
		if( strncmp(str, "STEAM_", 6, false) == 0 )
		{
			if( strcmp(sSteam, str, false) == 0 )
			{
				return true;
			}
		}
		else {
			if( StrContains(str, "*") ) // allow masks like "Dan*" to match "Danny and Danil"
			{
				ReplaceString(str, sizeof(str), "*", "");
				if( StrContains(sName, str, false) != -1 )
				{
					return true;
				}
			}
			else {
				if( strcmp(sName, str, false) == 0 )
				{
					return true;
				}
			}
		}
	}
	return false;
}

void StartVote(int client, int target)
{
	Menu menu = new Menu(Handle_Vote, MenuAction_DisplayItem | MenuAction_Display);
	g_iVoteTargetUserId = GetClientUserId(target);
	menu.AddItem("", "Yes");
	menu.AddItem("", "No");
	menu.ExitButton = false;
	
	GetClientAuthId(target, AuthId_Steam2, g_sSteamId, sizeof(g_sSteamId));
	g_iSteamId = GetSteamAccountID(target, true);
	GetClientName(target, g_sName, sizeof(g_sName));
	GetClientIP(target, g_sIP, sizeof(g_sIP));
	GeoipCode3(g_sIP, g_sCountry);
	
	g_bVotepass = false;
	g_bVeto = false;
	g_bVoteDisplayed = false;
	
	CreateTimer(g_hCvarAnnounceDelay.FloatValue, Timer_VoteDelayed, menu);
	
	switch( g_eVoteType )
	{
		case VOTE_TYPE_MUTE: {
			LogVoteAction(client, "[STARTED] Mute by");
			LogVoteAction(target, "[AGAINST] ");
			CPrintToChatAll("%t", "vote_started_mute", client, target);
			PrintToServer("Vote for mute is started by: %N", client);
			PrintToConsoleAll("Vote for mute is started by: %N", client);
			CPrintHintTextToAll("%t", "vote_started_mute_announce", g_sName);
		}
		case VOTE_TYPE_UNMUTE: {
			LogVoteAction(client, "[STARTED] Un-mute by");
			LogVoteAction(target, "[AGAINST] ");
			CPrintToChatAll("%t", "vote_started_unmute", client, target);
			PrintToServer("Vote for unmute is started by: %N", client);
			PrintToConsoleAll("Vote for unmute is started by: %N", client);
			CPrintHintTextToAll("%t", "vote_started_unmute_announce", g_sName);
		}
		case VOTE_TYPE_GAG: {
			LogVoteAction(client, "[STARTED] Gag by");
			LogVoteAction(target, "[AGAINST] ");
			CPrintToChatAll("%t", "vote_started_gag", client, target);
			PrintToServer("Vote for gag is started by: %N", client);
			PrintToConsoleAll("Vote for gag is started by: %N", client);
			CPrintHintTextToAll("%t", "vote_started_gag_announce", g_sName);
		}
		case VOTE_TYPE_UNGAG: {
			LogVoteAction(client, "[STARTED] Un-gag by");
			LogVoteAction(target, "[AGAINST] ");
			CPrintToChatAll("%t", "vote_started_ungag", client, target);
			PrintToServer("Vote for ungag is started by: %N", client);
			PrintToConsoleAll("Vote for ungag is started by: %N", client);
			CPrintHintTextToAll("%t", "vote_started_ungag_announce", g_sName);
		}
	}
}

Action Timer_VoteDelayed(Handle timer, Menu menu)
{
	if( g_bVotepass || g_bVeto ) {
		Handler_PostVoteAction(g_bVotepass);
		delete menu;
	}
	else {
		if( !IsVoteInProgress() ) {
			g_bVoteInProgress = true;
			menu.DisplayVoteToAll(g_hCvarTimeout.IntValue);
			g_bVoteDisplayed = true;
		}
		else {
			delete menu;
		}
	}
	return Plugin_Continue;
}

public int Handle_Vote(Menu menu, MenuAction action, int param1, int param2)
{
	static char display[64], buffer[255];

	switch( action )
	{
		case MenuAction_End: {
			if( g_bVoteInProgress && g_bVotepass ) { // in case vote is passed with CancelVote(), so MenuAction_VoteEnd is not called.
				Handler_PostVoteAction(true);
			}
			g_bVoteInProgress = false;
			delete menu;
		}
		
		case MenuAction_VoteEnd: // 0=yes, 1=no
		{
			if( (param1 == 0 || g_bVotepass) && !g_bVeto ) {
				Handler_PostVoteAction(true);
			}
			else {
				Handler_PostVoteAction(false);
			}
			g_bVoteInProgress = false;
		}
		case MenuAction_DisplayItem:
		{
			menu.GetItem(param2, "", 0, _, display, sizeof(display));
			Format(buffer, sizeof(buffer), "%T", display, param1);
			return RedrawMenuItem(buffer);
		}
		case MenuAction_Display:
		{
			switch( g_eVoteType )
			{
				case VOTE_TYPE_MUTE: 	Format(buffer, sizeof(buffer), "%T", "vote_started_mute_announce", param1, g_sName);
				case VOTE_TYPE_UNMUTE: 	Format(buffer, sizeof(buffer), "%T", "vote_started_unmute_announce", param1, g_sName);
				case VOTE_TYPE_GAG: 	Format(buffer, sizeof(buffer), "%T", "vote_started_gag_announce", param1, g_sName);
				case VOTE_TYPE_UNGAG: 	Format(buffer, sizeof(buffer), "%T", "vote_started_ungag_announce", param1, g_sName);
			}
			menu.SetTitle(buffer);
		}
	}
	return 0;
}

void Handler_PostVoteAction(bool bVoteSuccess)
{
	if( bVoteSuccess ) {
		int iTarget = GetClientOfUserId(g_iVoteTargetUserId);
		
		switch( g_eVoteType )
		{
			case VOTE_TYPE_MUTE: {
				MuteClient(iTarget, g_iSteamId);
				LogVoteAction(0, "[MUTED]");
				CPrintToChatAll("%t", "vote_success_mute", g_sName);
			}
			case VOTE_TYPE_UNMUTE: {
				UnmuteClient(iTarget, g_iSteamId);
				LogVoteAction(0, "[UNMUTED]");
				CPrintToChatAll("%t", "vote_success_unmute", g_sName);
			}
			case VOTE_TYPE_GAG: {
				GagClient(iTarget, g_iSteamId);
				LogVoteAction(0, "[GAGGED]");
				CPrintToChatAll("%t", "vote_success_gag", g_sName);
			}
			case VOTE_TYPE_UNGAG: {
				UngagClient(iTarget, g_iSteamId);
				LogVoteAction(0, "[UNGAGGED]");
				CPrintToChatAll("%t", "vote_success_ungag", g_sName);
			}
		}
	}
	else {
		LogVoteAction(0, "[NOT ACCEPTED]");
		
		switch( g_eVoteType )
		{
			case VOTE_TYPE_MUTE: 	CPrintToChatAll("%t", "vote_failed_mute");
			case VOTE_TYPE_UNMUTE: 	CPrintToChatAll("%t", "vote_failed_unmute");
			case VOTE_TYPE_GAG: 	CPrintToChatAll("%t", "vote_failed_gag");
			case VOTE_TYPE_UNGAG: 	CPrintToChatAll("%t", "vote_failed_ungag");
		}
	}
	g_bVoteInProgress = false;
}

stock bool IsClientRootAdmin(int client)
{
	return ((GetUserFlagBits(client) & ADMFLAG_ROOT) != 0);
}

bool HasVoteAccessFlag(int client)
{
	int iUserFlag = GetUserFlagBits(client);
	if( iUserFlag & ADMFLAG_ROOT != 0 ) return true;
	
	char sReq[32];
	g_hCvarAccessFlag.GetString(sReq, sizeof(sReq));
	if( strlen(sReq) == 0 ) return true;
	
	int iReqFlags = ReadFlagString(sReq);
	return (iUserFlag & iReqFlags != 0);
}

bool HasVetoAccessFlag(int client)
{
	int iUserFlag = GetUserFlagBits(client);
	if( iUserFlag & ADMFLAG_ROOT != 0 ) return true;
	
	char sReq[32];
	g_hCvarVetoFlag.GetString(sReq, sizeof(sReq));
	if( strlen(sReq) == 0 ) return true;
	
	int iReqFlags = ReadFlagString(sReq);
	return (iUserFlag & iReqFlags != 0);
}

void LogVoteAction(int client, const char[] format, any ...)
{
	if( !g_hCvarLog.BoolValue )
		return;
	
	static char sSteam[64];
	static char sIP[32];
	static char sCountry[4];
	static char sName[MAX_NAME_LENGTH];
	static char buffer[256];
	
	VFormat(buffer, sizeof(buffer), format, 3);
	
	if( client && IsClientInGame(client) ) {
		GetClientAuthId(client, AuthId_Steam2, sSteam, sizeof(sSteam));
		GetClientName(client, sName, sizeof(sName));
		GetClientIP(client, sIP, sizeof(sIP));
		GeoipCode3(sIP, sCountry);
		LogToFile(g_sLog, "%s %s (%s | [%s] %s)", buffer, sName, sSteam, sCountry, sIP);
	}
	else {
		LogToFile(g_sLog, "%s %s (%s | [%s] %s)", buffer, g_sName, g_sSteamId, g_sCountry, g_sIP);
	}
}

stock char[] Translate(int client, const char[] format, any ...)
{
	char buffer[192];
	SetGlobalTransTarget(client);
	VFormat(buffer, sizeof(buffer), format, 3);
	return buffer;
}

stock void ReplaceColor(char[] message, int maxLen)
{
    ReplaceString(message, maxLen, "{white}", "\x01", false);
    ReplaceString(message, maxLen, "{cyan}", "\x03", false);
    ReplaceString(message, maxLen, "{orange}", "\x04", false);
    ReplaceString(message, maxLen, "{green}", "\x05", false);
}

stock void CPrintToChat(int iClient, const char[] format, any ...)
{
    char buffer[192];
    SetGlobalTransTarget(iClient);
    VFormat(buffer, sizeof(buffer), format, 3);
    ReplaceColor(buffer, sizeof(buffer));
    PrintToChat(iClient, "\x01%s", buffer);
}

stock void CPrintToChatAll(const char[] format, any ...)
{
    char buffer[192];
    for( int i = 1; i <= MaxClients; i++ )
    {
        if( IsClientInGame(i) && !IsFakeClient(i) )
        {
            SetGlobalTransTarget(i);
            VFormat(buffer, sizeof(buffer), format, 2);
            ReplaceColor(buffer, sizeof(buffer));
            PrintToChat(i, "\x01%s", buffer);
        }
    }
}

stock void CPrintHintTextToAll(const char[] format, any ...)
{
    char buffer[192];
    for( int i = 1; i <= MaxClients; i++ )
    {
        if( IsClientInGame(i) && !IsFakeClient(i) )
        {
            SetGlobalTransTarget(i);
            VFormat(buffer, sizeof(buffer), format, 2);
            PrintHintText(i, buffer);
        }
    }
}

public void OnClientSpeaking(int client)
{
	g_bClientSpeaking[client] = true;
}

public void OnClientSpeakingEnd(int client)
{
	g_bClientSpeaking[client] = false;
}

void NormalizeName(char[] name, int len)
{
	int i, j, k, bytes;
	char sNew[MAX_NAME_LENGTH];
	
	while( name[i] )
	{
		bytes = GetCharBytes(name[i]);
		
		if( bytes > 1 )
		{
			for( k = 0; k < bytes; k++ )
			{
				sNew[j++] = name[i++];
			}
		}
		else {
			if( name[i] >= 32 )
			{
				sNew[j++] = name[i++];
			}
			else {
				i++;
			}
		}
	}
	strcopy(name, len, sNew);
}

int GetImmunityLevel(int client)
{
	AdminId id = GetUserAdmin(client);
	if( id != INVALID_ADMIN_ID )
	{
		return GetAdminImmunityLevel(id);
	}
	return 0;
}