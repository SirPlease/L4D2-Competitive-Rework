#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define			RM_DEBUG					0

#define			RM_DEBUG_PREFIX			"[ReqMatch]"

const	Float:	MAPRESTARTTIME			= 3.0;
const	Float:	RESETMINTIME			= 60.0;

new		bool:	RM_bMatchRequest[2];
new		bool:	RM_bIsMatchModeLoaded;
new		bool:	RM_bIsAMatchActive;
new		bool:	RM_bIsPluginsLoaded;
new		bool:	RM_bIsMapRestarted;
new		Handle:	RM_hDoRestart;
new		Handle:	RM_hAllowVoting;
new		Handle:	RM_hReloaded;
new		Handle:	RM_hAutoLoad;
new		Handle:	RM_hAutoCfg;
new		Handle: RM_hFwdMatchLoad;
new		Handle: RM_hFwdMatchUnload;
new 	Handle:	RM_hConfigFile_On;
new 	Handle:	RM_hConfigFile_Plugins;
new 	Handle:	RM_hConfigFile_Off;

RM_OnModuleStart()
{
	RM_hDoRestart			= CreateConVarEx("match_restart"		, "1", "Sets whether the plugin will restart the map upon match mode being forced or requested");
	RM_hAllowVoting			= CreateConVarEx("match_allowvoting"	, "1", "Sets whether players can vote/request for match mode");
	RM_hAutoLoad			= CreateConVarEx("match_autoload"		, "0", "Has match mode start up automatically when a player connects and the server is not in match mode");
	RM_hAutoCfg				= CreateConVarEx("match_autoconfig"		, "", "Specify which config to load if the autoloader is enabled");
	RM_hConfigFile_On		= CreateConVarEx("match_execcfg_on"		, "confogl.cfg" 		, "Execute this config file upon match mode starts and every map after that.");
	RM_hConfigFile_Plugins	= CreateConVarEx("match_execcfg_plugins", "generalfixes.cfg;confogl_plugins.cfg;sharedplugins.cfg" , "Execute this config file upon match mode starts. This will only get executed once and meant for plugins that needs to be loaded.");
	RM_hConfigFile_Off		= CreateConVarEx("match_execcfg_off"	, "confogl_off.cfg" 	, "Execute this config file upon match mode ends.");

	
	//RegConsoleCmd("sm_match", RM_Cmd_Match);
	RegAdminCmd("sm_forcematch",	RM_Cmd_ForceMatch, ADMFLAG_CONFIG, "Forces the game to use match mode");
	RegAdminCmd("sm_fm",	RM_Cmd_ForceMatch, ADMFLAG_CONFIG, "Forces the game to use match mode");
	RegAdminCmd("sm_resetmatch",	RM_Cmd_ResetMatch, ADMFLAG_CONFIG, "Forces match mode to turn off REGRADLESS for always on or forced match");
	
	RM_hReloaded = FindConVarEx("match_reloaded");
	if(RM_hReloaded == INVALID_HANDLE)
	{
		RM_hReloaded = CreateConVarEx("match_reloaded", "0", "DONT TOUCH THIS CVAR! This is to prevent match feature keep looping, however the plugin takes care of it. Don't change it!",FCVAR_DONTRECORD|FCVAR_UNLOGGED);
	}
	
	new bool:bIsReloaded = GetConVarBool(RM_hReloaded);
	if(bIsReloaded)
	{
		if(RM_DEBUG || IsDebugEnabled())
			LogMessage("%s Plugin was reloaded from match mode, executing match load",RM_DEBUG_PREFIX);
		
		RM_bIsPluginsLoaded = true;
		SetConVarInt(RM_hReloaded,0);
		RM_Match_Load();
	}
}

RM_APL()
{
	RM_hFwdMatchLoad = CreateGlobalForward("LGO_OnMatchModeLoaded", ET_Event);
	RM_hFwdMatchUnload = CreateGlobalForward("LGO_OnMatchModeUnloaded", ET_Event);
	CreateNative("LGO_IsMatchModeLoaded", native_IsMatchModeLoaded);

}

public native_IsMatchModeLoaded(Handle:plugin, numParams)
{
	return RM_bIsMatchModeLoaded;
}

RM_OnMapStart()
{
	if(!RM_bIsMatchModeLoaded) return;
	
	if(RM_DEBUG || IsDebugEnabled())
		LogMessage("%s New map, executing match config...",RM_DEBUG_PREFIX);
	
	
	RM_Match_Load();
}

RM_OnClientPutInServer()
{
	if (!GetConVarBool(RM_hAutoLoad) || RM_bIsAMatchActive) return;
	
	decl String:buffer[128];
	GetConVarString(RM_hAutoCfg, buffer, sizeof(buffer));
	
	RM_UpdateCfgOn(buffer);
	RM_Match_Load();
}

RM_Match_Load()
{
	if(RM_DEBUG || IsDebugEnabled())
		LogMessage("%s Match Load",RM_DEBUG_PREFIX);
	
	if(!RM_bIsAMatchActive)
	{
		RM_bIsAMatchActive = true;
	}

	SetConVarInt(FindConVar("sb_all_bot_game"),1);
	decl String:sBuffer[128];
	
	if(!RM_bIsPluginsLoaded)
	{
		if(RM_DEBUG || IsDebugEnabled())
			LogMessage("%s Loading plugins and reload self",RM_DEBUG_PREFIX);
		
		
		SetConVarInt(RM_hReloaded,1);
		GetConVarString(RM_hConfigFile_Plugins,sBuffer,sizeof(sBuffer));
		char sPieces[32][256];
		int iNumPieces = ExplodeString(sBuffer, ";", sPieces, sizeof(sPieces), sizeof(sPieces[]));

		// Unlocking and Unloading Plugins.
		ServerCommand("sm plugins load_unlock");
		ServerCommand("sm plugins unload_all");

		// Loading Plugins.
		for(int i = 0; i < iNumPieces; i++)
		{
			ExecuteCfg(sPieces[i]);
		}

		return;
	}
	
	GetConVarString(RM_hConfigFile_On,sBuffer,sizeof(sBuffer));
	ExecuteCfg(sBuffer);
	if(RM_DEBUG || IsDebugEnabled())
		LogMessage("%s Match config executed",RM_DEBUG_PREFIX);
	
	if(RM_bIsMatchModeLoaded) return;
	
	if(RM_DEBUG || IsDebugEnabled())
		LogMessage("%s Setting match mode active",RM_DEBUG_PREFIX);
	
	RM_bIsMatchModeLoaded = true;
	IsPluginEnabled(true,true);
	
	CPrintToChatAll("{blue}[{default}Confogl{blue}] {default}Match mode loaded!");
	
	if(!RM_bIsMapRestarted && GetConVarBool(RM_hDoRestart))
	{
		CPrintToChatAll("{blue}[{default}Confogl{blue}] {default}Restarting map!");
		CreateTimer(MAPRESTARTTIME,RM_Match_MapRestart_Timer);
	}
	
	if(RM_DEBUG || IsDebugEnabled())
		LogMessage("%s Match mode loaded!",RM_DEBUG_PREFIX);
	Call_StartForward(RM_hFwdMatchLoad);
	Call_Finish();	
}

RM_Match_Unload(bool:bForced=false)
{
	if(!IsHumansOnServer() || bForced)
	{
		if(RM_DEBUG || IsDebugEnabled())
			LogMessage("%s Match ís no longer active, sb_all_bot_game reset to 0, IsHumansOnServer %b, bForced %b",RM_DEBUG_PREFIX,IsHumansOnServer(),bForced);
		
		RM_bIsAMatchActive = false;
		SetConVarInt(FindConVar("sb_all_bot_game"),0);
	}
	
	if(IsHumansOnServer() && !bForced) return;
	
	if(RM_DEBUG || IsDebugEnabled())
		LogMessage("%s Unloading match mode...",RM_DEBUG_PREFIX);
	
	decl String:sBuffer[128];
	RM_bIsMatchModeLoaded = false;
	IsPluginEnabled(true,false);
	RM_bIsMapRestarted = false;
	RM_bIsPluginsLoaded = false;
	
	Call_StartForward(RM_hFwdMatchUnload);
	Call_Finish();	

	CPrintToChatAll("{blue}[{default}Confogl{blue}] {default}Match mode unloaded!");
	
	GetConVarString(RM_hConfigFile_Off,sBuffer,sizeof(sBuffer));
	ExecuteCfg(sBuffer);
	
	if(RM_DEBUG || IsDebugEnabled())
		LogMessage("%s Match mode unloaded!",RM_DEBUG_PREFIX);
	
}

public Action:RM_Match_MapRestart_Timer(Handle:timer)
{
	ServerCommand("sm plugins load_lock");
	
	if(RM_DEBUG || IsDebugEnabled())
		LogMessage("%s Restarting map...",RM_DEBUG_PREFIX);
	
	decl String:sBuffer[128];
	GetCurrentMap(sBuffer,sizeof(sBuffer));
	ServerCommand("changelevel %s",sBuffer);
	RM_bIsMapRestarted = true;
	// Locking Up.
}

RM_UpdateCfgOn(const String:cfgfile[])
{
	if(SetCustomCfg(cfgfile))
	{
		CPrintToChatAll("{blue}[{default}Confogl{blue}] {default}Loading {olive}%s", cfgfile);
		RM_Match_Load();

		if(RM_DEBUG || IsDebugEnabled())
		{
			LogMessage("%s Starting match on config %s", RM_DEBUG_PREFIX, cfgfile);
		}
	}
}

public Action:RM_Cmd_ForceMatch(client, args)
{
	if(RM_bIsMatchModeLoaded) { return Plugin_Handled; }

	
	if(RM_DEBUG || IsDebugEnabled())
		LogMessage("%s Match mode forced to load!",RM_DEBUG_PREFIX);
		
	if(args > 0) // cfgfile specified
	{
		static String:sBuffer[128];
		GetCmdArg(1, sBuffer, sizeof(sBuffer));
		RM_UpdateCfgOn(sBuffer);
	}
	else
	{
		CPrintToChat(client, "{blue}[{default}Confogl{blue}] {default}Please specify a {olive}Config {default}to load.");
	}
	
	return Plugin_Handled;
}

public Action:RM_Cmd_ResetMatch(client,args)
{
	if(!RM_bIsMatchModeLoaded){return Plugin_Handled;}
	
	if(RM_DEBUG || IsDebugEnabled())
		LogMessage("%s Match mode forced to unload!",RM_DEBUG_PREFIX);
	
	
	RM_Match_Unload(true);
	
	return Plugin_Handled;
}

public Action:RM_Cmd_Match(client, args)
{
	if(RM_bIsMatchModeLoaded || (!IsVersus() && !IsScavenge()) || !GetConVarBool(RM_hAllowVoting)){return Plugin_Handled;}
	
	new iTeam = GetClientTeam(client);
	if((iTeam == TEAM_SURVIVOR || iTeam == TEAM_INFECTED) && !RM_bMatchRequest[iTeam-2])
	{
		RM_bMatchRequest[iTeam-2] = true;
	}
	else
	{
		return Plugin_Handled;
	}
	
	if(RM_bMatchRequest[0] && RM_bMatchRequest[1])
	{
		PrintToChatAll("\x01[\x05Confogl\x01] Both teams have agreed to start a competitive match!");
		RM_Match_Load();
	}
	else if(RM_bMatchRequest[0] || RM_bMatchRequest[1])
	{
		PrintToChatAll("\x01[\x05Confogl\x01] The \x04%s \x01have requested to start a competitive match. The \x04%s \x01must accept with \x04/match \x01command!",g_sTeamName[iTeam+4],g_sTeamName[iTeam+3]);
		if(args > 0) // cfgfile specified
		{
			static String:sBuffer[128];
			GetCmdArg(1, sBuffer, sizeof(sBuffer));
			RM_UpdateCfgOn(sBuffer);
		}
		else
		{
			SetCustomCfg("");
		}
		CreateTimer(30.0, RM_MatchRequestTimeout);
	}
	
	return Plugin_Handled;
}

public Action:RM_MatchRequestTimeout(Handle:timer){RM_ResetMatchRequest();}

public Action:RM_MatchResetTimer(Handle:timer)
{
	RM_Match_Unload();
}

RM_OnClientDisconnect(client)
{
	if(IsFakeClient(client) || !RM_bIsMatchModeLoaded) return;
	CreateTimer(RESETMINTIME, RM_MatchResetTimer);
}

RM_ResetMatchRequest()
{
	ResetConVar(RM_hConfigFile_On);
	RM_bMatchRequest[0] = false;
	RM_bMatchRequest[1] = false;
}