#include <sourcemod>
#include <sdkhooks>

public Plugin:myinfo = 
{
	name = "L4D2 Ghost-Cheat Preventer",
	author = "Sir",
	description = "Don't broadcast Infected entities to Survivors while in ghost mode, disabling them from hooking onto the entities with 3rd party programs.",
	version = "1.0",
	url = "Nawl."
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_SetTransmit, Hook_SetTransmit);
}

public OnPluginStart()
{
	for (new client = 1; client <= MAXPLAYERS; client++)
	{
		if (IsValidClient(client)) SDKHook(client, SDKHook_SetTransmit, Hook_SetTransmit);
	}
}

public Action:Hook_SetTransmit(client, entity)
{
	// By default Valve still transmits the entities to Survivors, even when not in sight or in ghost mode.
	// Detecting if a player is actually in someone's sight is likely impossible to implement without issues, but blocking ghosts from being transmitted has no downsides.
	// This code will prevent 3rd party programs from hooking onto unspawned Infected.

    if (IsValidClient(client) && IsValidClient(entity) // Actual Clients?!
    && GetClientTeam(client) == 3 // Are we transmitting Infected Data?
    && GetClientTeam(entity) == 2 // Are we transmitting Infected Data to a Survivor?
    && GetEntProp(client, Prop_Send, "m_isGhost") == 1) // Is the Infected Player in Ghost Mode?
    {
    	return Plugin_Handled; // Block info from being transmitted to client if true.
    }
    return Plugin_Continue; // Transmit Data!
}

bool:IsValidClient(client) { 
    if (client <= 0 || client > MaxClients || !IsClientConnected(client)) return false; 
    return IsClientInGame(client); 
}