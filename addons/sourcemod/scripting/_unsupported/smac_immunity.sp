#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <smac>

/* Plugin Info */
public Plugin myinfo =
{
    name = "SMAC Immunity",
    author = "GoD-Tony",
    description = "Grants immunity from SMAC to players",
    version = "1.0.0",
    url = "http://forums.alliedmods.net/showthread.php?t=179365"
};

public Action SMAC_OnCheatDetected(int client, const char[] module)
{
    // ADMFLAG_CUSTOM1 = the "o" flag, see SM flags here for more info: https://wiki.alliedmods.net/Adding_Admins_(SourceMod)
    if (CheckCommandAccess(client, "smac_immunity", ADMFLAG_CUSTOM1, true))
    {
        return Plugin_Handled;
    }

    return Plugin_Continue;
}
