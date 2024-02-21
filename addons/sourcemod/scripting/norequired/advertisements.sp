#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <mapchooser>
#include <updater>

#pragma newdecls required
#pragma semicolon 1

#include "advertisements/chatcolors.sp"
#include "advertisements/topcolors.sp"

#define PL_VERSION	"2.1.1"
#define UPDATE_URL	"http://ErikMinekus.github.io/sm-advertisements/update.txt"

public Plugin myinfo =
{
    name        = "Advertisements",
    author      = "Tsunami",
    description = "Display advertisements",
    version     = PL_VERSION,
    url         = "http://www.tsunami-productions.nl"
};


enum struct Advertisement
{
    char center[1024];
    char chat[2048];
    char hint[1024];
    char menu[1024];
    char top[1024];
    bool adminsOnly;
    bool hasFlags;
    int flags;
}


/**
 * Globals
 */
bool g_bMapChooser;
bool g_bSayText2;
int g_iCurrentAd;
ArrayList g_hAdvertisements;
ConVar g_hEnabled;
ConVar g_hFile;
ConVar g_hInterval;
ConVar g_hRandom;
Handle g_hTimer;


/**
 * Plugin Forwards
 */
public void OnPluginStart()
{
    CreateConVar("sm_advertisements_version", PL_VERSION, "Display advertisements", FCVAR_NOTIFY);
    g_hEnabled  = CreateConVar("sm_advertisements_enabled",  "1",                  "Enable/disable displaying advertisements.");
    g_hFile     = CreateConVar("sm_advertisements_file",     "advertisements.txt", "File to read the advertisements from.");
    g_hInterval = CreateConVar("sm_advertisements_interval", "30",                 "Number of seconds between advertisements.");
    g_hRandom   = CreateConVar("sm_advertisements_random",   "0",                  "Enable/disable random advertisements.");

    g_hFile.AddChangeHook(ConVarChanged_File);
    g_hInterval.AddChangeHook(ConVarChanged_Interval);

    g_bMapChooser = LibraryExists("mapchooser");
    g_bSayText2 = GetUserMessageId("SayText2") != INVALID_MESSAGE_ID;
    g_hAdvertisements = new ArrayList(sizeof(Advertisement));

    RegServerCmd("sm_advertisements_reload", Command_ReloadAds, "Reload the advertisements");

    AddChatColors();
    AddTopColors();

    if (LibraryExists("updater")) {
        Updater_AddPlugin(UPDATE_URL);
    }
}

public void OnConfigsExecuted()
{
    ParseAds();
    RestartTimer();
}

public void OnLibraryAdded(const char[] name)
{
    if (StrEqual(name, "mapchooser")) {
        g_bMapChooser = true;
    }
    if (StrEqual(name, "updater")) {
        Updater_AddPlugin(UPDATE_URL);
    }
}

public void OnLibraryRemoved(const char[] name)
{
    if (StrEqual(name, "mapchooser")) {
        g_bMapChooser = false;
    }
}


/**
 * ConVar Changes
 */
public void ConVarChanged_File(ConVar convar, const char[] oldValue, const char[] newValue)
{
    ParseAds();
}

public void ConVarChanged_Interval(ConVar convar, const char[] oldValue, const char[] newValue)
{
    RestartTimer();
}


/**
 * Commands
 */
public Action Command_ReloadAds(int args)
{
    ParseAds();
    return Plugin_Handled;
}


/**
 * Menu Handlers
 */
public int MenuHandler_DoNothing(Menu menu, MenuAction action, int param1, int param2) {}


/**
 * Timers
 */
public Action Timer_DisplayAd(Handle timer)
{
    if (!g_hEnabled.BoolValue) {
        return;
    }

    Advertisement ad;
    g_hAdvertisements.GetArray(g_iCurrentAd, ad);
    char message[1024];

    if (ad.center[0]) {
        ProcessVariables(ad.center, message, sizeof(message));

        for (int i = 1; i <= MaxClients; i++) {
            if (IsValidClient(i, ad)) {
                PrintCenterText(i, "%s", message);

                DataPack hCenterAd;
                CreateDataTimer(1.0, Timer_CenterAd, hCenterAd, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
                hCenterAd.WriteCell(i);
                hCenterAd.WriteString(message);
            }
        }
    }
    if (ad.chat[0]) {
        bool teamColor[10];
        char messages[10][1024];
        int messageCount = ExplodeString(ad.chat, "\n", messages, sizeof(messages), sizeof(messages[]));

        for (int idx; idx < messageCount; idx++) {
            teamColor[idx] = StrContains(messages[idx], "{teamcolor}", false) != -1;
            if (teamColor[idx] && !g_bSayText2) {
                SetFailState("This game does not support {teamcolor}");
            }

            ProcessChatColors(messages[idx], message, sizeof(message));
            ProcessVariables(message, messages[idx], sizeof(messages[]));
        }

        for (int i = 1; i <= MaxClients; i++) {
            if (IsValidClient(i, ad)) {
                for (int idx; idx < messageCount; idx++) {
                    if (teamColor[idx]) {
                        SayText2(i, messages[idx]);
                    } else {
                        PrintToChat(i, "%s", messages[idx]);
                    }
                }
            }
        }
    }
    if (ad.hint[0]) {
        ProcessVariables(ad.hint, message, sizeof(message));

        for (int i = 1; i <= MaxClients; i++) {
            if (IsValidClient(i, ad)) {
                PrintHintText(i, "%s", message);
            }
        }
    }
    if (ad.menu[0]) {
        ProcessVariables(ad.menu, message, sizeof(message));

        Panel hPl = new Panel();
        hPl.DrawText(message);
        hPl.CurrentKey = 10;

        for (int i = 1; i <= MaxClients; i++) {
            if (IsValidClient(i, ad)) {
                hPl.Send(i, MenuHandler_DoNothing, 10);
            }
        }

        delete hPl;
    }
    if (ad.top[0]) {
        int iStart    = 0,
            aColor[4] = {255, 255, 255, 255};

        ParseTopColor(ad.top, iStart, aColor);
        ProcessVariables(ad.top[iStart], message, sizeof(message));

        KeyValues hKv = new KeyValues("Stuff", "title", message);
        hKv.SetColor4("color", aColor);
        hKv.SetNum("level",    1);
        hKv.SetNum("time",     10);

        for (int i = 1; i <= MaxClients; i++) {
            if (IsValidClient(i, ad)) {
                CreateDialog(i, hKv, DialogType_Msg);
            }
        }

        delete hKv;
    }

    if (++g_iCurrentAd >= g_hAdvertisements.Length) {
        g_iCurrentAd = 0;
    }
}

public Action Timer_CenterAd(Handle timer, DataPack pack)
{
    char message[1024];
    static int iCount = 0;

    pack.Reset();
    int iClient = pack.ReadCell();
    pack.ReadString(message, sizeof(message));

    if (!IsClientInGame(iClient) || ++iCount >= 5) {
        iCount = 0;
        return Plugin_Stop;
    }

    PrintCenterText(iClient, "%s", message);
    return Plugin_Continue;
}


/**
 * Functions
 */
bool IsValidClient(int client, Advertisement ad)
{
    return IsClientInGame(client) && !IsFakeClient(client)
        && ((!ad.adminsOnly && !(ad.hasFlags && (GetUserFlagBits(client) & (ad.flags|ADMFLAG_ROOT))))
            || (ad.adminsOnly && (GetUserFlagBits(client) & (ADMFLAG_GENERIC|ADMFLAG_ROOT))));
}

void ParseAds()
{
    g_iCurrentAd = 0;
    g_hAdvertisements.Clear();

    char sFile[64], sPath[PLATFORM_MAX_PATH];
    g_hFile.GetString(sFile, sizeof(sFile));
    BuildPath(Path_SM, sPath, sizeof(sPath), "configs/%s", sFile);

    if (!FileExists(sPath)) {
        SetFailState("File Not Found: %s", sPath);
    }

    KeyValues hConfig = new KeyValues("Advertisements");
    hConfig.SetEscapeSequences(true);
    hConfig.ImportFromFile(sPath);
    hConfig.GotoFirstSubKey();

    Advertisement ad;
    char flags[22];
    do {
        hConfig.GetString("center", ad.center, sizeof(Advertisement::center));
        hConfig.GetString("chat",   ad.chat,   sizeof(Advertisement::chat));
        hConfig.GetString("hint",   ad.hint,   sizeof(Advertisement::hint));
        hConfig.GetString("menu",   ad.menu,   sizeof(Advertisement::menu));
        hConfig.GetString("top",    ad.top,    sizeof(Advertisement::top));
        hConfig.GetString("flags",  flags,     sizeof(flags), "none");
        ad.adminsOnly = StrEqual(flags, "");
        ad.hasFlags   = !StrEqual(flags, "none");
        ad.flags      = ReadFlagString(flags);

        g_hAdvertisements.PushArray(ad);
    } while (hConfig.GotoNextKey());

    if (g_hRandom.BoolValue) {
        g_hAdvertisements.Sort(Sort_Random, Sort_Integer);
    }

    delete hConfig;
}

void ProcessVariables(const char[] message, char[] buffer, int maxlength)
{
    char name[64], value[256];
    int buf_idx, i, name_len;
    ConVar hConVar;

    while (message[i] && buf_idx < maxlength - 1) {
        if (message[i] != '{' || (name_len = FindCharInString(message[i + 1], '}')) == -1) {
            buffer[buf_idx++] = message[i++];
            continue;
        }

        strcopy(name, name_len + 1, message[i + 1]);

        if (StrEqual(name, "currentmap", false)) {
            GetCurrentMap(value, sizeof(value));
            GetMapDisplayName(value, value, sizeof(value));
            buf_idx += strcopy(buffer[buf_idx], maxlength - buf_idx, value);
        }
        else if (StrEqual(name, "nextmap", false)) {
            if (g_bMapChooser && EndOfMapVoteEnabled() && !HasEndOfMapVoteFinished()) {
                buf_idx += strcopy(buffer[buf_idx], maxlength - buf_idx, "Pending Vote");
            } else {
                GetNextMap(value, sizeof(value));
                GetMapDisplayName(value, value, sizeof(value));
                buf_idx += strcopy(buffer[buf_idx], maxlength - buf_idx, value);
            }
        }
        else if (StrEqual(name, "date", false)) {
            FormatTime(value, sizeof(value), "%m/%d/%Y");
            buf_idx += strcopy(buffer[buf_idx], maxlength - buf_idx, value);
        }
        else if (StrEqual(name, "time", false)) {
            FormatTime(value, sizeof(value), "%I:%M:%S%p");
            buf_idx += strcopy(buffer[buf_idx], maxlength - buf_idx, value);
        }
        else if (StrEqual(name, "time24", false)) {
            FormatTime(value, sizeof(value), "%H:%M:%S");
            buf_idx += strcopy(buffer[buf_idx], maxlength - buf_idx, value);
        }
        else if (StrEqual(name, "timeleft", false)) {
            int mins, secs, timeleft;
            if (GetMapTimeLeft(timeleft) && timeleft > 0) {
                mins = timeleft / 60;
                secs = timeleft % 60;
            }

            buf_idx += FormatEx(buffer[buf_idx], maxlength - buf_idx, "%d:%02d", mins, secs);
        }
        else if ((hConVar = FindConVar(name))) {
            hConVar.GetString(value, sizeof(value));
            buf_idx += strcopy(buffer[buf_idx], maxlength - buf_idx, value);
        }
        else {
            buf_idx += FormatEx(buffer[buf_idx], maxlength - buf_idx, "{%s}", name);
        }

        i += name_len + 2;
    }

    buffer[buf_idx] = '\0';
}

void RestartTimer()
{
    delete g_hTimer;
    g_hTimer = CreateTimer(float(g_hInterval.IntValue), Timer_DisplayAd, _, TIMER_REPEAT);
}
