/*
 ----------------------------------------------------------------
 Plugin      : SaveChat 
 Author      : citkabuto
 Game        : Any Source game
 Description : Will record all player messages to a file
 ================================================================
 Date       Version  Description
 ================================================================
 23/Feb/10  1.2.1    - Fixed bug with player team id
 15/Feb/10  1.2.0    - Now records team name when using cvar
                            sm_record_detail 
 01/Feb/10  1.1.1    - Fixed bug to prevent errors when using 
                       HLSW (client index 0 is invalid)
 31/Jan/10  1.1.0    - Fixed date format on filename
                       Added ability to record player info
                       when connecting using cvar:
                            sm_record_detail (0=none,1=all:def:1)
 28/Jan/10  1.0.0    - Initial Version 
 ----------------------------------------------------------------
*/

#include <sourcemod>
#include <sdktools>
#include <geoip.inc>
#include <string.inc>
#include <logger>
#include <left4dhooks>
#include <SteamWorks>

#define FLAG_STRINGS		14
#define PLUGIN_VERSION "SaveChat_1.2.2"
char g_FlagNames[FLAG_STRINGS][20] =
{
	"res",
	"admin",
	"kick",
	"ban",
	"unban",
	"slay",
	"map",
	"cvars",
	"cfg",
	"chat",
	"vote",
	"pass",
	"rcon",
	"cheat"
};

static String:chatFile[128]
new Handle:sc_record_detail = INVALID_HANDLE
Logger log, exp, player;
bool g_SkipOnce;
public Plugin:myinfo = 
{
	name = "SaveChat",
	author = "citkabuto",
	description = "Records player chat messages to a file",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=117116"
}

public OnPluginStart()
{
	new String:date[21]

	/* Register CVars */
	CreateConVar("sm_savechat_version", PLUGIN_VERSION, "Save Player Chat Messages Plugin", 
		FCVAR_DONTRECORD|FCVAR_REPLICATED)
	HookEvent("player_disconnect", Event_OnClientDisconnect)
	sc_record_detail = CreateConVar("sc_record_detail", "1", 
		"Record player Steam ID and IP address")

	/* Say commands */
	RegConsoleCmd("say", Command_Say)
	RegConsoleCmd("say_team", Command_SayTeam)
	/* Format date for log filename */
	FormatTime(date, sizeof(date), "%y%m%d", -1)


	Format(chatFile, 48, "Chat%s", date);
	log = new Logger(chatFile, LoggerType_NewLogFile);
	exp = new Logger(chatFile, LoggerType_NewLogFile);
	Format(chatFile, 48, "Player%s", date);
	player = new Logger(chatFile, LoggerType_NewLogFile);
	Format(chatFile, 48, "Command%s", date);
	exp.SetLogPrefix("exp_interface");
	player.SetLogPrefix("Player");
}

/*
 * Capture player chat and record to file
 */
public Action:Command_Say(client, args)
{
	LogChat(client, args, false)
	return Plugin_Continue
}


/*
 * Capture player team chat and record to file
 */
public Action:Command_SayTeam(client, args)
{
	LogChat(client, args, true)
	return Plugin_Continue
}

public void OnClientPostAdminCheck(client)
{
	/* Only record player detail if CVAR set */
	if(GetConVarInt(sc_record_detail) != 1)
		return

	if(IsFakeClient(client)) 
		return

	new String:msg[2048]
	new String:country[3]
	new String:steamID[128]
	new String:playerIP[50]
	
	GetClientAuthString(client, steamID, sizeof(steamID))

	AdminId id = GetUserAdmin(client);
	char flagstring[255];
	if (id != INVALID_ADMIN_ID)
	{
		int flags = GetUserFlagBits(client);
		char flagstring[255];
		if (flags == 0)
		{
			strcopy(flagstring, sizeof(flagstring), "无权限");
		}
		else if (flags & ADMFLAG_ROOT)
		{
			strcopy(flagstring, sizeof(flagstring), "root");
		}
		else
		{
			FlagsToString(flagstring, sizeof(flagstring), flags);
		}
	}


	/* Get 2 digit country code for current player */
	if(GetClientIP(client, playerIP, sizeof(playerIP), true) == false) {
		country   = "  "
	} else {
		if(GeoipCode2(playerIP, country) == false) {
			country = "  "
		}
	}
	
	Format(msg, sizeof(msg), "[%s] %N 进入游戏 ('%s' | '%s'%s)",
		country,
		client,
		steamID,
		playerIP,
		id != INVALID_ADMIN_ID ? flagstring : ""
		)

	log.info(msg)
	player.info(msg)
	CreateTimer(5.0, Timer_PerformWho, client);
}


public Action Timer_PerformWho(Handle timer, int target)
{
	char name[MAX_NAME_LENGTH];
	GetClientName(target, name, sizeof(name));
	
	bool show_name = false;
	char admin_name[MAX_NAME_LENGTH];
	AdminId id = GetUserAdmin(target);
	if (id != INVALID_ADMIN_ID && id.GetUsername(admin_name, sizeof(admin_name)))
	{
		show_name = true;
	}
	if (id == INVALID_ADMIN_ID)
	{
		return Plugin_Stop;
	}
	else
	{
		int flags = GetUserFlagBits(target);
		char flagstring[255];
		if (flags == 0)
		{
			strcopy(flagstring, sizeof(flagstring), "none");
			return Plugin_Stop;
		}
		else if (flags & ADMFLAG_ROOT)
		{
			strcopy(flagstring, sizeof(flagstring), "root");
		}
		else
		{
			FlagsToString(flagstring, sizeof(flagstring), flags);
		}
		
		if (show_name)
		{
			log.info("'%s' 为 云端管理 '%s'，拥有权限 '%s'", name, admin_name, flagstring);
			player.info("'%s' 为 云端管理 '%s'，拥有权限 '%s'", name, admin_name, flagstring);
		}
		else
		{
			log.info("'%s' 为 本地管理员，拥有权限 '%s'", name, flagstring);
			player.info("'%s' 为 云端管理 '%s'，拥有权限 '%s'", name, admin_name, flagstring);
		}
		
	}
	return Plugin_Stop;
}	


public void SteamWorks_OnValidateClient(int ownerauthid, int authid)
{
    int client = GetClientOfAuthId(authid);
    if (client == -1) return;
    if(ownerauthid != authid) {
		log.info("'%N' 为家庭共享账户，主账户authid为 '[U:1:%i]' !请知悉，中间一位数:1:可能为0", ownerauthid);
		player.info("'%N' 为家庭共享账户，主账户authid为 '[U:1:%i]' !请知悉，中间一位数:1:可能为0", ownerauthid);
	}
}
stock int GetClientOfAuthId(int authid)
{
    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsClientConnected(i))
        {
            char steamid[32]; GetClientAuthId(i, AuthId_Steam3, steamid, sizeof(steamid));
            char split[3][32]; 
            ExplodeString(steamid, ":", split, sizeof(split), sizeof(split[]));
            ReplaceString(split[2], sizeof(split[]), "]", "");
            //Split 1: [U:
            //Split 2: 1:
            //Split 3: 12345]
            
            int auth = StringToInt(split[2]);
            if(auth == authid) return i;
        }
    }

    return -1;
}
void FlagsToString(char[] buffer, int maxlength, int flags)
{
	char joins[FLAG_STRINGS+1][32];
	int total;

	for (int i=0; i<FLAG_STRINGS; i++)
	{
		if (flags & (1<<i))
		{
			strcopy(joins[total++], 32, g_FlagNames[i]);
		}
	}
	
	char custom_flags[32];
	if (CustomFlagsToString(custom_flags, sizeof(custom_flags), flags))
	{
		Format(joins[total++], 32, "custom(%s)", custom_flags);
	}

	ImplodeStrings(joins, total, ", ", buffer, maxlength);
}

int CustomFlagsToString(char[] buffer, int maxlength, int flags)
{
	char joins[6][6];
	int total;
	
	for (int i=view_as<int>(Admin_Custom1); i<=view_as<int>(Admin_Custom6); i++)
	{
		if (flags & (1<<i))
		{
			IntToString(i - view_as<int>(Admin_Custom1) + 1, joins[total++], 6);
		}
	}
	
	ImplodeStrings(joins, total, ",", buffer, maxlength);
	
	return total;
}

public Action Event_OnClientDisconnect(Event event, const char[] name, bool dontBroadcast){
		/* Only record player detail if CVAR set */
	if (g_SkipOnce){
		g_SkipOnce = false;
		return Plugin_Continue
	}
	g_SkipOnce = true;
	if(GetConVarInt(sc_record_detail) != 1)
		return Plugin_Continue
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsFakeClient(client)) 
		return Plugin_Continue

	new String:msg[2048]
	new String:country[3]
	new String:steamID[128]
	new String:playerIP[50]
	
	GetClientAuthString(client, steamID, sizeof(steamID))

	/* Get 2 digit country code for current player */
	if(GetClientIP(client, playerIP, sizeof(playerIP), true) == false) {
		country   = "  "
	} else {
		if(GeoipCode2(playerIP, country) == false) {
			country = "  "
		}
	}
	bool isADM;
	AdminId id = GetUserAdmin(client);
	isADM = GetAdminFlag(id, Admin_Generic);

	char reason[128];
	event.GetString("reason", reason, sizeof(reason));

	Format(msg, sizeof(msg), "[%s] %N 离开游戏 '%s' ('%s' | '%s'%s)",
		country,
		client,
		reason,
		steamID,
		playerIP,
		isADM ? " | 管理员" : ""
		)

	log.info(msg)
	player.info(msg)
	return Plugin_Continue

}
/*
 * Extract all relevant information and format 
 */
public LogChat(client, args, bool:teamchat)
{
	new String:msg[2048]
	new String:text[1024]
	new String:country[3]
	new String:playerIP[50]
	new String:teamName[20]

	GetCmdArgString(text, sizeof(text))
	StripQuotes(text)

	if(client == 0) {
		/* Don't try and obtain client country/team if this is a console message */
		Format(country, sizeof(country), "  ")
		Format(teamName, sizeof(teamName), "")
	} else {
		/* Get 2 digit country code for current player */
		if(GetClientIP(client, playerIP, sizeof(playerIP), true) == false) {
			country   = "  "
		} else {
			if(GeoipCode2(playerIP, country) == false) {
				country = "  "
			}
		}
		GetTeamName(GetClientTeam(client), teamName, sizeof(teamName))
	}

	if(GetConVarInt(sc_record_detail) == 1) {
		Format(msg, sizeof(msg), "[%s] [%s] %N :%s %s",
			country,
			teamName,
			client,
			teamchat == true ? " (TEAM)" : "",
			text)
	} else {
		Format(msg, sizeof(msg), "[%s] %N :%s '%s'",
			country,
			client,
			teamchat == true ? " (TEAM)" : "",
			text)
	}


	log.info(msg)
}
/*
 * Log a map transition
 */
public OnMapStart(){
	new String:map[128]
	char cfg[64];
	ConVar config = FindConVar("l4d_ready_cfg_name");
	GetConVarString(config != INVALID_HANDLE ? config : FindConVar("mp_gamemode"), cfg, sizeof(cfg))
	GetCurrentMap(map, sizeof(map))
	ConVar sname = FindConVar("hostname");
	char name[64];
	sname.GetString(name, sizeof(name));
	log.lograw("--=================================================================--")
	log.info(  "* >>> %s <<<", name)
	log.info(  "* 地图 >>> '%s'   ", 		map);
	log.info(  "* 配置文件: '%s'", 			cfg);
	log.info(  "* 比分 %i : %i", 			L4D2Direct_GetVSCampaignScore(GameRules_GetProp("m_bAreTeamsFlipped")), L4D2Direct_GetVSCampaignScore(!GameRules_GetProp("m_bAreTeamsFlipped")));
	log.lograw("----------------------------------")

	player.lograw("--=================================================================--")
}
