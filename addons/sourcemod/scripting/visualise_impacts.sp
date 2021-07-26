/* @A1m`:
 * We cannot show the client more than 15 impacts at one time, so a delay was added.
 * Now the plugin shows all impacts correctly.
 * The plugin also correctly resets this delay with some time, so we don't get high delay.
*/
#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define DECAL_NAME "materials/decals/metal/metal01b.vtf"
#define SHOW_DELAY_TIME_MULTIPLIER 0.01
#define RESET_COUNT_TIME 1.0

float
	g_fDelayTime[MAXPLAYERS + 1] = {0.0, ...};

int
	g_iCounter[MAXPLAYERS + 1] = {0, ...},
	g_precachedIndex = 0;

public Plugin myinfo = 
{
	name = "Visualise impacts",
	author = "Jahze?, A1m`",
	version = "1.2",
	description = "See name",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework" 
};

public void OnPluginStart()
{
	g_precachedIndex = PrecacheDecal(DECAL_NAME, true);
	
	HookEvent("bullet_impact", BulletImpactEvent);
	HookEvent("round_start", EventRoundReset);
	HookEvent("round_end", EventRoundReset);
}

public void OnMapStart()
{
	if (!IsDecalPrecached(DECAL_NAME)) {
		g_precachedIndex = PrecacheDecal(DECAL_NAME, true); //true or false?
	}
}

public void EventRoundReset(Event hEvent, const char[] name, bool dontBroadcast)
{
	for (int i = 0; i <= MAXPLAYERS; i++) {
		g_iCounter[i] = 0;
		g_fDelayTime[i] = 0.0;
	}
}

public void BulletImpactEvent(Event hEvent, const char[] name, bool dontBroadcast)
{
	int userid = hEvent.GetInt("userid");
	int client = GetClientOfUserId(userid);

	float pos[3];
	pos[0] = hEvent.GetFloat("x");
	pos[1] = hEvent.GetFloat("y");
	pos[2] = hEvent.GetFloat("z");
	
	/* 
	 * The "blocksize" determines how many cells each slot has; it cannot be changed after creation.
	*/
	ArrayStack hStack = new ArrayStack(sizeof(pos));
	hStack.PushArray(pos[0], sizeof(pos));
	hStack.Push(userid);
	
	float fNow = GetGameTime();
	
	if (g_fDelayTime[client] - fNow <= 0.0) {
		g_iCounter[client] = 0;
		g_fDelayTime[client] = fNow + RESET_COUNT_TIME;
	}
	
	CreateTimer(++g_iCounter[client] * SHOW_DELAY_TIME_MULTIPLIER, TimerDelayShow, hStack, TIMER_FLAG_NO_MAPCHANGE | TIMER_HNDL_CLOSE);
}

public Action TimerDelayShow(Handle hTimer, ArrayStack hStack)
{
	if (!hStack.Empty) {
		int client = GetClientOfUserId(hStack.Pop());
		if (client > 0) {
			float pos[3];
			hStack.PopArray(pos[0], sizeof(pos));
			ShowDecal(client, pos);
		}
	}
}

void ShowDecal(int client, float pos[3])
{
	TE_Start("BSP Decal");
	TE_WriteVector("m_vecOrigin", pos);
	TE_WriteNum("m_nEntity", 0);
	TE_WriteNum("m_nIndex", g_precachedIndex);
	TE_SendToClient(client, 0.0);
}
