#pragma semicolon 1

#include <sourcemod>
#include <left4dhooks>

new Handle:z_mob_spawn_max_size;

public Plugin:myinfo = 
{
    	name = "Boomer Horde Equalizer",
    	author = "Visor, Jacob",
    	version = "1.1",
    	description = "Fixes boomer hordes being different sizes based on wandering commons.",
	url = "https://github.com/Attano"
};

public OnPluginStart()
{
	z_mob_spawn_max_size = FindConVar("z_mob_spawn_max_size");
	
	PatchWanderersCheck(true);
}

public OnPluginEnd()
{
	PatchWanderersCheck(false);
}

public Action:L4D_OnSpawnITMob(&amount)
{
	amount = GetConVarInt(z_mob_spawn_max_size);
	return Plugin_Changed;
}

PatchWanderersCheck(bool:enable)
{
	new Handle:hGamedata = LoadGameConfigFile("boomer_horde_equalizer");
	new Address:pAddress;

	if (!hGamedata)
		SetFailState("Gamedata 'boomer_horde_equalizer.txt' missing or corrupt");

	pAddress = GameConfGetAddress(hGamedata, "OnCharacterVomitedUpon_Sig");
	if (!pAddress)
		SetFailState("Couldn't find the 'OnCharacterVomitedUpon_Sig' address");
		
	new iOffset = GameConfGetOffset(hGamedata, "WanderersCondition");
	
	new patchBytes[4] = {0x90, 0x90, 0x90, 0x90};
	new originalBytes[4] = {0x39, 0xF3, 0x7D, 0x13};

	if (LoadFromAddress(pAddress + Address:iOffset, NumberType_Int8) == (enable ? originalBytes[0] : patchBytes[0]))
	{
		for (new i = 0; i < sizeof(patchBytes); i++)
		{
			if (patchBytes[i] < 0) {
				break;
			}

			StoreToAddress(pAddress + Address:(iOffset + i), (enable ? patchBytes[i] : originalBytes[i]), NumberType_Int8);
			PrintToServer("Set %x@%i", (enable ? patchBytes[i] : originalBytes[i]), i);
		}
	}
	
	CloseHandle(hGamedata);
}
