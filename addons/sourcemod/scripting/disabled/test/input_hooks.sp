/*
*	Input Hooks - DevTools
*	Copyright (C) 2022 Silvers
*
*	This program is free software: you can redistribute it and/or modify
*	it under the terms of the GNU General Public License as published by
*	the Free Software Foundation, either version 3 of the License, or
*	(at your option) any later version.
*
*	This program is distributed in the hope that it will be useful,
*	but WITHOUT ANY WARRANTY; without even the implied warranty of
*	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*	GNU General Public License for more details.
*
*	You should have received a copy of the GNU General Public License
*	along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/



#define PLUGIN_VERSION 		"1.9"

/*=======================================================================================
	Plugin Info:

*	Name	:	[ANY] Input Hooks - DevTools
*	Author	:	SilverShot
*	Descrp	:	Prints entity inputs, with classname filtering.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=319141
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.9 (15-Jun-2022)
	- Changed some white spacing sizes when printing.
	- Removed quotes when printing various information, for a cleaner look.

1.8 (29-Apr-2022)
	- Added support for various types. Thanks to "Ilusion9" for coding.

1.7 (10-Apr-2022)
	- Added support for the "Pirates, Vikings and Knights II" game. GameData updated. Thanks to "Marttt" for the offsets.
	- Fixed crash when retrieving Color255 values. Thanks to "Ilusion9" for reporting and "domino_" for helping fix.

1.6 (20-May-2021)
	- Fixed using a static list for reading values instead of strings. Thanks to "bottiger" for fixing.

1.5 (03-Mar-2021)
	- Fixed crashing on "SetTotalItems" input. Thanks to "Marttt" for reporting.

1.4a (30-Sep-2020)
	- Compatibility update for L4D2's "The Last Stand" update.
	- L4D2: GameData .txt file updated.

1.4 (10-May-2020)
	- Added better error log message when gamedata file is missing.
	- Various changes to tidy up code.

1.3 (16-Mar-2020)
	- Fixed server crashing when reading "InValue" commands.
	- Fixed not logging when server is empty.
	- Fixed logging code in the wrong place.

1.2 (05-Dec-2019)
	- Added cvar "sm_input_hooks_logging" to enable or disable logging.
	- Added entity name to info. - Thanks to "Dragokas" for coding.
	- Added ability to log info in file "logs/input_hooks.log". - Thanks to "Dragokas" for coding.

1.1 (15-Nov-2019)
	- Fixed multiple classnames not working for the watch command and cvars.

1.0 (14-Oct-2019)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <dhooks>

#define CVAR_FLAGS			FCVAR_NOTIFY
#define GAMEDATA			"input_hooks.games"
#define CONFIG_DUMP			"logs/input_hooks.log"
#define MAX_ENTS			4096
#define LEN_CLASS			64

ConVar g_hCvarFilter, g_hCvarListen, g_hCvarLogging;
ArrayList g_aFilter, g_aListen, g_aWatch;
Handle gAcceptInput;
bool g_bWatch[MAXPLAYERS+1];
int g_iHookID[MAX_ENTS], g_iInputHookID[MAX_ENTS], g_iListenInput, g_iCvarLogging;
File g_hLogFile;

enum fieldtype_t
{
	FIELD_VOID = 0,
	FIELD_FLOAT = 1,
	FIELD_STRING = 2,
	FIELD_VECTOR = 3,
	FIELD_INTEGER = 5,
	FIELD_BOOLEAN = 6,
	FIELD_SHORT = 7,
	FIELD_CHARACTER = 8,
	FIELD_COLOR32 = 9,
	FIELD_CLASSPTR = 12,
	FIELD_EHANDLE = 13,
	FIELD_POSITION_VECTOR = 15
}

enum struct variant_t
{
	bool bValue;
	int iValue;
	float flValue;
	char iszValue[256];
	int rgbaValue[4];
	float vecValue[3];
	fieldtype_t fieldType;
}

/*
char USE_TYPE[][] =
{
	"USE_OFF",
	"USE_ON",
	"USE_SET",
	"USE_TOG"
};
// */



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[ANY] Input Hooks - DevTools",
	author = "SilverShot",
	description = "Prints entity inputs, with classname filtering.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=319141"
}

public void OnPluginStart()
{
	// ====================================================================================================
	// GAMEDATA
	// ====================================================================================================
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "gamedata/%s.txt", GAMEDATA);
	if( FileExists(sPath) == false ) SetFailState("\n==========\nMissing required file: \"%s\".\nRead installation instructions again.\n==========", sPath);

	Handle hGameData = LoadGameConfigFile(GAMEDATA);
	if( hGameData == null ) SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);

	int offset = GameConfGetOffset(hGameData, "AcceptInput");
	if( offset == 0 ) SetFailState("Failed to load \"AcceptInput\", invalid offset.");

	delete hGameData;

	gAcceptInput = DHookCreate(offset, HookType_Entity, ReturnType_Bool, ThisPointer_CBaseEntity, AcceptInput);
	DHookAddParam(gAcceptInput, HookParamType_CharPtr);
	DHookAddParam(gAcceptInput, HookParamType_CBaseEntity);
	DHookAddParam(gAcceptInput, HookParamType_CBaseEntity);
	DHookAddParam(gAcceptInput, HookParamType_Object, 20, DHookPass_ByVal|DHookPass_ODTOR|DHookPass_OCTOR|DHookPass_OASSIGNOP); //varaint_t is a union of 12 (float[3]) plus two int type params 12 + 8 = 20
	DHookAddParam(gAcceptInput, HookParamType_Int);



	// ====================================================================================================
	// CVARS CMDS ARRAYS
	// ====================================================================================================
	g_hCvarFilter = CreateConVar(	"sm_input_hooks_filter",		"",						"Do not hook and show input data from these classnames, separate by commas (no spaces). Only works for sm_input_listen command.", CVAR_FLAGS );
	g_hCvarListen = CreateConVar(	"sm_input_hooks_listen",		"",						"Only hook and display input data from these classnames, separate by commas (no spaces). Only works for sm_input_listen command.", CVAR_FLAGS );
	g_hCvarLogging = CreateConVar(	"sm_input_hooks_logging",		"0",					"0=Off. 1=Logs all input data to logs/input_hooks.log file.", CVAR_FLAGS );
	CreateConVar(					"sm_input_hooks_version",		PLUGIN_VERSION,			"Input Hooks plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true,			"sm_input_hooks");

	g_hCvarFilter.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarListen.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarLogging.AddChangeHook(ConVarChanged_Cvars);

	RegAdminCmd("sm_input_listen",		CmdListen,					ADMFLAG_ROOT,	 		"Starts listening to all inputs. Filters or listens for classnames from the filter and listen cvars.");
	RegAdminCmd("sm_input_stop",		CmdStop,					ADMFLAG_ROOT,	 		"Stop printing entity inputs.");
	RegAdminCmd("sm_input_watch",		CmdWatch,					ADMFLAG_ROOT,	 		"Start printing entity inputs. Usage: sm_input_watch <classnames to watch, separate by commas>");

	g_aFilter = new ArrayList(ByteCountToCells(LEN_CLASS));
	g_aListen = new ArrayList(ByteCountToCells(LEN_CLASS));
	g_aWatch = new ArrayList(ByteCountToCells(LEN_CLASS));

	GetCvars();
}



// ====================================================================================================
// CVARS
// ====================================================================================================
void ConVarChanged_Cvars(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();

	if( g_iListenInput == 1 )
	{
		UnhookAll();
		ListenAll();
	}
}

void GetCvars()
{
	g_iCvarLogging = g_hCvarLogging.IntValue;

	int pos, last;
	char sCvar[4096];
	g_aFilter.Clear();
	g_aListen.Clear();

	// Filter list
	g_hCvarFilter.GetString(sCvar, sizeof(sCvar));
	if( sCvar[0] != 0 )
	{
		StrCat(sCvar, sizeof(sCvar), ",");

		while( (pos = FindCharInString(sCvar[last], ',')) != -1 )
		{
			sCvar[pos + last] = 0;
			g_aFilter.PushString(sCvar[last]);
			last += pos + 1;
		}
	}

	// Listen list
	g_hCvarListen.GetString(sCvar, sizeof(sCvar));
	if( sCvar[0] != 0 )
	{
		StrCat(sCvar, sizeof(sCvar), ",");

		pos = 0;
		last = 0;
		while( (pos = FindCharInString(sCvar[last], ',')) != -1 )
		{
			sCvar[pos + last] = 0;
			g_aListen.PushString(sCvar[last]);
			last += pos + 1;
		}
	}
}



// ====================================================================================================
// COMMANDS
// ====================================================================================================
Action CmdListen(int client, int args)
{
	g_bWatch[client] = true;
	g_iListenInput = 1;
	UnhookAll();
	ListenAll();
	return Plugin_Handled;
}

Action CmdStop(int client, int args)
{
	g_aWatch.Clear();
	g_bWatch[client] = false;
	g_iListenInput = 0;
	UnhookAll();
	delete g_hLogFile;
	return Plugin_Handled;
}

Action CmdWatch(int client, int args)
{
	if( args != 1 )
	{
		ReplyToCommand(client, "Usage: sm_input_watch <classnames to watch, separate by commas>");
		return Plugin_Handled;
	}

	// Watch list
	int pos, last;
	char sCvar[4096];
	GetCmdArg(1, sCvar, sizeof(sCvar));
	g_aWatch.Clear();

	if( sCvar[0] != 0 )
	{
		StrCat(sCvar, sizeof(sCvar), ",");

		while( (pos = FindCharInString(sCvar[last], ',')) != -1 )
		{
			sCvar[pos + last] = 0;
			g_aWatch.PushString(sCvar[last]);
			last += pos + 1;
		}
	}

	// Find
	UnhookAll();
	g_bWatch[client] = true;
	g_iListenInput = 2;

	int i = -1;
	for( int index = 0; index < g_aWatch.Length; index++ )
	{
		g_aWatch.GetString(index, sCvar, sizeof(sCvar));

		while( (i = FindEntityByClassname(i, sCvar)) != INVALID_ENT_REFERENCE )
		{
			g_iHookID[i] = DHookEntity(gAcceptInput, false, i);
		}
	}

	return Plugin_Handled;
}



// ====================================================================================================
// LISTEN
// ====================================================================================================
void ListenAll()
{
	char classname[LEN_CLASS];
	for( int i = 0; i < MAX_ENTS; i++ )
	{
		if( IsValidEdict(i) )
		{
			GetEntPropString(i, Prop_Data, "m_iClassname", classname, sizeof(classname)); // Because GetEdictClassname fails for non-networked entities.
			OnEntityCreated(i, classname);
		}
	}
}

void UnhookAll()
{
	for( int i = 0; i < MAX_ENTS; i++ )
	{
		if( g_iHookID[i] )
		{
			DHookRemoveHookID(g_iHookID[i]);
			g_iHookID[i] = 0;
		}
		if( g_iInputHookID[i] )
		{
			DHookRemoveHookID(g_iInputHookID[i]);
			g_iInputHookID[i] = 0;
		}
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if( g_iListenInput == 0 )													return;
	if( g_iListenInput == 1 )
	{
		if( g_aFilter.Length != 0 && g_aFilter.FindString(classname) != -1 )	return;
		if( g_aListen.Length != 0 && g_aListen.FindString(classname) == -1 )	return;
	} else {
		if( g_aWatch.FindString(classname) == -1 )								return;
	}

	if( entity < 0 )
		entity = EntRefToEntIndex(entity);

	g_iHookID[entity] = DHookEntity(gAcceptInput, false, entity);
}

MRESReturn AcceptInput(int pThis, Handle hReturn, Handle hParams)
{
	// Get args
	static char result[128];
	static char command[128];
	DHookGetParamString(hParams, 1, command, sizeof(command));

	variant_t params;
	params.fieldType = view_as<fieldtype_t>(DHookGetParamObjectPtrVar(hParams, 4, 16, ObjectValueType_Int));

	switch (params.fieldType)
	{
		case FIELD_FLOAT:
		{
			params.flValue = DHookGetParamObjectPtrVar(hParams, 4, 0, ObjectValueType_Float);
			FloatToString(params.flValue, result, sizeof(result));
		}

		case FIELD_STRING:
		{
			DHookGetParamObjectPtrString(hParams, 4, 0, ObjectValueType_String, result, sizeof(result));
		}

		case FIELD_VECTOR, FIELD_POSITION_VECTOR:
		{
			DHookGetParamObjectPtrVarVector(hParams, 4, 0, ObjectValueType_Vector, params.vecValue);
			Format(result, sizeof(result), "%f, %f, %f", params.vecValue[0], params.vecValue[1], params.vecValue[2]);
		}

		case FIELD_INTEGER, FIELD_SHORT, FIELD_CHARACTER:
		{
			params.iValue = DHookGetParamObjectPtrVar(hParams, 4, 0, ObjectValueType_Int);
			IntToString(params.iValue, result, sizeof(result));
		}

		case FIELD_BOOLEAN:
		{
			params.bValue = DHookGetParamObjectPtrVar(hParams, 4, 0, ObjectValueType_Bool);
			IntToString(params.bValue, result, sizeof(result));
		}

		case FIELD_COLOR32:
		{
			int color = DHookGetParamObjectPtrVar(hParams, 4, 0, ObjectValueType_Int);
			params.rgbaValue[0] = color & 0xFF;
			params.rgbaValue[1] = (color >> 8) & 0xFF;
			params.rgbaValue[2] = (color >> 16) & 0xFF;
			params.rgbaValue[3] = (color >> 24) & 0xFF;

			Format(result, sizeof(result), "%d %d %d %d", params.rgbaValue[0], params.rgbaValue[1], params.rgbaValue[2], params.rgbaValue[3]);
		}

		case FIELD_CLASSPTR, FIELD_EHANDLE:
		{
			params.iValue = DHookGetParamObjectPtrVar(hParams, 4, 0, ObjectValueType_Ehandle);
			IntToString(params.iValue, result, sizeof(result));
		}

		default:
		{
			Format(result, sizeof(result), "Unknown type: %d", params.fieldType);
		}
	}

	static char classname[LEN_CLASS];
	GetEntPropString(pThis, Prop_Data, "m_iClassname", classname, sizeof(classname));

	if( pThis < 0 )
		pThis = EntRefToEntIndex(pThis);

	int entity = -1;
	if( DHookIsNullParam(hParams, 2) == false )
		entity = DHookGetParam(hParams, 2);

	// Activator + classname
	static char activator[LEN_CLASS];
	static char sName[128];

	activator[0] = 0;
	sName[0] = 0;

	if( entity != -1 )
	{
		if( entity > 0 && entity <= MaxClients )
			Format(activator, sizeof(activator), "%N", entity);
		else
		{
			GetEntPropString(entity, Prop_Data, "m_iClassname", activator, sizeof(activator));
			if( entity < 0 )
				entity = EntRefToEntIndex(entity);
		}
	}

	if( HasEntProp(pThis, Prop_Data, "m_iName") )
	{
		GetEntPropString(pThis, Prop_Data, "m_iName", sName, sizeof(sName));
	}

	// Print
	for( int i = 0; i <= MaxClients; i++ )
	{
		if( g_bWatch[i] )
		{
			if( i )
			{
				if( IsClientInGame(i) )
				{
					PrintToChat(i, "\x01Ent %4d \x04%36s \x01Cmd \x05%20s \x01Name \x03%45s \x01Param \x03%12s \x01Act \x01%4d \x04%s", pThis, classname, command, sName, result, entity, activator);
				}
				else
					g_bWatch[i] = false;
			}
			else
				PrintToServer("%4d %s. (%s). %s (%s). %d %s", pThis, classname, command, sName, result, entity, activator);
		}
	}

	if( g_iCvarLogging )
	{
		if( g_hLogFile == null )
		{
			char sPath[PLATFORM_MAX_PATH];
			BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_DUMP);
			g_hLogFile = OpenFile(sPath, "a", false);
		}

		char temp[16];
		FormatTime(temp, sizeof(temp), "%H:%M:%S", GetTime());
		WriteFileLine(g_hLogFile, "%s Ent %4d %16s Cmd %36s Name %45s Param %12s Act %4d %s", temp, pThis, classname, command, sName, result, entity, activator);
		FlushFile(g_hLogFile);
	}

	return MRES_Ignored;
}