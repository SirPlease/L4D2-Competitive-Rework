#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <builtinvotes>
#include <sdktools>
#include <l4d2util>
#include <left4dhooks>
#include <colors>
#include <nextmap>
#undef REQUIRE_PLUGIN
#include <l4d2_playstats>
#undef REQUIRE_PLUGIN
#include <sdkhooks>
#include <l4d2util_stocks>
#include <readyup>

#define SECTION_NAME "CTerrorGameRules::SetCampaignScores"
#define LEFT4FRAMEWORK_GAMEDATA "left4dhooks.l4d2"

public Plugin myinfo =
{
	name = "l4d2_mixmap",
	author = "Stabby, Bred",
	description = "随机抽取5张地图进行对抗，增加趣味性，借鉴CMT-https://github.com/Stabbath/L4D2-Stuff",
	version = "2.3",
	url = "https://gitee.com/honghl5/open-source-plug-in"
};

#define DIR_CFGS 			"mixmap/"
#define PATH_KV  			"cfg/mixmap/mapnames.txt"
#define CFG_DEFAULT			"default"
#define CFG_DODEFAULT		"disorderdefault"
#define CFG_DODEFAULT_ST	"do"
#define CFG_ALLOF			"official"
#define CFG_ALLOF_ST		"of"
#define	CFG_DOALLOF			"disorderofficial"
#define	CFG_DOALLOF_ST		"doof"
#define	CFG_UNOF			"unofficial"
#define	CFG_UNOF_ST			"uof"
#define	CFG_DOUNOF			"disorderunofficial"
#define	CFG_DOUNOF_ST		"douof"
#define BUF_SZ   			64

const TEAM_SPECTATOR = 1;
const TEAM_SURVIVOR = 2;
const TEAM_INFECTED = 3;
char cfg_exec[BUF_SZ];

Handle hVoteMixmap;
Handle hVoteStopMixmap;

//与随机抽签相关的变量
Handle g_hArrayTags;				// Stores tags for indexing g_hTriePools 存放地图池标签
Handle g_hTriePools;				// Stores pool array handles by tag name 存放由标签分类的地图
Handle g_hArrayTagOrder;			// Stores tags by rank 存放标签顺序
Handle g_hArrayMapOrder;			// Stores finalised map list in order 存放抽取完成后的地图顺序


bool g_bMaplistFinalized;
bool g_bMapsetInitialized;
int g_iMapsPlayed;
int g_iMapCount;

int
	g_iPointsTeam_A = 0,
	g_iPointsTeam_B = 0;

//bool bLeftStartArea;
//bool bReadyUpAvailable;
bool g_bCMapTransitioned = false;

Handle g_hForwardStart;
Handle g_hForwardNext;
Handle g_hForwardEnd;

Handle g_hCountDownTimer;
Handle g_hCMapSetCampaignScores;

// ----------------------------------------------------------
// 		Setup
// ----------------------------------------------------------

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	// Right before loading first map; params: 1 = maplist size; 2 = name of first map
	g_hForwardStart = CreateGlobalForward("OnCMTStart", ET_Ignore, Param_Cell, Param_String );
	// After loading a map (to let other plugins know what the next map will be ahead of time); 1 = name of next map
	g_hForwardNext = CreateGlobalForward("OnCMTNextKnown", ET_Ignore, Param_String );
	// After last map is played; no params
	g_hForwardEnd = CreateGlobalForward("OnCMTEnd", ET_Ignore );

	MarkNativeAsOptional("PLAYSTATS_BroadcastRoundStats");
	MarkNativeAsOptional("PLAYSTATS_BroadcastGameStats");
	MarkNativeAsOptional("IsInReady");

	return APLRes_Success;
}

public void OnPluginStart() 
{
	LoadSDK();

	//服务器指令（用于cfg文件）
	RegServerCmd( "sm_addmap", AddMap);
	RegServerCmd( "sm_tagrank", TagRank);

	//启用/中止指令
	RegAdminCmd( "sm_manualmixmap", ManualMixmap, ADMFLAG_ROOT, "启用mixmap加载特定地图顺序的地图组");
	RegAdminCmd( "sm_fmixmap", ForceMixmap, ADMFLAG_ROOT, "强制启用mixmap（随机官方地图）");
	RegConsoleCmd( "sm_mixmap", Mixmap_Cmd, "通过投票启用Mixmap，并可加载特定的地图池；无参数则启用官图顺序随机");
	RegConsoleCmd( "sm_stopmixmap",	StopMixmap_Cmd, "中止mixmap，并初始化地图列表");
	RegAdminCmd( "sm_fstopmixmap",	StopMixmap, ADMFLAG_ROOT, "强制中止mixmap，并初始化地图列表");

	//插件启用后可使用的指令
	RegConsoleCmd( "sm_maplist", Maplist, "展示mixmap最终抽取出的地图列表");
	RegAdminCmd( "sm_allmaps", ShowAllMaps, ADMFLAG_ROOT, "展示所有官方地图的地图代码");

	// HookEvent("player_left_start_area", LeftStartArea_Event, EventHookMode_PostNoCopy);
	// HookEvent("round_start", RoundStart_Event, EventHookMode_PostNoCopy);
	

	PluginStartInit();
	LoadTranslations("l4d2_mixmap.phrases");

}

void PluginStartInit() 
{
	g_hArrayTags = CreateArray(BUF_SZ/4);	//1 block = 4 characters => X characters = X/4 blocks
	g_hTriePools = CreateTrie();
	g_hArrayTagOrder = CreateArray(BUF_SZ/4);
	g_hArrayMapOrder = CreateArray(BUF_SZ/4);

	g_bMapsetInitialized = false;
	g_bMaplistFinalized = false;

	g_hCountDownTimer = null;
	
	g_iMapsPlayed = 0;
	g_iMapCount = 0;
}

void LoadSDK()
{
	Handle hGameData = LoadGameConfigFile(LEFT4FRAMEWORK_GAMEDATA);
	if (hGameData == null) {
		SetFailState("Could not load gamedata/%s.txt", LEFT4FRAMEWORK_GAMEDATA);
	}

	StartPrepSDKCall(SDKCall_GameRules);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, SECTION_NAME)) {
		SetFailState("Function '%s' not found.", SECTION_NAME);
	}

	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	g_hCMapSetCampaignScores = EndPrepSDKCall();

	if (g_hCMapSetCampaignScores == null) {
		SetFailState("Function '%s' found, but something went wrong.", SECTION_NAME);
	}

	delete hGameData;
}


// ----------------------------------------------------------
// 		Hooks
// ----------------------------------------------------------

// Otherwise nextmap would be stuck and people wouldn't be able to play normal campaigns without the plugin 结束后初始化sm_nextmap的值
public void OnPluginEnd() {
	ServerCommand("sm_nextmap ''");
}

public void OnClientPutInServer(int client)
{	
	if (g_bMapsetInitialized)
	{
		CreateTimer(10.0, Timer_ShowMaplist, client);//玩家加入服务器后，10s后提示正在使用mixmap插件。
	}
}

public Action Timer_ShowMaplist(Handle timer, int client)
{
	if (IsClientInGame(client))
	{
		CPrintToChat(client, "%t", "Auto_Show_Maplist");
	}
	
	return Plugin_Handled;
}

public void OnMapStart() {
	
	if (g_bCMapTransitioned) {
		CreateTimer(1.0, Timer_OnMapStartDelay, _, TIMER_FLAG_NO_MAPCHANGE); //Clients have issues connecting if team swap happens exactly on map start, so we delay it
		g_bCMapTransitioned = false;
	}

	ServerCommand("sm_nextmap ''");
	
	char buffer[BUF_SZ];
	
	//判断currentmap与预计的map的name是否一致，如果不一致就stopmixmap
	if (g_bMapsetInitialized)
	{
		char OriginalSetMapName[BUF_SZ];
		GetCurrentMap(buffer, BUF_SZ);
		GetArrayString(g_hArrayMapOrder, g_iMapsPlayed, OriginalSetMapName, BUF_SZ);
	
		if (! StrEqual(buffer,OriginalSetMapName) && g_bMaplistFinalized)
		{
			PluginStartInit();
			CPrintToChatAll("%t", "Differ_Abort");
			return;
		}
	}

	// let other plugins know what the map *after* this one will be (unless it is the last map)
	if (! g_bMaplistFinalized || g_iMapsPlayed >= g_iMapCount-1) {
		return;
	}

	GetArrayString(g_hArrayMapOrder, g_iMapsPlayed+1, buffer, BUF_SZ);

	Call_StartForward(g_hForwardNext);
	Call_PushString(buffer);
	Call_Finish();
}

public Action Timer_OnMapStartDelay(Handle hTimer)
{
	SetScores();

	return Plugin_Handled;
}

void SetScores()
{
	//If team B is winning, swap teams. Does not change how scores are set
	if (g_iPointsTeam_A < g_iPointsTeam_B) {
		L4D2_SwapTeams();
	}

	//Set scores on scoreboard
	SDKCall(g_hCMapSetCampaignScores, g_iPointsTeam_A, g_iPointsTeam_B);

	//Set actual scores
	L4D2Direct_SetVSCampaignScore(0, g_iPointsTeam_A);
	L4D2Direct_SetVSCampaignScore(1, g_iPointsTeam_B);
}

public void L4D2_OnEndVersusModeRound_Post() 
{
	if (InSecondHalfOfRound() && g_bMapsetInitialized)
	{
		PerformMapProgression();
		return;
	}
	return;
}

// ----------------------------------------------------------
// 		Map switching logic
// ----------------------------------------------------------

stock Action PerformMapProgression() 
{
	if (++g_iMapsPlayed < g_iMapCount) 
	{
		GotoNextMap(false);
		return Plugin_Handled;
	}

	Call_StartForward(g_hForwardEnd);
	Call_Finish();
	
	return Plugin_Handled;
}

void GotoNextMap(bool force = false) 
{
	char sMapName[BUF_SZ];
	GetArrayString(g_hArrayMapOrder, g_iMapsPlayed, sMapName, BUF_SZ);
	
	GotoMap(sMapName, force);
} 

void GotoMap(const char[] sMapName, bool force = false) 
{
	if (force) 
	{
		ForceChangeLevel(sMapName, "Mixmap");
		return;
	}
	ServerCommand("sm_nextmap %s", sMapName);
	CreateTimer(5.0, Timed_NextMapInfo);
} 

public Action Timed_NextMapInfo(Handle timer)
{
	char sMapName_New[BUF_SZ];
	char sMapName_Old[BUF_SZ];
	GetArrayString(g_hArrayMapOrder, g_iMapsPlayed, sMapName_New, BUF_SZ);
	GetArrayString(g_hArrayMapOrder, g_iMapsPlayed - 1, sMapName_Old, BUF_SZ);
	
	CPrintToChatAll("%t", "Show_Next_Map", sMapName_New);
	
	if ((StrEqual(sMapName_Old, "c6m2_bedlam") && !StrEqual(sMapName_New, "c7m1_docks")) || (StrEqual(sMapName_Old, "c9m2_lots") && !StrEqual(sMapName_New, "c14m1_junkyard")))
	{
		g_iPointsTeam_A = L4D2Direct_GetVSCampaignScore(0);
		g_iPointsTeam_B = L4D2Direct_GetVSCampaignScore(1);
		g_bCMapTransitioned = true;
		CreateTimer(9.0, Timed_Gotomap);	//this command must set ahead of the l4d2_map_transition plugin setting. Otherwise the map will be c7m1_docks/c14m1_junkyard after c6m2_bedlam/c9m2_lots
	}
	else if ((!StrEqual(sMapName_Old, "c6m2_bedlam") && StrEqual(sMapName_New, "c7m1_docks")) || (!StrEqual(sMapName_Old, "c9m2_lots") && StrEqual(sMapName_New, "c14m1_junkyard")))
	{
		g_iPointsTeam_A = L4D2Direct_GetVSCampaignScore(0);
		g_iPointsTeam_B = L4D2Direct_GetVSCampaignScore(1);
		g_bCMapTransitioned = true;
		CreateTimer(10.0, Timed_Gotomap);	//this command must set ahead of the l4d2_map_transition plugin setting. Otherwise the map will be c7m1_docks/c14m1_junkyard after c6m2_bedlam/c9m2_lots
	}
	
	return Plugin_Handled;
}

public Action Timed_Gotomap(Handle timer)
{
	char sMapName_New[BUF_SZ];
	GetArrayString(g_hArrayMapOrder, g_iMapsPlayed, sMapName_New, BUF_SZ);
	
	GotoMap(sMapName_New, true);
	return Plugin_Handled;
}
	

// ----------------------------------------------------------
// 		Commands: Console/Admin
// ----------------------------------------------------------

// Loads a specified set of maps
public Action ForceMixmap(int client, any args) 
{
	if (g_bMapsetInitialized) 
	{
		CPrintToChat(client,"%t", "Already_Start_Admin");
		return Plugin_Handled;
	}
	
	Format(cfg_exec, sizeof(cfg_exec), CFG_DEFAULT);
	
	if (args >=1)
	{
		char sbuffer[BUF_SZ];
		char arg[BUF_SZ];
		GetCmdArg(1, arg, BUF_SZ);
		Format(sbuffer, sizeof(sbuffer), "cfg/%s%s.cfg", DIR_CFGS, arg);
		if (FileExists(sbuffer)) Format(cfg_exec, sizeof(cfg_exec), arg);
		else
		{
			if (StrEqual(arg,CFG_DODEFAULT_ST))
				Format(cfg_exec, sizeof(cfg_exec), CFG_DODEFAULT);
			else if (StrEqual(arg, CFG_ALLOF_ST))
				Format(cfg_exec, sizeof(cfg_exec), CFG_ALLOF);
			else if (StrEqual(arg, CFG_DOALLOF_ST))
				Format(cfg_exec, sizeof(cfg_exec), CFG_DOALLOF);
			else if (StrEqual(arg, CFG_UNOF_ST))
					Format(cfg_exec, sizeof(cfg_exec), CFG_UNOF);
			else if (StrEqual(arg, CFG_DOUNOF_ST))
				Format(cfg_exec, sizeof(cfg_exec), CFG_DOUNOF);
			else
			{
				CPrintToChat(client, "%t", "Invalid_Cfg");
				return Plugin_Handled;
			}
		}
	}
	CPrintToChatAllEx(client, "%t", "Force_Start", client, cfg_exec);
	ServerCommand("exec %s%s.cfg", DIR_CFGS, cfg_exec);
	g_bMapsetInitialized = true;
	CreateTimer(0.1, Timed_PostMapSet);

	return Plugin_Handled;
}

// Load a specified set of maps
public Action ManualMixmap(int client, any args) 
{
	if (args < 1) 
	{
		CPrintToChat(client, "%t", "Manualmixmap_Syntax");
	}

	if (g_bMapsetInitialized) 
	{
		CPrintToChat(client, "%t", "Already_Start");
		return Plugin_Handled;
	}

	char map[BUF_SZ];
	for (int i = 1; i <= args; i++) 
	{
		GetCmdArg(i, map, BUF_SZ);
		ServerCommand("sm_addmap %s %d", map, i);
		ServerCommand("sm_tagrank %d %d", i, i-1);
	}
	g_bMapsetInitialized = true;
	CreateTimer(0.1, Timed_PostMapSet);

	return Plugin_Handled;
}

public Action ShowAllMaps(int client, any Args)
{
	CPrintToChat(client, "%t", "AllMaps_Official");
	CPrintToChat(client, "c1m1_hotel,c1m2_streets,c1m3_mall,c1m4_atrium");
	CPrintToChat(client, "c2m1_highway,c2m2_fairgrounds,c2m3_coaster,c2m4_barns,c2m5_concert");
	CPrintToChat(client, "c3m1_plankcountry,c3m2_swamp,c3m3_shantytown,c3m4_plantation");
	CPrintToChat(client, "c4m1_milltown_a,c4m2_sugarmill_a,c4m3_sugarmill_b,c4m4_milltown_b,c4m5_milltown_escape");
	CPrintToChat(client, "c5m1_waterfront,c5m2_park,c5m3_cemetery,c5m4_quarter,c5m5_bridge");
	CPrintToChat(client, "c6m1_riverbank,c6m2_bedlam,c7m1_docks,c7m2_barge,c7m3_port");
	CPrintToChat(client, "c8m1_apartment,c8m2_subway,c8m3_sewers,c8m4_interior,c8m5_rooftop");
	CPrintToChat(client, "c9m1_alleys,c9m2_lots,c14m1_junkyard,c14m2_lighthouse");
	CPrintToChat(client, "c10m1_caves,c10m2_drainage,c10m3_ranchhouse,c10m4_mainstreet,c10m5_houseboat");
	CPrintToChat(client, "c11m1_greenhouse,c11m2_offices,c11m3_garage,c11m4_terminal,c11m5_runway");
	CPrintToChat(client, "c12m1_hilltop,c12m2_traintunnel,c12m3_bridge,c12m4_barn,c12m5_cornfield");
	CPrintToChat(client, "c13m1_alpinecreek,c13m2_southpinestream,c13m3_memorialbridge,c13m4_cutthroatcreek");
	CPrintToChat(client, "%t", "AllMaps_Usage");
	
	return Plugin_Handled;
}


// ----------------------------------------------------------
// 		Commands: Client
// ----------------------------------------------------------

/* public void RoundStart_Event(Event event, const char[] name, bool dontBroadcast)
{
    bLeftStartArea = false;
}

public void LeftStartArea_Event(Event event, const char[] name, bool dontBroadcast)
{
    bLeftStartArea = true;
} */

public Action Mixmap_Cmd(int client, any args) 
{
	if (g_bMapsetInitialized) 
	{
		CPrintToChat(client, "%t", "Already_Start");
		return Plugin_Handled;
	}
	
	Format(cfg_exec, sizeof(cfg_exec), CFG_DEFAULT);
	
	if (args >=1)
	{
		char sbuffer[BUF_SZ];
		char arg[BUF_SZ];
		GetCmdArg(1, arg, BUF_SZ);
		Format(sbuffer, sizeof(sbuffer), "cfg/%s%s.cfg", DIR_CFGS, arg);
		if (FileExists(sbuffer)) Format(cfg_exec, sizeof(cfg_exec), arg);
		else
		{
			if (StrEqual(arg,CFG_DODEFAULT_ST))
				Format(cfg_exec, sizeof(cfg_exec), CFG_DODEFAULT);
			else if (StrEqual(arg, CFG_ALLOF_ST))
				Format(cfg_exec, sizeof(cfg_exec), CFG_ALLOF);
			else if (StrEqual(arg, CFG_DOALLOF_ST))
				Format(cfg_exec, sizeof(cfg_exec), CFG_DOALLOF);
			else if (StrEqual(arg, CFG_UNOF_ST))
					Format(cfg_exec, sizeof(cfg_exec), CFG_UNOF);
			else if (StrEqual(arg, CFG_DOUNOF_ST))
				Format(cfg_exec, sizeof(cfg_exec), CFG_DOUNOF);
			else
			{
				CPrintToChat(client, "%t", "Invalid_Cfg");
				return Plugin_Handled;
			}
		}
	}
	
	if (IsClientAndInGame(client))
    {
        if (!IsBuiltinVoteInProgress())
        {
			int iNumPlayers;
			int[] iPlayers = new int[MaxClients];
			for (int i = 1; i <= MaxClients; i++)
			{
				if (!IsClientAndInGame(i) || (GetClientTeam(i) == 1))
				{
					continue;
				}
				iPlayers[iNumPlayers++] = i;
			}
			
			char cVoteTitle[32];
			Format(cVoteTitle, sizeof(cVoteTitle), "%T", "Cvote_Title", LANG_SERVER, cfg_exec);

			hVoteMixmap = CreateBuiltinVote(VoteMixmapActionHandler, BuiltinVoteType_Custom_YesNo, BuiltinVoteAction_Cancel | BuiltinVoteAction_VoteEnd | BuiltinVoteAction_End);

			SetBuiltinVoteArgument(hVoteMixmap, cVoteTitle);
			SetBuiltinVoteInitiator(hVoteMixmap, client);
			SetBuiltinVoteResultCallback(hVoteMixmap, VoteMixmapResultHandler);
			DisplayBuiltinVote(hVoteMixmap, iPlayers, iNumPlayers, 20);

			CPrintToChatAllEx(client, "%t", "Start_Mixmap", client, cfg_exec);
			FakeClientCommand(client, "Vote Yes");
        }
		else
		{
			PrintToChat(client, "%t", "Vote_Progress");
		}

        return Plugin_Handled;
    }

	return Plugin_Continue;
}

public void VoteMixmapActionHandler(Handle vote, BuiltinVoteAction action, int param1, int param2)
{
    switch (action)
    {
        case BuiltinVoteAction_End:
        {
            hVoteMixmap = null;
            CloseHandle(vote);
        }
        case BuiltinVoteAction_Cancel:
        {
			DisplayBuiltinVoteFail(vote, view_as<BuiltinVoteFailReason>(param1));
        }
        case BuiltinVoteAction_Select:
        {
            char cItemVal[64];
            char cItemName[64];
            GetBuiltinVoteItem(vote, param2, cItemVal, sizeof(cItemVal), cItemName, sizeof(cItemName));
        }
    }
}

public void VoteMixmapResultHandler(Handle vote, int num_votes, int num_clients, const int[][] client_info, int num_items, const int[][] item_info)
{
    for (int i = 0; i < num_items; i++)
    {
        if (item_info[i][BUILTINVOTEINFO_ITEM_INDEX] == BUILTINVOTES_VOTE_YES)
        {
            if (item_info[i][BUILTINVOTEINFO_ITEM_VOTES] > (num_clients / 2))
            {
                if (vote == hVoteMixmap)
                {
					char cExecTitle[32];
					Format(cExecTitle, sizeof(cExecTitle), "%T", "Cexec_Title", LANG_SERVER);
					DisplayBuiltinVotePass(vote, cExecTitle);
					CreateTimer(5.0, StartVoteMixmap_Timer);
					return;
                }
            }
        }
    }
}

public Action StartVoteMixmap_Timer(Handle timer)
{
	Mixmap();
	
	return Plugin_Handled;
}

// Load a mixmap cfg
public Action Mixmap() 
{
	ServerCommand("exec %s%s.cfg", DIR_CFGS, cfg_exec);
//	PrintToChatAll("\x01Loading \x05random \x01preset...");
	g_bMapsetInitialized = true;
	CreateTimer(0.1, Timed_PostMapSet);
	
	return Plugin_Handled;
}

// Display current map list
public Action Maplist(int client, any args) 
{
	if (! g_bMaplistFinalized) 
	{
		CPrintToChat(client, "%t", "Show_Maplist_Not_Start");
		return Plugin_Handled;
	}

	char output[BUF_SZ];
	char buffer[BUF_SZ];

	CPrintToChat(client, "%t", "Maplist_Title");

	// Final Maplist
	if (g_bMaplistFinalized) 
	{
		for (int i = 0; i < GetArraySize(g_hArrayMapOrder); i++) 
		{
			GetArrayString(g_hArrayMapOrder, i, buffer, BUF_SZ);
			FormatEx(output, BUF_SZ, "\x05 %d - %s", i + 1, buffer);

			if (GetPrettyName(buffer)) 
			{
				if (g_iMapsPlayed == i) 
				{
					FormatEx(output, BUF_SZ, "\x04%d - %s", i + 1, buffer);
				}
				else
				{
					FormatEx(output, BUF_SZ, "%d - %s ", i + 1, buffer);
				}
			}
			CPrintToChat(client, "%s", output);
		}
		CPrintToChat(client, "%t", "Show_Maplist_Cmd");
		return Plugin_Handled;
	}

	Handle hArrayMapPool;
	char tag[BUF_SZ];
	int j;

	for (int i = 0; i < GetArraySize(g_hArrayTags); i++) 
	{
		GetArrayString(g_hArrayTags, i, tag, BUF_SZ);

		output = "";
		for (j = 0; j < GetArraySize(g_hArrayTagOrder); j++) 
		{
			GetArrayString(g_hArrayTagOrder, j, buffer, BUF_SZ);
			if (StrEqual(tag, buffer, false)) Format(output, BUF_SZ, "%s%s %d", output, output[0] == '\0' ? "" : ",", j + 1);
		}
		PrintToChat(client, "%s - %s", output, tag);

		GetTrieValue(g_hTriePools, tag, hArrayMapPool);
		for (j = 0; j < GetArraySize(hArrayMapPool); j++) 
		{
			GetArrayString(hArrayMapPool, j, buffer, BUF_SZ);

			FormatEx(output, BUF_SZ, "\t%s", buffer);
			if (GetPrettyName(buffer)) Format(output, BUF_SZ, "\x05%s \x01(%s)", output, buffer);
			PrintToChat(client, "%s", output);
		}
	}

	return Plugin_Handled;
}

// Abort a currently loaded mapset
public Action StopMixmap_Cmd(int client, any args) 
{
	if (!g_bMapsetInitialized ) 
	{
		CPrintToChat(client, "%t", "Not_Start");
		return Plugin_Handled;
	}
	if (IsClientAndInGame(client))
    {
        if (!IsBuiltinVoteInProgress())
        {
			int iNumPlayers;
			int[] iPlayers = new int[MaxClients];
			for (int i = 1; i <= MaxClients; i++)
			{
				if (!IsClientAndInGame(i) || (GetClientTeam(i) == 1))
				{
					continue;
				}
				iPlayers[iNumPlayers++] = i;
			}
			
			char cVoteTitle[32];
			Format(cVoteTitle, sizeof(cVoteTitle), "%T", "Cvote_Title_Off", LANG_SERVER);

			hVoteStopMixmap = CreateBuiltinVote(VoteStopMixmapActionHandler, BuiltinVoteType_Custom_YesNo, BuiltinVoteAction_Cancel | BuiltinVoteAction_VoteEnd | BuiltinVoteAction_End);

			SetBuiltinVoteArgument(hVoteStopMixmap, cVoteTitle);
			SetBuiltinVoteInitiator(hVoteStopMixmap, client);
			SetBuiltinVoteResultCallback(hVoteStopMixmap, VoteStopMixmapResultHandler);
			DisplayBuiltinVote(hVoteStopMixmap, iPlayers, iNumPlayers, 20);

			CPrintToChatAllEx(client, "%t", "Vote_Stop", client);
			FakeClientCommand(client, "Vote Yes");
        }
		else
		{
			PrintToChat(client, "%t", "Vote_Progress");
		}

        return Plugin_Handled;
    }

	return Plugin_Continue;
}

public void VoteStopMixmapActionHandler(Handle vote, BuiltinVoteAction action, int param1, int param2)
{
    switch (action)
    {
        case BuiltinVoteAction_End:
        {
            hVoteStopMixmap = null;
            CloseHandle(vote);
        }
        case BuiltinVoteAction_Cancel:
        {
			DisplayBuiltinVoteFail(vote, view_as<BuiltinVoteFailReason>(param1));
        }
        case BuiltinVoteAction_Select:
        {
            char cItemVal[64];
            char cItemName[64];
            GetBuiltinVoteItem(vote, param2, cItemVal, sizeof(cItemVal), cItemName, sizeof(cItemName));
        }
    }
}

public void VoteStopMixmapResultHandler(Handle vote, int num_votes, int num_clients, const int[][] client_info, int num_items, const int[][] item_info)
{
    for (int i = 0; i < num_items; i++)
    {
        if (item_info[i][BUILTINVOTEINFO_ITEM_INDEX] == BUILTINVOTES_VOTE_YES)
        {
            if (item_info[i][BUILTINVOTEINFO_ITEM_VOTES] > (num_clients / 2))
            {
                if (vote == hVoteStopMixmap)
                {
					DisplayBuiltinVotePass(vote, "stop Mixmap……");
					CreateTimer(1.0, StartVoteStopMixmap_Timer);
					return;
                }
            }
        }
    }
}

public Action StartVoteStopMixmap_Timer(Handle timer)
{
	if (g_hCountDownTimer) 
	{
		// interrupt any upcoming transitions
		KillTimer(g_hCountDownTimer, true);
	}
	PluginStartInit();
	
	CPrintToChatAll("%t", "Stop_Mixmap");
	return Plugin_Handled;
}

public Action StopMixmap(int client, any args) 
{
	if (!g_bMapsetInitialized) 
	{
		CPrintToChatAll("%t", "Not_Start");
		return Plugin_Handled;
	}

	if (g_hCountDownTimer) 
	{
		// interrupt any upcoming transitions
		KillTimer(g_hCountDownTimer, true);
	}

	PluginStartInit();

	CPrintToChatAllEx(client, "%t", "Stop_Mixmap_Admin", client);
	return Plugin_Handled;
}


// ----------------------------------------------------------
// 		Map set picking
// ----------------------------------------------------------

//creates the initial map list after a map set has been loaded
public Action Timed_PostMapSet(Handle timer) 
{
	int mapnum = GetArraySize(g_hArrayTagOrder);
	int triesize = GetTrieSize(g_hTriePools);

	if (mapnum == 0) 
	{
		g_bMapsetInitialized = false;	//failed to load it on the exec
		CPrintToChatAll("%t", "Fail_Load_Preset");
		return Plugin_Handled;
	}

	if (g_iMapCount < triesize) 
	{
		g_bMapsetInitialized = false;	//bad preset format
		CPrintToChatAll("%t", "Maps_Not_Match_Rank");
		return Plugin_Handled;
	}

	CPrintToChatAll("%t", "Select_Maps_Succeed");

	SelectRandomMap();
	return Plugin_Handled;
}

// ----------------------------------------------------------
// 		Map pool logic
// ----------------------------------------------------------

// Returns a handle to the first array which is found to contain the specified mapname
// (should be the first and only one)
stock Handle GetPoolThatContainsMap(char[] map, int index, char[] tag) 
{
	Handle hArrayMapPool;

	for (int i = 0; i < GetArraySize(g_hArrayTags); i++) 
	{
		GetArrayString(g_hArrayTags, i, tag, BUF_SZ);
		GetTrieValue(g_hTriePools, tag, hArrayMapPool);
		if ((index = FindStringInArray(hArrayMapPool, map)) >= 0) {
			return hArrayMapPool;
		}
	}
	return INVALID_HANDLE;
}

stock void SelectRandomMap() 
{
	g_bMaplistFinalized = true;
	//int test = view_as<int>(GetEngineTime());	//test
	SetRandomSeed(view_as<int>(GetEngineTime()));
	//CPrintToChatAll("种子：%d", test);
	//CPrintToChatAll("设种后第一次随机：%d", GetRandomInt(0,11));

	int i, mapIndex;
	Handle hArrayPool;
	char tag[BUF_SZ];
	char map[BUF_SZ];

	// Select 1 random map for each rank out of the remaining ones
	for (i = 0; i < GetArraySize(g_hArrayTagOrder); i++) 
	{
		GetArrayString(g_hArrayTagOrder, i, tag, BUF_SZ);
		GetTrieValue(g_hTriePools, tag, hArrayPool);
		mapIndex = GetRandomInt(0, GetArraySize(hArrayPool) - 1);
		//CPrintToChatAll("选图随机数%d：%d", i + 1, mapIndex);

		GetArrayString(hArrayPool, mapIndex, map, BUF_SZ);
		RemoveFromArray(hArrayPool, mapIndex);
		PushArrayString(g_hArrayMapOrder, map);
	}

	// Clear things because we only need the finalised map order in memory
	for (i = 0; i < GetArraySize(g_hArrayTagOrder); i++) 
	{
		GetArrayString(g_hArrayTagOrder, i, tag, BUF_SZ);
		GetTrieValue(g_hTriePools, tag, hArrayPool);
		ClearArray(hArrayPool);
	}
	ClearTrie(g_hTriePools);
	ClearArray(g_hArrayTagOrder);

	// Show final maplist to everyone
	for (i = 1; i <= MaxClients; i++) 
	{
		if (IsClientInGame(i) && !IsFakeClient(i)) 
		{
			FakeClientCommand(i, "sm_maplist");
		}
	}

	CPrintToChatAll("%t", "Change_Map_First");
	g_hCountDownTimer = CreateTimer(15.0, Timed_GiveThemTimeToReadTheMapList);
}

public Action Timed_GiveThemTimeToReadTheMapList(Handle timer) 
{
	g_hCountDownTimer = null;

	// call starting forward
	char buffer[BUF_SZ];
	GetArrayString(g_hArrayMapOrder, 0, buffer, BUF_SZ);

	Call_StartForward(g_hForwardStart);
	Call_PushCell(g_iMapCount);
	Call_PushString(buffer);
	Call_Finish();

	GotoNextMap(true);
	return Plugin_Handled;
}

// Specifiy a rank for a given tag
public Action TagRank(any args) {
	if (args < 2) 
	{
		ReplyToCommand(0, "Syntax: sm_tagrank <tag> <map number>");
		ReplyToCommand(0, "Sets tag <tag> as the tag to be used to fetch maps for map <map number> in the map list.");
		ReplyToCommand(0, "Rank 0 is map 1, rank 1 is map 2, etc.");

		return Plugin_Handled;
	}

	char buffer[BUF_SZ];
	GetCmdArg(2, buffer, BUF_SZ);
	int index = StringToInt(buffer);

	GetCmdArg(1, buffer, BUF_SZ);

	if (index >= GetArraySize(g_hArrayTagOrder)) 
	{
		ResizeArray(g_hArrayTagOrder, index + 1);
	}

	g_iMapCount++;
	SetArrayString(g_hArrayTagOrder, index, buffer);
	if (FindStringInArray(g_hArrayTags, buffer) < 0) 
	{
		PushArrayString(g_hArrayTags, buffer);
	}

	return Plugin_Handled;
}

// Add a map to the maplist under specified tags
public Action AddMap(any args) 
{
	if (args < 2) 
	{
		ReplyToCommand(0, "Syntax: sm_addmap <mapname> <tag1> <tag2> <...>");
		ReplyToCommand(0, "Adds <mapname> to the map selection and tags it with every mentioned tag.");

		return Plugin_Handled;
	}

	char map[BUF_SZ];
	GetCmdArg(1, map, BUF_SZ);

	char tag[BUF_SZ];

	//add the map under only one of the tags
	//TODO - maybe we should add it under all tags, since it might be removed from 1+ or even all of them anyway
	//also, if that ends up being implemented, remember to remove vetoed maps from ALL the pools it belongs to
	if (args == 2) 
	{
		GetCmdArg(2, tag, BUF_SZ);
	} 
	else 
	{
		GetCmdArg(GetRandomInt(2, args), tag, BUF_SZ);
	}

	Handle hArrayMapPool;
	if (! GetTrieValue(g_hTriePools, tag, hArrayMapPool)) 
	{
		SetTrieValue(g_hTriePools, tag, (hArrayMapPool = CreateArray(BUF_SZ/4)));
	}

	PushArrayString(hArrayMapPool, map);

	return Plugin_Handled;
}

// Return 0 if pretty name not found, 1 otherwise
stock int GetPrettyName(char[] map) 
{
	static Handle hKvMapNames = INVALID_HANDLE;
	if (hKvMapNames == INVALID_HANDLE) 
	{
		hKvMapNames = CreateKeyValues("Mixmap Map Names");
		if (! FileToKeyValues(hKvMapNames, PATH_KV)) 
		{
			LogMessage("Couldn't create KV for map names.");
			hKvMapNames = INVALID_HANDLE;
			return 0;
		}
	}

	char buffer[BUF_SZ];
	KvGetString(hKvMapNames, map, buffer, BUF_SZ, "no");
	if (! StrEqual(buffer, "no")) 
	{
		strcopy(map, BUF_SZ, buffer);
		return 1;
	}
	return 0;
}

// ----------------------------------------------------------
// 		Basic helpers
// ----------------------------------------------------------

stock bool IsClientAndInGame(int index) 
{
	return (index > 0 && index <= MaxClients && IsClientInGame(index) && IsClientConnected(index) && !IsFakeClient(index) && GetClientTeam(index) != 1);
}