#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <dhooks>

// int CBaseCombatCharacter::BloodColor(void)
DynamicHook hBloodColor;

// bool CBaseCombatCharacter::Weapon_CanUse(CBaseCombatWeapon *)
DynamicHook hHookCanUse;

// Vector CBasePlayer::GetPlayerMaxs()
DynamicHook hGetMaxs;

// string_t CBaseEntity::GetModelName(void)
DynamicHook hGetModelName;

// bool CGameRules::CanHaveAmmo(CBaseCombatCharacter *, int)
DynamicHook hCanHaveAmmo;

// void CBaseEntity::SetModel(char  const*)
DynamicHook hSetModel;

//float CCSPlayer::GetPlayerMaxSpeed()
DynamicHook hGetSpeed;

//int CCSPlayer::OnTakeDamage(CTakeDamageInfo const&)
DynamicHook hTakeDamage;

// bool CBaseEntity::AcceptInput(char  const*, CBaseEntity*, CBaseEntity*, variant_t, int)
DynamicHook hAcceptInput;

//int CBaseCombatCharacter::GiveAmmo(int, int, bool)
DynamicHook hGiveAmmo;

// CVEngineServer::ClientPrintf(edict_t *, char  const*)
DynamicHook hClientPrintf;

public void OnPluginStart()
{
	GameData temp = new GameData("dhooks-test.games");
	
	if(temp == INVALID_HANDLE)
	{
		SetFailState("Why you no has gamedata?");
	}
	
	int offset;
	
	offset = temp.GetOffset("BloodColor");
	hBloodColor = new DynamicHook(offset, HookType_Entity, ReturnType_Int, ThisPointer_CBaseEntity);
	
	offset = temp.GetOffset("GetModelName");
	hGetModelName = new DynamicHook(offset, HookType_Entity, ReturnType_String, ThisPointer_CBaseEntity);
	
	offset = temp.GetOffset("GetMaxs");
	hGetMaxs = new DynamicHook(offset, HookType_Entity, ReturnType_Vector, ThisPointer_Ignore);
	
	offset = temp.GetOffset("CanUse");
	hHookCanUse = new DynamicHook(offset, HookType_Entity, ReturnType_Bool, ThisPointer_CBaseEntity);
	hHookCanUse.AddParam(HookParamType_CBaseEntity);
	
	offset = temp.GetOffset("CanHaveAmmo");
	hCanHaveAmmo = new DynamicHook(offset, HookType_GameRules, ReturnType_Bool, ThisPointer_Ignore);
	hCanHaveAmmo.AddParam(HookParamType_CBaseEntity);
	hCanHaveAmmo.AddParam(HookParamType_Int);
	
	offset = temp.GetOffset("SetModel");
	hSetModel = new DynamicHook(offset, HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity);
	hSetModel.AddParam(HookParamType_CharPtr);
	
	offset = temp.GetOffset("AcceptInput");
	hAcceptInput = new DynamicHook(offset, HookType_Entity, ReturnType_Bool, ThisPointer_CBaseEntity);
	hAcceptInput.AddParam(HookParamType_CharPtr);
	hAcceptInput.AddParam(HookParamType_CBaseEntity);
	hAcceptInput.AddParam(HookParamType_CBaseEntity);
	hAcceptInput.AddParam(HookParamType_Object, 20, DHookPass_ByVal|DHookPass_ODTOR|DHookPass_OCTOR|DHookPass_OASSIGNOP); //variant_t is a union of 12 (float[3]) plus two int type params 12 + 8 = 20
	hAcceptInput.AddParam(HookParamType_Int);
		
	offset = temp.GetOffset("GetMaxPlayerSpeed");
	hGetSpeed = new DynamicHook(offset, HookType_Entity, ReturnType_Float, ThisPointer_CBaseEntity);
		
	offset = temp.GetOffset("GiveAmmo");
	hGiveAmmo = new DynamicHook(offset, HookType_Entity, ReturnType_Int, ThisPointer_CBaseEntity);
	hGiveAmmo.AddParam(HookParamType_Int);
	hGiveAmmo.AddParam(HookParamType_Int);
	hGiveAmmo.AddParam(HookParamType_Bool);
		
	offset = temp.GetOffset("OnTakeDamage");
	hTakeDamage = new DynamicHook(offset, HookType_Entity, ReturnType_Int, ThisPointer_CBaseEntity);
	hTakeDamage.AddParam(HookParamType_ObjectPtr, -1, DHookPass_ByRef);
	
	DHookAddEntityListener(ListenType_Created, EntityCreated);
	
	//Add client printf hook pThis requires effort
	StartPrepSDKCall(SDKCall_Static);
	if(!PrepSDKCall_SetFromConf(temp, SDKConf_Signature, "CreateInterface"))
	{
		SetFailState("Failed to get CreateInterface");
		CloseHandle(temp);
	}
	
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Pointer, VDECODE_FLAG_ALLOWNULL);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	
	char iface[64];
	if(!temp.GetKeyValue("EngineInterface", iface, sizeof(iface)))
	{
		SetFailState("Failed to get engine interface name");
		CloseHandle(temp);
	}
	
	Handle call = EndPrepSDKCall();
	Address addr = SDKCall(call, iface, 0);
	CloseHandle(call);
	
	if(!addr)
	{
		SetFailState("Failed to get engine ptr");
	}
	
	offset = GameConfGetOffset(temp, "ClientPrintf");
	hClientPrintf = new DynamicHook(offset, HookType_Raw, ReturnType_Void, ThisPointer_Ignore);
	hClientPrintf.AddParam(HookParamType_Edict);
	hClientPrintf.AddParam(HookParamType_CharPtr);
	hClientPrintf.HookRaw(Hook_Pre, addr, Hook_ClientPrintf);
	
	delete temp;
}

public MRESReturn Hook_ClientPrintf(DHookParam hParams)
{
	int client = hParams.Get(1);
	char buffer[1024];
	hParams.GetString(2, buffer, sizeof(buffer));
	PrintToChat(client, "BUFFER %s", buffer);
	return MRES_Ignored;
}

public MRESReturn AcceptInput(int pThis, DHookReturn hReturn, DHookParam hParams)
{
	char command[128];
	hParams.GetString(1, command, sizeof(command));
	int type = hParams.GetObjectVar(4, 16, ObjectValueType_Int);
	char wtf[128];
	hParams.GetObjectVarString(4, 0, ObjectValueType_String, wtf, sizeof(wtf));
	PrintToServer("Command %s Type %i String %s", command, type, wtf);
	hReturn.Value = false;
	return MRES_Supercede;
}

public void OnMapStart()
{
	//Hook Gamerules function in map start
	hCanHaveAmmo.HookGamerules(Hook_Post, CanHaveAmmoPost, RemovalCB);
}

public void OnClientPutInServer(int client)
{
	hSetModel.HookEntity(Hook_Pre, client, SetModel, RemovalCB);
	hHookCanUse.HookEntity(Hook_Post, client, CanUsePost, RemovalCB);
	hGetSpeed.HookEntity(Hook_Post, client, GetMaxPlayerSpeedPost, RemovalCB);
	hGiveAmmo.HookEntity(Hook_Pre, client, GiveAmmo);
	hGetModelName.HookEntity(Hook_Post, client, GetModelName);
	hTakeDamage.HookEntity(Hook_Pre, client, OnTakeDamage);
	hGetMaxs.HookEntity(Hook_Post, client, GetMaxsPost);
	hBloodColor.HookEntity(Hook_Post, client, BloodColorPost);
}

public void EntityCreated(int entity, const char[] classname)
{
	if(strcmp(classname, "point_servercommand") == 0)
	{
		hAcceptInput.HookEntity(Hook_Pre, entity, AcceptInput);
	}
}

//int CCSPlayer::OnTakeDamage(CTakeDamageInfo const&)
public MRESReturn OnTakeDamage(int pThis, DHookReturn hReturn, DHookParam hParams)
{
	PrintToServer("DHooksHacks = Victim %i, Attacker %i, Inflictor %i, Damage %f", pThis, hParams.GetObjectVar(1, 40, ObjectValueType_Ehandle), hParams.GetObjectVar(1, 36, ObjectValueType_Ehandle), hParams.GetObjectVar(1, 48, ObjectValueType_Float));
	
	if(pThis <= MaxClients && pThis > 0 && !IsFakeClient(pThis))
	{
		hParams.SetObjectVar(1, 48, ObjectValueType_Float, 0.0);
		PrintToChat(pThis, "Pimping your hp");
	}
}

// int CBaseCombatCharacter::GiveAmmo(int, int, bool)
public MRESReturn GiveAmmo(int pThis, DHookReturn hReturn, DHookParam hParams)
{
	PrintToChat(pThis, "Giving %i of %i supress %i", hParams.Get(1), hParams.Get(2), hParams.Get(3));
	return MRES_Ignored;
}

// void CBaseEntity::SetModel(char  const*)
public MRESReturn SetModel(int pThis, DHookParam hParams)
{
	//Change all bot skins to phoenix one
	if(IsFakeClient(pThis))
	{
		hParams.SetString(1, "models/player/t_phoenix.mdl");
		return MRES_ChangedHandled;
	}
	return MRES_Ignored;
}

//float CCSPlayer::GetPlayerMaxSpeed()
public MRESReturn GetMaxPlayerSpeedPost(int pThis, DHookReturn hReturn)
{
	//Make bots slow
	if(IsFakeClient(pThis))
	{
		hReturn.Value = 100.0;
		return MRES_Override;
	}
	return MRES_Ignored;
}

// bool CGameRules::CanHaveAmmo(CBaseCombatCharacter *, int)
public MRESReturn CanHaveAmmoPost(DHookReturn hReturn, DHookParam hParams)
{
	PrintToServer("Can has ammo? %s %i", hReturn.Value?"true":"false", hParams.Get(2));
	return MRES_Ignored;
}

// string_t CBaseEntity::GetModelName(void)
public MRESReturn GetModelName(int pThis, DHookReturn hReturn)
{
	char returnval[128];
	hReturn.GetString(returnval, sizeof(returnval));
	
	if(IsFakeClient(pThis))
	{
		PrintToServer("It is a bot, Model should be: models/player/t_phoenix.mdl It is %s", returnval);
	}
	
	return MRES_Ignored;
}

// Vector CBasePlayer::GetPlayerMaxs()
public MRESReturn GetMaxsPost(DHookReturn hReturn)
{
	float vec[3];
	hReturn.GetVector(vec);
	PrintToServer("Get maxes %.3f, %.3f, %.3f", vec[0], vec[1], vec[2]);
	
	return MRES_Ignored;
}

// bool CBaseCombatCharacter::Weapon_CanUse(CBaseCombatWeapon *)
public MRESReturn CanUsePost(int pThis, DHookReturn hReturn, DHookParam hParams)
{
	//Bots get nothing.
	if(IsFakeClient(pThis))
	{
		hReturn.Value = false;
		return MRES_Override;
	}
	return MRES_Ignored;
}

// int CBaseCombatCharacter::BloodColor(void)
public MRESReturn BloodColorPost(int pThis, DHookReturn hReturn)
{
	//Change the bots blood color to goldish yellow
	if(IsFakeClient(pThis))
	{
		hReturn.Value = 2;
		return MRES_Supercede;
	}
	return MRES_Ignored;
}

public void RemovalCB(int hookid)
{
	PrintToServer("Removed hook %i", hookid);
}
