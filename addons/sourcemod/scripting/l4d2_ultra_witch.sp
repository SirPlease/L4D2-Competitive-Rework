#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <left4dhooks> //#include <l4d2_direct>
#define L4D2UTIL_STOCKS_ONLY 1
#include <l4d2util>

#define GAMEDATA_FILE "l4d2_ultra_witch"
#define SIGNATURE_NAME "CBaseEntity::ApplyAbsVelocityImpulse"

#define MAX_ENTITY_NAME_SIZE 64

ConVar
	g_hZWitchDamage = null;

bool
	g_blateLoad = false;

Handle
	g_hApplyAbsVelocityImpulse;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_blateLoad = late;

	return APLRes_Success;
}

public Plugin myinfo =
{
	name = "L4D2 Ultra Witch",
	author = "Visor, A1m`",
	description = "The Witch's hit deals a set amount of damage instead of instantly incapping, while also sending the survivor flying. Fixes convar z_witch_damage",
	version = "1.2.1",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	InitGameData();
	
	g_hZWitchDamage = FindConVar("z_witch_damage");

	if (g_blateLoad) {
		for (int i = 1; i <= MaxClients; i++) {
			if (IsClientInGame(i)) {
				OnClientPutInServer(i);
			}
		}
	}
}

void InitGameData()
{
	Handle hGameData = LoadGameConfigFile(GAMEDATA_FILE);
	if (!hGameData) {
		SetFailState("Could not load gamedata/%s.txt", GAMEDATA_FILE);
	}

	StartPrepSDKCall(SDKCall_Player);
	
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, SIGNATURE_NAME)) {
		SetFailState("Function '%s' not found", SIGNATURE_NAME);
	}
	
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	
	g_hApplyAbsVelocityImpulse = EndPrepSDKCall();
	
	if (g_hApplyAbsVelocityImpulse == null) {
		SetFailState("Function '%s' found, but something went wrong", SIGNATURE_NAME);
	}

	delete hGameData;
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public void OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (!(damagetype & DMG_SLASH)) {
		return Plugin_Continue;
	}
	
	if (!IsWitch(attacker) || !IsValidSurvivor(victim)) {
		return Plugin_Continue;
	}
	
	if (IsIncapacitated(victim)) {
		return Plugin_Continue;
	}

	float witchDamage = g_hZWitchDamage.FloatValue;
	if (witchDamage >= (iGetSurvivorPermanentHealth(victim) + GetSurvivorTemporaryHealth(victim))) {
		return Plugin_Continue;
	}

	// Replication of tank punch throw algorithm from CTankClaw::OnPlayerHit()
	float victimPos[3], witchPos[3], throwForce[3];
	GetEntPropVector(victim, Prop_Send, "m_vecOrigin", victimPos);
	GetEntPropVector(attacker, Prop_Send, "m_vecOrigin", witchPos);

	NormalizeVector(victimPos, victimPos);
	NormalizeVector(witchPos, witchPos);
	
	throwForce[0] = L4D2Util_ClampFloat((360000.0 * (victimPos[0] - witchPos[0])), -400.0, 400.0);
	throwForce[1] = L4D2Util_ClampFloat((90000.0 * (victimPos[1] - witchPos[1])), -400.0, 400.0);
	throwForce[2] = 300.0;
	
	ApplyAbsVelocityImpulse(victim, throwForce);
	L4D2Direct_DoAnimationEvent(victim, view_as<int>(ANIM_TANK_PUNCH_GETUP));
	
	damage = witchDamage;
	
	return Plugin_Changed;
}

int iGetSurvivorPermanentHealth(int client)
{
	if (GetEntProp(client, Prop_Send, "m_currentReviveCount") > 0) {
		return 0;
	}
	
	int iHealth = GetEntProp(client, Prop_Send, "m_iHealth");
	
	return (iHealth > 0) ? iHealth : 0;
}

bool IsWitch(int entity)
{
	if (!IsValidEdict(entity)) {
		return false;
	}
	
	char sClassName[MAX_ENTITY_NAME_SIZE];
	GetEdictClassname(entity, sClassName, sizeof(sClassName));
	return (StrContains(sClassName, "witch") != -1); //witch and witch_bride
}

void ApplyAbsVelocityImpulse(int client, const float impulseForce[3])
{
	SDKCall(g_hApplyAbsVelocityImpulse, client, impulseForce);
}
