#include <sourcemod>
#include <sdktools>

#define SI_SMOKER               1
#define SI_BOOMER               2
#define SI_HUNTER               3
#define SI_SPITTER              4
#define SI_JOCKEY               5
#define SI_CHARGER              6
#define SI_WITCH                7
#define SI_TANK                 8
#define SI_NOTINFECTED          9

#define TEAM_SPECTATORS         1
#define TEAM_SURVIVORS          2
#define TEAM_INFECTED           3

#define SH_INFECTED		17

const 	Float:	SPECHUD_UPDATEINTERVAL 					= 0.5;

enum SIClasses 
{
	SMOKER=1,
	BOOMER,
	HUNTER,
	SPITTER,
	JOCKEY,
	CHARGER,
	WITCH,
	TANK,
	NOTINFECTED
}

static const String:SINames[SIClasses][] =
{ "Unknown", "Smoker", "Boomer", "Hunter", "Spitter", "Jockey", "Charger", "Witch", "Tank", "Unknown" } ;

new SH_SurvivorIndex[NUM_OF_SURVIVORS];
new SH_InfectedIndex[SH_INFECTED];

new 	Handle:	g_hSH_SpecHUD;
new 	bool:	g_bSH_SpecHUD_ShowPanel[MAXPLAYERS+1] 	= false;
new 	bool:	g_bSH_SpecHUD_ShowHint[MAXPLAYERS+1] 	= true;

SH_OnModuleStart() {
	RegConsoleCmd("spechud", SH_SpecHUD_Command, "Toggles Confogl\'s Spectator HUD");
	CreateTimer(SPECHUD_UPDATEINTERVAL, SH_SpecHUD_Timer, INVALID_HANDLE, TIMER_REPEAT);
}

// For other modules to use
bool:IsClientUsingSpecHud(client) {
	return g_bSH_SpecHUD_ShowPanel[client];
}

public Action:SH_SpecHUD_Timer(Handle:timer) {
	if (!IsPluginEnabled()) return Plugin_Stop;
	
	SH_BuildClientIndex();
	SH_SpecHUD_Draw();
	SH_SpecHUD_Update();
	
	return Plugin_Continue;
}

public Action:SH_SpecHUD_Command(client,args) {
	// if true set to false, if false set to true
	g_bSH_SpecHUD_ShowPanel[client] = !g_bSH_SpecHUD_ShowPanel[client];

	if(g_bSH_SpecHUD_ShowPanel[client]) {
		ReplyToCommand(client,"[Confogl] Spectator HUD is now enabled.");
	} else {
		ReplyToCommand(client,"[Confogl] Spectator HUD is now disabled.");
	}
}

// Function to check if the player is incapped or not
SH_IsPlayerIncapped(client) {
	if(GetEntProp(client, Prop_Send, "m_isIncapacitated") == 0 || GetEntProp(client, Prop_Send, "m_isHangingFromLedge") == 0 || GetEntProp(client, Prop_Send, "m_isFallingFromLedge") == 0) {
		return false;
	} else {
		return true;
	}
}

// Reset spectator HUD enable/disable settings on disconnect
SH_OnClientDisconnect(client) {
	g_bSH_SpecHUD_ShowPanel[client] = false;
	g_bSH_SpecHUD_ShowHint[client] = true;
}

// Create Internal Index
SH_BuildClientIndex() {
	new isurvivors;
	new iinfected;
	decl team;
	for (new client = 1; client <= MaxClients; client++) {	
		if (!IsClientInGame(client)) continue;
		
		team = GetClientTeam(client);
		switch(team)
		{
			case TEAM_SURVIVORS:
			{
				SH_SurvivorIndex[isurvivors++] = client;
			}
			case TEAM_INFECTED:
			{
				SH_InfectedIndex[iinfected++] = client;
			}
			default:
			{			}
		}
	}
	if(isurvivors < NUM_OF_SURVIVORS)
		SH_SurvivorIndex[isurvivors] = 0;
	if(iinfected < SH_INFECTED)
		SH_InfectedIndex[iinfected] = 0;
}

SH_SpecHUD_Update() {
	for(new client = 1;client < MaxClients+1;client++) {
		if(!IsClientInGame(client) || GetClientTeam(client) != TEAM_SPECTATORS || !g_bSH_SpecHUD_ShowPanel[client] || IsFakeClient(client)){continue;}
		SendPanelToClient(g_hSH_SpecHUD, client, SH_SpecHUD_MenuHandler, 3);
		
		if(g_bSH_SpecHUD_ShowHint[client]) {
			g_bSH_SpecHUD_ShowHint[client] = false;
			CPrintToChatAll("{blue}[{default}Confogl{blue}] {default}Say \"{olive}/spechud{default}\" to toggle the {blue}Spectator HUD");
		}
	}
}

SH_SpecHUD_Draw() {
	if(g_hSH_SpecHUD != INVALID_HANDLE) {
		CloseHandle(g_hSH_SpecHUD);
	}
	
	g_hSH_SpecHUD = CreatePanel();
	
	decl String:sTempString[512], String:sWeaponString[64], String:sNameString[MAX_NAME_LENGTH+1];
	new SIclass, Float:SIspawntimer, survivorhealth, survivordown;

	DrawPanelText(g_hSH_SpecHUD, "Confogl's Spectator HUD");
	DrawPanelText(g_hSH_SpecHUD, "-------------------------------------");
	
	// Health Bonus
	Format(sTempString, sizeof(sTempString), "Health Bonus: %d", SM_CalculateScore());
	DrawPanelText(g_hSH_SpecHUD, sTempString);
	
	// Mob Spawn timer
	Format(sTempString, sizeof(sTempString), "Mob Timer: %ds", 
		L4D2_CTimerHasStarted(L4D2CT_MobSpawnTimer) ? RoundFloat(L4D2_CTimerGetRemainingTime(L4D2CT_MobSpawnTimer)) : 0);
	DrawPanelText(g_hSH_SpecHUD, sTempString);
	
	
	//start with survivor team first
	//this part probably needs rewriting..
	for(new survivors = 0; survivors < NUM_OF_SURVIVORS; survivors++) {
		//just incase
		if(SH_SurvivorIndex[survivors] == 0) break;
		
		GetClientName(SH_SurvivorIndex[survivors],sNameString,sizeof(sNameString));
		if(sNameString[0] == '[')
		{
			// Horrid workaround for people whose names break the Radio menus.
			// Consider replacing me with sNameString[0]=' ';
			sNameString[sizeof(sNameString)-2]=0;
			decl String:buf[MAX_NAME_LENGTH];
			strcopy(buf, sizeof(buf), sNameString);
			strcopy(sNameString[1], sizeof(sNameString)-1, buf);
			sNameString[0]=' ';			
		}
		if(strlen(sNameString) > 25)
		{
				sNameString[22] = '.';
				sNameString[23] = '.';
				sNameString[24] = '.';
				sNameString[25] = 0;
		}

		if(IsPlayerAlive(SH_SurvivorIndex[survivors])) {
			GetClientWeapon(SH_SurvivorIndex[survivors],sWeaponString,sizeof(sWeaponString));
			if(StrContains(sWeaponString, "weapon", false) != -1)
				ReplaceString(sWeaponString, 64, "weapon_", "", false);
			if(StrContains(sWeaponString, "_spawn", false) != -1)
				ReplaceString(sWeaponString, 64, "_spawn", "", false);
		} else {
			Format(sTempString, sizeof(sTempString), "%s: Dead", sNameString);
			DrawPanelText(g_hSH_SpecHUD, sTempString);
			continue;
		}

		survivorhealth = GetSurvivorPermanentHealth(SH_SurvivorIndex[survivors]) + GetSurvivorTempHealth(SH_SurvivorIndex[survivors]);
		survivordown = GetSurvivorIncapCount(SH_SurvivorIndex[survivors]);

		if(SH_IsPlayerIncapped(SH_SurvivorIndex[survivors])) {
			Format(sTempString, sizeof(sTempString), "%s: %s [Down]", sNameString, sWeaponString);
		} else if(survivordown == 0) {
			Format(sTempString, sizeof(sTempString), "%s: %s [%d]", sNameString, sWeaponString, survivorhealth);
		} else {
			Format(sTempString, sizeof(sTempString), "%s: %s [%d (%d Down)]", sNameString, sWeaponString, survivorhealth, survivordown);
		}
		DrawPanelText(g_hSH_SpecHUD, sTempString);
	}

	// blank line
	DrawPanelText(g_hSH_SpecHUD, " ");

        //infected team
        for(new infected = 0; infected < SH_INFECTED; infected++) {
                //this is required
                if(SH_InfectedIndex[infected] == 0) break;

		if(!IsFakeClient(SH_InfectedIndex[infected])) {
			GetClientName(SH_InfectedIndex[infected],sNameString,sizeof(sNameString));
			if(sNameString[0] == '[')
			{
				// Horrid workaround for people whose names break the Radio menus.
				// Consider replacing me with sNameString[0]=' ';
				sNameString[sizeof(sNameString)-2]=0;
				decl String:buf[MAX_NAME_LENGTH];
				strcopy(buf, sizeof(buf), sNameString);
				strcopy(sNameString[1], sizeof(sNameString)-1, buf);
				sNameString[0]=' ';			
			}
			if(strlen(sNameString) > 25) {
					sNameString[22] = '.';
					sNameString[23] = '.';
					sNameString[24] = '.';
					sNameString[25] = 0;
			}
		} else {
			Format(sNameString, sizeof(sNameString), "AI");
		}

		if(!IsPlayerAlive(SH_InfectedIndex[infected])) {
			SIspawntimer = L4D_GetPlayerSpawnTime(SH_InfectedIndex[infected]);
			if(SIspawntimer < 0)
				Format(sTempString, sizeof(sTempString), "%s: Dead", sNameString);
			else
				Format(sTempString, sizeof(sTempString), "%s: Dead(%d)", sNameString, RoundToFloor(SIspawntimer));
		} else if(GetEntProp(SH_InfectedIndex[infected], Prop_Send, "m_isGhost")) {
			SIclass = GetEntProp(SH_InfectedIndex[infected], Prop_Send, "m_zombieClass");
			Format(sTempString, sizeof(sTempString), "%s: Spawning(%s)", sNameString, SINames[SIclass]);
		} else {
			SIclass = GetEntProp(SH_InfectedIndex[infected], Prop_Send, "m_zombieClass");
			if(GetEntityFlags(SH_InfectedIndex[infected]) & FL_ONFIRE) {
				Format(sTempString, sizeof(sTempString), "%s: %s[%d (OnFire)]", sNameString, SINames[SIclass], GetClientHealth(SH_InfectedIndex[infected]));
			} else if(SIclass == SI_TANK) {
				Format(sTempString, sizeof(sTempString), "%s: %s[%d (%d%%)]", sNameString, SINames[SIclass], GetClientHealth(SH_InfectedIndex[infected]), 100 - GetEntProp(SH_InfectedIndex[infected], Prop_Send, "m_frustration"));
			} else {
				Format(sTempString, sizeof(sTempString), "%s: %s[%d]", sNameString, SINames[SIclass], GetClientHealth(SH_InfectedIndex[infected]));
			}
		}

                DrawPanelText(g_hSH_SpecHUD, sTempString);
        }
}

public SH_SpecHUD_MenuHandler(Handle:menu, MenuAction:action, param1, param2) {
}
