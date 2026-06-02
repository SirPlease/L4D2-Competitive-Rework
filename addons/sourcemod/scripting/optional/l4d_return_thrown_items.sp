#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools_functions>
#include <left4dhooks>

#define PLUGIN_VERSION "1.0"

public Plugin myinfo = 
{
	name = "[L4D & 2] Return Thrown Items",
	author = "Forgetest",
	description = "Return pills/adrenalines thrown through shoving key if not successfully given.",
	version = PLUGIN_VERSION,
	url = "https://github.com/Target5150/MoYu_Server_Stupid_Plugins",
}

methodmap CountdownTimer {
	public bool HasStarted() {
		return this.m_timestamp > 0.0;
	}
	public bool IsElasped() {
		return GetGameTime() >= this.m_timestamp;
	}
	property float m_duration {
		public get() { return LoadFromAddress(view_as<Address>(this) + view_as<Address>(4), NumberType_Int32); }
	}
	property float m_timestamp {
		public get() { return LoadFromAddress(view_as<Address>(this) + view_as<Address>(8), NumberType_Int32); }
	}
}

public void OnMapStart()
{
	for (int i = 1; i <= MaxClients; ++i)
	{
		if (IsClientInGame(i)) OnClientPutInServer(i);
	}
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_WeaponDropPost, SDK_OnWeaponDrop_Post);
}

void SDK_OnWeaponDrop_Post(int client, int weapon)
{
	if (GetClientTeam(client) == 3)
		return;
	
	if (weapon <= 0 || !IsWeaponGiveable(weapon))
		return;
	
	// NOTE: Next weapon giving think defaults to 0.5s later, but the drop timer lasts 5.0s long.
	// TODO: Make a cvar in case? Detour `CTerrorWeapon::GiveThink` for arruracy?
	CreateTimer(1.0, Timer_CheckWeaponGiving, EntIndexToEntRef(weapon), TIMER_FLAG_NO_MAPCHANGE);
}

Action Timer_CheckWeaponGiving(Handle timer, int ref)
{
	int weapon = EntRefToEntIndex(ref);
	if (weapon == -1)
		return Plugin_Stop;
	
	CheckWeaponGiving(weapon);
	
	return Plugin_Stop;
}

bool CheckWeaponGiving(int weapon)
{
	CountdownTimer ct = GetWeaponDropTimer(weapon);
	if (!ct.HasStarted() || ct.IsElasped()) // don't bother if not dropping
		return false;

	if (GetEntPropEnt(weapon, Prop_Send, "m_hOwner") != -1) // somebody has grabbed it
		return false;

	int owner = GetWeaponDroppingPlayer(weapon);
	if (owner == -1 || !IsClientInGame(owner))
		return false;
	
	// yeah if empty, actually doesn't matter though, but yeah it feels good :)
	EquipPlayerWeaponIfEmpty(owner, weapon);

	return true;
}

void EquipPlayerWeaponIfEmpty(int client, int weapon)
{
	char cls[32];
	GetEntityClassname(weapon, cls, sizeof(cls));

	int slot = L4D2_GetIntWeaponAttribute(cls, L4D2IWA_Bucket);
	if (GetPlayerWeaponSlot(client, slot) == -1)
	{
		EquipPlayerWeapon(client, weapon);
	}
}

bool IsWeaponGiveable(int weapon)
{
	char cls[32];
	GetEntityClassname(weapon, cls, sizeof(cls));

	int slot = L4D2_GetIntWeaponAttribute(cls, L4D2IWA_Bucket);
	return slot == 4;
}

CountdownTimer GetWeaponDropTimer(int weapon)
{
	static int s_iOffs_m_dropTimer = -1;
	if (s_iOffs_m_dropTimer == -1)
		s_iOffs_m_dropTimer = L4D_IsEngineLeft4Dead1() ? 
				FindSendPropInfo("CTerrorWeapon", "m_flVsLastSwingTime") + 20 : FindSendPropInfo("CTerrorWeapon", "m_nUpgradedPrimaryAmmoLoaded") + 16;
	
	return view_as<CountdownTimer>(GetEntityAddress(weapon) + view_as<Address>(s_iOffs_m_dropTimer));
}

int GetWeaponDroppingPlayer(int weapon)
{
	static int s_iOffs_m_hDroppingPlayer = -1;
	if (s_iOffs_m_hDroppingPlayer == -1)
		s_iOffs_m_hDroppingPlayer = L4D_IsEngineLeft4Dead1() ? 
				FindSendPropInfo("CTerrorWeapon", "m_flVsLastSwingTime") + 16 : FindSendPropInfo("CTerrorWeapon", "m_nUpgradedPrimaryAmmoLoaded") + 8;
	
	return GetEntDataEnt2(weapon, s_iOffs_m_hDroppingPlayer);
}

// int GetWeaponDropTarget(int weapon)
// {
// 	static int s_iOffs_m_hDropTarget = -1;
// 	if (s_iOffs_m_hDropTarget == -1)
// 		s_iOffs_m_hDropTarget = L4D_IsEngineLeft4Dead1() ? 
// 				FindSendPropInfo("CTerrorWeapon", "m_flVsLastSwingTime") + 12 : FindSendPropInfo("CTerrorWeapon", "m_nUpgradedPrimaryAmmoLoaded") + 12;
	
// 	return GetEntDataEnt2(weapon, s_iOffs_m_hDropTarget);
// }
