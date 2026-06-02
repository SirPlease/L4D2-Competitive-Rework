#if defined _sourcecomms_included
#endinput
#endif
#define _sourcecomms_included

/**
 * @section Int definitions for punishments types.
 */
#define TYPE_MUTE           1
#define TYPE_GAG            2
#define TYPE_SILENCE        3
#define TYPE_UNMUTE         4
#define TYPE_UNGAG          5
#define TYPE_UNSILENCE      6
#define TYPE_TEMP_UNMUTE    14
#define TYPE_TEMP_UNGAG     15
#define TYPE_TEMP_UNSILENCE 16

enum bType
{
	bNot = 0,
	bSess,
	bTime,
	bPerm
}

native bool SourceComms_SetClientMute(int client, bool muteState, int muteLength = -1, bool saveToDB = false, const char[] reason = "Muted through natives");
native bool SourceComms_SetClientGag(int client, bool gagState, int gagLength = -1, bool saveToDB = false, const char[] reason = "Gagged through natives");
native bType SourceComms_GetClientMuteType(int client);
native bType SourceComms_GetClientGagType(int client);

forward void SourceComms_OnBlockAdded(int client, int target, int time, int type, char[] reason);

public SharedPlugin __pl_sourcecomms =
{
	name = "sourcecomms++",
	file = "sbpp_comms.smx",
	#if defined REQUIRE_PLUGIN
	required = 1
	#else
	required = 0
	#endif
};

public void __pl_sourcecomms_SetNTVOptional()
{
	MarkNativeAsOptional("SourceComms_SetClientMute");
	MarkNativeAsOptional("SourceComms_SetClientGag");
	MarkNativeAsOptional("SourceComms_GetClientMuteType");
	MarkNativeAsOptional("SourceComms_GetClientGagType");
}
