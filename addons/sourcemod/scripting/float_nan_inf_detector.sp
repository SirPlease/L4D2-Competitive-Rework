#include <sourcemod>
#include <logger>
#include <sourcebanspp>
#define FLOAT_MASK  0x7f800000
Logger log;
bool Kick[MAXPLAYERS];

public Plugin myinfo = {
    name = "Float NaN and INF detector",
    author = "J_Tanzanite",
    description = "This probably wont work",
    version = "0.0.2",
    url = ""
};


public void OnPluginStart()
{
    log = new Logger("nan_inf_detector", LoggerType_NewLogFile);
    log.logfirst("https://github.com/J-Tanzanite/Little-Anti-Cheat/issues/48\n只有作弊者才会因此被抓，\n这是因为 骑师 Bug 从来不会在客户端触发任何东西，但肯定会在引擎上触发，而与此同时，当它被恶意和故意使用时，就会使用 OnPlayerRunCmd。\n我使用它已经快两年了，没有误报，而且我发现它还能检测到使用相同系统破解游戏的其他类似作弊行为。")
    CreateTimer(15.0, Timer_KickClients);
}

public void OnClientDisconnect_Post(int client){
    Kick[client] = false;
}

public Action Timer_KickClients(Handle timer){
    for (int i = 1; i<=MaxClients; i++){
        if (IsClientInGame(i) && Kick[i]){
            SBPP_BanPlayer(0, i, 0, "[nan det.]检测到非法输入");
            log.info("封禁 %N", i)
        }
    }
    CreateTimer(15.0, Timer_KickClients);
    return Plugin_Stop;
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
    int sus = 0;

    if (!is_player_valid(client))
        return Plugin_Continue;

    /* Test velocity */
    for (int i = 0; i < 3 && !sus; i++) {
        int mask = view_as<int>(vel[i]);

        if ((mask & FLOAT_MASK) == FLOAT_MASK)
            sus = 1;
    }

    /* Test angles */
    for (int i = 0; i < 3 && !sus; i++) {
        int mask = view_as<int>(angles[i]);

        if ((mask & FLOAT_MASK) == FLOAT_MASK)
            sus = 1;
    }

    if (sus) {
        /* Terrible code... */
        log.info("阻止 %N 输入, 不合法的float值...", client)
        Kick[client] = true;
        vel[0] = 0.0;
        vel[1] = 0.0;
        vel[2] = 0.0;
        angles[0] = 0.0;
        angles[1] = 0.0;
        angles[2] = 0.0;
        return Plugin_Continue;
    }

    return Plugin_Continue;
}

bool is_player_valid(int client)
{
    return (client >= 1 && client <= MaxClients
        && IsClientConnected(client) && IsClientInGame(client));
}