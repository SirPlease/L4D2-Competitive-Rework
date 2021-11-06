#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define MAX_ENTITY_NAME_SIZE 64
#define MAX_MAP_NAME_SIZE 64

#define DMG_TYPE_SPIT (DMG_RADIATION|DMG_ENERGYBEAM)
#define PLUGIN_TAG "l4d2_spitblock"

bool
	g_bIsBlockEnable = false;

float
	g_fBlockSquare[4] = {0.0, ...};

StringMap
	g_hSpitBlockSquares = null;

bool
	g_bLateLoad = false;

public Plugin myinfo =
{
	name = "L4D2 Spit Blocker",
	author = "ProdigySim, Estoopi, Jacob, Visor, A1m`",
	description = "Blocks spit damage on various maps",
	version = "2.3",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_bLateLoad = late;

	return APLRes_Success;
}

public void OnPluginStart()
{
	g_hSpitBlockSquares = new StringMap();
	
	RegServerCmd("spit_block_square", AddSpitBlockSquare);
	RegServerCmd("spit_remove_block_square", RemoveSpitBlockSquare);
	
	if (g_bLateLoad) {
		for (int i = 1; i <= MaxClients; i++) {
			if (IsClientInGame(i)) {
				OnClientPostAdminCheck(i);
			}
		}
	}
}

public Action AddSpitBlockSquare(int iArgs)
{
	float fSquare[4];
	char sMapName[MAX_MAP_NAME_SIZE], sBuffer[32], sGetCmd[128];
	
	if (iArgs != 5) {
		GetCmdArgString(sGetCmd, sizeof(sGetCmd));
		ErrorAnnounce("[%s] You entered the wrong number of arguments '%f'. Need 5 arguments.", PLUGIN_TAG, sGetCmd);
		ErrorAnnounce("[%s] Usage: spit_block_square <mapname> <x1> <y1> <x2> <y2>.", PLUGIN_TAG);
		return Plugin_Handled;
	}
	
	GetCmdArg(1, sMapName, sizeof(sMapName));

	for (int i = 0; i < 4; i++) {
		GetCmdArg(2 + i, sBuffer, sizeof(sBuffer));
		fSquare[i] = StringToFloat(sBuffer);
	}
	
	g_hSpitBlockSquares.SetArray(sMapName, fSquare, sizeof(fSquare), true);

	OnMapStart();
	
	//PrintToServer("[%s] Spit block square added on this map '%s'.", PLUGIN_TAG, sMapName);
	
	return Plugin_Handled;
}

public Action RemoveSpitBlockSquare(int iArgs)
{
	float fSquare[4];
	char sMapName[MAX_MAP_NAME_SIZE], sGetCmd[128];
	
	if (iArgs != 1) {
		GetCmdArgString(sGetCmd, sizeof(sGetCmd));
		ErrorAnnounce("[%s] You entered the wrong number of arguments '%f'. Need 1 argument.", PLUGIN_TAG, sGetCmd);
		ErrorAnnounce("[%s] Usage: spit_remove_block_square <mapname>.", PLUGIN_TAG);
		return Plugin_Handled;
	}
	
	GetCmdArg(1, sMapName, sizeof(sMapName));
	if (g_hSpitBlockSquares.GetArray(sMapName, fSquare, sizeof(fSquare))) {
		g_hSpitBlockSquares.Remove(sMapName);
		PrintToServer("[%s] Spit block square removed on this map '%s'.", PLUGIN_TAG, sMapName);
	} else {
		PrintToServer("[%s] Сould not find the specified map '%s'.", PLUGIN_TAG, sMapName);
	}
	
	OnMapStart();

	return Plugin_Handled;
}

public void OnMapStart()
{
	char sMapName[MAX_MAP_NAME_SIZE];
	GetCurrentMap(sMapName, sizeof(sMapName));
	
	if (g_hSpitBlockSquares.GetArray(sMapName, g_fBlockSquare, sizeof(g_fBlockSquare))) {
		g_bIsBlockEnable = true;
		return;
	}
	
	for (int i = 0; i < sizeof(g_fBlockSquare); i++) {
		g_fBlockSquare[i] = 0.0;
	}

	g_bIsBlockEnable = false;
}

public void OnClientPostAdminCheck(int iClient)
{
	SDKHook(iClient, SDKHook_OnTakeDamage, stop_spit_dmg);
}

public Action stop_spit_dmg(int iVictim, int &iAttacker, int &iInflictor, float &fDamage, int &iDamageType)
{
	if (!g_bIsBlockEnable || !(iDamageType & DMG_TYPE_SPIT)) { //for performance
		return Plugin_Continue;
	}
	
	if (!IsInsectSwarm(iInflictor) || !IsValidClient(iVictim)) {
		return Plugin_Continue;
	}

	float fOrigin[3];
	GetClientAbsOrigin(iVictim, fOrigin);
	if (isPointIn2DBox(fOrigin[0], fOrigin[1], g_fBlockSquare[0], g_fBlockSquare[1], g_fBlockSquare[2], g_fBlockSquare[3])) {
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

// Is x0, y0 in the box defined by x1, y1 and x2, y2
bool isPointIn2DBox(float x0, float y0, float x1, float y1, float x2, float y2)
{
	if (x1 > x2) {
		if (y1 > y2) {
			return (x0 <= x1 && x0 >= x2 && y0 <= y1 && y0 >= y2);
		} else {
			return (x0 <= x1 && x0 >= x2 && y0 >= y1 && y0 <= y2);
		}
	} else {
		if(y1 > y2) {
			return (x0 >= x1 && x0 <= x2 && y0 <= y1 && y0 >= y2);
		} else {
			return (x0 >= x1 && x0 <= x2 && y0 >= y1 && y0 <= y2);
		}
	}
}

bool IsInsectSwarm(int iEntity)
{
	if (iEntity <= MaxClients || !IsValidEdict(iEntity)) {
		return false;
	}

	char sClassName[MAX_ENTITY_NAME_SIZE];
	GetEdictClassname(iEntity, sClassName, sizeof(sClassName));
	return (strcmp(sClassName, "insect_swarm") == 0);
}

bool IsValidClient(int iClient)
{
	return (iClient > 0 && iClient <= MaxClients /*&& IsClientInGame(iClient)*/); //need?
}

void ErrorAnnounce(const char[] szFormat, any ...)
{
	int iLen = strlen(szFormat) + 255;
	char[] szBuffer = new char[iLen];
	VFormat(szBuffer, iLen, szFormat, 2);
 
	LogError(szBuffer);
	PrintToServer(szBuffer);
}
