#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sourcescramble>
#include <dhooks>

#define GAMEDATA "fix_pill_pass"
#define PASS_INFLIGHT_WINDOW 0.5

int g_iOffs_m_hDroppingPlayer = -1; // CTerrorWeapon: the survivor who threw the item
int g_iOffs_m_hDropTarget     = -1; // CTerrorWeapon: the survivor the item is headed to
MemoryPatch g_hIsInCombatPatch;

float g_fIncomingPassAt[MAXPLAYERS + 1];

public Plugin myinfo =
{
	name = "[L4D/2] Fix Pill Passing",
	author = "Alan, A1m`, Forgetest, Sir",
	description = "Fixes being unable to pass Pills to Survivor considered 'In Combat' + Pills being thrown away.",
	version = "1.0"
};

public void OnPluginStart()
{
	int iBaseOffs = FindSendPropInfo("CTerrorWeapon", "m_nUpgradedPrimaryAmmoLoaded");
	if (iBaseOffs == -1)
		SetFailState("Could not find offset: CTerrorWeapon->m_nUpgradedPrimaryAmmoLoaded");

	g_iOffs_m_hDroppingPlayer = iBaseOffs + 8;
	g_iOffs_m_hDropTarget     = iBaseOffs + 12;

	GameData hGameData = new GameData(GAMEDATA);
	if (hGameData == null)
		SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);

	g_hIsInCombatPatch = MemoryPatch.CreateFromConf(hGameData, "IsInCombatPillPass");
	if (g_hIsInCombatPatch == null || !g_hIsInCombatPatch.Validate())
		SetFailState("Failed to validate \"IsInCombatPillPass\" target.");
	if (!g_hIsInCombatPatch.Enable())
		SetFailState("Failed to patch \"IsInCombatPillPass\" target.");

	DynamicDetour hDetour = DynamicDetour.FromConf(hGameData, "CBaseBeltItem::SecondaryAttack");
	if (!hDetour)
		SetFailState("Missing signature \""..."CBaseBeltItem::SecondaryAttack"..."\"");
	if (!hDetour.Enable(Hook_Post, BaseBeltItem_SecondaryAttack_Post))
		SetFailState("Failed to detour \""..."CBaseBeltItem::SecondaryAttack"..."\"");

	delete hDetour;
	delete hGameData;

	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
}

public void OnPluginEnd()
{
	if (g_hIsInCombatPatch != null)
		g_hIsInCombatPatch.Disable();
}

void Event_RoundStart(Event event, const char[] sEventName, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; ++i)
		g_fIncomingPassAt[i] = 0.0;
}

MRESReturn BaseBeltItem_SecondaryAttack_Post(int pThis)
{
	/*
		The pills only become an ownerless world entity when the game actually throws them
		to a teammate with a free slot; any other outcome keeps them held, nothing to do.
	*/
	if (GetEntPropEnt(pThis, Prop_Send, "m_hOwner") != -1)
		return MRES_Ignored;

	int iTarget  = GetEntDataEnt2(pThis, g_iOffs_m_hDropTarget);
	int iThrower = GetEntDataEnt2(pThis, g_iOffs_m_hDroppingPlayer);

	if (!IsValidSurvivor(iTarget) || !IsValidSurvivor(iThrower))
		return MRES_Ignored;

	float fNow = GetGameTime();
	float fSince = fNow - g_fIncomingPassAt[iTarget];

	/*
		Someone is already passing pills to this target and they haven't landed yet, so the
		target's slot will be taken - this pass can't be delivered and would drop on the
		floor. Hand it straight back to the thrower instead.
	*/
	if (fSince >= 0.0 && fSince < PASS_INFLIGHT_WINDOW)
	{
		EquipPlayerWeapon(iThrower, pThis);
		return MRES_Ignored;
	}

	/*
		First pass to this target: let it through, remember it so a follow-up before it lands
		gets bounced back above, and drop it at the target's feet so GiveThink hands it over.
	*/
	g_fIncomingPassAt[iTarget] = fNow;
	return MRES_Ignored;
}

bool IsValidSurvivor(int client)
{
	return client >= 1 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2;
}
