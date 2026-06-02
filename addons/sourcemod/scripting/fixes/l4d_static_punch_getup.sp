#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sourcescramble>

#define PLUGIN_VERSION "1.0"

public Plugin myinfo = 
{
	name = "[L4D & 2] Static Punch Get-up",
	author = "Forgetest",
	description = "Fix punch get-up varying in length, along with flexible setting to it.",
	version = PLUGIN_VERSION,
	url = "https://github.com/Target5150/MoYu_Server_Stupid_Plugins"
};

#define GAMEDATA_FILE "l4d_static_punch_getup"
#define PATCH_IGNORE_BUTTONS "HandleActivity_PunchedByTank__ignore_buttons"
#define PATCH_EARLY_EXIT_PERCENT "HandleActivity_PunchedByTank__early_exit_percent"
#define OFFS_OPCODE_SIZE "early_exit_percent__opcode_size"

MemoryBlock g_memEarlyExitPercent;

public void OnPluginStart()
{
	GameData gd = new GameData(GAMEDATA_FILE);
	if (!gd)
		SetFailState("Missing gamedata \""...GAMEDATA_FILE..."\"");
	
	MemoryPatch hPatch = MemoryPatch.CreateFromConf(gd, PATCH_IGNORE_BUTTONS);
	if (!hPatch.Validate())
		SetFailState("Failed to validate \""...PATCH_IGNORE_BUTTONS..."\"");
	if (!hPatch.Enable())
		SetFailState("Failed to patch \""...PATCH_IGNORE_BUTTONS..."\"");
	
	hPatch = MemoryPatch.CreateFromConf(gd, PATCH_EARLY_EXIT_PERCENT);
	if (!hPatch.Validate())
		SetFailState("Failed to validate \""...PATCH_EARLY_EXIT_PERCENT..."\"");
	if (!hPatch.Enable())
		SetFailState("Failed to patch \""...PATCH_EARLY_EXIT_PERCENT..."\"");
	
	int offs = gd.GetOffset(OFFS_OPCODE_SIZE);
	if (offs == -1)
		SetFailState("Missing offset \""...OFFS_OPCODE_SIZE..."\"");
	
	g_memEarlyExitPercent = new MemoryBlock(4); // 32-bit pointer size
	StoreToAddress(hPatch.Address + view_as<Address>(offs), view_as<int>(g_memEarlyExitPercent.Address), NumberType_Int32);
	
	delete gd;
	
	ConVar cvar = CreateConVar("tank_punch_getup_scale",
								"0.5",
								"How many the length of landing get-up of tank punch is scaled.\n"\
							... "Range [0.01 - 0.99]",
								FCVAR_SPONLY,
								true, 0.01, true, 0.99);
	CvarChg_GetupScale(cvar, "", "");
	cvar.AddChangeHook(CvarChg_GetupScale);
}

void CvarChg_GetupScale(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_memEarlyExitPercent.StoreToOffset(0, view_as<int>(convar.FloatValue), NumberType_Int32);
}