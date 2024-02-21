#include <sourcemod>
#include <sdktools>
#include <colors>
#include <l4d2util_constants>
#include <readyup>
#include <fix_team_shuffle>
#define CHECK_INTERVAL 1.0

char snd1[] = "buttons/blip2.wav";
char snd2[] = "buttons/button22.wav";
char snd3[] = "ui/beep07.wav";
char snd4[] = "buttons/button14.wav";
char snd5[] = "ui/menu_enter05.wav";

int kicktime[MAXPLAYERS] = {20};
int butitolazy = 0;
public void OnPluginStart()
{
    CreateTimer(CHECK_INTERVAL, Timer_CheckTeams, _, TIMER_REPEAT);
}
public void OnMapStart(){
    PrecacheSound(snd1);
    PrecacheSound(snd2);
    PrecacheSound(snd3);
    PrecacheSound(snd4);
    PrecacheSound(snd5);
    for (int i = 1; i <= MaxClients; i++){
        kicktime[i] = 20;
    }
}

void ResetTimeout(int client){
    if (IsInReady()){
        kicktime[client] = 60
    }
    else {
        kicktime[client] = 20
    }
}

public Action Timer_CheckTeams(Handle timer)
{
    int players[L4D2Team_Size]
    // 统计玩家数量
    for (int i = 1; i <= MaxClients; i++){
        if (!IsClientInGame(i)) continue;
        switch (GetClientTeam(i)){
            case L4D2Team_Spectator: 
                players[L4D2Team_Spectator]++;
            case L4D2Team_Survivor:{
                if (!IsPlayerAlive(i) || !IsFakeClient(i)) players[L4D2Team_Survivor]++;
            }
            case L4D2Team_Infected:
                players[L4D2Team_Infected]++;
        }
    }
    if (players[L4D2Team_Survivor] < 4 || players[L4D2Team_Infected] < 4){
        if (players[L4D2Team_Spectator] > 0){
            for (int i = 1; i <= MaxClients; i++){
                if (!IsClientInGame(i)) continue;
                if (IsFakeClient(i)) continue;
                if (isFixTeamShuffleRunning()) {
                    if (butitolazy-- < 0) {
                        CPrintToChat(i, "[{olive}!{default}] 防错位插件运行中，占位踢出将在防错位结束后开始倒数计时");
                        butitolazy = 5;
                        }
                    break;
                }
                if (GetClientTeam(i) == L4D2Team_Spectator){
                    CPrintToChat(i, "[{olive}!{default}] 请在 {green}%is{default} 内进入队伍, 不然将会踢出", kicktime[i]);
                    if (kicktime[i] > 20) EmitSoundToClient(i, snd2, SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
                    else if (kicktime[i] > 19) EmitSoundToClient(i, snd1, SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
                    else if (kicktime[i]>10) EmitSoundToClient(i, snd2, SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
                    else if(kicktime[i]>5) EmitSoundToClient(i, snd3, SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
                    else if(kicktime[i] > 1) EmitSoundToClient(i, snd4, SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
                    else if(kicktime[i] == 0) EmitSoundToClient(i, snd5, SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);

                    if (kicktime[i]-- < 0){
                        KickClient(i, "你因为旁观占位被踢出");
                    }
                    break;
                }
            }
        }
    }
    return Plugin_Continue;
}

public void OnClientConnected(int client){
    ResetTimeout(client);
}

public void OnClientDisconnect(int client){
    OnClientConnected(client);
}

public void OnReadyUpInitiate(){
    for (int i = 1; i <= MaxClients; i++){
        if (IsClientInGame(i)){
            OnClientConnected(i);
        }
    }
}

public void OnRoundIsLive(){
    OnReadyUpInitiate()
}