/*
 * ============================================================================
 *
 * This file is part of the Rotoblin 2 project.
 *
 *  File:			l4d_lib.inc
 *  Language:       SourcePawn
 *  Description:	Stock of l4d & l4d2 functions.
 *  Version:        2.4
 *  Credits:        SilverShot for GetTempHealth func (https://forums.alliedmods.net/showthread.php?p=1658852)
 *
 *  Copyright (C) 2012-2021 raziEiL [disawar1] <mr.raz4291@gmail.com>
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * ============================================================================
 */

#if defined _l4d_lib_
  #endinput
#endif
#define _l4d_lib_ "2.5"

#include <sourcemod>
#include <sdktools>
/*
|--------------------------------------------------------------------------
| LOCAL TEMP VARIABLES
|--------------------------------------------------------------------------
*/
static char g_sTemp[1024];
static int g_iTemp;
/*
|--------------------------------------------------------------------------
| MACROS
|--------------------------------------------------------------------------
*/
#define SZF(%0) 	%0, sizeof(%0)
#define MPS 33 // l4d max players + 1
#define CID(%0) 	GetClientOfUserId(%0)
#define UID(%0) 	GetClientUserId(%0)
#define IsIncaped(%1) IsIncapacitated(%1)
/*
|--------------------------------------------------------------------------
| ZOMBIE STRUCTURE
|--------------------------------------------------------------------------
*/
enum
{
	ZC_INVALID = -1,
	ZC_INFECTED, // just a zombie
	ZC_SMOKER,
	ZC_BOOMER,
	ZC_HUNTER,
	ZC_WITCH, // ZC_UNKNOWN
	ZC_TANK,
	ZC_SIZE
}

enum
{
	ZC2_INVALID = ZC_INVALID,
	ZC2_INFECTED,
	ZC2_SMOKER,
	ZC2_BOOMER,
	ZC2_HUNTER,
	ZC2_SPITTER,
	ZC2_JOCKEY,
	ZC2_CHARGER,
	ZC2_WITCH,
	ZC2_TANK,
	ZC2_SIZE
}
// Public variables
stock const char L4D_LIB_INFECTED_CHARACTER_NAME[ZC_SIZE][] =
{
	"Infected",
    "Smoker",
    "Boomer",
    "Hunter",
    "Witch",
    "Tank"
};

stock const char L4D2_LIB_INFECTED_CHARACTER_NAME[ZC2_SIZE][] =
{
	"Infected",
    "Smoker",
    "Boomer",
    "Hunter",
    "Spitter",
    "Jockey",
    "Charger",
    "Witch",
    "Tank"
};
/*
|--------------------------------------------------------------------------
| SURVIVORS STRUCTURE
|--------------------------------------------------------------------------
*/
#define L4D_SURVIVOR_CHARACTER_OFFSET 4

enum
{
	SC_INVALID = -1,
	SC_NICK,
	SC_ROCHELLE,
	SC_COACH,
	SC_ELLIS,
	SC_BILL,
	SC_ZOEY,
	SC_FRANCIS,
	SC_LOUIS,
	SC_SIZE
}

// Public variables
stock const char L4D2_LIB_SURVIVOR_CHARACTER[SC_SIZE][] =
{
	"gambler",
	"producer",
	"coach",
	"mechanic",
	"namvet", // L4D_SURVIVOR_CHARACTER_OFFSET
	"teengirl",
	"biker",
	"manager"
};

stock const char L4D2_LIB_SURVIVOR_CHARACTER_NAME[SC_SIZE][] =
{
	"Nick",
	"Rochelle",
	"Coach",
	"Ellis",
	"Bill", // L4D_SURVIVOR_CHARACTER_OFFSET
	"Zoey",
	"Francis",
	"Louis"
};

stock const char L4D2_LIB_SURVIVOR_MDL[SC_SIZE][] =
{
	"models/survivors/survivor_gambler.mdl",
	"models/survivors/survivor_producer.mdl",
	"models/survivors/survivor_coach.mdl",
	"models/survivors/survivor_mechanic.mdl",
	"models/survivors/survivor_namvet.mdl", // L4D_SURVIVOR_CHARACTER_OFFSET
	"models/survivors/survivor_teenangst.mdl",
	"models/survivors/survivor_biker.mdl",
	"models/survivors/survivor_manager.mdl"
};
/*
|--------------------------------------------------------------------------
| CLIENT
|--------------------------------------------------------------------------
*/
stock bool IsClientAndInGame(int client)
{
	return IsClient(client) && IsClientInGame(client);
}

stock bool IsClient(int client)
{
	return client > 0 && client <= MaxClients;
}

stock bool IsInfected(int client)
{
	return IsClientInGame(client) && GetClientTeam(client) == 3;
}

stock bool IsSurvivor(int client)
{
	return IsClientInGame(client) && GetClientTeam(client) == 2;
}

stock bool IsSpectator(int client)
{
	return IsClientInGame(client) && GetClientTeam(client) == 1;
}

stock bool IsInfectedAndInGame(int client)
{
	return IsClient(client) && IsInfected(client);
}

stock bool IsSurvivorAndInGame(int client)
{
	return IsClient(client) && IsSurvivor(client);
}

stock bool IsSpectatorAndInGame(int client)
{
	return IsClient(client) && IsSpectator(client);
}

stock bool IsPlayerBussy(int client, int team)
{
	return !IsPlayerAlive(client) || (team == 2 ? (IsSurvivorBussy(client) || IsIncapacitated(client) || IsHandingFromLedge(client)) :
		IsInfectedBussy(client));
}

stock bool IsSurvivorBussy(int client)
{
	return GetEntProp(client, Prop_Send, "m_tongueOwner") > 0 || GetEntProp(client, Prop_Send, "m_pounceAttacker") > 0 || (IsL4DGameEx() ? false : GetEntProp(client, Prop_Send, "m_pummelAttacker") > 0 || GetEntProp(client, Prop_Send, "m_jockeyAttacker") > 0);
}

stock bool IsInfectedBussy(int client)
{
	return GetEntProp(client, Prop_Send, "m_tongueVictim") > 0 || GetEntProp(client, Prop_Send, "m_pounceVictim") > 0 || (IsL4DGameEx() ? false : GetEntProp(client, Prop_Send, "m_pummelVictim") > 0 || GetEntProp(client, Prop_Send, "m_jockeyVictim") > 0);
}

stock bool IsIncapacitated(int client)
{
	return !!GetEntProp(client, Prop_Send, "m_isIncapacitated");
}

stock bool IsHandingFromLedge(int client)
{
	return GetEntProp(client, Prop_Send, "m_isHangingFromLedge") || GetEntProp(client, Prop_Send, "m_isFallingFromLedge");
}

#pragma deprecated Use IsPlayerAlive(int client) instead.
stock bool IsInfectedAlive(int client)
{
	return GetEntProp(client, Prop_Send, "m_iHealth") > 1;
}

stock bool IsPlayerTank(int client)
{
	return GetEntProp(client, Prop_Send, "m_zombieClass") == (IsL4DGameEx() ? ZC_TANK : ZC2_TANK);
}

stock bool IsPlayerGhost(int client)
{
	return !!GetEntProp(client, Prop_Send, "m_isGhost");
}

// @return Player class only! Use GetZombieClass to get Witch, infected or invalid class.
stock int GetPlayerClass(int client)
{
	return GetEntProp(client, Prop_Send, "m_zombieClass");
}

stock int GetZombieClass(int entity, bool validate = true)
{
	if (entity > MPS){
		if (!validate || IsValidEntity(entity)){
			if (IsWitch(entity))
				return IsL4DGameEx() ? ZC_WITCH : ZC2_WITCH;
			else if (IsCommonInfected(entity))
				return ZC_INFECTED;
		}
	}
	else if (!validate || IsInfectedAndInGame(entity))
		return GetEntProp(entity, Prop_Send, "m_zombieClass");

	return ZC_INVALID;
}

stock int GetFrustration(int client)
{
	return GetEntProp(client, Prop_Send, "m_frustration");
}

stock void SetTankFrustration(int client, int iFrustration)
{
	SetEntProp(client, Prop_Send, "m_frustration", 100 - iFrustration);
}

stock int GetGhostSpawnState(int client)
{
	return GetEntProp(client, Prop_Send, "m_ghostSpawnState");
}

stock void SetTempHealth(int client, float health)
{
	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", health);
}

stock float GetTempHealth(int client)
{
	static float fCvarDecayRate = -1.0;

	if (fCvarDecayRate == -1.0)
		fCvarDecayRate = FindConVar("pain_pills_decay_rate").FloatValue;

	float fTempHealth = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	fTempHealth -= (GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime")) * fCvarDecayRate;
	return fTempHealth < 0.0 ? 0.0 : fTempHealth;
}
/*
|--------------------------------------------------------------------------
| ENTITY
|--------------------------------------------------------------------------
*/
stock bool IsOnLadder(int entity)
{
	return GetEntityMoveType(entity) == MOVETYPE_LADDER;
}

stock bool IsOnFire(int entity)
{
	return (GetEntityFlags(entity) & FL_ONFIRE) == FL_ONFIRE;
}

stock bool IsWitch(int entity)
{
	GetEntityClassname(entity, SZF(g_sTemp));
	return StrEqual(g_sTemp, "witch");
}

stock bool IsCommonInfected(int entity)
{
	GetEntityClassname(entity, SZF(g_sTemp));
	return StrEqual(g_sTemp, "infected");
}

stock int GetHammerID(int entity)
{
	return GetEntProp(entity, Prop_Data, "m_iHammerID");
}
/*
|--------------------------------------------------------------------------
| WEAPONS
|  For more weapon functions see: https://github.com/raziEiL/l4d2_weapons
|--------------------------------------------------------------------------
*/
stock bool IsWeaponClass(const char[] sClassName)
{
	return StrContains(sClassName, "weapon_") != -1 || StrContains(sClassName, "upgrade_") != -1;
}

stock bool IsItem(const char[] entityname)
{
	if(StrEqual(entityname, "models/props_junk/gascan001a.mdl")||
	StrEqual(entityname, "models/props_junk/propanecanister001a.mdl")||
	StrEqual(entityname, "models/props_equipment/oxygentank01.mdl")
	)
		return true;
	return false;
	
}

stock bool IsWeaponClassEx(int entity)
{
	GetEntityClassname(entity, SZF(g_sTemp));
	return IsWeaponClass(g_sTemp);
}

stock bool IsWeaponSpawn(const char[] sClassName)
{
	return IsWeaponClass(sClassName) && StrContains(sClassName, "_spawn") != -1;
}

stock bool IsWeaponSpawnEx(int entity)
{
	GetEntityClassname(entity, SZF(g_sTemp));
	return IsWeaponSpawn(g_sTemp);
}

stock int GetWeaponClipSize(int entity)
{
	return GetEntProp(entity, Prop_Send, "m_iClip1");
}

stock int GetWeaponClipSizeEx(int client)
{
	int iWeap = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");

	if (IsValidEntity(iWeap))
		return GetWeaponClipSize(iWeap);

	return -1;
}
/*
|--------------------------------------------------------------------------
| VECTORS
|--------------------------------------------------------------------------
*/
stock void GetEntityOrg(int entity, float vOrg[3])
{
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vOrg);
}

stock bool IsVectorNull(float vOrg[3])
{
	return !vOrg[0] && !vOrg[1] && !vOrg[2];
}

stock bool IsVectorsMatch(float vVectorA[3], float vVectorB[3])
{
	return vVectorA[0] == vVectorB[0] && vVectorA[1] == vVectorB[1] && vVectorA[2] == vVectorB[2];
}

stock void CopyVectorVector(float dest[3], const float src[3])
{
	dest[0] = src[0];
	dest[1] = src[1];
	dest[2] = src[2];
}

stock void ScaleVectorVector(float vec[3], const float scale[3])
{
	vec[0] *= scale[0];
	vec[1] *= scale[1];
	vec[2] *= scale[2];
}

stock void AddVectorInt(float vec[3], int value)
{
	vec[0] += value;
	vec[1] += value;
	vec[2] += value;
}

stock void SubVectorInt(float vec[3], int value)
{
	vec[0] -= value;
	vec[1] -= value;
	vec[2] -= value;
}
/*
|--------------------------------------------------------------------------
| GLOW/COLOR
|--------------------------------------------------------------------------
*/
stock void SetEntGlowInt(int entity, const int rgb[3], int type = 3, int min = 1, int max = 450, bool flashing = false)
{
	SetEntProp(entity, Prop_Send, "m_iGlowType", type);
	SetEntProp(entity, Prop_Send, "m_glowColorOverride", ((rgb[2] & 0xFF) << 16) | ((rgb[1] & 0xFF) << 8) | (rgb[0] & 0xFF)); // little-endian byte order
	SetEntProp(entity, Prop_Send, "m_nGlowRangeMin", min);
	SetEntProp(entity, Prop_Send, "m_nGlowRange", max);
	SetEntProp(entity, Prop_Send, "m_bFlashing", flashing);
}

stock void DisableEntGlow(int entity)
{
	SetEntProp(entity, Prop_Send, "m_iGlowType", 0);
	SetEntProp(entity, Prop_Send, "m_glowColorOverride", 0);
	SetEntProp(entity, Prop_Send, "m_nGlowRange", 0);
	SetEntProp(entity, Prop_Send, "m_nGlowRangeMin", 0);
}

stock void SetEntGlowStr(int entity, char[] color, int type = 3, int min = 1, int max = 450, bool flashing = false)
{
	SetEntGlowInt(entity, ColorStrToInt(color), type, min, max, flashing);
}

stock void GetRandomRGBColor(char[] dest, int len)
{
	FormatEx(dest, len, "%d %d %d", GetRandomInt(0, 255), GetRandomInt(0, 255), GetRandomInt(0, 255));
}

stock int[] ColorStrToInt(const char[] color)
{
	int iRGB[3];
	ParseColorStr(color, iRGB);
	return iRGB;
}

stock void ParseColorStr(const char[] color, int dest[3])
{
	char sRGB[3][6];
	int iParts = ExplodeString(color, " ", sRGB, sizeof(sRGB), sizeof(sRGB[]));

	if (iParts == 3){ // RGB format
		for (int i; i < iParts; i++)
			dest[i] = StringToInt(sRGB[i]);
	}
	else { // HEX format
		int iHEX = StringToInt(color, 16);
		dest[0] = (iHEX >> 16) & 0xFF;
		dest[1] = (iHEX >> 8) & 0xFF;
		dest[2] = iHEX & 0xFF;
	}
}
/*
|--------------------------------------------------------------------------
| MISC
|--------------------------------------------------------------------------
*/
stock bool IsAnyOneConnected()
{
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientConnected(i) && !IsClientInGame(i) && !IsFakeClient(i))
			return true;

	return false;
}

stock bool IsServerEmpty()
{
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientConnected(i) && !IsFakeClient(i))
			return false;

	return true;
}

stock bool GetCharacterName(int client, char[] dest, int len)
{
	g_iTemp = GetSurvivorIndex(client);
	return g_iTemp == SC_INVALID ? false : !!strcopy(dest, len, L4D2_LIB_SURVIVOR_CHARACTER_NAME[g_iTemp]);
}

stock bool GetCharacter(int client, char[] dest, int len)
{
	g_iTemp = GetSurvivorIndex(client);
	return g_iTemp == SC_INVALID ? false : !!strcopy(dest, len, L4D2_LIB_SURVIVOR_CHARACTER[g_iTemp]);
}

// @return Player class names only! Use GetZombieName to get Witch or infected names.
stock bool GetInfectedName(int client, char[] dest, int len)
{
	g_iTemp = GetEntProp(client, Prop_Send, "m_zombieClass");
	return !!strcopy(dest, len, IsL4DGameEx() ? L4D_LIB_INFECTED_CHARACTER_NAME[g_iTemp] : L4D2_LIB_INFECTED_CHARACTER_NAME[g_iTemp]);
}

stock bool GetZombieName(int entity, char[] dest, int len)
{
	g_iTemp = GetZombieClass(entity);
	if (g_iTemp == ZC_INVALID)
		return false;
	return !!strcopy(dest, len, IsL4DGameEx() ? L4D_LIB_INFECTED_CHARACTER_NAME[g_iTemp] : L4D2_LIB_INFECTED_CHARACTER_NAME[g_iTemp]);
}

// @return SC_ enum index
stock int GetSurvivorIndex(int client)
{
	if (IsL4DGameEx()){
		static int survIndex;
		survIndex = GetEntProp(client, Prop_Send, "m_survivorCharacter");
		return survIndex < 0 ? SC_INVALID : survIndex + L4D_SURVIVOR_CHARACTER_OFFSET;
	}
	GetClientModel(client, SZF(g_sTemp));
	switch (g_sTemp[29]){
		case 'b':
			return SC_NICK;
		case 'd':
			return SC_ROCHELLE;
		case 'c':
			return SC_COACH;
		case 'h':
			return SC_ELLIS;
		case 'v':
			return SC_BILL;
		case 'n':
			return SC_ZOEY;
		case 'e':
			return SC_FRANCIS;
		case 'a':
			return SC_LOUIS;
	}
	return SC_INVALID;
}

stock void PrintToTeam(int team, int msgType, const char[] text, any ...)
{
	bool bTrans = StrContains(text, "%t") != -1;

	for (int i = 1; i <= MaxClients; i++){

		if (IsClientInGame(i) && GetClientTeam(i) == team && !IsFakeClient(i)){

			if (bTrans)
				SetGlobalTransTarget(i);

			VFormat(SZF(g_sTemp), text, 4);

			switch (msgType){

				case 0:
					PrintToChat(i, g_sTemp);
				case 1:
					PrintHintText(i, g_sTemp);
				case 2:
					PrintCenterText(i, g_sTemp);
			}
		}
	}
}

#pragma deprecated Use L4D_IsMissionFinalMap() from left4dhooks instead.
stock bool IsFinalMap()
{
	return FindEntityByClassname(-1, "info_changelevel") == INVALID_ENT_REFERENCE;
}

#pragma deprecated Use L4D_GetGameModeType() from left4dhooks instead. 
stock bool IsVersusMode()
{
	static ConVar hCvarGameMode;

	if (hCvarGameMode == null)
		hCvarGameMode = FindConVar("mp_gamemode");

	hCvarGameMode.GetString(SZF(g_sTemp));
	return StrEqual(g_sTemp, "versus");
}
/*
|--------------------------------------------------------------------------
| GAME DETECTION
|--------------------------------------------------------------------------
*/
stock bool IsL4DGame(bool bL4D2 = false)
{
	GetGameFolderName(SZF(g_sTemp));
	return StrEqual(g_sTemp, bL4D2 ? "left4dead2" : "left4dead");
}

stock bool IsL4DEngine(bool bL4D2 = false)
{
	return GetEngineVersion() == (bL4D2 ? Engine_Left4Dead2 : Engine_Left4Dead);
}

stock bool IsL4DGameEx(bool bL4D2 = false)
{
	static int iGame = -1;

	if (iGame == -1)
		iGame = IsL4DGame(bL4D2);

	return view_as<bool>(iGame);
}

stock bool IsL4DEngineEx(bool bL4D2 = false)
{
	static int iEngine = -1;

	if (iEngine == -1)
		iEngine = IsL4DEngine(bL4D2);

	return view_as<bool>(iEngine);
}