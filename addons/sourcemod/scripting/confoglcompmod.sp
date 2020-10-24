#pragma semicolon 1

#if defined(AUTOVERSION)
#include "version.inc"
#else
#define PLUGIN_VERSION	"2.2.4"
#endif

#if !defined(DEBUG_ALL)
#define DEBUG_ALL 	0
#endif

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>
#include <colors>
#include "includes/constants.sp"
#include "includes/functions.sp"
#include "includes/debug.sp"
#include "includes/survivorindex.sp"
#include "includes/configs.sp"
#include "includes/customtags.inc"

#include "modules/MapInfo.sp"
#include "modules/WeaponInformation.sp"
#include "modules/ReqMatch.sp"
#include "modules/CvarSettings.sp"
#include "modules/GhostTank.sp"
#include "modules/WaterSlowdown.sp"
#include "modules/UnreserveLobby.sp"
#include "modules/GhostWarp.sp"
#include "modules/UnprohibitBosses.sp"
#include "modules/PasswordSystem.sp"
#include "modules/BotKick.sp"
#include "modules/EntityRemover.sp"
#include "modules/ScoreMod.sp"
#include "modules/FinaleSpawn.sp"
#include "modules/BossSpawning.sp"
//#include "modules/WeaponCustomization.sp"
#include "modules/l4dt_forwards.sp"
#include "modules/ClientSettings.sp"
#include "modules/ItemTracking.sp"
//#include "modules/SpectatorHud.sp"

public Plugin:myinfo = 
{
	name = "Confogl's Competitive Mod",
	author = "Confogl Team",
	description = "A competitive mod for L4D2",
	version = PLUGIN_VERSION,
	url = "http://confogl.googlecode.com/"
}

public OnPluginStart()
{
	Debug_OnModuleStart();
	Configs_OnModuleStart();
	MI_OnModuleStart();
	SI_OnModuleStart();
	WI_OnModuleStart();
	
	RM_OnModuleStart();
	
	CVS_OnModuleStart();
	PS_OnModuleStart();
	UL_OnModuleStart();
	
	ER_OnModuleStart();
	GW_OnModuleStart();
	WS_OnModuleStart();
	GT_OnModuleStart();
	UB_OnModuleStart();
	
	BK_OnModuleStart();
	
	SM_OnModuleStart();
	FS_OnModuleStart();
	BS_OnModuleStart();
	//WC_OnModuleStart();
	CLS_OnModuleStart();
	IT_OnModuleStart();
	//SH_OnModuleStart();
	
	AddCustomServerTag("confogl", true);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	RM_APL();
	Configs_APL();
	MI_APL();
	RegPluginLibrary("confogl");
}

public OnPluginEnd()
{
	CVS_OnModuleEnd();
	PS_OnModuleEnd();
	ER_OnModuleEnd();
	SM_OnModuleEnd();
	
	WS_OnModuleEnd();
	RemoveCustomServerTag("confogl");
}

public OnGameFrame()
{
	WS_OnGameFrame();
}

public OnMapStart()
{
	MI_OnMapStart();
	RM_OnMapStart();
	
	SM_OnMapStart();
	BS_OnMapStart();
	IT_OnMapStart();
}

public OnMapEnd()
{
	MI_OnMapEnd();
	WI_OnMapEnd();
	PS_OnMapEnd();
	WS_OnMapEnd();
}

public OnConfigsExecuted()
{
	CVS_OnConfigsExecuted();
}

public OnClientDisconnect(client)
{
	RM_OnClientDisconnect(client);
	//GT_OnClientDisconnect(client);
	//SH_OnClientDisconnect(client);
}

public OnClientPutInServer(client)
{
	RM_OnClientPutInServer();
	UL_OnClientPutInServer();
	PS_OnClientPutInServer(client);
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(GW_OnPlayerRunCmd(client, buttons))
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}