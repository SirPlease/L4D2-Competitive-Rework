#pragma semicolon 1
#pragma newdecls required //強制1.7以後的新語法
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <basecomm>
#include <ThirdPersonShoulder_Detect>
#include <left4dhooks>

#define PLUGIN_VERSION "1.9"
#define CVAR_FLAGS	FCVAR_NOTIFY

#define UPDATESPEAKING_TIME_INTERVAL 0.5
#define Model_Head "models/extras/info_speech.mdl"

int g_iHatIndex[MAXPLAYERS+1];			// Player hat entity reference
bool ClientSpeakingTime[MAXPLAYERS+1];
bool g_bExternalCvar[MAXPLAYERS+1];		// If thirdperson view was detected (thirdperson_shoulder cvar)
bool g_bExternalState[MAXPLAYERS+1];	// If thirdperson view was detected
char SpeakingPlayers[512], SpeakingInfectedPlayers[512], SpeakingSurvivorPlayers[512], SpeakingSpectatorPlayers[512];
ConVar hSV_Alltalk;
ConVar hSV_VoiceEnable;
ConVar g_hCvarHatEnable, g_hCvarAnnounceEnable;
int iSV_Alltalk;
bool bSV_VoiceEnable, g_bCvarHatEnable, g_bCvarAnnounceEnable;

public Plugin myinfo = 
{
	name = "[L4D2] Voice Announce + Show MIC Hat.",
	author = "SupermenCJ & Harry Potter ",
	description = "Voice Announce in centr text + create hat to Show Who is speaking.",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/profiles/76561198026784913"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) 
{
	EngineVersion test = GetEngineVersion();
	
	if( test != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}
	
	return APLRes_Success; 
}


public void OnPluginStart()
{
	LoadTranslations("show_mic.phrases");
	
	hSV_Alltalk = FindConVar("sv_alltalk");
	hSV_VoiceEnable = FindConVar("sv_voiceenable");

	g_hCvarHatEnable = 	CreateConVar( 		"show_mic_center_hat_enable", "1", 		"If 1, display hat on player's head if player is speaking", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hCvarAnnounceEnable = CreateConVar( 	"show_mic_center_text_enable", "1", 	"If 1, display player speaking message in center text", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	CreateConVar(						 	"show_mic_version",		PLUGIN_VERSION,	"Show Mic plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true, "show_mic");

	GetCvars();
	g_hCvarHatEnable.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarAnnounceEnable.AddChangeHook(ConVarChanged_Cvars);
	hSV_Alltalk.AddChangeHook(ConVarChanged_Cvars);
	hSV_VoiceEnable.AddChangeHook(ConVarChanged_Cvars);
	
	HookEvent("round_end", 			Event_RoundEnd);
	HookEvent("player_death", 		Event_PlayerDeath);
	HookEvent("player_team",		Event_PlayerTeam);
	
	CreateTimer(UPDATESPEAKING_TIME_INTERVAL, Timer_UpdateSpeaking, _, TIMER_REPEAT);
}

public void ConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_bCvarHatEnable = g_hCvarHatEnable.BoolValue;
	g_bCvarAnnounceEnable = g_hCvarAnnounceEnable.BoolValue;
	iSV_Alltalk = hSV_Alltalk.IntValue;
	bSV_VoiceEnable = hSV_VoiceEnable.BoolValue;
}

public void OnPluginEnd()
{
	for( int i = 1; i <= MaxClients; i++ )
		RemoveHat(i);
}

public void OnMapStart()
{
	PrecacheModel(Model_Head, true);
}

public void OnClientDisconnect(int client)
{
	ClientSpeakingTime[client] = false;
	RemoveHat(client);
}

public void OnClientSpeaking(int client)
{
	if (!IsClientInGame(client) || IsFakeClient(client)) return;

	if (bSV_VoiceEnable == false
		|| BaseComm_IsClientMuted(client) 
		|| GetClientListeningFlags(client) == 1)
	{
		RemoveHat(client);
		ClientSpeakingTime[client] = false;
		
		return;
	}
	
	if (g_bCvarHatEnable == false || GetClientTeam(client) != 2 || !IsPlayerAlive(client))
	{
		RemoveHat(client);
	}
	else
	{
		CreateHat(client);
	}

	ClientSpeakingTime[client] = true;
}

public void OnClientSpeakingEnd(int client)
{
	RemoveHat(client);
	ClientSpeakingTime[client] = false;
}

public Action Timer_UpdateSpeaking(Handle timer)
{
	if(g_bCvarAnnounceEnable == false) return Plugin_Continue;

	if(iSV_Alltalk == 1)
	{
		int iCount = 0;
		SpeakingPlayers[0] = '\0';

		for (int i = 1; i <= MaxClients; i++)
		{
			if (ClientSpeakingTime[i] && IsClientInGame(i) && !IsFakeClient(i))
			{
				Format(SpeakingPlayers, sizeof(SpeakingPlayers), "%s%N\n", SpeakingPlayers, i);
				iCount++;
			}
		}

		if (iCount > 0)
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i) && !IsFakeClient(i))
				{
					SetGlobalTransTarget(i);
					PrintCenterText(i, "%T\n%s", "Players Speaking:", i, SpeakingPlayers);
				}
			}
		}
	}
	else
	{
		int sur = 0, inf = 0, spec = 0, iCount = 0, team;
		SpeakingSurvivorPlayers[0] = '\0';
		SpeakingInfectedPlayers[0] = '\0';
		SpeakingSpectatorPlayers[0] = '\0';
		SpeakingPlayers[0] = '\0';

		for (int i = 1; i <= MaxClients; i++)
		{
			if (ClientSpeakingTime[i] && IsClientInGame(i) && !IsFakeClient(i))
			{
				team = GetClientTeam(i);
				if(team == 2)
				{
					Format(SpeakingSurvivorPlayers, sizeof(SpeakingSurvivorPlayers), "%s%N\n", SpeakingSurvivorPlayers, i);
					sur++;
				}
				else if(team == 3)
				{
					Format(SpeakingInfectedPlayers, sizeof(SpeakingInfectedPlayers), "%s%N\n", SpeakingInfectedPlayers, i);
					inf++;
				}
				else if(team == 1)
				{
					Format(SpeakingSpectatorPlayers, sizeof(SpeakingSpectatorPlayers), "%s%N\n", SpeakingSpectatorPlayers, i);
					spec++;
				}

				Format(SpeakingPlayers, sizeof(SpeakingPlayers), "%s%N\n", SpeakingPlayers, i);
				iCount++;
			}
		}

		if(iCount > 0)
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i) && !IsFakeClient(i))
				{
					if(GetClientListeningFlags(i) == VOICE_LISTENALL)
					{
						SetGlobalTransTarget(i);
						PrintCenterText(i, "%T\n%s", "Players Speaking:", i, SpeakingPlayers);
						continue;
					}

					team = GetClientTeam(i);
					if(team == 2 && sur > 0)
					{
						SetGlobalTransTarget(i);
						PrintCenterText(i, "%T\n%s", "Players Speaking:", i, SpeakingSurvivorPlayers);
					}
					else if(team == 3 && inf > 0)
					{
						SetGlobalTransTarget(i);
						PrintCenterText(i, "%T\n%s", "Players Speaking:", i, SpeakingInfectedPlayers);
					}
					else if(team == 1 && spec > 0)
					{
						SetGlobalTransTarget(i);
						PrintCenterText(i, "%T\n%s", "Players Speaking:", i, SpeakingSpectatorPlayers);
					}
				}
			}
		}
	}

	return Plugin_Continue;
}

void CreateHat(int client)
{
	if (IsValidEntRef(g_iHatIndex[client]) == true)
	{
		return;
	}
	
	float g_vAng[3];
	float g_vPos[3];
	g_vAng[0] = 0.0;
	g_vAng[1] = 0.0;
	g_vAng[2] = 0.0;
	g_vPos[0] = -3.5;
	g_vPos[1] = 0.0;
	g_vPos[2] = 18.5;
	
	int entity = CreateEntityByName("prop_dynamic_override");
	if( entity != -1 )
	{
		SetEntityModel(entity, Model_Head);
		DispatchSpawn(entity);
		SetEntPropFloat(entity, Prop_Send, "m_flModelScale", 0.6, 0);
		SetVariantString("!activator");
		AcceptEntityInput(entity, "SetParent", client);
		SetVariantString("eyes");
		AcceptEntityInput(entity, "SetParentAttachment");
		
		// Lux
		AcceptEntityInput(entity, "DisableCollision");
		SetEntProp(entity, Prop_Send, "m_noGhostCollision", 1, 1);
		SetEntProp(entity, Prop_Data, "m_CollisionGroup", 0x0004);
		SetEntPropVector(entity, Prop_Send, "m_vecMins", view_as<float>({0.0, 0.0, 0.0}));
		SetEntPropVector(entity, Prop_Send, "m_vecMaxs", view_as<float>({0.0, 0.0, 0.0}));
		// Lux
		
		TeleportEntity(entity, g_vPos, g_vAng, NULL_VECTOR);
		SetEntProp(entity, Prop_Data, "m_iEFlags", 0);
		
		SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
		SetEntityRenderColor(entity, 255, 255, 255, 100);

		L4D2_SetEntityGlow(entity, L4D2Glow_Constant, 2000, 1, {200, 200, 200}, false);
		
		g_iHatIndex[client] = EntIndexToEntRef(entity);
		SDKHook(entity, SDKHook_SetTransmit, Hook_SetTransmit);
	}
}

void RemoveHat(int client)
{
	int entity = g_iHatIndex[client];
	g_iHatIndex[client] = 0;

	if( IsValidEntRef(entity) )
		AcceptEntityInput(entity, "kill");
}

public Action Hook_SetTransmit(int entity, int client)
{
	if( EntIndexToEntRef(entity) == g_iHatIndex[client] && g_bExternalCvar[client] == false ) //自己
		return Plugin_Handled;
		
	if(iSV_Alltalk == 0)
	{
		if( GetClientListeningFlags(client) == VOICE_LISTENALL ) return Plugin_Continue;
		if( GetClientTeam(client) != 2 ) return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public void TP_OnThirdPersonChanged(int client, bool bIsThirdPerson)
{
	if( bIsThirdPerson == true && g_bExternalCvar[client] == false )
	{
		g_bExternalCvar[client] = true;
		SetHatView(client, true);
	}
	else if( bIsThirdPerson == false && g_bExternalCvar[client] == true )
	{
		g_bExternalCvar[client] = false;
		SetHatView(client, false);
	}
}

void SetHatView(int client, bool bIsThirdPerson)
{
	if( bIsThirdPerson && !g_bExternalState[client] )
	{
		g_bExternalState[client] = true;

		int entity = g_iHatIndex[client];
		if( entity && (entity = EntRefToEntIndex(entity)) != INVALID_ENT_REFERENCE )
			SDKUnhook(entity, SDKHook_SetTransmit, Hook_SetTransmit);
	}
	else if( !bIsThirdPerson && g_bExternalState[client] )
	{
		g_bExternalState[client] = false;

		int entity = g_iHatIndex[client];
		if( entity && (entity = EntRefToEntIndex(entity)) != INVALID_ENT_REFERENCE )
			SDKHook(entity, SDKHook_SetTransmit, Hook_SetTransmit);
	}
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	for( int i = 1; i <= MaxClients; i++ )
		RemoveHat(i);
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	RemoveHat(client);
}

public void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	RemoveHat(client);
}

bool IsValidEntRef(int entity)
{
	if( entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE )
		return true;
	return false;
}