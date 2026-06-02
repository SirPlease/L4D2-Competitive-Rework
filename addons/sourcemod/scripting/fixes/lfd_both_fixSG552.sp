#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <sourcescramble>

public Plugin myinfo =
{
	name = "SG-552 Tickrate Fix",
	author = "bullet28",
	description = "Tries to fix strange FOV behavior when using SG-552 with increased tickrate",
	version = "2",
	url = "https://forums.alliedmods.net/showthread.php?p=2687318"
}

Handle hCycleZoom;
MemoryPatch hZoomPatch;

bool bPatched;
bool bLastFrameWasInZoom[MAXPLAYERS+1];
bool bUnZooming[MAXPLAYERS+1];

public void OnPluginStart() {
	GameData hGameData = LoadGameConfigFile("lfd_both_fixSG552");
	
	StartPrepSDKCall(SDKCall_Entity);
	if (PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "CTerrorGun::CycleZoom") == false) {
		SetFailState("Failed to find signature: \"CTerrorGun::CycleZoom\"");
		return;
	}
	
	hCycleZoom = EndPrepSDKCall();
	if (hCycleZoom == null) {
		SetFailState("Failed to create SDKCall: \"CTerrorGun::CycleZoom\"");
		return;
	}

	hZoomPatch = MemoryPatch.CreateFromConf(hGameData, "zoom");
	if (!hZoomPatch) LogMessage("Failed to create patch for \"zoom\". Skiping...");
	else if (!hZoomPatch.Validate()) LogMessage("Failed to verify patch for \"zoom\". Skiping...");

	delete hGameData;

	HookEvent("weapon_fire", eventWeaponFire);
}

public void eventWeaponFire(Event event, const char[] name, bool dontBroadcast) {
	if (event.GetInt("weaponid") != 34)
		return;

	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!IsClientInGame(client) || IsFakeClient(client))
		return;

	if (GetEntPropEnt(client, Prop_Send, "m_hZoomOwner") == -1)
		return;

	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (!isWeaponSG552(weapon))
		return;

	int clip = GetEntProp(weapon, Prop_Send, "m_iClip1");
	if (clip != 1)
		return;

	SDKCall(hCycleZoom, weapon);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float fAngles[3], int &weapon) {
	if (!IsClientInGame(client) || IsFakeClient(client)) {
		bLastFrameWasInZoom[client] = false;
		return Plugin_Continue;
	}

	int activeWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (!isWeaponSG552(activeWeapon)) {
		bLastFrameWasInZoom[client] = false;
		return Plugin_Continue;
	}

	if (!(GetEntityFlags(client) & FL_ONGROUND)) {
		if (bLastFrameWasInZoom[client]) {
			bLastFrameWasInZoom[client] = false;
			UnZoom(client, activeWeapon, true);
		}

		return Plugin_Continue;
	}

	if (GetEntPropEnt(client, Prop_Send, "m_hZoomOwner") == -1) {
		bLastFrameWasInZoom[client] = false;
		return Plugin_Continue;
	}

	bLastFrameWasInZoom[client] = true;

	if (buttons & IN_RELOAD) {
		if (!GetEntProp(activeWeapon, Prop_Data, "m_bInReload")) {
			if (GetEntProp(activeWeapon, Prop_Data, "m_iClip1") != 50) {
				UnZoom(client, activeWeapon, false);
			}
		}

	} else if (buttons & IN_JUMP) {
		UnZoom(client, activeWeapon, true);
	}

	return Plugin_Continue;
}

void UnZoom(int client, int activeWeapon, bool bFalling) {
	bUnZooming[client] = true;

	if (!bPatched) {
		hZoomPatch.Enable();
		RequestFrame(FrameUnPatchZoom);
		bPatched = true;
	}

	if (zoomToggleAllowed(client)) {
		if (!bFalling) bUnZooming[client] = false;
		SDKCall(hCycleZoom, activeWeapon);
	}
}

public void FrameUnPatchZoom() {
	for (int i = 1; i <= MaxClients; i++) {
		if (bUnZooming[i] && IsClientInGame(i) && !IsFakeClient(i) && !(GetEntityFlags(i) & FL_ONGROUND)) {
			
			if (zoomToggleAllowed(i)) {
				int m_hActiveWeapon = GetEntPropEnt(i, Prop_Send, "m_hActiveWeapon");
				SDKCall(hCycleZoom, m_hActiveWeapon);
				bUnZooming[i] = false;
			
			} else {
				RequestFrame(FrameUnPatchZoom);
				return;
			}
		}
		
		bUnZooming[i] = false;
	}

	hZoomPatch.Disable();
	bPatched = false;
}

bool zoomToggleAllowed(int client) {
	int m_iFOVStart = GetEntProp(client, Prop_Send, "m_iFOVStart");
	float m_flFOVTime = GetEntPropFloat(client, Prop_Send, "m_flFOVTime");
	return m_iFOVStart == 55 && GetGameTime() > m_flFOVTime;
}

bool isWeaponSG552(int entity) {
	if (entity > 0 && IsValidEntity(entity)) {
		char classname[32];
		GetEntityClassname(entity, classname, sizeof(classname));
		if (StrEqual(classname, "weapon_rifle_sg552")) {
			return true;
		}
	}

	return false;
}
