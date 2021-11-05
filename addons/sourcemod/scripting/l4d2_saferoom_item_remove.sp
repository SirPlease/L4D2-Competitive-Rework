#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <l4d2_saferoom_detect>

#define DELAY_ROUNDSTART 1.0

enum
{
	eSAFEROOM_END = 1,
	eSAFEROOM_START = 2
};

enum
{
	eITEM_KILLABLE = 0,					// 0
	eITEM_KILLABLE_HEALTH = (1 << 0),	// 1
	eITEM_KILLABLE_WEAPON = (1 << 1),	// 2
	eITEM_KILLABLE_MELEE = (1 << 2),	// 4
	eITEM_KILLABLE_OTHER = (1 << 3)		// 8
};

ConVar
	g_hCvarEnabled = null,
	g_hCvarSaferoom = null,
	g_hCvarItems = null;

StringMap
	g_hTrieItems = null;

public Plugin myinfo = 
{
	name = "Saferoom Item Remover",
	author = "Tabun, Sir, A1m`",
	description = "Removes any saferoom item (start or end).",
	version = "1.1",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	PrepareTrie();
	
	g_hCvarEnabled = CreateConVar("sm_safeitemkill_enable", "1", "Whether end saferoom items should be removed.", _, true, 0.0, true, 1.0);
	g_hCvarSaferoom = CreateConVar("sm_safeitemkill_saferooms", "1", "Saferooms to empty. Flags: 1 = end saferoom, 2 = start saferoom (3 = kill items from both).", _, true, 0.0, true, 3.0);
	g_hCvarItems = CreateConVar("sm_safeitemkill_items", "7", "Types to rmove. Flags: 1 = health items, 2 = guns, 4 = melees, 8 = all other usable items", _, true, 0.0, true, 15.0);
	
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
}

public void Event_RoundStart(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	if (g_hCvarEnabled.BoolValue) {
		CreateTimer(DELAY_ROUNDSTART, Timer_DelayedOnRoundStart, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Timer_DelayedOnRoundStart(Handle hTimer)
{
	// check for any items in the end saferoom, and remove them
	char sClassname[128];
	int iCheckItem, iCountEnd = 0, iCountStart = 0;
	
	int iEntityCount = GetEntityCount();
	int iCvarSafeRoomValue = g_hCvarSaferoom.IntValue;
	
	for (int i = (MaxClients + 1); i <= iEntityCount; i++) {
		if (!IsValidEntity(i)) {
			continue;
		}
		
		// check item type
		GetEntityClassname(i, sClassname, sizeof(sClassname));
		
		if (!g_hTrieItems.GetValue(sClassname, iCheckItem)) {
			continue;
		}
		
		// see if item is of a killable type by cvar
		if (iCheckItem == eITEM_KILLABLE || g_hCvarItems.IntValue & iCheckItem) {
			if (iCvarSafeRoomValue & eSAFEROOM_END) {
				if (SAFEDETECT_IsEntityInEndSaferoom(i)) {
					// kill the item
					KillEntity(i);
					
					iCountEnd++;
					continue;
				}
			}
			
			if (iCvarSafeRoomValue & eSAFEROOM_START) {
				if (SAFEDETECT_IsEntityInStartSaferoom(i)) {
					// kill the item
					KillEntity(i);
					
					iCountStart++;
					continue;
				}
			}
		}
	}

	LogMessage("Removed %i saferoom item(s) (start: %i; end: %i).", iCountStart + iCountEnd, iCountStart, iCountEnd);
	return Plugin_Stop;
}

void PrepareTrie()
{
	g_hTrieItems = new StringMap();
	
	g_hTrieItems.SetValue("weapon_spawn", eITEM_KILLABLE_WEAPON);
	g_hTrieItems.SetValue("weapon_ammo_spawn", eITEM_KILLABLE_WEAPON);
	g_hTrieItems.SetValue("weapon_pistol_spawn", eITEM_KILLABLE_WEAPON);
	g_hTrieItems.SetValue("weapon_pistol_magnum_spawn", eITEM_KILLABLE_WEAPON);
	g_hTrieItems.SetValue("weapon_smg_spawn", eITEM_KILLABLE_WEAPON);
	g_hTrieItems.SetValue("weapon_smg_silenced_spawn", eITEM_KILLABLE_WEAPON);
	g_hTrieItems.SetValue("weapon_pumpshotgun_spawn", eITEM_KILLABLE_WEAPON);
	g_hTrieItems.SetValue("weapon_shotgun_chrome_spawn", eITEM_KILLABLE_WEAPON);
	g_hTrieItems.SetValue("weapon_hunting_rifle_spawn", eITEM_KILLABLE_WEAPON);
	g_hTrieItems.SetValue("weapon_sniper_military_spawn", eITEM_KILLABLE_WEAPON);
	g_hTrieItems.SetValue("weapon_rifle_spawn", eITEM_KILLABLE_WEAPON);
	g_hTrieItems.SetValue("weapon_rifle_ak47_spawn", eITEM_KILLABLE_WEAPON);
	g_hTrieItems.SetValue("weapon_rifle_desert_spawn", eITEM_KILLABLE_WEAPON);
	g_hTrieItems.SetValue("weapon_autoshotgun_spawn", eITEM_KILLABLE_WEAPON);
	g_hTrieItems.SetValue("weapon_shotgun_spas_spawn", eITEM_KILLABLE_WEAPON);
	g_hTrieItems.SetValue("weapon_rifle_m60_spawn", eITEM_KILLABLE_WEAPON);
	g_hTrieItems.SetValue("weapon_grenade_launcher_spawn", eITEM_KILLABLE_WEAPON);
	g_hTrieItems.SetValue("weapon_chainsaw_spawn", eITEM_KILLABLE_WEAPON);
	
	g_hTrieItems.SetValue("weapon_melee_spawn", eITEM_KILLABLE_MELEE);
	
	g_hTrieItems.SetValue("weapon_item_spawn", eITEM_KILLABLE_HEALTH);
	g_hTrieItems.SetValue("weapon_first_aid_kit_spawn", eITEM_KILLABLE_HEALTH);
	g_hTrieItems.SetValue("weapon_defibrillator_spawn", eITEM_KILLABLE_HEALTH);
	g_hTrieItems.SetValue("weapon_pain_pills_spawn", eITEM_KILLABLE_HEALTH);
	g_hTrieItems.SetValue("weapon_adrenaline_spawn", eITEM_KILLABLE_HEALTH);
	
	g_hTrieItems.SetValue("weapon_pipe_bomb_spawn", eITEM_KILLABLE_OTHER);
	g_hTrieItems.SetValue("weapon_molotov_spawn", eITEM_KILLABLE_OTHER);
	g_hTrieItems.SetValue("weapon_vomitjar_spawn", eITEM_KILLABLE_OTHER);
	g_hTrieItems.SetValue("weapon_gascan_spawn", eITEM_KILLABLE_OTHER);
	g_hTrieItems.SetValue("upgrade_spawn", eITEM_KILLABLE_OTHER);
	g_hTrieItems.SetValue("upgrade_laser_sight", eITEM_KILLABLE_OTHER);
	g_hTrieItems.SetValue("weapon_upgradepack_explosive_spawn", eITEM_KILLABLE_OTHER);
	g_hTrieItems.SetValue("weapon_upgradepack_incendiary_spawn", eITEM_KILLABLE_OTHER);
	g_hTrieItems.SetValue("upgrade_ammo_incendiary", eITEM_KILLABLE_OTHER);
	g_hTrieItems.SetValue("upgrade_ammo_explosive", eITEM_KILLABLE_OTHER);
	
	//g_hTrieItems.SetValue(prop_fuel_barrel", eITEM_KILLABLE);
	//g_hTrieItems.SetValue("prop_physics", eITEM_KILLABLE);
}

void KillEntity(int iEntity)
{
#if SOURCEMOD_V_MINOR > 8
	RemoveEntity(iEntity);
#else
	AcceptEntityInput(iEntity, "Kill");
#endif
}
