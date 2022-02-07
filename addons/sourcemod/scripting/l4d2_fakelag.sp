#include <custom_fakelag>
#include <console>
#include <colors>

#define MAX_TARGET_PING GetConVarFloat(cvarMaxTargetPing)
ConVar cvarMaxTargetPing;

Handle fakeLagTimer;
float targetPingForced;
float currentMaxPing;

bool isFakeLagActive;
bool isVoteSurvivors;
bool isVoteInfected;

public Plugin:myinfo = 
{
  name = "Per-Player Fakelag",
  author = "ProdigySim, Luckylock",
  description = "Set a custom fake latency per player",
  version = "2.0",
  url = "https://github.com/ProdigySim/custom_fakelag"
};


public OnPluginStart()
{
    AddCommandListener(Cmd_OnPlayerJoinTeam, "jointeam");

    RegAdminCmd("sm_fakelag", FakeLagCmd, view_as<int>(Admin_Config), "Set fake lag for a player");
    RegAdminCmd("sm_printlag", PrintLagCmd, view_as<int>(Admin_Config), "Print Current FakeLag");

    cvarMaxTargetPing = CreateConVar("sm_fakelag_max_target_ping", "200", "Max fake lag target ping", FCVAR_NONE, true, 0.0, true, 500.0);

    RegAdminCmd("sm_fakelag_start", OnFakeLagStart, ADMFLAG_GENERIC); 
    RegAdminCmd("sm_fakelag_stop", OnFakeLagStop, ADMFLAG_GENERIC); 
    RegAdminCmd("sm_fakelag_force", OnFakeLagForce, ADMFLAG_GENERIC); 

    RegConsoleCmd("sm_fakelag_votestart", OnFakeLagVote, "Vote to start FakeLag");
    RegConsoleCmd("sm_fakelag_votestop", OnFakeLagVote, "Vote to start FakeLag");

    fakeLagTimer = INVALID_HANDLE;
    targetPingForced = 0.0;
    currentMaxPing = 999.9;
    isFakeLagActive = false;
    isVoteSurvivors = false;
    isVoteInfected = false;
}

public Action OnFakeLagVote(int client, int args)
{
    if (isFakeLagActive)
    {
        PrintFakeLag(client, "Already active.");
        return Plugin_Handled;
    }

    if (IsInfected(client) && !isVoteInfected)
    {
        isVoteInfected = true;

        if (!isVoteSurvivors)
        {
            PrintFakeLag(client, "Infected team wishes to start FakeLag, survivor team has to type !fakelag_votestart to start it.");
        }
    }
    else if (IsSurvivor(client) && !isVoteSurvivors)
    {
        isVoteSurvivors = true;

        if (!isVoteInfected)
        {
            PrintFakeLag(client, "Survivor team wishes to start FakeLag, infected team has to type !fakelag_votestart to start it.");
        }
    }

    if (isVoteSurvivors && isVoteInfected)
    {
        StartFakeLag();
    }

    return Plugin_Handled;
}

public PrintFakeLag(int client, char[] msg)
{
    if (client == 0)
    {
        CPrintToChatAll("{green}FakeLag: {default}%s", msg);
    }
    else
    {
        CPrintToChat(client, "{green}FakeLag: {default}%s", msg);
    }
}

public OnPluginEnd()
{
    StopFakeLag();
}

public Action OnFakeLagStart(int client, int args)
{
    StartFakeLag(); 
    return Plugin_Handled;  
}

public Action OnFakeLagStop(int client, int args)
{
    StopFakeLag();
    return Plugin_Handled;
}

public Action OnFakeLagForce(int client, int args)
{
    targetPingForced = GetCmdArgInt(1) * 1.0;
    CalibrateFakeLag();
    char buffer[250];

    if (targetPingForced > 0)
    {
        Format(buffer, 250, "Target ping forced at %dms.", RoundToNearest(targetPingForced));
        PrintFakeLag(0, buffer);
    }
    else
    {
        PrintFakeLag(0, "Target ping is no longer forced.");
    }

    return Plugin_Handled;
}

public Action FakeLagCmd(int client, int args) {
    if(args < 1) {
        ReplyToCommand(client, "Usage: sm_fakelag <target> <millseconds>");
        return Plugin_Handled;
    }

    char targetStr[256];
    GetCmdArg(1, targetStr, sizeof(targetStr))
    int target = FindTarget(client, targetStr, true);

    if(target < 0) {
        ReplyToCommand(client, "Unable to find target \"%s\"");
        return Plugin_Handled;
    }

    if(!IsClientInGame(target)) {
        ReplyToCommand(client, "Player %N is not in game yet.", target);
        return Plugin_Handled;
    }

    if (IsFakeClient(target)) {
        ReplyToCommand(client, "Player %N is a fake client and can't be lagged.", target);
        return Plugin_Handled;
    }

    int lagAmount = GetCmdArgInt(2);
    CFakeLag_SetPlayerLatency(target, lagAmount * 1.0);
    ShowActivity2(client, "[SM]", "Set fake lag of %dms on player %N", lagAmount, target);
    return Plugin_Handled;
}

public void StartFakeLag()
{
    PrintFakeLag(0, "Started.");
    CalibrateFakeLag();
    fakeLagTimer = CreateTimer(4.0, CalibrateFakeLagTimer, 0, TIMER_REPEAT);
    isFakeLagActive = true;
}

public void StopFakeLag()
{
    if (fakeLagTimer != INVALID_HANDLE)
    {
        
        CloseHandle(fakeLagTimer);
        fakeLagTimer = INVALID_HANDLE;
    }

    for(int client = 0; client < MaxClients; client++)
    {
        if (IsHuman(client))
        {
            SetTargetPing(client, 0.0);
        }
    }

    if (isFakeLagActive)
    {
        PrintFakeLag(0, "Stopped.");
    }

    isFakeLagActive = false;
    isVoteSurvivors = false;
    isVoteInfected = false;
    currentMaxPing = 999.99;
}

public Action CalibrateFakeLagTimer(Handle timer, Handle hndl)
{
    CalibrateFakeLag();
    return Plugin_Continue;
}

public Action CalibrateFakeLag()
{
    float targetPing;

    if (targetPingForced > 0.0)
    {
        targetPing = targetPingForced;
    }
    else
    {
        targetPing = GetMaxPing();
    }

    for (int client = 1; client < MaxClients; client++)
    {
        if (IsHumanPlaying(client))
        {
            SetTargetPing(client, targetPing);
        }
    }
}

public void SetTargetPing(int client, float targetPing)
{
    float clientPing = GetClientPing(client);
    float pingDifference = targetPing - clientPing;

    if (pingDifference > 0)
    {
        CFakeLag_SetPlayerLatency(client, pingDifference); 
    }
    else
    {
        CFakeLag_SetPlayerLatency(client, 0.0);
    }
}

public float GetMaxPing()
{
    float currentPing = 0.0;
    float maxPing = 0.0;

    for (int client = 1; client < MaxClients; client++)
    {
        if (IsHumanPlaying(client))
        {
            currentPing = GetClientPing(client);

            if (currentPing > maxPing)
            {
                maxPing = currentPing;
            }
        }
    }

    if (maxPing < currentMaxPing)
    {
        if (currentMaxPing - maxPing > 10.0)
        {
            char buffer[250];
            Format(buffer, 250, "Target ping set at %dms.", RoundToNearest(min(maxPing, MAX_TARGET_PING)));
            //PrintFakeLag(0, buffer);
        }

        currentMaxPing = maxPing;
    }

    return min(currentMaxPing, MAX_TARGET_PING);
}

public float GetClientPing(int client)
{
    float latency = GetClientLatency(client, NetFlow_Both);
    latency *= 1000; // convert to ms
    latency -= CFakeLag_GetPlayerLatency(client);

    return latency;
}

public Action Cmd_OnPlayerJoinTeam(int client, const char[] command, int argc)
{
    currentMaxPing = 999.99;
    return Plugin_Continue; 
}

public void OnClientPutInServer(int client)
{
    if (IsHuman(client))
    {
        CreateTimer(10.0, ResetMaxPingTimer);
    }
}

public Action ResetMaxPingTimer(Handle timer, Handle h)
{
    currentMaxPing = 999.99;
    return Plugin_Stop;
}

// DEBUG: See the value of s_FakeLag
public Action PrintLagCmd(int client, int args) {
	for(int i = 1; i < MaxClients; i++) {
    if(IsClientInGame(i) && !IsFakeClient(i))
    {
      ReplyToCommand(client, "%N: %fms", i, CFakeLag_GetPlayerLatency(i))
    }
  }

	return Plugin_Handled;
}

stock float min(float a, float b)
{
    if (a < b)
    {
        return a;
    }

    return b;
}

stock int GetCmdArgInt(int argnum) {
    char str[12];
    GetCmdArg(argnum, str, sizeof(str));

    return StringToInt(str);
}

stock bool:IsSurvivor(client)                                                   
{                                                                               
    return IsHuman(client)
        && GetClientTeam(client) == 2; 
}

stock bool:IsInfected(client)                                                   
{                                                                               
    return IsHuman(client)
        && GetClientTeam(client) == 3; 
}

stock bool:IsHumanPlaying(client)
{
    return IsInfected(client) || IsSurvivor(client);
}

stock bool:IsHuman(client)                                                   
{                                                                               
    return client > 0 
        && client <= MaxClients 
        && IsClientInGame(client)
        && !IsFakeClient(client)
}