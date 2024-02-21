/**
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 */


#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <geoip>
#undef REQUIRE_EXTENSIONS
#include <geoipcity>
#undef REQUIRE_PLUGIN
#include <adminmenu>
#include <multicolors>

#define VERSION "1.8"

/*****************************************************************


			G L O B A L   V A R S


*****************************************************************/
new Handle:hTopMenu = INVALID_HANDLE;
new String:g_fileset[128];
new String:g_filesettings[128];
new bool:g_UseGeoIPCity = false;

new Handle:g_CvarConnectDisplayType = INVALID_HANDLE;
/*****************************************************************


			L I B R A R Y   I N C L U D E S


*****************************************************************/
#include "cannounce/countryshow.sp"
#include "cannounce/joinmsg.sp"
#include "cannounce/geolist.sp"
#include "cannounce/suppress.sp"


/*****************************************************************


			P L U G I N   I N F O


*****************************************************************/
public Plugin:myinfo =
{
	name = "Connect Announce",
	author = "Arg!",
	description = "Replacement of default player connection message, allows for custom connection messages",
	version = VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=77306"
};



/*****************************************************************


			F O R W A R D   P U B L I C S


*****************************************************************/
public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("cannounce.phrases");
	
	CreateConVar("sm_cannounce_version", VERSION, "Connect announce replacement", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_CvarConnectDisplayType = CreateConVar("sm_ca_connectdisplaytype", "1", "[1|0] if 1 then displays connect message after admin check and allows the {PLAYERTYPE} placeholder. If 0 displays connect message on client auth (earlier) and disables the {PLAYERTYPE} placeholder");
	
	BuildPath(Path_SM, g_fileset, 128, "data/cannounce_messages.txt");
	BuildPath(Path_SM, g_filesettings, 128, "data/cannounce_settings.txt");
	
	//event hooks
	HookEvent("player_disconnect", event_PlayerDisconnect, EventHookMode_Pre);
	
	
	//country show
	SetupCountryShow();
	
	//custom join msg
	SetupJoinMsg();
	
	//geographical player list
	SetupGeoList();
	
	//suppress standard connection message
	SetupSuppress();
	
	//Account for late loading
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}
	
	// Check if we have GeoIPCity.ext loaded
	g_UseGeoIPCity = LibraryExists("GeoIPCity");
	
	//create config file if not exists
	AutoExecConfig(true, "cannounce");
}

public OnMapStart()
{
	//get, precache and set downloads for player custom sound files
	LoadSoundFilesCustomPlayer();
		
	//precahce and set downloads for sounds files for all players
	LoadSoundFilesAll();
	
	
	OnMapStart_JoinMsg();
}

public OnClientAuthorized(client, const String:auth[])
{
	if( GetConVarInt(g_CvarConnectDisplayType) == 0 )
	{
		if( !IsFakeClient(client) && GetClientCount(true) < MaxClients )
		{
			OnPostAdminCheck_CountryShow(client);
		
			OnPostAdminCheck_JoinMsg(auth);
		}
	}
}

public OnClientPostAdminCheck(client)
{
	decl String:auth[32];
	
	if( GetConVarInt(g_CvarConnectDisplayType) == 1 )
	{
		GetClientAuthId( client, AuthId_Steam2, auth, sizeof(auth) );
		
		if( !IsFakeClient(client) && GetClientCount(true) < MaxClients )
		{
			OnPostAdminCheck_CountryShow(client);
		
			OnPostAdminCheck_JoinMsg(auth);
		}
	}	
}

public OnPluginEnd()
{		
	OnPluginEnd_JoinMsg();
	
	OnPluginEnd_CountryShow();
}


public OnAdminMenuReady(Handle:topmenu)
{
	//Block us from being called twice
	if (topmenu == hTopMenu)
	{
		return;
	}
	
	//Save the Handle
	hTopMenu = topmenu;
	
	
	OnAdminMenuReady_JoinMsg();	
}


public OnLibraryRemoved(const String:name[])
{
	//remove this menu handle if adminmenu plugin unloaded
	if (strcmp(name, "adminmenu") == 0)
	{
		hTopMenu = INVALID_HANDLE;
	}
	
	// Was the GeoIPCity extension removed?
	if(StrEqual(name, "GeoIPCity"))
		g_UseGeoIPCity = false;
}


public OnLibraryAdded(const String:name[])
{
	// Is the GeoIPCity extension running?
	if(StrEqual(name, "GeoIPCity"))
		g_UseGeoIPCity = true;
}


/****************************************************************


			C A L L B A C K   F U N C T I O N S


****************************************************************/
public Action:event_PlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if( client && !IsFakeClient(client) && !dontBroadcast )
	{
		event_PlayerDisc_CountryShow(event, name, dontBroadcast);
		
		OnClientDisconnect_JoinMsg();
	}
	
	
	return event_PlayerDisconnect_Suppress( event, name, dontBroadcast );
}


/*****************************************************************


			P L U G I N   F U N C T I O N S


*****************************************************************/
//Thanks to Darkthrone (https://forums.alliedmods.net/member.php?u=54636)
bool:IsLanIP( String:src[16] )
{
	decl String:ip4[4][4];
	new ipnum;

	if(ExplodeString(src, ".", ip4, 4, 4) == 4)
	{
		ipnum = StringToInt(ip4[0])*65536 + StringToInt(ip4[1])*256 + StringToInt(ip4[2]);
		
		if((ipnum >= 655360 && ipnum < 655360+65535) || (ipnum >= 11276288 && ipnum < 11276288+4095) || (ipnum >= 12625920 && ipnum < 12625920+255))
		{
			return true;
		}
	}

	return false;
}

PrintFormattedMessageToAll( String:rawmsg[301], client )
{
	decl String:message[301];
	
	GetFormattedMessage( rawmsg, client, message, sizeof(message) );
	
	CPrintToChatAll( "%s", message );
}

PrintFormattedMessageToAdmins( String:rawmsg[301], client )
{
	decl String:message[301];
	
	GetFormattedMessage( rawmsg, client, message, sizeof(message) );
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if( IsClientInGame(i) && CheckCommandAccess( i, "", ADMFLAG_GENERIC, true ) )
		{
			CPrintToChat(i, "%s", message);
		}
	}
}

PrintFormattedMsgToNonAdmins( String:rawmsg[301], client )
{
	decl String:message[301];
	
	GetFormattedMessage( rawmsg, client, message, sizeof(message) );
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if( IsClientInGame(i) && !CheckCommandAccess( i, "", ADMFLAG_GENERIC, true ) )
		{
			CPrintToChat(i, "%s", message);
		}
	}
}

//GetFormattedMessage - based on code from the DJ Tsunami plugin Advertisements - http://forums.alliedmods.net/showthread.php?p=592536
GetFormattedMessage( String:rawmsg[301], client, String:outbuffer[], outbuffersize )
{
	decl String:buffer[256];
	decl String:ip[16];
	decl String:city[45];
	decl String:region[45];
	decl String:country[45];
	decl String:ccode[3];
	decl String:ccode3[4];
	decl String:sPlayerAdmin[32];
	decl String:sPlayerPublic[32];
	new bool:bIsLanIp;
	
	decl AdminId:aid;
	
	if( client > -1 )
	{
		GetClientIP(client, ip, sizeof(ip)); 
		
		//detect LAN ip
		bIsLanIp = IsLanIP( ip );
		
		// Using GeoIPCity extension...
		if ( g_UseGeoIPCity )
		{
			if( !GeoipGetRecord( ip, city, region, country, ccode, ccode3 ) )
			{
				if( bIsLanIp )
				{
					Format( city, sizeof(city), "%T", "LAN City Desc", LANG_SERVER );
					Format( region, sizeof(region), "%T", "LAN Region Desc", LANG_SERVER );
					Format( country, sizeof(country), "%T", "LAN Country Desc", LANG_SERVER );
					Format( ccode, sizeof(ccode), "%T", "LAN Country Short", LANG_SERVER );
					Format( ccode3, sizeof(ccode3), "%T", "LAN Country Short 3", LANG_SERVER );
				}
				else
				{
					Format( city, sizeof(city), "%T", "Unknown City Desc", LANG_SERVER );
					Format( region, sizeof(region), "%T", "Unknown Region Desc", LANG_SERVER );
					Format( country, sizeof(country), "%T", "Unknown Country Desc", LANG_SERVER );
					Format( ccode, sizeof(ccode), "%T", "Unknown Country Short", LANG_SERVER );
					Format( ccode3, sizeof(ccode3), "%T", "Unknown Country Short 3", LANG_SERVER );
				}
			}
		}
		else // Using GeoIP default extension...
		{
			if( !GeoipCode2(ip, ccode) )
			{
				if( bIsLanIp )
				{
					Format( ccode, sizeof(ccode), "%T", "LAN Country Short", LANG_SERVER );
				}
				else
				{
					Format( ccode, sizeof(ccode), "%T", "Unknown Country Short", LANG_SERVER );
				}
			}
			
			if( !GeoipCountry(ip, country, sizeof(country)) )
			{
				if( bIsLanIp )
				{
					Format( country, sizeof(country), "%T", "LAN Country Desc", LANG_SERVER );
				}
				else
				{
					Format( country, sizeof(country), "%T", "Unknown Country Desc", LANG_SERVER );
				}
			}
			
			// Since the GeoIPCity extension isn't loaded, we don't know the city or region.
			if( bIsLanIp )
			{
				Format( city, sizeof(city), "%T", "LAN City Desc", LANG_SERVER );
				Format( region, sizeof(region), "%T", "LAN Region Desc", LANG_SERVER );
				Format( ccode3, sizeof(ccode3), "%T", "LAN Country Short 3", LANG_SERVER );
			}
			else
			{
				Format( city, sizeof(city), "%T", "Unknown City Desc", LANG_SERVER );
				Format( region, sizeof(region), "%T", "Unknown Region Desc", LANG_SERVER );
				Format( ccode3, sizeof(ccode3), "%T", "Unknown Country Short 3", LANG_SERVER );
			}
		}
		
		// Fallback for unknown/empty location strings
		if( StrEqual( city, "" ) )
		{
			Format( city, sizeof(city), "%T", "Unknown City Desc", LANG_SERVER );
		}
		
		if( StrEqual( region, "" ) )
		{
			Format( region, sizeof(region), "%T", "Unknown Region Desc", LANG_SERVER );
		}
		
		if( StrEqual( country, "" ) )
		{
			Format( country, sizeof(country), "%T", "Unknown Country Desc", LANG_SERVER );
		}
		
		if( StrEqual( ccode, "" ) )
		{
			Format( ccode, sizeof(ccode), "%T", "Unknown Country Short", LANG_SERVER );
		}
		
		if( StrEqual( ccode3, "" ) )
		{
			Format( ccode3, sizeof(ccode3), "%T", "Unknown Country Short 3", LANG_SERVER );
		}
		
		// Add "The" in front of certain countries
		if( StrContains( country, "United", false ) != -1 || 
			StrContains( country, "Republic", false ) != -1 || 
			StrContains( country, "Federation", false ) != -1 || 
			StrContains( country, "Island", false ) != -1 || 
			StrContains( country, "Netherlands", false ) != -1 || 
			StrContains( country, "Isle", false ) != -1 || 
			StrContains( country, "Bahamas", false ) != -1 || 
			StrContains( country, "Maldives", false ) != -1 || 
			StrContains( country, "Philippines", false ) != -1 || 
			StrContains( country, "Vatican", false ) != -1 )
		{
			Format( country, sizeof(country), "The %s", country );
		}
		
		if (StrContains(rawmsg, "{PLAYERNAME}") != -1) 
		{
			GetClientName(client, buffer, sizeof(buffer));
			ReplaceString(rawmsg, sizeof(rawmsg), "{PLAYERNAME}", buffer);
		}

		if (StrContains(rawmsg, "{STEAMID}") != -1) 
		{
			GetClientAuthId(client, AuthId_Steam2, buffer, sizeof(buffer));
			ReplaceString(rawmsg, sizeof(rawmsg), "{STEAMID}", buffer);
		}
		
		if (StrContains(rawmsg, "{PLAYERCOUNTRY}") != -1 ) 
		{
			ReplaceString(rawmsg, sizeof(rawmsg), "{PLAYERCOUNTRY}", country);
		}
		
		if (StrContains(rawmsg, "{PLAYERCOUNTRYSHORT}") != -1 ) 
		{
			ReplaceString(rawmsg, sizeof(rawmsg), "{PLAYERCOUNTRYSHORT}", ccode);
		}
		
		if (StrContains(rawmsg, "{PLAYERCOUNTRYSHORT3}") != -1 ) 
		{
			ReplaceString(rawmsg, sizeof(rawmsg), "{PLAYERCOUNTRYSHORT3}", ccode3);
		}
		
		if (StrContains(rawmsg, "{PLAYERCITY}") != -1 ) 
		{
			ReplaceString(rawmsg, sizeof(rawmsg), "{PLAYERCITY}", city);
		}
		
		if (StrContains(rawmsg, "{PLAYERREGION}") != -1 ) 
		{
			ReplaceString(rawmsg, sizeof(rawmsg), "{PLAYERREGION}", region);
		}
		
		if (StrContains(rawmsg, "{PLAYERIP}") != -1 ) 
		{
			ReplaceString(rawmsg, sizeof(rawmsg), "{PLAYERIP}", ip);
		}
		
		if( StrContains(rawmsg, "{PLAYERTYPE}") != -1 && GetConVarInt(g_CvarConnectDisplayType) == 1  )
		{
			aid = GetUserAdmin( client );
			
			if( GetAdminFlag( aid, Admin_Generic ) )
			{
				Format( sPlayerAdmin, sizeof(sPlayerAdmin), "%T", "CA Admin", LANG_SERVER );
				ReplaceString(rawmsg, sizeof(rawmsg), "{PLAYERTYPE}", sPlayerAdmin);
			}
			else
			{
				Format( sPlayerPublic, sizeof(sPlayerPublic), "%T", "CA Public", LANG_SERVER );
				ReplaceString(rawmsg, sizeof(rawmsg), "{PLAYERTYPE}", sPlayerPublic);
			}
		}
	}
	
	Format( outbuffer, outbuffersize, "%s", rawmsg );
}