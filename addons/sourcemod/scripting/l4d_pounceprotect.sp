#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <dhooks>

#define GAMEDATA "l4d2_si_ability"

DynamicHook hCBaseAbility_OnOwnerTakeDamage;

public Plugin myinfo =
{
	name		= "L4D2 Pounce Protect",
	author		= "ProdigySim",
	description	= "Prevent damage from blocking a hunter's ability to pounce",
	version		= "1.1",
	url			= "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	GameData hGamedata = new GameData(GAMEDATA);

	if (!hGamedata) {
		SetFailState("Gamedata '%s.txt' missing or corrupt.", GAMEDATA);
	}
	
	int iOnOwnerTakeDamageOffset = hGamedata.GetOffset("CBaseAbility::OnOwnerTakeDamage");
	if (iOnOwnerTakeDamageOffset == -1) {
		SetFailState("Failed to get offset 'CBaseAbility::OnOwnerTakeDamage'.");
	}
	
	hCBaseAbility_OnOwnerTakeDamage = new DynamicHook(iOnOwnerTakeDamageOffset, HookType_Entity, ReturnType_Void, ThisPointer_Ignore);
	hCBaseAbility_OnOwnerTakeDamage.AddParam(HookParamType_ObjectPtr);

	delete hGamedata;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (strcmp(classname, "ability_lunge") == 0) {
		hCBaseAbility_OnOwnerTakeDamage.HookEntity(Hook_Post, entity, CBaseAbility_OnOwnerTakeDamage); 
	}
}

// During this function call the game simply validates the owner entity 
// and then sets a bool saying you can't pounce again if you're already mid-pounce.
// afaik
MRESReturn CBaseAbility_OnOwnerTakeDamage(Handle hParams)
{
	// Skip the whole function plox
	return MRES_Supercede;
}
