#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <left4dhooks>
#include <l4d2util>

new bool:isSurvivorStaggerBlocked[8];

//Courtesy of the l4d2_getupfix plugin
new const getUpAnimations[SurvivorCharacter][5] = {    
    // 0: Coach, 1: Nick, 2: Rochelle, 3: Ellis
    //[][4] = Flying animation from being hit by a tank
    {621, 656, 660, 661, 629}, {620, 667, 671, 672, 629}, {629, 674, 678, 679, 637}, {625, 671, 675, 676, 634},
    // 4: Louis, 5: Zoey, 6: Bill, 7: Francis
    {528, 759, 763, 764, 537}, {537, 819, 823, 824, 546}, {528, 759, 763, 764, 537}, {531, 762, 766, 767, 540}
};

public Plugin:myinfo =
{
    name        = "Stagger Blocker",
    author      = "Standalone (aka Manu), Visor, Sir",
    description = "Block players from being staggered by Jockeys and Hunters for a time while getting up from a Hunter pounce & Charger pummel",
    version     = "1.3",
    url         = "https://github.com/SirPlease/L4D2-Competitive-Rework"
}

public OnPluginStart() 
{
    HookEvent("pounce_stopped", Event_PounceChargeEnd);
    HookEvent("charger_pummel_end", Event_PounceChargeEnd);
    HookEvent("charger_carry_end", Event_PounceChargeEnd);
    HookEvent("player_bot_replace", Event_PlayerBotReplace);
    HookEvent("bot_player_replace", Event_BotPlayerReplace);
    HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
    ResetStaggerBlocked();
}

public OnMapEnd()
{
    ResetStaggerBlocked();
}

//Called when a Player replaces a Bot
public Action:Event_BotPlayerReplace(Handle:event, const String:name[], bool:dontBroadcast) 
{
    new player = GetClientOfUserId(GetEventInt(event, "player"));
    new SurvivorCharacter:charIndex = IdentifySurvivor(player);
    if (charIndex == SC_NONE) return;
    
    if (isSurvivorStaggerBlocked[charIndex])
    {
        SDKHook(player, SDKHook_PostThink, OnThink);
    }
}

//Called when a Bot replaces a Player
public Action:Event_PlayerBotReplace(Handle:event, const String:name[], bool:dontBroadcast) 
{
    new bot = GetClientOfUserId(GetEventInt(event, "bot"));
    new SurvivorCharacter:charIndex = IdentifySurvivor(bot);
    if (charIndex == SC_NONE) return;
    
    if (isSurvivorStaggerBlocked[charIndex])
    {
        SDKHook(bot, SDKHook_PostThink, OnThink);
    }
}

public Action:Event_PounceChargeEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "victim"));
    new SurvivorCharacter:charIndex = IdentifySurvivor(client);
    if (charIndex == SC_NONE) return;
    
    CreateTimer(0.2, HookOnThink, client);
    isSurvivorStaggerBlocked[charIndex] = true;
}

public Action:HookOnThink(Handle:timer, any:client)
{
    if (client && IsClientInGame(client) && IsSurvivor(client))
    {
        SDKHook(client, SDKHook_PostThink, OnThink);
    }
    
}

public OnThink(client)
{
    new SurvivorCharacter:charIndex = IdentifySurvivor(client);
    if (charIndex == SC_NONE) return;
    
    new sequence = GetEntProp(client, Prop_Send, "m_nSequence");
    if (sequence != getUpAnimations[charIndex][0] && sequence != getUpAnimations[charIndex][1] && sequence != getUpAnimations[charIndex][2] && sequence != getUpAnimations[charIndex][3]&& sequence != getUpAnimations[charIndex][4])
    {
        isSurvivorStaggerBlocked[charIndex] = false;
        SDKUnhook(client, SDKHook_PostThink, OnThink);
    }
}

public Action:L4D2_OnStagger(target, source) 
{
    if (IsValidInfected(source))
    {
        new L4D2_Infected:sourceClass = GetInfectedClass(source);
        
        if (sourceClass == L4D2Infected_Hunter || sourceClass == L4D2Infected_Jockey)
        {
            new SurvivorCharacter:charIndex = IdentifySurvivor(target);
            if (charIndex == SC_NONE) return Plugin_Continue;
            
            if (isSurvivorStaggerBlocked[charIndex])
            {
                return Plugin_Handled;
            }
        }
    }

    return Plugin_Continue;
}

public Action:L4D2_OnPounceOrLeapStumble(victim, attacker)
{
	if (IsValidInfected(attacker))
	{
		new L4D2_Infected:sourceClass = GetInfectedClass(attacker);
		
		if (sourceClass == L4D2Infected_Hunter || sourceClass == L4D2Infected_Jockey)
		{
			new SurvivorCharacter:charIndex = IdentifySurvivor(victim);
			if (charIndex == SC_NONE) return Plugin_Continue;
			
			if (isSurvivorStaggerBlocked[charIndex])
			{
				return Plugin_Handled;
			}
		}
	}
	
	return Plugin_Continue;
}

public ResetStaggerBlocked()
{
    for (new i = 0; i < 8; i++)
    {
        isSurvivorStaggerBlocked[i] = false;
    }
}

stock bool IsValidInfected(int client) 
{ 
    if (client <= 0 || client > MaxClients) return false;
    if (!IsClientConnected(client) || !IsClientInGame(client)) return false; 
    return GetClientTeam(client) == 3;
} 