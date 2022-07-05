#include <sourcemod>
#include <sdktools_functions>
#include <sdktools_entinput>

// Fixed issues:
// - Server crash when kicking a bot who have been an active target of camera (point_viewcontrol_survivor)
// - Multiple visual spectator bugs after team swap in finale

public void Event_round_start_pre_entity(Event event, const char[] name, bool dontBroadcast)
{
    int entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, "point_viewcontrol*")) != INVALID_ENT_REFERENCE) {
        // Invoke a "Disable" input on camera entities to free all players
        // Doing so on round_start_pre_entity should help to not let map logic kick in too early
        AcceptEntityInput(entity, "Disable");
    }
}

public void OnClientDisconnect(int client)
{
    if (!IsClientInGame(client)) {
        return;
    }
    
    int viewEntity = GetEntPropEnt(client, Prop_Send, "m_hViewEntity");
    if (!IsValidEdict(viewEntity)) {
        return;
    }
    
    char cls[64];
    GetEdictClassname(viewEntity, cls, sizeof(cls));
    if (strncmp(cls, "point_viewcontrol", 17) == 0) {
        // Matches CSurvivorCamera, CTriggerCamera
        if (strcmp(cls[17], "_survivor") == 0 || cls[17] == '\0') {
            // Disable entity to prevent CMoveableCamera::FollowTarget to cause a crash
            // m_hTargetEnt EHANDLE is not checked for existence and can be NULL
            // CBaseEntity::GetAbsAngles being called on causing a crash
            AcceptEntityInput(viewEntity, "Disable");
        }
        
        // Matches CTriggerCameraMultiplayer
        if (strcmp(cls[17], "_multiplayer") == 0) {
            AcceptEntityInput(viewEntity, "RemovePlayer", client);
        }
    }
}

public void OnPluginStart()
{
    HookEvent("round_start_pre_entity", Event_round_start_pre_entity, EventHookMode_PostNoCopy);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    switch (GetEngineVersion()) {
        case Engine_Left4Dead2, Engine_Left4Dead:
        {
            return APLRes_Success;
        }
    }

    strcopy(error, err_max, "Plugin only supports Left 4 Dead and Left 4 Dead 2.");

    return APLRes_SilentFailure;
}

public Plugin myinfo =
{
    name = "[L4D/2] Unlink Camera Entities",
    author = "shqke",
    description = "Frees cached players from camera entity",
    version = "1.1",
    url = "https://github.com/shqke/sp_public"
};
