#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#include <sourcescramble>

public Plugin myinfo =
{
    name = "[L4D2] Boomer Ladder Fix",
    author = "BHaType"
};

MemoryPatch gLadderPatch;

public void OnPluginStart()
{
	GameData data = new GameData("l4d2_boomer_ladder_fix");
	
	gLadderPatch = MemoryPatch.CreateFromConf(data, "CTerrorGameMovement::CheckForLadders");
	
	delete data;
	
	Patch(true);
}

void Patch( int state )
{
	static bool set;
	
	if ( state == 3 )
	{
		state = !set;
	}
	
	if ( set && !state )
	{
		gLadderPatch.Disable();
		set = false;
	}
	else if ( !set && state )
	{
		gLadderPatch.Enable();
		set = true;
	}
}