/*
	Checkpoint Rage Control (C) 2014 Michael Busby
	All trademarks are property of their respective owners.

	This program is free software: you can redistribute it and/or modify it
	under the terms of the GNU General Public License as published by the
	Free Software Foundation, either version 3 of the License, or (at your
	option) any later version.

	This program is distributed in the hope that it will be useful, but
	WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
	General Public License for more details.

	You should have received a copy of the GNU General Public License along
	with this program.  If not, see <http://www.gnu.org/licenses/>.
*/
#pragma semicolon 1
#pragma newdecls required

#include <colors>
#include <sourcemod>

#undef REQUIRE_PLUGIN
#include <left4dhooks>
#define REQUIRE_PLUGIN 

#define CALL_OPCODE 0xE8

// xor eax,eax; NOP_3;
int
	g_iOriginal[5],
	g_iReplacement[5] = {
		0x31,
		0xC0,
		0x0f,
		0x1f,
		0x00
	};

Address
	g_pPatchTarget;

bool
	g_bIsPatched,
	g_bIsHooked = false,
	g_bPlayerJoin[MAXPLAYERS + 1] = {false, ...};

ConVar
	g_cvarAllMaps,
	g_cvarDebug;

StringMap
	g_smTickdownMaps;

public Plugin myinfo =
{
	name		= "Checkpoint Rage Control",
	author		= "ProdigySim, Visor",
	description = "Enable tank to lose rage while survivors are in saferoom",
	version		= "0.3.1",
	url			= "https://github.com/Attano/L4D2-Competitive-Framework"

}

public void OnPluginStart()
{
	LoadTranslation("checkpoint-rage-control.phrases");
	
	g_cvarAllMaps = CreateConVar("crc_global", "0", "Remove saferoom frustration preservation mechanic on all maps by default");
	g_cvarDebug	  = CreateConVar("crc_debug", "0", "Whether or not to debug. 0:disable, 1:enable, 2:onlychat, 3:onlyconsole", FCVAR_NONE, true, 0.0, true, 3.0);

	LoadGameData();
	RegServerCmd("saferoom_frustration_tickdown", SetSaferoomFrustrationTickdown);
}

Action SetSaferoomFrustrationTickdown(int args)
{
	char sMap[64];
	GetCmdArg(1, sMap, sizeof(sMap));

	g_smTickdownMaps.SetValue(sMap, true);
	return Plugin_Handled;
}

public void OnPluginEnd()
{
	Unpatch();
}

public void OnMapStart()
{
	if (g_cvarAllMaps.BoolValue)
	{
		Patch();
		return;
	}

	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));

	int dummy;
	if (g_smTickdownMaps.GetValue(sMap, dummy))
		Patch();
	else
		Unpatch();
}

public void L4D_OnSpawnTank_Post(int client, const float vecPos[3], const float vecAng[3])
{
	if (g_bIsHooked)
		return;

	HookEvent("player_entered_start_area", Event_EnteredStartArea);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_team", Event_PlayerTeam, EventHookMode_Pre);

	DebugPrint("{blue}Prepared hooks{default} from L4D_OnSpawnTank_Post [player_entered_start_area, player_death, player_team]");
	g_bIsHooked = true;
}

public void L4D2_OnEndVersusModeRound_Post()
{
	if (!g_bIsHooked)
		return;

	DebugPrint("{red}Unhook{default} from L4D2_OnEndVersusModeRound_Post");
	UnHookAll();
}

void Event_EnteredStartArea(Event hEvent, const char[] sName, bool dontBroadcast)
{
	if (!g_bIsHooked)
		return;
		
	int client = GetClientOfUserId(hEvent.GetInt("userid"));
	if (!IsValidClientIndex(client) || !IsClientInGame(client) || IsFakeClient(client) || L4D_GetClientTeam(client) != L4DTeam_Survivor)
		return;

	if (g_bPlayerJoin[client])
	{
		DebugPrint("{red}Client{default} (%N) is marked as joining, skip {red}Unhook{default}", client);
		return;
	}

	if (g_cvarAllMaps.BoolValue)
		CPrintToChatAll("%t %t", "Tag", "LoseFrustration");
	else
		CPrintToChatAll("%t %t", "Tag", "KeepFrustration");

	DebugPrint("{red}Unhook{default} from Event_EnteredStartArea (%N)", client);
	UnHookAll();
}

void Event_PlayerDeath(Event hEvent, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(hEvent.GetInt("userid"));
	if (!IsValidClientIndex(client) || !IsClientInGame(client) || !IsTank(client))
		return;

	DebugPrint("{red}Unhook{default} from Event_PlayerDeath (%N)", client);
	UnHookAll();
}

public void Event_PlayerTeam(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	if (!g_bIsHooked)
		return;

	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if (!IsClientInGame(client) || IsFakeClient(client))
		return;

	L4DTeam Team = view_as<L4DTeam>(GetEventInt(hEvent, "team"));

	if (Team != L4DTeam_Survivor)
		return;
	
	g_bPlayerJoin[client] = true;
	DebugPrint("{blue}Client{default} ({blue}%N{default}) marked to joining", client);
	CreateTimer(0.2, Timer_PlayerTeamSurvivor, client, TIMER_FLAG_NO_MAPCHANGE);
}

Action Timer_PlayerTeamSurvivor(Handle timer, any data)
{
	g_bPlayerJoin[data] = false;
	DebugPrint("{blue}Client{default} ({blue}%N{default}) marked to not joining", data);
	return Plugin_Stop;
}

/**
 * Loads the game data for the 'checkpoint-rage-control' mod.
 * This function creates a new instance of the GameData class and checks if it was successfully created.
 * If the game data is missing or corrupt, it sets the fail state.
 * Otherwise, it prints a debug message indicating that the game data was loaded.
 * It then finds the patch target using the game data, deletes the game data instance, and creates a trie for tickdown maps.
 */
void LoadGameData()
{
	GameData
		gdRagecontrol = new GameData("checkpoint-rage-control");

	if (!gdRagecontrol)
		SetFailState("Gamedata 'checkpoint-rage-control.txt' missing or corrupt");
	else
		DebugPrint("{green}Loaded{default} gamedata 'checkpoint-rage-control.txt'");

	g_pPatchTarget = FindPatchTarget(gdRagecontrol);
	delete gdRagecontrol;

	g_smTickdownMaps = new StringMap();
}

/**
 * Unhooks all events that were previously hooked.
 */
void UnHookAll()
{
	UnhookEvent("player_entered_start_area", Event_EnteredStartArea);
	UnhookEvent("player_death", Event_PlayerDeath);
	g_bIsHooked = false;
}

/**
 * Patch function that applies a patch to the game.
 * This function checks if the patch has already been applied and returns if it has.
 * It then iterates over the g_iReplacement array and stores each element to the corresponding address in memory.
 * Finally, it sets the g_bIsPatched flag to true.
 */
void Patch()
{
	if (g_bIsPatched)
		return;

	for (int i = 0; i < sizeof(g_iReplacement); i++)
	{
		if (StoreToAddress(g_pPatchTarget + view_as<Address>(i), g_iReplacement[i], NumberType_Int8))
			DebugPrint("{green}Patched{default} Saferoom Check [Address:0x%X], [Replacement:0x%X]", g_pPatchTarget + view_as<Address>(i), g_iReplacement[i]);
		else
			DebugPrint("{red}Failed to patch{default} Saferoom Check [Address:0x%X], [Replacement:0x%X]", g_pPatchTarget + view_as<Address>(i), g_iReplacement[i]);

	}
	g_bIsPatched = true;
}

/**
 * Unpatches the target address by restoring the original bytes.
 * If the target address is not patched, this function does nothing.
 */
void Unpatch()
{
	if (!g_bIsPatched)
		return;

	for (int i = 0; i < sizeof(g_iOriginal); i++)
	{
		StoreToAddress(g_pPatchTarget + view_as<Address>(i), g_iOriginal[i], NumberType_Int8);
	}
	g_bIsPatched = false;
}

/**
 * Finds the target address for patching in the game data.
 *
 * @param gamedata The game data object containing the necessary information.
 * @return The target address for patching.
 */
Address FindPatchTarget(GameData gamedata)
{
	Address
		pTarget = gamedata.GetAddress("SaferoomCheck_Sig");

	if (!pTarget)
		SetFailState("Couldn't find the 'SaferoomCheck_Sig' address");
	else
		DebugPrint("{green}Found{default} Saferoom Check Signature [Address:0x%X]", pTarget);

	int iOffset = gamedata.GetOffset("UpdateZombieFrustration_SaferoomCheck");
	pTarget = pTarget + (view_as<Address>(iOffset));

	if (LoadFromAddress(pTarget, NumberType_Int8) != CALL_OPCODE)
		SetFailState("Saferoom Check Offset or signature seems incorrect");

	g_iOriginal[0] = CALL_OPCODE;

	for (int i = 1; i < sizeof(g_iOriginal); i++)
	{
		g_iOriginal[i] = LoadFromAddress(pTarget + view_as<Address>(i), NumberType_Int8);
	}

	return pTarget;
}

/**
 * Checks if the given client index is valid.
 *
 * @param client The client index to check.
 * @return True if the client index is valid, false otherwise.
 */
bool IsValidClientIndex(int client)
{
	return (client > 0 && client <= MaxClients);
}

/**
 * Is the player the tank?
 *
 * @param client client ID
 * @return bool
 */
bool IsTank(int client)
{
	return (L4D_GetClientTeam(client) == L4DTeam_Infected && L4D2_GetPlayerZombieClass(client) == L4D2ZombieClass_Tank);
}

/**
 * Prints a debug message to the chat for all players.
 *
 * @param sMsg The message to be printed.
 */
void DebugPrint(char[] sMessage, any...)
{
	if (!g_cvarDebug.BoolValue)
		return;

	static char sFormat[512];
	VFormat(sFormat, sizeof(sFormat), sMessage, 2);

	if (g_cvarDebug.IntValue == 1 || g_cvarDebug.IntValue == 2)
		CPrintToChatAll("%t %s", "Tag", sFormat);
	
	if (g_cvarDebug.IntValue == 1 || g_cvarDebug.IntValue == 3)
	{
		CRemoveTags(sFormat, sizeof(sFormat));
		PrintToServer("[Checkpoint Rage Control] %s", sFormat);
	}
}

/**
 * Check if the translation file exists
 *
 * @param translation	Translation name.
 * @noreturn
 */
void LoadTranslation(const char[] translation)
{
	char
		sPath[PLATFORM_MAX_PATH],
		sName[64];

	Format(sName, sizeof(sName), "translations/%s.txt", translation);
	BuildPath(Path_SM, sPath, sizeof(sPath), sName);
	if (!FileExists(sPath))
		SetFailState("Missing translation file %s.txt", translation);

	LoadTranslations(translation);
}
