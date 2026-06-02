#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <colors>

#pragma newdecls required

#define MAX_STR_LEN             100
#define DEFAULT_STEP_SIZE       1.0
#define TEAM_INFECTED           3
#define HUD_DRAW_INTERVAL       0.5

static int selectedLadder[MAXPLAYERS + 1];
static int bEditMode[MAXPLAYERS + 1];
static float stepSize[MAXPLAYERS + 1];
StringMap hLadders;
bool in_attack[MAXPLAYERS + 1];
bool in_attack2[MAXPLAYERS + 1];
bool in_score[MAXPLAYERS + 1];
bool in_speed[MAXPLAYERS + 1];
bool bHudActive[MAXPLAYERS + 1];
bool bHudHintShown[MAXPLAYERS + 1];

public Plugin myinfo = {
    name = "L4D2 Ladder Editor",
    author = "devilesk",
    version = "0.5.0",
    description = "Clone and move special infected ladders.",
    url = "https://github.com/devilesk/rl4d2l-plugins"
};

public void OnPluginStart() {
    RegConsoleCmd("sm_edit", Command_Edit);
    RegConsoleCmd("sm_step", Command_Step);
    RegConsoleCmd("sm_select", Command_Select);
    RegConsoleCmd("sm_clone", Command_Clone);
    RegConsoleCmd("sm_move", Command_Move);
    RegConsoleCmd("sm_nudge", Command_Nudge);
    RegConsoleCmd("sm_rotate", Command_Rotate);
    RegConsoleCmd("sm_kill", Command_Kill);
    RegConsoleCmd("sm_info", Command_Info);
    RegConsoleCmd("sm_togglehud", Command_ToggleHud);
    HookEvent("player_team", PlayerTeam_Event);
    hLadders = new StringMap();
    for (int i = 1; i <= MaxClients; i++) {
        selectedLadder[i] = -1;
        bEditMode[i] = false;
        in_attack[i] = false;
        in_attack2[i] = false;
        in_score[i] = false;
        in_speed[i] = false;
        bHudActive[i] = false;
        stepSize[i] = DEFAULT_STEP_SIZE;
    }
    CreateTimer(HUD_DRAW_INTERVAL, HudDrawTimer, _, TIMER_REPEAT);
}

public void OnMapStart() {
    for (int i = 1; i <= MaxClients; i++) {
        selectedLadder[i] = -1;
        bEditMode[i] = false;
        in_attack[i] = false;
        in_attack2[i] = false;
        in_score[i] = false;
        in_speed[i] = false;
        bHudActive[i] = false;
        stepSize[i] = DEFAULT_STEP_SIZE;
    }
    hLadders.Clear();
}

public void OnClientAuthorized(int client, const char[] auth)
{
    bHudHintShown[client] = false;
}

public void OnClientDisconnect_Post(int client)
{
    bEditMode[client] = false;
    in_attack[client] = false;
    in_attack2[client] = false;
    in_score[client] = false;
    in_speed[client] = false;
    bHudActive[client] = false;
    stepSize[client] = DEFAULT_STEP_SIZE;
}

stock void SetClientFrozen(int client, int freeze)
{
    SetEntityMoveType(client, freeze ? MOVETYPE_NONE : MOVETYPE_WALK);
}

public Action Command_ToggleHud(int client, int args) 
{
    bHudActive[client] = !bHudActive[client];
    CPrintToChat(client, "<{olive}HUD{default}> Ladder Editor HUD is now %s.", (bHudActive[client] ? "{blue}on{default}" : "{red}off{default}"));
}

public Action HudDrawTimer(Handle hTimer) 
{
    

    for (int i = 1; i <= MaxClients; i++) 
    {
        if (!bHudActive[i] || IsFakeClient(i))
            continue;
        Handle hud = CreatePanel();
        FillHudInfo(i, hud);
        SendPanelToClient(hud, i, DummyHudHandler, 3);
        delete hud;
        if (!bHudHintShown[i])
        {
            bHudHintShown[i] = true;
            CPrintToChat(i, "<{olive}HUD{default}> Type {green}!togglehud{default} into chat to toggle the {blue}Ladder Editor HUD{default}.");
        }
    }
}

public int DummyHudHandler(Handle hMenu, MenuAction action, int param1, int param2) {}

public void FillHudInfo(int client, Handle hHud)
{
    DrawPanelText(hHud, "Ladder Editor HUD");
    DrawPanelText(hHud, " ");
    char buffer[512];
    Format(buffer, sizeof(buffer), "Edit mode: %s", (bEditMode[client] ? "on" : "off"));
    DrawPanelText(hHud, buffer);
    DrawPanelText(hHud, " ");
    int entity = selectedLadder[client];
    if (!IsValidEntity(entity)) {
        Format(buffer, sizeof(buffer), "No ladder selected.");
        DrawPanelText(hHud, buffer);
        return;
    }

    char modelname[128];
    float origin[3];
    float position[3];
    float normal[3];
    float angles[3];
    GetLadderEntityInfo(entity, modelname, sizeof(modelname), origin, position, normal, angles);

    Format(buffer, sizeof(buffer), "Entity: %i", entity);
    DrawPanelText(hHud, buffer);
    Format(buffer, sizeof(buffer), "Model Name: %s", modelname);
    DrawPanelText(hHud, buffer);
    Format(buffer, sizeof(buffer), "Position: %.2f, %.2f, %.2f", position[0], position[1], position[2]);
    DrawPanelText(hHud, buffer);
    Format(buffer, sizeof(buffer), "Origin: %.2f, %.2f, %.2f", origin[0], origin[1], origin[2]);
    DrawPanelText(hHud, buffer);
    Format(buffer, sizeof(buffer), "Normal: %.2f, %.2f, %.2f", normal[0], normal[1], normal[2]);
    DrawPanelText(hHud, buffer);
    Format(buffer, sizeof(buffer), "Angles: %.2f, %.2f, %.2f", angles[0], angles[1], angles[2]);
    DrawPanelText(hHud, buffer);
}

public bool GetEndPosition(int client, float end[3])
{
    float start[3];
    float angle[3];
    GetClientEyePosition(client, start);
    GetClientEyeAngles(client, angle);
    TR_TraceRayFilter(start, angle, MASK_SOLID, RayType_Infinite, TraceEntityFilterPlayer, client);
    if (TR_DidHit(INVALID_HANDLE))
    {
        TR_GetEndPosition(end, INVALID_HANDLE);
        return true;
    }
    return false;
}

public bool TraceEntityFilterPlayer(int entity, int contentsMask, any data)
{
    return entity > MaxClients;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon) {
    if (client <= 0 || client > MaxClients) return Plugin_Continue;
    if (!IsClientInGame(client)) return Plugin_Continue;
    if (IsFakeClient(client)) return Plugin_Continue;
    
    int prevButtons = buttons;

    // Player was holding m1, and now isn't. (Released)
    if (buttons & IN_ATTACK != IN_ATTACK && in_attack[client]) {
        in_attack[client] = false;
        if (bEditMode[client])
            Command_Select(client, 0);
    }
    // Player was not holding m1, and now is. (Pressed)
    if (buttons & IN_ATTACK == IN_ATTACK && !in_attack[client]) {
        in_attack[client] = true;
    }

    // Player was holding m2, and now isn't. (Released)
    if (buttons & IN_ATTACK2 != IN_ATTACK2 && in_attack2[client]) {
        in_attack2[client] = false;
        if (bEditMode[client]) {
            float end[3];
            if (GetEndPosition(client, end))
                Move(client, end[0], end[1], end[2], true);
            else
                PrintToChat(client, "Invalid end position.");
        }
    }
    // Player was not holding m2, and now is. (Pressed)
    if (buttons & IN_ATTACK2 == IN_ATTACK2 && !in_attack2[client]) {
        in_attack2[client] = true;
    }

    // Player was holding tab, and now isn't. (Released)
    if (buttons & IN_SCORE != IN_SCORE && in_score[client]) {
        in_score[client] = false;
        Command_Edit(client, 0);
    }
    // Player was not holding tab, and now is. (Pressed)
    if (buttons & IN_SCORE == IN_SCORE && !in_score[client]) {
        in_score[client] = true;
    }

    // Player was holding shift, and now isn't. (Released)
    if (buttons & IN_SPEED != IN_SPEED && in_speed[client]) {
        in_speed[client] = false;
        if (bEditMode[client])
            RotateStep(client);
    }
    // Player was not holding shift, and now is. (Pressed)
    if (buttons & IN_SPEED == IN_SPEED && !in_speed[client]) {
        in_speed[client] = true;
    }
    
    if (!bEditMode[client]) return Plugin_Continue;

    if (buttons & IN_MOVELEFT == IN_MOVELEFT) {
        Nudge(client, -stepSize[client], 0.0, 0.0, false);
    }
    if (buttons & IN_MOVERIGHT == IN_MOVERIGHT) {
        Nudge(client, stepSize[client], 0.0, 0.0, false);
    }
    if (buttons & IN_FORWARD == IN_FORWARD) {
        Nudge(client, 0.0, stepSize[client], 0.0, false);
    }
    if (buttons & IN_BACK == IN_BACK) {
        Nudge(client, 0.0, -stepSize[client], 0.0, false);
    }
    if (buttons & IN_USE == IN_USE) {
        Nudge(client, 0.0, 0.0, stepSize[client], false);
    }
    if (buttons & IN_RELOAD == IN_RELOAD) {
        Nudge(client, 0.0, 0.0, -stepSize[client], false);
    }

    buttons &= ~(IN_ATTACK | IN_ATTACK2 | IN_SCORE | IN_USE | IN_RELOAD);

    if (prevButtons != buttons) {
        return Plugin_Changed;
    }
    return Plugin_Continue;
}

public Action PlayerTeam_Event(Handle event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    int team = GetEventInt(event, "team");
    if (bEditMode[client]) {
        bEditMode[client] = false;
        PrintToChat(client, "Exiting edit mode.");
    }
}

public Action Command_Step(int client, int args)
{
    if (args != 1) {
        PrintToChat(client, "[SM] Usage: sm_step <size>");
        return Plugin_Handled;
    }
    char x[8];
    GetCmdArg(1, x, sizeof(x));
    int size = StringToInt(x);
    if (size > 0) {
        stepSize[client] = size * 1.0;
        PrintToChat(client, "Step size set to %i.", size);
    }
    else {
        PrintToChat(client, "Step size must be greater than 0.");
    }
    return Plugin_Handled;
}

public Action Command_Edit(int client, int args)
{
    if (GetClientTeam(client) != TEAM_INFECTED) {
        PrintToChat(client, "Must be on infected team to enter edit mode.");
        return Plugin_Handled;
    }
    if (bEditMode[client]) {
        bEditMode[client] = false;
        SetClientFrozen(client, false);
        PrintToChat(client, "Exiting edit mode.");
    }
    else {
        bEditMode[client] = true;
        SetClientFrozen(client, true);
        PrintToChat(client, "Entering edit mode.");
    }
    return Plugin_Handled;
}

public Action Command_Kill(int client, int args)
{
    char modelname[128];
    char classname[MAX_STR_LEN];
    int entity = selectedLadder[client];
    if (IsValidEntity(entity)) {
        GetEntityClassname(entity, classname, MAX_STR_LEN);
        float normal[3];
        float origin[3];
        float position[3];
        float mins[3];
        float maxs[3];
        GetEntPropVector(entity, Prop_Send, "m_climbableNormal", normal);
        GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin);
        GetEntPropVector(entity,Prop_Send,"m_vecMins",mins);
        GetEntPropVector(entity,Prop_Send,"m_vecMaxs",maxs);
        position[0] = origin[0] + (mins[0] + maxs[0]) * 0.5;
        position[1] = origin[1] + (mins[1] + maxs[1]) * 0.5;
        position[2] = origin[1] + (mins[2] + maxs[2]) * 0.5;
        AcceptEntityInput(entity, "Kill");
        selectedLadder[client] = -1;
        char key[8];
        IntToString(entity, key, 8);
        RemoveFromTrie(hLadders, key);
        PrintToChat(client, "Killed ladder entity %i, %s at (%.2f,%.2f,%.2f). origin: (%.2f,%.2f,%.2f). normal: (%.2f,%.2f,%.2f)", entity, modelname, position[0], position[1], position[2], origin[0], origin[1], origin[2], normal[0], normal[1], normal[2]);
    }
    else {
        PrintToChat(client, "No ladder selected.");
    }
    return Plugin_Handled;
}

public void GetLadderEntityInfo(int entity, char[] modelname, int modelnamelen, float origin[3], float position[3], float normal[3], float angles[3]) {
    float mins[3];
    float maxs[3];
    GetEntPropString(entity, Prop_Data, "m_ModelName", modelname, modelnamelen);
    GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin);
    GetEntPropVector(entity, Prop_Send, "m_vecMins", mins);
    GetEntPropVector(entity, Prop_Send, "m_vecMaxs", maxs);
    GetEntPropVector(entity, Prop_Send, "m_climbableNormal", normal);
    GetEntPropVector(entity, Prop_Send, "m_angRotation", angles);
    Math_RotateVector(mins, angles, mins);
    Math_RotateVector(maxs, angles, maxs);
    position[0] = origin[0] + (mins[0] + maxs[0]) * 0.5;
    position[1] = origin[1] + (mins[1] + maxs[1]) * 0.5;
    position[2] = origin[2] + (mins[2] + maxs[2]) * 0.5;
}

public Action Command_Info(int client, int args)
{
    char classname[MAX_STR_LEN];
    int entity = GetClientAimTarget(client, false);
    if (IsValidEntity(entity)) {
        GetEntityClassname(entity, classname, MAX_STR_LEN);
        if (StrEqual(classname, "func_simpleladder", false)) {
            char modelname[128];
            float origin[3];
            float position[3];
            float normal[3];
            float angles[3];
            GetLadderEntityInfo(entity, modelname, sizeof(modelname), origin, position, normal, angles);

            PrintToChat(client, "Ladder entity %i, %s at (%.2f,%.2f,%.2f). origin: (%.2f,%.2f,%.2f). normal: (%.2f,%.2f,%.2f). angles: (%.2f,%.2f,%.2f)", entity, modelname, position[0], position[1], position[2], origin[0], origin[1], origin[2], normal[0], normal[1], normal[2], angles[0], angles[1], angles[2]);

            PrintToConsole(client, "add:");
            PrintToConsole(client, "{");
            PrintToConsole(client, "    \"model\" \"%s\"", modelname);
            PrintToConsole(client, "    \"normal.z\" \"%.2f\"", normal[2]);
            PrintToConsole(client, "    \"normal.y\" \"%.2f\"", normal[1]);
            PrintToConsole(client, "    \"normal.x\" \"%.2f\"", normal[0]);
            PrintToConsole(client, "    \"team\" \"2\"");
            PrintToConsole(client, "    \"classname\" \"func_simpleladder\"");
            PrintToConsole(client, "    \"origin\" \"%.2f %.2f %.2f\"", origin[0], origin[1], origin[2]);
            PrintToConsole(client, "    \"angles\" \"%.2f %.2f %.2f\"", angles[0], angles[1], angles[2]);
            PrintToConsole(client, "}");
        }
        else {
            PrintToChat(client, "Not looking at a ladder. Entity %i, classname: %s", entity, classname);
        }
    }
    else {
        PrintToChat(client, "Looking at invalid entity %i", entity);
    }
    return Plugin_Handled;
}

public void RotateStep(int client)
{
    int entity = selectedLadder[client];
    if (IsValidEntity(entity)) {
        char modelname[128];
        float origin[3];
        float position[3];
        float normal[3];
        float angles[3];
        GetLadderEntityInfo(entity, modelname, sizeof(modelname), origin, position, normal, angles);
        Rotate(client, 0.0, angles[1] + 90, 0.0, true);
    }
    else {
        PrintToChat(client, "No ladder selected.");
    }
}

public void Nudge(int client, float x, float y, float z, bool bPrint)
{
    int entity = selectedLadder[client];
    if (IsValidEntity(entity)) {
        float position[3];
        GetEntPropVector(entity, Prop_Send, "m_vecOrigin", position);
        float origin[3];
        origin[0] = position[0] + x;
        origin[1] = position[1] + y;
        origin[2] = position[2] + z;
        TeleportEntity(entity, origin, NULL_VECTOR, NULL_VECTOR);
        GetEntPropVector(entity, Prop_Send, "m_vecOrigin", position);
        if (bPrint)
            PrintToChat(client, "Nudged ladder entity %i. Origin (%.2f,%.2f,%.2f)", entity, origin[0], origin[1], origin[2]);
    }
    else {
        if (bPrint)
            PrintToChat(client, "No ladder selected.");
    }
}

public void Rotate(int client, float x, float y, float z, bool bPrint)
{
    int entity = selectedLadder[client];
    if (IsValidEntity(entity)) {
        int sourceEnt;
        char key[8];
        IntToString(entity, key, 8);
        if (!hLadders.GetValue(key, sourceEnt)) {
            if (bPrint)
                PrintToChat(client, "Original ladder not found.");
            return;
        }
        
        char modelname[128];
        float sourceOrigin[3];
        float sourcePos[3];
        float sourceNormal[3];
        float sourceAngles[3];
        GetLadderEntityInfo(sourceEnt, modelname, sizeof(modelname), sourceOrigin, sourcePos, sourceNormal, sourceAngles);
        if (bPrint)
            PrintToChat(client, "Original ladder entity %i at (%.2f,%.2f,%.2f)", sourceEnt, sourcePos[0], sourcePos[1], sourcePos[2]);
        
        float origin[3];
        float position[3];
        float normal[3];
        float angles[3];
        GetLadderEntityInfo(entity, modelname, sizeof(modelname), origin, position, normal, angles);
        
        angles[0] = x;
        angles[1] = y;
        angles[2] = z;
        
        float rotatedPos[3];
        Math_RotateVector(sourcePos, angles, rotatedPos);
        
        origin[0] = -rotatedPos[0] + position[0];
        origin[1] = -rotatedPos[1] + position[1];
        origin[2] = -rotatedPos[2] + position[2];
    
        TeleportEntity(entity, origin, angles, NULL_VECTOR);
        
        Math_RotateVector(sourceNormal, angles, normal);
        SetEntPropVector(entity, Prop_Send, "m_climbableNormal", normal);
        
        if (bPrint)
            PrintToChat(client, "Rotated ladder entity %i. Origin (%.2f,%.2f,%.2f). Angles (%.2f,%.2f,%.2f). Normal (%.2f,%.2f,%.2f)", entity, origin[0], origin[1], origin[2], angles[0], angles[1], angles[2], normal[0], normal[1], normal[2]);
    }
    else {
        if (bPrint)
            PrintToChat(client, "No ladder selected.");
    }
}

public void Move(int client, float x, float y, float z, bool bPrint)
{
    int entity = selectedLadder[client];
    if (IsValidEntity(entity)) {
        int sourceEnt;
        char key[8];
        IntToString(entity, key, 8);
        if (!hLadders.GetValue(key, sourceEnt)) {
            if (bPrint)
                PrintToChat(client, "Original ladder not found.");
            return;
        }
        
        char modelname[128];
        float origin[3];
        float sourcePos[3];
        float normal[3];
        float angles[3];
        GetLadderEntityInfo(sourceEnt, modelname, sizeof(modelname), origin, sourcePos, normal, angles);

        if (bPrint)
            PrintToChat(client, "Original ladder entity %i at (%.2f,%.2f,%.2f)", sourceEnt, sourcePos[0], sourcePos[1], sourcePos[2]);
        
        origin[0] = x - sourcePos[0];
        origin[1] = y - sourcePos[1];
        origin[2] = z - sourcePos[2];
    
        TeleportEntity(entity, origin, NULL_VECTOR, NULL_VECTOR);
        if (bPrint)
            PrintToChat(client, "Moved ladder entity %i. Origin (%.2f,%.2f,%.2f)", entity, origin[0], origin[1], origin[2]);
    }
    else {
        if (bPrint)
            PrintToChat(client, "No ladder selected.");
    }
}

public Action Command_Rotate(int client, int args)
{
    if (args != 3) {
        PrintToChat(client, "[SM] Usage: sm_rotate <x> <y> <z>");
        return Plugin_Handled;
    }
    char x[8];
    char y[8];
    char z[8];
    GetCmdArg(1, x, sizeof(x));
    GetCmdArg(2, y, sizeof(y));
    GetCmdArg(3, z, sizeof(z));
    Rotate(client, StringToFloat(x), StringToFloat(y), StringToFloat(z), true);
    return Plugin_Handled;
}

public Action Command_Nudge(int client, int args)
{
    if (args != 3) {
        PrintToChat(client, "[SM] Usage: sm_nudge <x> <y> <z>");
        return Plugin_Handled;
    }
    char x[8], y[8], z[8];
    GetCmdArg(1, x, sizeof(x));
    GetCmdArg(2, y, sizeof(y));
    GetCmdArg(3, z, sizeof(z));
    Nudge(client, StringToFloat(x), StringToFloat(y), StringToFloat(z), true);
    return Plugin_Handled;
}

public Action Command_Move(int client, int args)
{
    if (args != 3) {
        PrintToChat(client, "[SM] Usage: sm_move <x> <y> <z>");
        return Plugin_Handled;
    }
    char x[8], y[8], z[8];
    GetCmdArg(1, x, sizeof(x));
    GetCmdArg(2, y, sizeof(y));
    GetCmdArg(3, z, sizeof(z));
    Move(client, StringToFloat(x), StringToFloat(y), StringToFloat(z), true);
    return Plugin_Handled;
}

public Action Command_Clone(int client, int args)
{
    char classname[MAX_STR_LEN];
    int sourceEnt = selectedLadder[client];
    if (IsValidEntity(sourceEnt)) {
        GetEntityClassname(sourceEnt, classname, MAX_STR_LEN);
        if (!StrEqual(classname, "func_simpleladder", false)) {
            selectedLadder[client] = -1;
            PrintToChat(client, "No ladder selected.");
            return Plugin_Handled;
        }
        char modelname[128];
        float origin[3];
        float position[3];
        float normal[3];
        float angles[3];
        GetLadderEntityInfo(sourceEnt, modelname, sizeof(modelname), origin, position, normal, angles);
        PrecacheModel(modelname, true);
        int entity = CreateEntityByName("func_simpleladder");
        if (entity == -1)
        {
            PrintToChat(client, "Failed to create ladder.");
            return Plugin_Handled;
        }
        char buf[32];
        DispatchKeyValue(entity, "model", modelname);
        Format(buf, sizeof(buf), "%.6f", normal[2]);
        DispatchKeyValue(entity, "normal.z", buf);
        Format(buf, sizeof(buf), "%.6f", normal[1]);
        DispatchKeyValue(entity, "normal.y", buf);
        Format(buf, sizeof(buf), "%.6f", normal[0]);
        DispatchKeyValue(entity, "normal.x", buf);
        DispatchKeyValue(entity, "team", "2");
        DispatchKeyValue(entity, "origin", "50 0 0");

        DispatchSpawn(entity);
        selectedLadder[client] = entity;
        char key[8];
        IntToString(entity, key, 8);
        SetTrieValue(hLadders, key, sourceEnt, true);
        PrintToChat(client, "Cloned ladder entity %i. New entity %i", sourceEnt, entity);
    }
    else {
        PrintToChat(client, "No ladder selected.");
    }
    return Plugin_Handled;
}

public Action Command_Select(int client, int args)
{
    char classname[MAX_STR_LEN];
    int entity = GetClientAimTarget(client, false);
    if (IsValidEntity(entity)) {
        GetEntityClassname(entity, classname, MAX_STR_LEN);
        if (StrEqual(classname, "func_simpleladder", false)) {
            selectedLadder[client] = entity;
            
            char modelname[128];
            float origin[3];
            float position[3];
            float normal[3];
            float angles[3];
            GetLadderEntityInfo(entity, modelname, sizeof(modelname), origin, position, normal, angles);
            PrintToChat(client, "Selected ladder entity %i, %s at (%.2f,%.2f,%.2f). origin: (%.2f,%.2f,%.2f). normal: (%.2f,%.2f,%.2f)", entity, modelname, position[0], position[1], position[2], origin[0], origin[1], origin[2], normal[0], normal[1], normal[2]);
        }
        else {
            selectedLadder[client] = -1;
            PrintToChat(client, "Not looking at a ladder. Entity %i, classname: %s", entity, classname);
        }
    }
    else {
        selectedLadder[client] = -1;
        PrintToChat(client, "Looking at invalid entity %i", entity);
    }
    return Plugin_Handled;
}

// from smlib https://github.com/bcserv/smlib

/**
 * Rotates a vector around its zero-point.
 * Note: As example you can rotate mins and maxs of an entity and then add its origin to mins and maxs to get its bounding box in relation to the world and its rotation.
 * When used with players use the following angle input:
 *   angles[0] = 0.0;
 *   angles[1] = 0.0;
 *   angles[2] = playerEyeAngles[1];
 *
 * @param vec 			Vector to rotate.
 * @param angles 		How to rotate the vector.
 * @param result		Output vector.
 * @noreturn
 */
stock void Math_RotateVector(const float vec[3], const float angles[3], float result[3])
{
    // First the angle/radiant calculations
    float rad[3];
    // I don't really know why, but the alpha, beta, gamma order of the angles are messed up...
    // 2 = xAxis
    // 0 = yAxis
    // 1 = zAxis
    rad[0] = DegToRad(angles[2]);
    rad[1] = DegToRad(angles[0]);
    rad[2] = DegToRad(angles[1]);

    // Pre-calc function calls
    float cosAlpha = Cosine(rad[0]);
    float sinAlpha = Sine(rad[0]);
    float cosBeta = Cosine(rad[1]);
    float sinBeta = Sine(rad[1]);
    float cosGamma = Cosine(rad[2]);
    float sinGamma = Sine(rad[2]);

    // 3D rotation matrix for more information: http://en.wikipedia.org/wiki/Rotation_matrix#In_three_dimensions
    float x = vec[0];
    float y = vec[1];
    float z = vec[2];
    float newX;
    float newY;
    float newZ;
    newY = cosAlpha*y - sinAlpha*z;
    newZ = cosAlpha*z + sinAlpha*y;
    y = newY;
    z = newZ;

    newX = cosBeta*x + sinBeta*z;
    newZ = cosBeta*z - sinBeta*x;
    x = newX;
    z = newZ;

    newX = cosGamma*x - sinGamma*y;
    newY = cosGamma*y + sinGamma*x;
    x = newX;
    y = newY;

    // Store everything...
    result[0] = x;
    result[1] = y;
    result[2] = z;
}