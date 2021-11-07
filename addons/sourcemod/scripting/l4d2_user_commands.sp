#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#include <dhooks>

#undef REQUIRE_PLUGIN
#include <smac>

#pragma newdecls required

#define IsFinite(%0) ((%0 & view_as<float>(0x7F800000)) != view_as<float>(0x7F800000))

public Plugin myinfo =
{
    name = "[L4D2] Usercommands Check",
    author = "BHaType"
};

enum CUserCmd
{
	command_number,
	tick_count = 4,
	viewangles = 8,
	forwardmove = 20,
	sidemove = 24,
	upmove = 28,
	buttons = 32
};

methodmap CUserCommand 
{
	public CUserCommand (int command)
	{
		return view_as<CUserCommand>(command);
	}
	
	public int Get (CUserCmd propertie)
	{
		return LoadFromAddress(view_as<Address>(this) + view_as<Address>(propertie), NumberType_Int32); 
	}
	
	public void GetVector (CUserCmd propertie, float vVec[3])
	{
		vVec[0] = view_as<float>(LoadFromAddress(view_as<Address>(this) + view_as<Address>(propertie), NumberType_Int32)); 
		vVec[1] = view_as<float>(LoadFromAddress(view_as<Address>(this) + view_as<Address>(propertie + tick_count), NumberType_Int32)); 
		vVec[2] = view_as<float>(LoadFromAddress(view_as<Address>(this) + view_as<Address>(propertie + viewangles), NumberType_Int32));
	}
	
	public void Set (CUserCmd propertie, any data)
	{
		StoreToAddress(view_as<Address>(this) + view_as<Address>(propertie), data, NumberType_Int32); 
	}
	
	public void SetVector (CUserCmd propertie, float vVec[3])
	{
		StoreToAddress(view_as<Address>(this) + view_as<Address>(propertie), view_as<int>(vVec[0]), NumberType_Int32); 
		StoreToAddress(view_as<Address>(this) + view_as<Address>(propertie + tick_count), view_as<int>(vVec[1]), NumberType_Int32); 
		StoreToAddress(view_as<Address>(this) + view_as<Address>(propertie + viewangles), view_as<int>(vVec[2]), NumberType_Int32); 
	}
}

DynamicHook g_hProcessCommand;

const float g_flMaxEntityEulerAngle = 360000.0;
const float g_flMaxEntityPosCoord = 16384.0;

enum struct CCommandContext
{
	float detection;
	int ignored_commands;
}

CCommandContext gCommandContext[MAXPLAYERS + 1];
int m_nTickBase;

bool g_bSMAC;

ConVar sm_usercmd_null_invalid_commands;
int g_iNull;

public void OnPluginStart()
{
	m_nTickBase = FindSendPropInfo("CBasePlayer", "m_nTickBase");
	
	sm_usercmd_null_invalid_commands = CreateConVar("sm_usercmd_null_invalid_commands", "0", "Null invalid commands");
	sm_usercmd_null_invalid_commands.AddChangeHook(OnConVarChanged);
	
	AutoExecConfig(true, "l4d2_user_commands");
	
	g_iNull = sm_usercmd_null_invalid_commands.IntValue;
	
	GameData data = new GameData("l4d2_user_commands");

	g_hProcessCommand = DynamicHook.FromConf(data, "ProcessUsercmds");
	
	delete data;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if ( IsClientConnected(i) )
		{
			OnClientPutInServer(i);
		}
	}
}

public void OnConVarChanged (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iNull = sm_usercmd_null_invalid_commands.IntValue;
}

public void OnClientPutInServer (int client)
{
	if ( !IsFakeClient(client) )
	{
		gCommandContext[client].ignored_commands = RoundToCeil(( 1.0 / GetTickInterval() ) * 2.5);
		g_hProcessCommand.HookEntity(Hook_Pre, client, ProcessUsercmds);
	}
}

public MRESReturn ProcessUsercmds (int client, DHookParam params)
{
	if ( gCommandContext[client].ignored_commands-- > 0 )
		return MRES_Ignored;
		
	//int numcmds = params.Get(2);
	int totalcmds = params.Get(3);
	int dropped_packets = params.Get(4);
	
	int i;
	for ( i = totalcmds - 1; i >= 0; i-- )
	{
		int numcommand = totalcmds - 1 - i;
		CUserCommand command = CUserCommand(params.Get(1) + numcommand * 88);
		
		if ( !IsUserCommandValid(client, command) )
		{
			if ( g_iNull )
			{
				float vAngle[3];
		
				command.SetVector(viewangles, vAngle);
				
				command.Set(forwardmove, 0.0);
				command.Set(sidemove, 0.0);
				command.Set(upmove, 0.0);
				
				command.Set(buttons, 0);
			}
			
			if ( GetEngineTime() - gCommandContext[client].detection >= 5.0 )
			{
				gCommandContext[client].detection = GetEngineTime();
				
				if ( !g_bSMAC )
				{
					LogMessage("Player %L is suspected in using invalid user commands (dropped packets %i)", client, dropped_packets);
				}
				else
				{
					SMAC_Log("Player %L is suspected in using invalid user commands (dropped packets %i)", client, dropped_packets);
				}
			}
		}
	}
	
	return MRES_Ignored;
}


bool IsUserCommandValid (int client, CUserCommand command)
{
	int nCmdMaxTickDelta = RoundToCeil(( 1.0 / GetTickInterval() ) * 2.5);
	int nMinDelta = Max(0, GetGameTickCount() - nCmdMaxTickDelta);
	int nMaxDelta = GetGameTickCount() + nCmdMaxTickDelta;

	float flForwardmove, flSidemove, flUpmove;
	float vAngles[3];
	int tick;
	
	flForwardmove = view_as<float>(command.Get(forwardmove));
	flSidemove = view_as<float>(command.Get(sidemove));
	flUpmove = view_as<float>(command.Get(upmove));
	
	tick = GetEntData(client, m_nTickBase);
	command.GetVector(viewangles, vAngles);
	
	bool bValid = ( tick >= nMinDelta && tick < nMaxDelta ) &&
				  ( IsFinite(vAngles[0]) && IsFinite(vAngles[1]) && IsFinite(vAngles[2]) && IsEntityQAngleReasonable( vAngles ) ) &&
				  ( IsFinite( flForwardmove ) && IsEntityCoordinateReasonable( flForwardmove ) ) &&
				  ( IsFinite( flSidemove ) && IsEntityCoordinateReasonable( flSidemove ) ) &&
				  ( IsFinite( flUpmove ) && IsEntityCoordinateReasonable( flUpmove ) );

	return bValid;
}

bool IsEntityCoordinateReasonable ( const float c )
{
	float r = g_flMaxEntityPosCoord;
	return c > -r && c < r;
}

bool IsEntityQAngleReasonable( const float q[3] )
{
	float r = g_flMaxEntityEulerAngle;
	return
		q[0] > -r && q[0] < r &&
		q[1] > -r && q[1] < r &&
		q[2] > -r && q[2] < r;
}

int Max (int left, int right) { return left > right ? left : right; }

public void OnLibraryAdded (const char[] name) { if ( strcmp(name, "smac") == 0 ) g_bSMAC = true; }
public void OnLibraryRemoved (const char[] name) { if ( strcmp(name, "smac") == 0 ) g_bSMAC = false; }

/* Some notes:
	
	Maybe in future i will add tickbase shifting check to be actually sure in someone cheats.
	if player using invalid commands and have rounded or fixed dropped_packets. I am pretty much sure he is cheating.
	g_iIgnoredCommands here is only for remove false positive results. Since when map changes server tickbase also changes but client sided doesnt and becomes synced with server only on second tick
	Perhaps for an additional check, I can add check for the number of commands sent and if they differ from the expected value then player possibly cheating or have a bad performance.
	
	⠄⠄⠄⠄⠄⡇⠄⠄⠄⠄⠄⢠⡀⠄⠄⢀⡬⠛⠁⠄⠄⠄⠄⠄⠄⠄⠉⠻⣿⣿⣿⣽⣿⣿⣿⣿⣿⣿⣿⣿⣧⠄⠄⠙⢦
	⠄⠄⠄⠄⠄⡇⠄⠄⠄⠄⢰⠼⠙⢀⡴⠋⠄⠄⠄⠄⠄⠄⠄⠄⠄⡠⠖⠄⠄⠙⠿⢿⣿⣿⣿⣿⣿⣿⣿⣿⣯⣀⡀⠄⠄⠄⡀
	⠄⠄⠄⠄⠄⡇⠄⠄⠄⠄⠄⠄⡴⠋⠄⠄⠄⠄⠄⠄⠄⠄⠄⢠⠞⠄⠄⠄⠄⠄⠄⠄⠄⠄⠉⠉⠉⠙⠋⠙⠋⠙⠻⠦⠤⣤⣼⣆⣀⣀⣀⣀⡀
	⠄⠄⠄⠄⠄⢷⠄⠄⠄⠄⢠⠞⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⡰⠃⡄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠉⠉⠉
	⠄⠄⠄⠄⠄⢸⡀⠄⠄⢠⠏⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⣰⠁⣸⠁⠄⠄⠄⠄⠄⠄⠄⠄⢀⠄⠄⡄
	⠄⠄⠄⠄⠄⢀⣧⠄⢠⠏⠄⠄⠄⠄⠄⠄⠄⠄⠄⢀⢾⠃⡜⡿⠄⠄⠄⠄⠄⠄⠄⠄⣠⠋⢀⣼⠁⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠸⢾⣀⣠
	⠄⠄⠄⢀⣠⢌⣦⢀⡏⠄⡄⠄⠄⢠⠃⠄⠄⠐⣶⡁⡞⡼⠄⣇⠄⠄⠄⠄⠄⠄⠄⡴⠁⢠⠎⢸⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⢈⠝⠁
	⠄⢀⠞⠉⠄⠄⠹⡼⠄⣼⠁⠄⠄⡏⠄⠄⢀⡞⠄⠈⣷⠇⠄⢻⠄⠄⠄⠄⠄⢐⣞⣀⣰⣃⣀⣸⠄⢀⠇⠄⠄⠄⠄⠄⠄⠄⠄⠄⠁⠄⠄⠄⠄⠄⢀
	⢰⠋⠄⠄⠄⠄⢀⡇⢠⡏⠄⠄⢸⠄⠄⢀⠎⠄⠄⠄⡇⠄⠄⢸⡀⠄⠄⠄⢠⢾⢁⡜⠁⠄⠄⢸⠄⣸⠄⠄⠄⠄⠄⠄⡀⠄⠄⠄⠄⠄⠄⠄⢀⡴⠃
	⡞⠄⠄⠄⠄⠄⢸⠄⡞⡷⠄⠄⡟⠄⢘⡟⠛⠷⠶⣤⣅⠄⠄⠄⣇⠄⠄⢠⠋⡧⠊⠄⠄⠄⠄⢸⢀⠇⠄⠄⠄⠄⠄⢰⠁⠄⠄⠄⠄⠄⢀⡴⠋
	⢹⠄⠄⠄⠄⠄⡾⢰⠃⡇⠄⠄⡇⠄⡜⢀⣠⣤⠶⠞⠛⠁⠄⠄⠘⡄⡰⠃⠘⠱⣾⣟⡛⠛⠛⠛⡟⠂⠄⠄⠄⠄⠄⡎⠄⠄⠄⠄⣀⠴⡋
	⠈⢳⠄⠄⠄⠄⡇⡼⠄⢻⠄⢠⡇⢸⠁⠈⠁⠄⠄⠄⠄⠄⠄⠄⠄⠈⠁⠄⠄⠄⠄⠙⠿⣶⣄⡰⠇⠄⠄⠄⠄⠄⡼⠄⠄⠄⡠⢾⣿⣆⢳
	⣀⣬⠿⠷⠦⠤⣷⣇⡠⠾⡄⢸⣇⢸⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⢹⠛⠂⠄⠄⠄⠄⣰⠁⠄⣀⣬⣷⠞⠛⠙⠛⢧⣤⣀
	⠉⠄⠄⠄⠄⠄⢻⠄⠄⠄⢧⢸⢸⠘⡇⠄⠄⠄⠄⠄⠄⠄⠄⣠⠄⠄⠄⠄⠄⠄⠄⠄⠄⢠⠃⠄⠄⠄⠄⠄⣰⠃⣶⢉⠜⠋⠄⠄⠄⠄⠄⠄⠄⠈⢳
	⠄⠄⠄⢀⣤⡀⢸⠄⠄⠄⠈⢿⠄⠄⣿⣆⠄⠄⠄⠄⠄⠄⠄⡟⣧⠄⠄⠄⠄⠄⠄⠄⡴⠃⠄⠄⠄⡠⠊⡰⡗⠋⡰⡼⠃⠄⠄⠄⠄⠄⠄⠄⠄⠄⢨
	⠄⢀⡔⠉⠄⠙⢦⠄⠄⠄⠄⢸⡀⢰⡏⠈⠳⣄⠄⠄⠄⠄⠄⠉⠁⠄⠄⠄⠄⠄⢀⡞⠁⠄⢀⣤⠎⠄⡔⣡⠃⢰⡇⣹⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⢼
	⣰⠋⠄⢀⣴⣖⠒⠓⡆⠄⠄⠈⣇⣿⣿⠄⢸⠹⡷⢄⠄⠄⠄⠄⠄⠄⠄⠄⠄⣠⠋⠄⢀⣴⣿⠏⠠⠊⣴⡏⢠⢻⡇⢹⡆⠄⠄⠄⠄⠄⣷⠄⠄⣰⠋
	⡇⠄⣰⣿⣿⣿⠒⠋⣛⣄⠄⠄⣹⢸⠈⢧⠸⡄⠹⣄⠙⠶⢶⣶⣶⣶⣶⡶⢾⠃⠄⡴⢋⡾⠋⣀⡴⣞⡝⡰⠃⠄⡇⡸⠉⠳⣄⣀⣀⣀⣿⣦⠞⠁
	⢷⢰⣿⣿⣿⣿⠄⠈⠁⠈⡇⠄⡏⢸⠄⠈⠓⢧⣀⣈⣤⡤⠖⠛⠉⠁⠄⢡⠃⢠⡞⠓⠚⠓⠚⣳⡞⠈⠘⠁⠄⠄⢹⡇⠄⠄⠄⠈⠉⠁⠸⣷⣀⣀⣀
	⢸⣿⣿⣿⣿⣿⠄⣿⣁⠜⠁⢸⡇⢸⣄⣀⡀⠘⢦⡀⠄⠄⠄⠄⠄⠄⢀⠏⡴⡻⠄⠄⠄⠠⣎⠹⡄⠄⢀⣀⣤⣤⣀⠁⠄⠄⠄⠄⠄⠄⠄⠈⢻⣿⣿
	⢸⣿⣿⣿⣿⣿⡇⢸⠄⠄⢀⡴⡇⠈⡇⠈⣩⠗⠒⣵⠆⠄⠄⠄⠄⠄⢸⡞⢰⠃⢀⠄⣀⡰⠟⠒⠒⡿⠉⠄⠄⠄⠈⠑⣄⠄⠄⠄⠄⠄⠄⠄⠈⢿⣿
	⣿⣿⣿⣿⣿⣿⣷⠎⠄⢠⠏⠄⠹⣄⢣⢠⠃⠄⠄⢤⠤⠄⠄⠠⠤⢶⡏⠄⡎⢠⠞⠋⠁⠄⠄⠄⣸⠁⠄⠄⠄⠄⠄⠄⠈⣧⠄⠄⠄⠄⠄⠄⠄⠄⠻
	⣿⣿⣿⣿⣿⣿⣃⡀⢠⠏⠄⠄⠄⠄⣨⠇⠄⣠⠴⠚⠁⠄⠄⠄⠄⠈⡇⢰⠃⠄⠄⠄⠄⠄⠄⢰⠇⠄⠄⠄⠄⠄⠄⠄⠄⢹⡀
	⣿⣿⣿⣿⣿⡿⢉⣇⡎⠄⠄⠄⠄⢰⠇⠄⢨⠇⠄⠄⠄⠄⠄⠄⠄⠄⠘⢾⡀⠄⠄⠄⠄⠄⠄⡞⢀⠄⠄⠄⠄⠄⠄⠄⠄⢸⡇
	
*/