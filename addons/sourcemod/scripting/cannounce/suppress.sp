/*****************************************************************


			G L O B A L   V A R S


*****************************************************************/
new Handle:g_CvarShowConnectionMsg = INVALID_HANDLE;
new Handle:g_CvarShowDisonnectionMsg = INVALID_HANDLE;

#include "chatlogex"

/*****************************************************************


			F O R W A R D   P U B L I C S


*****************************************************************/
SetupSuppress()
{
	g_CvarShowConnectionMsg = CreateConVar("sm_ca_showstandard", "0", "shows standard player connected message");
	g_CvarShowDisonnectionMsg = CreateConVar("sm_ca_showstandarddisc", "0", "shows standard player discconnected message");
	
	//player_connect_client replaced player_connect but the old event is still required for some older games. 
	//lets try the new event first then fallback if it dont worky
	if( HookEventEx("player_connect_client", event_PlayerConnectClient, EventHookMode_Pre) == false )
	{
		HookEventEx("player_connect", event_PlayerConnect, EventHookMode_Pre);
	}
}


/****************************************************************


			C A L L B A C K   F U N C T I O N S


****************************************************************/
//For the newer event player_connect_client
public Action:event_PlayerConnectClient(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (!dontBroadcast && !GetConVarInt(g_CvarShowConnectionMsg))
    {
        decl String:clientName[33], String:networkID[22];
        GetEventString(event, "name", clientName, sizeof(clientName));
        GetEventString(event, "networkid", networkID, sizeof(networkID));

        new Handle:newEvent = CreateEvent("player_connect_client", true);
        SetEventString(newEvent, "name", clientName);
        SetEventInt(newEvent, "index", GetEventInt(event, "index"));
        SetEventInt(newEvent, "userid", GetEventInt(event, "userid"));
        SetEventString(newEvent, "networkid", networkID);

        FireEvent(newEvent, true);

        return Plugin_Handled;
    }

    return Plugin_Continue;
}

//For the older event player_connect
public Action:event_PlayerConnect(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (!dontBroadcast && !GetConVarInt(g_CvarShowConnectionMsg))
    {
        decl String:clientName[33], String:networkID[22], String:address[32];
        GetEventString(event, "name", clientName, sizeof(clientName));
        GetEventString(event, "networkid", networkID, sizeof(networkID));
        GetEventString(event, "address", address, sizeof(address));

        new Handle:newEvent = CreateEvent("player_connect", true);
        SetEventString(newEvent, "name", clientName);
        SetEventInt(newEvent, "index", GetEventInt(event, "index"));
        SetEventInt(newEvent, "userid", GetEventInt(event, "userid"));
        SetEventString(newEvent, "networkid", networkID);
        SetEventString(newEvent, "address", address);

        FireEvent(newEvent, true);

        return Plugin_Handled;
    }

    return Plugin_Continue;
}


public Action:event_PlayerDisconnect_Suppress(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (!dontBroadcast && !GetConVarInt(g_CvarShowDisonnectionMsg))
    {
        decl String:clientName[33], String:networkID[22], String:reason[65];
        GetEventString(event, "name", clientName, sizeof(clientName));
        GetEventString(event, "networkid", networkID, sizeof(networkID));
        GetEventString(event, "reason", reason, sizeof(reason));

        new Handle:newEvent = CreateEvent("player_disconnect", true);
        SetEventInt(newEvent, "userid", GetEventInt(event, "userid"));
        SetEventString(newEvent, "reason", reason);
        SetEventString(newEvent, "name", clientName);        
        SetEventString(newEvent, "networkid", networkID);

        FireEvent(newEvent, true);

        return Plugin_Handled;
    }

    return Plugin_Continue;
}