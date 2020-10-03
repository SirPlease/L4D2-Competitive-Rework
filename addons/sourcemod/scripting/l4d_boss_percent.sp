/*
	SourcePawn is Copyright (C) 2006-2008 AlliedModders LLC.  All rights reserved.
	SourceMod is Copyright (C) 2006-2008 AlliedModders LLC.  All rights reserved.
	Pawn and SMALL are Copyright (C) 1997-2008 ITB CompuPhase.
	Source is Copyright (C) Valve Corporation.
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

#include <sourcemod>
#include <builtinvotes>
#include <left4dhooks>
#include <l4d2util>
#include <readyup>
#include <colors>

#define IS_VALID_CLIENT(%1)     (%1 > 0 && %1 <= MaxClients)
#define IS_INFECTED(%1)         (GetClientTeam(%1) == 3)
#define IS_VALID_INGAME(%1)     (IS_VALID_CLIENT(%1) && IsClientInGame(%1))
#define IS_VALID_INFECTED(%1)   (IS_VALID_INGAME(%1) && IS_INFECTED(%1))
#define IS_VALID_CASTER(%1)     (IS_VALID_INGAME(%1) && IsClientCaster(%1))

public Plugin:myinfo =
{
	name = "L4D2 Boss Flow Announce (Back to roots edition)",
	author = "ProdigySim, Jahze, Stabby, CircleSquared, CanadaRox, Visor, Sir",
	version = "1.6.2",
	description = "Announce boss flow percents!",
	url = "https://github.com/Attano/Equilibrium"
};

new iWitchPercent = 0;
new iTankPercent = 0;
new iTank;
new iWitch;
new bool:bTank;
new bool:bWitch;
new bool:bDKR;

new Handle:g_hVsBossBuffer;
new Handle:hCvarPrintToEveryone;
new Handle:hCvarTankPercent;
new Handle:hCvarWitchPercent;
new Handle:hCvarVoteEnable;
new bool:readyUpIsAvailable;
new bool:readyFooterAdded;
new Handle:g_hVote;
new Handle:VoteForward;


public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("UpdateBossPercents", Native_UpdateBossPercents);
	MarkNativeAsOptional("AddStringToReadyFooter");
	RegPluginLibrary("l4d_boss_percent");
	return APLRes_Success;
}

public OnPluginStart()
{
	g_hVsBossBuffer = FindConVar("versus_boss_buffer");

	hCvarPrintToEveryone = CreateConVar("l4d_global_percent", "1", "Display boss percentages to entire team when using commands");
	hCvarTankPercent = CreateConVar("l4d_tank_percent", "1", "Display Tank flow percentage in chat");
	hCvarWitchPercent = CreateConVar("l4d_witch_percent", "1", "Display Witch flow percentage in chat");
	hCvarVoteEnable = CreateConVar("l4d_boss_vote", "1", "Allow for Easy Setup of the Boss Spawns");

	RegConsoleCmd("sm_boss", BossCmd);
	RegConsoleCmd("sm_tank", BossCmd);
	RegConsoleCmd("sm_witch", BossCmd);
	RegConsoleCmd("sm_voteboss", VoteBoss_Cmd, "Let's vote to set those Boss Spawns!");
	RegConsoleCmd("sm_bossvote", VoteBoss_Cmd, "Let's vote to set those Boss Spawns!");
	RegConsoleCmd("sm_settank", VoteBoss_Cmd, "Let's vote to set those Boss Spawns!");
	RegConsoleCmd("sm_setwitch", VoteBoss_Cmd, "Let's vote to set those Boss Spawns!");
	VoteForward = CreateGlobalForward("OnBossVote", ET_Event);

	HookEvent("player_left_start_area", LeftStartAreaEvent, EventHookMode_PostNoCopy);
	HookEvent("round_start", RoundStartEvent, EventHookMode_PostNoCopy);
	HookEvent("player_say", CuteWorkAround, EventHookMode_Pre);
}

public OnMapStart()
{
	if (IsDKR()) bDKR = true;
	else bDKR = false;
}

public OnAllPluginsLoaded()
{
	readyUpIsAvailable = LibraryExists("readyup");
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "readyup")) readyUpIsAvailable = false;
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "readyup")) readyUpIsAvailable = true;
}

public LeftStartAreaEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!readyUpIsAvailable)
		for (new client = 1; client <= MaxClients; client++)
			if (IsClientConnected(client) && IsClientInGame(client))
				PrintBossPercents(client);
}

public OnRoundIsLive()
{
	for (new client = 1; client <= MaxClients; client++)
		if (IsClientConnected(client) && IsClientInGame(client))
			PrintBossPercents(client);
}

public RoundStartEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	readyFooterAdded = false;

	if (!IsDKR())
	{
		CreateTimer(5.0, SaveBossFlows);
		CreateTimer(6.0, AddReadyFooter); // workaround for boss equalizer
	}
}

public Native_UpdateBossPercents(Handle:plugin, numParams)
{
	CreateTimer(0.1, SaveBossFlows);
	CreateTimer(0.2, AddReadyFooter);
	return true;
}

public Action:CuteWorkAround(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!bDKR) return Plugin_Continue;
	new UserID = GetEventInt(event, "userid");
	if (UserID == 0) // Is Console Output on Dark Carnival Remix
	{
		new String:sBuffer[128];
		GetEventString(event, "text", sBuffer, sizeof(sBuffer));

		if (StrContains(sBuffer, "The Tank", false) != -1)
		{
			iTankPercent = FindNumbers(sBuffer);
			iWitchPercent = 0;
			CreateTimer(0.2, AddReadyFooter);
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public Action:SaveBossFlows(Handle:timer)
{
	if (!InSecondHalfOfRound())
	{
		iWitchPercent = 0;
		iTankPercent = 0;

		if (L4D2Direct_GetVSWitchToSpawnThisRound(0))
		{
			iWitchPercent = RoundToNearest(GetWitchFlow(0)*100.0);
		}
		if (L4D2Direct_GetVSTankToSpawnThisRound(0))
		{
			iTankPercent = RoundToNearest(GetTankFlow(0)*100.0);
		}
	}
	else
	{
		if (iWitchPercent != 0)
		{
			iWitchPercent = RoundToNearest(GetWitchFlow(1)*100.0);
		}
		if (iTankPercent != 0)
		{
			iTankPercent = RoundToNearest(GetTankFlow(1)*100.0);
		}
	}
}

public Action:AddReadyFooter(Handle:timer)
{
	if (readyFooterAdded) return;
	if (readyUpIsAvailable)
	{
		decl String:readyString[65];
		if (iWitchPercent && iTankPercent)
			Format(readyString, sizeof(readyString), "Tank: %d%%, Witch: %d%%", iTankPercent, iWitchPercent);
		else if (iTankPercent)
			Format(readyString, sizeof(readyString), "Tank: %d%%, Witch: None", iTankPercent);
		else if (iWitchPercent)
			Format(readyString, sizeof(readyString), "Tank: None, Witch: %d%%", iWitchPercent);
		else
			Format(readyString, sizeof(readyString), "Tank: None, Witch: None");
		AddStringToReadyFooter(readyString);
		readyFooterAdded = true;
	}
}

stock PrintBossPercents(client)
{
	FakeClientCommand(client, "say /current");
	CreateTimer(0.1, PrintStuff, client);
}

public Action:PrintStuff(Handle:timer, any:client)
{
	if(IsValidClient(client))
	{
		if(GetConVarBool(hCvarTankPercent))
		{
			if (iTankPercent)
				CPrintToChat(client, "{default}<{olive}Tank{default}> {red}%d%%", iTankPercent);
			else
				CPrintToChat(client, "{default}<{olive}Tank{default}> {red}None");
		}

		if(GetConVarBool(hCvarWitchPercent))
		{
			if (iWitchPercent)
				CPrintToChat(client, "{default}<{olive}Witch{default}> {red}%d%%", iWitchPercent);
			else
				CPrintToChat(client, "{default}<{olive}Witch{default}> {red}None");
		}
	}	
}

stock bool:IsValidClient(client)
{ 
	if (client <= 0 || client > MaxClients || !IsClientConnected(client))
	{
		return false; 
	}
	return IsClientInGame(client); 
}

public Action:BossCmd(client, args)
{
	new L4D2_Team:iTeam = L4D2_Team:GetClientTeam(client);
	if (iTeam == L4D2Team_Spectator)
	{
		PrintBossPercents(client);
		return Plugin_Handled;
	}

	if (GetConVarBool(hCvarPrintToEveryone))
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientConnected(i) && IsClientInGame(i) && L4D2_Team:GetClientTeam(i) == iTeam)
			{
				PrintBossPercents(i);
			}
		}
	}
	else
	{
		PrintBossPercents(client);
	}

	return Plugin_Handled;
}

public Action:VoteBoss_Cmd(client, args)
{
	if (IsValidClient(client) && GetConVarBool(hCvarVoteEnable))
	{
		if (IsDKR()) 
		{
			CPrintToChat(client, "{blue}[{default}VoteBoss{blue}] {olive}Not Available on this Map.");
			return Plugin_Handled;
		}

		if (args != 2 || !IsInReady() || InSecondHalfOfRound())
		{
			if (!IsInReady() || InSecondHalfOfRound()) CPrintToChat(client, "{blue}[{default}BossVote{blue}] {default}You can only set Spawns during Ready-up in the first round.");
			else
			{
				CPrintToChat(client, "{blue}[{default}VoteBoss{blue}] {olive}Usage: {default}!voteboss <tank> <witch>");
				CPrintToChat(client, "{blue}[{default}VoteBoss{blue}] {olive}Use {default}'{blue}0{default}' for {olive}No Spawn.");
			}
			return Plugin_Handled;
		}

		//Args
		new String:sTank[32];
		new String:sWitch[32];
		GetCmdArg(1, sTank, sizeof(sTank));
		GetCmdArg(2, sWitch, sizeof(sWitch));
		iTank = StringToInt(sTank);
		iWitch = StringToInt(sWitch);
		bWitch = GetConVarBool(hCvarWitchPercent);
		bTank = GetConVarBool(hCvarTankPercent);

		// Admins don't need votes!
		if (GetUserAdmin(client) != INVALID_ADMIN_ID)
		{
			SetBoss();
			return Plugin_Handled;
		}

		new iNumPlayers;
		decl iPlayers[MaxClients];
		//list of non-spectators players
		for (new i=1; i<=MaxClients; i++)
		{
			if (!IsClientInGame(i) || IsFakeClient(i) || (GetClientTeam(i) == 1))
			{
				continue;
			}
			iPlayers[iNumPlayers++] = i;
		}

		if (iNumPlayers < 4)
		{
			CPrintToChat(client, "{blue}[{default}VoteBoss{blue}] {default}You need at least 4 Players to start this vote.");
			return Plugin_Handled;
		}

		if (IsNewBuiltinVoteAllowed())
		{
			new String:sBuffer[64];
			g_hVote = CreateBuiltinVote(VoteActionHandler, BuiltinVoteType_Custom_YesNo, BuiltinVoteAction_Cancel | BuiltinVoteAction_VoteEnd | BuiltinVoteAction_End);
			Format(sBuffer, sizeof(sBuffer), "Set Tank to %i%% and Witch to %i%%?", iTank, iWitch);
			SetBuiltinVoteArgument(g_hVote, sBuffer);
			SetBuiltinVoteInitiator(g_hVote, client);
			SetBuiltinVoteResultCallback(g_hVote, VoteResultHandler);
			DisplayBuiltinVote(g_hVote, iPlayers, iNumPlayers, 20);
			return Plugin_Handled;
		}
		CPrintToChat(client, "{blue}[{default}VoteBoss{blue}] {default}Vote can't be started right now...");
	}
	return Plugin_Handled;
}

public VoteResultHandler(Handle:vote, num_votes, num_clients, const client_info[][2], num_items, const item_info[][2])
{
	for (new i=0; i<num_items; i++)
	{
		if (item_info[i][BUILTINVOTEINFO_ITEM_INDEX] == BUILTINVOTES_VOTE_YES)
		{
			if (item_info[i][BUILTINVOTEINFO_ITEM_VOTES] > (num_votes / 2))
			{
				DisplayBuiltinVotePass(vote, "Setting Spawns...");
				SetBoss();
				return;
			}
		}
	}
	DisplayBuiltinVoteFail(vote, BuiltinVoteFail_Loses);
}

public VoteActionHandler(Handle:vote, BuiltinVoteAction:action, param1, param2)
{
	switch (action)
	{
		case BuiltinVoteAction_End:
		{
			g_hVote = INVALID_HANDLE;
			CloseHandle(vote);
		}
		case BuiltinVoteAction_Cancel:
		{
			DisplayBuiltinVoteFail(vote, BuiltinVoteFailReason:param1);
		}
	}
}

stock SetBoss()
{
	new String:sBuffer[64];
	new Float:fSpawnflow = 0.0;
	if (iTank == 0 || !bTank)
	{
		L4D2Direct_SetVSTankToSpawnThisRound(0, false);
		L4D2Direct_SetVSTankToSpawnThisRound(1, false);
	}
	else if (iTank == 100) fSpawnflow = 1.0;
	else
	{
		Format(sBuffer, sizeof(sBuffer), "0.%i", iTank);
		fSpawnflow = StringToFloat(sBuffer);
	}

	L4D2Direct_SetVSTankFlowPercent(0, fSpawnflow);
	L4D2Direct_SetVSTankFlowPercent(1, fSpawnflow);

	if (iWitch == 0 || !bWitch)
	{
		fSpawnflow = 0.0;
		L4D2Direct_SetVSWitchToSpawnThisRound(0, false);
		L4D2Direct_SetVSWitchToSpawnThisRound(1, false);
	}
	else if (iWitch == 100) fSpawnflow = 1.0;
	else
	{
		Format(sBuffer, sizeof(sBuffer), "0.%i", iWitch);
		fSpawnflow = StringToFloat(sBuffer);
	}

	L4D2Direct_SetVSWitchFlowPercent(0, fSpawnflow);
	L4D2Direct_SetVSWitchFlowPercent(1, fSpawnflow);

	Call_StartForward(VoteForward);
	Call_Finish();

	readyFooterAdded = false;
	CreateTimer(0.1, SaveBossFlows);
	CreateTimer(0.2, AddReadyFooter);
}

stock Float:GetTankFlow(round)
{
	return L4D2Direct_GetVSTankFlowPercent(round) -
		( Float:GetConVarInt(g_hVsBossBuffer) / L4D2Direct_GetMapMaxFlowDistance() );
}

stock Float:GetWitchFlow(round)
{
	return L4D2Direct_GetVSWitchFlowPercent(round) -
		( Float:GetConVarInt(g_hVsBossBuffer) / L4D2Direct_GetMapMaxFlowDistance() );
}

stock PrintToInfected(const String:Message[], any:... )
{
	decl String:sPrint[256];
	VFormat(sPrint, sizeof(sPrint), Message, 2);

	for (new i = 1; i <= MaxClients; i++) 
	{
		if (!IS_VALID_INFECTED(i) && !IS_VALID_CASTER(i)) 
		{ 
			continue; 
		}

		CPrintToChat(i, "{default}%s", sPrint);
	}
}

stock bool:IsDKR()
{
	new String:sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));
	if (StrEqual(sMap, "dkr_m1_motel") 	  ||
	StrEqual(sMap, "dkr_m2_carnival") 	  ||
	StrEqual(sMap, "dkr_m3_tunneloflove") ||
	StrEqual(sMap, "dkr_m4_ferris") 	  ||
	StrEqual(sMap, "dkr_m5_stadium")) return true;
	return false;
}

stock FindNumbers(String:sTemp[])
{
	new String:sBuffer[2];
	sBuffer[0] = 'A'; sBuffer[1] = 'A';

	new n=0;
	while (sTemp[n] != '\0' && (sBuffer[0] == 'A' || sBuffer[1] == 'A')) {
	
		new character = sTemp[n]; // Caching
		if (character == '0' ||
		character == '1' ||
		character == '2' ||
		character == '3' ||
		character == '4' ||
		character == '5' ||
		character == '6' ||
		character == '7' ||
		character == '8' ||
		character == '9')
		{
			if (StrEqual(sBuffer, "AA")) sBuffer[0] = character;
			else sBuffer[1] = character;
		}

		n++;
	}

	return StringToInt(sBuffer);
}