/* @A1m`:
 * We cannot send to the client temporary objects larger than specified in cvar 'sv_multiplayer_maxtempentities'.
 * A large number of decals will not be displayed if you do not set a delay in sending,
 * or we need to increase the cvar 'sv_multiplayer_maxtempentities' value, by default it is 32 (we can set 255). 
 *
 * TE_SendToClient with the set delay does not fix this issue.
 * Now the plugin shows all impacts correctly.
 * The plugin also correctly resets this delay with some time, so we don't get high delay.
 * Fix plugin not working after loading the map, it was necessary to constantly reload it.
*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define DECAL_NAME "materials/decals/metal/metal01b.vtf"

int
	decalThisTick = 0,
	iLastTick = 0,
	g_iPrecacheDecal = 0;
	
public Plugin myinfo = 
{
	name = "Visualise impacts",
	author = "Jahze?, A1m`",
	version = "1.3",
	description = "See name",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework" 
};

public void OnPluginStart()
{
	g_iPrecacheDecal = PrecacheDecal(DECAL_NAME, true);
	
	HookEvent("bullet_impact", BulletImpactEvent, EventHookMode_Post);
	HookEvent("round_start", EventRoundReset, EventHookMode_PostNoCopy);
	HookEvent("round_end", EventRoundReset, EventHookMode_PostNoCopy);
}

public void OnMapStart()
{
	if (!IsDecalPrecached(DECAL_NAME)) {
		g_iPrecacheDecal = PrecacheDecal(DECAL_NAME, true); //true or false?
	}
}

public void EventRoundReset(Event hEvent, const char[] name, bool dontBroadcast)
{
	decalThisTick = 0;
	iLastTick = 0;
}

public void BulletImpactEvent(Event hEvent, const char[] name, bool dontBroadcast)
{
	float pos[3];
	int userid = hEvent.GetInt("userid");
	//int client = GetClientOfUserId(userid);

	pos[0] = hEvent.GetFloat("x");
	pos[1] = hEvent.GetFloat("y");
	pos[2] = hEvent.GetFloat("z");

	int iTick = GetGameTickCount();

	if (iTick != iLastTick) {
		decalThisTick = 0;
		iLastTick = iTick;
	}

	ArrayStack hStack = new ArrayStack(sizeof(pos));
	hStack.PushArray(pos[0], sizeof(pos));
	hStack.Push(userid);
	
	CreateTimer(++decalThisTick * GetTickInterval(), TimerDelayShowDecal, hStack, TIMER_FLAG_NO_MAPCHANGE | TIMER_HNDL_CLOSE);
}

public Action TimerDelayShowDecal(Handle hTimer, ArrayStack hStack)
{
	if (!hStack.Empty) {
		int client = GetClientOfUserId(hStack.Pop());
		if (client > 0) {
			float pos[3];
			hStack.PopArray(pos[0], sizeof(pos));
			SendDecal(client, pos);
		}
	}

	return Plugin_Stop;
}

void SendDecal(int client, float pos[3])
{
	TE_Start("BSP Decal");
	TE_WriteVector("m_vecOrigin", pos);
	TE_WriteNum("m_nEntity", 0);
	TE_WriteNum("m_nIndex", g_iPrecacheDecal);
	TE_SendToClient(client, 0.0);
}
