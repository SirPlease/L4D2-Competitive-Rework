#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#include <sourcescramble>

ArrayStack gStack;

public void OnPluginStart()
{
	gStack = new ArrayStack();
	
	GameData data = new GameData("l4d2_air_data"); Patch(data); delete data;
}

public void OnPluginEnd()
{
	MemoryPatch patch;
	
	while (!gStack.Empty)
	{
		patch = gStack.Pop();
		patch.Disable();
	}
}

void Patch (GameData data)
{
	static const char name[][] =
	{
		"charger",
		"zoom"
	};
	
	MemoryPatch patch;
	
	for (int i; i < sizeof name; i++)
	{
		patch = MemoryPatch.CreateFromConf(data, name[i]);
		
		if ( !patch )
		{
			LogMessage("Failed to create patch for \"%s\". Skiping...", name[i]);
			continue;
		}
		else if ( !patch.Validate() ) 
		{
			LogMessage("Failed to verify patch for \"%s\". Skiping...", name[i]);
			continue;
		}
		
		patch.Enable();
		gStack.Push(patch);
	}
}