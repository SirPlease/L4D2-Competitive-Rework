#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <readyup>
#define REQUIRE_PLUGIN

new Handle:ghost_hurt_type;
new bool:g_bReadyUpAvailable = false;

public Plugin:myinfo = 
{
    name = "Ghost Hurt Management",
    author = "Jacob",
    description = "Allows for modifications of trigger_hurt_ghost",
    version = "1.4",
    url = "github.com/jacob404/myplugins"
}

public OnPluginStart()
{
    ghost_hurt_type = CreateConVar("ghost_hurt_type", "0", "When should trigger_hurt_ghost be enabled? 0 = Never, 1 = On Round Start", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    HookEvent("round_start", Event_Round_Start, EventHookMode_PostNoCopy);
    RegServerCmd("sm_reset_ghost_hurt", ResetGhostHurt_Cmd, "Used to reset trigger_hurt_ghost between matches.  This should be in confogl_off.cfg or equivalent for your system");
}

public OnAllPluginsLoaded()
{
    g_bReadyUpAvailable = LibraryExists("readyup");
}
public OnLibraryRemoved(const String:name[])
{
    if ( StrEqual(name, "readyup") ) { g_bReadyUpAvailable = false; }
}
public OnLibraryAdded(const String:name[])
{
    if ( StrEqual(name, "readyup") ) { g_bReadyUpAvailable = true; }
}

public OnRoundIsLive()
{
    if(GetConVarBool(ghost_hurt_type) == true)
    {
        ModifyEntity("Enable");
    }
}

public Action: L4D_OnFirstSurvivorLeftSafeArea( client )
{   
    if (!g_bReadyUpAvailable && GetConVarBool(ghost_hurt_type) == true)
    {
        ModifyEntity("Enable");
    }
}

public Event_Round_Start(Handle:event, const String:name[], bool:dontBroadcast)
{
    ModifyEntity("Disable");
}

public Action:ResetGhostHurt_Cmd(args)
{
    ModifyEntity("Enable");
}

ModifyEntity(String:inputName[])
{ 
    new iEntity;

    while ( (iEntity = FindEntityByClassname(iEntity, "trigger_hurt_ghost")) != -1 )
    {
        if ( !IsValidEdict(iEntity) || !IsValidEntity(iEntity) )
        {
            continue;
        }
        AcceptEntityInput(iEntity, inputName);
    }
}