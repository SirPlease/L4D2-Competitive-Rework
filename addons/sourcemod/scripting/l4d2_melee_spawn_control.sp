/*====================================================
1.3
	- Fixed the meleeweapons list if some 3rd party map mission do not declare the "meleeweapons".
	- Save the initial meleeweapons list. After changing the new mission, the "meleeweapons" will be restored and redeclared.

1.2
	- Fixed didn't take effect in time if added Cvars to server.cfg. Thanks to "Target_7" for reporting.

1.1
	- Fixed broken windows signatures.
	- Not forces map to reload any more.
	- Thanks to "Silvers" for reporting and help.

1.0
	- Initial release
======================================================*/
#pragma newdecls required

#include <sdktools>
#include <dhooks>
#include <sourcemod>

Handle hKvGetString, hKvSetString, hKvFindKey
Handle hCvarMeleeSpawn, hCvarAddMelee
StringMap hMapInitMelee

public Plugin myinfo=
{
	name = "l4d2 melee spawn control",
	author = "IA/NanaNana",
	description = "Unlock melee weapons",
	version = "1.3",
	url = "http://forums.alliedmods.net/showthread.php?t=327605"
}

public void OnPluginStart()
{
	Handle h = LoadGameConfigFile("l4d2_melee_spawn_control")
	if(!h) SetFailState("Could not find gamedata \"l4d2_melee_spawn_control.txt\"");
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(h, SDKConf_Signature, "KeyValues::GetString");
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_String, SDKPass_Pointer);
	if(!(hKvGetString = EndPrepSDKCall())) SetFailState("KeyValues::GetString sig invalid.");
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(h, SDKConf_Signature, "KeyValues::SetString");
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	if(!(hKvSetString = EndPrepSDKCall())) SetFailState("KeyValues::SetString sig invalid.");
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(h, SDKConf_Signature, "KeyValues::FindKey");
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	if(!(hKvFindKey = EndPrepSDKCall())) SetFailState("KeyValues::FindKey sig invalid.");

	DHookEnableDetour(DHookCreateFromConf(h, "OnGetMissionInfo"), true, DH_OnGetMissionInfo)

	hMapInitMelee = new StringMap()

	CloseHandle(h)
	hCvarMeleeSpawn = CreateConVar("l4d2_melee_spawn", "", "Melee weapon list for unlock, use ',' to separate between names, e.g: pitchfork,shovel. Empty for no change");
	hCvarAddMelee = CreateConVar("l4d2_add_melee", "", "Add melee weapons to map basis melee spawn or l4d2_melee_spawn, use ',' to separate between names. Empty for don't add");
}

public MRESReturn DH_OnGetMissionInfo(Handle hReturn)
{
	if(GetGameTime() > 5.0) return
	char t[255], s[255], f[255], m[64]
	int i = DHookGetReturn(hReturn)
	GetConVarString(FindConVar("mp_gamemode"), m, 64)
	SDKCall(hKvGetString, SDKCall(hKvFindKey, SDKCall(hKvFindKey, SDKCall(hKvFindKey, i, "modes", false), m, false), "1", false), m, 64, "Map", "N/A");
	if(!hMapInitMelee.GetString(m, t, 255))
	{
		SDKCall(hKvGetString, i, t, 255, "meleeweapons", "");
		if(!t[0])
		{
			t = "fireaxe;frying_pan;machete;baseball_bat;crowbar;cricket_bat;tonfa;katana;electric_guitar;knife;riotshield;golfclub;shovel;pitchfork"
			SDKCall(hKvSetString, i, "meleeweapons", t);
		}
		if(!StrEqual(m, "N/A")) hMapInitMelee.SetString(m, t, false)
	}
	GetConVarString(hCvarMeleeSpawn, s, 255)
	GetConVarString(hCvarAddMelee, f, 255)
	ReplaceString(s, 255, " ", "")
	ReplaceString(f, 255, " ", "")
	if(!s[0] && !f[0])
	{
		SDKCall(hKvGetString, i, s, 255, "meleeweapons", "");
		if(!StrEqual(s, t)) SDKCall(hKvSetString, i, "meleeweapons", t);
		return
	}
	ReplaceString(t, 255, ";", ",")
	if(!s[0]) s = t
	char sOriginal[32][40], sAdded[32][40]
	ExplodeString(s, ",", sOriginal, sizeof(sOriginal) , sizeof(sOriginal[]))
	ExplodeString(f, ",", sAdded, sizeof(sOriginal) , sizeof(sOriginal[]))
	int j, l
	for(j = 0;j<32;j++)
	{
		for(l = 0;l<32;l++)
		{
			if(StrEqual(sOriginal[j], sAdded[l], false)) sAdded[l] = ""
		}
	}
	for(l = 0;l<32;l++)
	{
		if(sAdded[l][0] != 0) Format(s, 255, "%s,%s", s,sAdded[l])
	}
	if(StrEqual(s, t)) return // If melee spawn setting same as the mission info, then return
	ReplaceString(s, 255, ",", ";")
	SDKCall(hKvSetString, i, "meleeweapons", s);
}