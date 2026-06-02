/*  
*    Fixes for gamebreaking bugs and stupid gameplay aspects
*    Copyright (C) 2020  LuxLuma		acceliacat@gmail.com
*
*    This program is free software: you can redistribute it and/or modify
*    it under the terms of the GNU General Public License as published by
*    the Free Software Foundation, either version 3 of the License, or
*    (at your option) any later version.
*
*    This program is distributed in the hope that it will be useful,
*    but WITHOUT ANY WARRANTY; without even the implied warranty of
*    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*    GNU General Public License for more details.
*
*    You should have received a copy of the GNU General Public License
*    along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <dhooks>

#pragma newdecls required


#define DEBUG 0

#define GAMEDATA "survivor_afk_fix"
#define PLUGIN_VERSION	"1.0.4"

#if DEBUG
Handle hAFKSDKCall;
#endif

Handle hSetHumanSpecSDKCall;
Handle hSetObserverTargetSDKCall;

bool g_bShouldFixAFK = false;
int g_iSurvivorBot;
bool g_bShouldIgnore = false;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if(GetEngineVersion() != Engine_Left4Dead2 && GetEngineVersion() != Engine_Left4Dead)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1/2");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public Plugin myinfo =
{
	name = "[L4D2]Survivor_AFK_Fix",
	author = "Lux",
	description = "Fixes survivor going AFK game function.",
	version = PLUGIN_VERSION,
	url = "https://github.com/LuxLuma/Left-4-fix/tree/master/left%204%20fix/survivors/survivor_afk_fix"
};

public void OnPluginStart()
{
	CreateConVar("survivor_afk_fix_ver", PLUGIN_VERSION, "", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	Handle hGamedata = LoadGameConfigFile(GAMEDATA);
	if(hGamedata == null) 
		SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);
	
	Handle hDetour;
	hDetour = DHookCreateFromConf(hGamedata, "CTerrorPlayer::GoAwayFromKeyboard");
	if(!hDetour)
		SetFailState("Failed to find 'CTerrorPlayer::GoAwayFromKeyboard' signature");
	
	if(!DHookEnableDetour(hDetour, false, OnGoAFKPre))
		SetFailState("Failed to detour 'CTerrorPlayer::GoAwayFromKeyboard'");
	if(!DHookEnableDetour(hDetour, true, OnGoAFKPost))
		SetFailState("Failed to detour 'CTerrorPlayer::GoAwayFromKeyboard'");
	
	hDetour = DHookCreateFromConf(hGamedata, "SurvivorBot::SetHumanSpectator");
	if(!hDetour)
		SetFailState("Failed to find 'SurvivorBot::SetHumanSpectator' signature");
	
	if(!DHookEnableDetour(hDetour, false, OnSetHumanSpectatorPre))
		SetFailState("Failed to detour 'SurvivorBot::SetHumanSpectator'");
	
	StartPrepSDKCall(SDKCall_Player);
	if(!PrepSDKCall_SetFromConf(hGamedata, SDKConf_Signature, "SurvivorBot::SetHumanSpectator"))
		SetFailState("Error finding the 'SurvivorBot::SetHumanSpectator' signature.");
		
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	hSetHumanSpecSDKCall = EndPrepSDKCall();
	if(hSetHumanSpecSDKCall == null)
		SetFailState("Unable to prep SDKCall 'SurvivorBot::SetHumanSpectator'");
		
	StartPrepSDKCall(SDKCall_Player);
	if(!PrepSDKCall_SetFromConf(hGamedata, SDKConf_Virtual, "CTerrorPlayer::SetObserverTarget"))
		SetFailState("Error finding the 'CTerrorPlayer::SetObserverTargetv' offset.");
		
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	hSetObserverTargetSDKCall = EndPrepSDKCall();
	if(hSetObserverTargetSDKCall == null)
		SetFailState("Unable to prep SDKCall 'CTerrorPlayer::SetObserverTarget'");
	
	
	#if DEBUG
	StartPrepSDKCall(SDKCall_Player);
	if(!PrepSDKCall_SetFromConf(hGamedata, SDKConf_Signature, "CTerrorPlayer::GoAwayFromKeyboard"))
		SetFailState("Error finding the 'CTerrorPlayer::GoAwayFromKeyboard' signature.");
		
	hAFKSDKCall = EndPrepSDKCall();
	if(hAFKSDKCall == null)
		SetFailState("Unable to prep SDKCall 'CTerrorPlayer::GoAwayFromKeyboard'");
	
	RegAdminCmd("sm_afktest", AFKTEST, ADMFLAG_ROOT);
	#endif
	
	delete hGamedata;
}

#if DEBUG
public Action AFKTEST(int client, int args)
{
	if(client == 0)
		return Plugin_Handled;
	
	SDKCall(hAFKSDKCall, client);
	return Plugin_Handled;
}
#endif

public MRESReturn OnGoAFKPre(int pThis, Handle hReturn)
{
	if(g_bShouldFixAFK)
		LogError("Something wentwrong here 'CTerrorPlayer::GoAwayFromKeyboard' :(");
	
	g_bShouldFixAFK = true;
}

//Only thing we need is the bot single threaded logic means we use the call order
public void OnEntityCreated(int entity, const char[] classname)
{
	if(!g_bShouldFixAFK)
		return;
	
	if(classname[0] != 's' || !StrEqual(classname, "survivor_bot", false))
		return;
	
	g_iSurvivorBot = entity;
}


public MRESReturn OnSetHumanSpectatorPre(int pThis, Handle hParams)
{
	if(g_bShouldIgnore)
		return MRES_Ignored;
	
	if(!g_bShouldFixAFK)
		return MRES_Ignored;
	
	if(g_iSurvivorBot < 1)
		return MRES_Ignored;
	
	return MRES_Supercede;
}

//pThis should only be CTerrorPlayer class and real players only not going to check for it
public MRESReturn OnGoAFKPost(int pThis, Handle hReturn)
{
	if(g_bShouldFixAFK && g_iSurvivorBot > 0 && IsFakeClient(g_iSurvivorBot))
	{
		g_bShouldIgnore = true;
		
		SDKCall(hSetHumanSpecSDKCall, g_iSurvivorBot, pThis);
		SDKCall(hSetObserverTargetSDKCall, pThis, g_iSurvivorBot);
		
		WriteTakeoverPanel(pThis, g_iSurvivorBot);
		
		g_bShouldIgnore = false;
	}
	
	g_iSurvivorBot = 0;
	g_bShouldFixAFK = false;
	return MRES_Ignored;
}

//Thanks Leonardo for helping me with the vgui keyvalue layout
//This is for rare case sometimes the takeover panel don't show.
void WriteTakeoverPanel(int client, int bot)
{
	char buf[2];
	int character = GetEntProp(bot, Prop_Send, "m_survivorCharacter", 1);
	IntToString(character, buf, sizeof(buf));
	BfWrite msg = view_as<BfWrite>(StartMessageOne("VGUIMenu", client));
	msg.WriteString("takeover_survivor_bar"); //type
	msg.WriteByte(true); //hide or show panel type
	msg.WriteByte(1); //amount of keys
	msg.WriteString("character"); //key name
	msg.WriteString(buf); //key value
	EndMessage();
}