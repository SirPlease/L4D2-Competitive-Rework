#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <dhooks>

#define GAMEDATA         "l4d2_npc_manager"
#define GAMEDATA_VERSION 27

methodmap GameDataWrapper < GameData
{

    public  GameDataWrapper(const char[] file)
    {
        GameData gd = new GameData(file);
        if (!gd) SetFailState("[GameData] Missing gamedata of file \"%s\".", file);
        return view_as<GameDataWrapper>(gd);
    }

    public  DynamicDetour CreateDetourOrFail(const char[] name,
                                     bool          bNow     = true,
                                     DHookCallback preHook  = INVALID_FUNCTION,
                                     DHookCallback postHook = INVALID_FUNCTION)
    {
        DynamicDetour hSetup = DynamicDetour.FromConf(this, name);

        if (!hSetup)
            SetFailState("[Detour] Missing detour setup section \"%s\".", name);

        if (bNow)
        {
            if (preHook != INVALID_FUNCTION && !hSetup.Enable(Hook_Pre, preHook))
                SetFailState("[Detour] Failed to pre-detour of section \"%s\".", name);

            if (postHook != INVALID_FUNCTION && !hSetup.Enable(Hook_Post, postHook))
                SetFailState("[Detour] Failed to post-detour of section \"%s\".", name);
        }

        return hSetup;
    }
}
DynamicDetour g_hShouldUpdate;
Address       g_pNextBotManager;
Handle        g_hSDK_CallGetEntity;

ConVar        g_hCvar_Origin_UpdateFrequency;
ConVar        g_hCvar_Plugins;

enum
{
    NPC_COMMON = 0,
    NPC_SMOKER,
    NPC_BOOMER,
    NPC_HUNTER,
    NPC_SPITTER,
    NPC_JOCKEY,
    NPC_CHARGER,
    NPC_WITCH,
    NPC_TANK,
    NPC_SURVIVOR_BOT,
    NPC_COUNT
};

ConVar        g_hCvar_UpdateFrequency[NPC_COUNT];

enum struct EntityIDData
{
    int entity;
    int class;
}

EntityIDData
     m_botlist[2048];

bool
    g_bPlugins,
    g_bLinuxOS;

int
    updatetick;

float
    g_fUpdateFrequency[NPC_COUNT];

public Plugin myinfo =
{
    name        = "l4d2_npc_manager",
    author      = "洛琪,小燐RM",    //特别感谢小燐RM为我提供了win 签名支持 Thanks For 小燐RM Support for Windows Signature
    description = "插件控制每种特感、僵尸的刷新率，不同特感可以不同刷新率，适用tank、witch、小僵尸和特感",
    version     = "1.0",
    url         = "https://steamcommunity.com/profiles/76561198812009299/"
};

public void OnPluginStart()
{
    g_hCvar_Origin_UpdateFrequency = FindConVar("nb_update_frequency");
    g_hCvar_Plugins                = CreateConVar("nb_uf_onoff", "1", "插件是否接管update frequency,1接管,0不接管", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_hCvar_UpdateFrequency[NPC_COMMON]       = CreateConVar("nb_uf_Common", "0.02", "Common的update frequency更新频率.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_hCvar_UpdateFrequency[NPC_SMOKER]       = CreateConVar("nb_uf_Smoker", "0.02", "Smoker的update frequency更新频率.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_hCvar_UpdateFrequency[NPC_BOOMER]       = CreateConVar("nb_uf_Boomer", "0.03", "Boomer的update frequency更新频率.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_hCvar_UpdateFrequency[NPC_HUNTER]       = CreateConVar("nb_uf_Hunter", "0.03", "Hunter的update frequency更新频率.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_hCvar_UpdateFrequency[NPC_SPITTER]      = CreateConVar("nb_uf_Spitter", "0.1", "Spitter的update frequency更新频率.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_hCvar_UpdateFrequency[NPC_JOCKEY]       = CreateConVar("nb_uf_Jockey", "0.1", "Jockey的update frequency更新频率.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_hCvar_UpdateFrequency[NPC_CHARGER]      = CreateConVar("nb_uf_Charger", "0.03", "Charger的update frequency更新频率.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_hCvar_UpdateFrequency[NPC_WITCH]        = CreateConVar("nb_uf_Witch", "0.01", "Witch的update frequency更新频率.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_hCvar_UpdateFrequency[NPC_TANK]         = CreateConVar("nb_uf_Tank", "0.03", "Tank的update frequency更新频率.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_hCvar_UpdateFrequency[NPC_SURVIVOR_BOT] = CreateConVar("nb_uf_sb", "0.1", "Survivor Bot的update frequency更新频率.", FCVAR_NOTIFY, true, 0.0, true, 1.0);

    for (int i = 0; i < NPC_COUNT; i++)
    {
        g_hCvar_UpdateFrequency[i].AddChangeHook(OnCvarChnaged);
    }

    g_hCvar_Plugins.AddChangeHook(OnCvarChnaged);
    g_hCvar_Origin_UpdateFrequency.AddChangeHook(OnCvarChnaged);
    HookEvent("round_start_pre_entity", Event_RoundStart, EventHookMode_PostNoCopy);
    InItGameData();
}

public void OnConfigsExecuted()
{
    UpdateCvars();
}

void OnCvarChnaged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    UpdateCvars();
}

void UpdateCvars()
{
    bool g_bTemp = g_hCvar_Plugins.BoolValue;
    if (g_bTemp != g_bPlugins)
    {
        if (g_bTemp)
            g_hShouldUpdate.Enable(Hook_Pre, DTR_NextBotManager_ShouldUpdate_Pre);
        else
            g_hShouldUpdate.Disable(Hook_Pre, DTR_NextBotManager_ShouldUpdate_Pre);
        g_bPlugins = g_bTemp;
    }
    float tickinterval = GetTickInterval();
    for (int i = 0; i < NPC_COUNT; i++)
    {
        g_fUpdateFrequency[i] = g_hCvar_UpdateFrequency[i].FloatValue;
        g_fUpdateFrequency[i] = g_fUpdateFrequency[i] <= tickinterval ? tickinterval : g_fUpdateFrequency[i];
    }
    updatetick = RoundToNearest(g_hCvar_Origin_UpdateFrequency.FloatValue / tickinterval);
    updatetick = updatetick < 1 ? 1 : updatetick;
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    for (int i = 0; i < 2048; i++)
    {
        m_botlist[i].entity = -1;
        m_botlist[i].class  = -1;
    }
}

MRESReturn DTR_NextBotManager_Register_Post(Address pManager, DHookReturn hReturn, DHookParam hParams)
{
    Address pBot = Address_Null;
    pBot         = hParams.GetAddress(1);
    RequestFrame(UpdateNextBotID, pBot);
    return MRES_Ignored;
}

MRESReturn DTR_NextBotManager_UnRegister_Post(Address pManager, DHookReturn hReturn, DHookParam hParams)
{
    int ptr               = hParams.GetObjectVar(1, 8, ObjectValueType_Int);
    m_botlist[ptr].entity = -1;
    return MRES_Ignored;
}

// [Helps]:偏移维护：如果求生更新导致偏移改变,请对照NextBotManager::Reset的反汇编代码修复偏移
void UpdateNextBotID(Address pBot)
{
    if (!g_pNextBotManager) return;

    int head = LoadFromAddress(g_pNextBotManager + view_as<Address>(g_bLinuxOS ? 16 : 20), NumberType_Int16);
    if (head == 0xFFFF) return;

    Address nodeArray = view_as<Address>(LoadFromAddress(g_pNextBotManager + view_as<Address>(g_bLinuxOS ? 4 : 8), NumberType_Int32));
    if (nodeArray == Address_Null) return;

    int current        = head;
    int maxIterations  = 2048;
    int iterationCount = 0;

    int botptr = -1, ptr = -1;
    botptr = LoadFromAddress(pBot + view_as<Address>(8), NumberType_Int32);
    while (current != 0xFFFF && iterationCount++ < maxIterations)
    {
        Address node     = nodeArray + view_as<Address>(current * 8);
        Address pNextBot = view_as<Address>(LoadFromAddress(node, NumberType_Int32));
        if (pNextBot != Address_Null)
        {
            ptr = view_as<int>(LoadFromAddress(pNextBot + view_as<Address>(8), NumberType_Int32));
            if (ptr == botptr)
            {
                int entity = SDKCall(g_hSDK_CallGetEntity, pNextBot);
                if (IsValidEntity(entity))
                {
                    m_botlist[ptr].entity = entity;
                    m_botlist[ptr].class  = GetEntityClassID(entity);
                    break;
                }
            }
        }
        current = LoadFromAddress(node + view_as<Address>(6), NumberType_Int16);
    }
}

int GetEntityClassID(int entity)
{
    if (0 < entity < MaxClients + 1)
        return GetEntProp(entity, Prop_Send, "m_zombieClass");

    char classname[64];
    GetEdictClassname(entity, classname, sizeof(classname));
    if (StrEqual(classname, "infected", false))
        return 0;

    if (StrEqual(classname, "witch", false))
        return 7;
    return -1;
}

MRESReturn DTR_NextBotManager_ShouldUpdate_Pre(Address pManager, DHookReturn hReturn, DHookParam hParams)
{
    int ptr = hParams.GetObjectVar(1, 8, ObjectValueType_Int);
    if (m_botlist[ptr].entity != -1)
    {
        int current = GetGameTickCount();
        int class   = m_botlist[ptr].class;
        if (class == -1) return MRES_Ignored;

        int last   = hParams.GetObjectVar(1, 16, ObjectValueType_Int);
        int update = RoundToNearest(g_fUpdateFrequency[m_botlist[ptr].class] / GetTickInterval());
        if (current < last + update)
        {
            hReturn.Value = 0;
            return MRES_Supercede;
        }
        else
        {
            hParams.SetObjectVar(1, 12, ObjectValueType_Bool, true);
            if (update < updatetick)
                hParams.SetObjectVar(1, 16, ObjectValueType_Int, last + update - updatetick);
            return MRES_ChangedHandled;
        }
    }
    return MRES_Ignored;
}

void InItGameData()
{
    CheckGameDataFile();

    GameDataWrapper gd = new GameDataWrapper(GAMEDATA);
    g_bLinuxOS         = gd.GetOffset("OS") == 1;
    g_hShouldUpdate    = gd.CreateDetourOrFail("NextBotManager::ShouldUpdate", true, DTR_NextBotManager_ShouldUpdate_Pre);

    delete gd.CreateDetourOrFail("NextBotManager::Register", true, _, DTR_NextBotManager_Register_Post);
    delete gd.CreateDetourOrFail("NextBotManager::UnRegister", true, _, DTR_NextBotManager_UnRegister_Post);

    Handle g_hSDK_NextBotManager;
    StartPrepSDKCall(SDKCall_Static);
    PrepSDKCall_SetFromConf(gd, SDKConf_Signature, "TheNextBots");
    PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
    g_hSDK_NextBotManager = EndPrepSDKCall();

    g_pNextBotManager     = view_as<Address>(SDKCall(g_hSDK_NextBotManager));

    StartPrepSDKCall(SDKCall_Raw);
    PrepSDKCall_SetVirtual(g_bLinuxOS ? 45 : 44);
    PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
    g_hSDK_CallGetEntity = EndPrepSDKCall();
    delete gd;
}

void CheckGameDataFile()
{
    char sPath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, sPath, sizeof(sPath), "gamedata/%s.txt", GAMEDATA);
    File hFile;
    bool bNeedUpdate = false;
    if (FileExists(sPath))
    {
        char buffer1[64], buffer2[64];
        hFile = OpenFile(sPath, "r", false);
        if (hFile != null)
        {
            if (hFile.ReadLine(buffer1, sizeof(buffer1)))
            {
                FormatEx(buffer2, sizeof(buffer2), "//%d\n", GAMEDATA_VERSION);
                if (!StrEqual(buffer1, buffer2, false))
                    bNeedUpdate = true;
            }
            else
            {
                bNeedUpdate = true;
            }
            delete hFile;
            hFile = null;
        }
    }
    else
    {
        bNeedUpdate = true;
    }

    if (bNeedUpdate)
    {
        hFile = OpenFile(sPath, "w", false);    // 覆盖写入
        if (hFile != null)
        {
            hFile.WriteLine("//%d", GAMEDATA_VERSION);
            hFile.WriteLine("\"Games\"");
            hFile.WriteLine("{");
            hFile.WriteLine("	\"left4dead2\"");
            hFile.WriteLine("	{");
            hFile.WriteLine("		\"Signatures\"");
            hFile.WriteLine("		{");
            hFile.WriteLine("			\"NextBotManager::ShouldUpdate\"");
            hFile.WriteLine("			{");
            hFile.WriteLine("				\"library\" \"server\"");
            hFile.WriteLine("				\"linux\"		\"@_ZN14NextBotManager12ShouldUpdateEP8INextBot\"");
            hFile.WriteLine("				\"windows\"	\"\\x55\\x8B\\xEC\\x83\\xEC\\x08\\x57\\x8B\\xF9\\x83\\x7F\\x24\\x01\"");
            hFile.WriteLine("			}");
            hFile.WriteLine("");
            hFile.WriteLine("			\"NextBotManager::Register\"");
            hFile.WriteLine("			{");
            hFile.WriteLine("				\"library\" \"server\"");
            hFile.WriteLine("				\"linux\"		\"@_ZN14NextBotManager8RegisterEP8INextBot\"");
            hFile.WriteLine("				\"windows\"	\"\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x79\\x08\\x6A\\x00\"");
            hFile.WriteLine("			}");
            hFile.WriteLine("");
            hFile.WriteLine("			\"NextBotManager::UnRegister\"");
            hFile.WriteLine("			{");
            hFile.WriteLine("				\"library\" \"server\"");
            hFile.WriteLine("				\"linux\"		\"@_ZN14NextBotManager10UnRegisterEP8INextBot\"");
            hFile.WriteLine("				\"windows\"	\"\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x53\\x56\\x57\\x8B\\x78\\x08\"");
            hFile.WriteLine("			}");
            hFile.WriteLine("");
            hFile.WriteLine("			\"TheNextBots\"");
            hFile.WriteLine("			{");
            hFile.WriteLine("				\"library\" \"server\"");
            hFile.WriteLine("				\"linux\"		\"@_Z11TheNextBotsv\"");
            hFile.WriteLine("				\"windows\"	\"\\xB8\\x01\\x00\\x00\\x00\\x84\\x05\\x2A\\x2A\\x2A\\x2A\\x0F\\x85\\x2A\\x2A\\x2A\\x2A\\x09\\x05\\x2A\\x2A\\x2A\\x2A\\x33\\xC0\"");
            hFile.WriteLine("			}");
            hFile.WriteLine("");
            hFile.WriteLine("		}");
            hFile.WriteLine("		\"Offsets\"");
            hFile.WriteLine("		{");
            hFile.WriteLine("			\"OS\"");
            hFile.WriteLine("			{");
            hFile.WriteLine("				\"linux\"		\"1\"");
            hFile.WriteLine("				\"windows\"	    \"0\"");
            hFile.WriteLine("			}");
            hFile.WriteLine("");
            hFile.WriteLine("		}");
            hFile.WriteLine("");
            hFile.WriteLine("		\"Functions\"");
            hFile.WriteLine("		{");
            hFile.WriteLine("			\"NextBotManager::ShouldUpdate\"");
            hFile.WriteLine("			{");
            hFile.WriteLine("				\"signature\" \"NextBotManager::ShouldUpdate\"");
            hFile.WriteLine("				\"callconv\" \"thiscall\"");
            hFile.WriteLine("				\"return\" \"bool\"");
            hFile.WriteLine("				\"this\" \"address\"");
            hFile.WriteLine("				\"arguments\"");
            hFile.WriteLine("				{");
            hFile.WriteLine("					\"INextBot\"");
            hFile.WriteLine("					{");
            hFile.WriteLine("						\"type\" \"objectptr\"");
            hFile.WriteLine("					}");
            hFile.WriteLine("				}");
            hFile.WriteLine("			}");
            hFile.WriteLine("");
            hFile.WriteLine("			\"NextBotManager::Register\"");
            hFile.WriteLine("			{");
            hFile.WriteLine("				\"signature\" \"NextBotManager::Register\"");
            hFile.WriteLine("				\"callconv\" \"thiscall\"");
            hFile.WriteLine("				\"return\" \"int\"");
            hFile.WriteLine("				\"this\" \"address\"");
            hFile.WriteLine("				\"arguments\"");
            hFile.WriteLine("				{");
            hFile.WriteLine("					\"INextBot\"");
            hFile.WriteLine("					{");
            hFile.WriteLine("						\"type\" \"objectptr\"");
            hFile.WriteLine("					}");
            hFile.WriteLine("				}");
            hFile.WriteLine("			}");
            hFile.WriteLine("");
            hFile.WriteLine("			\"NextBotManager::UnRegister\"");
            hFile.WriteLine("			{");
            hFile.WriteLine("				\"signature\" \"NextBotManager::UnRegister\"");
            hFile.WriteLine("				\"callconv\" \"thiscall\"");
            hFile.WriteLine("				\"return\" \"int\"");
            hFile.WriteLine("				\"this\" \"address\"");
            hFile.WriteLine("				\"arguments\"");
            hFile.WriteLine("				{");
            hFile.WriteLine("					\"INextBot\"");
            hFile.WriteLine("					{");
            hFile.WriteLine("						\"type\" \"objectptr\"");
            hFile.WriteLine("					}");
            hFile.WriteLine("				}");
            hFile.WriteLine("			}");
            hFile.WriteLine("");
            hFile.WriteLine("		}");
            hFile.WriteLine("	}");
            hFile.WriteLine("}");

            FlushFile(hFile);
            delete hFile;
            hFile = null;
        }
    }

    delete hFile;
}
