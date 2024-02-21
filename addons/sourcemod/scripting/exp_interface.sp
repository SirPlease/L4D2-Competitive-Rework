#pragma semicolon               1
#pragma newdecls                required

#include <sourcemod>
#include <colors>
#include <SteamWorks>
#include <logger>

#define PTYPE_SMG 0
#define PTYPE_SHOTGUN 1

enum struct PlayerInfo{
    int rankpoint;
    int gametime;	
    int tankrocks;	
    float winrounds;
    int versustotal;
    int versuswin;
    int versuslose;
    int smgkills;
    int shotgunkills;
    int type;
}

PlayerInfo PlayerInfoData[MAXPLAYERS];
int GetTimeOut[MAXPLAYERS] = {5};
Logger log;
Handle g_hForward_OnGetExp;
public void OnPluginStart(){
    log = new Logger("exp_interface", LoggerType_NewLogFile);
    //log.IgnoreLevel = LogType_Debug;
    if (log.FileSize > 1024*1024*5) log.DelLogFile();
    log.logfirst("exp interface log记录");

    for (int i = 1; i <= MaxClients; i++){
        if (IsClientInGame(i) && !IsFakeClient(i)){
            OnClientPutInServer(i);
        }
    }

}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    g_hForward_OnGetExp = CreateGlobalForward("L4D2_OnGetExp", ET_Ignore, Param_Cell, Param_Cell);
    CreateNative("L4D2_GetClientExp", _Native_GetClientExp);
    CreateNative("L4D2_CheckAndGetAllClientExp", _Native_CheckAndGetAllClient);
    RegPluginLibrary("exp_interface");
    return APLRes_Success;
}
public int _Native_CheckAndGetAllClient(Handle plugin, int numParams)
{
    if (log.IgnoreLevel == LogType_Debug){
        char name[64];
        GetPluginFilename(plugin, name, sizeof(name));
        log.debug("\"%s\" 调用了 _Native_CheckAndGetAllClient()", name);
    }
    for (int i = 1; i <= MaxClients; i++){
        if (IsClientInGame(i) && !IsFakeClient(i)){
            if (PlayerInfoData[i].rankpoint <= 0){
                OnClientPutInServer(i);
            }
        }
    }
    return 0;
}

public int _Native_GetClientExp(Handle plugin, int numParams){
    int client = GetNativeCell(1);
    if (log.IgnoreLevel == LogType_Debug){
        char name[64];
        GetPluginFilename(plugin, name, sizeof(name));
        log.debug("\"%s\" 调用了 _Native_GetClientExp(%i), return %i", 
            name, client, PlayerInfoData[client].rankpoint
        );
    }

    return PlayerInfoData[client].rankpoint;
}
public void OnClientPutInServer(int client){
    GetTimeOut[client] = 8;
    CreateTimer(0.5, Timer_GetClientExp, client);
}
public void ClearClientExpData(int client){
    PlayerInfoData[client].gametime = 0;
    PlayerInfoData[client].rankpoint = -2;
    PlayerInfoData[client].shotgunkills = 0;
    PlayerInfoData[client].smgkills = 0;
    PlayerInfoData[client].tankrocks = 0;
    PlayerInfoData[client].versuslose = 0;
    PlayerInfoData[client].versuswin = 0;
    PlayerInfoData[client].versustotal = 0;
    PlayerInfoData[client].winrounds = 0.0;
}
public Action Timer_GetClientExp(Handle timer, int iClient){
    GetTimeOut[iClient]--;
    ClearClientExpData(iClient);
    if (GetTimeOut[iClient] < 0) {
        log.warning("获取 %N 的信息时重试超时", iClient);
        return Plugin_Stop;
    }
    if (!IsClientInGame(iClient)){
        if (!IsClientConnected(iClient)){
            log.debug("%i 未连接, 不再尝试查询", iClient);
            return Plugin_Stop;
        } 
        log.debug("%i 不在游戏内, 重试%i", iClient, GetTimeOut[iClient]);
        CreateTimer(0.5, Timer_GetClientExp, iClient);
        return Plugin_Stop;
    }
    if (IsFakeClient(iClient)) return Plugin_Stop;
    int res = GetClientRP(iClient);
    if (res == -2) {
        CreateTimer(0.5, Timer_GetClientExp, iClient);
        return Plugin_Stop;
    }
    Call_StartForward(g_hForward_OnGetExp);
    Call_PushCell(iClient);
    Call_PushCell(res);
    Call_Finish();
    // global forward
    log.debug("%N 的经验评分为 %i", iClient, res);
    return Plugin_Stop;
}

public int GetClientRP(int iClient){
    PlayerInfoData[iClient].rankpoint = -2;
    SteamWorks_RequestStats(iClient, 550);
    bool status = SteamWorks_GetStatCell(iClient, "Stat.TotalPlayTime.Total", PlayerInfoData[iClient].gametime);
    if (!status) {
        log.debug("获取 %N 的数据信息时失败了, 但这也许是正常的...", iClient);
        return -2;
    }

    PlayerInfoData[iClient].gametime = PlayerInfoData[iClient].gametime/3600;
    status = SteamWorks_GetStatCell(iClient, "Stat.SpecAttack.Tank", PlayerInfoData[iClient].tankrocks) && 
    SteamWorks_GetStatCell(iClient, "Stat.GamesLost.Versus", PlayerInfoData[iClient].versuslose) &&
    SteamWorks_GetStatCell(iClient, "Stat.GamesWon.Versus", PlayerInfoData[iClient].versuswin);
    if (!status) {
        log.warning("获取 %N 的数据信息时失败了", iClient);
        return -2;
    }
    
    
    PlayerInfoData[iClient].versustotal = PlayerInfoData[iClient].versuslose + PlayerInfoData[iClient].versuswin;
    PlayerInfoData[iClient].smgkills = 0;
    PlayerInfoData[iClient].shotgunkills = 0;
    int t_kills;
    SteamWorks_GetStatCell(iClient, "Stat.smg_silenced.Kills.Total", t_kills);
    PlayerInfoData[iClient].smgkills += t_kills;
    SteamWorks_GetStatCell(iClient, "Stat.smg.Kills.Total", t_kills);
    PlayerInfoData[iClient].smgkills += t_kills;
    SteamWorks_GetStatCell(iClient, "Stat.shotgun_chrome.Kills.Total", t_kills);
    PlayerInfoData[iClient].shotgunkills += t_kills;
    SteamWorks_GetStatCell(iClient, "Stat.pumpshotgun.Kills.Total", t_kills);
    PlayerInfoData[iClient].shotgunkills += t_kills;
    PlayerInfoData[iClient].winrounds = float(PlayerInfoData[iClient].versuswin) / float(PlayerInfoData[iClient].versustotal);
    if(PlayerInfoData[iClient].versustotal < 700) PlayerInfoData[iClient].winrounds = 0.5;
    PlayerInfoData[iClient].rankpoint = Calculate_RP(PlayerInfoData[iClient]);
    if (PlayerInfoData[iClient].shotgunkills > PlayerInfoData[iClient].smgkills){
        PlayerInfoData[iClient].type = PTYPE_SHOTGUN;
    }else{
        PlayerInfoData[iClient].type = PTYPE_SMG;
    }
    return PlayerInfoData[iClient].rankpoint;
}

int Calculate_RP(PlayerInfo tPlayer)
{
    int killtotal = tPlayer.shotgunkills + tPlayer.smgkills;
    float shotgunperc = float(tPlayer.shotgunkills) / float(killtotal);   
    float rpm = float(tPlayer.tankrocks) / float(tPlayer.gametime);
    rpm = 1.0 + rpm;
    float rp = tPlayer.winrounds * (0.55 * float(tPlayer.gametime) + float(tPlayer.tankrocks) * rpm * 0.65 + 
        float(killtotal) * 0.005 * (1.0 + shotgunperc));
    return RoundToNearest(rp);
}
