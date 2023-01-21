#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <dhooks>

#define Z_JOCKEY 5
#define Z_CHARGER 6
#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3

#define GAMEDATA "l4d2_si_ability"

int m_queuedPummelAttacker = -1;

Handle hCLeap_OnTouch;

public Plugin myinfo =
{
	name = "L4D2 Jockeyed Charger Fix",
	author = "Visor, A1m`",
	description = "Prevent jockeys and chargers from capping the same target simultaneously",
	version = "1.5",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	Handle hGamedata = LoadGameConfigFile(GAMEDATA);

	if (!hGamedata) {
		SetFailState("Gamedata '%s.txt' missing or corrupt.", GAMEDATA);
	}
	
	m_queuedPummelAttacker = GameConfGetOffset(hGamedata, "CTerrorPlayer->m_queuedPummelAttacker");
	if (m_queuedPummelAttacker == -1) {
		SetFailState("Failed to get offset 'CTerrorPlayer->m_queuedPummelAttacker'.");
	}
	
	int iCleapOnTouch = GameConfGetOffset(hGamedata, "CBaseAbility::OnTouch");
	if (iCleapOnTouch == -1) {
		SetFailState("Failed to get offset 'CBaseAbility::OnTouch'.");
	}
	
	hCLeap_OnTouch = DHookCreate(iCleapOnTouch, HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity, CLeap_OnTouch);
	DHookAddParam(hCLeap_OnTouch, HookParamType_CBaseEntity);
	
	delete hGamedata;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (strcmp(classname, "ability_leap") == 0) {
		DHookEntity(hCLeap_OnTouch, false, entity); 
	}
}

public MRESReturn CLeap_OnTouch(int pThis, Handle hParams)
{
	int jockey = GetEntPropEnt(pThis, Prop_Send, "m_owner");
	int survivor = DHookGetParam(hParams, 1);
	if (IsValidJockey(jockey)/* probably redundant */ && IsSurvivor(survivor))
	{
		if (IsValidCharger(GetCarrier(survivor)) 
		|| IsValidCharger(GetPummelQueueAttacker(survivor)) 
		|| IsValidCharger(GetPummelAttacker(survivor))
		) {
			return MRES_Supercede;
		}
	}
	return MRES_Ignored;
}

bool IsSurvivor(int client)
{
	return (client > 0 
		&& client <= MaxClients 
		&& IsClientInGame(client) 
		&& GetClientTeam(client) == TEAM_SURVIVOR);
}

bool IsValidJockey(int client)
{
	return (client > 0 
		&& client <= MaxClients 
		&& IsClientInGame(client) 
		&& GetClientTeam(client) == TEAM_INFECTED
		&& GetEntProp(client, Prop_Send, "m_zombieClass") == Z_JOCKEY);
}

bool IsValidCharger(int client)
{
	return (client > 0 
		&& client <= MaxClients 
		&& IsClientInGame(client) 
		&& GetClientTeam(client) == TEAM_INFECTED 
		&& GetEntProp(client, Prop_Send, "m_zombieClass") == Z_CHARGER);
}

int GetCarrier(int survivor)
{
	return GetEntPropEnt(survivor, Prop_Send, "m_carryAttacker");
}

/* @A1m:
 * It cannot be simply found using sourcemod, 
 * now there is a problem with this plugin, it can break after every update. 
 * Need to check this every update.
 * I need to add game data here to make it easier to fix.
 *
 * After the last update, all offsets in the class 'CTerrorPlayer' changed to offset - 32,
 * which proves that we found it right (old offset 15988 -32 = 15956)
 *
 * How can find this:
 * function 'CTerrorPlayer::OnPummelEnded' the very end 
 *
 *        v37 = *((_DWORD *)this + 3757);
 *        *((_DWORD *)this + 3989) = -1; 									//we need to find this line 3989. 3989*4=15956
 *        result = (*(int (__fastcall **)(void *))(v37 + 248))(v35);
 *        if ( !*((_BYTE *)this + 14833) )
 *          result = CTerrorPlayer::WarpToValidPositionIfStuck();
 *
 * Or we need to find this function 'CTerrorPlayer::QueuePummelVictim' the very end 
 *
 *        if ( a2 )
 *        {
 *           //we need to find this line 3989. 3989*4=15956
 *          *((_DWORD *)a2 + 3989) = *(_DWORD *)(*(int (__fastcall **)(char *, int, CTerrorPlayer *))(*(_DWORD *)this + 12))(v3, v7, this);  
 *          result = CBaseEntity::AddFlag(this, 32);
 *        }
 *        v8 = -1.0;
 *        if ( a3 != -1.0 )
 *        {
 *          result = gpGlobals;
 *          v8 = a3 + *(float *)(gpGlobals + 12);
 *        }
 *        *((float *)this + 3988) = v8;
 *        return result;
 */
int GetPummelQueueAttacker(int survivor)
{
	return GetEntDataEnt2(survivor, m_queuedPummelAttacker);
}

int GetPummelAttacker(int survivor)
{
	return GetEntPropEnt(survivor, Prop_Send, "m_pummelAttacker");
}
