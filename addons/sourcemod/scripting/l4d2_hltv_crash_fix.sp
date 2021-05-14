#include <sourcemod>

public Plugin myinfo =
{
    name = "L4D2 HLTV Crash Exploit Fix",
    author = "backwards, ProdigySim",
    description = "Prevents Exploit That Crashes Servers",
    version = "1.1",
    url = "http://steamcommunity.com/id/mypassword"
};

public OnPluginStart()
{
	if (GetEngineVersion() != Engine_Left4Dead2)
		SetFailState("This plugin is only for L4D2!");
		
	Handle config = LoadGameConfigFile("l4d2_hltv_crash_fix");
	Address addy = GameConfGetAddress(config, "ProcessClientInfo");
	int offset = GameConfGetOffset(config, "hltv_write");

	if (addy != Address_Null && offset > 0)
	{
		static int patch[] = {
			0x31, 0xC0, // xor eax, eax
			0x66, 0x90  // 66 NOP (two byte nop)
		};
		for(int i = 0;i<4;i++)
		{
			StoreToAddress(addy + view_as<Address>(offset) + view_as<Address>(i), patch[i], NumberType_Int8);
		}
	}
	else
		SetFailState("HLTV Crash Fix Signature Incorrect.");
}
