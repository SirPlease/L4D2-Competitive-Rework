#define PLUGIN_VERSION "2.5"

#pragma semicolon 1
#pragma newdecls required
/*
|--------------------------------------------------------------------------
| INCLUDES
|--------------------------------------------------------------------------
*/
#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#undef REQUIRE_PLUGIN
#include <adminmenu>
#include <l4d_lib>
#include <exp_interface>
#include <colors>
/*
|--------------------------------------------------------------------------
| MACROS
|--------------------------------------------------------------------------
*/
#define IGNITE_TIME 3600.0
#define DISPLAY_TIME 10
#define FORWARD_ARGS "TP_OnTankPass", ET_Ignore, Param_Cell, Param_Cell
#define SOURCEMOD_V_COMPAT (SOURCEMOD_V_MAJOR >= 1 && SOURCEMOD_V_MINOR >= 10 || SOURCEMOD_V_MAJOR > 2)
/*
|--------------------------------------------------------------------------
| VARIABLES
|--------------------------------------------------------------------------
*/
enum
{
    Validate_Default,
    Validate_NotiyfyTarget,
    Validate_SkipTarget
}

enum
{
    Menu_Pass,
    Menu_ForcePass,
    Menu_ForceAdmPass,
    Menu_Take
}

#if SOURCEMOD_V_COMPAT
GlobalForward g_fwdOnTankPass;
#else
Handle g_fwdOnTankPass;
#endif
int g_iCvarTankHealth, g_iCvarPassedCount, g_iTakeOverPassedCount, g_iTankId[MPS], g_iPassedCount[MPS];
char g_sCvarCmd[32];
TopMenu g_hTopMenu;
bool g_bCvarDamage, g_bCvarFire, g_bCvarReplace, g_bCvarExtinguish, g_bCvarNotify, g_bCvarQuickPass, g_bCvarMenu, g_bCvarConfirm, g_bIsFinale, g_bIsIgnited[MPS], g_bIsBlocked[MPS];
ConVar g_hCvarTankHealth, g_hCvarTankBonusHealth;

public Plugin myinfo =
{
    name = "[L4D & L4D2] Tank Pass",
    author = "Scratchy [Laika] & raziEiL [disawar1]",
    description = "Allows the Tank to pass control to another player.",
    version = PLUGIN_VERSION,
    url = "https://steamcommunity.com/id/raziEiL/"
}

public void OnPluginStart()
{
    // forward void TP_OnTankPass(int old_tank, int new_tank);
#if SOURCEMOD_V_COMPAT
    g_fwdOnTankPass = new GlobalForward(FORWARD_ARGS);
#else
    g_fwdOnTankPass = CreateGlobalForward(FORWARD_ARGS);
#endif
    LoadTranslations("l4d_tank_pass.phrases");
    LoadTranslations("common.phrases");

    g_hCvarTankHealth = FindConVar("z_tank_health");
    g_hCvarTankBonusHealth = FindConVar("versus_tank_bonus_health");
    g_iCvarTankHealth = CalcTankHealth();

    if (g_hCvarTankBonusHealth)
        g_hCvarTankBonusHealth.AddChangeHook(OnCvarChange_TankHealth);
    g_hCvarTankHealth.AddChangeHook(OnCvarChange_TankHealth);

    CreateConVar("l4d_tank_pass_version", PLUGIN_VERSION, "Tank Pass plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);

    ConVar cVar = CreateConVar("l4d_tank_pass_command", "sm_tankhud", "Execute command according convar value on old_tank and new_tank to close 3d party HUD.", FCVAR_NOTIFY);
    cVar.GetString(SZF(g_sCvarCmd));
    cVar.AddChangeHook(OnCvarChange_Exec);

    cVar = CreateConVar("l4d_tank_pass_replace", "0", "0=Kill the alive player before the Tank pass, 1=Replace the alive player with an infected bot before the Tank pass.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_bCvarReplace = cVar.BoolValue;
    cVar.AddChangeHook(OnCvarChange_Replace);

    cVar = CreateConVar("l4d_tank_pass_damage", "0", "0=Allow to pass the Tank when taking any damage, 1=Prevent to pass the Tank when taking any damage.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_bCvarDamage = cVar.BoolValue;
    cVar.AddChangeHook(OnCvarChange_Damage);

    cVar = CreateConVar("l4d_tank_pass_fire", "0", "0=Allow to pass the Tank when on fire, 1=Prevent to pass the Tank when on fire.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_bCvarFire = cVar.BoolValue;
    cVar.AddChangeHook(OnCvarChange_Fire);

    cVar = CreateConVar("l4d_tank_pass_extinguish", "0", "If \"l4d_tank_pass_fire\" convar set to 0: 0=Ignite the new Tank when passed, 1=Extinguish the new Tank when passed.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_bCvarExtinguish = cVar.BoolValue;
    cVar.AddChangeHook(OnCvarChange_Extinguish);

    cVar = CreateConVar("l4d_tank_pass_takeover", "1", "Sets the Tank passed count according convar value when taking control of the Tank AI. If >1 the tank will be replaced with a bot when the his frustration reaches 0.", FCVAR_NOTIFY, true, 1.0, true, 2.0);
    g_iTakeOverPassedCount = cVar.IntValue;
    cVar.AddChangeHook(OnCvarChange_TakeOver);

    cVar = CreateConVar("l4d_tank_pass_notify", "1", "0=Off, 1=Display pass command info to the Tank through chat messages.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_bCvarNotify = cVar.BoolValue;
    cVar.AddChangeHook(OnCvarChange_Notify);

    cVar = CreateConVar("l4d_tank_pass_logic", "1", "0=\"X gets Tank\" window, 1=Quick pass except finales", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_bCvarQuickPass = cVar.BoolValue;
    cVar.AddChangeHook(OnCvarChange_QuickPass);

    cVar = CreateConVar("l4d_tank_pass_menu", "1", "0=Off, 1=Display the menu when the Tank is spawned", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_bCvarMenu = cVar.BoolValue;
    cVar.AddChangeHook(OnCvarChange_Menu);

    cVar = CreateConVar("l4d_tank_pass_count", "2", "0=Off, >0=The number of times the Tank can be passed by plugin (Frustration counts as pass).", FCVAR_NOTIFY, true, 0.0);
    g_iCvarPassedCount = cVar.IntValue;
    cVar.AddChangeHook(OnCvarChange_PassCount);

    cVar = CreateConVar("l4d_tank_pass_confirm", "1", "0=Off, 1=Ask the player if he wants to get the Tank.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_bCvarConfirm = cVar.BoolValue;
    cVar.AddChangeHook(OnCvarChange_Confirm);

    HookEvent("tank_spawn", Event_TankSpawn);
    HookEvent("finale_start", Event_FinalStart, EventHookMode_PostNoCopy);
    HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
    HookEvent("entity_killed", Event_EntityKilled);
    HookEvent("player_bot_replace", Event_PlayerBotReplace);
    HookEvent("bot_player_replace", Event_BotPlayerReplace);

    RegConsoleCmd("sm_pass", Command_TankPass, "Pass the Tank control to another player.");
    RegConsoleCmd("sm_passtank", Command_TankPass, "Pass the Tank control to another player.");
    RegConsoleCmd("sm_tankpass", Command_TankPass, "Pass the Tank control to another player.");
    RegAdminCmd("sm_forcepass", Command_ForcePass, ADMFLAG_KICK, "sm_forcepass <#userid|name> - Force to pass the Tank to target player.");
    RegAdminCmd("sm_taketank", Command_TakeTank, ADMFLAG_KICK, "sm_taketank <#userid|name> - Take control of the Tank AI.");

    TopMenu topmenu;
    if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != null))
        OnAdminMenuReady(topmenu);

    //AutoExecConfig(true, "l4d_tank_pass");
}
/*
|--------------------------------------------------------------------------
| ADM MENU
|--------------------------------------------------------------------------
*/
public void OnAdminMenuReady(Handle aTopMenu)
{
    TopMenu topmenu = TopMenu.FromHandle(aTopMenu);

    if (topmenu == g_hTopMenu)
        return;

    g_hTopMenu = topmenu;

    TopMenuObject player_commands = g_hTopMenu.FindCategory(ADMINMENU_PLAYERCOMMANDS);

    if (player_commands != INVALID_TOPMENUOBJECT){
        g_hTopMenu.AddItem("sm_forcepass", AdminMenu_ForcePass, player_commands, "sm_forcepass", ADMFLAG_KICK);
        g_hTopMenu.AddItem("sm_taketank", AdminMenu_TakeTank, player_commands, "sm_taketank", ADMFLAG_KICK);
    }
}

public void AdminMenu_ForcePass(TopMenu topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
    switch (action)
    {
        case TopMenuAction_DisplayOption:
        {
            Format(buffer, maxlength, "%T", "phrase10", param);
        }
        case TopMenuAction_SelectOption:
        {
            if (GetTank())
                TankPassMenu(param, Menu_ForceAdmPass);
            else {
                CPrintToChat(param, "[{olive}!{default}] %t", "phrase7");
                if (g_hTopMenu != null)
                    g_hTopMenu.Display(param, TopMenuPosition_LastCategory);
            }
        }
    }
}

public int MenuForceAdmHandler(Menu menu, MenuAction action, int admin, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            char sId[12];
            menu.GetItem(param2, SZF(sId));
            int target = CID(StringToInt(sId));
            int tank = GetTank();

            if (ValidateOffer(Validate_Default, tank, target, admin))
                TankPass(tank, target, admin);

            if (g_hTopMenu != null)
                g_hTopMenu.Display(admin, TopMenuPosition_LastCategory);
        }
        case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack && g_hTopMenu != null)
                g_hTopMenu.Display(admin, TopMenuPosition_LastCategory);
        }
        case MenuAction_End:
        {
            delete menu;
        }
    }
}

public void AdminMenu_TakeTank(TopMenu topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
    switch (action)
    {
        case TopMenuAction_DisplayOption:
        {
            Format(buffer, maxlength, "%T", "phrase12", param);
        }
        case TopMenuAction_SelectOption:
        {
            if (GetTankBot())
                TankPassMenu(param, Menu_Take);
            else {
                CPrintToChat(param, "[{olive}!{default}] %t", "phrase7");
                if (g_hTopMenu != null)
                    g_hTopMenu.Display(param, TopMenuPosition_LastCategory);
            }
        }
    }
}

public int MenuTakeAdmHandler(Menu menu, MenuAction action, int admin, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            char sId[12];
            menu.GetItem(param2, SZF(sId));
            TakeOverTank(CID(StringToInt(sId)), admin);

            if (g_hTopMenu != null)
                g_hTopMenu.Display(admin, TopMenuPosition_LastCategory);
        }
        case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_ExitBack && g_hTopMenu != null)
                g_hTopMenu.Display(admin, TopMenuPosition_LastCategory);
        }
        case MenuAction_End:
        {
            delete menu;
        }
    }
}
/*
|--------------------------------------------------------------------------
| MENU
|--------------------------------------------------------------------------
*/
void PreTankPassMenu(int client)
{
    if (client && ValidateOffer(Validate_SkipTarget, client))
        TankPassMenu(client, g_bCvarConfirm ? Menu_Pass : Menu_ForcePass);
}

void TankPassMenu(int client, int menuType = Menu_Pass)
{
    bool hasTarget;
    Menu menu;

    switch (menuType)
    {
        case Menu_Pass:
            menu = new Menu(MenuPassHandler);
        case Menu_ForcePass:
            menu = new Menu(MenuForceHandler);
        case Menu_ForceAdmPass:
            menu = new Menu(MenuForceAdmHandler);
        case Menu_Take:
            menu = new Menu(MenuTakeAdmHandler);
    }

    menu.SetTitle("%T", "phrase4", client);
    char sName[MAX_NAME_LENGTH], sId[12];
    int maxexp, maxexpplayer;
    for (int i = 1; i <= MaxClients; i++){
        if (!IsValidTarget(i)) continue;
        int iexp = L4D2_GetClientExp(i);
        if ( iexp > maxexp){
            maxexp = iexp;
            maxexpplayer = i;
        }
    }
    char buffer[64], buffer2[3];
    Format(buffer, sizeof(buffer), "最高经验分: %N(%i)", maxexpplayer, maxexp);
    Format(buffer2, sizeof(buffer2), "%i", maxexpplayer);
    menu.AddItem(buffer2, buffer);
    for (int i = 1; i <= MaxClients; i++){
        if (!IsValidTarget(i)) continue;

        hasTarget = true;
        GetClientName(i, SZF(sName));
        IntToString(UID(i), SZF(sId));
        menu.AddItem(sId, sName);
    }
    if (!hasTarget){

        CPrintToChat(client, "[{olive}!{default}]  %t", "phrase7");
        delete menu;
        return;
    }
    if (menuType == Menu_Pass || menuType == Menu_ForcePass){
        ExecCmd(client);
        menu.ExitButton = true;
        menu.Display(client, DISPLAY_TIME);
    }
    else {
        menu.ExitBackButton = true;
        menu.Display(client, MENU_TIME_FOREVER);
    }
}

public int MenuForceHandler(Menu menu, MenuAction action, int tank, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            char sId[12];
            menu.GetItem(param2, SZF(sId));
            int target = CID(StringToInt(sId));

            if (ValidateOffer(Validate_Default, tank, target))
                TankPass(tank, target);
        }
        case MenuAction_End:
        {
            delete menu;
        }
    }
}
public int MenuPassHandler(Menu menu, MenuAction action, int tank, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            char sId[12];
            menu.GetItem(param2, SZF(sId));
            int target = CID(StringToInt(sId));

            if (ValidateOffer(Validate_Default, tank, target))
                OfferMenu(tank, target);
        }
        case MenuAction_End:
        {
            delete menu;
        }
    }
}

void OfferMenu(int tank, int target)
{
    g_iTankId[target] = UID(tank);
    ExecCmd(target);
    char sTemp[64];
    Menu menu = new Menu(OfferMenuHandler);
    FormatEx(SZF(sTemp), "%T", "phrase5", target);
    menu.SetTitle(sTemp);
    FormatEx(SZF(sTemp), "%T", "Yes", target);
    menu.AddItem("", sTemp);
    FormatEx(SZF(sTemp), "%T", "No", target);
    menu.AddItem("", sTemp);
    menu.ExitButton = true;
    menu.Display(target, 10);
}

public int OfferMenuHandler(Menu menu, MenuAction action, int target, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            int tank = CID(g_iTankId[target]);

            if (param2 == 0){
                if (ValidateOffer(Validate_NotiyfyTarget, tank, target))
                    TankPass(tank, target);
            }
            else if (IsValidTank(tank))
                CPrintToChat(tank, "[{olive}!{default}] %t", "phrase6", target);
        }
        case MenuAction_Cancel:
        {
            int tank = CID(g_iTankId[target]);
            if (IsValidTank(tank))
                CPrintToChat(tank, "[{olive}!{default}] %t", "phrase6", target);
        }
        case MenuAction_End:
        {
            delete menu;
        }
    }
}
/*
|--------------------------------------------------------------------------
| COMMANDS
|--------------------------------------------------------------------------
*/
public Action Command_TankPass(int client, int args)
{
    if (!g_bIsBlocked[client])
        PreTankPassMenu(client);
    return Plugin_Handled;
}

public Action Command_ForcePass(int client, int args)
{
    if (client && args){

        char sArg[32], sName[MAX_TARGET_LENGTH];
        int iTargetList[MPS], iCount;
        bool bIsML;
        GetCmdArg(1, SZF(sArg));

        if ((iCount = ProcessTargetString(
            sArg,
            client,
            iTargetList,
            MPS,
            COMMAND_FILTER_NO_MULTI|COMMAND_FILTER_NO_BOTS,
            SZF(sName),
            bIsML)) <= 0){
            ReplyToTargetError(client, iCount);
            return Plugin_Handled;
        }

        int tank = GetTank();

        if (ValidateOffer(Validate_Default, tank, iTargetList[0], client))
            TankPass(tank, iTargetList[0], client);
    }
    else
        ReplyToCommand(client, "sm_forcepass <#userid|name>");

    return Plugin_Handled;
}

public Action Command_TakeTank(int client, int args)
{
    if (client && args){

        char sArg[32], sName[MAX_TARGET_LENGTH];
        int iTargetList[MPS], iCount;
        bool bIsML;
        GetCmdArg(1, SZF(sArg));

        if ((iCount = ProcessTargetString(
            sArg,
            client,
            iTargetList,
            MPS,
            COMMAND_FILTER_NO_MULTI|COMMAND_FILTER_NO_BOTS,
            SZF(sName),
            bIsML)) <= 0){
            ReplyToTargetError(client, iCount);
            return Plugin_Handled;
        }

        TakeOverTank(client, iTargetList[0]);
    }
    else
        ReplyToCommand(client, "sm_taketank <#userid|name>");

    return Plugin_Handled;
}
/*
|--------------------------------------------------------------------------
| EVENTS
|--------------------------------------------------------------------------
*/
public void OnClientPutInServer(int client)
{
    if (client)
        ResetPassData(client);
}

public void Event_RoundStart(Event h_Event, char[] s_Name, bool b_DontBroadcast)
{
    for (int i = 1; i <= MaxClients; i++)
        ResetPassData(i);

    g_bIsFinale = false;
}

public void Event_FinalStart(Event h_Event, char[] s_Name, bool b_DontBroadcast)
{
    g_bIsFinale = true;
}

public void Event_TankSpawn(Event h_Event, char[] s_Name, bool b_DontBroadcast)
{
    int client = CID(h_Event.GetInt("userid"));

    if (IsClientAndInGame(client) && !IsFakeClient(client)){
        ResetPassData(client);
        if (!g_bCvarNotify) return;

        g_bIsBlocked[client] = true;
        DataPack pack;
        CreateDataTimer(0.2, Timer_Notify, pack); // waiting for bot_player_replace fired
        pack.WriteCell(UID(client));
        pack.WriteCell(client);
    }
}

public Action Timer_Notify(Handle timer, DataPack pack)
{
    pack.Reset();
    int userId = pack.ReadCell();
    int client = pack.ReadCell();

    g_bIsBlocked[client] = false;
    client = CID(userId);

    if (IsAllowToPass(client) && IsValidTank(client)){

        if (g_bCvarMenu)
            PreTankPassMenu(client);

        CPrintToChat(client, "[{olive}!{default}] %t", "phrase1");
    }
}

public void Event_EntityKilled(Event h_Event, char[] s_Name, bool b_DontBroadcast)
{
    int entity = h_Event.GetInt("entindex_killed");
    if (IsClient(entity) && IsPlayerTank(entity))
        RequestFrame(OnEntKilled, entity);
}

public void OnEntKilled(int client)
{
    if (!IsAliveTank(client))
        ResetPassData(client);
}

public void Event_PlayerBotReplace(Event h_Event, char[] s_Name, bool b_DontBroadcast)
{
    int client = CID(h_Event.GetInt("player"));
    if (!g_iPassedCount[client]) return;
    int bot = CID(h_Event.GetInt("bot"));

    if (IsReplaceableTank(bot, client))
        TransferPass(client, bot);
}

// fired after tank_spawn
public void Event_BotPlayerReplace(Event h_Event, char[] s_Name, bool b_DontBroadcast)
{
    int bot = CID(h_Event.GetInt("bot"));
    if (!g_iPassedCount[bot]) return;
    int client = CID(h_Event.GetInt("player"));

    if (IsReplaceableTank(bot, client))
        TransferPass(bot, client, false);
}

public void L4D_OnReplaceTank(int tank, int newtank)
{
    OnReplaceTank(tank, newtank);
}

// support nyx extension
public Action L4D2_OnReplaceTank(int tank, int newtank)
{
    OnReplaceTank(tank, newtank);
    return Plugin_Continue;
}

void OnReplaceTank(int tank, int newtank)
{
    if (tank == newtank) return;

    if (g_bIsIgnited[tank])
        RequestFrame(OnFrameIgnite, UID(newtank));

    TransferPass(tank, newtank);
}

public void OnFrameIgnite(int client)
{
    client = CID(client);
    if (IsValidTank(client))
         IgniteEntity(client, IGNITE_TIME);
}
/*
|--------------------------------------------------------------------------
| FUNCTIONS
|--------------------------------------------------------------------------
*/
void TankPass(int tank, int target, int admin = 0)
{
    if (admin){
        PrintToTeam(3, 0, "%t", "phrase9", target);
        LogAction(admin, target, "\"%L\" has passed the Tank from \"%L\" to \"%L\"", admin, tank, target);
    }
    else if (g_iCvarPassedCount == 1)
        PrintToTeam(3, 0, "%t", "phrase3", tank, target);
    else
        PrintToTeam(3, 0, "%t", "phrase14", tank, target, g_iPassedCount[tank] + 1, g_iCvarPassedCount);

    bool isOnFire = IsOnFire(tank);

    if (g_bIsFinale || !g_bCvarQuickPass){
        if (IsMustIgnite(isOnFire))
            g_bIsIgnited[tank] = true;

        if (!g_bCvarReplace && IsReplaceableSI(target))
            ForcePlayerSuicide(target);

        for (int i = 1; i <= MaxClients; i++)
            if (i != target && IsInfected(i) && !IsFakeClient(i))
                L4D2Direct_SetTankTickets(i, 0);

        L4D2Direct_SetTankTickets(target, 10000);
        SetPassCount(tank, true);
        L4D2Direct_TryOfferingTankBot(tank, false);
    }
    else {
        if (IsReplaceableSI(target)){

            if (g_bCvarReplace)
                L4D_ReplaceWithBot(target);

            ForcePlayerSuicide(target);
        }
        // left4dhooks bugfix
        float vPos[3], vAng[3];
        GetClientAbsOrigin(tank, vPos);
        GetClientAbsAngles(tank, vAng);
        TeleportEntity(target, vPos, vAng, NULL_VECTOR);

        SetPassCount(tank);
        L4D_ReplaceTank(tank, target);

        if (IsMustIgnite(isOnFire))
            IgniteEntity(target, IGNITE_TIME);
    }

    Call_StartForward(g_fwdOnTankPass);
    Call_PushCell(tank);
    Call_PushCell(target);
    Call_Finish();
}

void TakeOverTank(int admin, int target)
{
    int tank = GetTankBot();

    if (tank && IsValidTarget(target)){
        L4D_TakeOverZombieBot(target, tank);
        L4D2Direct_SetTankPassedCount(g_iTakeOverPassedCount);
    }
    else
        CPrintToChat(admin, "[{olive}!{default}] %t", "Player no longer available");
}

void SetPassCount(int tank, bool offer = false)
{
    int count = (g_iPassedCount[tank] + 1) >= g_iCvarPassedCount ? 2 : 1;
    if (offer) count--;
    L4D2Direct_SetTankPassedCount(count);
}

void TransferPass(int tank, int newtank, bool count = true)
{
    if (count)
        g_iPassedCount[tank]++;

    if (g_iPassedCount[tank] > g_iCvarPassedCount)
        g_iPassedCount[tank] = g_iCvarPassedCount;

    g_iPassedCount[newtank] = g_iPassedCount[tank];
    ResetPassData(tank);
}

void ResetPassData(int client)
{
    g_iPassedCount[client] = 0;
    g_bIsIgnited[client] = false;
}

void ExecCmd(int client)
{
    if (g_sCvarCmd[0] && GetClientMenu(client) == MenuSource_Normal)
        FakeClientCommand(client, g_sCvarCmd);
}

int GetTank()
{
    for (int i = 1; i <= MaxClients; i++){
        if (IsValidTank(i))
            return i;
    }
    return 0;
}

int GetTankBot()
{
    for (int i = 1; i <= MaxClients; i++){
        if (IsValidTankBot(i))
            return i;
    }
    return 0;
}

bool ValidateOffer(int validate = Validate_Default, int tank, int target = 0, int admin = 0)
{
    bool hasTarget = validate == Validate_SkipTarget ? true : IsValidTarget(target);
    bool hasTank = IsValidTank(tank);
    int client = admin ? admin : tank;

    if (!hasTank){
        if (IsClientAndInGame(client))
            CPrintToChat(client, "[{olive}!{default}] %t", "phrase7");
        if (validate == Validate_NotiyfyTarget && hasTarget)
            CPrintToChat(target, "[{olive}!{default}] %t", "phrase7");
        return false;
    }
    if (!IsAllowToPass(tank)){
        if (hasTank){
            if (g_iCvarPassedCount == 1)
                CPrintToChat(client, "[{olive}!{default}] %t", "phrase2");
            else
                CPrintToChat(client, "[{olive}!{default}] %t", "phrase13", g_iPassedCount[tank], g_iCvarPassedCount);
        }
        if (validate == Validate_NotiyfyTarget && hasTarget){
            if (g_iCvarPassedCount == 1)
                CPrintToChat(client, "[{olive}!{default}] %t", "phrase2");
            else
                CPrintToChat(client, "[{olive}!{default}] %t", "phrase13", g_iPassedCount[tank], g_iCvarPassedCount);
        }
        return false;
    }
    if (!hasTarget){
        CPrintToChat(client, "[{olive}!{default}] %t", "Player no longer available");
        return false;
    }
    if (g_bCvarFire && IsOnFire(tank)){
        CPrintToChat(client, "[{olive}!{default}] %t", "phrase8");
        if (validate == Validate_NotiyfyTarget)
            CPrintToChat(target, "[{olive}!{default}] %t", "phrase8");
        return false;
    }
    if (g_bCvarDamage && GetClientHealth(tank) != g_iCvarTankHealth){
        CPrintToChat(client, "[{olive}!{default}] %t", "phrase11");
        if (validate == Validate_NotiyfyTarget)
            CPrintToChat(target, "[{olive}!{default}] %t", "phrase11");
        return false;
    }
    return true;
}
/*
|--------------------------------------------------------------------------
| CONDITION
|--------------------------------------------------------------------------
*/
bool IsMustIgnite(bool ignited)
{
    return ignited && !g_bCvarFire && !g_bCvarExtinguish;
}

bool IsAllowToPass(int tank)
{
    return g_iPassedCount[tank] < g_iCvarPassedCount;
}

bool IsReplaceableTank(int client, int bot)
{
    return IsClient(client) && IsClient(bot) && IsTank(client) && IsTank(bot);
}

bool IsReplaceableSI(int client)
{
    return IsPlayerAlive(client) && !IsPlayerGhost(client);
}

bool IsValidTarget(int target)
{
    return IsValid(target) && (!IsPlayerTank(target) || !IsPlayerAlive(target));
}

bool IsValidTank(int tank)
{
    return IsValid(tank) && IsAliveTank(tank);
}

bool IsValidTankBot(int tank)
{
    return IsInfected(tank) && IsFakeClient(tank) && IsAliveTank(tank);
}

bool IsAliveTank(int tank)
{
    return IsTank(tank) && IsPlayerAlive(tank);
}

bool IsTank(int tank)
{
    return IsPlayerTank(tank) && !IsIncaped(tank);
}

bool IsValid(int client)
{
    return IsInfectedAndInGame(client) && !IsFakeClient(client);
}
/*
|--------------------------------------------------------------------------
| CVARS
|--------------------------------------------------------------------------
*/
public void OnCvarChange_Exec(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if (!StrEqual(oldValue, newValue))
        convar.GetString(SZF(g_sCvarCmd));
}

public void OnCvarChange_Replace(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if (!StrEqual(oldValue, newValue))
        g_bCvarReplace = convar.BoolValue;
}

public void OnCvarChange_Damage(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if (!StrEqual(oldValue, newValue))
        g_bCvarDamage = convar.BoolValue;
}

public void OnCvarChange_Fire(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if (!StrEqual(oldValue, newValue))
        g_bCvarFire = convar.BoolValue;
}

public void OnCvarChange_Extinguish(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if (!StrEqual(oldValue, newValue))
        g_bCvarExtinguish = convar.BoolValue;
}

public void OnCvarChange_TakeOver(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if (!StrEqual(oldValue, newValue))
        g_iTakeOverPassedCount = convar.IntValue;
}

public void OnCvarChange_TankHealth(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if (!StrEqual(oldValue, newValue))
        g_iCvarTankHealth = CalcTankHealth();
}

int CalcTankHealth()
{
    return RoundToNearest(g_hCvarTankHealth.FloatValue * (g_hCvarTankBonusHealth ? g_hCvarTankBonusHealth.FloatValue : 1.5));
}

public void OnCvarChange_Notify(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if (!StrEqual(oldValue, newValue))
        g_bCvarNotify = convar.BoolValue;
}

public void OnCvarChange_QuickPass(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if (!StrEqual(oldValue, newValue))
        g_bCvarQuickPass = convar.BoolValue;
}

public void OnCvarChange_Menu(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if (!StrEqual(oldValue, newValue))
        g_bCvarMenu = convar.BoolValue;
}

public void OnCvarChange_PassCount(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if (!StrEqual(oldValue, newValue))
        g_iCvarPassedCount = convar.IntValue;
}

public void OnCvarChange_Confirm(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if (!StrEqual(oldValue, newValue))
        g_bCvarConfirm = convar.BoolValue;
}