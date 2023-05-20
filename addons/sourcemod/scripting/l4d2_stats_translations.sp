#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#define L4D2UTIL_STOCKS_ONLY 1
#include <colors>
#include <l4d2util>

#define TEAM_SPECTATOR 1
#define TEAM_SURVIVOR  2
#define TEAM_INFECTED  3

#define BOOMER_STAGGER_TIME 4.0    // Amount of time after a boomer has been meleed that we consider the meleer the person who
// shut down the boomer, this is just a guess value..

// Player temp stats
int
	g_iDamageDealt[MAXPLAYERS + 1][MAXPLAYERS + 1],    // Victim - Attacker
	g_iShotsDealt[MAXPLAYERS + 1][MAXPLAYERS + 1];     // Victim - Attacker, count # of shots (not pellets)
//

int
	g_iBoomerClient               = 0,    // Last player to be boomer (or current boomer)
	g_iBoomerKiller               = 0,    // Client who shot the boomer
	g_iBoomerShover               = 0,    // Client who shoved the boomer
	g_iLastHealth[MAXPLAYERS + 1] = { 0, ... };

float
	BoomerKillTime = 0.0;

bool
	g_bHasRoundEnded              = false,
	g_bHasBoomLanded              = false,
	g_bIsPouncing[MAXPLAYERS + 1] = { false, ... },
	g_bShotCounted[MAXPLAYERS + 1][MAXPLAYERS + 1];    // Victim - Attacker, used by playerhurt and weaponfired

Handle
	g_hBoomerShoveTimer = null,
	g_hBoomerKillTimer  = null;

char
	Boomer[32];    // Name of Boomer
public Plugin myinfo =
{
	name        = "L4D2 Realtime Stats",
	author      = "Griffin, Philogl, Sir, A1m`",
	description = "Display Skeets/Etc to Chat to clients",
	version     = "1.2.2",
	url         = "https://github.com/SirPlease/L4D2-Competitive-Rework"

}

public void OnPluginStart()
{
	LoadTranslations("l4d2_stats_translations.phrases");
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);

	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_spawn", Event_PlayerSpawn);

	HookEvent("ability_use", Event_AbilityUse);
	HookEvent("lunge_pounce", Event_LungePounce);
	HookEvent("weapon_fire", Event_WeaponFire);
	HookEvent("player_shoved", Event_PlayerShoved);
	HookEvent("player_now_it", Event_PlayerBoomed);

	HookEvent("triggered_car_alarm", Event_AlarmCar);
}

public void Event_PlayerSpawn(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	int client = GetClientOfUserId(hEvent.GetInt("userid"));
	if (client == 0 || !IsClientInGame(client))
	{
		return;
	}

	if (GetClientTeam(client) == TEAM_INFECTED)
	{
		int zombieclass = GetInfectedClass(client);
		if (zombieclass == L4D2Infected_Tank)
		{
			return;
		}

		if (zombieclass == L4D2Infected_Boomer)
		{
			// Fresh boomer spawning (if g_iBoomerClient is set and an AI boomer spawns, it's a boomer going AI)
			if (!IsFakeClient(client) || !g_iBoomerClient)
			{
				g_bHasBoomLanded = false;
				g_iBoomerClient  = client;
				g_iBoomerShover  = 0;
				g_iBoomerKiller  = 0;
			}

			DestroyTimer(g_hBoomerShoveTimer);

			BoomerKillTime     = 0.0;
			g_hBoomerKillTimer = CreateTimer(0.1, Timer_KillBoomer, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		}

		g_iLastHealth[client] = GetClientHealth(client);
	}
}

public void Event_WeaponFire(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	int client = GetClientOfUserId(hEvent.GetInt("userid"));
	for (int i = 1; i <= MaxClients; i++)
	{
		// [Victim][Attacker]
		g_bShotCounted[i][client] = false;
	}
}

public void OnMapStart()
{
	g_bHasRoundEnded = false;

	ClearMapStats();
}

public void OnMapEnd()
{
	/*
	 * Sometimes the event 'round_start' is called before OnMapStart()
	 * and the timer handle is not reset, so it's better to do it here.
	 */
	g_hBoomerShoveTimer = null;    // TIMER_FLAG_NO_MAPCHANGE
	g_hBoomerKillTimer  = null;    // TIMER_FLAG_NO_MAPCHANGE

	g_bHasRoundEnded = true;
}

public void Event_RoundStart(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	g_bHasRoundEnded = false;

	DestroyTimer(g_hBoomerKillTimer);

	BoomerKillTime = 0.0;
}

public void Event_RoundEnd(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	if (g_bHasRoundEnded)
	{
		return;
	}

	g_bHasRoundEnded = true;

	for (int i = 1; i <= MaxClients; i++)
	{
		ClearDamage(i);
	}
}

// Pounce tracking, from skeet announce
public void Event_AbilityUse(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	if (g_bHasRoundEnded)
	{
		return;
	}

	int userid = hEvent.GetInt("userid");
	int client = GetClientOfUserId(userid);

	if (!IsClientInGame(client) || GetClientTeam(client) != TEAM_INFECTED)
	{
		return;
	}

	int zombieclass = GetInfectedClass(client);

	if (zombieclass == L4D2Infected_Hunter)
	{
		g_bIsPouncing[client] = true;
		CreateTimer(0.5, Timer_GroundedCheck, userid, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
}

public void Event_LungePounce(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	int attacker    = GetClientOfUserId(hEvent.GetInt("userid"));
	int zombieclass = GetInfectedClass(attacker);

	if (zombieclass == L4D2Infected_Hunter)
	{
		g_bIsPouncing[attacker] = false;
	}
}

public Action Timer_GroundedCheck(Handle hTimer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (client > 0 && !(GetEntityFlags(client) & FL_ONGROUND))
	{
		return Plugin_Continue;
	}

	g_bIsPouncing[client] = false;
	return Plugin_Stop;
}

public Action Timer_KillBoomer(Handle hTimer)
{
	BoomerKillTime += 0.1;
	return Plugin_Continue;
}

public void Event_PlayerHurt(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	if (g_bHasRoundEnded)
	{
		return;
	}

	int victim = GetClientOfUserId(hEvent.GetInt("userid"));
	if (victim == 0 || !IsClientInGame(victim))
	{
		return;
	}

	int attacker = GetClientOfUserId(hEvent.GetInt("attacker"));
	if (!attacker || !IsClientInGame(attacker))
	{
		return;
	}

	if (GetClientTeam(attacker) == TEAM_SURVIVOR && GetClientTeam(victim) == TEAM_INFECTED)
	{
		int zombieclass = GetInfectedClass(victim);
		if (zombieclass == L4D2Infected_Tank)
		{
			return;    // We don't care about tank damage
		}

		if (!g_bShotCounted[victim][attacker])
		{
			g_iShotsDealt[victim][attacker]++;
			g_bShotCounted[victim][attacker] = true;
		}

		int remaining_health = hEvent.GetInt("health");

		// Let player_death handle remainder damage (avoid overkill damage)
		if (remaining_health <= 0)
		{
			return;
		}

		// remainder health will be awarded as damage on kill
		g_iLastHealth[victim] = remaining_health;

		int damage = hEvent.GetInt("dmg_health");
		g_iDamageDealt[victim][attacker] += damage;

		/*switch(zombieclass) {
		    case L4D2Infected_Boomer: {
		        // Boomer Code Here
		    }
		    case L4D2Infected_Hunter: {
		        // Hunter Code Here
		    }
		    case L4D2Infected_Smoker: {
		        // Smoker Code Here
		    }
		    case L4D2Infected_Jockey: {
		        // Jockey Code Here
		    }
		    case L4D2Infected_Charger: {
		        // Charger Code Here
		    }
		    case L4D2Infected_Spitter: {
		        // Spitter Code Here
		    }
		}*/
	}
}

public void Event_PlayerDeath(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	if (g_bHasRoundEnded)
	{
		return;
	}

	int victim   = GetClientOfUserId(hEvent.GetInt("userid"));
	int attacker = GetClientOfUserId(hEvent.GetInt("attacker"));

	if (victim == 0 || !IsClientInGame(victim) || attacker == 0)
	{
		return;
	}

	if (!IsClientInGame(attacker))
	{
		if (GetClientTeam(victim) == TEAM_INFECTED)
		{
			ClearDamage(victim);
		}

		return;
	}

	if (GetClientTeam(attacker) == TEAM_SURVIVOR && GetClientTeam(victim) == TEAM_INFECTED)
	{
		int zombieclass = GetInfectedClass(victim);
		if (zombieclass == L4D2Infected_Tank)
		{
			return;    // We don't care about tank damage
		}

		int lasthealth = g_iLastHealth[victim];
		g_iDamageDealt[victim][attacker] += lasthealth;

		if (zombieclass == L4D2Infected_Boomer)
		{
			// Only happens on mid map plugin load when a boomer is up
			if (!g_iBoomerClient)
			{
				g_iBoomerClient = victim;
			}

			//// Oringial code ////
			/*if (!IsFakeClient(g_iBoomerClient)) {
			    GetClientName(g_iBoomerClient, Boomer, sizeof(Boomer));
			} else {
			    Boomer = "AI";
			}*/

			//// Code from decompiler ////
			if (IsClientConnected(g_iBoomerClient))
			{
				if (!IsFakeClient(g_iBoomerClient))
				{
					GetClientName(g_iBoomerClient, Boomer, sizeof(Boomer));
				}
				else {
					Format(Boomer, sizeof(Boomer), "AI");
				}
			}
			else {
				if (!IsFakeClient(victim))
				{
					GetClientName(victim, Boomer, sizeof(Boomer));
				}
				else {
					Format(Boomer, sizeof(Boomer), "AI");
				}
			}
			////////

			CreateTimer(0.2, Timer_BoomerKilledCheck, victim, TIMER_FLAG_NO_MAPCHANGE);
			g_iBoomerKiller = attacker;

			DestroyTimer(g_hBoomerKillTimer);
		}
		else if (zombieclass == L4D2Infected_Hunter && g_bIsPouncing[victim]) {    // Skeet!
			int[][] assisters = new int[MaxClients][2];

			int assister_count, i;
			int damage = g_iDamageDealt[victim][attacker];
			int shots  = g_iShotsDealt[victim][attacker];

			// char plural = (shots == 1) ? 0 : 's';

			for (i = 1; i <= MaxClients; i++)
			{
				if (i == attacker)
				{
					continue;
				}

				if (g_iDamageDealt[victim][i] > 0 && IsClientInGame(i))
				{
					assisters[assister_count][0] = i;
					assisters[assister_count][1] = g_iDamageDealt[victim][i];
					assister_count++;
				}
			}

			// Used GetClientWeapon because Melee Damage is known to be broken
			// Use l4d2_melee_fix.smx in order to make this work properly. :)
			// Rlly?!
			char weapon[64];
			GetClientWeapon(attacker, weapon, sizeof(weapon));

			if (strcmp(weapon, "weapon_melee") == 0)
			{
				/*CPrintToChat(victim, "{green}★ {default}You were {blue}melee skeeted {default}by {olive}%N", attacker);
				CPrintToChat(attacker, "{green}★ {default}You {blue}melee{default}-{blue}skeeted {olive}%N", victim);

				for (int b = 1; b <= MaxClients; b++) {
				    //Print to Specs!
				    if (IsClientInGame(b) && (victim != b) && (attacker != b)) {
				        CPrintToChat(b, "{green}★  {olive}%N {default}was {blue}melee{default}-{blue}skeeted {default}by {olive}%N", victim, attacker)
				    }
				}*/
				CPrintToChatAll("%t %t", "Tag+", "MeleeSkeeted", victim, attacker);
			}
			else if (hEvent.GetBool("headshot") && strcmp(weapon, "weapon_sniper_scout") == 0)
			{    // Scout Headshot
				/*CPrintToChat(victim, "{green}★ {default}You were {blue}Headshotted {default}by {blue}Scout-Player{default}: {olive}%N", attacker);
				CPrintToChat(attacker, "{green}★ {default}You {blue}Headshotted {olive}%N {default}with the {blue}Scout", victim);

				for (int b = 1; b <= MaxClients; b++) {
				    //Print to Specs!
				    if (IsClientInGame(b) && (victim != b) && (attacker != b)) {
				        CPrintToChat(b, "{green}★ {olive}%N {default}was {blue}Headshotted {default}by {blue}Scout-Player{default}: {olive}%N", \
				                                        victim, attacker);
				    }
				}*/

				CPrintToChatAll("%t %t", "Tag+", "Headshotted", victim, attacker);
			}
			else if (assister_count) {
				// Sort by damage, descending
				SortCustom2D(assisters, assister_count, ClientValue2DSortDesc);

				char assister_string[128];
				char buf[MAX_NAME_LENGTH + 8];
				int  assist_shots = g_iShotsDealt[victim][assisters[0][0]];

				// Construct assisters string
				Format(assister_string, sizeof(assister_string), "%t", "assister", assisters[0][0], assisters[0][1], g_iShotsDealt[victim][assisters[0][0]], assist_shots == 1 ? AssistShotsSingular() : AssistShotsPlural());

				for (i = 1; i < assister_count; i++)
				{
					assist_shots = g_iShotsDealt[victim][assisters[i][0]];
					Format(buf, sizeof(buf), ", %t", "assister", assisters[i][0], assisters[i][1], assist_shots, assist_shots == 1 ? AssistShotsSingular() : AssistShotsPlural());

					StrCat(assister_string, sizeof(assister_string), buf);
				}

				/*
				// Print to assisters
				for (i = 0; i < assister_count; i++) {
				    CPrintToChat(assisters[i][0], "{green}★ {olive}%N {default}teamskeeted {olive}%N {default}for {blue}%d damage {default}in {blue}%d shot%c{default}. Assisted by: {olive}%s", \
				                                        attacker, victim, damage, shots, plural, assister_string);
				}

				// Print to victim
				CPrintToChat(victim, "{green}★ {default}You were teamskeeted by {olive}%N {default}for {blue}%d damage {default}in {blue}%d shot%c{default}. Assisted by: {olive}%s", \
				                                            attacker, damage, shots, plural, assister_string);

				// Finally print to attacker
				CPrintToChat(attacker, "{green}★ {default}You teamskeeted {olive}%N {default}for {blue}%d damage {default}in {blue}%d shot%c{default}. Assisted by: {olive}%s", \
				                                            victim, damage, shots, plural, assister_string);

				//Print to Specs!
				for (int b = 1; b <= MaxClients; b++) {
				    if (IsClientInGame(b) && GetClientTeam(b) == TEAM_SPECTATOR) {
				        CPrintToChat(b, "{green}★ {olive}%N {default}teamskeeted {olive}%N {default}for {blue}%d damage {default}in {blue}%d shot%c{default}. Assisted by: {olive}%s", \
				                                            attacker, victim, damage, shots, plural, assister_string);
				    }
				}*/

				CPrintToChatAll("%t %t", "Tag+" , "TeamSkeeted", attacker, victim, damage, shots, shots == 1 ? "" : "s", assister_string);
			}
			else {
				/*CPrintToChat(victim, "{green}★ {default}You were skeeted by {olive}%N {default}in {blue}%d shot%c", attacker, shots, plural);

				CPrintToChat(attacker, "{green}★ {default}You skeeted {olive}%N {default}in {blue}%d shot%c", victim, shots, plural);

				for (int b = 1; b <= MaxClients; b++) {
				    //Print to Everyone Else!
				    if (IsClientInGame(b) && (victim != b) && attacker != b) {
				        CPrintToChat(b, "{green}★ {olive}%N {default}skeeted {olive}%N {default}in {blue}%d shot%c", attacker, victim, shots, plural);
				    }
				}*/

				CPrintToChatAll("%t %t", "Tag+", "Skeeted", attacker, victim, shots, shots == 1 ? "" : "s");
			}
		}
	}

	if (GetClientTeam(victim) == TEAM_INFECTED)
	{
		ClearDamage(victim);
	}
}

public Action Timer_BoomerKilledCheck(Handle hTimer)
{
	BoomerKillTime = BoomerKillTime - 0.2;

	if (g_bHasBoomLanded || BoomerKillTime > 2.0)
	{
		g_iBoomerClient = 0;
		BoomerKillTime  = 0.0;
		return Plugin_Stop;
	}

	// Oringial Code
	/*if (IsClientInGame(g_iBoomerKiller)) {
	    if (IsClientInGame(g_iBoomerClient)) {
	        //Boomer was Shoved before he was Killed!
	        if (g_iBoomerShover != 0 && IsClientInGame(g_iBoomerShover)) {
	            // Shover is Killer
	            if (g_iBoomerShover == g_iBoomerKiller) {
	                //CPrintToChatAll("{green}★ {olive}%N {default}shoved and popped {olive}%s{default}'s Boomer in {blue}%0.1fs", g_iBoomerKiller, Boomer, BoomerKillTime);
	            } else { // Someone Shoved and Someone Killed
	                //CPrintToChatAll("{green}★ {olive}%N {default}shoved and {olive}%N {default}popped {olive}%s{default}'s Boomer in {blue}%0.1fs", g_iBoomerShover, g_iBoomerKiller, Boomer, BoomerKillTime);
	            }
	        } else { //Boomer got Popped without Shove
	            //CPrintToChatAll("{green}★ {olive}%N {default}has shutdown {olive}%s{default}'s Boomer in {blue}%0.1fs", g_iBoomerKiller, Boomer, BoomerKillTime);
	        }
	    }
	}*/

	// Code from decompiler and modified code:)
	if (BoomerKillTime < 0.1)
	{
		BoomerKillTime = 0.1;
	}

	if (IsValidClient(g_iBoomerKiller))
	{
		if (IsValidClient(g_iBoomerClient))
		{
			if (BoomerKillTime <= 0.5)
			{
				CPrintToChatAll("%t %t", "Tag+++", "ShutBoomer", g_iBoomerKiller, Boomer, BoomerKillTime);
			}
			else if (BoomerKillTime > 0.5 && BoomerKillTime <= 1.4)
			{
				CPrintToChatAll("%t %t", "Tag++", "ShutBoomer", g_iBoomerKiller, Boomer, BoomerKillTime);
			}
			else
			{
				CPrintToChatAll("%t %t", "Tag+", "ShutBoomer", g_iBoomerKiller, Boomer, BoomerKillTime);
			}
		}
	}

	g_iBoomerClient = 0;
	BoomerKillTime  = 0.0;
	return Plugin_Stop;
}

public void Event_PlayerShoved(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	if (g_bHasRoundEnded)
	{
		return;
	}

	int victim = GetClientOfUserId(hEvent.GetInt("userid"));
	if (victim == 0 || !IsClientInGame(victim) || GetClientTeam(victim) != TEAM_INFECTED)
	{
		return;
	}

	int attacker = GetClientOfUserId(hEvent.GetInt("attacker"));
	if (attacker == 0 || !IsClientInGame(attacker) || GetClientTeam(attacker) != TEAM_SURVIVOR)
	{
		return;
	}

	int zombieclass = GetInfectedClass(victim);
	if (zombieclass == L4D2Infected_Boomer)
	{
		if (g_hBoomerShoveTimer != null)
		{
			DestroyTimer(g_hBoomerShoveTimer);

			if (!g_iBoomerShover || !IsClientInGame(g_iBoomerShover))
			{
				g_iBoomerShover = attacker;
			}
		}
		else {
			g_iBoomerShover = attacker;
		}

		g_hBoomerShoveTimer = CreateTimer(BOOMER_STAGGER_TIME, Timer_BoomerShove, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Timer_BoomerShove(Handle hTimer)
{
	// PrintToChatAll("[DEBUG] BoomerShove timer expired, credit for boomer shutdown is available to anyone at this point!");
	g_hBoomerShoveTimer = null;
	g_iBoomerShover     = 0;

	return Plugin_Stop;
}

public void Event_PlayerBoomed(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	if (g_bHasBoomLanded)
	{
		return;
	}

	g_bHasBoomLanded = true;

	// Doesn't matter if we log stats to an out of play client, won't affect anything
	/*if (!IsClientInGame(g_iBoomerClient) || IsFakeClient(g_iBoomerClient)) {
	    return;
	}*/

	// We credit the person who spawned the boomer with booms even if it went AI
	// if (hEvent.GetBool("exploded")) {
	// Proxy Boom!
	// if (g_iBoomerShover != 0) {
	/*if (g_iBoomerKiller == g_iBoomerShover) {
	    int iTeam = 0;
	    for (int i = 1; i <= MaxClients; i++) {
	        if (IsClientInGame(i)) {
	            iTeam = GetClientTeam(i);
	            if (iTeam == TEAM_SURVIVOR || iTeam == TEAM_SURVIVOR) {
	                CPrintToChat(i, "{green}★ {olive}%N {default}shoved {olive}%s{default}'s Boomer, but popped it too early", g_iBoomerShover, Boomer);
	            }
	        }
	    }
	} else {
	    int iTeam = 0;
	    for (int i = 1; i <= MaxClients; i++) {
	        if (IsClientInGame(i)) {
	            iTeam = GetClientTeam(i);
	            if (iTeam == TEAM_SURVIVOR || iTeam == TEAM_SURVIVOR) {
	                CPrintToChat(i, "{green}★ {olive}%N {default}shoved {olive}%s{default}'s Boomer, but {olive}%N {default}popped it too early", g_iBoomerShover, Boomer, g_iBoomerKiller);
	            }
	        }
	    }
	}
	*/
	//}
	//} else {
	// Boomer > Survivor Skills.
	//}
}

/*
 * "triggered_car_alarm"
 * {
 * 	"userid"	"short"		// person who triggered the car alarm
 * }
 */
public void Event_AlarmCar(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	if (iClient > 0 && GetClientTeam(iClient) == TEAM_SURVIVOR)
	{
		CPrintToChatAll("%t %t", "Tag+", "AlarmedCar", iClient);
	}
}

void ClearMapStats()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		ClearDamage(i);
	}
}

void ClearDamage(int client)
{
	g_iLastHealth[client] = 0;

	for (int i = 1; i <= MaxClients; i++)
	{
		g_iDamageDealt[client][i] = 0;
		g_iShotsDealt[client][i]  = 0;
	}
}

public int ClientValue2DSortDesc(int[] x, int[] y, const int[][] array, Handle hndl)
{
	if (x[1] > y[1])
	{
		return -1;
	}
	else if (x[1] < y[1]) {
		return 1;
	}
	else {
		return 0;
	}
}

void DestroyTimer(Handle& hRefTimer)
{
	if (hRefTimer != null)
	{
		KillTimer(hRefTimer);
		hRefTimer = null;
	}
}

//// Code from decompiler ////
bool IsValidClient(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client));
}
////

stock char[] AssistShotsSingular()
{
    char buffer[8];
    Format(buffer, sizeof(buffer), "%t", "AssistShotsSingular");
    return buffer;
}

stock char[] AssistShotsPlural()
{
    char buffer[8];
    Format(buffer, sizeof(buffer), "%t", "AssistShotsPlural");
    return buffer;
}