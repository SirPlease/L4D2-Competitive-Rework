#define PLUGIN_VERSION		"1.2"

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <dhooks>

#define DEBUG 0
#define GAMEDATA		"FollowTarget_Detour"

public Plugin myinfo =
{
	name = "[L4D2][NIX] FollowTarget_Detour",
	author = "Dragokas & TheTrick",
	description = "Fixing the valve crash with null pointer dereference in CMoveableCamera::FollowTarget",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showpost.php?p=2725811&postcount=19"
}

Handle hDetour;
int g_pEntityList;
int g_camIndex;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "gamedata/%s.txt", GAMEDATA);

	Handle hGameData = LoadGameConfigFile(GAMEDATA);
	if( hGameData == null ) SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);
	
	SetupDetour(hGameData);
	
	g_pEntityList = GetEntityListPtr(hGameData);
	
	delete hGameData;
}

public void OnPluginEnd()
{
	if( !DHookDisableDetour(hDetour, false, FollowTarget) )
		SetFailState("Failed to disable detour \"CMoveableCamera::FollowTarget\".");
}

void SetupDetour(Handle hGameData)
{
	hDetour = DHookCreateFromConf(hGameData, "CMoveableCamera::FollowTarget");
	if( !hDetour )
		SetFailState("Failed to find \"CMoveableCamera::FollowTarget\" signature.");
	if( !DHookEnableDetour(hDetour, false, FollowTarget) )
		SetFailState("Failed to start detour \"CMoveableCamera::FollowTarget\".");
}

int GetEntityListPtr(Handle hGameData)
{
	int pFunc = view_as<int>(GameConfGetAddress(hGameData, "CMoveableCamera::FollowTarget"));
	if( pFunc == 0 ) SetFailState("Failed to find \"CMoveableCamera::FollowTarget\" signature.");

	g_camIndex = GameConfGetOffset(hGameData, "Camera_Index");
	if( g_camIndex == -1 ) SetFailState("Failed to load \"Camera_Index\" value.");
	
	int iOffsetOpcode = GameConfGetOffset(hGameData, "g_pEntityList_Opcode_Offset");
	if( iOffsetOpcode == -1 ) SetFailState("Failed to load \"g_pEntityList_Opcode_Offset\" offset.");
	
	int iRelOffset = GameConfGetOffset(hGameData, "g_pEntityList_Relative_Offset");
	if( iRelOffset == -1 ) SetFailState("Failed to load \"g_pEntityList_Relative_Offset\" offset.");
	
	int iBytesMatch = GameConfGetOffset(hGameData, "g_pEntityList_Bytes");
	if( iBytesMatch == -1 ) SetFailState("Failed to load \"g_pEntityList_Bytes\" offset.");
	
	int iCheck = LoadFromAddress(view_as<Address>(pFunc + iOffsetOpcode), NumberType_Int16);
	if( iCheck != iBytesMatch ) SetFailState("Failed to load, byte mis-match @ %d (0x%04X != 0x%04X)", iOffsetOpcode, iCheck, iBytesMatch);
	
	int iEntityListOffset = iOffsetOpcode + iRelOffset;
	
	int pEntityList = SafeDeref(pFunc + iEntityListOffset);
	if( pEntityList == 0 ) SetFailState("Failed to find \"g_pEntityList\" structure.");

	return SafeDeref(pEntityList);
}

public MRESReturn FollowTarget(int pThis, Handle hReturn, Handle hParams)
{
	if( !CameraHasTarget(pThis) )
	{
		if( pThis && IsValidEntity(pThis) )
		{
			AcceptEntityInput(pThis, "Disable");
		}
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}
	return MRES_Ignored;
}

bool CameraHasTarget(int pCamera) // thanks to @TheTrick for helping with disassembly understanding
{
	/*
		v2 = *(this + 281*4); // dwBitField (LB == entIndex; HB == serial)
		
		if ( v2 != -1 )
		{
			v3 = (char *)g_pEntityList[v2 & 0xFFF]; // entIndex
			
			if ( *(v3 + 2 * 4) == v2 >> 12 ) // if (g_pEntityList[index].Unknown2 == serial)
			{
				v1 = (CBaseEntity *)*(v3 + 1 * 4); // = g_pEntityList[index].Unknown1
			}
		}
	*/
	
	int camAddr, entIndex, serial_cam, serial_cli, cliAddr;
	
	if( pCamera && IsValidEntity(pCamera) )
	{
		camAddr = view_as<int>(GetEntityAddress(pCamera));
		
		int bf = SafeDeref( camAddr + g_camIndex*4 ); // bit-field, holding client index + serial
		
		entIndex = bf & 0xFFF;
		serial_cam = bf >> 12;
		
		if( entIndex && IsValidEntity(entIndex) )
		{
			int pEntityStruct = g_pEntityList + entIndex*16; // array of 16-bytes struct
			
			serial_cli = SafeDeref( pEntityStruct + 2*4 );
			
			if( serial_cli == serial_cam )
			{
				cliAddr = SafeDeref( pEntityStruct + 1*4 );
				
				if( IsValidClientAddress(cliAddr) )
				{
					return true;
				}
			}
		}
	}
	
	#if DEBUG
		PrintToServer("########### CMoveableCamera::FollowTarget crash is successfully prevented!");
		PrintToServer("########### CMoveableCamera = %i", pCamera);
		PrintToServer("########### camAddr = %i", camAddr);
		PrintToServer("########### entIndex = %i", entIndex);
		PrintToServer("########### serial_cam = %i (0x%X)", serial_cam, serial_cam);
		PrintToServer("########### serial_cli = %i (0x%X)", serial_cli, serial_cli);
		PrintToServer("########### v1 = %i (0x%X)", cliAddr, cliAddr);
	#endif
	
	return false;
}

int SafeDeref(int Addr)
{
	if( Addr != 0 )
	{
		return LoadFromAddress(view_as<Address>(Addr), NumberType_Int32);
	}
	return 0;
}

bool IsValidClientAddress(int Addr)
{
	if( Addr == 0 )
		return false;

	for( int cli = 1; cli <= MaxClients; cli++ )
	{
		if( IsClientInGame(cli) && GetEntityAddress(cli) == view_as<Address>(Addr) )
		{
			return true;
		}
	}
	return false;
}
