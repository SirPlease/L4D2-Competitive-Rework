#pragma semicolon 1
#pragma newdecls required //強制1.7以後的新語法
#include <sourcemod>
#include <sdktools>

#define TEAM_SPECTATOR 1
#define CVAR_FLAGS			FCVAR_NOTIFY

char g_sPrefixType[32];
ConVar g_hCvarAllow, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog, g_hPrefixType;
ConVar g_hCvarMPGameMode;
bool g_bCvarAllow, g_bMapStarted;

public Plugin myinfo = 
{
	name = "Spectator Prefix",
	author = "Nana & Harry Potter",
	description = "when player in spec team, add prefix",
	version = "1.2",
	url = "https://steamcommunity.com/id/fbef0102/"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) 
{
	EngineVersion test = GetEngineVersion();
	
	if( test != Engine_Left4Dead && test != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	
	return APLRes_Success; 
}

public void OnPluginStart()
{
	g_hCvarAllow = CreateConVar(	"l4d_spectator_prefix_allow",			"1",					"0=Plugin off, 1=Plugin on.", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_hCvarModes =	CreateConVar("l4d_spectator_prefix_modes",	"",	"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff = CreateConVar("l4d_spectator_prefix_modes_off",	"",	"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog = CreateConVar("l4d_spectator_prefix_modes_tog",   "0", "Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	g_hPrefixType = CreateConVar("l4d_spectator_prefix_type", "(S)", "Determine your preferred type of Spectator Prefix", CVAR_FLAGS);
	
	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hPrefixType.AddChangeHook(ConVarChanged_PrefixType);

	AutoExecConfig(true, "l4d_spectator_prefix");
}

public void OnPluginEnd()
{
	RemoveAllClientPrefix();
}

public void OnMapStart()
{
	g_bMapStarted = true;
}

public void OnMapEnd()
{
	g_bMapStarted = false;
}

// ====================================================================================================
//					CVARS
// ====================================================================================================
public void OnConfigsExecuted()
{
	IsAllowed();
}

public void ConVarChanged_Allow(Handle convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

public void ConVarChanged_PrefixType(ConVar convar, const char[] oldValue, const char[] newValue)
{
	RemoveAllClientPrefix();
	GetCvars();
	AddAllClientPrefix();
}

void GetCvars()
{
	g_hPrefixType.GetString(g_sPrefixType, sizeof(g_sPrefixType));
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();
	GetCvars();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		g_bCvarAllow = true;

		HookEvent("player_team", Event_PlayerTeam, EventHookMode_PostNoCopy);
		HookEvent("player_changename", Event_NameChanged);

		AddAllClientPrefix();
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		g_bCvarAllow = false;

		UnhookEvent("player_team", Event_PlayerTeam, EventHookMode_PostNoCopy);
		UnhookEvent("player_changename", Event_NameChanged);

		RemoveAllClientPrefix();
	}
}

int g_iCurrentMode;
bool IsAllowedGameMode()
{
	if( g_bMapStarted == false )
		return false;

	if( g_hCvarMPGameMode == null )
		return false;

	int iCvarModesTog = g_hCvarModesTog.IntValue;
	g_iCurrentMode = 0;

	int entity = CreateEntityByName("info_gamemode");
	if( IsValidEntity(entity) )
	{
		DispatchSpawn(entity);
		HookSingleEntityOutput(entity, "OnCoop", OnGamemode, true);
		HookSingleEntityOutput(entity, "OnSurvival", OnGamemode, true);
		HookSingleEntityOutput(entity, "OnVersus", OnGamemode, true);
		HookSingleEntityOutput(entity, "OnScavenge", OnGamemode, true);
		ActivateEntity(entity);
		AcceptEntityInput(entity, "PostSpawnActivate");
		if( IsValidEntity(entity) ) // Because sometimes "PostSpawnActivate" seems to kill the ent.
			RemoveEdict(entity); // Because multiple plugins creating at once, avoid too many duplicate ents in the same frame
	}

	if( iCvarModesTog != 0 )
	{
		if( g_iCurrentMode == 0 )
			return false;

		if( !(iCvarModesTog & g_iCurrentMode) )
			return false;
	}

	char sGameModes[64], sGameMode[64];
	g_hCvarMPGameMode.GetString(sGameMode, sizeof(sGameMode));
	Format(sGameMode, sizeof(sGameMode), ",%s,", sGameMode);

	g_hCvarModes.GetString(sGameModes, sizeof(sGameModes));
	if( sGameModes[0] )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) == -1 )
			return false;
	}

	g_hCvarModesOff.GetString(sGameModes, sizeof(sGameModes));
	if( sGameModes[0] )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) != -1 )
			return false;
	}

	return true;
}

public void OnGamemode(const char[] output, int caller, int activator, float delay)
{
	if( strcmp(output, "OnCoop") == 0 )
		g_iCurrentMode = 1;
	else if( strcmp(output, "OnSurvival") == 0 )
		g_iCurrentMode = 2;
	else if( strcmp(output, "OnVersus") == 0 )
		g_iCurrentMode = 4;
	else if( strcmp(output, "OnScavenge") == 0 )
		g_iCurrentMode = 8;
}

//event
public Action Event_NameChanged(Event event, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	CreateTimer(0.8,PlayerNameCheck,client,TIMER_FLAG_NO_MAPCHANGE);//延遲0.8秒檢查

	return Plugin_Continue;
}

public Action Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	CreateTimer(0.8,PlayerNameCheck,client,TIMER_FLAG_NO_MAPCHANGE);//延遲0.8秒檢查

	return Plugin_Continue;
}

//timer
public Action PlayerNameCheck(Handle timer,any client)
{
	if(!IsClientInGame(client) || IsFakeClient(client)) return Plugin_Continue;
	
	int team = GetClientTeam(client);
	
	//PrintToChatAll("client: %N - %d",client,team);
	if (IsClientAndInGame(client) && !IsFakeClient(client))
	{
		char sOldname[256], sNewname[256];
		GetClientName(client, sOldname, sizeof(sOldname));
		if (team == TEAM_SPECTATOR)
		{
			if(!CheckClientHasPreFix(sOldname))
			{
				Format(sNewname, sizeof(sNewname), "%s%s", g_sPrefixType, sOldname);
				CS_SetClientName(client, sNewname);
				
				//PrintToChatAll("sNewname: %s",sNewname);
			}
		}
		else
		{
			if(CheckClientHasPreFix(sOldname))
			{
				ReplaceString(sOldname, sizeof(sOldname), g_sPrefixType, "", true);
				strcopy(sNewname,sizeof(sOldname),sOldname);
				CS_SetClientName(client, sNewname);
				
				//PrintToChatAll("sNewname: %s",sNewname);
			}
		}
	}
	
	return Plugin_Continue;
}

//function
stock bool IsClientAndInGame(int index)
{
	if (index > 0 && index < MaxClients)
	{
		return IsClientInGame(index);
	}
	return false;
}

bool CheckClientHasPreFix(const char[] sOldname)
{
	for(int i =0 ; i< strlen(g_sPrefixType); ++i)
	{
		if(sOldname[i] == g_sPrefixType[i])
		{
			//PrintToChatAll("%d-%c",i,g_sPrefixType[i]);
			continue;
		}
		else
			return false;
	}
	return true;
}

stock void CS_SetClientName(int client, const char[] name, bool silent=false)
{
    char oldname[MAX_NAME_LENGTH];
    GetClientName(client, oldname, sizeof(oldname));

    SetClientInfo(client, "name", name);
    SetEntPropString(client, Prop_Data, "m_szNetname", name);

    Event event = CreateEvent("player_changename");

    if (event != null)
    {
        event.SetInt("userid", GetClientUserId(client));
        event.SetString("oldname", oldname);
        event.SetString("newname", name);
        event.Fire();
    }

    if (silent)
        return;
    
    Handle msg = StartMessageAll("SayText2");

    if (msg != null)
    {
        BfWriteByte(msg, client);
        BfWriteByte(msg, true);
        BfWriteString(msg, "#Cstrike_Name_Change");
        BfWriteString(msg, oldname);
        BfWriteString(msg, name);
        EndMessage();
    }
}

void AddAllClientPrefix()
{
	char sOldname[256],sNewname[256];
	for( int i = 1; i <= MaxClients; i++ ) 
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == TEAM_SPECTATOR)
		{
			GetClientName(i, sOldname, sizeof(sOldname));
			if(!CheckClientHasPreFix(sOldname))
			{
				Format(sNewname, sizeof(sNewname), "%s%s", g_sPrefixType, sOldname);
				CS_SetClientName(i, sNewname);
			}
		}
	}
}

void RemoveAllClientPrefix()
{
	char sOldname[256],sNewname[256];
	for( int i = 1; i <= MaxClients; i++ ) 
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			GetClientName(i, sOldname, sizeof(sOldname));
			if(CheckClientHasPreFix(sOldname))
			{
				ReplaceString(sOldname, sizeof(sOldname), g_sPrefixType, "", true);
				strcopy(sNewname,sizeof(sOldname),sOldname);
				CS_SetClientName(i, sNewname);
			}
		}
	}
}