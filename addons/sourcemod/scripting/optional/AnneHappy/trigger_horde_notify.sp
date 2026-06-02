#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <dhooks>
#include <colors>
#include <left4dhooks>
#define PLUGIN_VERSION			"1.1-2023/6/20"
#define PLUGIN_NAME			    "trigger_horde_notify"
#define DEBUG 0

#define GAMEDATA_FILE "trigger_horde_notify"
#define FUNCTION_PATCH "CDirector::OnMapInvokedPanicEvent"

public Plugin myinfo =
{
    name = "[L4D & L4D2] trigger horde notify",
    author = "HarryPotter",
    description = "As the name says, you dumb as fuck",
    version = PLUGIN_VERSION,
    url = "https://steamcommunity.com/profiles/76561198026784913/"
}

bool g_bL4D2Version;
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    EngineVersion test = GetEngineVersion();

    if( test == Engine_Left4Dead )
    {
        g_bL4D2Version = false;
    }
    else if( test == Engine_Left4Dead2 )
    {
        g_bL4D2Version = true;
    }
    else
    {
        strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
        return APLRes_SilentFailure;
    }

    return APLRes_Success;
}

#define CVAR_FLAGS                    FCVAR_NOTIFY
#define CVAR_FLAGS_PLUGIN_VERSION     FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY

ConVar g_hAlarmCarNotify, g_hColdDown;

float g_fColdDown, g_fTriggerHordeTime;
bool g_bAlarmCarNotify, g_bFinalMap, g_bRescueStart;
Handle g_hForward;

public void OnPluginStart()
{
    LoadTranslations(PLUGIN_NAME ... ".phrases");
    g_hForward = CreateGlobalForward("L4D2_HordeStatus", ET_Ignore, Param_Cell);

    if(g_bL4D2Version)
    {
        GameData hGameData = new GameData(GAMEDATA_FILE);
        if (hGameData == null)
            SetFailState("Missing gamedata file (" ... GAMEDATA_FILE ... ")");

        DynamicDetour hDetour = DynamicDetour.FromConf(hGameData, FUNCTION_PATCH);
        if(!hDetour)
            SetFailState("Missing detour setup of \"" ... FUNCTION_PATCH ... "\"");

        if(!hDetour.Enable(Hook_Post, DTR_OnMapInvokedPanicEvent_Post))
            SetFailState("Faild to post-detour \"" ... FUNCTION_PATCH ... "\"");

        delete hDetour;

        delete hGameData;
    }

    if(g_bL4D2Version) g_hAlarmCarNotify = CreateConVar(   PLUGIN_NAME ... "_alarm_car", "0", "If 1, Notify who tirggers the alarm car.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hColdDown =       CreateConVar(   PLUGIN_NAME ... "_cool_down_time", "30.0", "Cold down time to notify again.", CVAR_FLAGS, true, 0.0);
    CreateConVar(                       PLUGIN_NAME ... "_version",       PLUGIN_VERSION, PLUGIN_NAME ... " Plugin Version", CVAR_FLAGS_PLUGIN_VERSION);
    AutoExecConfig(true, PLUGIN_NAME);

    GetCvars();
    if(g_bL4D2Version) g_hAlarmCarNotify.AddChangeHook(ConVarChanged_Cvars);
    g_hColdDown.AddChangeHook(ConVarChanged_Cvars);

    HookEvent("round_start",            Event_RoundStart,		EventHookMode_PostNoCopy);
    HookEvent("finale_start", Event_Finale_Start, EventHookMode_PostNoCopy); //final starts, some of final maps won't trigger
    HookEvent("finale_radio_start", Event_Finale_Start, EventHookMode_PostNoCopy); //final starts, all final maps trigger
    if(g_bL4D2Version)
    {
        HookEvent("gauntlet_finale_start", Event_Finale_Start, EventHookMode_PostNoCopy); //final starts, only rushing maps trigger (C5M5, C13M4)
    }
    else
    {
        HookEvent("create_panic_event", Event_create_panic_event);
    }
}

public void ConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
    if(g_bL4D2Version) g_bAlarmCarNotify = g_hAlarmCarNotify.BoolValue;
    g_fColdDown = g_hColdDown.FloatValue;
}

MRESReturn DTR_OnMapInvokedPanicEvent_Post(int pThis, Handle hReturn, Handle hParams)
{
    if(g_bRescueStart) return MRES_Ignored;
    if(DHookIsNullParam(hParams, 1)) return MRES_Ignored;

    int client = DHookGetParam(hParams, 1); //觸發者
    int type_Horde = DHookGetParam(hParams, 2); //屍潮類型 0: 一代守殭屍方式/機關屍潮, 1: 警報車
    //PrintToChatAll("觸發者: %d - 屍潮類型: %d", client, type_Horde);

    if(g_fTriggerHordeTime < GetEngineTime() && client > 0 && client < MaxClients + 1 && IsClientInGame(client))
    {
        if(type_Horde == 1)
        {
            SendForward(2);//警报车
            if(g_bAlarmCarNotify) CPrintToChatAll("[{olive}TS{default}] %t", "Alarmed_Car", client);
        }
        else
        {
            SendForward(3);// 机关有限尸潮
            CPrintToChatAll("[{olive}Anne{default}] %t", "Horde", client);
        }

        g_fTriggerHordeTime = GetEngineTime() + g_fColdDown;
    }

    return MRES_Ignored;
}

public void OnMapStart()
{
    g_bFinalMap = false;

    if(L4D_IsMissionFinalMap(true))
    {
        g_bFinalMap = true;

        int entity = -1;
        if ((entity = FindEntityByClassname(entity, "trigger_finale")) != -1)
        {
            HookSingleEntityOutput(entity, "UseStart", OnFinalTriggered);
        }
    }
}

public void OnEntityCreated(int entity, const char[] classname) //late spawn
{
    if (!IsValidEntityIndex(entity))
        return;

    if(!g_bFinalMap)
        return;

    switch (classname[0])
    {
        case 't':
        {
            if (strncmp(classname, "trigger_finale", 14) == 0)
            {
                HookSingleEntityOutput(entity, "UseStart", OnFinalTriggered);
            }
        }
    }
}

public void Event_create_panic_event(Event event, const char[] name, bool dontBroadcast)
{
    if(g_bRescueStart) return;

    int client = GetClientOfUserId(event.GetInt("userid"));
    if(client && IsClientInGame(client) && GetClientTeam(client) == L4D_TEAM_SURVIVOR)
    {
        if(g_fTriggerHordeTime < GetEngineTime())
        {
            SendForward(3);
            CPrintToChatAll("[{olive}Anne{default}] %t", "Horde", client);
            g_fTriggerHordeTime = GetEngineTime() + g_fColdDown;
        }
    }
} 

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    g_fTriggerHordeTime = 0.0;
    g_bRescueStart = false;
} 

public void Event_Finale_Start(Event event, const char[] name, bool dontBroadcast)
{
    if(g_bRescueStart) return;
    
    CPrintToChatAll("%t", "Final Rescue Start");
    SendForward(4);
    g_bRescueStart = true;
}

void OnFinalTriggered(const char[] output, int caller, int activator, float delay)
{
    if(activator > 0 && activator < MaxClients+1 && IsClientInGame(activator))
    {
        CPrintToChatAll("[{olive}Anne{default}] %t", "Final Rescue", activator);
        SendForward(4);
    }

    UnhookSingleEntityOutput(caller, "UseStart", OnFinalTriggered);
}

bool IsValidEntityIndex(int entity)
{
    return (MaxClients+1 <= entity <= GetMaxEntities());
}

public void SendForward(int client){
	Call_StartForward(g_hForward);
	Call_PushCell(client);
	Call_Finish();
}