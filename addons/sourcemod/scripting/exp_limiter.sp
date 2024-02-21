#pragma semicolon               1
#pragma newdecls                required
#include <sourcemod>
#include <colors>
#include <l4d2util_constants>
#include <exp_interface>
#include <SteamWorks>
#define WARMBOT_STEAMID "STEAM_1:1:695917591"
ConVar enable, max, min, sharedmin;
bool isFamilyShared[MAXPLAYERS];

public void OnPluginStart(){
    CreateTimer(2.0, Timer_CheckAllPlayer);
    enable = CreateConVar("exp_limit_enabled", "1");
    min = CreateConVar("exp_limit_min", "75");
    max = CreateConVar("exp_limit_max", "7355608");
    sharedmin = CreateConVar("exp_limit_min_fs", "1350");
    RegConsoleCmd("sm_exp", CMD_Exp);
}

public Action Timer_CheckAllPlayer(Handle timer){
    if (enable.IntValue == 0) {
        CreateTimer(2.0, Timer_CheckAllPlayer);
        return Plugin_Stop;
    }
    for (int client = 1; client <= MaxClients; client++){
        if (!IsClientInGame(client)) continue;
        if (!IsClientAuthorized(client)) continue;
        if (IsFakeClient(client)) continue;
        if (IsWarmBot(client)) continue;
        int team = GetClientTeam(client);
        if (team == L4D2Team_Infected || team == L4D2Team_Survivor){
            if (isFamilyShared[client]){
                if (!isInRange(L4D2_GetClientExp(client), sharedmin.IntValue, max.IntValue)){
                    CPrintToChatAll("[{red}!{default}] %N 你不能进入游戏, 因为家庭共享玩家至少要求{olive}%i{default}经验分才能进入游戏, 你仍可以旁观", client, sharedmin.IntValue);
                    CreateTimer(3.0, Timer_SafeToSpec, client);
                }
            }
            if (!isInRange(L4D2_GetClientExp(client), min.IntValue, max.IntValue)){
                if (L4D2_GetClientExp(client) == -2){
                    CPrintToChatAll("[{red}!{default}] %N 你不能进入游戏, 因为暂时无法获取到你的经验分, 请尝试重连服务器", client);
                }
                else CPrintToChatAll("[{red}!{default}] %N 你不能进入游戏, 因为你的经验分(%i)不在服务器当前规定范围内 {olive}(%i~%i){default}, 你仍可以旁观", client,L4D2_GetClientExp(client) ,min.IntValue, max.IntValue);
                CreateTimer(3.0, Timer_SafeToSpec, client);
            }  

        }
    }
    CreateTimer(2.0, Timer_CheckAllPlayer);
    return Plugin_Stop;
}
public Action CMD_Exp(int client, int args){
    for (int i = 1; i<=MaxClients; i++){
        if (IsClientInGame(i)){
            PrintToChat(client, "%N %i", i, L4D2_GetClientExp(i));
        }
    }
    return Plugin_Handled;
}
public bool isInRange(int i, int mi, int ma){
    return i >= mi && i <= ma;
}

public Action Timer_SafeToSpec(Handle timer, int client){
    if (IsWarmBot(client)) return Plugin_Stop;
    if (IsFakeClient(client)) return Plugin_Stop;
    if (IsClientInGame(client) && GetClientTeam(client) != L4D2Team_Spectator) FakeClientCommand(client, "sm_s");
    else if (IsClientConnected(client)) CreateTimer(3.0, Timer_SafeToSpec, client);
    else return Plugin_Stop;
    return Plugin_Continue;
}

bool IsWarmBot(int client)
{
    char steamid[64];
    GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
    return StrEqual(steamid, WARMBOT_STEAMID);
}

public void SteamWorks_OnValidateClient(int ownerauthid, int authid)
{
    int client = GetClientOfAuthId(authid);
    if (client == -1) return;
    if(ownerauthid != authid) isFamilyShared[client] = true;
    else isFamilyShared[client] = false;
}
public void OnClientDisconnect(int client){
    isFamilyShared[client] = false;
}
stock int GetClientOfAuthId(int authid)
{
    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsClientConnected(i))
        {
            char steamid[32]; GetClientAuthId(i, AuthId_Steam3, steamid, sizeof(steamid));
            char split[3][32]; 
            ExplodeString(steamid, ":", split, sizeof(split), sizeof(split[]));
            ReplaceString(split[2], sizeof(split[]), "]", "");
            //Split 1: [U:
            //Split 2: 1:
            //Split 3: 12345]
            
            int auth = StringToInt(split[2]);
            if(auth == authid) return i;
        }
    }

    return -1;
}