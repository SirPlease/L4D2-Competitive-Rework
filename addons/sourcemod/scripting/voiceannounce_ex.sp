/*  VoiceAnnounceEx
 *
 *  Copyright (C) 2017-2020 Francisco 'Franc1sco' García
 * 
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option) 
 * any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT 
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with 
 * this program. If not, see http://www.gnu.org/licenses/.
 */
#include <sourcemod>
#include <sdktools>
#include <dhooks>
#include <voiceannounce_ex>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "2.3"

Handle g_hProcessVoice;
Handle g_hOnClientTalking;
Handle g_hOnClientTalkingEnd;
bool g_bLateLoad;

int g_iHookID[MAXPLAYERS+1] = { -1, ... };
Handle g_hClientMicTimers[MAXPLAYERS + 1];

bool g_bUseVoiceTransmit;
Handle g_hOnVoiceTransmit;

public Plugin myinfo = 
{
	name = "VoiceAnnounceEx",
	author = "Franc1sco franug, Mini and GoD-Tony",
	description = "Feature for developers to check/control client mic usage.",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/franug"
}


public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_bUseVoiceTransmit = (GetEngineVersion() == Engine_CSGO || GetEngineVersion() == Engine_Left4Dead || GetEngineVersion() == Engine_Left4Dead2 || GetEngineVersion() ==  Engine_Insurgency);
	
	CreateNative("IsClientSpeaking", Native_IsClientTalking);
	RegPluginLibrary("voiceannounce_ex");
	
	g_hOnClientTalking = CreateGlobalForward("OnClientSpeakingEx", ET_Ignore, Param_Cell);
	g_hOnClientTalkingEnd = CreateGlobalForward("OnClientSpeakingEnd", ET_Ignore, Param_Cell);
	
	g_bLateLoad = late;
	return APLRes_Success;
}

public int Native_IsClientTalking(Handle plugin, int numParams)
{
	int iClient = GetNativeCell(1);
	if (iClient > MaxClients || iClient <= 0)
		return ThrowNativeError(SP_ERROR_NATIVE, "Client is not valid.");
	
	else if (!IsClientInGame(iClient))
		return ThrowNativeError(SP_ERROR_NATIVE, "Client is not in-game.");
	
	else if (IsFakeClient(iClient))
		return ThrowNativeError(SP_ERROR_NATIVE, "Cannot do mic checks on fake clients.");

	return g_hClientMicTimers[iClient] != INVALID_HANDLE;
}

public void OnPluginStart()
{
	CreateConVar("voiceannounce_ex_version", PLUGIN_VERSION, "VoiceAnnounceEx version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	int offset;
	if (g_bUseVoiceTransmit)
	{
		offset = GameConfGetOffset(GetConfig(), "OnVoiceTransmit");
		if (offset == -1)
			SetFailState("Failed to get offset");
		
		g_hOnVoiceTransmit = DHookCreate(offset, HookType_Entity, ReturnType_Int, ThisPointer_CBaseEntity, CSGOVoicePost);
	}
	else
	{
		offset = GameConfGetOffset(GetConfig(), "CGameClient::ProcessVoiceData");
		g_hProcessVoice = DHookCreate(offset, HookType_Raw, ReturnType_Void, ThisPointer_Address, Hook_ProcessVoiceData);
		DHookAddParam(g_hProcessVoice, HookParamType_ObjectPtr);
	}

	if (g_bLateLoad)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i) || IsFakeClient(i))
				continue;
			
			OnClientPutInServer(i);
		}
	}
}

public void OnClientPutInServer(int iClient)
{
	if (IsFakeClient(iClient))
		return;
	
	if (g_bUseVoiceTransmit)
		DHookEntity(g_hOnVoiceTransmit, true, iClient);
	
	else
		g_iHookID[iClient] = DHookRaw(g_hProcessVoice, true, GetIMsgHandler(iClient));
	
	g_hClientMicTimers[iClient] = INVALID_HANDLE;
}

public void OnClientDisconnect(int iClient)
{
	if (IsFakeClient(iClient))
		return;
	
	if (g_bUseVoiceTransmit)
	{
		if (g_iHookID[iClient] != -1)
		{
			DHookRemoveHookID(g_iHookID[iClient]);
			g_iHookID[iClient] = -1;
		}
	}
	
	g_hClientMicTimers[iClient] = INVALID_HANDLE;
}

public MRESReturn Hook_ProcessVoiceData(Address pThis)
{
	Address pIClient = pThis - view_as<Address>(4);
	int iClient = view_as<int>(GetPlayerSlot(pIClient)) + 1;
	
	if (!IsClientConnected(iClient))
		return MRES_Ignored;
		
	if (g_hClientMicTimers[iClient] != INVALID_HANDLE)
		delete g_hClientMicTimers[iClient];
	
	g_hClientMicTimers[iClient] = CreateTimer(0.3, Timer_ClientMicUsage, GetClientUserId(iClient));

	Call_StartForward(g_hOnClientTalking);
	Call_PushCell(iClient);
	Call_Finish();
	
	return MRES_Ignored;
}

public MRESReturn CSGOVoicePost(int iClient, Handle hReturn, Handle hParams) 
{ 	
	if (g_hClientMicTimers[iClient] != INVALID_HANDLE)
		delete g_hClientMicTimers[iClient];
		
	g_hClientMicTimers[iClient] = CreateTimer(0.3, Timer_ClientMicUsage, GetClientUserId(iClient));

	Call_StartForward(g_hOnClientTalking);
	Call_PushCell(iClient);
	Call_Finish();
	
	return MRES_Ignored;
}  

public Action Timer_ClientMicUsage(Handle hTimer, int iUserid)
{
	int iClient = GetClientOfUserId(iUserid);
	if (!iClient)
		return;
	
	if (g_hClientMicTimers[iClient] != hTimer)
		return;
	
	g_hClientMicTimers[iClient] = INVALID_HANDLE;
	
	Call_StartForward(g_hOnClientTalkingEnd);
	Call_PushCell(iClient);
	Call_Finish();
}

/*
* Internal Functions
* Credits go to GoD-Tony
*/
stock Handle GetConfig()
{
	static Handle hGameConf = INVALID_HANDLE;
	if (hGameConf == INVALID_HANDLE)
		hGameConf = LoadGameConfigFile("voiceannounce_ex.games");
	
	return hGameConf;
}

stock Address GetBaseServer()
{
	static Address pBaseServer = Address_Null;
	if (pBaseServer == Address_Null)
		pBaseServer = GameConfGetAddress(GetConfig(), "CBaseServer");
	
	return pBaseServer;
}

stock Address GetIClient(int slot)
{
	static Handle hGetClient = INVALID_HANDLE;
	if (hGetClient == INVALID_HANDLE)
	{
		StartPrepSDKCall(SDKCall_Raw);
		PrepSDKCall_SetFromConf(GetConfig(), SDKConf_Virtual, "CBaseServer::GetClient");
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		hGetClient = EndPrepSDKCall();
	}
	
	return view_as<Address>(SDKCall(hGetClient, GetBaseServer(), slot));
}

stock any GetPlayerSlot(Address pIClient)
{
	static Handle hPlayerSlot = INVALID_HANDLE;
	if (hPlayerSlot == INVALID_HANDLE)
	{
		StartPrepSDKCall(SDKCall_Raw);
		PrepSDKCall_SetFromConf(GetConfig(), SDKConf_Virtual, "CBaseClient::GetPlayerSlot");
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		hPlayerSlot = EndPrepSDKCall();
	}
	
	return SDKCall(hPlayerSlot, pIClient);
}

stock Address GetIMsgHandler(int iClient)
{
	return GetIClient(iClient - 1) + view_as<Address>(4);
}