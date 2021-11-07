/* @A1m`:
 * Original code from the game, function 'CTerrorMeleeWeapon::GetDamageForVictim':
 * Rewritten to sourcepawn for example :D
 * In fact, there is no problem with melee damage, the damage depends on where you hit the hitbox (head, leg or body). This plugin removes it.
 * 
 * 	float fResult = 175.0;
 * 	int iZclass = GetEntProp(iVictim, Prop_Send, "m_zombieClass", 4);
 * 	switch (iZclass)
 * 	{
 * 		case L4D2Infected_Common:
 * 		case L4D2Infected_Smoker:
 * 		case L4D2Infected_Boomer:
 * 		case L4D2Infected_Hunter:
 * 		case L4D2Infected_Spitter:
 * 		case L4D2Infected_Jockey:
 * 			fResult = GetEntProp(iVictim, Prop_Send, "m_iHealth");
 * 			break;
 * 		case L4D2Infected_Charger:
 * 			fResult = GetEntProp(client, Prop_Send, "m_iMaxHealth") * 0.64999998;
 * 			break;
 * 		case L4D2Infected_Witch:
 * 			fResult = GetEntProp(client, Prop_Send, "m_iMaxHealth") * 0.25;
 * 			break;
 * 		case L4D2Infected_Tank:
 * 			fResult = GetEntProp(client, Prop_Send, "m_iMaxHealth") * 0.050000001;
 * 			break;
 * 		default:
 * 			return CMeleeWeaponInfo->m_fDamage;
 * 	}
 * 	return fResult;
}*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <l4d2util_constants>

#define DEBUG 0

#define MAX_ENTITY_NAME 64

bool
	g_bMeleeDmgFixEnable = false,
	g_bLateLoad = false;

float
	g_fChargerMeleeDamage = -1.0,
	g_fTankMeleeNerfDamage = -1.0;

ConVar
	g_hCvarMeleeDmgFix = null,
	g_hCvarMeleeDmgCharger = null,
	g_hCvarTankDmgMeleeNerfPercentage = null;

public Plugin myinfo =
{
	name = "L4D2 Melee Damage Fix&Control",
	description = "Fix melees weapons not applying correct damage values on infected. Allows manipulate melee damage on some infected.",
	author = "Visor, Sir, A1m`",
	version = "2.1",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErrMax)
{
	g_bLateLoad = bLate;
	
	return APLRes_Success;
}

public void OnPluginStart()
{
	g_hCvarMeleeDmgFix = CreateConVar( \
		"l4d2_melee_damage_fix", \
		"1.0", \
		"Enable fix melees weapons not applying correct damage values on infected (damage no longer depends on hitgroup).", \
		_, true, 0.0, true, 1.0 \
	);
	
	// For melee damage to the tank to be 220, you need to set this value 26.666666 :D
	g_hCvarTankDmgMeleeNerfPercentage = CreateConVar( \
		"l4d2_melee_damage_tank_nerf", \
		"-1.0", \
		"Percentage of melee damage nerf against tank (a zero or negative value disables this).", \
		_, false, 0.0, true, 100.0 \
	);
	
	g_hCvarMeleeDmgCharger = CreateConVar( \
		"l4d2_melee_damage_charger", \
		"-1.0", \
		"Melee damage dealt to сharger per swing (a zero or negative value disables this).", \
		_, false, 0.0, false, 0.0 \
	);
	
	CvarsToType();
	
	g_hCvarMeleeDmgFix.AddChangeHook(Cvars_Changed);
	g_hCvarTankDmgMeleeNerfPercentage.AddChangeHook(Cvars_Changed);
	g_hCvarMeleeDmgCharger.AddChangeHook(Cvars_Changed);
	
	if (g_bLateLoad) {
		for (int i = 1; i <= MaxClients; i++) {
			if (IsClientInGame(i)) {
				OnClientPutInServer(i);
			}
		}
	}
}

public void Cvars_Changed(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	CvarsToType();
}

void CvarsToType()
{
	g_bMeleeDmgFixEnable = g_hCvarMeleeDmgFix.BoolValue;
	g_fChargerMeleeDamage = g_hCvarMeleeDmgCharger.FloatValue;
	g_fTankMeleeNerfDamage = g_hCvarTankDmgMeleeNerfPercentage.FloatValue;
}

public void OnClientPutInServer(int iClient)
{
	SDKHook(iClient, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
}

public void OnClientDisconnect(int iClient)
{
	SDKUnhook(iClient, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
}

public Action Hook_OnTakeDamage(int iVictim, int &iAttacker, int &iInflictor, float &fDamage, int &iDamagetype)
{
	//DMG_SLOWBURN - works for all types of melee weapons
	if (!(iDamagetype & DMG_SLOWBURN)) {
		return Plugin_Continue;
	}
	
	if (fDamage <= 0.0 || !IsMelee(iInflictor)) {
		return Plugin_Continue;
	}
	
	if (!IsInfected(iVictim) || !IsSurvivor(iAttacker)) {
		return Plugin_Continue;
	}
	
	int iZclass = GetEntProp(iVictim, Prop_Send, "m_zombieClass", 4);
	if (iZclass <= L4D2Infected_Jockey) {
		if (g_bMeleeDmgFixEnable) {
		
			#if DEBUG
				float fHealth = float(GetClientHealth(iVictim));
				PrintToChatAll("[MeleeDmgFix] Infected: (%N) %d, Class: %s (%d), attacker: (%N) %d , inflictor: %d, damage: %f, damagetype: %d, set damage: %f", \
										iVictim, iVictim, L4D2_InfectedNames[iZclass], iZclass, iAttacker, iAttacker, iInflictor, fDamage, iDamagetype, fHealth);
			#endif
			
			fDamage = float(GetClientHealth(iVictim));
			return Plugin_Changed;
		}
	} else if (iZclass == L4D2Infected_Charger) {
		if (g_fChargerMeleeDamage > 0.0) {
			float fHealth = float(GetClientHealth(iVictim));
			
			#if DEBUG
				float fNewDamage = (fHealth < g_fChargerMeleeDamage) ? fHealth : g_fChargerMeleeDamage;
				PrintToChatAll("[MeleeDmgControl] Charger: (%N) %d, attacker: (%N) %d , inflictor: %d, damage: %f, damagetype: %d, set damage: %f", \
										iVictim, iVictim, iAttacker, iAttacker, iInflictor, fDamage, iDamagetype, fNewDamage);
			#endif
			
			// Take care of low health Chargers to prevent Overkill damage.
			fDamage = (fHealth < g_fChargerMeleeDamage) ? fHealth : g_fChargerMeleeDamage; // Deal requested Damage to Chargers.
			return Plugin_Changed;
		}
	} else if (iZclass == L4D2Infected_Tank) {
		if (g_fTankMeleeNerfDamage > 0.0) {
		
			#if DEBUG
				float fNewDamage = (fDamage * (100.0 - g_fTankMeleeNerfDamage)) / 100.0;
				PrintToChatAll("[MeleeDmgControl] Tank: (%N) %d, attacker: (%N) %d, inflictor: %d, damage: %f, damagetype: %d, set damage: %f", \
										iVictim, iVictim, iAttacker, iAttacker, iInflictor, fDamage, iDamagetype, fNewDamage);
			#endif
			
			fDamage = (fDamage * (100.0 - g_fTankMeleeNerfDamage)) / 100.0;
			return Plugin_Changed;
		}
	}
	
	return Plugin_Continue;
}

bool IsMelee(int iEntity)
{
	if (iEntity > MaxClients && IsValidEntity(iEntity)) {
		char sClassName[MAX_ENTITY_NAME];
		GetEntityClassname(iEntity, sClassName, sizeof(sClassName));
		
		#if DEBUG
			PrintToChatAll("sClassName: %s (%d)", sClassName, iEntity);
		#endif
		
		//weapon_ - 7
		return (strncmp(sClassName[7], "melee", 5, true) == 0);
	}
	
	return false;
}

bool IsSurvivor(int iClient)
{
	return (iClient > 0
		&& iClient <= MaxClients
		&& IsClientInGame(iClient)
		&& GetClientTeam(iClient) == L4D2Team_Survivor);
}

bool IsInfected(int iClient)
{
	return (iClient > 0
		&& iClient <= MaxClients
		&& IsClientInGame(iClient)
		&& GetClientTeam(iClient) == L4D2Team_Infected);
}
