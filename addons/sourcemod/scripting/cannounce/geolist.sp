

void SetupGeoList()
{
	RegAdminCmd("sm_geolist", Command_GeoList, ADMFLAG_GENERIC, "sm_geolist <name or #userid> - prints geopraphical information about target(s)");
}


public Action Command_GeoList(int client, int args)
{
	char target[65];
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS];
	int target_count;
	bool tn_is_ml;
	char name[32];
	
	char ip[16];
	char city[45];
	char region[45];
	char country[45];
	char ccode[3];
	char ccode3[4];
	bool bIsLanIp;

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
		
		if(!GeoipCity(ip, city, sizeof(city)))
		{
			if( bIsLanIp )
			{
				Format( city, sizeof(city), "%T", "LAN City Desc", LANG_SERVER );
			}
			else
			{
				Format( city, sizeof(city), "%T", "Unknown City Desc", LANG_SERVER );
			}
		}

		if(!GeoipRegion(ip, region, sizeof(region)))
		{
			if( bIsLanIp )
			{
				Format( region, sizeof(region), "%T", "LAN Region Desc", LANG_SERVER );
			}
			else
			{
				Format( region, sizeof(region), "%T", "Unknown Region Desc", LANG_SERVER );
			}
		}

		if(!GeoipCode3(ip, ccode3))
		{
			if( bIsLanIp )
			{
				Format( ccode3, sizeof(ccode3), "%T", "LAN Country Short 3", LANG_SERVER );
			}
			else
			{
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