#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define DMG_TYPE_SPIT (DMG_RADIATION|DMG_ENERGYBEAM)
#define PLUGIN_TAG "l4d2_spitblock"

bool
	IsBlockEnable = false;

float
	block_square[4];

StringMap
	hSpitBlockSquares;

bool
	bLateLoad;

public Plugin myinfo =
{
	name = "L4D2 Spit Blocker",
	author = "ProdigySim, Estoopi, Jacob, Visor, A1m`",
	description = "Blocks spit damage on various maps",
	version = "2.2",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	bLateLoad = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	hSpitBlockSquares = new StringMap();
	
	RegServerCmd("spit_block_square", AddSpitBlockSquare);
	RegServerCmd("spit_remove_block_square", RemoveSpitBlockSquare);
	
	if (bLateLoad) {
		OnMapStart();
		for (int i = 1; i <= MaxClients; i++) {
			if (IsClientInGame(i)) {
				OnClientPostAdminCheck(i);
			}
		}
	}
}

public Action AddSpitBlockSquare(int args)
{
	static float square[4];
	static char mapname[64], buf[32], sGetCmd[128];
	
	if (args != 5) {
		GetCmdArgString(sGetCmd, sizeof(sGetCmd));
		ErrorAnnounce("[%s] You entered the wrong number of arguments '%f'. Need 5 arguments.", PLUGIN_TAG, sGetCmd);
		ErrorAnnounce("[%s] Usage: spit_block_square <mapname> <x1> <y1> <x2> <y2>.", PLUGIN_TAG);
		return Plugin_Handled;
	}
	
	GetCmdArg(1, mapname, sizeof(mapname));

	for (int i = 0; i < 4; i++) {
		GetCmdArg(2 + i, buf, sizeof(buf));
		square[i] = StringToFloat(buf);
	}
	
	hSpitBlockSquares.SetArray(mapname, square, sizeof(square), true);

	OnMapStart();
	
	//PrintToServer("[%s] Spit block square added on this map '%s'.", PLUGIN_TAG, mapname);
	
	return Plugin_Handled;
}

public Action RemoveSpitBlockSquare(int args)
{
	static float square[4];
	static char mapname[64], sGetCmd[128];
	
	if (args != 1) {
		GetCmdArgString(sGetCmd, sizeof(sGetCmd));
		ErrorAnnounce("[%s] You entered the wrong number of arguments '%f'. Need 1 argument.", PLUGIN_TAG, sGetCmd);
		ErrorAnnounce("[%s] Usage: spit_remove_block_square <mapname>.", PLUGIN_TAG);
		return Plugin_Handled;
	}
	
	GetCmdArg(1, mapname, sizeof(mapname));
	if (hSpitBlockSquares.GetArray(mapname, square, sizeof(square))) {
		hSpitBlockSquares.Remove(mapname);
		PrintToServer("[%s] Spit block square removed on this map '%s'.", PLUGIN_TAG, mapname);
	} else {
		PrintToServer("[%s] Сould not find the specified map '%s'.", PLUGIN_TAG, mapname);
	}
	
	OnMapStart();

	return Plugin_Handled;
}

public void OnMapStart()
{
	static char mapname[64];
	GetCurrentMap(mapname, sizeof(mapname));
	
	if (hSpitBlockSquares.GetArray(mapname, block_square, sizeof(block_square))) {
		IsBlockEnable = true;
		return;
	}
	
	for (int i = 0; i < sizeof(block_square); i++) {
		block_square[i] = 0.0;
	}

	IsBlockEnable = false;
}

public void OnClientPostAdminCheck(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, stop_spit_dmg);
}

public Action stop_spit_dmg(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (!IsBlockEnable || !(damagetype & DMG_TYPE_SPIT)) { //for performance
		return Plugin_Continue;
	}
	
	if (!IsInsectSwarm(inflictor) || !IsValidClient(victim)) {
		return Plugin_Continue;
	}

	float origin[3];
	GetClientAbsOrigin(victim, origin);
	if (isPointIn2DBox(origin[0], origin[1], block_square[0], block_square[1], block_square[2], block_square[3])) {
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

// Is x0,y0 in the box defined by x1,y1 and x2,y2
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

bool IsInsectSwarm(int entity)
{
	if (IsValidEntity(entity)) {
		char classname[32];
		GetEntityClassname(entity, classname, sizeof(classname));
		return (strcmp(classname, "insect_swarm") == 0);
	}

	return false;
}

bool IsValidClient(int client)
{
	return (client > 0 && client <= MaxClients /*&& IsClientInGame(client)*/); //need?
}

void ErrorAnnounce(const char[] szFormat, any ...)
{
	int iLen = strlen(szFormat) + 255;
	char[] szBuffer = new char[iLen];
	VFormat(szBuffer, iLen, szFormat, 2);
 
	LogError(szBuffer);
	PrintToServer(szBuffer);
}
