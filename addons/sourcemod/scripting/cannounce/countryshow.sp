/*****************************************************************


			G L O B A L   V A R S


*****************************************************************/
new Handle:g_CvarShowConnect = INVALID_HANDLE;
new Handle:g_CvarShowDisconnect = INVALID_HANDLE;
new Handle:g_CvarShowEnhancedToAdmins = INVALID_HANDLE;

new Handle:hKVCountryShow = INVALID_HANDLE;

#include <chatlogex>

/*****************************************************************


			F O R W A R D   P U B L I C S


*****************************************************************/
SetupCountryShow()
{
	g_CvarShowConnect = CreateConVar("sm_ca_showenhanced", "1", "displays enhanced message when player connects");
	g_CvarShowDisconnect = CreateConVar("sm_ca_showenhanceddisc", "1", "displays enhanced message when player disconnects");
	g_CvarShowEnhancedToAdmins = CreateConVar("sm_ca_showenhancedadmins", "0", "displays a different enhanced message to admin players (ADMFLAG_GENERIC)");
	
	//prepare kv for countryshow
	hKVCountryShow = CreateKeyValues("CountryShow");
	
	if(!FileToKeyValues(hKVCountryShow, g_filesettings))
	{
		KeyValuesToFile(hKVCountryShow, g_filesettings);
	}
	
	SetupDefaultMessages();
}

OnPostAdminCheck_CountryShow(client)
{
	decl String:rawmsg[301];
	decl String:rawadmmsg[301];

	//if enabled, show message
	if( GetConVarInt(g_CvarShowConnect) )
	{
		KvRewind(hKVCountryShow);
		
		//get message admins will see (if sm_ca_showenhancedadmins)
		if( KvJumpToKey(hKVCountryShow, "messages_admin", false) )
		{
			KvGetString(hKVCountryShow, "playerjoin", rawadmmsg, sizeof(rawadmmsg), "");
			Format(rawadmmsg, sizeof(rawadmmsg), "%c%s", 1, rawadmmsg);
			KvRewind(hKVCountryShow);
		}
		
		//get message all players will see
		if( KvJumpToKey(hKVCountryShow, "messages", false) )
		{
			KvGetString(hKVCountryShow, "playerjoin", rawmsg, sizeof(rawmsg), "");
			Format(rawmsg, sizeof(rawmsg), "%c%s", 1, rawmsg);
			KvRewind(hKVCountryShow);
		}
		
		//if sm_ca_showenhancedadmins - show diff messages to admins
		if( GetConVarInt(g_CvarShowEnhancedToAdmins) )
		{
			PrintFormattedMessageToAdmins( rawadmmsg, client );
			PrintFormattedMsgToNonAdmins( rawmsg, client );
		}
		else
		{
			PrintFormattedMessageToAll( rawmsg, client );
		}
		char msgl[128];
		Format(msgl, 128, "%N 进入游戏", client)
	}	
}

OnPluginEnd_CountryShow()
{		
	CloseHandle(hKVCountryShow);
}


/****************************************************************


			C A L L B A C K   F U N C T I O N S


****************************************************************/
public Action:event_PlayerDisc_CountryShow(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:rawmsg[301];
	decl String:rawadmmsg[301];
	decl String:reason[65];
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	//if enabled, show message
	if( GetConVarInt(g_CvarShowDisconnect) )
	{
		GetEventString(event, "reason", reason, sizeof(reason));

		KvRewind(hKVCountryShow);
		
		//get message admins will see (if sm_ca_showenhancedadmins)
		if( KvJumpToKey(hKVCountryShow, "messages_admin", false) )
		{
			KvGetString(hKVCountryShow, "playerdisc", rawadmmsg, sizeof(rawadmmsg), "");
			Format(rawadmmsg, sizeof(rawadmmsg), "%c%s", 1, rawadmmsg);
			KvRewind(hKVCountryShow);
			
			//first replace disconnect reason if applicable
			if (StrContains(rawadmmsg, "{DISC_REASON}") != -1 ) 
			{
				ReplaceString(rawadmmsg, sizeof(rawadmmsg), "{DISC_REASON}", reason);
				
				//strip carriage returns, replace with space
				ReplaceString(rawadmmsg, sizeof(rawadmmsg), "\n", " ");
				
			}
		}
		
		//get message all players will see
		if( KvJumpToKey(hKVCountryShow, "messages", false) )
		{
			KvGetString(hKVCountryShow, "playerdisc", rawmsg, sizeof(rawmsg), "");
			Format(rawmsg, sizeof(rawmsg), "%c%s", 1, rawmsg);
			KvRewind(hKVCountryShow);
			
			//first replace disconnect reason if applicable
			if (StrContains(rawmsg, "{DISC_REASON}") != -1 ) 
			{
				ReplaceString(rawmsg, sizeof(rawmsg), "{DISC_REASON}", reason);
				
				//strip carriage returns, replace with space
				ReplaceString(rawmsg, sizeof(rawmsg), "\n", " ");
			}
		}
		char msgl[128];
		Format(msgl, 128, "%N 离开游戏 (%s)", client, reason)
		//if sm_ca_showenhancedadmins - show diff messages to admins
		if( GetConVarInt(g_CvarShowEnhancedToAdmins) )
		{
			PrintFormattedMessageToAdmins( rawadmmsg, client );
			PrintFormattedMsgToNonAdmins( rawmsg, client );
		}
		else
		{
			PrintFormattedMessageToAll( rawmsg, client );
		}
		
		KvRewind(hKVCountryShow);
	}
}

/*****************************************************************


			P L U G I N   F U N C T I O N S


*****************************************************************/
SetupDefaultMessages()
{
	if(!KvJumpToKey(hKVCountryShow, "messages"))
	{				
		KvJumpToKey(hKVCountryShow, "messages", true);
		KvSetString(hKVCountryShow, "playerjoin", "{PLAYERTYPE} {GREEN}{PLAYERNAME} {DEFAULT}<{LIGHTGREEN}{STEAMID}{DEFAULT}> connected from country {GREEN}{PLAYERCOUNTRY} {DEFAULT}({LIGHTGREEN}{PLAYERCOUNTRYSHORT}{DEFAULT}), IP {GREEN}{PLAYERIP}");
		KvSetString(hKVCountryShow, "playerdisc", "{PLAYERTYPE} {GREEN}{PLAYERNAME} {DEFAULT}<{LIGHTGREEN}{STEAMID}{DEFAULT}> from country {GREEN}{PLAYERCOUNTRY} {DEFAULT}({LIGHTGREEN}{PLAYERCOUNTRYSHORT}{DEFAULT}) disconnected from IP {GREEN}{PLAYERIP}{GREEN}reason: {DEFAULT}{DISC_REASON}");

		KvRewind(hKVCountryShow);			
		KeyValuesToFile(hKVCountryShow, g_filesettings);		
	}
	
	KvRewind(hKVCountryShow);
	
	if(!KvJumpToKey(hKVCountryShow, "messages_admin"))
	{				
		KvJumpToKey(hKVCountryShow, "messages_admin", true);
		KvSetString(hKVCountryShow, "playerjoin", "{PLAYERTYPE} {GREEN}{PLAYERNAME} {DEFAULT}<{LIGHTGREEN}{STEAMID}{DEFAULT}> connected from country {GREEN}{PLAYERCOUNTRY} {DEFAULT}({LIGHTGREEN}{PLAYERCOUNTRYSHORT}{DEFAULT}), IP {GREEN}{PLAYERIP}");
		KvSetString(hKVCountryShow, "playerdisc", "{PLAYERTYPE} {GREEN}{PLAYERNAME} {DEFAULT}<{LIGHTGREEN}{STEAMID}{DEFAULT}> from country {GREEN}{PLAYERCOUNTRY} {DEFAULT}({LIGHTGREEN}{PLAYERCOUNTRYSHORT}{DEFAULT}) disconnected from IP {GREEN}{PLAYERIP}{GREEN}reason: {DEFAULT}{DISC_REASON}");

		KvRewind(hKVCountryShow);			
		KeyValuesToFile(hKVCountryShow, g_filesettings);		
	}

	KvRewind(hKVCountryShow);
}