#include <sourcemod>
#include <sourcebanspp>
#include <colors>
#define CHEAT_ANGLES             0
#define CHEAT_CHATCLEAR          1
#define CHEAT_CONVAR             2
#define CHEAT_NOLERP             3
#define CHEAT_BHOP               4
#define CHEAT_AIMBOT             5
#define CHEAT_AIMLOCK            6
#define CHEAT_ANTI_DUCK_DELAY    7
#define CHEAT_NOISEMAKER_SPAM    8
#define CHEAT_MACRO              9 /* Macros aren't actually cheats, but are forwarded as such. */
#define CHEAT_NEWLINE_NAME      10
#define CHEAT_MAX               11

char cheats[10][64] = {
    "角度",
    "刷屏",
    "作弊CVAR",
    "过低lerp",
    "连跳",
    "自瞄",
    "暴力锁",
    "无下蹲延迟",
    "宏",
    "非法名称"
}

public Action lilac_cheater_detected(int client, int cheat)
{
    char Buffer[512];
    Format(Buffer, 512, "[LAC] %N - %s", client, cheats[cheat]);
    

    if (GetClientTeam(client) == 2)
    {
        CPrintToChatAll("[{green}!{default}] 检测到作弊嫌疑");
        CPrintToChatAll(Buffer);
        CPrintToChatAll("{olive}如果你只是偶尔看见此消息，那么不必在意，如果你看到两次以上，那就自行决策吧");
    }

    return Plugin_Continue;
}

public void SBPP_OnBanPlayer(int iAdmin, int iTarget, int iTime, const char[] sReason){
    Panel congratulation = new Panel();
    char buffer[128]
    congratulation.SetTitle(">>> 喜报 <<<");
    congratulation.DrawText("==================================");
    Format(buffer, sizeof(buffer), "%N 被当场封禁", iTarget);
    congratulation.DrawText(buffer);
    congratulation.DrawItem("", ITEMDRAW_SPACER);
    Format(buffer, sizeof(buffer), "原因: %s", sReason);
    congratulation.DrawText(buffer);
    char time[64];
    Format(time, sizeof(time), "%i 分钟", iTime)
    Format(buffer, sizeof(buffer), "封禁时长: %s", iTime == 0 ? "永久" : iTime);
    congratulation.DrawText(buffer);
    congratulation.DrawItem("", ITEMDRAW_SPACER);
    congratulation.DrawText("==================================");
    congratulation.DrawItem("好死", ITEMDRAW_CONTROL);

    for (int i = 1; i <= MaxClients; i++){
        if (IsClientInGame(i) && !IsFakeClient(i)){
            congratulation.Send(i, Handler_DoNothing, 10);
        }
    }

    delete congratulation;

}

public int Handler_DoNothing(Menu menu, MenuAction action, int param1, int param2)
{
    /* Do nothing */
    return 0;
}
