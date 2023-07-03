#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

public Plugin myinfo =
{
	name = "[L4D & L4D2] witch smart attack behind",
	author = "HarryPotter",
	description = "The witch turns back if nearby survivor scares her behind",
	version = "1.2",
	url = "https://steamcommunity.com/id/TIGER_x_DRAGON/"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) 
{
	EngineVersion test = GetEngineVersion();
	
	if( test != Engine_Left4Dead && test != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	
	return APLRes_Success; 
}

ConVar witch_target_override_on;
bool witch_target_override_on_value = false;
public void OnAllPluginsLoaded()
{
	// Use Witch Target Override: https://github.com/fbef0102/L4D1_2-Plugins/tree/master/witch_target_override
	witch_target_override_on = FindConVar("witch_target_override_on");
	if(witch_target_override_on != null)
	{
		GetCvars();
		witch_target_override_on.AddChangeHook(ConVarChanged_Cvars);
	}
}

public void ConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	witch_target_override_on_value = witch_target_override_on.BoolValue;
}

public void OnPluginStart()
{
	HookEvent("witch_harasser_set", WitchHarasserSet_Event);
}

public void WitchHarasserSet_Event(Event event, const char[] name, bool dontBroadcast)
{
	if(witch_target_override_on_value == true) return;
	
	int witch = event.GetInt("witchid");
	int attacker = GetClientOfUserId(event.GetInt("userid"));
	if (attacker > 0 && attacker <= MaxClients && IsClientInGame(attacker) && GetClientTeam(attacker) == 2 && IsPlayerAlive(attacker))
	{
		float witchOrigin[3], clientOrigin[3], fFinalPos[3], fFinalwitch[3];
		GetEntPropVector(witch, Prop_Send, "m_vecOrigin", witchOrigin);
		GetEntPropVector(attacker, Prop_Send, "m_vecOrigin",clientOrigin);
		
		if (GetVectorDistance(clientOrigin, witchOrigin, true) < Pow(150.0, 2.0))
		{
			MakeVectorFromPoints(witchOrigin, clientOrigin, fFinalPos);
			GetVectorAngles(fFinalPos, fFinalwitch);
			fFinalwitch[0] = 0.0;
			SetEntPropVector(witch, Prop_Send, "m_angRotation", fFinalwitch);

			DataPack hPack = new DataPack();
			hPack.WriteCell(EntIndexToEntRef(witch));
			hPack.WriteFloat(fFinalwitch[0]);
			hPack.WriteFloat(fFinalwitch[1]);
			hPack.WriteFloat(fFinalwitch[2]);
			RequestFrame(OnNextFrame, hPack); 
		}
	}
}

public void OnNextFrame(DataPack hPack)
{
	hPack.Reset();
	float fFinalwitch[3];
	int witch = EntRefToEntIndex(hPack.ReadCell());
	fFinalwitch[0] = hPack.ReadFloat();
	fFinalwitch[1] = hPack.ReadFloat();
	fFinalwitch[2] = hPack.ReadFloat();

	if( witch == INVALID_ENT_REFERENCE )
		return;

	if(GetEntProp(witch, Prop_Data, "m_iHealth") < 1)
		return;

	SetEntPropVector(witch, Prop_Send, "m_angRotation", fFinalwitch);
	
	if(GetEntProp(witch, Prop_Send, "m_nSequence", 2) == 30)
	{
		RequestFrame(OnNextFrame, hPack);
		return;
	}

	delete hPack;
}