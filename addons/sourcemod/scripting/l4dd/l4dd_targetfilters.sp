/*
*	Left 4 DHooks Direct
*	Copyright (C) 2023 Silvers
*
*	This program is free software: you can redistribute it and/or modify
*	it under the terms of the GNU General Public License as published by
*	the Free Software Foundation, either version 3 of the License, or
*	(at your option) any later version.
*
*	This program is distributed in the hope that it will be useful,
*	but WITHOUT ANY WARRANTY; without even the implied warranty of
*	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*	GNU General Public License for more details.
*
*	You should have received a copy of the GNU General Public License
*	along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/



// Prevent compiling if not compiled from "left4dhooks.sp"
#if !defined COMPILE_FROM_MAIN
 #error This file must be inside "scripting/l4dd/" while compiling "left4dhooks.sp" to include its content.
#endif



#pragma semicolon 1
#pragma newdecls required



// ====================================================================================================
//										TARGET FILTERS
// ====================================================================================================
void LoadTargetFilters()
{
	AddMultiTargetFilter("@s",							FilterSurvivor,	"Survivors", false);
	AddMultiTargetFilter("@surv",						FilterSurvivor,	"Survivors", false);
	AddMultiTargetFilter("@survivors",					FilterSurvivor,	"Survivors", false);
	AddMultiTargetFilter("@incappedsurvivors",			FilterIncapped,	"Incapped Survivors", false);
	AddMultiTargetFilter("@is",							FilterIncapped,	"Incapped Survivors", false);
	AddMultiTargetFilter("@infe",						FilterInfected,	"Infected", false);
	AddMultiTargetFilter("@infected",					FilterInfected,	"Infected", false);
	AddMultiTargetFilter("@i",							FilterInfected,	"Infected", false);

	AddMultiTargetFilter("@randomincappedsurvivor",		FilterRandomA,	"Random Incapped Survivors", false);
	AddMultiTargetFilter("@ris",						FilterRandomA,	"Random Incapped Survivors", false);
	AddMultiTargetFilter("@randomsurvivor",				FilterRandomB,	"Random Survivors", false);
	AddMultiTargetFilter("@rs",							FilterRandomB,	"Random Survivors", false);
	AddMultiTargetFilter("@randominfected",				FilterRandomC,	"Random Infected", false);
	AddMultiTargetFilter("@ri",							FilterRandomC,	"Random Infected", false);
	AddMultiTargetFilter("@randomtank",					FilterRandomD,	"Random Tank", false);
	AddMultiTargetFilter("@rt",							FilterRandomD,	"Random Tank", false);
	AddMultiTargetFilter("@rincappedsurvivorbot",		FilterRandomE,	"Random Incapped Survivor Bot", false);
	AddMultiTargetFilter("@risb",						FilterRandomE,	"Random Incapped Survivor Bot", false);
	AddMultiTargetFilter("@rsurvivorbot",				FilterRandomF,	"Random Survivor Bot", false);
	AddMultiTargetFilter("@rsb",						FilterRandomF,	"Random Survivor Bot", false);
	AddMultiTargetFilter("@rinfectedbot",				FilterRandomG,	"Random Infected Bot", false);
	AddMultiTargetFilter("@rib",						FilterRandomG,	"Random Infected Bot", false);
	AddMultiTargetFilter("@rtankbot",					FilterRandomH,	"Random Tank Bot", false);
	AddMultiTargetFilter("@rtb",						FilterRandomH,	"Random Tank Bot", false);

	AddMultiTargetFilter("@blackwhite",					FilterDeadG,	"Black and White survivors on third strike", false);
	AddMultiTargetFilter("@bw",							FilterDeadG,	"Black and White survivors on third strike", false);
	AddMultiTargetFilter("@deads",						FilterDeadA,	"Dead Survivors (all, bots)", false);
	AddMultiTargetFilter("@deadsi",						FilterDeadB,	"Dead Special Infected (all, bots)", false);
	AddMultiTargetFilter("@deadsp",						FilterDeadC,	"Dead Survivors players (no bots)", false);
	AddMultiTargetFilter("@deadsip",					FilterDeadD,	"Dead Special Infected players (no bots)", false);
	AddMultiTargetFilter("@deadsb",						FilterDeadE,	"Dead Survivors bots (no players)", false);
	AddMultiTargetFilter("@deadsib",					FilterDeadF,	"Dead Special Infected bots (no players)", false);
	AddMultiTargetFilter("@sp",							FilterPlayA,	"Survivors players (no bots)", false);
	AddMultiTargetFilter("@sip",						FilterPlayB,	"Special Infected players (no bots)", false);
	AddMultiTargetFilter("@isb",						FilterIncapA,	"Incapped Survivor Only Bots", false);
	AddMultiTargetFilter("@isp",						FilterIncapB,	"Incapped Survivor Only Players", false);
	AddMultiTargetFilter("@survivorbots",				FilterPlayC,	"Survivors players (bots only)", false);
	AddMultiTargetFilter("@sb",							FilterPlayC,	"Survivors players (bots only)", false);
	AddMultiTargetFilter("@infectedbots",				FilterPlayD,	"Infected players (bots only)", false);
	AddMultiTargetFilter("@ib",							FilterPlayD,	"Infected players (bots only)", false);

	AddMultiTargetFilter("@nick",						FilterNick,		"Nick", false);
	AddMultiTargetFilter("@rochelle",					FilterRochelle,	"Rochelle", false);
	AddMultiTargetFilter("@coach",						FilterCoach,	"Coach", false);
	AddMultiTargetFilter("@ellis",						FilterEllis,	"Ellis", false);
	AddMultiTargetFilter("@bill",						FilterBill,		"Bill", false);
	AddMultiTargetFilter("@zoey",						FilterZoey,		"Zoey", false);
	AddMultiTargetFilter("@francis",					FilterFrancis,	"Francis", false);
	AddMultiTargetFilter("@louis",						FilterLouis,	"Louis", false);

	AddMultiTargetFilter("@smokers",					FilterSmoker,	"Smokers", false);
	AddMultiTargetFilter("@boomers",					FilterBoomer,	"Boomers", false);
	AddMultiTargetFilter("@hunters",					FilterHunter,	"Hunters", false);
	AddMultiTargetFilter("@spitters",					FilterSpitter,	"Spitters", false);
	AddMultiTargetFilter("@jockeys",					FilterJockey,	"Jockeys", false);
	AddMultiTargetFilter("@chargers",					FilterCharger,	"Chargers", false);

	AddMultiTargetFilter("@tank",						FilterTanks,	"Tanks", false);
	AddMultiTargetFilter("@tanks",						FilterTanks,	"Tanks", false);
	AddMultiTargetFilter("@t",							FilterTanks,	"Tanks", false);
}

void UnloadTargetFilters()
{
	RemoveMultiTargetFilter("@s",						FilterSurvivor);
	RemoveMultiTargetFilter("@surv",					FilterSurvivor);
	RemoveMultiTargetFilter("@survivors",				FilterSurvivor);
	RemoveMultiTargetFilter("@incappedsurvivors",		FilterIncapped);
	RemoveMultiTargetFilter("@is",						FilterIncapped);
	RemoveMultiTargetFilter("@infe",					FilterInfected);
	RemoveMultiTargetFilter("@infected",				FilterInfected);
	RemoveMultiTargetFilter("@i",						FilterInfected);

	RemoveMultiTargetFilter("@randomincappedsurvivor",	FilterRandomA);
	RemoveMultiTargetFilter("@ris",						FilterRandomA);
	RemoveMultiTargetFilter("@randomsurvivor",			FilterRandomB);
	RemoveMultiTargetFilter("@rs",						FilterRandomB);
	RemoveMultiTargetFilter("@randominfected",			FilterRandomC);
	RemoveMultiTargetFilter("@ri",						FilterRandomC);
	RemoveMultiTargetFilter("@randomtank",				FilterRandomD);
	RemoveMultiTargetFilter("@rt",						FilterRandomD);
	RemoveMultiTargetFilter("@rincappedsurvivorbot",	FilterRandomE);
	RemoveMultiTargetFilter("@risb",					FilterRandomE);
	RemoveMultiTargetFilter("@rsurvivorbot",			FilterRandomF);
	RemoveMultiTargetFilter("@rsb",						FilterRandomF);
	RemoveMultiTargetFilter("@rinfectedbot",			FilterRandomG);
	RemoveMultiTargetFilter("@rib",						FilterRandomG);
	RemoveMultiTargetFilter("@rtankbot",				FilterRandomH);
	RemoveMultiTargetFilter("@rtb",						FilterRandomH);

	RemoveMultiTargetFilter("@blackwhite",				FilterDeadG);
	RemoveMultiTargetFilter("@bw",						FilterDeadG);
	RemoveMultiTargetFilter("@deads",					FilterDeadA);
	RemoveMultiTargetFilter("@deadsi",					FilterDeadB);
	RemoveMultiTargetFilter("@deadsp",					FilterDeadC);
	RemoveMultiTargetFilter("@deadsip",					FilterDeadD);
	RemoveMultiTargetFilter("@deadsb",					FilterDeadE);
	RemoveMultiTargetFilter("@deadsib",					FilterDeadF);
	RemoveMultiTargetFilter("@sp",						FilterPlayA);
	RemoveMultiTargetFilter("@sip",						FilterPlayB);
	RemoveMultiTargetFilter("@isb",						FilterIncapA);
	RemoveMultiTargetFilter("@isp",						FilterIncapB);
	RemoveMultiTargetFilter("@survivorbots",			FilterPlayC);
	RemoveMultiTargetFilter("@sb",						FilterPlayC);
	RemoveMultiTargetFilter("@infectedbots",			FilterPlayD);
	RemoveMultiTargetFilter("@ib",						FilterPlayD);

	RemoveMultiTargetFilter("@nick",					FilterNick);
	RemoveMultiTargetFilter("@rochelle",				FilterRochelle);
	RemoveMultiTargetFilter("@coach",					FilterCoach);
	RemoveMultiTargetFilter("@ellis",					FilterEllis);
	RemoveMultiTargetFilter("@bill",					FilterBill);
	RemoveMultiTargetFilter("@zoey",					FilterZoey);
	RemoveMultiTargetFilter("@francis",					FilterFrancis);
	RemoveMultiTargetFilter("@louis",					FilterLouis);

	RemoveMultiTargetFilter("@smokers",					FilterSmoker);
	RemoveMultiTargetFilter("@boomers",					FilterBoomer);
	RemoveMultiTargetFilter("@hunters",					FilterHunter);
	RemoveMultiTargetFilter("@spitters",				FilterSpitter);
	RemoveMultiTargetFilter("@jockeys",					FilterJockey);
	RemoveMultiTargetFilter("@chargers",				FilterCharger);

	RemoveMultiTargetFilter("@tank",					FilterTanks);
	RemoveMultiTargetFilter("@tanks",					FilterTanks);
	RemoveMultiTargetFilter("@t",						FilterTanks);
}

bool FilterSurvivor(const char[] pattern, ArrayList clients)
{
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && GetClientTeam(i) == 2 )
		{
			clients.Push(i);
		}
	}

	return true;
}

bool FilterIncapped(const char[] pattern, ArrayList clients)
{
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && GetEntProp(i, Prop_Send, "m_isIncapacitated", 1) )
		{
			clients.Push(i);
		}
	}

	return true;
}



// =========================
// Specific survivors
// =========================
void MatchSurvivor(ArrayList clients, int survivorCharacter)
{
	int type;
	bool matched;

	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && GetClientTeam(i) == 2 )
		{
			matched = false;

			if( g_bLeft4Dead2 )
			{
				static char modelname[32];
				GetClientModel(i, modelname, sizeof(modelname));

				switch( modelname[29] )
				{
					case 'b':		type = 0; // Nick
					case 'd', 'w':	type = 1; // Rochelle, Adawong
					case 'c':		type = 2; // Coach
					case 'h':		type = 3; // Ellis
					case 'v':		type = 4; // Bill
					case 'n':		type = 5; // Zoey
					case 'e':		type = 6; // Francis
					case 'a':		type = 7; // Louis
					default:		type = 0;
				}

				if( type == survivorCharacter )
					matched = true;
			} else {
				survivorCharacter -= 4;

				if( GetEntProp(i, Prop_Send, "m_survivorCharacter") == survivorCharacter )
					matched = true;
			}

			if( matched )
			{
				clients.Push(i);
			}
		}
	}
}

bool FilterNick(const char[] pattern, ArrayList clients)
{
	if( g_bLeft4Dead2 )
		MatchSurvivor(clients, 0);
	return true;
}

bool FilterRochelle(const char[] pattern, ArrayList clients)
{
	if( g_bLeft4Dead2 )
		MatchSurvivor(clients, 1);
	return true;
}

bool FilterCoach(const char[] pattern, ArrayList clients)
{
	if( g_bLeft4Dead2 )
		MatchSurvivor(clients, 2);
	return true;
}

bool FilterEllis(const char[] pattern, ArrayList clients)
{
	if( g_bLeft4Dead2 )
		MatchSurvivor(clients, 3);
	return true;
}

bool FilterBill(const char[] pattern, ArrayList clients)
{
	MatchSurvivor(clients, 4);
	return true;
}

bool FilterZoey(const char[] pattern, ArrayList clients)
{
	MatchSurvivor(clients, 5);
	return true;
}

bool FilterFrancis(const char[] pattern, ArrayList clients)
{
	MatchSurvivor(clients, 6);
	return true;
}

bool FilterLouis(const char[] pattern, ArrayList clients)
{
	MatchSurvivor(clients, 7);
	return true;
}



// =========================
// Filter all Infected
// =========================
bool FilterInfected(const char[] pattern, ArrayList clients)
{
	for( int i = 1; i <= MaxClients; i++ )
	{
		// Exclude tanks
		// if( IsClientInGame(i) && GetClientTeam(i) == 3 && !GetEntProp(i, Prop_Send, "m_isGhost") && GetEntProp(i, Prop_Send, "m_zombieClass") != g_iClassTank )

		// Include all specials
		if( IsClientInGame(i) && GetClientTeam(i) == 3 && !GetEntProp(i, Prop_Send, "m_isGhost") )
		{
			clients.Push(i);
		}
	}

	return true;
}



// =========================
// Filter - Random Clients
// =========================
void MatchRandomClient(ArrayList clients, int index)
{
	ArrayList aList = new ArrayList();

	for( int i = 1; i <= MaxClients; i++ )
	{
		switch( index )
		{
			case 1:			if( IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && GetEntProp(i, Prop_Send, "m_isIncapacitated", 1) )									aList.Push(i);	// Random Incapped Survivors
			case 2:			if( IsClientInGame(i) && GetClientTeam(i) == 2 )																											aList.Push(i);	// Random Survivors
			case 3:			if( IsClientInGame(i) && GetClientTeam(i) == 3 )																											aList.Push(i);	// Random Infected
			case 4:			if( IsClientInGame(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i) && GetEntProp(i, Prop_Send, "m_zombieClass") == g_iClassTank )							aList.Push(i);	// Random Tank
			case 5:			if( IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && IsFakeClient(i) && GetEntProp(i, Prop_Send, "m_isIncapacitated", 1) )					aList.Push(i);	// Random Incapped Survivor Bot
			case 6:			if( IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && IsFakeClient(i) )																		aList.Push(i);	// Random Survivor Bot
			case 7:			if( IsClientInGame(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i) && IsFakeClient(i) )																		aList.Push(i);	// Random Infected Bot
			case 8:			if( IsClientInGame(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i) && IsFakeClient(i) && GetEntProp(i, Prop_Send, "m_zombieClass") == g_iClassTank )		aList.Push(i);	// Random Tank Bot
		}
	}

	if( aList.Length )
	{
		SetRandomSeed(GetGameTickCount());
		clients.Push(aList.Get(GetRandomInt(0, aList.Length - 1)));
	}

	delete aList;
}

bool FilterRandomA(const char[] pattern, ArrayList clients)
{
	MatchRandomClient(clients, 1);
	return true;
}

bool FilterRandomB(const char[] pattern, ArrayList clients)
{
	MatchRandomClient(clients, 2);
	return true;
}

bool FilterRandomC(const char[] pattern, ArrayList clients)
{
	MatchRandomClient(clients, 3);
	return true;
}

bool FilterRandomD(const char[] pattern, ArrayList clients)
{
	MatchRandomClient(clients, 4);
	return true;
}

bool FilterRandomE(const char[] pattern, ArrayList clients)
{
	MatchRandomClient(clients, 5);
	return true;
}

bool FilterRandomF(const char[] pattern, ArrayList clients)
{
	MatchRandomClient(clients, 6);
	return true;
}

bool FilterRandomG(const char[] pattern, ArrayList clients)
{
	MatchRandomClient(clients, 7);
	return true;
}

bool FilterRandomH(const char[] pattern, ArrayList clients)
{
	MatchRandomClient(clients, 8);
	return true;
}



// =========================
// Various matches
// =========================
void MatchVariousClients(ArrayList clients, int index)
{
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) )
		{
			switch( index )
			{
				case 1:			if( !IsPlayerAlive(i) && GetClientTeam(i) == 2 )															clients.Push(i);	// "Dead Survivors (all, bots)"
				case 2:			if( !IsPlayerAlive(i) && GetClientTeam(i) == 3 )															clients.Push(i);	// "Dead Special Infected (all, bots)"
				case 3:			if( !IsPlayerAlive(i) && GetClientTeam(i) == 2 && !IsFakeClient(i) )										clients.Push(i);	// "Dead Survivors players (no bots)"
				case 4:			if( !IsPlayerAlive(i) && GetClientTeam(i) == 3 && !IsFakeClient(i) )										clients.Push(i);	// "Dead Special Infected players (no bots)"
				case 5:			if( !IsPlayerAlive(i) && GetClientTeam(i) == 2 && IsFakeClient(i) )											clients.Push(i);	// "Dead Survivors bots (no players)"
				case 6:			if( !IsPlayerAlive(i) && GetClientTeam(i) == 3 && IsFakeClient(i) )											clients.Push(i);	// "Dead Special Infected bots (no players)"
				case 7:			if( GetClientTeam(i) == 2 && !IsFakeClient(i) )																clients.Push(i);	// "Survivors players (no bots)"
				case 8:			if( GetClientTeam(i) == 3 && !IsFakeClient(i) )																clients.Push(i);	// "Special Infected players (no bots)"
				case 9:			if( GetClientTeam(i) == 2 && IsFakeClient(i) && GetEntProp(i, Prop_Send, "m_isIncapacitated", 1) )			clients.Push(i);	// "Incapped Survivor Only Bots"
				case 10:		if( GetClientTeam(i) == 2 && !IsFakeClient(i) && GetEntProp(i, Prop_Send, "m_isIncapacitated", 1) )			clients.Push(i);	// "Incapped Survivor Only Players"
				// Black and White players on third strike
				case 11:
				{
					if( GetClientTeam(i) == 2 && IsPlayerAlive(i) )
					{
						if( (g_bLeft4Dead2 ? GetEntProp(i, Prop_Send, "m_bIsOnThirdStrike", 1) != 0 : GetEntProp(i, Prop_Send, "m_currentReviveCount") >= g_hCvar_Revives.IntValue) )
						{
							clients.Push(i);
						}
					}
				}
				case 12:		if( GetClientTeam(i) == 2 && IsFakeClient(i) )																clients.Push(i);	// Survivor Bots
				case 13:		if( GetClientTeam(i) == 3 && IsFakeClient(i) )																clients.Push(i);	// Infected Bots
			}
		}
	}
}

bool FilterDeadA(const char[] pattern, ArrayList clients)
{
	MatchVariousClients(clients, 1);
	return true;
}

bool FilterDeadB(const char[] pattern, ArrayList clients)
{
	MatchVariousClients(clients, 2);
	return true;
}

bool FilterDeadC(const char[] pattern, ArrayList clients)
{
	MatchVariousClients(clients, 3);
	return true;
}

bool FilterDeadD(const char[] pattern, ArrayList clients)
{
	MatchVariousClients(clients, 4);
	return true;
}

bool FilterDeadE(const char[] pattern, ArrayList clients)
{
	MatchVariousClients(clients, 5);
	return true;
}

bool FilterDeadF(const char[] pattern, ArrayList clients)
{
	MatchVariousClients(clients, 6);
	return true;
}

bool FilterDeadG(const char[] pattern, ArrayList clients)
{
	MatchVariousClients(clients, 11);
	return true;
}

bool FilterPlayA(const char[] pattern, ArrayList clients)
{
	MatchVariousClients(clients, 7);
	return true;
}

bool FilterPlayB(const char[] pattern, ArrayList clients)
{
	MatchVariousClients(clients, 8);
	return true;
}

bool FilterPlayC(const char[] pattern, ArrayList clients)
{
	MatchVariousClients(clients, 12);
	return true;
}

bool FilterPlayD(const char[] pattern, ArrayList clients)
{
	MatchVariousClients(clients, 13);
	return true;
}

bool FilterIncapA(const char[] pattern, ArrayList clients)
{
	MatchVariousClients(clients, 9);
	return true;
}

bool FilterIncapB(const char[] pattern, ArrayList clients)
{
	MatchVariousClients(clients, 10);
	return true;
}



// =========================
// Specific Infected
// =========================
void MatchZombie(ArrayList clients, int zombieClass)
{
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && GetClientTeam(i) == 3 && GetEntProp(i, Prop_Send, "m_zombieClass") == zombieClass )
		{
			clients.Push(i);
		}
	}
}

bool FilterSmoker(const char[] pattern, ArrayList clients)
{
	MatchZombie(clients, 1);
	return true;
}

bool FilterBoomer(const char[] pattern, ArrayList clients)
{
	MatchZombie(clients, 2);
	return true;
}

bool FilterHunter(const char[] pattern, ArrayList clients)
{
	MatchZombie(clients, 3);
	return true;
}

bool FilterSpitter(const char[] pattern, ArrayList clients)
{
	MatchZombie(clients, 4);
	return true;
}

bool FilterJockey(const char[] pattern, ArrayList clients)
{
	MatchZombie(clients, 5);
	return true;
}

bool FilterCharger(const char[] pattern, ArrayList clients)
{
	MatchZombie(clients, 6);
	return true;
}

bool FilterTanks(const char[] pattern, ArrayList clients)
{
	MatchZombie(clients, g_iClassTank);
	return true;
}