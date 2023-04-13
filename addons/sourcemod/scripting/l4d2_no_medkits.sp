#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

public Plugin:myinfo = 
{
	name = "[L4D2] No Medkits",
	author = "Altair Sossai",
	description = "Removes all medkits from the map",
	version = "1.0.0",
	url = "https://github.com/altair-sossai/l4d2-zone-server"
}

public void OnRoundIsLive()
{
    RemoveAllMedKits();
}

public RemoveAllMedKits()
{
	new entityCount = GetEntityCount()
	new String:className[128]
	
	for (new i = 0; i <= entityCount; i++)
	{
		if (!IsValidEntity(i))
			continue;
		
		GetEdictClassname(i, className, sizeof(className))

		if (StrContains(className, "weapon_first_aid_kit", false) != -1)
			AcceptEntityInput(i, "Kill");
	}
}
