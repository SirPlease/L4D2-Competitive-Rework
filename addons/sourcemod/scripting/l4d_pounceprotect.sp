#include <sourcemod>
#include <dhooks>

public Plugin:myinfo =
{
	name        = "L4D2 Pounce Protect",
	author      = "ProdigySim",
	description = "Prevent damage from blocking a hunter's ability to pounce",
	version     = "1.0",
	url         = "http://www.l4dnation.com/"
}

new Handle:hCBaseAbility_OnOwnerTakeDamage;
public OnPluginStart()
{
	new Handle:gameConf = LoadGameConfigFile("l4d_pounceprotect"); 
	new OnOwnerTakeDamageOffset = GameConfGetOffset(gameConf, "CBaseAbility_OnOwnerTakeDamage");
	
	hCBaseAbility_OnOwnerTakeDamage = DHookCreate(
		OnOwnerTakeDamageOffset, 
		HookType_Entity, 
		ReturnType_Void, 
		ThisPointer_Ignore, 
		CBaseAbility_OnOwnerTakeDamage);
	DHookAddParam(hCBaseAbility_OnOwnerTakeDamage, HookParamType_ObjectPtr);
}

public OnEntityCreated(entity, const String:classname[])
{
	if(StrEqual(classname, "ability_lunge"))
	{
		DHookEntity(hCBaseAbility_OnOwnerTakeDamage, false, entity); 
	}
}

// During this function call the game simply validates the owner entity 
// and then sets a bool saying you can't pounce again if you're already mid-pounce.
// afaik
public MRESReturn:CBaseAbility_OnOwnerTakeDamage(Handle:hParams)
{
	// Skip the whole function plox
	return MRES_Supercede;
}