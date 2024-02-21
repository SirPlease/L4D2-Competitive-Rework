#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

#define PLUGIN_VERSION "1.0.7"

#define TEST_DEBUG 0
#define TEST_DEBUG_LOG 1


static const String:SURRENDER_BUTTON_STRING[]      = "RELOAD"; // what is shown in the Notification as Button to press
static const SURRENDER_BUTTON                       = IN_RELOAD; // Sourcemod Button definition. Alternatives: IN_DUCK, IN_USE

static const String:GAMEDATA_FILENAME[]             = "l4d2addresses";
static const String:GHOST_ENTPROP[]                 = "m_isGhost";
static const String:CLASS_ENTPROP[]                 = "m_zombieClass";
static const Float:CONTROL_DELAY_SAFETY             = 0.3;
static const Float:CONTROL_RETRY_DELAY              = 2.0;
static const TEAM_INFECTED                          = 3;
static const ZOMBIECLASS_TANK                       = 8;


static Handle:cvar_SurrenderTimeLimit               = INVALID_HANDLE;
static Handle:cvar_SurrenderChoiceType              = INVALID_HANDLE;
static Handle:surrenderMenu                         = INVALID_HANDLE;

static bool:withinTimeLimit                         = false;
static bool:isFinale                                = false;
static primaryTankPlayer                            = -1;
static tankAttemptsFailed                         = 0;

static Handle:sdkTakeOverZombieBot = INVALID_HANDLE;
static Handle:sdkReplaceWithBot = INVALID_HANDLE;
static Handle:sdkCullZombie = INVALID_HANDLE;
static Handle:sdkReplaceTank = INVALID_HANDLE;
static Address:g_pZombieManager;

Handle IsTankPass = INVALID_HANDLE;

public Plugin:myinfo = 
{
    name = "L4D2 Tank Swap",
    author = "AtomicStryker",
    description = " Allows a primary Tank Player to surrender control to one of his teammates, or admins to take it anytime ",
    version = PLUGIN_VERSION,
    url = "http://forums.alliedmods.net/showthread.php?t=120807"
}

#define TRANSLATION_FILE "l4d2_tankswap.phrases"
void LoadPluginTranslations()
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "translations/"...TRANSLATION_FILE...".txt");
	if (!FileExists(sPath))
	{
		SetFailState("Missing translation \""...TRANSLATION_FILE..."\"");
	}
	LoadTranslations(TRANSLATION_FILE);
}
public OnPluginStart()
{
    Require_L4D2();
    LoadPluginTranslations();
    
    PrepSDKCalls();
	IsTankPass = CreateGlobalForward("OnIsTankPass", ET_Ignore);
    CreateConVar("l4d2_tankswap_version", PLUGIN_VERSION, " Version of L4D2 Tank Swap on this server ", FCVAR_NOTIFY|FCVAR_SPONLY|FCVAR_DONTRECORD);
    cvar_SurrenderTimeLimit = CreateConVar("l4d2_tankswap_timelimit", "10", " How many seconds can a primary Tank Player surrender control ", FCVAR_NOTIFY);
    cvar_SurrenderChoiceType = CreateConVar("l4d2_tankswap_choicetype", "2", " 0 - Disabled; 1 - press Button to call Menu; 2 - Menu appears for every Tank ", FCVAR_NOTIFY);
    
    RegAdminCmd("sm_taketank", TS_CMD_TakeTank, ADMFLAG_CHEATS, " Take over the current Tank ");
    
    LoadTranslations("common.phrases");
    
    HookEvent("finale_start", _FinaleStart_Event, EventHookMode_PostNoCopy);
    HookEvent("round_end", _RoundEnd_Event, EventHookMode_PostNoCopy);
}

public Action:_RoundEnd_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
    isFinale = false;
}

public Action:_FinaleStart_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
    isFinale = true;
}

stock Require_L4D2()
{
    decl String:game[32];
    GetGameFolderName(game, sizeof(game));
    if (!StrEqual(game, "left4dead2", false))
    {
        SetFailState("Plugin supports Left 4 Dead 2 only.");
    }
    RegPluginLibrary("tankswap");
}

public Action:TS_CMD_TakeTank(client, args)
{
    if (!client) return Plugin_Handled;
    
    new target = FindHumanTankPlayer();
    
    if (!target)
    {
        ReplyToCommand(client, "没得坦克给你操控");
        return Plugin_Handled;
    }
    else if (target == client)
    {
        ReplyToCommand(client, "Dont try to use dangerous SDKCalls with experimental inputs.");
        return Plugin_Handled;
    }
    
    if (CancelClientMenu(target))
    {
        DebugPrintToAll("TakeTank Command used while client menu was active, shutting down client menu");
        withinTimeLimit = false;
        surrenderMenu = INVALID_HANDLE;
    }
    
    if (GetClientHealth(client) > 1 && !IsPlayerGhost(client))
    {
        L4D2_ReplaceWithBot(client, true);
    }
    L4D2_ReplaceTank(target, client);
    return Plugin_Handled;
}

public Action:L4D_OnSpawnTank(const Float:vector[3], const Float:qangle[3])
{
    DebugPrintToAll("L4D_OnSpawnTank fired, creating Timer");
    
    new Float:PlayerControlDelay = GetConVarFloat(FindConVar("director_tank_lottery_selection_time"));
    
    if (!isFinale)
    {
        tankAttemptsFailed = 0;
        switch (GetConVarInt(cvar_SurrenderChoiceType))
        {
            case 0:     return Plugin_Continue;
            case 1:     CreateTimer(PlayerControlDelay + CONTROL_DELAY_SAFETY, TS_DisplayNotificationToTank);
            case 2:     CreateTimer(PlayerControlDelay + CONTROL_DELAY_SAFETY, TS_Display_Auto_MenuToTank);
        }
    }
    
    return Plugin_Continue;
}

public Action:TS_DisplayNotificationToTank(Handle:timer)
{
    primaryTankPlayer = FindHumanTankPlayer();
    if (!primaryTankPlayer)
    {
        tankAttemptsFailed++;
        if (tankAttemptsFailed < 5)
        {
            DebugPrintToAll("FindHumanTankPlayer didnt find a human tank, retrying in 2 seconds");
            CreateTimer(CONTROL_RETRY_DELAY, TS_DisplayNotificationToTank);
        }
        return Plugin_Stop;
    }
    
    withinTimeLimit = true;
    new Float:SurrenderTimeLimit = GetConVarFloat(cvar_SurrenderTimeLimit);
    CreateTimer(SurrenderTimeLimit, TS_TimeLimitIsOver);
    PrintToChat(primaryTankPlayer, "\x04[Tank Swap]\x01 You can \x03surrender Tank Control\x01 during the next \x04%i seconds\x01 to one of your teammates by pressing \x04%s\x01", RoundFloat(SurrenderTimeLimit), SURRENDER_BUTTON_STRING);
    return Plugin_Stop;
}

public Action:TS_TimeLimitIsOver(Handle:timer)
{
    withinTimeLimit = false;
    if (surrenderMenu != INVALID_HANDLE)
    {
        surrenderMenu = INVALID_HANDLE;
    }
    
    return Plugin_Stop;
}

static FindHumanTankPlayer()
{
    for (new i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i)) continue;
        if (GetClientTeam(i) != TEAM_INFECTED) continue;
        if (!IsPlayerTank(i)) continue;
        if (GetClientHealth(i) < 1 || !IsPlayerAlive(i)) continue;
        
        return i;
    }
    
    return 0;
}

static bool:IsPlayerTank (client)
{
    return (GetEntProp(client, Prop_Send, CLASS_ENTPROP) == ZOMBIECLASS_TANK);
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
    if (!withinTimeLimit) return Plugin_Continue;
    if (client != primaryTankPlayer) return Plugin_Continue;
    
    if (buttons & SURRENDER_BUTTON)
    {
        withinTimeLimit = false;
        CallSurrenderMenu();
        return Plugin_Handled;
    }
    
    return Plugin_Continue;
}

static CallSurrenderMenu()
{
    surrenderMenu = CreateMenu(TS_MenuCallBack, MenuAction:MENU_ACTIONS_ALL);
    decl String:temp[MAX_NAME_LENGTH];
    Format(temp,sizeof(temp),"%t","SurrenderPanelName");   
    SetMenuTitle(surrenderMenu, temp);
    //SetMenuTitle(surrenderMenu, " 谁应该玩这个克 ");
    
    DebugPrintToAll("Initializing Tank Swap Menu");
    
    decl String:name[MAX_NAME_LENGTH], String:number[10];
    new electables;
    Format(temp,sizeof(temp),"%t","SurrenderAnyoneTankButme"); 
    //AddMenuItem(surrenderMenu, "0", "我不知道谁会玩，但我不想背锅!");
    AddMenuItem(surrenderMenu, "0", temp);
    for (new i = 1; i <= MaxClients; i++)
    {
        if (i == primaryTankPlayer) continue;
        if (!IsClientInGame(i)) continue;
        if (GetClientTeam(i) != TEAM_INFECTED) continue;
        if (IsFakeClient(i)) continue;
        
        DebugPrintToAll("Found valid Tank Swap Choice: %N", i);
        
        Format(name, sizeof(name), "%N", i);
        Format(number, sizeof(number), "%i", i);
        AddMenuItem(surrenderMenu, number, name);
        
        electables++;
    }
    
    DebugPrintToAll("Valid Tank Choices Amount: %i", electables);
    
    if (electables > 0) //only do all that if there is someone to swap to
    {
        SetMenuExitButton(surrenderMenu, false);
        DisplayMenu(surrenderMenu, primaryTankPlayer, GetConVarInt(cvar_SurrenderTimeLimit));
    }
}

public TS_MenuCallBack(Handle:menu, MenuAction:action, param1, param2)
{
    if (action == MenuAction_End) CloseHandle(menu);

    if (action != MenuAction_Select) return; // only allow a valid choice to pass
    
    decl String:number[4];
    GetMenuItem(menu, param2, number, sizeof(number));
    DebugPrintToAll("Manual MenuCallBack, param1/client: %s: %N, choice: %s", param1, param1, number);

    new choice = StringToInt(number);
    if (!choice)
    {
        choice = GetRandomEligibleTank();
        if (GetClientHealth(choice) > 1 && !IsPlayerGhost(choice))
        {
            L4D2_ReplaceWithBot(choice, true);
        }
        L4D2_ReplaceTank(primaryTankPlayer, choice);
        PrintToChatAll("%t","SystemChangeToAPlayer",choice);
        //PrintToChatAll("\x04[坦克交换]\x01 Tank的白给权被系统决定交给： \x03%N\x01", choice);
        DebugPrintToAll("Tank Control was surrendered randomly to: %N", choice);
    }
    else
    {
        if (GetClientHealth(choice) > 1 && !IsPlayerGhost(choice))
        {
            L4D2_ReplaceWithBot(choice, true);
        }
        L4D2_ReplaceTank(primaryTankPlayer, choice);
        PrintToChatAll("%t","PlayerChangeToPlayer",choice);
        //PrintToChatAll("\x04[Tank Swap]\x01 Tank的白给权被玩家决定交给: \x03%N\x01", choice);
        DebugPrintToAll("Tank Control was surrendered to: %N", choice);
    }
}

public Action:TS_Display_Auto_MenuToTank(Handle:timer)
{
    primaryTankPlayer = FindHumanTankPlayer();
    if (!primaryTankPlayer)
    {
        if (HasTeamHumanPlayers(3))
        {
            DebugPrintToAll("FindHumanTankPlayer didnt find a human tank, retrying auto menu in 2 seconds");
            CreateTimer(CONTROL_RETRY_DELAY, TS_Display_Auto_MenuToTank);
            return Plugin_Stop;
        }
        else
        {
            DebugPrintToAll("No Humans on Infected team, aborting");
            return Plugin_Stop;
        }
    }

    surrenderMenu = CreateMenu(TS_Auto_MenuCallBack, MenuAction:MENU_ACTIONS_ALL); 
    decl String:temp[MAX_NAME_LENGTH];
    Format(temp,sizeof(temp),"%t","PanalName");
    SetMenuTitle(surrenderMenu, temp);
    SetMenuTitle(surrenderMenu, " Tank白给面板 ");
    SetMenuTitle(surrenderMenu, "%t","panelname");
    DebugPrintToAll("Initializing Tank Swap Menu, auto triggered");
    
    decl String:name[MAX_NAME_LENGTH], String:number[10];
    new electables;
    Format(temp,sizeof(temp),"%t","MyselfBeTank");
    AddMenuItem(surrenderMenu, "0", temp);
    AddMenuItem(surrenderMenu, "0", "不给!我要自己装逼!");
    //AddMenuItem(surrenderMenu, "98", "加强AI帮我代打!");
    AddMenuItem(surrenderMenu, "99", "随机让克!");
    Format(temp,sizeof(temp),"%t","AnyoneTankButMe");
    AddMenuItem(surrenderMenu,"99", temp);
    for (new i = 1; i <= MaxClients; i++)
    {
        if (i == primaryTankPlayer) continue;
        if (!IsClientInGame(i)) continue;
        if (GetClientTeam(i) != TEAM_INFECTED) continue;
        if (IsFakeClient(i)) continue;
        
        DebugPrintToAll("Found valid Tank Swap Choice: %N", i);
        
        Format(name, sizeof(name), "%N", i);
        Format(number, sizeof(number), "%i", i);
        AddMenuItem(surrenderMenu, number, name);
        
        electables++;
    }
    
    DebugPrintToAll("Valid Tank Choices Amount: %i", electables);
    
    if (electables > 0) //only do all that if there is someone to swap to
    {
        SetMenuExitButton(surrenderMenu, false);
        DisplayMenu(surrenderMenu, primaryTankPlayer, 2 * GetConVarInt(cvar_SurrenderTimeLimit));
    }
    
    return Plugin_Stop;
}

bool:HasTeamHumanPlayers(team)
{
    for (new i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i)
        && GetClientTeam(i) == team
        && !IsFakeClient(i))
        {
            return true;
        }
    }
    return false;
}

public TS_Auto_MenuCallBack(Handle:menu, MenuAction:action, param1, param2)
{
    if (action == MenuAction_End) CloseHandle(menu);
    
    if (action != MenuAction_Select) return; // only allow a valid choice to pass
    
    decl String:number[4];
    GetMenuItem(menu, param2, number, sizeof(number));
    DebugPrintToAll("Auto MenuCallBack, param1/client: %s: %N, choice: %s", param1, param1, number);

    new choice = StringToInt(number);
    if (!choice) return; // "I want to stay Tank"
	else if (choice == 98) // "AI代打"
	{
	    L4D2_ReplaceWithBot(primaryTankPlayer, true);
		ForcePlayerSuicide(primaryTankPlayer);
		Call_StartForward(IsTankPass);
		Call_PushCell(0);
		Call_Finish();
		PrintToChatAll("%t","ChangeToAI");
		//PrintToChatAll("\x04[坦克交换]\x01 Tank的白给权被交给了\x03憨憨加强AI坦克");
	}
    else if (choice == 99)  // "Anyone but me"
    {
        choice = GetRandomEligibleTank();
        if (GetClientHealth(choice) > 1 && !IsPlayerGhost(choice))
        {
            L4D2_ReplaceWithBot(choice, true);
        }
        L4D2_ReplaceTank(primaryTankPlayer, choice);
        Call_StartForward(IsTankPass);
        Call_PushCell(choice);
		Call_Finish();
		PrintToChatAll("%t","ChangeToRandom",choice);
        //PrintToChatAll("\x04[坦克交换]\x01 可能是怕背锅所以挑了 \x03%N\x01 当背锅的", choice);
        DebugPrintToAll("Tank Control was surrendered randomly to: %N", choice);
    }
    else    // choice is a specific player id
    {
        if (GetClientHealth(choice) > 1 && !IsPlayerGhost(choice))
        {
            L4D2_ReplaceWithBot(choice, true);
        }
        L4D2_ReplaceTank(primaryTankPlayer, choice);
    	Call_StartForward(IsTankPass);
    	Call_PushCell(choice);
		Call_Finish();   
		PrintToChatAll("%t","ChangeToPlayer",choice);
        //PrintToChatAll("\x04[坦克交换]\x01  装逼的机会被让给了 \x03%N\x01", choice);
        DebugPrintToAll("Tank Control was surrendered to: %N", choice);
    }
}

static bool:IsPlayerGhost(client)
{
    return (GetEntProp(client, Prop_Send, GHOST_ENTPROP, 1) == 1);
}

static GetRandomEligibleTank()
{
    new electables, pool[MaxClients/2];
    
    for (new i = 1; i <= MaxClients; i++)
    {
        if (i == primaryTankPlayer) continue;
        if (!IsClientInGame(i)) continue;
        if (GetClientTeam(i) != TEAM_INFECTED) continue;
        if (IsFakeClient(i)) continue;
        
        DebugPrintToAll("Found valid random Tank: %N", i);
        
        electables++;
        pool[electables] = i;
    }
    
    return pool[ GetRandomInt(1, electables) ];
}

PrepSDKCalls()
{
    new Handle:ConfigFile = LoadGameConfigFile(GAMEDATA_FILENAME);
    new Handle:MySDKCall = INVALID_HANDLE;
    
    StartPrepSDKCall(SDKCall_Player);
    PrepSDKCall_SetFromConf(ConfigFile, SDKConf_Signature, "TakeOverZombieBot");
    PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
    MySDKCall = EndPrepSDKCall();
    
    if (MySDKCall == INVALID_HANDLE)
    {
        SetFailState("Cant initialize TakeOverZombieBot SDKCall");
    }
    
    sdkTakeOverZombieBot = CloneHandle(MySDKCall, sdkTakeOverZombieBot);
    
    StartPrepSDKCall(SDKCall_Player);
    PrepSDKCall_SetFromConf(ConfigFile, SDKConf_Signature, "ReplaceWithBot");
    PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
    MySDKCall = EndPrepSDKCall();
    
    if (MySDKCall == INVALID_HANDLE)
    {
        SetFailState("Cant initialize ReplaceWithBot SDKCall");
    }
    
    sdkReplaceWithBot = CloneHandle(MySDKCall, sdkReplaceWithBot);
    
    StartPrepSDKCall(SDKCall_Player);
    PrepSDKCall_SetFromConf(ConfigFile, SDKConf_Signature, "CullZombie");
    MySDKCall = EndPrepSDKCall();
    
    if (MySDKCall == INVALID_HANDLE)
    {
        SetFailState("Cant initialize CullZombie SDKCall");
    }
    
    sdkCullZombie = CloneHandle(MySDKCall, sdkCullZombie);
    
    g_pZombieManager = GameConfGetAddress(ConfigFile, "CZombieManager");
    if(g_pZombieManager == Address_Null)
    {
        SetFailState("Could not load the ZombieManager pointer");
    }
    
    StartPrepSDKCall(SDKCall_Raw);
    PrepSDKCall_SetFromConf(ConfigFile, SDKConf_Signature, "ReplaceTank");
    PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
    PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
    MySDKCall = EndPrepSDKCall();
    
    if (MySDKCall == INVALID_HANDLE)
    {
        SetFailState("Cant initialize ReplaceTank SDKCall");
    }
    
    sdkReplaceTank = CloneHandle(MySDKCall, sdkReplaceTank);
    
    CloseHandle(ConfigFile);
    CloseHandle(MySDKCall);
}

// CTerrorPlayer::TakeOverZombieBot(CTerrorPlayer*)
// Client takes control of an Infected Bot - Tank included. Causes odd shit to happen if an alive client's current SI class doesnt match the taken over one, exception tank
// i suggest CullZombie or State Transitioning until classes match before calling this
stock L4D2_TakeOverZombieBot(client, target)
{
    DebugPrintToAll("TakeOverZombieBot being called, client %N target %N", client, target);
    SDKCall(sdkTakeOverZombieBot, client, target);
}

// CTerrorPlayer::ReplaceWithBot(bool)
// causes a perfect 'clone' of you as bot to appear at your location. you do not(!) disappear or die by this function alone
// boolean has no obvious effect
// intended for use directly before CullZombie or ReplaceTank
stock L4D2_ReplaceWithBot(client, boolean)
{
    DebugPrintToAll("ReplaceWithBot being called, client %N boolean %b", client, boolean);
    SDKCall(sdkReplaceWithBot, client, boolean);
}

// CTerrorPlayer::CullZombie(void)
// causes instant respawn as spawnready ghost, new class - but only when you were alive in the first place (ghost included)
stock L4D2_CullZombie(target)
{
    DebugPrintToAll("CullZombie being called, target %N", target);
    SDKCall(sdkCullZombie, target);
}


// ZombieManager::ReplaceTank(CTerrorPlayer *, CTerrorPlayer *)
// causes Tank control to instantly shift from target 1 to target 2. Frustration is reset, target 1 may become tank again if target 2 gets frustrated.
// if target 2 was alive and/or spawned at calling this, it disappears.
// do not use with bots. Use L4D2_TakeOverZombieBot instead.
stock L4D2_ReplaceTank(client, target)
{
    DebugPrintToAll("ReplaceTank being called, client %N target %N", client, target);
    DebugPrintToAll("ZombieManager pointer: 0x%x", g_pZombieManager);

    if (GetClientHealth(client) < 1)
    {
        DebugPrintToAll("ReplaceTank invalid, origin tank %N health is below 1", client);
    }
    
    SDKCall(sdkReplaceTank, g_pZombieManager, client, target);
}

stock DebugPrintToAll(const String:format[], any:...)
{
    #if (TEST_DEBUG || TEST_DEBUG_LOG)
    decl String:buffer[256];
    
    VFormat(buffer, sizeof(buffer), format, 2);
    
    #if TEST_DEBUG
    PrintToChatAll("[TANKVOTE] %s", buffer);
    PrintToConsole(0, "[TANKVOTE] %s", buffer);
    #endif
    
    LogMessage("%s", buffer);
    #else
    //suppress "format" never used warning
    if(format[0])
        return;
    else
        return;
    #endif
}

stock CheatCommand(client, const String:command[], const String:arguments[]="")
{
    if (!client || !IsClientInGame(client))
    {
        for (new target = 1; target <= MaxClients; target++)
        {
            if (IsClientInGame(target)) client = target;
        }
    }
    if (!client || !IsClientInGame(client)) return;
    
    new admindata = GetUserFlagBits(client);
    SetUserFlagBits(client, ADMFLAG_ROOT);
    new flags = GetCommandFlags(command);
    SetCommandFlags(command, flags & ~FCVAR_CHEAT);
    FakeClientCommand(client, "%s %s", command, arguments);
    SetCommandFlags(command, flags);
    SetUserFlagBits(client, admindata);
}