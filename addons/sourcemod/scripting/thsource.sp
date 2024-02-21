#include <sourcemod>
#include <sdktools>
#include <l4d2_direct>
#include <l4d2_weapon_stocks>
#include <readyup>
#include <pause>
#include <multicolors>

#pragma semicolon 1

#define SPECHUD_DRAW_INTERVAL   0.5

#define ZOMBIECLASS_NAME(%0) (L4D2SI_Names[(%0)])

char Tank_UpTime[20];
int UpTime;
int punch_connected;
int rock_connected;
int prop_connected;
int damage_connected;

enum L4D2Gamemode
{
	L4D2Gamemode_None,
	L4D2Gamemode_Versus,
	L4D2Gamemode_Scavenge
};

enum L4D2SI 
{
	ZC_None,
	ZC_Smoker,
	ZC_Boomer,
	ZC_Hunter,
	ZC_Spitter,
	ZC_Jockey,
	ZC_Charger,
	ZC_Witch,
	ZC_Tank
};

static const String:L4D2SI_Names[][] = 
{
	"None",
	"Smoker",
	"Boomer",
	"Hunter",
	"Spitter",
	"Jockey",
	"Charger",
	"Witch",
	"Tank"
};

new Handle:survivor_limit;
new Handle:z_max_player_zombies;

new bool:bSpecHudActive[MAXPLAYERS + 1];
new bool:bSpecHudHintShown[MAXPLAYERS + 1];
new bool:bTankHudActive[MAXPLAYERS + 1];
new bool:bTankHudHintShown[MAXPLAYERS + 1];

public Plugin:myinfo = 
{
	name = "Hyper-V HUD Manager [Public Version]",
	author = "Visor, Foxhound27",
	description = "Provides different HUDs for spectators",
	version = "3.1",
	url = "https://github.com/Attano/smplugins"
};

public OnPluginStart() 
{
	survivor_limit = FindConVar("survivor_limit");
	z_max_player_zombies = FindConVar("z_max_player_zombies");

	RegConsoleCmd("sm_spechud", ToggleSpecHudCmd);
	RegConsoleCmd("sm_tankhud", ToggleTankHudCmd);
	HookEvent("tank_spawn", tank_spawn);//to calculate tank spawn time
	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Pre); //to get punch, rock, prop, totaldamage

	CreateTimer(SPECHUD_DRAW_INTERVAL, HudDrawTimer, _, TIMER_REPEAT);
}

public Action tank_spawn(Handle event, const char[] name, bool dontBroadcast) {
    UpTime = GetTime();
    punch_connected = 0;
    rock_connected = 0;
    prop_connected = 0;
    damage_connected = 0;
}

public Action Event_PlayerHurt(Handle event, const char[] name, bool dontBroadcast) {
    int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
    int victim = GetClientOfUserId(GetEventInt(event, "userid"));

    if (!attacker) {
        return Plugin_Continue;
    }

    if (GetEventInt(event, "dmg_health") < 1) {
        return Plugin_Continue;
    }
    if (victim == attacker) {
        return Plugin_Continue;
    }

    char weapon[16];
    GetEventString(event, "weapon", weapon, sizeof(weapon));
    if (GetEntProp(attacker, Prop_Send, "m_zombieClass") == 8 && GetClientTeam(victim) == 2) {
        damage_connected = damage_connected + GetEventInt(event, "dmg_health");

        if (StrEqual(weapon, "tank_claw")) {
            punch_connected = punch_connected + 1;
        } else if (StrEqual(weapon, "tank_rock")) {
                rock_connected = rock_connected + 1;
            } else {
                prop_connected = prop_connected + 1;
        }
    }
    return Plugin_Continue;
}

public OnClientAuthorized(client, const String:auth[])
{
	bSpecHudActive[client] = false;
	bSpecHudHintShown[client] = false;
	bTankHudActive[client] = true;
	bTankHudHintShown[client] = false;
}

public Action:ToggleSpecHudCmd(client, args) 
{
	bSpecHudActive[client] = !bSpecHudActive[client];
	CPrintToChat(client, "<{olive}HUD{default}> El Espectador HUD esta %s.", (bSpecHudActive[client] ? "{blue}activado{default}" : "{red}desactivado{default}"));
}

public Action:ToggleTankHudCmd(client, args) 
{
	bTankHudActive[client] = !bTankHudActive[client];
	CPrintToChat(client, "<{olive}HUD{default}> El Tank HUD esta %s.", (bTankHudActive[client] ? "{blue}activado{default}" : "{red}desactivado{default}"));
}

public Action:HudDrawTimer(Handle:hTimer) 
{
	if (IsInReady() || IsInPause())
		return Plugin_Handled;

	new bool:bSpecsOnServer = false;
	for (new i = 1; i <= MaxClients; i++) 
	{
		if (IsSpectator(i))
		{
			bSpecsOnServer = true;
			break;
		}
	}

	if (bSpecsOnServer) // Only bother if someone's watching us
	{
		new Handle:specHud = CreatePanel();

		FillHeaderInfo(specHud);
		FillSurvivorInfo(specHud);
		FillInfectedInfo(specHud);
		FillTankInfo(specHud);
		FillGameInfo(specHud);

		for (new i = 1; i <= MaxClients; i++) 
		{
			if (!bSpecHudActive[i] || !IsSpectator(i) || IsFakeClient(i))
				continue;

			SendPanelToClient(specHud, i, DummySpecHudHandler, 3);
			if (!bSpecHudHintShown[i])
			{
				bSpecHudHintShown[i] = true;
				CPrintToChat(i, "<{olive}HUD{default}> Escriba {green}!spechud{default} en el chat para alternar el {blue}Espectador HUD{default}.");
			}
		}

		CloseHandle(specHud);
	}
	
	new Handle:tankHud = CreatePanel();
	if (!FillTankInfo(tankHud, true)) // No tank -- no HUD
		return Plugin_Handled;

	for (new i = 1; i <= MaxClients; i++) 
	{
		if (!bTankHudActive[i] || !IsClientInGame(i) || IsFakeClient(i) || IsSurvivor(i) || (bSpecHudActive[i] && IsSpectator(i)))
			continue;

		SendPanelToClient(tankHud, i, DummyTankHudHandler, 3);
		if (!bTankHudHintShown[i])
		{
			bTankHudHintShown[i] = true;
			CPrintToChat(i, "<{olive}HUD{default}> Escriba {green}!tankhud{default} en el chat para alternar el {red}Tank HUD{default}.");
		}
	}

	CloseHandle(tankHud);
	return Plugin_Continue;
}

public DummySpecHudHandler(Handle:hMenu, MenuAction:action, param1, param2) {}
public DummyTankHudHandler(Handle:hMenu, MenuAction:action, param1, param2) {}

FillHeaderInfo(Handle:hSpecHud) 
{
	DrawPanelText(hSpecHud, "Espectador HUD");

	decl String:buffer[512];
	Format(buffer, sizeof(buffer), "Slots: %i/%i | Tickrate: %i", GetRealClientCount(), GetConVarInt(FindConVar("sv_maxplayers")), RoundToNearest(1.0 / GetTickInterval()));
	DrawPanelText(hSpecHud, buffer);
}

GetMeleePrefix(client, String:prefix[], length) 
{
	new secondary = GetPlayerWeaponSlot(client, _:L4D2WeaponSlot_Secondary);
	new WeaponId:secondaryWep = IdentifyWeapon(secondary);

	decl String:buf[4];
	switch (secondaryWep)
	{
		case WEPID_NONE: buf = "N";
		case WEPID_PISTOL: buf = (GetEntProp(secondary, Prop_Send, "m_isDualWielding") ? "DP" : "P");
		case WEPID_MELEE: buf = "M";
		case WEPID_PISTOL_MAGNUM: buf = "DE";
		default: buf = "?";
	}

	strcopy(prefix, length, buf);
}

FillSurvivorInfo(Handle:hSpecHud) 
{
	decl String:info[512];
	decl String:buffer[64];
	decl String:name[MAX_NAME_LENGTH];

	DrawPanelText(hSpecHud, " ");
	DrawPanelText(hSpecHud, "->1. Supervivientes");

	new survivorCount;
	for (new client = 1; client <= MaxClients && survivorCount < GetConVarInt(survivor_limit); client++) 
	{
		if (!IsSurvivor(client))
			continue;

		GetClientFixedName(client, name, sizeof(name));
		if (!IsPlayerAlive(client))
		{
			Format(info, sizeof(info), "%s: Muerto", name);
		}
		else
		{
			new WeaponId:primaryWep = IdentifyWeapon(GetPlayerWeaponSlot(client, _:L4D2WeaponSlot_Primary));
			GetLongWeaponName(primaryWep, info, sizeof(info));
			GetMeleePrefix(client, buffer, sizeof(buffer)); 
			Format(info, sizeof(info), "%s/%s", info, buffer);

			if (IsSurvivorHanging(client))
			{
				Format(info, sizeof(info), "%s: %iHP <Colgado> [%s]", name, GetSurvivorHealth(client), info);
			}
			else if (IsIncapacitated(client))
			{
				Format(info, sizeof(info), "%s: %iHP <Incap(#%i)> [%s]", name, GetSurvivorHealth(client), (GetSurvivorIncapCount(client) + 1), info);
			}
			else
			{
				new health = GetSurvivorHealth(client) + GetSurvivorTemporaryHealth(client);
				new incapCount = GetSurvivorIncapCount(client);
				if (incapCount == 0)
				{
					Format(info, sizeof(info), "%s: %iHP [%s]", name, health, info);
				}
				else
				{
					Format(buffer, sizeof(buffer), "%i incapacitado%s", incapCount, (incapCount > 1 ? "s" : ""));
					Format(info, sizeof(info), "%s: %iHP (%s) [%s]", name, health, buffer, info);
				}
			}
		}

		survivorCount++;
		DrawPanelText(hSpecHud, info);
	}
}

FillInfectedInfo(Handle:hSpecHud) 
{
	DrawPanelText(hSpecHud, " ");
	DrawPanelText(hSpecHud, "->2. Infectados");

	decl String:info[512];
	decl String:buffer[32];
	decl String:name[MAX_NAME_LENGTH];

	new infectedCount;
	for (new client = 1; client <= MaxClients && infectedCount < GetConVarInt(z_max_player_zombies); client++) 
	{
		if (!IsInfected(client))
			continue;

		GetClientFixedName(client, name, sizeof(name));
		if (!IsPlayerAlive(client)) 
		{
			new CountdownTimer:spawnTimer = L4D2Direct_GetSpawnTimer(client);
			new Float:timeLeft = -1.0;
			if (spawnTimer != CTimer_Null)
			{
				timeLeft = CTimer_GetRemainingTime(spawnTimer);
			}

			if (timeLeft < 0.0)
			{
				Format(info, sizeof(info), "%s: Muerto", name);
			}
			else
			{
				Format(buffer, sizeof(buffer), "%is", RoundToNearest(timeLeft));
				Format(info, sizeof(info), "%s: Muerto (%s)", name, (RoundToNearest(timeLeft) ? buffer : "Spawning..."));
			}
		}
		else 
		{
			new L4D2SI:zClass = GetInfectedClass(client);
			if (zClass == ZC_Tank)
				continue;

			if (IsInfectedGhost(client))
			{
				// TO-DO: Handle a case of respawning chipped SI, show the ghost's health
				Format(info, sizeof(info), "%s: %s (Fantasma)", name, ZOMBIECLASS_NAME(zClass));
			}
			else if (GetEntityFlags(client) & FL_ONFIRE)
			{
				Format(info, sizeof(info), "%s: %s (%iHP) [Quemandose]", name, ZOMBIECLASS_NAME(zClass), GetClientHealth(client));
			}
			else
			{
				Format(info, sizeof(info), "%s: %s (%iHP)", name, ZOMBIECLASS_NAME(zClass), GetClientHealth(client));
			}
		}

		infectedCount++;
		DrawPanelText(hSpecHud, info);
	}
	
	if (!infectedCount)
	{
		DrawPanelText(hSpecHud, "No hay SI en este momento.");
	}
}

stock void UpdateTankUpTime() {
    char str_uptime_temp[8];
    int Current_UpTime = GetTime() - UpTime;
    int Days = RoundToFloor(Current_UpTime / 86400.0);
    Current_UpTime -= Days * 86400;
    Tank_UpTime = "";
    int Hours = RoundToFloor(Current_UpTime / 3600.0);
    Current_UpTime -= Hours * 3600;
    FormatTime(str_uptime_temp, sizeof(str_uptime_temp), "%M:%S", Current_UpTime);
    StrCat(view_as < char > (Tank_UpTime), sizeof(Tank_UpTime), str_uptime_temp);
}

bool: FillTankInfo(Handle: hSpecHud, bool: bTankHUD = false) {
    new tank = FindTank();
    if (tank == -1)
        return false;

    decl String: info[512];
    decl String: name[MAX_NAME_LENGTH];

    if (bTankHUD) {
        GetConVarString(FindConVar("l4d_ready_cfg_name"), info, sizeof(info));
        Format(info, sizeof(info), "%s :: Tank HUD", info);
        DrawPanelText(hSpecHud, info);
        DrawPanelText(hSpecHud, "▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬");
        Format(info, sizeof(info), "Ataques: %i | Rocas: %i | Objetos: %i", punch_connected, rock_connected, prop_connected);
        DrawPanelText(hSpecHud, info);
        Format(info, sizeof(info), "           Daño Total: %i", damage_connected);
        DrawPanelText(hSpecHud, info);
        DrawPanelText(hSpecHud, "▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬");
    } else {
        DrawPanelText(hSpecHud, " ");
        DrawPanelText(hSpecHud, "->3. Tank");
    }

    // Draw owner & pass counter
    new passCount = L4D2Direct_GetTankPassedCount();
    switch (passCount) {
        case 0: Format(info, sizeof(info), "bot");
        case 1: Format(info, sizeof(info), "%iº", passCount);
        case 2: Format(info, sizeof(info), "%iº", passCount);
        case 3: Format(info, sizeof(info), "%iº", passCount);
        default: Format(info, sizeof(info), "%iº", passCount);
    }

    if (!IsFakeClient(tank)) {
        GetClientFixedName(tank, name, sizeof(name));
        Format(info, sizeof(info), "Control : %s (%s)", name, info);
    } else {
        Format(info, sizeof(info), "Control : AI (%s)", info);
    }
    DrawPanelText(hSpecHud, info);

    // Draw health
    new health = GetClientHealth(tank);
    if (health <= 0 || IsIncapacitated(tank) || !IsPlayerAlive(tank)) {
        info = "Salud  : Muerto";
    } else {
        new healthPercent = RoundFloat((100.0 / (GetConVarFloat(FindConVar("z_tank_health")) * 1.5)) * health);
        Format(info, sizeof(info), "Salud  : %i / %i%%", health, ((healthPercent < 1) ? 1 : healthPercent));
    }
    DrawPanelText(hSpecHud, info);

    // Draw frustration
    if (!IsFakeClient(tank)) {
        Format(info, sizeof(info), "Frustr.  : %d%%", GetTankFrustration(tank));
    } else {
        info = "Frustr.  : AI";
    }
    DrawPanelText(hSpecHud, info);

    //Spawn Time

    UpdateTankUpTime();
    Format(info, sizeof(info), "Spawn: (%s)", Tank_UpTime);

    DrawPanelText(hSpecHud, info);

    // Draw fire status
    if (GetEntityFlags(tank) & FL_ONFIRE) {
        new timeleft = RoundToCeil(health / 80.0);
        Format(info, sizeof(info), "Quemandose : %is", timeleft);
        DrawPanelText(hSpecHud, info);
    }

    return true;
}

FillGameInfo(Handle:hSpecHud)
{
	// Turns out too much info actually CAN be bad, funny ikr
	new tank = FindTank();
	if (tank != -1)
		return;

	DrawPanelText(hSpecHud, " ");
	DrawPanelText(hSpecHud, "->3. Servidor");

	decl String:info[512];
	decl String:buffer[512];

	GetConVarString(FindConVar("l4d_ready_cfg_name"), info, sizeof(info));

	if (GetCurrentGameMode() == L4D2Gamemode_Versus)
	{
		Format(info, sizeof(info), "%s (%s ronda)", info, (InSecondHalfOfRound() ? "2º" : "1º"));
		DrawPanelText(hSpecHud, info);

		Format(info, sizeof(info), "Horda entrante: %is", CTimer_HasStarted(L4D2Direct_GetMobSpawnTimer()) ? RoundFloat(CTimer_GetRemainingTime(L4D2Direct_GetMobSpawnTimer())) : 0);
		DrawPanelText(hSpecHud, info);

		Format(info, sizeof(info), "Progreso del mapa: %i%%", RoundToNearest(GetHighestSurvivorFlow() * 100.0));
		DrawPanelText(hSpecHud, info);

		if (RoundHasFlowTank())
		{
			Format(info, sizeof(info), "Tank: %i%%", RoundToNearest(GetTankFlow() * 100.0));
			DrawPanelText(hSpecHud, info);
		}

		if (RoundHasFlowWitch())
		{
			Format(info, sizeof(info), "Witch: %i%%", RoundToNearest(GetWitchFlow() * 100.0));
			DrawPanelText(hSpecHud, info);
		}
	}
	else if (GetCurrentGameMode() == L4D2Gamemode_Scavenge)
	{
		DrawPanelText(hSpecHud, info);

		new round = GetScavengeRoundNumber();
		switch (round)
		{
			case 0: Format(buffer, sizeof(buffer), "N/A");
			case 1: Format(buffer, sizeof(buffer), "%iº", round);
			case 2: Format(buffer, sizeof(buffer), "%iº", round);
			case 3: Format(buffer, sizeof(buffer), "%iº", round);
			default: Format(buffer, sizeof(buffer), "%iº", round);
		}

		Format(info, sizeof(info), "Mitad: %s", (InSecondHalfOfRound() ? "2º" : "1º"));
		DrawPanelText(hSpecHud, info);

		Format(info, sizeof(info), "Ronda: %s", buffer);
		DrawPanelText(hSpecHud, info);
	}
}

/* Stocks */

GetClientFixedName(client, String:name[], length) 
{
	GetClientName(client, name, length);

	if (name[0] == '[') 
	{
		decl String:temp[MAX_NAME_LENGTH];
		strcopy(temp, sizeof(temp), name);
		temp[sizeof(temp)-2] = 0;
		strcopy(name[1], length-1, temp);
		name[0] = ' ';
	}

	if (strlen(name) > 25) 
	{
		name[22] = name[23] = name[24] = '.';
		name[25] = 0;
	}
}

GetRealClientCount() 
{
	new clients = 0;
	for (new i = 1; i <= MaxClients; i++) 
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i)) clients++;
	}
	return clients;
}

InSecondHalfOfRound()
{
	return GameRules_GetProp("m_bInSecondHalfOfRound");
}

GetScavengeRoundNumber()
{
	return GameRules_GetProp("m_nRoundNumber");
}

Float:GetClientFlow(client)
{
	return (L4D2Direct_GetFlowDistance(client) / L4D2Direct_GetMapMaxFlowDistance());
}

Float:GetHighestSurvivorFlow()
{
	new Float:flow;
	new Float:maxflow = 0.0;
	for (new i = 1; i <= MaxClients; i++) 
	{
		if (IsSurvivor(i))
		{
			flow = GetClientFlow(i);
			if (flow > maxflow)
			{
				maxflow = flow;
			}
		}
	}
	return maxflow;
}

bool:RoundHasFlowTank()
{
	return L4D2Direct_GetVSTankToSpawnThisRound(InSecondHalfOfRound());
}

bool:RoundHasFlowWitch()
{
	return L4D2Direct_GetVSWitchToSpawnThisRound(InSecondHalfOfRound());
}

Float:GetTankFlow() 
{
	return L4D2Direct_GetVSTankFlowPercent(0) -
		(Float:GetConVarInt(FindConVar("versus_boss_buffer")) / L4D2Direct_GetMapMaxFlowDistance());
}

Float:GetWitchFlow() 
{
	return L4D2Direct_GetVSWitchFlowPercent(0) -
		(Float:GetConVarInt(FindConVar("versus_boss_buffer")) / L4D2Direct_GetMapMaxFlowDistance());
}

bool:IsSpectator(client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 1;
}

bool:IsSurvivor(client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2;
}

bool:IsInfected(client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3;
}

bool:IsInfectedGhost(client) 
{
	return bool:GetEntProp(client, Prop_Send, "m_isGhost");
}

L4D2SI:GetInfectedClass(client)
{
	return IsInfected(client) ? (L4D2SI:GetEntProp(client, Prop_Send, "m_zombieClass")) : ZC_None;
}

FindTank() 
{
	for (new i = 1; i <= MaxClients; i++) 
	{
		if (IsInfected(i) && GetInfectedClass(i) == ZC_Tank && IsPlayerAlive(i))
			return i;
	}

	return -1;
}

GetTankFrustration(tank)
{
	return (100 - GetEntProp(tank, Prop_Send, "m_frustration"));
}

bool:IsIncapacitated(client)
{
	return bool:GetEntProp(client, Prop_Send, "m_isIncapacitated");
}

bool:IsSurvivorHanging(client)
{
	return bool:(GetEntProp(client, Prop_Send, "m_isHangingFromLedge") | GetEntProp(client, Prop_Send, "m_isFallingFromLedge"));
}

GetSurvivorIncapCount(client)
{
	return GetEntProp(client, Prop_Send, "m_currentReviveCount");
}

GetSurvivorTemporaryHealth(client)
{
	new temphp = RoundToCeil(GetEntPropFloat(client, Prop_Send, "m_healthBuffer") - ((GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime")) * GetConVarFloat(FindConVar("pain_pills_decay_rate")))) - 1;
	return (temphp > 0 ? temphp : 0);
}

GetSurvivorHealth(client)
{
	return GetEntProp(client, Prop_Send, "m_iHealth");
}

L4D2Gamemode:GetCurrentGameMode()
{
	static String:sGameMode[32];
	if (sGameMode[0] == EOS)
	{
		GetConVarString(FindConVar("mp_gamemode"), sGameMode, sizeof(sGameMode));
	}
	if (StrContains(sGameMode, "scavenge") > -1)
	{
		return L4D2Gamemode_Scavenge;
	}
	if (StrContains(sGameMode, "versus") > -1
		|| StrEqual(sGameMode, "mutation12")) // realism versus
	{
		return L4D2Gamemode_Versus;
	}
	else
	{
		return L4D2Gamemode_None; // Unsupported
	}
}