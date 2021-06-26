#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <dhooks>

#define GAMEDATA "l4d2_si_ability"

Handle hCBaseAbility_OnOwnerTakeDamage;

public Plugin myinfo =
{
	name		= "L4D2 Pounce Protect",
	author		= "ProdigySim", //A1m` add new syntax, add new gamedata file
	description	= "Prevent damage from blocking a hunter's ability to pounce",
	version		= "1.1",
	url			= "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	Handle hGamedata = LoadGameConfigFile(GAMEDATA);

	if (!hGamedata) {
		SetFailState("Gamedata '%s.txt' missing or corrupt.", GAMEDATA);
	}
	
	int iOnOwnerTakeDamageOffset = GameConfGetOffset(hGamedata, "CBaseAbility::OnOwnerTakeDamage");
	if (iOnOwnerTakeDamageOffset == -1) {
		SetFailState("Failed to get offset 'CBaseAbility::OnOwnerTakeDamage'.");
	}
	
	hCBaseAbility_OnOwnerTakeDamage = DHookCreate(iOnOwnerTakeDamageOffset, HookType_Entity, ReturnType_Void, ThisPointer_Ignore, CBaseAbility_OnOwnerTakeDamage);

	DHookAddParam(hCBaseAbility_OnOwnerTakeDamage, HookParamType_ObjectPtr);

	delete hGamedata;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (strcmp(classname, "ability_lunge") == 0) {
		DHookEntity(hCBaseAbility_OnOwnerTakeDamage, false, entity); 
	}
}

// During this function call the game simply validates the owner entity 
// and then sets a bool saying you can't pounce again if you're already mid-pounce.
// afaik
public MRESReturn CBaseAbility_OnOwnerTakeDamage(Handle hParams)
{
	// Skip the whole function plox
	return MRES_Supercede;
}
