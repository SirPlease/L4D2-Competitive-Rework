#define PLUGIN_VERSION 		"1.1"

/*=======================================================================================
	Plugin Info:

*	Name	:	[L4D2] Versus Rematch Vote Block
*	Author	:	SilverShot
*	Descrp	:	Blocks the Versus rematch voting panel when the entire game has finished.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=321275
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.1 (10-May-2020)
	- Various changes to tidy up code.

1.0 (02-Feb-2020)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D2] Versus Rematch Vote Block",
	author = "SilverShot",
	description = "Blocks the Versus rematch voting panel when the entire game has finished.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=321275"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if( GetEngineVersion() != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("l4d_vs_rematch_version", PLUGIN_VERSION,	"Versus Rematch Vote Block plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);

	// Force these?
	// SetConVarInt(FindConVar("sv_pz_endgame_vote_period"), 1);
	// SetConVarInt(FindConVar("sv_pz_endgame_vote_post_period"), 1);

	HookMsgs();
}



// ====================================================================================================
//					EVENTS
// ====================================================================================================
void HookMsgs()
{
	char msgname[64];
	int i = 1;
	while( i )
	{
		if( GetUserMessageName(view_as<UserMsg>(i), msgname, sizeof msgname) )
		{
			if( strcmp(msgname, "PZEndGamePanelMsg") == 0 )
			{
				HookUserMessage(view_as<UserMsg>(i), OnMessage, true);
				break;
			}

			i++;
		} else {
			i = 0;
		}
	}
}

public Action OnMessage(UserMsg msg_id, BfRead hMsg, const int[] players, int playersNum, bool reliable, bool init)
{
	return Plugin_Handled;
}