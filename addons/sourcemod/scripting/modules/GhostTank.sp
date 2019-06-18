#include <sourcemod>
#include <sdktools>

#define 		ZOMBIECLASS_TANK						8

const 	Float:	THROWRANGE 								= 99999999.0;
const 	Float:	FIREIMMUNITY_TIME 						= 5.0;
const 			INCAPHEALTH 							= 300;
const 	Float:	SPECHUD_UPDATEINTERVAL 					= 0.5;

new 	Handle:	g_hGT_Enabled;
new 			g_iGT_TankClient;
new 	bool:	g_bGT_TankIsInPlay;
new 	bool:	g_bGT_TankHasFireImmunity;
new		Handle: g_hGT_TankDeathTimer=INVALID_HANDLE;

new		Handle:	g_hGT_RemoveEscapeTank;
new		bool:	g_bGT_FinaleVehicleIncoming;

new		Handle:	g_hGT_BlockPunchRock;

/*new 	Handle:	g_hGT_SpecHUD;
new 			g_iGT_SpecHUD_LastHealth;
new		Handle:	g_hGT_SpecHUD_TankHealth;
new 	bool:	g_bGT_SpecHUD_ShowPanel[MAXPLAYERS+1] 	= true;
new 	bool:	g_bGT_SpecHUD_ShowHint[MAXPLAYERS+1] 	= true;
*/
new passes;

// Disable Tank Hordes items
static	Handle: g_hGT_DisableTankHordes;
static 	bool:	g_bGT_HordesDisabled;

GT_OnModuleStart()
{
    g_hGT_Enabled	= CreateConVarEx("boss_tank", "1", "Tank can't be prelight, frozen and ghost until player takes over, punch fix, and no rock throw for AI tank while waiting for player",CVAR_FLAGS);
    g_hGT_RemoveEscapeTank = CreateConVarEx("remove_escape_tank", "1", "Remove tanks that spawn as the rescue vehicle is incoming on finales.");
    g_hGT_DisableTankHordes = CreateConVarEx("disable_tank_hordes", "0", "Disable natural hordes while tanks are in play");
    g_hGT_BlockPunchRock = CreateConVarEx("block_punch_rock", "0", "Block tanks from punching and throwing a rock at the same time");
    HookEvent("tank_spawn", GT_TankSpawn);
    HookEvent("player_death",GT_TankKilled);
    HookEvent("player_hurt",GT_TankOnFire);
    HookEvent("round_start",GT_RoundStart);
    HookEvent("item_pickup", GT_ItemPickup);
    HookEvent("player_incapacitated", GT_PlayerIncap);
    HookEvent("finale_vehicle_incoming", GT_FinaleVehicleIncoming);
    //RegConsoleCmd("tankhud",GT_SpecHUD_Command,"Toggles Confogl\'s Tank Spectate HUD");
    //g_hGT_SpecHUD_TankHealth = FindConVar("z_tank_health");
    //g_iGT_SpecHUD_LastHealth = RoundFloat(GetConVarFloat(g_hGT_SpecHUD_TankHealth)*1.5);
}

// For other modules to use
public IsTankInPlay()
{
    return g_bGT_TankIsInPlay;
}

Action:GT_OnTankSpawn_Forward()
{
    if(IsPluginEnabled() && GetConVarBool(g_hGT_RemoveEscapeTank) && g_bGT_FinaleVehicleIncoming)
        return Plugin_Handled;
    return Plugin_Continue;
}

public Action:L4D_OnCThrowActivate()
{
    if(IsPluginEnabled() && IsTankInPlay() && GetConVarBool(g_hGT_BlockPunchRock) && GetClientButtons(g_iGT_TankClient) & IN_ATTACK)
    {
        if(IsDebugEnabled())
        {
            LogMessage("[GT] Blocking Haymaker on %L", g_iGT_TankClient);
        }
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

Action:GT_OnSpawnMob_Forward(&amount)
{
    // quick fix. needs normalize_hordes 1
    if(IsPluginEnabled())
    {
        if(IsDebugEnabled())
        {
            LogMessage("[GT] SpawnMob(%d), HordesDisabled: %d TimerDuration: %f Minimum: %f Remaining: %f", 
            amount, g_bGT_HordesDisabled, L4D2_CTimerGetCountdownDuration(L4D2CT_MobSpawnTimer), 
            GetConVarFloat(FindConVar("z_mob_spawn_min_interval_normal")), L4D2_CTimerGetRemainingTime(L4D2CT_MobSpawnTimer));
        }
        if(g_bGT_HordesDisabled)
        {
            static Handle:mob_spawn_interval_min, Handle:mob_spawn_interval_max, Handle:mob_spawn_size_min, Handle:mob_spawn_size_max;
            if(mob_spawn_interval_min == INVALID_HANDLE)
            {
                mob_spawn_interval_min = FindConVar("z_mob_spawn_min_interval_normal");
                mob_spawn_interval_max = FindConVar("z_mob_spawn_max_interval_normal");
                mob_spawn_size_min = FindConVar("z_mob_spawn_min_size");
                mob_spawn_size_max = FindConVar("z_mob_spawn_max_size");
            }
            
            new minsize = GetConVarInt(mob_spawn_size_min), maxsize = GetConVarInt(mob_spawn_size_max);
            if (amount < minsize || amount > maxsize)
            {
                return Plugin_Continue;
            }
            if (!L4D2_CTimerIsElapsed(L4D2CT_MobSpawnTimer))
            {
                return Plugin_Continue;
            }
            
            new Float:duration = L4D2_CTimerGetCountdownDuration(L4D2CT_MobSpawnTimer);
            if (duration < GetConVarFloat(mob_spawn_interval_min) || duration > GetConVarFloat(mob_spawn_interval_max))
            {
                return Plugin_Continue;
            }
            
            return Plugin_Handled;
        }
    }
    return Plugin_Continue;
}

// Disable stasis when we're using GhostTank
Action:GT_OnTryOfferingTankBot(& bool:enterStasis)
{
    passes++;
    if(IsPluginEnabled())
    {
        if(GetConVarBool(g_hGT_Enabled)) enterStasis=false;
        if(GetConVarBool(g_hGT_RemoveEscapeTank) && g_bGT_FinaleVehicleIncoming) return Plugin_Handled;
    }
    return Plugin_Continue;
}

public GT_FinaleVehicleIncoming(Handle:event, const String:name[], bool:dontBroadcast)
{
    g_bGT_FinaleVehicleIncoming = true;
    if(g_bGT_TankIsInPlay && IsFakeClient(g_iGT_TankClient))
    {
        KickClient(g_iGT_TankClient);
        GT_Reset();
    }
}

public GT_ItemPickup(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (!g_bGT_TankIsInPlay) return;
    
    decl String:item[64];
    GetEventString(event, "item", item, sizeof(item));
    
    if (StrEqual(item, "tank_claw")) 
    {
        g_iGT_TankClient = GetClientOfUserId(GetEventInt(event, "userid"));
        if(g_hGT_TankDeathTimer != INVALID_HANDLE)
        {
            KillTimer(g_hGT_TankDeathTimer);
            g_hGT_TankDeathTimer = INVALID_HANDLE;
        }
    }
}

static DisableNaturalHordes()
{
    // 0x7fff = 16 bit signed max value. Over 9 hours.
    g_bGT_HordesDisabled = true;
}

static EnableNaturalHordes()
{
    g_bGT_HordesDisabled = false;
}

public GT_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    g_bGT_FinaleVehicleIncoming = false;
    GT_Reset();
}

public GT_TankKilled(Handle:event, const String:name[], bool:dontBroadcast)
{
    if(!g_bGT_TankIsInPlay) return;
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if(client != g_iGT_TankClient) return;
    g_hGT_TankDeathTimer = CreateTimer(1.0,GT_TankKilled_Timer);
}

public GT_TankSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    g_iGT_TankClient = client;
    
    if(g_bGT_TankIsInPlay) return;
    
    g_bGT_TankIsInPlay = true;
    
    if(GetConVarBool(g_hGT_DisableTankHordes))
    {
        DisableNaturalHordes();
    }
    
    if(!IsPluginEnabled() || !GetConVarBool(g_hGT_Enabled)) return;
    
    
    // Spec HUD
    //CreateTimer(SPECHUD_UPDATEINTERVAL, GT_SpecHUD_Timer, INVALID_HANDLE, TIMER_REPEAT);
    
    new Float:fFireImmunityTime = FIREIMMUNITY_TIME;
    new Float:fSelectionTime = GetConVarFloat(FindConVar("director_tank_lottery_selection_time"));
    
    if(IsFakeClient(client))
    {
        GT_PauseTank();
        CreateTimer(fSelectionTime,GT_ResumeTankTimer);
        fFireImmunityTime += fSelectionTime;
    }
    
    CreateTimer(fFireImmunityTime,GT_FireImmunityTimer);
}

public GT_TankOnFire(Handle:event, const String:name[], bool:dontBroadcast)
{
    if(!g_bGT_TankIsInPlay || !g_bGT_TankHasFireImmunity || !IsPluginEnabled() || !GetConVarBool(g_hGT_Enabled)) return;
    
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if(g_iGT_TankClient != client || !IsValidClient(client)) return;
    
    new dmgtype = GetEventInt(event,"type");
    
    if(dmgtype != 8) return;
    
    ExtinguishEntity(client);
    new CurHealth = GetClientHealth(client);
    new DmgDone	  = GetEventInt(event,"dmg_health");
    SetEntityHealth(client,(CurHealth + DmgDone));
}

public GT_PlayerIncap(Handle:event, String:event_name[], bool:dontBroadcast)
{
    if(!g_bGT_TankIsInPlay || !IsPluginEnabled() || !GetConVarBool(g_hGT_Enabled)) return;
    
    decl String:weapon[16];
    GetEventString(event, "weapon", weapon, 16);
    
    if(!StrEqual(weapon, "tank_claw")) return;
    
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if(!IsValidClient(client)) return;
    
    SetEntProp(client, Prop_Send, "m_isIncapacitated", 0);
    SetEntityHealth(client, 1);
    CreateTimer(0.4, GT_IncapTimer, client);
}

public Action:GT_IncapTimer(Handle:timer, any:client)
{
    SetEntProp(client, Prop_Send, "m_isIncapacitated", 1);
    SetEntityHealth(client, INCAPHEALTH);
}

public Action:GT_ResumeTankTimer(Handle:timer)
{
    GT_ResumeTank();
}

public Action:GT_FireImmunityTimer(Handle:timer)
{
    g_bGT_TankHasFireImmunity = false;
}

GT_PauseTank()
{
    SetConVarFloat(FindConVar("tank_throw_allow_range"),THROWRANGE);
    if(!IsValidEntity(g_iGT_TankClient)) return;
    SetEntityMoveType(g_iGT_TankClient,MOVETYPE_NONE);
    SetEntProp(g_iGT_TankClient,Prop_Send,"m_isGhost",1,1);
}

GT_ResumeTank()
{
    ResetConVar(FindConVar("tank_throw_allow_range"));
    if(!IsValidEntity(g_iGT_TankClient)) return;
    SetEntityMoveType(g_iGT_TankClient,MOVETYPE_CUSTOM);
    SetEntProp(g_iGT_TankClient,Prop_Send,"m_isGhost",0,1);
}

GT_Reset()
{
    passes = 0;
    g_hGT_TankDeathTimer = INVALID_HANDLE;
    if(g_bGT_HordesDisabled)
    {
        EnableNaturalHordes();
    }
    g_bGT_TankIsInPlay = false;
    g_bGT_TankHasFireImmunity = true;
    //g_iGT_SpecHUD_LastHealth = RoundFloat(GetConVarFloat(g_hGT_SpecHUD_TankHealth)*1.5);
}

public Action:GT_TankKilled_Timer(Handle:timer)
{
    GT_Reset();
}


// //////////////////////////////////////////////
// Spec Hud
// //////////////////////////////////////////////
/*public Action:GT_SpecHUD_Timer(Handle:timer)
{
    GT_SpecHUD_Draw();
    GT_SpecHUD_Update();
    
    if(!g_bGT_TankIsInPlay)
    {
        GT_SpecHUD_ResetHint();
        return Plugin_Stop;
    }
    
    return Plugin_Continue;
}

public Action:GT_SpecHUD_Command(client,args)
{
    g_bGT_SpecHUD_ShowPanel[client] = !g_bGT_SpecHUD_ShowPanel[client];
    if(g_bGT_SpecHUD_ShowPanel[client])
    {
        PrintToChat(client,"\x01[\x05Confogl\x01] Tank HUD is now enabled.");
    }
    else
    {
        PrintToChat(client,"\x01[\x05Confogl\x01] Tank HUD is now disabled.");
    }
}

GT_OnClientDisconnect(client)
{
    g_bGT_SpecHUD_ShowPanel[client] = true;
    g_bGT_SpecHUD_ShowHint[client] = true;
}

GT_SpecHUD_ResetHint()
{
    for(new client = 1;client < MaxClients+1;client++)
    {
        g_bGT_SpecHUD_ShowHint[client] = true;
    }
}

GT_SpecHUD_Update()
{
    decl team;
    for(new client = 1;client < MaxClients+1;client++)
    {
        
        if(!IsValidClient(client)) continue;
        team = GetClientTeam(client);
        if(team == 2 || IsFakeClient(client) || !g_bGT_SpecHUD_ShowPanel[client] 
            || client == g_iGT_TankClient) 
            //|| (team == 1 && IsClientUsingSpecHud(client)) || client == g_iGT_TankClient) 
        continue; 
        
        SendPanelToClient(g_hGT_SpecHUD, client, GT_SpecHUD_MenuHandler, 3);
        
        if(g_bGT_SpecHUD_ShowHint[client])
        {
            g_bGT_SpecHUD_ShowHint[client] = false;
            PrintToChat(client,"\x01[\x05Confogl\x01] Say \x05/tankhud \x01to toggle the tank HUD.");
        }
    }
}

GT_SpecHUD_Draw()
{
    if(!g_bGT_TankIsInPlay)
    {
        return;
    }
    
    if(g_hGT_SpecHUD != INVALID_HANDLE)
    {
        CloseHandle(g_hGT_SpecHUD);
    }
    
    g_hGT_SpecHUD = CreatePanel();
    
    decl String:sTempString[512], String:sNameString[MAX_NAME_LENGTH+1];
    
    decl String:sCFGName[512];
    GetConVarString(FindConVar("l4d_ready_cfg_name"), sCFGName, sizeof(sCFGName));
    
    DrawPanelText(g_hGT_SpecHUD, sCFGName);
    DrawPanelText(g_hGT_SpecHUD, "Tank Spec HUD");
    DrawPanelText(g_hGT_SpecHUD, "-------------------------------");
    
    // Draw name
    if(IsValidClient(g_iGT_TankClient) && !IsFakeClient(g_iGT_TankClient))
    {
        GetClientName(g_iGT_TankClient,sNameString,sizeof(sNameString));
        
        if(strlen(sNameString) > 25)
        {
            sNameString[22] = '.';
            sNameString[23] = '.';
            sNameString[24] = '.';
            sNameString[25] = 0;
        }
        
        Format(sTempString, sizeof(sTempString), "  Control : %s (Pass #%i)", sNameString, passes);
    }
    else
    {
        Format(sTempString, sizeof(sTempString), "  Control : AI");
    }
    DrawPanelText(g_hGT_SpecHUD, sTempString);
    
    // Draw health
    new health = 0;
    if(IsValidClient(g_iGT_TankClient))
        health = GetClientHealth(g_iGT_TankClient);
    
    if(g_iGT_SpecHUD_LastHealth < health)
    {
        sTempString = "  Health  : Dead";
    }
    else
    {
        new healthpro = RoundFloat((100.0/(GetConVarFloat(g_hGT_SpecHUD_TankHealth)*1.5)) * health);
        if(healthpro < 1)
        {
            healthpro = 1;
        }
        Format(sTempString, sizeof(sTempString), "  Health  : %i / %i%%", health, healthpro);
        g_iGT_SpecHUD_LastHealth = health;
    }
    DrawPanelText(g_hGT_SpecHUD, sTempString);
    
    // Draw frustration
    if(IsValidClient(g_iGT_TankClient) && !IsFakeClient(g_iGT_TankClient))
    {
        Format(sTempString, sizeof(sTempString), "  Rage : %d%%", 100-GetEntProp(g_iGT_TankClient, Prop_Send, "m_frustration"));
    }
    else
    {
        sTempString = "  Frustr.  : Calm";
    }
    DrawPanelText(g_hGT_SpecHUD, sTempString);
    
    // Draw fire status
    if(IsValidClient(g_iGT_TankClient) && GetEntityFlags(g_iGT_TankClient) & FL_ONFIRE)
    {
        new timeleft = RoundToCeil(health / 80.0);
        Format(sTempString, sizeof(sTempString), "  OnFire. : Yes, %i sec",timeleft);
        DrawPanelText(g_hGT_SpecHUD, sTempString);
    }
}

public GT_SpecHUD_MenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
}
*/

bool:IsValidClient(client)
{
    if (client <= 0 || client > MaxClients) return false;
    if (!IsClientInGame(client)) return false;
    return true;
}
