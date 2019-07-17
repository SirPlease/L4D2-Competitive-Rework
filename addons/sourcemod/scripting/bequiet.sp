#pragma semicolon 1

#include <colors>
#pragma newdecls required
#include <sourcemod>


ConVar hCvarCvarChange, hCvarNameChange, hCvarSpecNameChange, hCvarSpecSeeChat;
bool bCvarChange, bNameChange, bSpecNameChange, bSpecSeeChat;

public Plugin myinfo = 
{
    name = "BeQuiet",
    author = "Sir",
    description = "Please be Quiet!",
    version = "1.33.7",
    url = "https://github.com/SirPlease/SirCoding"
}

public void OnPluginStart()
{
    AddCommandListener(Say_Callback, "say");
    AddCommandListener(TeamSay_Callback, "say_team");

    //Server CVar
    HookEvent("server_cvar", Event_ServerConVar, EventHookMode_Pre);
    HookEvent("player_changename", Event_NameChange, EventHookMode_Pre);

    //Cvars
    hCvarCvarChange = CreateConVar("bq_cvar_change_suppress", "1", "Silence Server Cvars being changed, this makes for a clean chat with no disturbances.");
    hCvarNameChange = CreateConVar("bq_name_change_suppress", "1", "Silence Player name Changes.");
    hCvarSpecNameChange = CreateConVar("bq_name_change_spec_suppress", "1", "Silence Spectating Player name Changes.");
    hCvarSpecSeeChat = CreateConVar("bq_show_player_team_chat_spec", "1", "Show Spectators Survivors and Infected Team chat?");

    bCvarChange = GetConVarBool(hCvarCvarChange);
    bNameChange = GetConVarBool(hCvarNameChange);
    bSpecNameChange = GetConVarBool(hCvarSpecNameChange);
    bSpecSeeChat = GetConVarBool(hCvarSpecSeeChat);

    hCvarCvarChange.AddChangeHook(cvarChanged);
    hCvarNameChange.AddChangeHook(cvarChanged);
    hCvarSpecNameChange.AddChangeHook(cvarChanged);
    hCvarSpecSeeChat.AddChangeHook(cvarChanged);
}

public Action Say_Callback(int client, char[] command, int args)
{
    char sayWord[MAX_NAME_LENGTH];
    GetCmdArg(1, sayWord, sizeof(sayWord));
    
    if(sayWord[0] == '!' || sayWord[0] == '/')
    {
        return Plugin_Handled;
    }
    return Plugin_Continue; 
}

public Action TeamSay_Callback(int client, char[] command, int args)
{
    char sayWord[MAX_NAME_LENGTH];
    GetCmdArg(1, sayWord, sizeof(sayWord));
    
    if(sayWord[0] == '!' || sayWord[0] == '/')
    {
        return Plugin_Handled;
    }
    
    if (bSpecSeeChat && GetClientTeam(client) != 1)
    {
        char sChat[256];
        GetCmdArgString(sChat, 256);
        StripQuotes(sChat);
        int i = 1;
        while (i <= 65)
        {
            if (IsValidClient(i) && GetClientTeam(i) == 1)
            {
                if (GetClientTeam(client) == 2)
                {
                    CPrintToChat(i, "{default}(Survivor) {blue}%N {default}: %s", client, sChat);
                }
                else CPrintToChat(i, "{default}(Infected) {red}%N {default}: %s", client, sChat);
            }
            i++;
        }
    }
    return Plugin_Continue;
}

public Action Event_ServerConVar(Event event, const char[] name, bool dontBroadcast)
{
    if (bCvarChange) return Plugin_Handled;
    return Plugin_Continue;
}

public Action Event_NameChange(Event event, const char[] name, bool dontBroadcast)
{
    int clientid = event.GetInt("userid");
    int client = GetClientOfUserId(clientid); 

    if (IsValidClient(client))
    {
        if (GetClientTeam(client) == 1 && bSpecNameChange) return Plugin_Handled;
        else if (bNameChange) return Plugin_Handled;
    }
    return Plugin_Continue;
}

public void cvarChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
    bCvarChange = hCvarCvarChange.BoolValue;
    bNameChange = hCvarNameChange.BoolValue;
    bSpecNameChange = hCvarSpecNameChange.BoolValue;
    bSpecSeeChat = hCvarSpecNameChange.BoolValue;
}

stock bool IsValidClient(int client)
{ 
    if (client <= 0 || client > MaxClients || !IsClientConnected(client) || !IsClientInGame(client)) return false; 
    return true;
}
