#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#include <l4d2util_constants>

// Has to cover every command the client re-predicts after a correction, i.e. a full round trip
#define BLOCK_WINDOW	1.0

enum
{
	Weapon_Gun,
	Weapon_Pistol,
	Weapon_Shotgun
};

StringMap
	g_hStockClip,
	g_hWeaponType;

int
	g_iBlockedWeapon[MAXPLAYERS + 1] = {INVALID_ENT_REFERENCE, ...},
	g_iBlockedClip[MAXPLAYERS + 1];

float
	g_fSavedNext[MAXPLAYERS + 1],
	g_fBlockedNext[MAXPLAYERS + 1];

public Plugin myinfo =
{
	name        = "[L4D2] Clip Size Reload Fix",
	author      = "Sir",
	description = "Stops the reload animation glitch when reloading a full clip of a weapon with a changed clip size",
	version     = "1.0",
	url         = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	g_hStockClip = new StringMap();
	g_hWeaponType = new StringMap();

	// Stock clip sizes, client predicted values for weapons
	AddWeapon("weapon_pistol",            15,  Weapon_Pistol);
	AddWeapon("weapon_pistol_magnum",     8,   Weapon_Pistol);
	AddWeapon("weapon_smg",               50,  Weapon_Gun);
	AddWeapon("weapon_smg_silenced",      50,  Weapon_Gun);
	AddWeapon("weapon_smg_mp5",           50,  Weapon_Gun);
	AddWeapon("weapon_rifle",             50,  Weapon_Gun);
	AddWeapon("weapon_rifle_ak47",        40,  Weapon_Gun);
	AddWeapon("weapon_rifle_desert",      60,  Weapon_Gun);
	AddWeapon("weapon_rifle_sg552",       50,  Weapon_Gun);
	AddWeapon("weapon_rifle_m60",         150, Weapon_Gun);
	AddWeapon("weapon_hunting_rifle",     15,  Weapon_Gun);
	AddWeapon("weapon_sniper_military",   30,  Weapon_Gun);
	AddWeapon("weapon_sniper_scout",      15,  Weapon_Gun);
	AddWeapon("weapon_sniper_awp",        20,  Weapon_Gun);
	AddWeapon("weapon_grenade_launcher",  1,   Weapon_Gun);
	AddWeapon("weapon_pumpshotgun",       8,   Weapon_Shotgun);
	AddWeapon("weapon_shotgun_chrome",    8,   Weapon_Shotgun);
	AddWeapon("weapon_autoshotgun",       10,  Weapon_Shotgun);
	AddWeapon("weapon_shotgun_spas",      10,  Weapon_Shotgun);
}

void AddWeapon(const char[] sClassname, int iStockClip, int iType)
{
	g_hStockClip.SetValue(sClassname, iStockClip);
	g_hWeaponType.SetValue(sClassname, iType);
}

public void OnClientDisconnect(int client)
{
	g_iBlockedWeapon[client] = INVALID_ENT_REFERENCE;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	// Release the block before the game runs this command, so a shot or a switched weapon isn't held up by it
	if (g_iBlockedWeapon[client] == INVALID_ENT_REFERENCE)
		return Plugin_Continue;

	int iActive = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (!(buttons & IN_RELOAD) || (buttons & IN_ATTACK) || iActive == -1 || EntIndexToEntRef(iActive) != g_iBlockedWeapon[client])
		ReleaseBlock(client);

	return Plugin_Continue;
}

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
	if (!(buttons & IN_RELOAD) || IsFakeClient(client) || GetClientTeam(client) != L4D2Team_Survivor || !IsPlayerAlive(client))
		return;

	int iWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (iWeapon == -1 || !ClientWouldMispredictReload(client, iWeapon, buttons))
		return;

	g_iBlockedClip[client] = GetEntProp(iWeapon, Prop_Send, "m_iClip1");

	// Keep the time from before the block, unless something else changed the timer since
	float fNext = GetEntPropFloat(iWeapon, Prop_Send, "m_flNextPrimaryAttack");
	if (EntIndexToEntRef(iWeapon) != g_iBlockedWeapon[client] || fNext != g_fBlockedNext[client])
		g_fSavedNext[client] = fNext;

	g_iBlockedWeapon[client] = EntIndexToEntRef(iWeapon);
	g_fBlockedNext[client] = GetGameTime() + BLOCK_WINDOW;
	if (g_fBlockedNext[client] < fNext)
		g_fBlockedNext[client] = fNext;

	SetEntPropFloat(iWeapon, Prop_Send, "m_flNextPrimaryAttack", g_fBlockedNext[client]);
}

/*
	Whether this reload was refused by the server because of the changed clip size (while the client predicts a reload)
	Basically mirrors the checks in CTerrorGun::Reload, CBaseShotgun::Reload and CBaseCombatWeapon::DefaultReload.
*/
bool ClientWouldMispredictReload(int client, int iWeapon, int buttons)
{
	char sClassname[64];
	GetEntityClassname(iWeapon, sClassname, sizeof(sClassname));

	int iStockClip, iType;
	if (!g_hStockClip.GetValue(sClassname, iStockClip))
		return false;

	g_hWeaponType.GetValue(sClassname, iType);

	if (GetEntProp(iWeapon, Prop_Send, "m_bInReload"))
		return false;

	// Both sides refuse while this timer runs, and it's the one we're using (if we already are, it's in the future too)
	if (GetGameTime() < GetEntPropFloat(iWeapon, Prop_Send, "m_flNextPrimaryAttack") && EntIndexToEntRef(iWeapon) != g_iBlockedWeapon[client])
		return false;

	int iClipSize = L4D2_GetIntWeaponAttribute(sClassname, L4D2IWA_ClipSize);
	if (iClipSize == iStockClip)
		return false;

	// Dual pistols double the clip on both sides
	if (GetEntProp(iWeapon, Prop_Send, "m_isDualWielding"))
	{
		iClipSize *= 2;
		iStockClip *= 2;
	}

	// The server only refuses a full clip
	int iClip = GetEntProp(iWeapon, Prop_Send, "m_iClip1");
	if (iClip != iClipSize)
		return false;

	// Pistol ammo is infinite, the rest needs reserve ammo to reload from
	if (iType != Weapon_Pistol && GetReserveAmmo(client, iWeapon) < 1)
		return false;

	// Shotguns don't reload with attack or shove held, and only to fill a clip that's short (a negative count counts as nothing)
	if (iType == Weapon_Shotgun)
		return !(buttons & (IN_ATTACK | IN_ATTACK2)) && !GetEntProp(iWeapon, Prop_Send, "m_reloadState") && iStockClip > iClip;

	// Other guns reload whenever the count to fill isn't 0, a negative one included
	return true;
}

void ReleaseBlock(int client)
{
	int iWeapon = EntRefToEntIndex(g_iBlockedWeapon[client]);
	g_iBlockedWeapon[client] = INVALID_ENT_REFERENCE;

	if (iWeapon == INVALID_ENT_REFERENCE)
		return;

	// Ignore if something else (a shove, a deploy) modified the timer since the block
	if (GetEntPropFloat(iWeapon, Prop_Send, "m_flNextPrimaryAttack") == g_fBlockedNext[client])
		SetEntPropFloat(iWeapon, Prop_Send, "m_flNextPrimaryAttack", g_fSavedNext[client]);

	// A queued reload can only be refused while the clip is still full
	if (GetEntProp(iWeapon, Prop_Send, "m_iClip1") == g_iBlockedClip[client])
		SetEntPropFloat(iWeapon, Prop_Send, "m_reloadQueuedStartTime", 0.0);
}

int GetReserveAmmo(int client, int iWeapon)
{
	int iAmmoType = GetEntProp(iWeapon, Prop_Send, "m_iPrimaryAmmoType");
	if (iAmmoType < 0)
		return 0;

	return GetEntProp(client, Prop_Send, "m_iAmmo", _, iAmmoType);
}
