#include <sourcemod>
#include <sdktools>

/**
 * How much of a shove penalty will be added if a client melees when not fatigued. 
 * If you _are_ fatigued (you can tell when you're fatigued, as meleeing causes the 
 * "I'm bloody knackered, mate" icon to appear), then the game will just add the 
 * standard count of 1 to your shove penalty, capped at a maximum of maximum of 6.
 *
 * I.e. this setting only has an effect until you're fatigued, at which point the
 * standard code takes over.
 */
static g_nonFatiguedMeleePenalty					= 1;  
static Handle:g_hNonFatiguedMeleePenalty_CVAR	= INVALID_HANDLE;

// shove penalty on a client before we stop adding to it and just let the game take over.
static const MAX_EXISTING_FATIGUE					= 3; 

static const Float:MELEE_DURATION					= 0.6;
static bool:soundHookDelay[MAXPLAYERS+1] 			= false;

public Plugin:myinfo =
{
	name = "L4D2 Melee Fatigue Control",
	description = "Allows players to set custom fatigue levels.",
	author = "Rotoblin Team & Blade; rebuilt by Visor",
	version = "0.1",
	url = "https://github.com/ConfoglTeam/ProMod"
};

public OnPluginStart()
{
	g_hNonFatiguedMeleePenalty_CVAR = CreateConVar("melee_penalty", "1", "Sets the value to be added to a survivor's shove penalty.  This _only_ gets added when that survivor is not already fatigued (so basically, setting this to a large value will make the survivors become fatigued more quickly, but the cooldown effect won't change once fatigue has set in)");
	HookConVarChange(g_hNonFatiguedMeleePenalty_CVAR, MeleePenalty_CvarChange);

	AddNormalSoundHook(NormalSHook:HookSound_Callback);
}

public MeleePenalty_CvarChange(Handle:convar, String:oldValue[], String:newValue[])
{
	UpdateNonFatiguedMeleePenalty();
}

UpdateNonFatiguedMeleePenalty()
{
	g_nonFatiguedMeleePenalty = GetConVarInt(g_hNonFatiguedMeleePenalty_CVAR);
}

public Action:HookSound_Callback(Clients[64], &NumClients, String:StrSample[PLATFORM_MAX_PATH], &Entity)
{
	// Only execute if appropriate.  

	// Note: This is potentially wasteful, as the callback will be getting fired for each sound 
	// even if the melee penalty is set to 1 (the default).  It may be better to hook/unhook the 
	// callback when the feature is enabled/disabled, but let's keep it simple for now.
	if(!ShouldPerformCustomFatigueLogic(StrSample, Entity))
	{
		return Plugin_Continue;
	}

	// the player just started to shove
	soundHookDelay[Entity] = true;
	CreateTimer(MELEE_DURATION, ResetsoundHookDelay, Entity);
		
	// we need to subtract 1 from the current shove penalty prior to applying 
	// our own as the game has already incremented the shove penalty before we got hold of it.
	new shovePenalty = L4D_GetMeleeFatigue(Entity) - 1;
	if(shovePenalty < 0)	
		shovePenalty = 0;	

	if (shovePenalty >= MAX_EXISTING_FATIGUE)
		return Plugin_Continue;
			
	new newFatigue = shovePenalty + g_nonFatiguedMeleePenalty;
	L4D_SetMeleeFatigue(Entity, newFatigue);

	return Plugin_Continue;
}

L4D_GetMeleeFatigue(client)
{
	return GetEntProp(client, Prop_Send, "m_iShovePenalty");
}

L4D_SetMeleeFatigue(client, value)
{
	SetEntProp(client, Prop_Send, "m_iShovePenalty", value);
}

public Action:ResetsoundHookDelay(Handle:timer, any:client)
{
	soundHookDelay[client] = false;
}

static bool:ShouldPerformCustomFatigueLogic(const String:StrSample[PLATFORM_MAX_PATH], entity)
{
	// 1 is the standard setting, so just let the game handle it as normal.  
	if (g_nonFatiguedMeleePenalty <= 1) 
		return false;	

	// bugfix for some people on L4D2
	if (entity > MAXPLAYERS) 
		return false; 

	// note 'entity' means 'client' here
	if (soundHookDelay[entity]) 
		return false; 

	// Do the string contains last, as it's the most expensive check.	
	if (StrContains(StrSample, "Swish", false) == -1) 
		return false;
		
	return true;
}