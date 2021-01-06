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
#include <sdktools>
#include <left4dhooks>

new const L4D2_SI_Victim_Slots[] = {
    -1,
    13280,    // Smoker
    -1,
    16004,    // Hunter
    -1,
    16124,    // Jockey
    15972,    // Charger
    -1,
    -1,
    -1
};

new Handle:bot_kick_delay;

public Plugin:myinfo = 
{
    name = "L4D2 No Second Chances",
    author = "Visor + Jacob",
    description = "Previously human-controlled SI bots with a cap won't die",
    version = "1.1",
    url = "https://github.com/Attano/Equilibrium"
};

public OnPluginStart()
{
    HookEvent("player_bot_replace", PlayerBotReplace);
    bot_kick_delay = CreateConVar("bot_kick_delay", "0", "How long should we wait before kicking infected bots?", FCVAR_NONE, true, 0.0, true, 30.0);
}

public PlayerBotReplace(Handle:event, const String:name[], bool:dontBroadcast)
{
    new bot = GetClientOfUserId(GetEventInt(event, "bot"));
    new Float:delay = GetConVarFloat(bot_kick_delay);
    if (IsClientConnected(bot) && IsClientInGame(bot) && GetClientTeam(bot) == 3 && IsFakeClient(bot))
    {
        if (delay >= 1.0)
        {
            CreateTimer(delay, KillBot, bot);
        }
        else if (ShouldBeKicked(bot))
        {
            ForcePlayerSuicide(bot);
        }
    }
}

bool:ShouldBeKicked(infected)
{
    new Address:pEntity = GetEntityAddress(infected);
    if (pEntity == Address_Null)
        return false;

    new zcOffset = L4D2_SI_Victim_Slots[GetEntProp(infected, Prop_Send, "m_zombieClass")];
    if (zcOffset == -1)
        return false;
    
    new hasTarget = LoadFromAddress(pEntity + Address:zcOffset, NumberType_Int32);
    return hasTarget > 0 ? false : true;
}

public Action:KillBot(Handle:timer, any:bot)
{
    if (IsClientConnected(bot) && IsClientInGame(bot) && GetClientTeam(bot) == 3 && IsFakeClient(bot) && ShouldBeKicked(bot))
    {
        ForcePlayerSuicide(bot);
    }
}