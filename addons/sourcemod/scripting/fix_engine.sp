#define PLUGIN_VERSION "1.1.2"

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define debug 0

#define FIRST_RESTORE_TIME 0.3
#define RESTORE_TIME 2.0
#define MAX_HEALTH_PER_RESTORE 10
#define MAX_HEALTH 100
#define CONSTANT_HEALTH 1
#define MAX_TEMP_HEALTH MAX_HEALTH - CONSTANT_HEALTH

public Plugin:myinfo =
{
	name = "[L4D & L4D2] Engine Fix",
	author = "raziEiL [disawar1]",
	description = "Blocking ladder speed glitch, no fall damage bug, health boost glitch.",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/raziEiL"
}

enum ()
{
	LadderSpeedGlitch = 1,
	NoFallDamageBug,
	HealthBoostGlitch
};

static		Handle:g_hFixGlitchTimer[MAXPLAYERS+1], g_iHealthToRestore[MAXPLAYERS+1], g_iLastKnownHealth[MAXPLAYERS+1], Handle:g_hRestoreTimer[MAXPLAYERS+1],
			g_bTempWarnLock[MAXPLAYERS+1], Float:g_fCvarDecayRate, bool:g_bCvarWarnEnabled, g_iCvarEngineFlags;

public OnPluginStart()
{
	new Handle:hCvarDecayRate = FindConVar("pain_pills_decay_rate");

	CreateConVar("engine_fix_version", PLUGIN_VERSION, "Engine Fix plugin version", FCVAR_REPLICATED|FCVAR_NOTIFY);

	new Handle:hCvarWarnEnabled = CreateConVar("engine_warning", "0", "Display a warning message saying that player using expolit: 1=enable, 0=disable.", FCVAR_NONE, true, 0.0, true, 1.0);
	new Handle:hCvarEngineFlags = CreateConVar("engine_fix_flags", "14", "Enables what kind of exploit should be fixed/blocked. Flags (add together): 0=disable, 2=ladder speed glitch, 4=no fall damage bug, 8=health boost glitch.", FCVAR_NONE, true, 0.0, true, 14.0);
	//AutoExecConfig(true, "Fix_Engine");

	g_fCvarDecayRate = GetConVarFloat(hCvarDecayRate);
	g_bCvarWarnEnabled = GetConVarBool(hCvarWarnEnabled);
	g_iCvarEngineFlags = GetConVarInt(hCvarEngineFlags);

	if (g_iCvarEngineFlags & (1 << HealthBoostGlitch))
		EF_ToogleEvents(true);

	HookConVarChange(hCvarDecayRate, OnConvarChange_DecayRate);
	HookConVarChange(hCvarWarnEnabled, OnConvarChange_WarnEnabled);
	HookConVarChange(hCvarEngineFlags, OnConvarChange_EngineFlags);

#if debug
	RegConsoleCmd("debug", CmdDebug);
#endif
}

public OnMapEnd()
{
	for (new i = 0; i <= MAXPLAYERS; i++)
	{
		g_hRestoreTimer[i] = INVALID_HANDLE;
		g_hFixGlitchTimer[i] = INVALID_HANDLE;
#if debug
		g_hDebugTimer[i] = INVALID_HANDLE;
#endif
	}
}

/*                                      +==========================================+
                                        |               LADDER GLITCH              |
                                        |             NO FALL DMG GLITCH           |
                                        +==========================================+
*/
public Action:OnPlayerRunCmd(client, &buttons)
{
	if (g_iCvarEngineFlags && IsValidClient(client) && IsPlayerAlive(client) && !IsFakeClient(client)){

		if (g_iCvarEngineFlags & (1 << LadderSpeedGlitch) && GetEntityMoveType(client) == MOVETYPE_LADDER){

			static iUsingBug[MAXPLAYERS+1];

			if (buttons & 8 || buttons & 16){

				if (buttons & 512){

					iUsingBug[client]++;
					buttons &= ~IN_MOVELEFT;
				}
				if (buttons & 1024){

					iUsingBug[client]++;
					buttons &= ~IN_MOVERIGHT;
				}

				if (g_bCvarWarnEnabled && iUsingBug[client] > 48){

					WarningsMsg(client, 1);
					iUsingBug[client] = 0;
				}
			}
			else
				iUsingBug[client] = 0;
		}
		if (g_iCvarEngineFlags & (1 << NoFallDamageBug) && GetClientTeam(client) == 2 && IsFallDamage(client) && buttons & IN_USE){

			buttons &= ~IN_USE;

			if (g_bCvarWarnEnabled && !g_bTempWarnLock[client]){

				g_bTempWarnLock[client] = true;
				WarningsMsg(client, 2);
				CreateTimer(5.0, EF_t_UnlockWarnMsg, client);
			}
		}
	}
	return Plugin_Continue;
}

public Action:EF_t_UnlockWarnMsg(Handle:timer, any:client)
{
	g_bTempWarnLock[client] = false;
}

bool:IsFallDamage(client)
{
	return GetEntPropFloat(client, Prop_Send, "m_flFallVelocity") > 440;
}

/*                                      +==========================================+
                                        |               DROWN GLITCH               |
                                        +==========================================+
*/
public OnClientDisconnect(client)
{
	if (client && g_iCvarEngineFlags & (1 << HealthBoostGlitch))
		EF_ClearAllVars(client);
}

public EF_ev_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i = 1; i <= MaxClients; i++){

		EF_ClearAllVars(i);

		if (IsClientInGame(i) && IsDrownPropNotEqual(i))
			ForceEqualDrownProp(i);
	}
}

public EF_ev_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetEventInt(event, "type") & DMG_DROWN){

		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if (IsIncapacitated(client)) return;

		if (GetEventInt(event, "health") == CONSTANT_HEALTH){

			new damage = GetEventInt(event, "dmg_health");

			if (g_iLastKnownHealth[client] && damage >= g_iLastKnownHealth[client]){

				damage -= g_iLastKnownHealth[client];
				g_iLastKnownHealth[client] -= CONSTANT_HEALTH;
			}
			if (g_iHealthToRestore[client] < 0)
				g_iHealthToRestore[client] = 0;

			if (!g_iHealthToRestore[client]){

				EF_KillRestoreTimer(client);
				CreateTimer(FIRST_RESTORE_TIME, EF_t_CheckRestoring, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			}

			g_iHealthToRestore[client] += damage;
#if debug
			PrintToChatAll("m_idrowndmg = %d, dmg = %d, temp hp to restote = %d", GetEntProp(client, Prop_Data, "m_idrowndmg"), damage, g_iHealthToRestore[client]);
#endif
			decl Handle:hdataPack;
			CreateDataTimer(0.1, EF_t_SetDrownDmg, hdataPack, TIMER_FLAG_NO_MAPCHANGE);
			WritePackCell(hdataPack, client);
			WritePackCell(hdataPack, GetEntProp(client, Prop_Data, "m_idrowndmg") + g_iLastKnownHealth[client]);

			g_iLastKnownHealth[client] = 0;
		}
		else
			g_iLastKnownHealth[client] = GetEventInt(event, "health");
	}
}

public Action:EF_t_SetDrownDmg(Handle:timer, Handle:datapack)
{
	ResetPack(datapack, false);
	new client = ReadPackCell(datapack);

	if (!IsSurvivor(client)) return;

	new drowndmg = ReadPackCell(datapack);

	SetEntProp(client, Prop_Data, "m_idrowndmg", drowndmg);
}

public Action:EF_t_CheckRestoring(Handle:timer, any:client)
{
	if (g_iHealthToRestore[client] <= 0 || !IsSurvivor(client)){

		g_iHealthToRestore[client] = 0;
		return Plugin_Stop;
	}

	if (IsUnderWater(client))
		return Plugin_Continue;

	new Float:fHealthToRestore = float(GetEntProp(client, Prop_Data, "m_idrowndmg") - GetEntProp(client, Prop_Data, "m_idrownrestored"));

	if (fHealthToRestore <= 0){
#if debug
		PrintToChatAll("restoring started (player using glitch while have 1-10hp");
#endif
		g_hRestoreTimer[client] = CreateTimer(RESTORE_TIME, EF_t_RestoreTempHealth, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		return Plugin_Stop;
	}

	new iRestoreCount = RoundToCeil(fHealthToRestore / MAX_HEALTH_PER_RESTORE);
	new Float:fRestoreTimeEnd = RESTORE_TIME * float(iRestoreCount);
#if debug
	PrintToChatAll("restore count = %d (beginning in %.0f sec.)", iRestoreCount, fRestoreTimeEnd);
#endif
	CreateTimer(fRestoreTimeEnd, EF_t_StartRestoreTempHealth, client, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Stop;
}

public Action:EF_t_StartRestoreTempHealth(Handle:timer, any:client)
{
	if (g_iHealthToRestore[client] <= 0 || !IsSurvivor(client)) return;
#if debug
	PrintToChatAll("restoring started");
#endif
	g_hRestoreTimer[client] = CreateTimer(RESTORE_TIME, EF_t_RestoreTempHealth, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action:EF_t_RestoreTempHealth(Handle:timer, any:client)
{
	if (g_iHealthToRestore[client] <= 0 || !IsSurvivor(client)){

		EF_ClearVars(client);
		return Plugin_Stop;
	}

	if (!IsUnderWater(client) && !IsDrownPropNotEqual(client)){

		new Float:fTemp = GetTempHealth(client);
		new iLimit = MAX_TEMP_HEALTH - (GetClientHealth(client) + RoundToFloor(fTemp));
		new iTempToRestore = g_iHealthToRestore[client] >= MAX_HEALTH_PER_RESTORE ? MAX_HEALTH_PER_RESTORE : g_iHealthToRestore[client];

		if (iTempToRestore > iLimit){
#if debug
			PrintToChatAll("temp health limit is exceeded");
#endif
			iTempToRestore = iLimit;
			g_iHealthToRestore[client] = 0;

			if (iTempToRestore <= 0)
				return Plugin_Continue;
		}

		SetTempHealth(client, fTemp + iTempToRestore);
		g_iHealthToRestore[client] -= MAX_HEALTH_PER_RESTORE;

		EF_GlitchWarnFunc(client);
	}

	return Plugin_Continue;
}

public EF_ev_HealSuccess(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, StrEqual(name, "player_incapacitated") ? "userid" : "subject"));

	if (IsDrownPropNotEqual(client)){
#if debug
		PrintToChatAll("reset drownrestored prop %N", client);
#endif
		EF_ClearVars(client);
		ForceEqualDrownProp(client);
	}
}

public EF_ev_PillsUsed(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (IsDrownPropNotEqual(client)){

		EF_KillFixGlitchTimer(client);
		g_hFixGlitchTimer[client] = CreateTimer(0.0, EF_t_FixTempHpGlitch, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:EF_t_FixTempHpGlitch(Handle:timer, any:client)
{
	if (IsSurvivor(client) && !IsIncapacitated(client)){

		new Float:fTemp = GetTempHealth(client);

		if (fTemp){

			new iHealth = GetClientHealth(client);

			if ((iHealth + RoundToFloor(fTemp)) > MAX_TEMP_HEALTH){

				SetTempHealth(client, float(MAX_HEALTH - iHealth));

				EF_GlitchWarnFunc(client);
#if debug
				PrintToChatAll("temp glitch fixed");
#endif
			}
		}
		if (IsDrownPropNotEqual(client))
			return Plugin_Continue;
	}
#if debug
	PrintToChatAll("stopped temp glich fix timer");
#endif
	g_hFixGlitchTimer[client] = INVALID_HANDLE;
	return Plugin_Stop;
}

EF_GlitchWarnFunc(client)
{
	if (g_bCvarWarnEnabled && !g_bTempWarnLock[client]){

		g_bTempWarnLock[client] = true;
		WarningsMsg(client, 3);
		CreateTimer(15.0, EF_t_UnlockWarnMsg, client);
	}
}

EF_KillRestoreTimer(client)
{
	if (g_hRestoreTimer[client] != INVALID_HANDLE){
#if debug
		PrintToChatAll("restoring stopped");
#endif
		KillTimer(g_hRestoreTimer[client]);
		g_hRestoreTimer[client] = INVALID_HANDLE;
	}
}

EF_KillFixGlitchTimer(client)
{
	if (g_hFixGlitchTimer[client] != INVALID_HANDLE){

		KillTimer(g_hFixGlitchTimer[client]);
		g_hFixGlitchTimer[client] = INVALID_HANDLE;
	}
}

EF_ClearVars(client)
{
	EF_KillRestoreTimer(client);
	g_iHealthToRestore[client] = 0;
	g_iLastKnownHealth[client] = 0;
}

EF_ClearAllVars(client)
{
	EF_ClearVars(client);
	EF_KillFixGlitchTimer(client);
}

bool:IsSurvivor(client)
{
	return IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client);
}

bool:IsUnderWater(client)
{
	return GetEntProp(client, Prop_Send, "m_nWaterLevel") == 3;
}

IsIncapacitated(client)
{
	return GetEntProp(client, Prop_Send, "m_isIncapacitated");
}

bool:IsDrownPropNotEqual(client)
{
	return GetEntProp(client, Prop_Data, "m_idrowndmg") != GetEntProp(client, Prop_Data, "m_idrownrestored");
}

ForceEqualDrownProp(client)
{
	SetEntProp(client, Prop_Data, "m_idrownrestored", GetEntProp(client, Prop_Data, "m_idrowndmg"));
}

SetTempHealth(client, Float:health)
{
	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", health);
}
// Code by SilverShot aka Silvers (Healing Gnome plugin https://forums.alliedmods.net/showthread.php?p=1658852)
Float:GetTempHealth(client)
{
	new Float:fTempHealth = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	fTempHealth -= (GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime")) * g_fCvarDecayRate;
	return fTempHealth < 0.0 ? 0.0 : fTempHealth;
}

WarningsMsg(client, msg)
{
	decl String:STEAM_ID[32];
	GetClientAuthId(client, AuthId_Steam2, STEAM_ID, sizeof(STEAM_ID));

	switch (msg){

		case 1:
			PrintToChatAll("%N (%s) attempted to use a ladder speed glitch.", client, STEAM_ID);
		case 2:
			PrintToChatAll("%N (%s) is suspected of using a no fall damage bug.", client, STEAM_ID);
		case 3:
			PrintToChatAll("%N (%s) attempted to use a health boost glitch.", client, STEAM_ID);
	}
}

public OnConvarChange_DecayRate(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_fCvarDecayRate = GetConVarFloat(convar);
}

public OnConvarChange_WarnEnabled(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_bCvarWarnEnabled = GetConVarBool(convar);
}

public OnConvarChange_EngineFlags(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_iCvarEngineFlags = GetConVarInt(convar);
	EF_ToogleEvents(bool:(g_iCvarEngineFlags & (1 << HealthBoostGlitch)));
}

EF_ToogleEvents(bool:bHook)
{
	static bool:bIsHooked;

	if (!bIsHooked && bHook){

		for (new i = 1; i <= MAXPLAYERS; i++)
			EF_ClearAllVars(i);

		HookEvent("round_start", EF_ev_RoundStart, EventHookMode_PostNoCopy);
		HookEvent("pills_used", EF_ev_PillsUsed);
		HookEvent("player_hurt", EF_ev_PlayerHurt);
		HookEvent("heal_success", EF_ev_HealSuccess);
		HookEvent("revive_success", EF_ev_HealSuccess);
		HookEvent("player_incapacitated", EF_ev_HealSuccess);
	}
	else if (bIsHooked && !bHook){

		UnhookEvent("round_start", EF_ev_RoundStart, EventHookMode_PostNoCopy);
		UnhookEvent("pills_used", EF_ev_PillsUsed);
		UnhookEvent("player_hurt", EF_ev_PlayerHurt);
		UnhookEvent("heal_success", EF_ev_HealSuccess);
		UnhookEvent("revive_success", EF_ev_HealSuccess);
		UnhookEvent("player_incapacitated", EF_ev_HealSuccess);
	}
}

bool:IsValidClient(client)
{
	if (client <= 0 || client > MaxClients || !IsClientConnected(client)) return false;
	return IsClientInGame(client);
}

/*                                      +==========================================+
                                        |               Debug Stuff                |
                                        +==========================================+
*/
#if debug
static bool:g_bDebugEnabled[MAXPLAYERS+1], Handle:g_hDebugTimer[MAXPLAYERS+1];

public Action:CmdDebug(client, agrs)
{
	g_bDebugEnabled[client] = !g_bDebugEnabled[client];

	if (g_bDebugEnabled[client]){

		PrintHintText(client, "LOADING...");
		CreateTimer(1.0, EF_t_LoadDebug, client);
	}
	else {

		DisableDebug(client);
		PrintHintText(client, "Developers Stuff by raziEiL", client);
	}
	return Plugin_Handled;
}

public Action:EF_t_LoadDebug(Handle:timer, any:client)
{
	g_hDebugTimer[client] = CreateTimer(0.1, EF_t_DebugMe, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action:EF_t_DebugMe(Handle:timer, any:client)
{
	if (IsClientInGame(client)){

		new Float:speed = GetEntPropFloat(client, Prop_Data, "m_flGroundSpeed");
		new Float:fall = GetEntPropFloat(client, Prop_Send, "m_flFallVelocity");

		PrintCenterText(client, "%d/%d", GetEntProp(client, Prop_Data, "m_idrownrestored"), GetEntProp(client, Prop_Data, "m_idrowndmg"));

		if (GetEntityMoveType(client) == MOVETYPE_LADDER){

			if (speed > 130)
				PrintHintText(client, "Ground Speed %f WARNING!!!!", speed);
			else
				PrintHintText(client, "Ground Speed %f", speed);
		}
		else {

			if (fall != 0){
				PrintHintText(client, "Move type %d | Flags %d\n Fall Speed: %f\n Health %d(%f)", GetEntityMoveType(client), GetEntityFlags(client), fall, GetClientHealth(client), GetTempHealth(client));
				if (fall > 500)
					PrintCenterText(client, "FALL DMG!");
			}
			else
				PrintHintText(client, "Move type %d | Flags %d\n Ground Speed %f\n Health %d(%f)", GetEntityMoveType(client), GetEntityFlags(client), speed, GetClientHealth(client), GetTempHealth(client));
		}
	}
	else
		DisableDebug(client);
}

DisableDebug(client)
{
	if (g_hDebugTimer[client] != INVALID_HANDLE){

		KillTimer(g_hDebugTimer[client]);
		g_hDebugTimer[client] = INVALID_HANDLE;
	}
}
#endif
