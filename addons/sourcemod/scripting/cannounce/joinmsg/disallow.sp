/*****************************************************************


			F O R W A R D   P U B L I C S


*****************************************************************/

SetupJoinMsg_DisAllow()
{
	RegAdminCmd("sm_joinmsgoff", Command_DisAllowJoinMsg, CHECKFLAG, "sm_joinmsgoff <name or #userid> - disallows a client from setting a custom join message");
	RegAdminCmd("sm_joinmsgoffid", Command_DisAllowJoinMsgID, CHECKFLAG, "sm_joinmsgoffid \"<steamId>\" - allows specified steamid from setting a custom join message");
}

OnAdminMenuReady_JoinMsg_DAllow(TopMenuObject:player_commands)
{
	AddToTopMenu(hTopMenu,
		"sm_joinmsgoff",
		TopMenuObject_Item,
		AdminMenu_DisAllowJoinMsg,
		player_commands,
		"sm_joinmsgoff",
		CHECKFLAG);	
}

/****************************************************************


			C A L L B A C K   F U N C T I O N S


****************************************************************/

public Action:Command_DisAllowJoinMsg(client, args)
{
	decl String:target[65];
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS];
	decl target_count;
	decl bool:tn_is_ml;
	new String:steamId[24];
	
	//not enough arguments, display usage
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_joinmsgoff <name or #userid>");
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
			COMMAND_FILTER_NO_MULTI,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	

	//remove allowed custom join in kv file	
	if( target_count > 0 && GetClientAuthId(target_list[0], AuthId_Steam2, steamId, sizeof(steamId)) )
	{
		DoDisAllowJoinMsg( steamId, target_name, client );
	}
	else
	{
		ReplyToCommand(client, "[SM] Unable to find player's steam id");
	}

	return Plugin_Handled;
}



public Action:Command_DisAllowJoinMsgID(client, args)
{
	new String:steamId[24];
	
	//not enough arguments, display usage
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_joinmsgoffid \"<steamId>\"");
		return Plugin_Handled;
	}	

	//get command arguments
	GetCmdArg(1, steamId, sizeof(steamId));

	//disallow steam id
	DoDisAllowJoinMsg(steamId, "<unknown>", client);

	return Plugin_Handled;
}


/*****************************************************************


			P L U G I N   F U N C T I O N S


*****************************************************************/

DoDisAllowJoinMsg( String:steamId[], String:target_name[], client )
{
	if( DisAllowJoinMsg( steamId ) )
	{
	LogMessage( "\"%L\" disallowed custom join message for player \"%s\" (Steam ID: %s)", client, target_name, steamId );
	ReplyToCommand(client, "[SM] Disallowed custom join message for player %s (Steam ID: %s)", target_name, steamId);
	}
	else
	{
	ReplyToCommand(client, "[SM] Player %s (Steam ID: %s) is not currently allowed a custom join message", target_name, steamId);
	}	
}


bool:DisAllowJoinMsg( String:steamId[] )
{
	if(KvJumpToKey(hKVCustomJoinMessages, steamId))
	{	
		KvDeleteThis(hKVCustomJoinMessages);

		KvRewind(hKVCustomJoinMessages);			
		KeyValuesToFile(hKVCustomJoinMessages, g_fileset);
		
		return true;
	}
	else
	{
		KvRewind(hKVCustomJoinMessages);
		
		return false;
	}
}

/*****************************************************************


			A D M I N   M E N U   F U N C T I O N S


*****************************************************************/

public AdminMenu_DisAllowJoinMsg(Handle:topmenu, 
					  TopMenuAction:action,
					  TopMenuObject:object_id,
					  param,
					  String:buffer[],
					  maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "%s", "Disallow custom join message");
	}
	else if (action == TopMenuAction_SelectOption)
	{
		DisplayDisAllowJoinMsgMenu(param);
	}
}

DisplayDisAllowJoinMsgMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_DisAllowJoinMsg);
	
	decl String:title[100];
	Format(title, sizeof(title), "%s:", "Disallow custom join message");
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	
	AddTargetsToMenu(menu, client, true, false);
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}


public MenuHandler_DisAllowJoinMsg(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[32];
		new userid, target;
		new String:steamId[24];
		new String:target_name[MAX_TARGET_LENGTH];
		
		
		GetMenuItem(menu, param2, info, sizeof(info));
		userid = StringToInt(info);

		if ((target = GetClientOfUserId(userid)) == 0)
		{
			PrintToChat(param1, "[SM] %t", "Player no longer available");
		}
		else if (!CanUserTarget(param1, target))
		{
			PrintToChat(param1, "[SM] %t", "Unable to target");
		}
		else
		{
			GetClientName(target, target_name, sizeof(target_name));
			
			//remove allowed custom join in kv file	
			if( GetClientAuthId(target, AuthId_Steam2, steamId, sizeof(steamId)) )
			{
				DoDisAllowJoinMsg( steamId, target_name, param1 );
			}
			else
			{
				PrintToChat(param1, "[SM] Unable to find player's steam id");
			}
		}
		
		/* Re-draw the menu if they're still valid */
		if (IsClientInGame(param1) && !IsClientInKickQueue(param1))
		{
			DisplayDisAllowJoinMsgMenu(param1);
		}
	}
}