/*****************************************************************


			G L O B A L   V A R S


*****************************************************************/
ConVar g_CvarShowConnectionMsg = null;
ConVar g_CvarShowDisonnectionMsg = null;


/*****************************************************************


			F O R W A R D   P U B L I C S


*****************************************************************/
void SetupSuppress()
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
public Action event_PlayerConnectClient(Event event, char[] name, bool dontBroadcast)
{
    if (!dontBroadcast && !g_CvarShowConnectionMsg.BoolValue)
    {
        char clientName[33],networkID[22];
        event.GetString("name", clientName, sizeof(clientName));
        event.GetString("networkid", networkID, sizeof(networkID));

        Event newEvent = CreateEvent("player_connect_client", true);
        newEvent.SetString("name", clientName);
        newEvent.SetInt("index", GetEventInt(event, "index"));
        newEvent.SetInt("userid", GetEventInt(event, "userid"));
        newEvent.SetString("networkid", networkID);

        FireEvent(newEvent, true);

        return Plugin_Handled;
    }

    return Plugin_Continue;
}

//For the older event player_connect
public Action event_PlayerConnect(Event event, char[] name, bool dontBroadcast)
{
    if (!dontBroadcast && !g_CvarShowConnectionMsg.BoolValue)
    {
        char clientName[33], networkID[22], address[32];
        event.GetString("name", clientName, sizeof(clientName));
        event.GetString("networkid", networkID, sizeof(networkID));
        event.GetString("address", address, sizeof(address));

        Event newEvent = CreateEvent("player_connect", true);
        newEvent.SetString("name", clientName);
        newEvent.SetInt("index", GetEventInt(event, "index"));
        newEvent.SetInt("userid", GetEventInt(event, "userid"));
        newEvent.SetString("networkid", networkID);
        newEvent.SetString("address", address);

        FireEvent(newEvent, true);

        return Plugin_Handled;
    }

    return Plugin_Continue;
}


public Action event_PlayerDisconnect_Suppress(Event event, char[] name, bool dontBroadcast)
{
    if (!dontBroadcast && !g_CvarShowDisonnectionMsg.BoolValue)
    {
        char clientName[33], networkID[22], reason[65];
        event.GetString("name", clientName, sizeof(clientName));
        event.GetString("networkid", networkID, sizeof(networkID));
        event.GetString("reason", reason, sizeof(reason));

        Event newEvent = CreateEvent("player_disconnect", true);
        newEvent.SetInt("userid", GetEventInt(event, "userid"));
        newEvent.SetString("reason", reason);
        newEvent.SetString("name", clientName);        
        newEvent.SetString("networkid", networkID);

        FireEvent(newEvent, true);

        return Plugin_Handled;
    }

    return Plugin_Continue;
}