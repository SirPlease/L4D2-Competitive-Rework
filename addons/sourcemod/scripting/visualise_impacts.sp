/** @A1m`:
 * The engine does not allow sending temporary entities larger than the value set in the cvar 'sv_multiplayer_maxtempentities'.
 * If too many decals are sent in a single tick, some will not be displayed unless we add a delay,
 * or increase the cvar value (default is 32, can be raised up to 255).
 *
 * Note: Using TE_SendToClient with a delay alone does not fix this issue.
 *
 * This plugin solves the problem by properly queuing decals, so all bullet impacts are displayed.
 * The delay is cleared automatically after a short period, so it won’t accumulate.
 * Additionally, the plugin fixes an issue where it would stop working after map load (previously it required a manual reload)
 * (Add PrecacheDecal in `OnMapStart`).
 *
 * The plugin now supports automatic decal removal after the configured time period.
 *
 * Original code & Notes (Author Jahze): https://github.com/Jahze/l4d2_plugins/tree/master/spread_patch
 *
 * Note: For some reason, calling function `CBaseEntity::RemoveAllDecals` for the client doesn't work to clear decals.
 * Note: Use command `r_removedecals` for client to clean old decals.
 * 
**/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define DECAL_NAME		"materials/decals/metal/metal01b.vtf"

int
	g_iPrecacheDecal = 0;

float
	g_hRemoveDecalsTime = 0.0;

ConVar
	g_hCvarMultiplayerMaxTempEnts = null,
	g_hCvarRemoveDecalsTime = null;

ArrayList
	g_hDecalQueue = null;

public Plugin myinfo =
{
	name = "Visualise impacts",
	author = "A1m`",
	version = "1.7",
	description = "Shows bullet impacts (based on the original by Jahze, fully rewritten and improved)",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework" 
};

public void OnPluginStart()
{
	g_hCvarRemoveDecalsTime = CreateConVar("l4d_remove_decals_time", "20.0", "After what time will the decals be removed? (0 for disable)", _, true, 0.0, true, 320.0);

	InitPlugin();
}

void InitPlugin()
{
	g_hCvarMultiplayerMaxTempEnts = FindConVar("sv_multiplayer_maxtempentities");

	g_hDecalQueue = new ArrayList();

	g_iPrecacheDecal = PrecacheDecal(DECAL_NAME, true);

	HookEvent("bullet_impact", Event_BulletImpact, EventHookMode_Post);

	HookEvent("round_start", Event_RoundChangeState, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_RoundChangeState, EventHookMode_PostNoCopy);
}

public void OnPluginEnd()
{
	ClearAllData();
}

public void OnMapStart()
{
	ClearAllData();

	if (!IsDecalPrecached(DECAL_NAME)) {
		g_iPrecacheDecal = PrecacheDecal(DECAL_NAME, true); //true or false?
	}
}

public void OnMapEnd()
{
	ClearAllData();
}

public void OnGameFrame()
{
	/** @A1m`:
	 * We only use half the possible value for reliability if any other decals were sent.
	 * We use a function `OnGameFrame` instead of creating a bunch of timers,
	 * and no longer ignore cvar `sv_multiplayer_maxtempentities`.
	**/

	SendSendQueueDecals();
	ShouldRemoveAllDecals();
}

void ShouldRemoveAllDecals()
{
	if (g_hRemoveDecalsTime <= 0.5 || GetGameTime() < g_hRemoveDecalsTime) {
		return;
	}

	RemoveAllDecalsForAll();
	g_hRemoveDecalsTime = 0.0;
}

void SendSendQueueDecals()
{
	if (g_hDecalQueue.Length <= 0) {
		return;
	}

	int iMaxPerTick = 32 / 2; // 32 - default value

	if (g_hCvarMultiplayerMaxTempEnts != null) {
		int iCvarValue = g_hCvarMultiplayerMaxTempEnts.IntValue;

		// Disabled?
		// We protect against division by zero and guarantee that at least one decal will be send.
		if (iCvarValue < 1) {
			return;
		}

		if (iCvarValue < 2) {
			iCvarValue = 2;
		}

		iMaxPerTick = iCvarValue / 2;
	}

	int iProcessed = 0;

	while (g_hDecalQueue.Length > 0 && iProcessed < iMaxPerTick) {
		DataPack hDp = g_hDecalQueue.Get(0);

		if (hDp != null) {
			hDp.Reset();

			int iClient = GetClientOfUserId(hDp.ReadCell());
			if (iClient > 0) {
				float fPos[3];
				hDp.ReadFloatArray(fPos, sizeof(fPos));

				SendDecal(iClient, fPos);
			}
		}

		CloseHandle(hDp);
		g_hDecalQueue.Erase(0);
		iProcessed++;
	}
}

void Event_RoundChangeState(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	ClearAllData();
}

void Event_BulletImpact(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	int iUserId = hEvent.GetInt("userid");

	float fPos[3];
	fPos[0] = hEvent.GetFloat("x");
	fPos[1] = hEvent.GetFloat("y");
	fPos[2] = hEvent.GetFloat("z");

	DataPack hDp = new DataPack();
	hDp.WriteCell(iUserId);
	hDp.WriteFloatArray(fPos, sizeof(fPos), false);

	g_hDecalQueue.Push(hDp);

	g_hRemoveDecalsTime = GetGameTime() + g_hCvarRemoveDecalsTime.FloatValue;
}

void SendDecal(int iClient, float fPos[3])
{
	/** @A1m`:
	 * "World Decal" instead of "BSP Decal" allows you to use command `r_cleardecal` for clearing.
	 * Command `r_cleardecal` cannot be executed by the server only by the client. =(
	 * But it seems like it's impossible to clean "BSP Decal" at all.
	**/

	TE_Start("World Decal");

	TE_WriteVector("m_vecOrigin", fPos);
	TE_WriteNum("m_nIndex", g_iPrecacheDecal);

	TE_SendToClient(iClient, 0.0);

	g_hRemoveDecalsTime = GetGameTime() + g_hCvarRemoveDecalsTime.FloatValue;
}

void RemoveAllDecalsForAll()
{
	for (int iIter = 1; iIter <= MaxClients; iIter++) {
		if (!IsClientInGame(iIter) || IsFakeClient(iIter)) {
			continue;
		}

		RemoveAllDecals(iIter);
	}
}

void RemoveAllDecals(int iClient)
{
	PrintToChat(iClient, "[Note] Use command `r_removedecals` for client to clean old decals.");
}

void ClearAllData()
{
	g_hRemoveDecalsTime = 0.0;

	for (int iIter = 0; iIter < g_hDecalQueue.Length; iIter++) {
		DataPack hDp = g_hDecalQueue.Get(0);

		if (hDp != null) {
			CloseHandle(hDp);
		}

		g_hDecalQueue.Erase(0);
	}

	g_hDecalQueue.Clear();
}
