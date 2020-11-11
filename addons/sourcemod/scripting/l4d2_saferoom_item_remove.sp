#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <l4d2util>
#include <l4d2_saferoom_detect>

#define DELAY_ROUNDSTART    1.0

#define SAFEROOM_END        1
#define SAFEROOM_START      2


public Plugin:myinfo = 
{
    name = "Saferoom Item Remover",
    author = "Tabun, Sir",
    description = "Removes any saferoom item (start or end).",
    version = "0.0.7",
    url = ""
}


new     Handle:         g_hCvarEnabled                                      = INVALID_HANDLE;
new     Handle:         g_hCvarSaferoom                                     = INVALID_HANDLE;
new     Handle:         g_hCvarItems                                        = INVALID_HANDLE;
new     Handle:         g_hTrieItems                                        = INVALID_HANDLE;


enum eTrieItemKillable
{
    ITEM_KILLABLE           = 0,
    ITEM_KILLABLE_HEALTH    = (1 << 0),
    ITEM_KILLABLE_WEAPON    = (1 << 1),
    ITEM_KILLABLE_MELEE     = (1 << 2),
    ITEM_KILLABLE_OTHER     = (1 << 3)
}


public OnPluginStart()
{
    g_hCvarEnabled = CreateConVar(      "sm_safeitemkill_enable",       "1",    "Whether end saferoom items should be removed.", FCVAR_NONE, true, 0.0, true, 1.0);
    g_hCvarSaferoom = CreateConVar(     "sm_safeitemkill_saferooms",    "1",    "Saferooms to empty. Flags: 1 = end saferoom, 2 = start saferoom (3 = kill items from both).", FCVAR_NONE, true, 0.0, false);
    g_hCvarItems = CreateConVar(        "sm_safeitemkill_items",        "7",    "Types to rmove. Flags: 1 = health items, 2 = guns, 4 = melees, 8 = all other usable items", FCVAR_NONE, true, 0.0, false);
    
    PrepareTrie();
}

public OnRoundStart()
{
    if (GetConVarBool(g_hCvarEnabled))
    {
        // needs to be delayed to work right
        CreateTimer( DELAY_ROUNDSTART, Timer_DelayedOnRoundStart, _, TIMER_FLAG_NO_MAPCHANGE );
    }
}

public Action: Timer_DelayedOnRoundStart(Handle:timer)
{
    RemoveEndSaferoomItems();
}


RemoveEndSaferoomItems()
{
    // check for any items in the end saferoom, and remove them
    
    new String:classname[128];
    new eTrieItemKillable: checkItem;
    
    new entityCount = GetEntityCount();
    new iCountEnd = 0;
    new iCountStart = 0;
    
    for (new i=1; i <= entityCount; i++)
    {
        if (!IsValidEntity(i)) { continue; }
        
        // check item type
        GetEdictClassname(i, classname, sizeof(classname));
        if (!GetTrieValue(g_hTrieItems, classname, checkItem)) { continue; }
        
        // see if item is of a killable type by cvar
        if (checkItem == ITEM_KILLABLE || GetConVarInt(g_hCvarItems) & _:checkItem)
        {
            if (GetConVarInt(g_hCvarSaferoom) & SAFEROOM_END)
            {
                if (SAFEDETECT_IsEntityInEndSaferoom(i))
                {
                    // kill the item
                    AcceptEntityInput(i, "Kill");
                    iCountEnd++;
                    continue;
                }
            }
            
            if (GetConVarInt(g_hCvarSaferoom) & SAFEROOM_START)
            {
                if (SAFEDETECT_IsEntityInStartSaferoom(i))
                {
                    // kill the item
                    AcceptEntityInput(i, "Kill");
                    iCountStart++;
                    continue;
                }
            }
        }
    }
    
    LogMessage("Removed %i saferoom item(s) (start: %i; end: %i).", iCountStart + iCountEnd, iCountStart, iCountEnd);
}


PrepareTrie()
{
    g_hTrieItems = CreateTrie();
    SetTrieValue(g_hTrieItems, "weapon_spawn",                         ITEM_KILLABLE_WEAPON);
    SetTrieValue(g_hTrieItems, "weapon_ammo_spawn",                    ITEM_KILLABLE_WEAPON);
    SetTrieValue(g_hTrieItems, "weapon_pistol_spawn",                  ITEM_KILLABLE_WEAPON);
    SetTrieValue(g_hTrieItems, "weapon_pistol_magnum_spawn",           ITEM_KILLABLE_WEAPON);
    SetTrieValue(g_hTrieItems, "weapon_smg_spawn",                     ITEM_KILLABLE_WEAPON);
    SetTrieValue(g_hTrieItems, "weapon_smg_silenced_spawn",            ITEM_KILLABLE_WEAPON);
    SetTrieValue(g_hTrieItems, "weapon_pumpshotgun_spawn",             ITEM_KILLABLE_WEAPON);
    SetTrieValue(g_hTrieItems, "weapon_shotgun_chrome_spawn",          ITEM_KILLABLE_WEAPON);
    SetTrieValue(g_hTrieItems, "weapon_hunting_rifle_spawn",           ITEM_KILLABLE_WEAPON);
    SetTrieValue(g_hTrieItems, "weapon_sniper_military_spawn",         ITEM_KILLABLE_WEAPON);
    SetTrieValue(g_hTrieItems, "weapon_rifle_spawn",                   ITEM_KILLABLE_WEAPON);
    SetTrieValue(g_hTrieItems, "weapon_rifle_ak47_spawn",              ITEM_KILLABLE_WEAPON);
    SetTrieValue(g_hTrieItems, "weapon_rifle_desert_spawn",            ITEM_KILLABLE_WEAPON);
    SetTrieValue(g_hTrieItems, "weapon_autoshotgun_spawn",             ITEM_KILLABLE_WEAPON);
    SetTrieValue(g_hTrieItems, "weapon_shotgun_spas_spawn",            ITEM_KILLABLE_WEAPON);
    SetTrieValue(g_hTrieItems, "weapon_rifle_m60_spawn",               ITEM_KILLABLE_WEAPON);
    SetTrieValue(g_hTrieItems, "weapon_grenade_launcher_spawn",        ITEM_KILLABLE_WEAPON);
    SetTrieValue(g_hTrieItems, "weapon_chainsaw_spawn",                ITEM_KILLABLE_WEAPON);
    SetTrieValue(g_hTrieItems, "weapon_melee_spawn",                   ITEM_KILLABLE_MELEE);
    SetTrieValue(g_hTrieItems, "weapon_item_spawn",                    ITEM_KILLABLE_HEALTH);
    SetTrieValue(g_hTrieItems, "weapon_first_aid_kit_spawn",           ITEM_KILLABLE_HEALTH);
    SetTrieValue(g_hTrieItems, "weapon_defibrillator_spawn",           ITEM_KILLABLE_HEALTH);
    SetTrieValue(g_hTrieItems, "weapon_pain_pills_spawn",              ITEM_KILLABLE_HEALTH);
    SetTrieValue(g_hTrieItems, "weapon_adrenaline_spawn",              ITEM_KILLABLE_HEALTH);
    SetTrieValue(g_hTrieItems, "weapon_pipe_bomb_spawn",               ITEM_KILLABLE_OTHER);
    SetTrieValue(g_hTrieItems, "weapon_molotov_spawn",                 ITEM_KILLABLE_OTHER);
    SetTrieValue(g_hTrieItems, "weapon_vomitjar_spawn",                ITEM_KILLABLE_OTHER);
    SetTrieValue(g_hTrieItems, "weapon_gascan_spawn",                  ITEM_KILLABLE_OTHER);
    SetTrieValue(g_hTrieItems, "upgrade_spawn",                        ITEM_KILLABLE_OTHER);
    SetTrieValue(g_hTrieItems, "upgrade_laser_sight",                  ITEM_KILLABLE_OTHER);
    SetTrieValue(g_hTrieItems, "weapon_upgradepack_explosive_spawn",   ITEM_KILLABLE_OTHER);
    SetTrieValue(g_hTrieItems, "weapon_upgradepack_incendiary_spawn",  ITEM_KILLABLE_OTHER);
    SetTrieValue(g_hTrieItems, "upgrade_ammo_incendiary",              ITEM_KILLABLE_OTHER);
    SetTrieValue(g_hTrieItems, "upgrade_ammo_explosive",               ITEM_KILLABLE_OTHER);
    //SetTrieValue(g_hTrieItems, "prop_fuel_barrel",                     ITEM_KILLABLE);
    //SetTrieValue(g_hTrieItems, "prop_physics",                         ITEM_KILLABLE);
}