/*
*	UserMsg Hooks - DevTools
*	Copyright (C) 2021 Silvers
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



#define PLUGIN_VERSION 		"1.5"

/*=======================================================================================
	Plugin Info:

*	Name	:	[ANY] UserMsg Hooks - DevTools
*	Author	:	SilverShot
*	Descrp	:	Prints UserMessage data, with class filtering.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=319685
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.5 (04-Dec-2021)
	- Changes to fix warnings when compiling on SourceMod 1.11.

1.4 (20-Apr-2021)
	- Fixed compile errors on SourceMod 1.11.

1.3 (01-Dec-2019)
	- Changed timestamps to use 24 hour format.

1.2 (29-Nov-2019)
	- Fixed percent formatting operators breaking print to chat.

1.1 (24-Nov-2019)
	- Plugin now logs an error and quits when failing to find required "UserMessageBegin" function.
	- Prints which functions are hooked when VERBOSE = 1.

1.0 (15-Nov-2019)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <dhooks>

#define CVAR_FLAGS			FCVAR_NOTIFY
#define GAMEDATA			"usermsg_hooks.games"
#define GAMEDATA2			"usermsg_hooks.find"
#define CONFIG_DUMP			"logs/user_messages_dump.log"
#define CONFIG_TYPES		"logs/user_messages_types.log"

#define LEN_CLASS			64	// Max UserMessage names string length
#define MAX_MSGS			128 // 255 = game max? // Potential number of usermessages for monitoring hooks
#define MAX_HOOKS			18	// Max number of MessageWrite detours to check for, must match gamedata entries
#define MAX_SEARCH			500	// How many bytes to reverse search for function start.
#define VERBOSE				0	// 0=Off. Print: 1=Ptrs + Info. 2=Both + Types.



ConVar g_hCvarFilter, g_hCvarListen, g_hCvarLogging;
ArrayList g_aFilter, g_aListen, g_aWatch, g_aStruct;
KeyValues g_kvMsgStructs;
File g_hLogFile;
bool g_WatchDetour, g_bWatch[MAXPLAYERS+1];
int g_iCvarLogging, g_iListening, g_iHookedUserMsg[MAX_MSGS];

enum
{
	TYPE_Angle = 0,		TYPE_Bits,			TYPE_BitVecInt,		TYPE_Bool,			TYPE_Coord,			TYPE_EHandle,
	TYPE_Entity,		TYPE_Float,			TYPE_Long,			TYPE_SBitLong,		TYPE_String,		TYPE_UBitLong,
	TYPE_Vec3Coord,		TYPE_Vec3Normal,	TYPE_WRITE_BYTE,	TYPE_WRITE_CHAR,	TYPE_WRITE_SHORT,	TYPE_WRITE_WORD
}

static const char g_sTypes[][] =
{
	"Angle",			"Bits",				"BitVecIntegral",	"Bool",				"Coord",			"EHandle",
	"Entity",			"Float",			"Long",				"SBitLong",			"String",			"UBitLong",
	"Vec3Coord",		"Vec3Normal",		"WRITE_BYTE",		"WRITE_CHAR",		"WRITE_SHORT",		"WRITE_WORD"
};

int g_iSizes[] =
{
	1,					1,					2,					1,					2,					4,
	4,					4,					4,					4,					1,					4,
	2,					2,					1,					1,					2,					1
};



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[ANY] UserMsg Hooks - DevTools",
	author = "SilverShot",
	description = ".",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=319685"
}

public void OnPluginStart()
{
	// Detours
	HookDetours();

	// Arrays
	g_aFilter = new ArrayList(ByteCountToCells(LEN_CLASS));
	g_aListen = new ArrayList(ByteCountToCells(LEN_CLASS));
	g_aWatch = new ArrayList(ByteCountToCells(LEN_CLASS));
	g_aStruct = CreateArray(LEN_CLASS);

	// Cvars
	g_hCvarFilter = CreateConVar(	"sm_usermsg_filter",		"MusicCmd",			"Do not hook and these UserMessages, separate by commas (no spaces). Only works for sm_um_listen command.", CVAR_FLAGS );
	g_hCvarListen = CreateConVar(	"sm_usermsg_listen",		"",					"Only hook and display these UserMessages, separate by commas (no spaces). Only works for sm_um_listen command.", CVAR_FLAGS );
	g_hCvarLogging = CreateConVar(	"sm_usermsg_logging",		"1",				"0=Off. 1=Logs all UserMessage structures. 2=Log listen UserMessage data. 4=Log listen UserMessage data with timestamps. Add numbers together.", CVAR_FLAGS );
	CreateConVar(					"sm_usermsg_version",		PLUGIN_VERSION,		"UserMsg Hooks plugin version.", CVAR_FLAGS|FCVAR_DONTRECORD);
	AutoExecConfig(true,			"usermsg_hooks");

	g_hCvarFilter.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarListen.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarLogging.AddChangeHook(ConVarChanged_Cvars);

	GetCvars();

	// Commands
	RegAdminCmd("sm_um_listen",		CmdListen,					ADMFLAG_ROOT,	 	"Starts listening to all UserMessages. Filters or listens for messages from the filter and listen cvars.");
	RegAdminCmd("sm_um_stop",		CmdStop,					ADMFLAG_ROOT,	 	"Stop printing UserMessages.");
	RegAdminCmd("sm_um_watch",		CmdWatch,					ADMFLAG_ROOT,	 	"Start printing UserMessages. Usage: sm_um_watch <messages to watch, separate by commas>");

	// Logging
	g_kvMsgStructs = new KeyValues("usermessages");
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof sPath, CONFIG_TYPES);
	if( FileExists(sPath) )
		g_kvMsgStructs.ImportFromFile(sPath);
}



// ====================================================================================================
// HOOK DETOURS
// ====================================================================================================
void HookDetours()
{
	// GAMEDATA
	Handle hDetour;
	Handle hGamedata = LoadGameConfigFile(GAMEDATA);
	if( hGamedata == null ) SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);

	int OS = GameConfGetOffset(hGamedata, "OS");



	// AUTOMATICALLY GENERATE DETOURS
	// Search game memory for usermessage strings
	Address patchAddr;
	Address patches[MAX_HOOKS + 1];

	char temp[64];
	for( int i = 0; i <= MAX_HOOKS; i++ )
	{
		Format(temp, sizeof temp, "UserMsg_%d", i);
		patchAddr = GameConfGetAddress(hGamedata, temp);
		#if VERBOSE
		PrintToServer("USERMSG: STRING %02d PTR %X", i, patchAddr);
		#endif

		patches[i] = patchAddr;
	}

	delete hGamedata;



	// Write custom gamedata with found addresses
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof sPath, "gamedata/%s.txt", GAMEDATA2);
	File hFile = OpenFile(sPath, "w", false);

	char sAddress[12];
	char sHexAddr[32];

	hFile.WriteLine("\"Games\"");
	hFile.WriteLine("{");
	hFile.WriteLine("	\"#default\"");
	hFile.WriteLine("	{");
	hFile.WriteLine("		\"Addresses\"");
	hFile.WriteLine("		{");

	for( int i = 0; i <= MAX_HOOKS; i++ )
	{
		patchAddr = patches[i];

		if( patchAddr )
		{
			hFile.WriteLine("			\"UserMsg_%d\"", i);
			hFile.WriteLine("			{");
			if( OS )
			{
				hFile.WriteLine("				\"linux\"");
				hFile.WriteLine("				{");
				hFile.WriteLine("					\"signature\"		\"UserMsg_%d\"", i);
				hFile.WriteLine("				}");
			} else {
				hFile.WriteLine("				\"windows\"");
				hFile.WriteLine("				{");
				hFile.WriteLine("					\"signature\"		\"UserMsg_%d\"", i);
				hFile.WriteLine("				}");
			}
			hFile.WriteLine("			}");
		}
	}

	hFile.WriteLine("		}");
	hFile.WriteLine("");
	hFile.WriteLine("		\"Signatures\"");
	hFile.WriteLine("		{");

	for( int i = 0; i <= MAX_HOOKS; i++ )
	{
		patchAddr = patches[i];

		if( patchAddr )
		{
			Format(sAddress, sizeof sAddress, "%X", patchAddr);
			ReverseAddress(sAddress, sHexAddr);

			hFile.WriteLine("			\"UserMsg_%d\"", i);
			hFile.WriteLine("			{");
			// hFile.WriteLine("				\"library\"	\"server\""); // Server is default.
			if( OS )
			{
				hFile.WriteLine("				\"linux\"	\"%s\"", sHexAddr);
			} else {
				hFile.WriteLine("				\"windows\"	\"%s\"", sHexAddr);
			}
			hFile.WriteLine("			}");
		}
	}

	hFile.WriteLine("		}");
	hFile.WriteLine("	}");
	hFile.WriteLine("}");

	FlushFile(hFile);
	delete hFile;



	// Load custom gamedata addresses to detour
	hGamedata = LoadGameConfigFile(GAMEDATA2);
	if( hGamedata == null ) SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA2);

	int cc;

	for( int i = 0; i <= MAX_HOOKS; i++ )
	{
		patchAddr = patches[i];

		if( patchAddr )
		{
			Format(temp, sizeof temp, "UserMsg_%d", i);
			patchAddr = GameConfGetAddress(hGamedata, temp);

			if( patchAddr )
			{
				// Find function start:
				cc = 0;
				for( int x = 1; x < MAX_SEARCH; x++ )
				{
					// 55 89 E5 // Linux
					// 55 8B EC // Win
					if(
						LoadFromAddress(patchAddr - view_as<Address>(x),		NumberType_Int8) == (OS ? 0xE5 : 0xEC) &&
						LoadFromAddress(patchAddr - view_as<Address>(x + 1),	NumberType_Int8) == (OS ? 0x89 : 0x8B) &&
						LoadFromAddress(patchAddr - view_as<Address>(x + 2),	NumberType_Int8) == 0x55
					)
					{
						break;
					} else {
						cc = x + 3;
					}
				}

				if( cc == 0 ) SetFailState("Couldn't find function start: %d.", i);
				patchAddr -= view_as<Address>(cc);

				// Detour to get structure
				if( i == 0 )
				{
					hDetour = DHookCreateDetour(patchAddr, CallConv_CDECL, ReturnType_Int, ThisPointer_Ignore);
					DHookAddParam(hDetour, HookParamType_Int);
					DHookAddParam(hDetour, HookParamType_CharPtr);
				}
				else
					hDetour = DHookCreateDetour(patchAddr, CallConv_CDECL, ReturnType_Int, ThisPointer_Ignore);

				if( hDetour == INVALID_HANDLE ) SetFailState("Failed to create detour \"%s\" %d function.", i ? "MessageWrite" : "UserMessageBegin", i);

				switch( i )
				{
					case 0:		if( !DHookEnableDetour(hDetour, false, UserMessageBegin) )				SetFailState("Failed to detour \"UserMessageBegin\" function.");
					case 1:		if( !DHookEnableDetour(hDetour, false, MessageWriteAngle) )				SetFailState("Failed to detour \"MessageWriteAngle\" function.");
					case 2:		if( !DHookEnableDetour(hDetour, false, MessageWriteBits) )				SetFailState("Failed to detour \"MessageWriteBits\" function.");
					case 3:		if( !DHookEnableDetour(hDetour, false, MessageWriteBitVecIntegral) )	SetFailState("Failed to detour \"MessageWriteBitVecIntegral\" function.");
					case 4:		if( !DHookEnableDetour(hDetour, false, MessageWriteBool) )				SetFailState("Failed to detour \"MessageWriteBool\" function.");
					case 5:		if( !DHookEnableDetour(hDetour, false, MessageWriteCoord) )				SetFailState("Failed to detour \"MessageWriteCoord\" function.");
					case 6:		if( !DHookEnableDetour(hDetour, false, MessageWriteEHandle) )			SetFailState("Failed to detour \"MessageWriteEHandle\" function.");
					case 7:		if( !DHookEnableDetour(hDetour, false, MessageWriteEntity) )			SetFailState("Failed to detour \"MessageWriteEntity\" function.");
					case 8:		if( !DHookEnableDetour(hDetour, false, MessageWriteFloat) )				SetFailState("Failed to detour \"MessageWriteFloat\" function.");
					case 9:		if( !DHookEnableDetour(hDetour, false, MessageWriteLong) )				SetFailState("Failed to detour \"MessageWriteLong\" function.");
					case 10:	if( !DHookEnableDetour(hDetour, false, MessageWriteSBitLong) )			SetFailState("Failed to detour \"MessageWriteSBitLong\" function.");
					case 11:	if( !DHookEnableDetour(hDetour, false, MessageWriteString) )			SetFailState("Failed to detour \"MessageWriteString\" function.");
					case 12:	if( !DHookEnableDetour(hDetour, false, MessageWriteUBitLong) )			SetFailState("Failed to detour \"MessageWriteUBitLong\" function.");
					case 13:	if( !DHookEnableDetour(hDetour, false, MessageWriteVec3Coord) )			SetFailState("Failed to detour \"MessageWriteVec3Coord\" function.");
					case 14:	if( !DHookEnableDetour(hDetour, false, MessageWriteVec3Normal) )		SetFailState("Failed to detour \"MessageWriteVec3Normal\" function.");
					case 15:	if( !DHookEnableDetour(hDetour, false, MessageWriteWRITE_BYTE) )		SetFailState("Failed to detour \"MessageWriteWRITE_BYTE\" function.");
					case 16:	if( !DHookEnableDetour(hDetour, false, MessageWriteWRITE_CHAR) )		SetFailState("Failed to detour \"MessageWriteWRITE_CHAR\" function.");
					case 17:	if( !DHookEnableDetour(hDetour, false, MessageWriteWRITE_SHORT) )		SetFailState("Failed to detour \"MessageWriteWRITE_SHORT\" function.");
					case 18:	if( !DHookEnableDetour(hDetour, false, MessageWriteWRITE_WORD) )		SetFailState("Failed to detour \"MessageWriteWRITE_WORD\" function.");
				}

				#if VERBOSE
				PrintToServer("USERMSG: DETOUR %02d PTR %X (%s)", i, patchAddr, i == 0 ? "UserMessageBegin" : g_sTypes[i-1]);
				#endif
			}
		} else {
			if( i == 0 ) SetFailState("Couldn't find required UserMessageBegin function.");
		}
	}
	delete hGamedata;
}

void ReverseAddress(const char[] sBytes, char sReturn[32])
{
	sReturn[0] = 0;
	char sByte[3];
	for( int i = strlen(sBytes) - 2; i >= -1 ; i -= 2 )
	{
		strcopy(sByte, i >= 1 ? 3 : i + 3, sBytes[i >= 0 ? i : 0]);

		StrCat(sReturn, sizeof sReturn, "\\x");
		if( strlen(sByte) == 1 )
			StrCat(sReturn, sizeof sReturn, "0");
		StrCat(sReturn, sizeof sReturn, sByte);
	}
}



// ====================================================================================================
// CVARS
// ====================================================================================================
public void ConVarChanged_Cvars(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	// Cvars
	g_iCvarLogging = g_hCvarLogging.IntValue;

	// Filters
	int pos, last;
	char sCvar[4096];
	g_aFilter.Clear();
	g_aListen.Clear();

	// Filter list
	g_hCvarFilter.GetString(sCvar, sizeof(sCvar));
	if( sCvar[0] != 0 )
	{
		StrCat(sCvar, sizeof sCvar, ",");

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
		StrCat(sCvar, sizeof sCvar, ",");

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
public Action CmdListen(int client, int args)
{
	g_iListening = 1;
	g_bWatch[client] = true;

	UnhookAll();
	ListenAll();
	return Plugin_Handled;
}

public Action CmdStop(int client, int args)
{
	g_aWatch.Clear();
	g_bWatch[client] = false;
	g_iListening = 0;
	if( g_hLogFile != null ) delete g_hLogFile;

	UnhookAll();
	return Plugin_Handled;
}

public Action CmdWatch(int client, int args)
{
	if( args != 1 )
	{
		ReplyToCommand(client, "Usage: sm_um_watch <classnames to watch, separate by commas>");
		return Plugin_Handled;
	}

	// Watch list
	int pos, last;
	char sCvar[4096];
	GetCmdArg(1, sCvar, sizeof sCvar);
	g_aWatch.Clear();

	if( sCvar[0] != 0 )
	{
		StrCat(sCvar, sizeof sCvar, ",");

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
	g_iListening = 2;
	ListenAll();

	return Plugin_Handled;
}



// ====================================================================================================
// LISTEN
// ====================================================================================================
void ListenAll()
{
	char msgname[LEN_CLASS];
	int i = 1;
	while( i )
	{
		if( GetUserMessageName(view_as<UserMsg>(i), msgname, sizeof msgname) )
		{
			g_iHookedUserMsg[i] = 1;
			HookUserMessage(view_as<UserMsg>(i), OnMessage, false);

			#if VERBOSE
			PrintToServer("USERMSG: HOOKED %02d - %s", i, msgname);
			#endif

			i++;
		} else {
			i = 0;
		}
	}
}

void UnhookAll()
{
	for( int i = 1; i < MAX_MSGS; i++ )
	{
		if( g_iHookedUserMsg[i] )
		{
			g_iHookedUserMsg[i] = 0;
			UnhookUserMessage(view_as<UserMsg>(i), OnMessage, false);
		}
	}
}

public Action OnMessage(UserMsg msg_id, BfRead hMsg, const int[] players, int playersNum, bool reliable, bool init)
{
	// Exit?
	g_WatchDetour = false;

	if( (g_iListening == 0 && g_iCvarLogging == 0) ) return Plugin_Continue;
	if( g_aStruct.Length == 0 ) return Plugin_Continue;



	// Var
	static char msgname[LEN_CLASS];
	static char buffer[255];
	static char temp[255];
	static char id[128];
	int type;



	// Name
	GetUserMessageName(msg_id, msgname, sizeof msgname);
	g_aStruct.GetString(0, id, sizeof id);

	if( strcmp(msgname, id) )
	{
		LogError("Mismatch types: %s - %s", msgname, id);
		g_aStruct.Clear();
		return Plugin_Continue;
	}



	// ID
	int sizes;
	int types;
	// int num;
	for( int i = 1; i < g_aStruct.Length; i++ )
	{
		type = g_aStruct.Get(i);
		types |= (1<<type);
		sizes += g_iSizes[type];
	}

	Format(id, sizeof id, "%s/%d:%d:%d", msgname, g_aStruct.Length - 1, sizes, types);



	// Logging - Structure
	if( g_iCvarLogging & (1<<0) )
	{
		char val[4];

		// Unique entry
		g_kvMsgStructs.Rewind();
		if( g_kvMsgStructs.JumpToKey(id) == true )
		{
			type = 0;
		} else {
			type = 1;

			#if VERBOSE
			PrintToServer("USERMSG: Adding new format entry for %s", id);
			#endif
		}



		// Not matched, write to log
		if( type )
		{
			g_kvMsgStructs.Rewind();

			if( g_kvMsgStructs.JumpToKey(id, true) )
			{
				if( g_aStruct.Length == 1 )
				{
					g_kvMsgStructs.SetString("0", "<NO ARGS>");
				} else {
					for( int i = 1; i < g_aStruct.Length; i++ )
					{
						type = g_aStruct.Get(i);
						IntToString(i, val, sizeof val);
						g_kvMsgStructs.SetString(val, g_sTypes[type]);
					}
				}

				char sPath[PLATFORM_MAX_PATH];
				BuildPath(Path_SM, sPath, sizeof sPath, CONFIG_TYPES);

				g_kvMsgStructs.Rewind();
				g_kvMsgStructs.ExportToFile(sPath);
			}
		}
	}



	// Listening
	if( g_iListening )
	{
		if( g_iListening == 1 )
		{
			if( g_aFilter.Length != 0 && g_aFilter.FindString(msgname) != -1 )	{g_aStruct.Clear(); return Plugin_Continue;}
			if( g_aListen.Length != 0 && g_aListen.FindString(msgname) == -1 )	{g_aStruct.Clear(); return Plugin_Continue;}
		} else {
			if( g_aWatch.FindString(msgname) == -1 )							{g_aStruct.Clear(); return Plugin_Continue;}
		}

		buffer[0] = 0;

		#if VERBOSE == 2
		PrintToServer("");
		#endif

		for( int i = 1; i < g_aStruct.Length; i++ )
		{
			type = g_aStruct.Get(i);

			#if VERBOSE == 2
			PrintToServer("UM Type: %d %s", type, g_sTypes[type]);
			#endif

			switch( type )
			{
				// case TYPE_Angle:
				// {
					// float vVec[3];
					// BfReadAngles(hMsg, vVec);
					// Format(buffer, sizeof buffer, "%s[%f %f %f]", buffer, vVec[0], vVec[1], vVec[2]);
				// }
				case TYPE_String:
				{
					BfReadString(hMsg, temp, sizeof temp);
					Format(buffer, sizeof(buffer), "%s[%s]", buffer, temp);
				}
				case TYPE_BitVecInt, TYPE_Vec3Coord:
				{
					float vVec[3];
					BfReadVecCoord(hMsg, vVec);
					Format(buffer, sizeof buffer, "%s[%f %f %f]", buffer, vVec[0], vVec[1], vVec[2]);
				}
				case TYPE_Vec3Normal:
				{
					float vVec[3];
					BfReadVecNormal(hMsg, vVec);
					Format(buffer, sizeof buffer, "%s[%f %f %f]", buffer, vVec[0], vVec[1], vVec[2]);
				}
				case TYPE_Entity:													Format(buffer, sizeof(buffer), "%s[%d]", buffer, BfReadEntity(hMsg));
				case TYPE_Bool, TYPE_WRITE_CHAR:									Format(buffer, sizeof(buffer), "%s[%d]", buffer, BfReadBool(hMsg));
				case TYPE_WRITE_BYTE:												Format(buffer, sizeof(buffer), "%s[%d]", buffer, BfReadByte(hMsg));
				case TYPE_Angle, TYPE_Coord, TYPE_Float:							Format(buffer, sizeof(buffer), "%s[%f]", buffer, BfReadFloat(hMsg));
				case TYPE_EHandle, TYPE_Long, TYPE_SBitLong, TYPE_UBitLong:			Format(buffer, sizeof(buffer), "%s[%d]", buffer, BfReadNum(hMsg));
				case TYPE_WRITE_SHORT, TYPE_WRITE_WORD:								Format(buffer, sizeof(buffer), "%s[%d]", buffer, BfReadShort(hMsg));
				default:
				{
					Format(buffer, sizeof(buffer), "%sUnsupported type: %d (%s)", buffer, type, msgname);
				}
			}

			StrCat(buffer, sizeof buffer, " ");
		}

		if( g_aStruct.Length > 1 )
			buffer[strlen(buffer) - 1] = 0; // Remove last space
		g_aStruct.Clear();
 
 
 
		// Logging - Dump
		if( g_iCvarLogging & (1<<1) || g_iCvarLogging & (1<<2) )
		{
			if( g_hLogFile == null )
			{
				char sPath[PLATFORM_MAX_PATH];
				BuildPath(Path_SM, sPath, sizeof sPath, CONFIG_DUMP);
				g_hLogFile = OpenFile(sPath, "a", false);
			}

			if( g_iCvarLogging & (1<<1) )
				WriteFileLine(g_hLogFile, "%s: %s", id, buffer);
			else
			{
				FormatTime(temp, sizeof(temp), "%H:%M:%S", GetTime());
				WriteFileLine(g_hLogFile, "%s %0.2f: %s: %s", temp, GetGameTime(), id, buffer);
			}
		}



		// Print
		for( int i = 0; i <= MaxClients; i++ )
		{
			if( g_bWatch[i] )
			{
				if( i )
				{
					// Cannot print from inside a UserMessage!
					if( IsClientInGame(i) && !IsFakeClient(i) )
					{
						// Format to 250 bytes due to TextMsg size limit:
						// "DLL_MessageEnd:  Refusing to send user message TextMsg of 256 bytes to client, user message size limit is 255 bytes"
						ReplaceString(buffer, sizeof buffer, "\%", "%%/");
						Format(temp, 250, "\x04UM: \x05%s\x01: %s", id, buffer);

						DataPack hPack = new DataPack();
						hPack.WriteCell(GetClientUserId(i));
						hPack.WriteString(temp);
						RequestFrame(OnNext, hPack);
					}
					else
						g_bWatch[i] = false;
				}
				else
					PrintToServer("UM: %s: %s", id, buffer);
			}
		}
	}

	return Plugin_Continue;
}

public void OnNext(DataPack hPack)
{
	hPack.Reset();
	int client = hPack.ReadCell();
	if( (client = GetClientOfUserId(client)) && IsClientInGame(client) )
	{
		char temp[250];
		hPack.ReadString(temp, sizeof temp);
		delete hPack;
		PrintToChat(client, temp);
	}
}



// ====================================================================================================
// DETOURS - MSG BEGIN / END
// ====================================================================================================
public MRESReturn UserMessageBegin(Handle hReturn, Handle hParams)
{
	if( g_iListening || g_iCvarLogging )
	{
		static char msgname[LEN_CLASS];
		DHookGetParamString(hParams, 2, msgname, sizeof msgname);

		g_aStruct.Clear();
		g_aStruct.PushString(msgname);
		g_WatchDetour = true;
	}

	return MRES_Ignored;
}



// ====================================================================================================
// DETOURS - STRUCTS
// ====================================================================================================
public MRESReturn MessageWriteAngle(Handle hReturn, Handle hParams)
{
	if( g_WatchDetour ) g_aStruct.Push(TYPE_Angle);
	return MRES_Ignored;
}
public MRESReturn MessageWriteBits(Handle hReturn, Handle hParams)
{
	if( g_WatchDetour ) g_aStruct.Push(TYPE_Bits);
	return MRES_Ignored;
}
public MRESReturn MessageWriteBitVecIntegral(Handle hReturn, Handle hParams)
{
	if( g_WatchDetour ) g_aStruct.Push(TYPE_BitVecInt);
	return MRES_Ignored;
}
public MRESReturn MessageWriteBool(Handle hReturn, Handle hParams)
{
	if( g_WatchDetour ) g_aStruct.Push(TYPE_Bool);
	return MRES_Ignored;
}
public MRESReturn MessageWriteCoord(Handle hReturn, Handle hParams)
{
	if( g_WatchDetour ) g_aStruct.Push(TYPE_Coord);
	return MRES_Ignored;
}
public MRESReturn MessageWriteEHandle(Handle hReturn, Handle hParams)
{
	if( g_WatchDetour ) g_aStruct.Push(TYPE_EHandle);
	return MRES_Ignored;
}
public MRESReturn MessageWriteEntity(Handle hReturn, Handle hParams)
{
	if( g_WatchDetour ) g_aStruct.Push(TYPE_Entity);
	return MRES_Ignored;
}
public MRESReturn MessageWriteFloat(Handle hReturn, Handle hParams)
{
	if( g_WatchDetour ) g_aStruct.Push(TYPE_Float);
	return MRES_Ignored;
}
public MRESReturn MessageWriteLong(Handle hReturn, Handle hParams)
{
	if( g_WatchDetour ) g_aStruct.Push(TYPE_Long);
	return MRES_Ignored;
}
public MRESReturn MessageWriteSBitLong(Handle hReturn, Handle hParams)
{
	if( g_WatchDetour ) g_aStruct.Push(TYPE_SBitLong);
	return MRES_Ignored;
}
public MRESReturn MessageWriteString(Handle hReturn, Handle hParams)
{
	if( g_WatchDetour ) g_aStruct.Push(TYPE_String);
	return MRES_Ignored;
}
public MRESReturn MessageWriteUBitLong(Handle hReturn, Handle hParams)
{
	if( g_WatchDetour ) g_aStruct.Push(TYPE_UBitLong);
	return MRES_Ignored;
}
public MRESReturn MessageWriteVec3Coord(Handle hReturn, Handle hParams)
{
	if( g_WatchDetour ) g_aStruct.Push(TYPE_Vec3Coord);
	return MRES_Ignored;
}
public MRESReturn MessageWriteVec3Normal(Handle hReturn, Handle hParams)
{
	if( g_WatchDetour ) g_aStruct.Push(TYPE_Vec3Normal);
	return MRES_Ignored;
}
public MRESReturn MessageWriteWRITE_BYTE(Handle hReturn, Handle hParams)
{
	if( g_WatchDetour ) g_aStruct.Push(TYPE_WRITE_BYTE);
	return MRES_Ignored;
}
public MRESReturn MessageWriteWRITE_CHAR(Handle hReturn, Handle hParams)
{
	if( g_WatchDetour ) g_aStruct.Push(TYPE_WRITE_CHAR);
	return MRES_Ignored;
}
public MRESReturn MessageWriteWRITE_SHORT(Handle hReturn, Handle hParams)
{
	if( g_WatchDetour ) g_aStruct.Push(TYPE_WRITE_SHORT);
	return MRES_Ignored;
}
public MRESReturn MessageWriteWRITE_WORD(Handle hReturn, Handle hParams)
{
	if( g_WatchDetour ) g_aStruct.Push(TYPE_WRITE_WORD);
	return MRES_Ignored;
}