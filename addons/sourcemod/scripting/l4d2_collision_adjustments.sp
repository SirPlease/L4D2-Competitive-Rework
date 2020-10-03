#include <sourcemod>
#include <collisionhook>

new bool:isPulled[MAXPLAYERS + 1] = false;
new String:sModelCharged[64];

//Cvars
new Handle:hRockFix;
new Handle:hPullThrough;
new Handle:hRockThroughIncap;
new bool:bRockFix;
new bool:bPullThrough;
new bool:bRockThroughIncap;

//Strings to dump stuff in
new String:sEntityCName[20];
new String:sEntityCNameTwo[20];



public Plugin:myinfo =
{
	name = "L4D2 Collision Adjustments",
	author = "Sir",
	version = "1.2",
	description = "Allows messing with pesky Collisions in Left 4 Dead 2",
	url = "https://github.com/SirPlease/SirCoding"
};

public OnPluginStart()
{
	// Smokers
	HookEvent("tongue_grab", Event_SurvivorPulled);
	HookEvent("tongue_release", Event_PullEnd);

	// Chargers
	HookEvent("round_start", Event_RoundStart);
	HookEvent("charger_killed", Event_ChargerKilled);
	HookEvent("charger_carry_start", Event_CarryStart);
	HookEvent("charger_pummel_end", Event_PummelEnd);

	RegConsoleCmd("sm_tellme", TellMe_Cmd);

	//Cvars
	hRockFix = CreateConVar("collision_tankrock_common", "1", "Will Rocks go through Common Infected (and also kill them) instead of possibly getting stuck on them?");
	hPullThrough = CreateConVar("collision_smoker_common", "0", "Will Pulled Survivors go through Common Infected?");
	hRockThroughIncap = CreateConVar("collision_tankrock_incap", "0", "Will Rocks go through Incapacitated Survivors? (Won't go through new incaps caused by the Rock)");
	bRockFix = GetConVarBool(hRockFix);
	bPullThrough = GetConVarBool(hPullThrough);
	bRockThroughIncap = GetConVarBool(hRockThroughIncap);

	//Cvar Changes
	HookConVarChange(hRockFix, cvarChanged);
	HookConVarChange(hPullThrough, cvarChanged);
	HookConVarChange(hRockThroughIncap, cvarChanged);

	sModelCharged = "Nobody";
}

public Action:TellMe_Cmd(client, args)
{
	PrintToChat(client, "sModelCharged = %s", sModelCharged);
}

public Action:CH_PassFilter(ent1, ent2, &bool:result)
{
	if (!IsValidEdict(ent1) || !IsValidEdict(ent2)) return Plugin_Handled;

	GetEdictClassname(ent1, sEntityCName, 20);
	GetEdictClassname(ent2, sEntityCNameTwo, 20);

	if (StrEqual(sEntityCName, "infected"))
	{
		if (bRockFix && StrEqual(sEntityCNameTwo, "tank_rock"))
		{
			result = false;
			return Plugin_Handled;
		}

		if (bPullThrough && IsSurvivor(ent2) && isPulled[ent2])
		{
			result = false;
			return Plugin_Handled;			
		}
	}
	else if (StrEqual(sEntityCNameTwo, "infected"))
	{
		if (bRockFix && StrEqual(sEntityCName, "tank_rock"))
		{
			result = false;
			return Plugin_Handled;
		}

		if (bPullThrough && IsSurvivor(ent1) && isPulled[ent1])
		{
			result = false;
			return Plugin_Handled;			
		}
	}
	else if (StrEqual(sEntityCName, "tank_rock"))
	{
		if (bRockThroughIncap && IsIncapacitated(ent2))
		{
			result = false;
			return Plugin_Handled;
		}
	}
	else if (StrEqual(sEntityCNameTwo, "tank_rock"))
	{
		if (bRockThroughIncap && IsIncapacitated(ent1))
		{
			result = false;
			return Plugin_Handled;
		}		
	}
	else if (!StrEqual("Nobody", sModelCharged) && IsValidClient(ent1) && IsValidClient(ent2))
	{
		if (GetClientTeam(ent1) == 2 && GetClientTeam(ent2) == 3 && GetEntProp(ent2, Prop_Send, "m_zombieClass") < 6)
		{
			/*if (GetEntPropEnt(ent1, Prop_Send, "m_pummelAttacker") > 0) 
			{
				sModelCharged = "Nobody";
				return Plugin_Continue;
			}*/

			new String:sModel[64];
			GetClientModel(ent1, sModel, sizeof(sModel));
			if (StrEqual(sModel, sModelCharged))
			{
				result = false;
				return Plugin_Handled;
			}
		}
		else if (GetClientTeam(ent2) == 2 && GetClientTeam(ent1) == 3 && GetEntProp(ent1, Prop_Send, "m_zombieClass") < 6 )
		{
			/*if (GetEntPropEnt(ent2, Prop_Send, "m_pummelAttacker") > 0) 
			{
				sModelCharged = "Nobody";
				return Plugin_Continue;
			}*/

			new String:sModel[64];
			GetClientModel(ent2, sModel, sizeof(sModel));
			if (StrEqual(sModel, sModelCharged))
			{
				result = false;
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Continue;
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	sModelCharged = "Nobody";
}

public Event_ChargerKilled(Handle:event, const String:name[], bool:dontBroadcast)
{
	sModelCharged = "Nobody";
}

public Event_CarryStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Victim = GetClientOfUserId(GetEventInt(event, "victim"));
	GetClientModel(Victim, sModelCharged, sizeof(sModelCharged));
}

public Event_PummelEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	sModelCharged = "Nobody";
}

public Event_SurvivorPulled(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	isPulled[victim] = true;
}

public Event_PullEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	isPulled[victim] = false;
}

public cvarChanged(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	bRockFix = GetConVarBool(hRockFix);
	bPullThrough = GetConVarBool(hPullThrough);
	bRockThroughIncap = GetConVarBool(hRockThroughIncap);
}

// ----------------------------

bool:IsValidClient(client) { 
    if (client <= 0 || client > MaxClients || !IsClientConnected(client)) return false; 
    return IsClientInGame(client); 
} 

bool:IsSurvivor(client) {
	return IsValidClient(client) && GetClientTeam(client) == 2;
}

bool:IsIncapacitated(client) {
	new bool:bIsIncapped = false;
	if ( IsSurvivor(client) ) {
		if (GetEntProp(client, Prop_Send, "m_isIncapacitated") > 0) bIsIncapped = true;
		if (!IsPlayerAlive(client)) bIsIncapped = true;
	}
	return bIsIncapped;
}