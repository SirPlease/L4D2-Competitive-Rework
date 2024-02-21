/*****************************************************************


			F O R W A R D   P U B L I C S


*****************************************************************/

SetupJoinMsg_Allow()
{
	RegAdminCmd("sm_joinmsgon", Command_AllowJoinMsg, CHECKFLAG, "sm_joinmsgon <name or #userid> - allows a client to set a custom join message");
	RegAdminCmd("sm_joinmsgonid", Command_AllowJoinMsgID, CHECKFLAG, "sm_joinmsgonid \"<steamId>\" \"<player name>\" - allows specified steamid to set a custom join message");
}


OnAdminMenuReady_JoinMsg_Allow(TopMenuObject:player_commands)
{
	AddToTopMenu(hTopMenu, 
		"sm_joinmsgon",
		TopMenuObject_Item,
		AdminMenu_AllowJoinMsg,
		player_commands,
		"sm_joinmsgon",
		CHECKFLAG);		
}

/****************************************************************


			C A L L B A C K   F U N C T I O N S


****************************************************************/

public Action:Command_AllowJoinMsg(client, args)
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
		ReplyToCommand(client, "[SM] Usage: sm_joinmsgon <name or #userid>");
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

	//set allowed custom join in kv file	
	if( target_count > 0 && GetClientAuthId(target_list[0], AuthId_Steam2, steamId, sizeof(steamId)) )
	{
		DoAllowJoinMsg(steamId,target_name,client);
		
		//inform player of their enabled custom join msg
		PrintToChat(target_list[0], "[SM] type sm_joinmsg in console to set your custom join message!");
	}
	else
	{
		ReplyToCommand(client, "[SM] Unable to find player's steam id");
	}

	return Plugin_Handled;
}



public Action:Command_AllowJoinMsgID(client, args)
{
	decl String:player_name[MAX_TARGET_LENGTH];
	new String:steamId[24];
	
	//not enough arguments, display usage
	if (args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_joinmsgonid \"<steamId>\" \"<player name>\"");
		return Plugin_Handled;
	}	

	//get command arguments
	GetCmdArg(1, steamId, sizeof(steamId));
	GetCmdArg(2, player_name, sizeof(player_name));

	//allow steam id
	DoAllowJoinMsg(steamId,player_name,client);

	return Plugin_Handled;
}


/*****************************************************************


			P L U G I N   F U N C T I O N S


*****************************************************************/

DoAllowJoinMsg( String:steamId[], String:target_name[], client )
{
	if( AllowJoinMsg(steamId,target_name) )
	{
		LogMessage( "\"%L\" allowed custom join message for player \"%s\" (Steam ID: %s)", client, target_name, steamId );
		ReplyToCommand(client, "[SM] Allowed custom join message for player %s (Steam ID: %s)", target_name, steamId);
	}
	else
	{
		ReplyToCommand(client, "[SM] Player %s (Steam ID: %s) is already allowed custom join message", target_name, steamId);
	}
}


bool:AllowJoinMsg( String:steamId[], String:player_name[] )
{
	if(!KvJumpToKey(hKVCustomJoinMessages, steamId))
	{				
		KvJumpToKey(hKVCustomJoinMessages, steamId, true);
		KvSetString(hKVCustomJoinMessages, "playerwasnamed", player_name );

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

public AdminMenu_AllowJoinMsg(Handle:topmenu, 
					  TopMenuAction:action,
					  TopMenuObject:object_id,
					  param,
					  String:buffer[],
					  maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "%s", "Allow custom join message");
	}
	else if (action == TopMenuAction_SelectOption)
	{
		DisplayAllowJoinMsgMenu(param);
	}
}

DisplayAllowJoinMsgMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_AllowJoinMsg);
	
	decl String:title[100];
	Format(title, sizeof(title), "%s:", "Allow custom join message");
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	
	AddTargetsToMenu(menu, client, true, false);
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}


public MenuHandler_AllowJoinMsg(Handle:menu, MenuAction:action, param1, param2)
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
			
			//set allowed custom join in kv file	
			if( GetClientAuthId(target, AuthId_Steam2, steamId, sizeof(steamId)) )
			{
				DoAllowJoinMsg(steamId,target_name,param1);
				
				//inform player of their enabled custom join msg
				PrintToChat(target, "[SM] type sm_joinmsg in console to set your custom join message!");
			}
			else
			{
				PrintToChat(param1, "[SM] Unable to find player's steam id");
			}
		}
		
		/* Re-draw the menu if they're still valid */
		if (IsClientInGame(param1) && !IsClientInKickQueue(param1))
		{
			DisplayAllowJoinMsgMenu(param1);
		}
	}
}