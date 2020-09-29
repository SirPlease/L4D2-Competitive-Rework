#define PLUGIN_VERSION		"1.0"
#define BUFFER_SIZE			8192

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>



public Plugin myinfo =
{
	name = "[L4D2] Script Command Swap - Mem Leak Fix",
	author = "SilverShot (Timocop's idea)",
	description = "Blocks the script command and replaces with a logic_script entity to execute the code instead.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=317128"
}

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
	CreateConVar("l4d2_script_cmd_swap_version", PLUGIN_VERSION, "Script Cmd Swap version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AddCommandListener(CmdScript, "script");
}

public Action CmdScript(int client, const char[] command, int arg)
{
	static char args[BUFFER_SIZE];
	GetCmdArgString(args, sizeof(args));
	L4D2_RunScript(args);
	return Plugin_Handled;
}

// Credit to Timocop on VScript function
/**
* Runs a single line of VScript code.
* NOTE: Dont use the "script" console command, it starts a new instance and leaks memory. Use this instead!
*
* @param sCode        The code to run.
* @noreturn
*/
stock void L4D2_RunScript(char[] sCode, any ...)
{
	static int iScriptLogic = INVALID_ENT_REFERENCE;
	if( iScriptLogic == INVALID_ENT_REFERENCE || !IsValidEntity(iScriptLogic) )
	{
		iScriptLogic = EntIndexToEntRef(CreateEntityByName("logic_script"));
		if( iScriptLogic == INVALID_ENT_REFERENCE || !IsValidEntity(iScriptLogic) )
			SetFailState("Could not create 'logic_script'");

		DispatchSpawn(iScriptLogic);
	}

	static char sBuffer[BUFFER_SIZE];
	VFormat(sBuffer, sizeof(sBuffer), sCode, 2);

	SetVariantString(sBuffer);
	AcceptEntityInput(iScriptLogic, "RunScriptCode");
}