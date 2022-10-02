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
#include <left4dhooks>
#include <sourcemod>

#define CALL_OPCODE 0xE8
#define L4D2Team_Survivor 2
#define L4D2Team_Infected 3
#define L4D2Infected_Tank 8

// xor eax,eax; NOP_3;
int
	PATCH_REPLACEMENT[5] = { 0x31, 0xC0, 0x0f, 0x1f, 0x00 },
	ORIGINAL_BYTES[5];
Address g_pPatchTarget;
bool    g_bIsPatched;

Handle
	hAllMaps,
	hSaferoomFrustrationTickdownMaps;

public Plugin myinfo =
{
	name        = "Checkpoint Rage Control",
	author      = "ProdigySim, Visor",
	description = "Enable tank to lose rage while survivors are in saferoom",
	version     = "0.3",
	url         = "https://github.com/Attano/L4D2-Competitive-Framework"


}

public void
	OnPluginStart()
{
	LoadTranslations("checkpoint-rage-control.phrases");
	Handle hGamedata = LoadGameConfigFile("checkpoint-rage-control");
	if (!hGamedata)
		SetFailState("Gamedata 'checkpoint-rage-control.txt' missing or corrupt");

	g_pPatchTarget = FindPatchTarget(hGamedata);
	CloseHandle(hGamedata);

	hSaferoomFrustrationTickdownMaps = CreateTrie();

	hAllMaps = CreateConVar("crc_global", "0", "Remove saferoom frustration preservation mechanic on all maps by default");

	RegServerCmd("saferoom_frustration_tickdown", SetSaferoomFrustrationTickdown);
}

public Action SetSaferoomFrustrationTickdown(int args)
{
	char mapname[64];
	GetCmdArg(1, mapname, sizeof(mapname));
	SetTrieValue(hSaferoomFrustrationTickdownMaps, mapname, true);
	return Plugin_Continue;
}

public void OnPluginEnd()
{
	Unpatch();
}

public void OnMapStart()
{
	if (GetConVarBool(hAllMaps))
	{
		Patch();
		return;
	}

	char mapname[64];
	GetCurrentMap(mapname, sizeof(mapname));

	int dummy;
	if (GetTrieValue(hSaferoomFrustrationTickdownMaps, mapname, dummy))
	{
		Patch();
	}
	else
	{
		Unpatch();
	}
}

public void L4D_OnSpawnTank_Post(int client, const float vecPos[3], const float vecAng[3])
{
	HookEvent("player_entered_start_area", Event_EnteredStartArea);
}

public void Event_EnteredStartArea(Event hEvent, const char[] eName, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if (IsValidSurvivor(client))
	{
		if (GetConVarBool(hAllMaps))
		{
			CPrintToChatAll("%t %t", "Tag", "LoseFrustration");
		}
		else
		{
			CPrintToChatAll("%t %t", "Tag", "KeepFrustration");
		}
	}
	UnhookEvent("player_entered_start_area", Event_EnteredStartArea);
}

bool IsPatched()
{
	return g_bIsPatched;
}

void Patch()
{
	if (!IsPatched())
	{
		for (int i = 0; i < sizeof(PATCH_REPLACEMENT); i++)
		{
			StoreToAddress(g_pPatchTarget + view_as<Address>(i), PATCH_REPLACEMENT[i], NumberType_Int8);
		}
		g_bIsPatched = true;
	}
}

void Unpatch()
{
	if (IsPatched())
	{
		for (int i = 0; i < sizeof(ORIGINAL_BYTES); i++)
		{
			StoreToAddress(g_pPatchTarget + view_as<Address>(i), ORIGINAL_BYTES[i], NumberType_Int8);
		}
		g_bIsPatched = false;
	}
}

Address FindPatchTarget(Handle hGamedata)
{
	Address pTarget = GameConfGetAddress(hGamedata, "SaferoomCheck_Sig");
	if (!pTarget)
		SetFailState("Couldn't find the 'SaferoomCheck_Sig' address");

	int iOffset = GameConfGetOffset(hGamedata, "UpdateZombieFrustration_SaferoomCheck");

	pTarget = pTarget + (view_as<Address>(iOffset));

	if (LoadFromAddress(pTarget, NumberType_Int8) != CALL_OPCODE)
		SetFailState("Saferoom Check Offset or signature seems incorrect");

	ORIGINAL_BYTES[0] = CALL_OPCODE;

	for (int i = 1; i < sizeof(ORIGINAL_BYTES); i++)
	{
		ORIGINAL_BYTES[i] = LoadFromAddress(pTarget + view_as<Address>(i), NumberType_Int8);
	}

	return pTarget;
}

stock bool IsValidClientIndex(int client)
{
	return (client > 0 && client <= MaxClients);
}

/**
 * Returns true if the client is currently on the survivor team. 
 *
 * @param client client ID
 * @return bool
 */
stock bool IsSurvivor(int client)
{
	return (IsClientInGame(client) && GetClientTeam(client) == L4D2Team_Survivor);
}

/**
 * Return true if the valid client index and is client on the survivor team.
 *
 * @param client client ID
 * @return bool
 */
stock bool IsValidSurvivor(int client)
{
	return (IsValidClientIndex(client) && IsSurvivor(client));
}