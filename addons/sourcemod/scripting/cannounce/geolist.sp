

SetupGeoList()
{
	RegAdminCmd("sm_geolist", Command_GeoList, ADMFLAG_GENERIC, "sm_geolist <name or #userid> - prints geopraphical information about target(s)");
}


public Action:Command_GeoList(client, args)
{
	decl String:target[65];
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS];
	decl target_count;
	decl bool:tn_is_ml;
	decl String:name[32];
	
	decl String:ip[16];
	decl String:city[45];
	decl String:region[45];
	decl String:country[45];
	decl String:ccode[3];
	decl String:ccode3[4];
	new bool:bIsLanIp;

	//not enough arguments, display usage
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_geolist <name, #userid or @targets>");
		return Plugin_Handled;
	}	

	//get command arguments
	GetCmdArg(1, target, sizeof(target));


	//get the target of this command, return error if invalid
	if ((target_count = ProcessTargetString(
			target,
			client,
			target_list,
			MAXPLAYERS,
			0,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
				
	for (new i = 0; i < target_count; i++)
	{
		GetClientIP(target_list[i], ip, sizeof(ip)); 
		GetClientName(target_list[i], name, 32);	
		
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
		
		ReplyToCommand( client, "%s from %s in %s/%s", name, city, region, country );
	}			
	
	return Plugin_Handled;
}