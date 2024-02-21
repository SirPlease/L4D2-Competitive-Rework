/*****************************************************************


			F O R W A R D   P U B L I C S


*****************************************************************/

SetupJoinSound_Set()
{
	RegAdminCmd("sm_setjoinsnd", Command_SetJoinSnd, CHECKFLAG, "sm_setjoinsnd <name or #userid> \"<path to sound file>\" - sets a custom join sound for specified player");
	RegAdminCmd("sm_setjoinsndid", Command_SetJoinSndID, CHECKFLAG, "sm_setjoinsndid \"<steamId>\" \"<path to sound file>\" - sets a custom join sound for specified steam ID");
	RegAdminCmd("sm_playsnd", Command_PlaySnd, CHECKFLAG, "sm_playsnd \"<path to sound file>\" [entity] - Plays sound file on all clients, entity is optional - default 'from player'");
}

/****************************************************************


			C A L L B A C K   F U N C T I O N S


****************************************************************/

public Action:Command_SetJoinSnd(client, args)
{
	decl String:target[65];
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS];
	decl target_count;
	decl bool:tn_is_ml;
	new String:steamId[24];
	new String:sndFile[SOUNDFILE_PATH_LEN];
	decl charsSet;
	
    //not enough arguments, display usage
	if (args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_setjoinsnd <name or #userid> \"<path to sound file>\"");
		return Plugin_Handled;
	}	

	//get command arguments
	GetCmdArg(1, target, sizeof(target));
	
	//check message length
	charsSet = GetCmdArg( 2, sndFile, sizeof(sndFile) );
	
	if( charsSet > SOUNDFILE_PATH_LEN)
	{
		ReplyToCommand(client, "[SM] Maximum sound file path length is %d characters", MSGLENGTH );
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
		if( SetJoinSnd( steamId, sndFile ) )
		{
			LogMessage( "\"%L\" set custom join sound for player \"%s\" (Steam ID: %s)", client, target_name, steamId );
			ReplyToCommand(client, "[SM] Auto join sound set for player %s", target_name);
		}
		else
		{
			ReplyToCommand(client, "[SM] Player %s is not allowed to have a custom join sound", target_name);
		}
	}
	else
	{
		ReplyToCommand(client, "[SM] Unable to find player's steam id");
	}

	return Plugin_Handled;
}


public Action:Command_SetJoinSndID(client, args)
{
	decl String:steamId[24];
	new String:sndFile[SOUNDFILE_PATH_LEN];
	decl charsSet;
	
    //not enough arguments, display usage
	if (args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_setjoinsndid \"<steamId>\" \"<path to sound file>\"");
		return Plugin_Handled;
	}
	
	//get command arguments
	GetCmdArg(1, steamId, sizeof(steamId));
	
	//check message length
	charsSet = GetCmdArg( 2, sndFile, sizeof(sndFile) );
	
	if( charsSet > SOUNDFILE_PATH_LEN)
	{
		ReplyToCommand(client, "[SM] Maximum sound file path length is %d characters", MSGLENGTH );
		return Plugin_Handled;
	}
	
	//set custom join msg in kv file	
	if( SetJoinSnd( steamId, sndFile ) )
	{
		LogMessage( "\"%L\" set custom join sound for steam id: \"%s\"", client, steamId );
		ReplyToCommand(client, "[SM] Auto join sound set for steam ID \"%s\"", steamId);
	}
	else
	{
		ReplyToCommand(client, "[SM] Steam ID \"%s\" is not allowed to have a custom join sound", steamId);
	}
	
	return Plugin_Handled;
}


public Action:Command_PlaySnd(client, args)
{
	decl String:sFile[256];
	new entity = SOUND_FROM_PLAYER;
	decl String:arg2[20];
	
	//not enough arguments, display usage
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_playsnd \"<path to sound file>\" [entity]");
		return Plugin_Handled;
	}
	
	//get entity param, if supplied
	if (args > 1)
	{		
		GetCmdArg(2, arg2, sizeof(arg2));
		
		if (StringToIntEx(arg2, entity) == 0)
		{
			ReplyToCommand(client, "[SM] Invalid entity");
			return Plugin_Handled;
		}
	}

	//get command arguments
	GetCmdArg(1, sFile, sizeof(sFile));

	PrecacheSound(sFile);

	//play sound
	EmitSoundToAll( sFile, entity);
	
	ReplyToCommand(client, "[SM] Played Sound \"%s\"", sFile);
	
	return Plugin_Handled;
}


/*****************************************************************


			P L U G I N   F U N C T I O N S


*****************************************************************/
bool:SetJoinSnd( String:steamId[], String:sndFile[] )
{
	if(KvJumpToKey(hKVCustomJoinMessages, steamId))
	{
		KvSetString(hKVCustomJoinMessages, "soundfile", sndFile );

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

LoadSoundFilesCustomPlayer()
{
	new String:sndFile[SOUNDFILE_PATH_LEN];
	new String:sndFileFullPath[SOUNDFILE_PATH_LEN + 6];
	
	KvGotoFirstSubKey(hKVCustomJoinMessages);
	
	//cycle thru soundfile values, if they exist, add to download table and precache
	do
	{
		KvGetString(hKVCustomJoinMessages,"soundfile", sndFile, sizeof(sndFile) );
		
		if( strlen( sndFile ) > 0 )
		{
			Format(sndFileFullPath, sizeof(sndFileFullPath), "sound/%s", sndFile);
			
			if( FileExists( sndFileFullPath ) )
			{
				AddFileToDownloadsTable(sndFileFullPath);
				
				PrecacheSound(sndFile);
			}
			else
			{
				LogError( "[CANNOUNCE] Sound file '%s' does not exist on server", sndFileFullPath );
			}				
		}
	}
	while (KvGotoNextKey(hKVCustomJoinMessages));
	
	KvRewind(hKVCustomJoinMessages);	
}
