#pragma semicolon 1

#include <sourcemod>

public Plugin:myinfo =
{
	name = "L4D2 Tank Claw Fix",
	author = "Jahze(patch data) & Visor(SM)",
	description = "Removes the Tank claw's undocumented auto-aiming ability",
	version = "0.1",
	url = ""
}

public OnPluginStart()
{
	new Handle:hGamedata = LoadGameConfigFile("l4d2_notankautoaim");
	new Address:pAddress;

	if (!hGamedata)
		SetFailState("Gamedata 'l4d2_notankautoaim.txt' missing or corrupt");

	pAddress = GameConfGetAddress(hGamedata, "OnWindupFinished_Sig");
	if (!pAddress)
		SetFailState("Couldn't find the 'OnWindupFinished_Sig' address");
		
	new bool:bIsWin = (GameConfGetOffset(hGamedata, "Platform") == 1);
	new iOffset = GameConfGetOffset(hGamedata, "ClawTargetScan");
	
	new offsetCheck[2];
	new patchBytes[3];
	if (bIsWin)
	{
		offsetCheck = {0x83, 0xEC};
		patchBytes = {0xEB, 0x29, -1};
	}
	else
	{
		offsetCheck = {0x0F, 0x84};
		patchBytes = {0xE9, 0x8B, 0x00};
	}
	
	if (LoadFromAddress(pAddress + Address:iOffset, NumberType_Int8) == offsetCheck[0]
	&& LoadFromAddress(pAddress + Address:(iOffset + 1), NumberType_Int8) == offsetCheck[1])
	{
		for (new i = 0; i < sizeof(patchBytes); i++)
		{
			if (patchBytes[i] < 0) {
				break;
			}

			StoreToAddress(pAddress + Address:(iOffset + i), patchBytes[i], NumberType_Int8);
			PrintToServer("Set %x@%i", patchBytes[i], i);
		}
	}
	
	CloseHandle(hGamedata);
}