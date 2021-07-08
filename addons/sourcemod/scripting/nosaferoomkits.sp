#pragma semicolon 1
#pragma newdecls required;

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "0.1.1"

float SurvivorStart[3];

public Plugin myinfo = 
{
	name = "No Safe Room Medkits",
	author = "Blade", //update syntax A1m`
	description = "Removes Safe Room Medkits",
	version = PLUGIN_VERSION,
	url = "https://github.com/Attano/L4D2-Competitive-Framework"
};

public void OnPluginStart()
{
	char game[64];
	GetGameFolderName(game, sizeof(game));
	if (!StrEqual(game, "left4dead2", false)) {
		SetFailState("Plugin supports Left 4 Dead 2 only.");
	}
	
	CreateConVar("nokits_version", PLUGIN_VERSION,"No Safe Room Medkits Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	HookEvent("round_start", view_as<EventHook>(Event_RoundStart), EventHookMode_PostNoCopy);
}

public void Event_RoundStart()
{
	char GameMode[32];
	GetConVarString(FindConVar("mp_gamemode"), GameMode, sizeof(GameMode));
	if (StrContains(GameMode, "versus", false) != -1) {
		//find where the survivors start so we know which medkits to replace,
		FindSurvivorStart();
		//and replace the medkits with pills.
		ReplaceMedkits();
	}
}

void FindSurvivorStart()
{
	int iEntityCount = GetEntityCount();
	char EdictClassName[128];
	float Location[3];
	//Search entities for either a locked saferoom door,
	for (int i = 0; i <= iEntityCount; i++) {
		if (IsValidEntity(i)) {
			GetEdictClassname(i, EdictClassName, sizeof(EdictClassName));
			if ((StrContains(EdictClassName, "prop_door_rotating_checkpoint", false) != -1) && (GetEntProp(i, Prop_Send, "m_bLocked")== 1)) {
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", Location);
				SurvivorStart = Location;
				return;
			}
		}
	}
	
	//or a survivor start point.
	for (int i = 0; i <= iEntityCount; i++) {
		if (IsValidEntity(i)) {
			GetEdictClassname(i, EdictClassName, sizeof(EdictClassName));
			if (StrContains(EdictClassName, "info_survivor_position", false) != -1) {
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", Location);
				SurvivorStart = Location;
				return;
			}
		}
	}
}

void ReplaceMedkits()
{
	int iEntityCount = GetEntityCount();
	char EdictClassName[128];
	float NearestMedkit[3], Location[3];
	
	//Look for the nearest medkit from where the survivors start,
	for (int i = 0; i <= iEntityCount; i++) {
		if (IsValidEntity(i)) {
			GetEdictClassname(i, EdictClassName, sizeof(EdictClassName));
			
			if (StrContains(EdictClassName, "weapon_first_aid_kit", false) != -1) {
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", Location);
				//If NearestMedkit is zero, then this must be the first medkit we found.
				
				if ((NearestMedkit[0] + NearestMedkit[1] + NearestMedkit[2]) == 0.0) {
					NearestMedkit = Location;
					continue;
				}
				
				//If this medkit is closer than the last medkit, record its location.
				if (GetVectorDistance(SurvivorStart, Location, false) < GetVectorDistance(SurvivorStart, NearestMedkit, false)) {
					NearestMedkit = Location;
				}
			}
		}
	}

	//then remove the kits
	for (int i = 0; i <= iEntityCount; i++) {
		if (IsValidEntity(i)) {
			GetEdictClassname(i, EdictClassName, sizeof(EdictClassName));
		
			if (StrContains(EdictClassName, "weapon_first_aid_kit", false) != -1) {
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", Location);
				
				if (GetVectorDistance(NearestMedkit, Location, false) < 400) {
					AcceptEntityInput(i, "Kill");
				}
			}
		}
	}
}
