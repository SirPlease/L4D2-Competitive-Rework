
new Handle:g_CvarAutoAllowMsg = INVALID_HANDLE;
new Handle:g_CvarDisableClientJoinMsg = INVALID_HANDLE;

/*****************************************************************


			F O R W A R D   P U B L I C S


*****************************************************************/

SetupJoinMsg_Set()
{
	RegAdminCmd("sm_setjoinmsg", Command_SetJoinMsg, CHECKFLAG, "sm_setjoinmsg <name or #userid> \"<message>\" - sets a custom join message for specified player");
	RegAdminCmd("sm_setjoinmsgid", Command_SetJoinMsgID, CHECKFLAG, "sm_setjoinmsgid \"<steamId>\" \"<message>\" - sets a custom join message for specified steam ID");
	
	RegConsoleCmd("sm_joinmsg", Command_JoinMsg, "sm_joinmsg [message] - Sets a message to be displayed when you join the game, or returns current message");
	
	g_CvarAutoAllowMsg = CreateConVar("sm_ca_autoallowmsg", "1", "Always allow custom join messages for admins with the ADMIN_KICK flag");
	g_CvarDisableClientJoinMsg = CreateConVar("sm_ca_disableclientmsgchange", "0", "Prevent clients from being able to change their own custom join message");
}

/****************************************************************


			C A L L B A C K   F U N C T I O N S


****************************************************************/

public Action:Command_SetJoinMsg(client, args)
{
	decl String:target[65];
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS];
	decl target_count;
	decl bool:tn_is_ml;
	new String:steamId[24];
	new String:message[MSGLENGTH + 2];
	decl charsSet;
	
    //not enough arguments, display usage
	if (args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_setjoinmsg <name or #userid> \"<message>\"");
		return Plugin_Handled;
	}	

	//get command arguments
	GetCmdArg(1, target, sizeof(target));
	
	//check message length
	charsSet = GetCmdArg( 2, message, sizeof(message) );
	TrimString(message);
	
	if( charsSet > MSGLENGTH)
	{
		ReplyToCommand(client, "[SM] Maximum message length is %d characters", MSGLENGTH );
		return Plugin_Handled;
	}	

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

	//set custom join msg in kv file
	if( target_count > 0 && GetClientAuthId(target_list[0], AuthId_Steam2, steamId, sizeof(steamId)) )
	{
		CheckAutoAdd( target_list[0], target_name, steamId);
		
		if( SetJoinMsg( steamId, message ) )
		{
			LogMessage( "\"%L\" set custom join message for player \"%s\" (Steam ID: %s)", client, target_name, steamId );
			ReplyToCommand(client, "[SM] Auto join message set for player %s", target_name);
		}
		else
		{
			ReplyToCommand(client, "[SM] Player %s is not allowed to have a custom join message", target_name);
		}
	}
	else
	{
		ReplyToCommand(client, "[SM] Unable to find player's steam id");
	}

	return Plugin_Handled;
}




public Action:Command_SetJoinMsgID(client, args)
{
	decl String:steamId[24];
	new String:message[MSGLENGTH + 2];
	decl charsSet;
	
    //not enough arguments, display usage
	if (args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_setjoinmsgid \"<steamId>\" \"<message>\"");
		return Plugin_Handled;
	}
	
	//get command arguments
	GetCmdArg(1, steamId, sizeof(steamId));
	
	//check message length
	charsSet = GetCmdArg( 2, message, sizeof(message) );
	TrimString(message);
	
	if( charsSet > MSGLENGTH)
	{
		ReplyToCommand(client, "[SM] Maximum message length is %d characters", MSGLENGTH );
		return Plugin_Handled;
	}
	
	//set custom join msg in kv file	
	if( SetJoinMsg( steamId, message ) )
	{
		LogMessage( "\"%L\" set custom join message for steam id: \"%s\"", client, steamId );
		ReplyToCommand(client, "[SM] Auto join message set for steam ID \"%s\"", steamId);
	}
	else
	{
		ReplyToCommand(client, "[SM] Steam ID \"%s\" is not allowed to have a custom join message", steamId);
	}
	
	return Plugin_Handled;
}


public Action:Command_JoinMsg(client, args)
{
	new String:steamId[24];
	new String:message[MSGLENGTH + 2];
	decl charsSet;
	decl String:target_name[MAX_TARGET_LENGTH];
	
    //not enough arguments, display current join msg
	if (args < 1)
	{
		if( client && GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId)) )
		{
			//get from kv file
			KvRewind(hKVCustomJoinMessages);
			if(KvJumpToKey(hKVCustomJoinMessages, steamId) && !GetConVarInt(g_CvarDisableClientJoinMsg))
			{
				KvGetString(hKVCustomJoinMessages, "message", message, sizeof(message), "");
				ReplyToCommand(client, "[SM] Your join message is: \"%s\"", message);
			}
			else
			{
				ReplyToCommand(client, "[SM] You are not allowed to have a custom join message");	
			}
			
			KvRewind(hKVCustomJoinMessages);
		}
		else
		{
			LogMessage( "\"%L\" set their custom join message", client );
			ReplyToCommand(client, "[SM] Unable to find your steam id");
		}
		
		return Plugin_Handled;
	}
	
	//check message length
	charsSet = GetCmdArg(1, message, sizeof(message) );
	TrimString(message);
	
	if( charsSet > MSGLENGTH)
	{
		ReplyToCommand(client, "[SM] Maximum message length is %d characters", MSGLENGTH );
		return Plugin_Handled;
	}
	
	//set custom join msg in kv file	
	if( client && GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId)) )
	{
		GetClientName( client, target_name, sizeof(target_name));
		
		CheckAutoAdd( client, target_name, steamId);
		
		if( SetJoinMsg( steamId, message ) )
		{
			ReplyToCommand(client, "[SM] Your auto join message is set!");
		}
		else
		{
			ReplyToCommand(client, "[SM] You are not allowed to have a custom join message");
		}
	}
	else
	{
		ReplyToCommand(client, "[SM] Unable to find your steam id");
	}
	
	return Plugin_Handled;
}


/*****************************************************************


			P L U G I N   F U N C T I O N S


*****************************************************************/


bool:SetJoinMsg( String:steamId[], String:message[] )
{
	if(KvJumpToKey(hKVCustomJoinMessages, steamId))
	{
		KvSetString(hKVCustomJoinMessages, "message", message );

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


bool:CheckAutoAdd( target, String:playerName[], String:steamId[] )
{
	new AdminId:id = GetUserAdmin(target);
	new bool:has_kick;
	has_kick = (id == INVALID_ADMIN_ID) ? false : GetAdminFlag(id, Admin_Kick);
	
	if(GetConVarInt(g_CvarAutoAllowMsg) && has_kick)	
	{
		if( AllowJoinMsg( steamId, playerName ) )
		{
			LogMessage( "Automatically allowed custom join message for player \"%s\" (Steam ID: %s) due to sm_ca_autoallowmsg and admin kick flag present", playerName, steamId );
		}
		
		return true;
	}
	else
	{
		return false;
	}
	
}