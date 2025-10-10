#pragma semicolon 1
#pragma newdecls required

#define GAMEDATA "block_m2_giver"
#define FUNCTION "CY115::CTerrorPlayer::ThrowWeapon"

enum {
    BLOCKTYPE_NONE = 0,
    BLOCKTYPE_PILLS,
    BLOCKTYPE_ADRENALINE,
    
    BLOCKTYPE_SIZE
};

#include <dhooks>

int
    g_iBlockType = 0;

public void OnPluginStart()
{
    InitGameData();

    CreateConVarHook("block_item_giver_mask", "1", "Block Pass Item By M2[0=dont block, 1=block pills, 2=block adrenaline, 3=block both]", _, true, 0.0, true, 3.0, OnBlockTypeChanged).IntValue;
}

void InitGameData()
{
    GameData gd = new GameData(GAMEDATA);
    if (!gd) {
        SetFailState("Missing gamedata \"%s.txt\"", GAMEDATA);
    }

    DynamicDetour hDetour = DynamicDetour.FromConf(gd, FUNCTION);
    if (!hDetour) {
        SetFailState("Failed to setup detour \"%s\"", FUNCTION);
    }

    if (!hDetour.Enable(Hook_Pre, OnCTerrorPlayerThrowWeaponPre)) {
        SetFailState("Failed to create detour pre-hook \"%s\"", FUNCTION);
    }

    delete hDetour;
    delete gd;
}

void OnBlockTypeChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    g_iBlockType = convar.IntValue;
}

MRESReturn OnCTerrorPlayerThrowWeaponPre(int pThis, DHookReturn hReturn, DHookParam hParams)
{
    int entity = hParams.Get(1);
    if (entity && IsValidEntity(entity)) {
        char weapon[64];
        GetEntityClassname(entity, weapon, sizeof(weapon));
        if ((StrEqual(weapon, "weapon_pain_pills") && (g_iBlockType & BLOCKTYPE_PILLS)) || 
            StrEqual(weapon, "weapon_adrenaline") && (g_iBlockType & BLOCKTYPE_ADRENALINE)) {
            return MRES_Supercede;
        }

    }

    return MRES_Ignored;
}

ConVar CreateConVarHook(const char[] name, const char[] defaultValue, const char[] description="", int flags=0,
	bool hasMin=false, float min=0.0, bool hasMax=false, float max=0.0, ConVarChanged callback) {
    ConVar convar = CreateConVar(name, defaultValue, description, flags, hasMin, min, hasMax, max);

    Call_StartFunction(INVALID_HANDLE, callback);
    Call_PushCell(convar);
    Call_PushNullString();
    Call_PushNullString();
    Call_Finish();

    convar.AddChangeHook(callback);

    return convar;
}