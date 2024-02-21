//Please refer to https://github.com/Nolo001-Aha/SourceMod-ReBanner/wiki for installation steps.

#include <sourcemod>
#include <regex>
#include <filenetwork>
#include <sdktools_stringtables>
#include <dhooks>
#undef REQUIRE_PLUGIN
#tryinclude <sourcebanspp>
#define REQUIRE_PLUGIN

#define DEFAULT_FINGERPRINT "materials/models/texture.vmt"
#define BAN_REASON "Alternative account detected, re-applying ban"
#define ANTITAMPER_ACTION_REASON "File tampering detected! Please download server files from scratch"
#define LOGFILE "logs/rebanner.log"
#define INVALID_USERID -1

enum QueueState
{
        QueueState_Ignore = 0,
        QueueState_Queued = 1
}

enum TableType
{
        TableType_Fingerprints = 0,
        TableType_SteamIDs = 1,
        TableType_IPs = 2
}

enum LogLevel
{
        LogLevel_None = 0,
        LogLevel_Bans,
        LogLevel_Associations,
        LogLevel_Debug
}

enum OSType
{
        OS_Linux = 0,
        OS_Windows,
        OS_Unknown
}

OSType os;

Database db;

GameData gamedatafile;
Handle hPlayerSlot = INVALID_HANDLE;

StringMap bannedFingerprints; //contains all banned fingerprints
StringMap steamIDToFingerprintTable; //StringMap representation of rebanner_steamids table
StringMap ipToFingerprintTable;//StringMap representation of rebanner_ips table
StringMap fingerprintTable;//StringMap representation of rebanner_fingerprints table
StringMap temporaryFingerprints; //fingerprints generated during early connection if we fail to recognize clients by Steam and IP
StringMap steamIDToTemporaryFingerrpints; //SteamID to temporary fingerprint relation

ConVar rebanDuration;
ConVar antiTamperMode;
ConVar antiTamperAction;
ConVar shouldCheckIP;
ConVar logLevel;
ConVar svDownloadUrl;

Regex regex;

EngineVersion engineVersion;

bool canMarkForScan[MAXPLAYERS + 1];
bool conVarQuerySuccessful = false;

char logFilePath[PLATFORM_MAX_PATH];
char fingerprintPath[PLATFORM_MAX_PATH];
char rebanReason[256];
char antitamperKickReason[256];
static char logLevelDefinitions[4][32] = {"[NONE]", "[BAN EVENT]", "[ASSOCIATION]", "[DEBUG]"};
char defaultDownloadUrlConvar[512];
char logMessageRB[256];

bool globalLocked = true;

int currentUserId = INVALID_USERID;
int fingerprintCounter = 0;
int modifyConVarCurrentClient = 0;

QueueState clientQueueState[MAXPLAYERS+1];

#include "include/bans.sp" //Everything related to ban forwards
#include "include/database.sp" //database creation and parsing

methodmap DataFragments
{
        public DataFragments(Address addr)
        {
                return view_as<DataFragments>(addr);
        }

        public void filename(char[] buffer, int length)
        {
                int offset = 0x4;
                for(int i = 0; i < length; i++)
                {
                        buffer[i] = LoadFromAddress(view_as<Address>(view_as<int>(this) + offset + i), NumberType_Int8);
                        if(buffer[i] == '\0') break;
                }
        }
}

methodmap CUtlVector //Borrowed from File Network by Batfoxkid
{
        public CUtlVector(Address addr)
        {
                return view_as<CUtlVector>(addr);
        }

        //Part of CUtlMemory
        public Address m_pMemory()
        {
                return LoadFromAddress(view_as<Address>(view_as<int>(this) + 0x0), NumberType_Int32);
        }

        public int m_nAllocationCount()
        {
                return LoadFromAddress(view_as<Address>(view_as<int>(this) + 0x4), NumberType_Int32);
        }

        public int m_nGrowSize()
        {
                return LoadFromAddress(view_as<Address>(view_as<int>(this) + 0x8), NumberType_Int32);
        }

        //Part of CUtlVector
        public int m_Size()
        {
                return LoadFromAddress(view_as<Address>(view_as<int>(this) + 0xC), NumberType_Int32);
        }

        public Address m_pElements()
        {
                return LoadFromAddress(view_as<Address>(view_as<int>(this) + 0x10), NumberType_Int32);
        }

        public DataFragments GetAt(int i)
        {
                return view_as<DataFragments>(LoadFromAddress(view_as<Address>(view_as<int>(this.m_pElements()) + 0x4 * i), NumberType_Int32));
        }

        public void SetAt(int i, DataFragments data)
        {
                StoreToAddress(view_as<Address>(view_as<int>(this.m_pElements()) + 0x4 * i), data, NumberType_Int32);
        }

}

methodmap CNetChan
{
        public CNetChan(Address addr)
        {
                return view_as<CNetChan>(addr);
        }

        public CUtlVector m_WaitingList(int idx = 0)
        {
                return view_as<CUtlVector>(view_as<int>(this) + 0x100 + 0x14 * idx);
        }
}

public Plugin myinfo =
{
        name = "SourceMod Re-Banner",
        author = "Nolo001",
        description = "Detects and re-bans alt accounts of banned players through client-side fingerprinting",
        url = "https://github.com/Nolo001-Aha/SourceMod-ReBanner",
        version = "1.3"
};

public void OnPluginStart()
{
        engineVersion = GetEngineVersion();
        bannedFingerprints = new StringMap();
        steamIDToFingerprintTable = new StringMap();
        ipToFingerprintTable = new StringMap();
        fingerprintTable = new StringMap();
        temporaryFingerprints = new StringMap();
        steamIDToTemporaryFingerrpints = new StringMap();

        regex = new Regex("^[0-9]+$");
        for(int client = 1; client<=MaxClients; client++)
                clientQueueState[client] = QueueState_Ignore;


        gamedatafile = LoadGameConfigFile("rebanner.games");

        if(gamedatafile == null)
                SetFailState("Cannot load rebanner.games.txt! Make sure you have it installed!");

        Handle detourSendServerInfo = DHookCreateDetour(Address_Null, CallConv_THISCALL, ReturnType_Bool, ThisPointer_Address);
        if(detourSendServerInfo == null)
                SetFailState("Failed to create detour for CBaseClient::SendServerInfo!");

        if(!DHookSetFromConf(detourSendServerInfo, gamedatafile, SDKConf_Signature, "CBaseClient::SendServerInfo"))
                SetFailState("Failed to load CBaseClient::SendServerInfo signature from gamedata!");

        if(!DHookEnableDetour(detourSendServerInfo, false, sendServerInfoDetCallback_Pre))
                SetFailState("Failed to detour CBaseClient::SendServerInfo PreHook!");

        Handle detourBuildConVarMessage = DHookCreateDetour(Address_Null, CallConv_CDECL, ReturnType_Void, ThisPointer_Ignore);
        if(detourBuildConVarMessage == null)
                SetFailState("Failed to create detour for Host_BuildConVarUpdateMessage!");

        //if(!DHookSetFromConf(detourBuildConVarMessage, gamedatafile, SDKConf_Signature, "CBaseClient::SendServerInfo"))
        if(!DHookSetFromConf(detourBuildConVarMessage, gamedatafile, SDKConf_Signature, "Host_BuildConVarUpdateMessage"))
                SetFailState("Failed to load Host_BuildConVarUpdateMessage signature from gamedata!");

        DHookAddParam(detourBuildConVarMessage, HookParamType_Unknown);
        DHookAddParam(detourBuildConVarMessage, HookParamType_Int);
        DHookAddParam(detourBuildConVarMessage, HookParamType_Bool);

        if(!DHookEnableDetour(detourBuildConVarMessage, false, buildConVarMessageDetCallback_Pre))
                SetFailState("Failed to detour Host_BuildConVarUpdateMessage PreHook!");

        if(!DHookEnableDetour(detourBuildConVarMessage, true, buildConVarMessageDetCallback_Post))
                SetFailState("Failed to detour Host_BuildConVarUpdateMessage PostHook!");

        StartPrepSDKCall(SDKCall_Raw);
        PrepSDKCall_SetFromConf(gamedatafile, SDKConf_Virtual, "CBaseClient::GetPlayerSlot");
        PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
        hPlayerSlot = EndPrepSDKCall();

        Database.Connect(OnDatabaseConnected, "rebanner", 0);

        checkOS();
        ParseConfigFile();
        RegAdminCmd("rb_unbansteam", Command_UnbanBySteamID, ADMFLAG_UNBAN, "Remove the ban flag on a fingerprint via a SteamID");
        RegAdminCmd("rb_unbanip", Command_UnbanByIP, ADMFLAG_UNBAN, "Remove the ban flag on a fingerprint via an IP address");

        logLevel = CreateConVar("rb_log_level", "1", "Logging level. 0 - disable. 1 - log alt account bans, 2 - also log associations, 3 - log everything(debug, lots of SPAM).")
        shouldCheckIP = CreateConVar("rb_check_ip", "1", "Should IP addresses be taken into account? 0 - no, 1 - yes (RECOMMENDED)");
        antiTamperAction = CreateConVar("rb_antitamper_action", "1", "Action taken when fingerprint tampering is detected. 0 - do nothing, 1 - kick");
        antiTamperMode = CreateConVar("rb_antitamper_mode", "1", "Anti-tamper mode. 0 - disable (DANGEROUS), 1 - check fingerprints for tampering, 2 - Also check if client fingerprint is known by the server");
        rebanDuration = CreateConVar("rb_reban_type", "0", "How long should alts be re-banned for? 1 - same duration as original ban, 0 - remaining duration of the original ban");
}

public MRESReturn sendServerInfoDetCallback_Pre(Address pointer, Handle hReturn, Handle hParams) //First callback in chain, derive client and find their IP
{
        int client;
        Address pointer2 = pointer + view_as<Address>(0x4);
        if(os == OS_Windows)
        {

                client = view_as<int>(SDKCall(hPlayerSlot, pointer2)) + 1;
        }
        else
        {
                client = view_as<int>(SDKCall(hPlayerSlot, pointer2)) + 1;
        }
        modifyConVarCurrentClient = client;
        //PrintToServer("sendServerInfoDetCallback_Pre for client %N, %i", modifyConVarCurrentClient, modifyConVarCurrentClient);
        return MRES_Ignored;
}

public MRESReturn buildConVarMessageDetCallback_Pre(Handle hParams) //Second callback in chain, call our main function and get a node link in response
{
        if(modifyConVarCurrentClient == -1)
                return MRES_Ignored;

        //PrintToServer("buildConVarMessageDetCallback_Pre for client %N, %i", modifyConVarCurrentClient, modifyConVarCurrentClient);
        int client = modifyConVarCurrentClient;
        modifyConVarCurrentClient = -1;

        char steamid2[64], query[512];
        GetClientAuthId(client, AuthId_Steam2, steamid2, sizeof(steamid2), false);
        char ip[64];
        GetClientIP(client, ip, sizeof(ip));
        if(steamIDToFingerprintTable.ContainsKey(steamid2)) //if we match a steamID to a fingerprint
        {
                char fingerprint[128];
                steamIDToFingerprintTable.GetString(steamid2, fingerprint, sizeof(fingerprint));
                if(!ipToFingerprintTable.ContainsKey(ip) && shouldCheckIP.BoolValue) //and if we haven't recorded this IP yet
                {
                        Format(query, sizeof(query), "INSERT INTO rebanner_ips (ip, fingerprint) VALUES ('%s', '%s')", ip, fingerprint);
                        db.Query(OnFingerprintRelationSaved, query); //save new ip-fingerprint relation
                        UpdateMainFingerprintRecordWithNewSteamIDAndOrIP(fingerprint, "", ip);
                }
                Format(logMessageRB, sizeof(logMessageRB), "Found existing fingerprint record (%s) by SteamID match (%s). Sending through FastDownloads.", fingerprint, steamid2);
                WriteLog(logMessageRB, LogLevel_Associations);
                updateDownloadUrlConVarWithUniqueFingerprint(fingerprint);
        }
        else
        {
                if(ipToFingerprintTable.ContainsKey(ip) && shouldCheckIP.BoolValue) //if we match a steamID to an ip
                {
                        char fingerprint[128];
                        ipToFingerprintTable.GetString(ip, fingerprint, sizeof(fingerprint));
                        Format(logMessageRB, sizeof(logMessageRB), "Found existing fingerprint record (%s) by IP match (%s). Sending through FastDownloads.", fingerprint, ip);
                        WriteLog(logMessageRB, LogLevel_Associations);
                        updateDownloadUrlConVarWithUniqueFingerprint(fingerprint);
                        Format(query, sizeof(query), "INSERT INTO rebanner_steamids (steamid2, fingerprint) VALUES ('%s', '%s')", steamid2, fingerprint);
                        db.Query(OnFingerprintRelationSaved, query); //save new steamid-fingerprint relation
                        UpdateMainFingerprintRecordWithNewSteamIDAndOrIP(fingerprint, steamid2, "");
                }
                else //if we're out of options and we don't recognize this client
                {
                        Format(logMessageRB, sizeof(logMessageRB), "Generating new fingerprint for client %N", client);
                        WriteLog(logMessageRB, LogLevel_Debug);
                        GenerateNewFingerprintAndSetConVar(steamid2);
                }

        }
        return MRES_Ignored;
}

void GenerateNewFingerprintAndSetConVar(const char[] steamid)
{
        char uniqueFingerprint[512];

        for(int i=1; i<=3; i++)
                Format(uniqueFingerprint, sizeof(uniqueFingerprint), "%s%i", uniqueFingerprint, (GetURandomInt() % 988888889) + 11111111);

        temporaryFingerprints.SetString(uniqueFingerprint, "");
        steamIDToTemporaryFingerrpints.SetString(steamid, uniqueFingerprint);
        updateDownloadUrlConVarWithUniqueFingerprint(uniqueFingerprint);
}

void updateDownloadUrlConVarWithUniqueFingerprint(const char[] fingerprint)
{
        int oldflags = GetConVarFlags(svDownloadUrl);
        SetConVarFlags(svDownloadUrl, oldflags &~ FCVAR_REPLICATED);
        char newDownloadUrl[512];
        Format(newDownloadUrl, sizeof(newDownloadUrl), "%s/serve.php?id=%s&url=", defaultDownloadUrlConvar, fingerprint);
        SetConVarString(svDownloadUrl, newDownloadUrl);
        SetConVarFlags(svDownloadUrl, oldflags|FCVAR_REPLICATED);
        Format(logMessageRB, sizeof(logMessageRB), "Diverting to new FastDownload address: %s", newDownloadUrl);
        WriteLog(logMessageRB, LogLevel_Debug);
}


public MRESReturn buildConVarMessageDetCallback_Post(Handle hParams) //Reverts the ConVar to it's original value
{
        int oldflags = GetConVarFlags(svDownloadUrl);
        SetConVarFlags(svDownloadUrl, oldflags &~ FCVAR_REPLICATED);
        SetConVarString(svDownloadUrl, defaultDownloadUrlConvar);
        SetConVarFlags(svDownloadUrl, oldflags|FCVAR_REPLICATED);
        Format(logMessageRB, sizeof(logMessageRB), "Resetting to default FastDownload address.");
        WriteLog(logMessageRB, LogLevel_Debug);
        return MRES_Ignored;
}

public void OnAllPluginsLoaded()
{
        ConVar svAllowDownload = FindConVar("sv_allowdownload");
        if(svAllowDownload)
                svAllowDownload.SetInt(1);

        ConVar svAllowUpload = FindConVar("sv_allowupload");
        if(svAllowUpload)
                svAllowUpload.SetInt(1);

        ConVar clAllowUpload = FindConVar("cl_allowupload");
        if(clAllowUpload)
                clAllowUpload.SetInt(1);

        ConVar clAllowDownload = FindConVar("cl_allowdownload");
        if(clAllowDownload)
                clAllowDownload.SetInt(1);
}

public void OnPluginEnd()
{
        SetConVarString(svDownloadUrl, defaultDownloadUrlConvar);
}

public void OnConfigsExecuted()
{
        svDownloadUrl = FindConVar("sv_downloadurl");
        GetConVarString(svDownloadUrl, defaultDownloadUrlConvar, sizeof(defaultDownloadUrlConvar));
        AddFileToDownloadsTable(fingerprintPath);
        globalLocked = false;
        currentUserId = INVALID_USERID;
        CreateTimer(5.0, Timer_ProcessQueue, _, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);

        //Some checks are needed here for proper operation
        char buf[PLATFORM_MAX_PATH];
        strcopy(buf, sizeof(buf), fingerprintPath);
        for(int i = strlen(buf) - 1; i >= 0; i--)
        {
            if(buf[i] == '\\' || buf[i] == '/')
            {
                buf[i] = '\0';
                break;
            }
        }
        Format(logMessageRB, sizeof(logMessageRB), "Folder '%s' creation | Result: %d", buf, CreateDirectory(buf, FPERM_O_READ|FPERM_O_EXEC|FPERM_G_READ|FPERM_G_EXEC|FPERM_U_READ|FPERM_U_WRITE|FPERM_U_EXEC, true, "download"));
        WriteLog(logMessageRB, LogLevel_Debug);

        File file = OpenFile(fingerprintPath, "w+", true, "download");
        if(file == null)
                SetFailState("Unable to create or open fingerprint file '%s'. Please build the path to this file!", fingerprintPath);

        delete file;

        //Refer to engine/net_chan.cpp#2136
        if(FileExists(fingerprintPath, true, "download"))
        {
                int status = DeleteFile(fingerprintPath, true, "download");
                Format(logMessageRB, sizeof(logMessageRB), "File in 'download' folder deleted: %s | Result: %d", fingerprintPath, status);
                WriteLog(logMessageRB, LogLevel_Debug);
        }
}

public void OnMapEnd()
{
        SetConVarString(svDownloadUrl, defaultDownloadUrlConvar);
        globalLocked = false;
        currentUserId = INVALID_USERID;
        for(int client = 1; client<=MaxClients; client++)
                clientQueueState[client] = QueueState_Ignore;

}

void ParseConfigFile()
{
        char config[PLATFORM_MAX_PATH];
        BuildPath(Path_SM, config, sizeof(config), "configs/rebanner.cfg");
        if(!FileExists(config))
                GenerateConfigFile(config);

        char configFingerprint[PLATFORM_MAX_PATH], configRebanReason[256], configKickReason[256];
        KeyValues kv = new KeyValues("Settings");
        kv.ImportFromFile(config);
        kv.Rewind();
        char enabled[8];
        kv.GetString("enable", enabled, sizeof(enabled), "0");
        if(!view_as<bool>(StringToInt(enabled)))
        {
                LogError("Waiting for FastDownloads setup. Please refer to the Wiki Setup page!");
                SetFailState("Waiting for FastDownloads setup. Please refer to the Wiki Setup page!");
        }

        kv.GetString("fingerprint path", configFingerprint, sizeof(configFingerprint));
        kv.GetString("ban reason", configRebanReason, sizeof(configRebanReason));
        kv.GetString("tampering kick reason", configKickReason, sizeof(configKickReason));



        strcopy(fingerprintPath, sizeof(fingerprintPath), configFingerprint);

        strcopy(rebanReason, sizeof(rebanReason), configRebanReason);
        strcopy(antitamperKickReason, sizeof(antitamperKickReason), configKickReason);
        delete kv;
}

void GenerateConfigFile(const char[] path)
{
        char randomDownloadPath[PLATFORM_MAX_PATH];
        int downloadTable = FindStringTable("downloadables");
        if(downloadTable == INVALID_STRING_TABLE)
                SetFailState("Unable to find downloadables stringtable. What?");

        KeyValues kv = new KeyValues("Settings");
        int downloadTableSize = GetStringTableNumStrings(downloadTable);
        if(downloadTableSize > 3)
        {
                ReadStringTable(downloadTable, GetRandomInt(3, downloadTableSize-1), randomDownloadPath, sizeof(randomDownloadPath));
                char explodedString[4][256];
                int explodeSize = ExplodeString(randomDownloadPath, ".", explodedString, 4, 256);
                Format(explodedString[explodeSize-2], 256, "%s1", explodedString[explodeSize-2]);
                char finalFingerprintPath[PLATFORM_MAX_PATH];
                for(int i = 0; i< explodeSize-1; i++)
                Format(finalFingerprintPath, sizeof(finalFingerprintPath), "%s%s", finalFingerprintPath, explodedString[i]);

                Format(finalFingerprintPath, sizeof(finalFingerprintPath), "%s.%s", finalFingerprintPath, explodedString[explodeSize-1]);
                kv.SetString("fingerprint path", finalFingerprintPath);
        }
        else
        {
                kv.SetString("fingerprint path", DEFAULT_FINGERPRINT);
        }
        kv.SetString("ban reason", BAN_REASON);
        kv.SetString("tampering kick reason", ANTITAMPER_ACTION_REASON);
        kv.SetString("enable", "0");
        kv.Rewind();
        kv.ExportToFile(path);
        delete kv;
}

public void OnClientAuthorized(int client)
{
    if(!canMarkForScan[client])
    {
        canMarkForScan[client] = true;
        return;
    }
    BeginScan(client);
}

public void OnClientPutInServer(int client)
{
    if(!canMarkForScan[client])
    {
        canMarkForScan[client] = true;
        return;
    }
    BeginScan(client);
}

public void OnClientDisconnect(int client)
{
        clientQueueState[client] = QueueState_Ignore;
        canMarkForScan[client] = false;
        if(currentUserId == GetClientUserId(client))
        {
                currentUserId = INVALID_USERID;
                globalLocked = false;
                conVarQuerySuccessful = false;
        }
        if(modifyConVarCurrentClient == client)
                modifyConVarCurrentClient = -1;
}

void BeginScan(int client)
{
        canMarkForScan[client] = false;
        CreateTimer(3.0, Timer_AppendClientToQueue, client, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_AppendClientToQueue(Handle tmr, int client)
{
        if(IsValidClient(client))
                clientQueueState[client] = QueueState_Queued;

        return Plugin_Continue;
}

public Action Timer_ProcessQueue(Handle tmr, any data)
{
        if(globalLocked)
                return Plugin_Continue;
        for(int client = 1; client<=MaxClients; client++)
        {
                if(!IsValidClient(client))
                        continue;

                if(clientQueueState[client] == QueueState_Queued)
                {
                        globalLocked = true;
                        currentUserId = GetClientUserId(client);
                        Format(logMessageRB, sizeof(logMessageRB), "Processing queued client %N, %i", client, client);
                        WriteLog(logMessageRB, LogLevel_Debug);
                        StartProcessingClient(client);
                        return Plugin_Continue;
                }
        }
        return Plugin_Continue;
}

void StartProcessingClient(int client)
{
        if(!IsValidClient(client))
        {
                currentUserId = INVALID_USERID;
                clientQueueState[client] = QueueState_Ignore;
                globalLocked = false;
                return;
        }
        int oldflags = GetConVarFlags(svDownloadUrl);
        SetConVarFlags(svDownloadUrl, oldflags|FCVAR_REPLICATED);
        SetConVarString(svDownloadUrl, defaultDownloadUrlConvar, true, true);
        SendConVarValue(client, svDownloadUrl, defaultDownloadUrlConvar);
        RemoveBanRecordIfExists(client); //if client got to this point, means they're not banned and we can reset is_banned if it's set to 1
        conVarQuerySuccessful = false;
        WriteLog("Requesting client fingerpint via File Network...", LogLevel_Debug);
        if(FileExists(fingerprintPath, true, "download"))
        {
                DeleteFile(fingerprintPath, true, "download");
        }
        FileNet_RequestFile(client, fingerprintPath, RequestClientFingerprint);
}

public Action Timer_CheckForSuccessfulConVarQuery(Handle tmr, int client)
{
        if(!IsValidClient(client))
                return Plugin_Continue;

        if(currentUserId != GetClientUserId(client))
                return Plugin_Continue;

        if(!conVarQuerySuccessful)
        {
                currentUserId = INVALID_USERID;
                clientQueueState[client] = QueueState_Ignore;
                globalLocked = false;
                return Plugin_Continue;
        }
        return Plugin_Continue;
}

public void OnClientConVarQueried(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue)
{
        conVarQuerySuccessful = true;
        if(!IsValidClient(client))
        {
                clientQueueState[client] = QueueState_Ignore;
                currentUserId = INVALID_USERID;
                globalLocked = false;
                return;
        }
        if(currentUserId != GetClientUserId(client))
        {
                clientQueueState[client] = QueueState_Ignore;
                currentUserId = INVALID_USERID;
                globalLocked = false;
                return;
        }

        if(result == ConVarQuery_Cancelled)
        {
                clientQueueState[client] = QueueState_Ignore;
                currentUserId = INVALID_USERID;
                globalLocked = false;
                return;
        }

        float value = StringToFloat(cvarValue);
        if(value == 1.0)
        {
                WriteLog("sv_allowupload is 1. Sending fingerprint via File Network...", LogLevel_Debug);
                CreateOrResendClientFingerprint(client);
        }
        else
        {
                WriteLog("sv_allowupload is 0. Unable to use File Network. Aborting...", LogLevel_Debug);
                clientQueueState[client] = QueueState_Ignore;
                currentUserId = INVALID_USERID;
                globalLocked = false;
                return;
        }


}

void RequestClientFingerprint(int client, const char[] file, int id, bool success)
{
        if(!IsValidClient(client))
        {
                currentUserId = INVALID_USERID;
                clientQueueState[client] = QueueState_Ignore;
                globalLocked = false;
                return;
        }
        if(currentUserId != GetClientUserId(client))
        {
                currentUserId = INVALID_USERID;
                clientQueueState[client] = QueueState_Ignore;
                globalLocked = false;
                return;
        }
        if(!success)
        {
                QueryClientConVar(client, "sv_allowupload", OnClientConVarQueried);
                WriteLog("Unable to request client fingerprint or they didn't download it through FastDownloads. Checking if we can send through File Network...", LogLevel_Debug);
                return;
        }


        File fingerprintFile = OpenFile(fingerprintPath, "r", true, "download");
        if(fingerprintFile == null)
                SetFailState("Could not find fingerprint file on disk! Should never happen?");

        char clientFingerprint[256];
        fingerprintFile.ReadLine(clientFingerprint, sizeof(clientFingerprint));
        fingerprintFile.Close();
        Format(logMessageRB, sizeof(logMessageRB), "Received fingerprint %s of client %N. Processing...", clientFingerprint, client);
        WriteLog(logMessageRB, LogLevel_Debug);
        if(FileExists(fingerprintPath, true, "download"))
                DeleteFile(fingerprintPath, true, "download");

        ProcessReceivedClientFingerprint(client, clientFingerprint);
}

void ProcessReceivedClientFingerprint(int client, const char[] fingerprint)
{
        if(currentUserId != GetClientUserId(client))
        {
                currentUserId = INVALID_USERID;
                clientQueueState[client] = QueueState_Ignore;
                globalLocked = false;
                return;
        }
        char ip[64], steamid[64], query[512];
        GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
        GetClientIP(client, ip, sizeof(ip));

        if(steamIDToFingerprintTable.ContainsKey(steamid) || ipToFingerprintTable.ContainsKey(ip)) // we recognize this client by IP or SteamID, we know their fingerprint.
        {                                                                                               //Make sure to store their IP/SteamID if we don't have such a match
                if(steamIDToFingerprintTable.ContainsKey(steamid)) //if we matched by steamid
                {
                        char knownFingerprint[128];
                        steamIDToFingerprintTable.GetString(steamid, knownFingerprint, sizeof(knownFingerprint));

                        if(!ipToFingerprintTable.ContainsKey(ip)) //and if we haven't recorded this IP yet
                        {
                                Format(query, sizeof(query), "INSERT INTO rebanner_ips (ip, fingerprint) VALUES ('%s', '%s')", ip, knownFingerprint);
                                db.Query(OnFingerprintRelationSaved, query); //save new ip-fingerprint relation
                                Format(logMessageRB, sizeof(logMessageRB), "Adding new IP (%s) association for client %N", ip, client);
                                WriteLog(logMessageRB, LogLevel_Associations);
                                UpdateMainFingerprintRecordWithNewSteamIDAndOrIP(knownFingerprint, "", ip);
                        }

                        if(bannedFingerprints.ContainsKey(knownFingerprint)) //if this known fingerprint is banned, execute em
                        {
                                RebanClient(client, knownFingerprint);
                        }
                        else
                        {
                                currentUserId = INVALID_USERID;
                                clientQueueState[client] = QueueState_Ignore;
                                globalLocked = false;
                        }
                        return;
                }

                if(ipToFingerprintTable.ContainsKey(ip)) //if we matched by ip
                {
                        char knownFingerprint[128];
                        ipToFingerprintTable.GetString(ip, knownFingerprint, sizeof(knownFingerprint));

                        if(!steamIDToFingerprintTable.ContainsKey(steamid)) //and if we haven't recorded this SteamID yet
                        {
                                Format(query, sizeof(query), "INSERT INTO rebanner_steamids (steamid2, fingerprint) VALUES ('%s', '%s')", steamid, knownFingerprint);
                                db.Query(OnFingerprintRelationSaved, query); //save new steamid-fingerprint relation
                                Format(logMessageRB, sizeof(logMessageRB), "Adding new SteamID (%s) association for client %N", steamid, client);
                                WriteLog(logMessageRB, LogLevel_Associations);
                                UpdateMainFingerprintRecordWithNewSteamIDAndOrIP(knownFingerprint, steamid, "");
                        }
                        if(bannedFingerprints.ContainsKey(knownFingerprint))//if this known fingerprint is banned, execute em
                        {
                                RebanClient(client, knownFingerprint);
                        }
                        else
                        {
                                currentUserId = INVALID_USERID;
                                clientQueueState[client] = QueueState_Ignore;
                                globalLocked = false;
                        }
                        return;
                }

        }
        else //we do not recognize their IP and SteamID and can't find their fingerprint, but they have a fingerprint clientside. Grab their clientside fingerprint and match it with their steamid and ip
        {


                if(temporaryFingerprints.ContainsKey(fingerprint)) //the client responded with a new fingerprint that we generated earlier. This means that they did not have the fingerprint file locally before joining the server.
                { //If we're here, then this is a new client that we cannot recognize.
                        temporaryFingerprints.Remove(fingerprint);
                        char log[256];
                        Format(log, sizeof(log), "Client %N not recognized and did not have a fingerprint client-side before joining the server. Generating new fingerprint record.", client);
                        WriteLog(log, LogLevel_Associations);


                        Format(query, sizeof(query), "INSERT INTO rebanner_fingerprints (fingerprint, steamid2, is_banned, banned_duration, banned_timestamp, ip) VALUES ('%s', '%s', 0, 0, 0, '%s')", fingerprint, steamid, ip);
                        db.Query(OnFingerprintRelationSaved, query); //save new fingerprint
                        DataPack fingerprintPack = new DataPack();
                        fingerprintPack.WriteString(steamid);
                        fingerprintPack.WriteCell(0);
                        fingerprintPack.WriteCell(0);
                        fingerprintPack.WriteCell(0);
                        fingerprintPack.WriteString(ip);
                        fingerprintTable.SetValue(fingerprint, fingerprintPack);
                        steamIDToFingerprintTable.SetString(steamid, fingerprint);
                        Format(query, sizeof(query), "INSERT INTO rebanner_steamids (steamid2, fingerprint) VALUES ('%s', '%s')", steamid, fingerprint);
                        db.Query(OnFingerprintRelationSaved, query); //save new steamid-fingerprint relation
                        if(shouldCheckIP.BoolValue)
                        {
                                ipToFingerprintTable.SetString(ip, fingerprint);
                                Format(query, sizeof(query), "INSERT INTO rebanner_ips (ip, fingerprint) VALUES ('%s', '%s')", ip, fingerprint);
                                db.Query(OnFingerprintRelationSaved, query); //save new ip-fingerprint relation
                        }
                        clientQueueState[client] = QueueState_Ignore;
                        currentUserId = INVALID_USERID;
                        globalLocked = false;
                        return;
                }
                if(IsFingerprintTamperedWith(fingerprint)) //we reach this if the client responded with a fingerprint that is not the one we generated when they connected.
                {//i.e. they had a fingerprint file locally before joining the server.
                        char log[512];
                        Format(log, sizeof(log), "Potential fingerprint tampering detected for client %N!", client);
                        WriteLog(log, LogLevel_Associations);
                        if(antiTamperAction.BoolValue) //kick client
                        {
                                KickClient(client, antitamperKickReason);
                        }
                        clientQueueState[client] = QueueState_Ignore;
                        currentUserId = INVALID_USERID;
                        globalLocked = false;
                        return;
                }
                Format(query, sizeof(query), "INSERT INTO rebanner_steamids (steamid2, fingerprint) VALUES ('%s', '%s')", steamid, fingerprint);
                db.Query(OnFingerprintRelationSaved, query); //save new steamid-fingerprint relation
                steamIDToFingerprintTable.SetString(steamid, fingerprint);

                if(shouldCheckIP.BoolValue)
                {
                        Format(query, sizeof(query), "INSERT INTO rebanner_ips (ip, fingerprint) VALUES ('%s', '%s')", ip, fingerprint);
                        db.Query(OnFingerprintRelationSaved, query); //save new ip-fingerprint relation

                        UpdateMainFingerprintRecordWithNewSteamIDAndOrIP(fingerprint, steamid, ip);
                }
                else
                {
                        UpdateMainFingerprintRecordWithNewSteamIDAndOrIP(fingerprint, steamid);
                }

                if(bannedFingerprints.ContainsKey(fingerprint))
                {
                        RebanClient(client, fingerprint);
                } //if this fingerprint is banned, execute em
                else
                {
                        currentUserId = INVALID_USERID;
                        clientQueueState[client] = QueueState_Ignore;
                        globalLocked = false;
                        return;
                }
        }
}

bool IsFingerprintTamperedWith(const char[] fingerprint)
{
        if(antiTamperMode.IntValue)
        {
                if(regex.Match(fingerprint) == -1) //our regex detected tampering, the fingerprint string contains something other than numbers
                        return true;

                if(antiTamperMode.IntValue == 2)
                {
                        if(!fingerprintTable.ContainsKey(fingerprint)) //the fingerprint from the client is numeric only, but we don't recognize it = tampering.
                                return true;
                }
        }
        return false;
}

void UpdateMainFingerprintRecordWithNewSteamIDAndOrIP(const char[] fingerprint, const char[] steamid = "", const char[] ip = "")
{
        char query[512];
        if(steamid[0])
        {
                steamIDToFingerprintTable.SetString(steamid, fingerprint);
                char steamidString[256];
                DataPack pack;
                fingerprintTable.GetValue(fingerprint, pack);
                pack.Reset();
                pack.ReadString(steamidString, sizeof(steamidString));
                Format(query, sizeof(query), "UPDATE rebanner_fingerprints SET steamid2 = '%s;%s' WHERE fingerprint = '%s'", steamidString, steamid, fingerprint);
                db.Query(AppendFingerprintSteamIDOrIPCallback, query);
        }
        if(ip[0])
        {
                ipToFingerprintTable.SetString(ip, fingerprint);
                char ipString[256];
                DataPack pack;
                fingerprintTable.GetValue(fingerprint, pack);
                pack.Reset();
                pack.ReadString(ipString, sizeof(ipString));
                pack.ReadCell();
                pack.ReadCell();
                pack.ReadCell();
                pack.ReadString(ipString, sizeof(ipString));

                Format(query, sizeof(query), "UPDATE rebanner_fingerprints SET ip = '%s;%s' WHERE fingerprint = '%s'", ipString, ip, fingerprint);
                db.Query(AppendFingerprintSteamIDOrIPCallback, query);
        }
}


public void AppendFingerprintSteamIDOrIPCallback(Database dtb, DBResultSet results, const char[] error, any data)
{
        if(error[0])
                SetFailState("Failed to update fingerprint steamID or IP: %s", error);

}

bool ForceShiftFingerprintQueuePosition(int client)
{
        if(engineVersion == Engine_CSGO)
                return false;

        Address netChanAddress = FileNet_GetNetChanPtr(client);
        if(netChanAddress == Address_Null)
                return false;

        CNetChan netchan = CNetChan(netChanAddress);
        CUtlVector waitingList = netchan.m_WaitingList(1);
        if(waitingList.m_Size() <= 3)
                return false;


        DataFragments swapWith = waitingList.GetAt(waitingList.m_Size() - 1);
        char filename[PLATFORM_MAX_PATH];
        swapWith.filename(filename, sizeof(filename));

        DataFragments toSwap = waitingList.GetAt(1);
        waitingList.SetAt(1, swapWith);
        waitingList.SetAt(waitingList.m_Size() - 1, toSwap);
        return true;
}

void GenerateLocalFingerprintAndSendToClient(int client, const char[] existingFingerprint = "")
{
        if(currentUserId != GetClientUserId(client))
        {
                currentUserId = INVALID_USERID;
                clientQueueState[client] = QueueState_Ignore;
                globalLocked = false;
                return;
        }
        char uniqueFingerprint[256], steamID2[128], ip[256], query[1024];

        if(!existingFingerprint[0]) //if existingFingerprint is empty (i.e. we didn't identify them through SteamID and IP and failed to query their local fingerprint ), send the fingerprint that we generated during connection
        {
                char steamid[64];
                GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
                if(!steamIDToTemporaryFingerrpints.ContainsKey(steamid))
                {
                        currentUserId = INVALID_USERID;
                        clientQueueState[client] = QueueState_Ignore;
                        globalLocked = false;
                        return;
                }
                steamIDToTemporaryFingerrpints.GetString(steamid, uniqueFingerprint, sizeof(uniqueFingerprint));
                steamIDToTemporaryFingerrpints.Remove(steamid);
        }
        else //otherwise we're sending an existng fingerprint, so dont create a new one
        {
                strcopy(uniqueFingerprint, sizeof(uniqueFingerprint), existingFingerprint);
        }


        File file = OpenFile(fingerprintPath, "w+", true, "download");
        if(file == null)
        {
                SetFailState("Unable to create or open fingerprint file '%s'. Please build the path to this file!", fingerprintPath);
        }
        file.WriteString(uniqueFingerprint, false);
        file.Flush();
        file.Close();
        DataPack pack = new DataPack();
        pack.WriteString(uniqueFingerprint);
        pack.WriteCell(client);

        WriteLog("Attempting to send fingerprint via File Network...", LogLevel_Debug);
        if(!FileNet_SendFile(client, fingerprintPath, OnFingerprintFirstSent, pack))
        { //we failed to queue the fingerprint for some reason, wtf?
                clientQueueState[client] = QueueState_Ignore;
                currentUserId = INVALID_USERID;
                globalLocked = false;
                return;
        }
        ForceShiftFingerprintQueuePosition(client);
        if(!existingFingerprint[0])
        {
                GetClientAuthId(client, AuthId_Steam2, steamID2, sizeof(steamID2));
                GetClientIP(client, ip, sizeof(ip));
                Format(query, sizeof(query), "INSERT INTO rebanner_fingerprints (fingerprint, steamid2, is_banned, banned_duration, banned_timestamp, ip) VALUES ('%s', '%s', 0, 0, 0, '%s')", uniqueFingerprint, steamID2, ip);
                db.Query(OnFingerprintRelationSaved, query); //save new fingerprint
                DataPack fingerprintPack = new DataPack();
                fingerprintPack.WriteString(steamID2);
                fingerprintPack.WriteCell(0);
                fingerprintPack.WriteCell(0);
                fingerprintPack.WriteCell(0);
                fingerprintPack.WriteString(ip);
                fingerprintTable.SetValue(uniqueFingerprint, fingerprintPack);
                steamIDToFingerprintTable.SetString(steamID2, uniqueFingerprint);
                ipToFingerprintTable.SetString(ip, uniqueFingerprint);
                Format(query, sizeof(query), "INSERT INTO rebanner_steamids (steamid2, fingerprint) VALUES ('%s', '%s')", steamID2, uniqueFingerprint);
                db.Query(OnFingerprintRelationSaved, query); //save new steamid-fingerprint relation

                if(shouldCheckIP.BoolValue)
                {
                        Format(query, sizeof(query), "INSERT INTO rebanner_ips (ip, fingerprint) VALUES ('%s', '%s')", ip, uniqueFingerprint);
                        db.Query(OnFingerprintRelationSaved, query); //save new ip-fingerprint relation
                }

        }
}

void OnFingerprintFirstSent(int client, const char[] file, bool success, DataPack pack)
{
        if(!success)
        {
                WriteLog("Failed to send fingerpint via File Network.", LogLevel_Debug);
                currentUserId=INVALID_USERID;
                clientQueueState[client] = QueueState_Ignore;
                globalLocked = false;
        }
        else
        {
                Format(logMessageRB, sizeof(logMessageRB), "Sent fingerprint file of client %N via File Network.", client);
                WriteLog(logMessageRB, LogLevel_Debug);

                if(FileExists(fingerprintPath, true, "download"))
                        DeleteFile(fingerprintPath, true, "download");
        }
        WriteLog("Processing client fingerprint. Checking for bans...", LogLevel_Debug);

        pack.Reset();
        char fingerprint[128];
        pack.ReadString(fingerprint, sizeof(fingerprint));
        delete pack;
        if(bannedFingerprints.ContainsKey(fingerprint)) //client is banned
        {
                RebanClient(client, fingerprint);
        }
        else
        {
                currentUserId=INVALID_USERID;
                clientQueueState[client] = QueueState_Ignore;
                globalLocked = false;
        }
}

void RebanClient(int client, const char[] fingerprint, const char[] reason = BAN_REASON)
{
        char query[512];
        Format(logMessageRB, sizeof(logMessageRB), "Processing ban event of client %N", client);
        WriteLog(logMessageRB, LogLevel_Bans);
        Format(query, sizeof(query), "SELECT banned_duration, banned_timestamp FROM rebanner_fingerprints WHERE fingerprint = '%s'", fingerprint);
        DataPack pack = new DataPack();
        pack.WriteCell(client);
        pack.WriteString(fingerprint);
        pack.WriteString(reason);
        db.Query(RebanClientQueryResult, query, pack);
}

public void RebanClientQueryResult(Database dtb, DBResultSet results, const char[] error, DataPack pack)
{
        if(error[0])
                ThrowError("Failed to query banned fingerprint data: %s", error);

        if(results.FetchRow())
        {
                pack.Reset();
                int client = pack.ReadCell();
                if(currentUserId != GetClientUserId(client))
                {
                        currentUserId = INVALID_USERID;
                        clientQueueState[client] = QueueState_Ignore;
                        globalLocked = false;
                        return;
                }
                char fingerprint[128], reason[256];
                pack.ReadString(fingerprint, sizeof(fingerprint));
                pack.ReadString(reason, sizeof(reason));
                delete pack;
                int duration = results.FetchInt(0);
                int banned_timestamp = results.FetchInt(1);
                if(rebanDuration.BoolValue)
                {
                        BanClient(client, duration, BANFLAG_AUTO, reason, reason, "reban", client);
                }
                else
                {
                        int remainingDuration = duration - ((GetTime() - banned_timestamp)/60);
                        if(remainingDuration < 0)
                                remainingDuration = 0;
                        BanClient(client, remainingDuration, BANFLAG_AUTO, reason, reason, "reban", client);
                }
                bannedFingerprints.SetString(fingerprint, "", false);
                currentUserId = INVALID_USERID;
                globalLocked = false;
                clientQueueState[client] = QueueState_Ignore;

        }
}

void CreateOrResendClientFingerprint(int client)
{
        if(currentUserId != GetClientUserId(client))
        {
                currentUserId = INVALID_USERID;
                clientQueueState[client] = QueueState_Ignore;
                globalLocked = false;
                return;
        }
        char steamid2[64], query[512];
        GetClientAuthId(client, AuthId_Steam2, steamid2, sizeof(steamid2));
        char ip[64];
        GetClientIP(client, ip, sizeof(ip));
        if(steamIDToFingerprintTable.ContainsKey(steamid2)) //if we match a steamID to a fingerprint
        {
                char fingerprint[128];
                steamIDToFingerprintTable.GetString(steamid2, fingerprint, sizeof(fingerprint));
                if(!ipToFingerprintTable.ContainsKey(ip) && shouldCheckIP.BoolValue) //and if we haven't recorded this IP yet
                {
                        Format(query, sizeof(query), "INSERT INTO rebanner_ips (ip, fingerprint) VALUES ('%s', '%s')", ip, fingerprint);
                        db.Query(OnFingerprintRelationSaved, query); //save new ip-fingerprint relation
                        UpdateMainFingerprintRecordWithNewSteamIDAndOrIP(fingerprint, "", ip);
                }
                Format(logMessageRB, sizeof(logMessageRB), "Found existing fingerprint record (%s) by SteamID match (%s). Sending via File Network.", fingerprint, steamid2);
                WriteLog(logMessageRB, LogLevel_Associations);

                GenerateLocalFingerprintAndSendToClient(client, fingerprint);
        }
        else
        {
                if(ipToFingerprintTable.ContainsKey(ip) && shouldCheckIP.BoolValue) //if we match a steamID to an ip
                {
                        char fingerprint[128];
                        ipToFingerprintTable.GetString(ip, fingerprint, sizeof(fingerprint));
                        Format(logMessageRB, sizeof(logMessageRB), "Found existing fingerprint record (%s) by IP match (%s). Sending via File Network.", fingerprint, ip);
                        WriteLog(logMessageRB, LogLevel_Associations);
                        GenerateLocalFingerprintAndSendToClient(client, fingerprint);
                        Format(query, sizeof(query), "INSERT INTO rebanner_steamids (steamid2, fingerprint) VALUES ('%s', '%s')", steamid2, fingerprint);
                        db.Query(OnFingerprintRelationSaved, query); //save new steamid-fingerprint relation
                        UpdateMainFingerprintRecordWithNewSteamIDAndOrIP(fingerprint, steamid2, "");
                }
                else //if we're out of options and we don't recognize this client. Send the fingerprint that we generated during connection
                {

                        Format(logMessageRB, sizeof(logMessageRB), "Unable to recognize client by SteamID and IP, and unable to query local fingerprint. Sending fingerprint via File Network.", client);
                        WriteLog(logMessageRB, LogLevel_Debug);

                        GenerateLocalFingerprintAndSendToClient(client);
                }

        }
}

void WriteLog(const char[] message, LogLevel level)
{
        LogLevel currentLogLevel = view_as<LogLevel>(logLevel.IntValue);
        if(currentLogLevel >= level)
        {
                File logFile;
                BuildPath(Path_SM, logFilePath, PLATFORM_MAX_PATH, LOGFILE);
                logFile = OpenFile(logFilePath, "a");
                logFile.WriteLine("%s %s", logLevelDefinitions[level], message);
                logFile.Close();
                //PrintToServer(message);
        }

}

void OnFingerprintRelationSaved(Database dtb, DBResultSet results, const char[] error, any data)
{
        if(error[0])
                SetFailState("Failed to parse database: %s", error);

}

public Action Command_UnbanBySteamID(int client, int args)
{
        if(args != 1)
        {
                PrintToChat(client, "You need to provide a SteamID (STEAM_X:X:XXXXXXXXX).");
                return Plugin_Handled;
        }
        char steamid[64];
        GetCmdArg(1, steamid, sizeof(steamid));
        if(TryUnbanBySteamIDOrIP(steamid))
        {
                PrintToChat(client, "Successfully removed ban record from SteamID %s.", steamid);
                return Plugin_Handled;
        }
        else
        {
                PrintToChat(client, "Failed to match %s to a known fingerprint or it's not banned. Aborting.", steamid);
                return Plugin_Handled;
        }
}

public Action Command_UnbanByIP(int client, int args)
{
        if(args != 1)
        {
                PrintToChat(client, "You need to provide an IP address.");
                return Plugin_Handled;
        }
        char ip[64];
        GetCmdArg(1, ip, sizeof(ip));
        if(TryUnbanBySteamIDOrIP("", ip))
        {
                PrintToChat(client, "Successfully removed ban record from IP address %s.", ip);
                return Plugin_Handled;
        }
        else
        {
                PrintToChat(client, "Failed to match %s to a known fingerprint or it's not banned. Aborting.", ip);
                return Plugin_Handled;
        }
}

bool TryUnbanBySteamIDOrIP(const char[] steamid="", const char[] ip="")
{
        if(steamid[0])
        {
                if(steamIDToFingerprintTable.ContainsKey(steamid))
                {
                        char fingerprint[128];
                        steamIDToFingerprintTable.GetString(steamid, fingerprint, sizeof(fingerprint));
                        if(bannedFingerprints.ContainsKey(fingerprint))
                        {
                                bannedFingerprints.Remove(fingerprint);
                                Format(logMessageRB, sizeof(logMessageRB), "Removing ban flag from %s", steamid);
                                WriteLog(logMessageRB, LogLevel_Debug);
                                char query[512];
                                Format(query, sizeof(query), "UPDATE rebanner_fingerprints SET is_banned = 0, banned_duration = 0, banned_timestamp = 0 WHERE fingerprint = '%s'", fingerprint);
                                db.Query(ClientBanRecordRemoved, query);
                                return true;
                        }
                }
        }
        if(ip[0])
        {
                if(ipToFingerprintTable.ContainsKey(ip))
                {
                        char fingerprint[128];
                        ipToFingerprintTable.GetString(ip, fingerprint, sizeof(fingerprint));
                        if(bannedFingerprints.ContainsKey(fingerprint))
                        {
                                bannedFingerprints.Remove(fingerprint);
                                Format(logMessageRB, sizeof(logMessageRB), "Removing ban flag from %s", ip);
                                WriteLog(logMessageRB, LogLevel_Debug);
                                char query[512];
                                Format(query, sizeof(query), "UPDATE rebanner_fingerprints SET is_banned = 0, banned_duration = 0, banned_timestamp = 0 WHERE fingerprint = '%s'", fingerprint);
                                db.Query(ClientBanRecordRemoved, query);
                                return true;
                        }
                }
        }
        return false;
}

void checkOS()
{
        char cmdline[256];
        GetCommandLine(cmdline, sizeof(cmdline));

        if (StrContains(cmdline, "./srcds_linux ", false) != -1)
        {
                os = OS_Linux;
        }
        else if (StrContains(cmdline, ".exe", false) != -1)
        {
                os = OS_Windows;
        }
        else
        {
                os = OS_Unknown;
        }
}

stock bool IsValidClient(int client, bool replaycheck=false, bool onlyrealclients=true) //stock that checks if the client is valid(not bot, connected, in game, authorized etc)
{
        if(client<=0 || client>MaxClients)
        {
                return false;
        }

        if(!IsClientInGame(client))
        {
                return false;
        }

        if(onlyrealclients)
        {
                if(IsFakeClient(client))
                        return false;
        }

        if(replaycheck)
        {
                if(IsClientSourceTV(client) || IsClientReplay(client))
                {
                        return false;
                }
        }

        return true;
}
