//# vim: set filetype=cpp :

/*
Dingshot a SourceMod L4D2 Plugin
Copyright (C) 2016  Victor B. Gonzalez

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the

Free Software Foundation, Inc.
51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "0.1.0"

ConVar g_cvHeadShot;
ConVar g_cvKillShot;
char g_HeadShot[256];
char g_KillShot[256];
char g_sB[512];

public Plugin:myinfo= {
	name = "Dingshot",
	author = "Victor BUCKWANGS Gonzalez",
	description = "DING Headshot!",
	version = PLUGIN_VERSION,
	url = "https://gitlab.com/vbgunz/Dingshot"
}

public OnPluginStart() {
	HookEvent("player_hurt", HeadShotHook, EventHookMode_Pre);
	HookEvent("infected_hurt", HeadShotHook, EventHookMode_Pre);
	HookEvent("infected_death", HeadShotHook, EventHookMode_Pre);

	g_cvHeadShot = CreateConVar("ds_headshot", "ui/littlereward.wav", "Sound bite for head shot");
	HookConVarChange(g_cvHeadShot, UpdateConVarsHook);
	UpdateConVarsHook(g_cvHeadShot, "ui/littlereward.wav", "ui/littlereward.wav");

	g_cvKillShot = CreateConVar("ds_killshot", "level/bell_normal.wav", "Sound bite for kill shot to the head");
	HookConVarChange(g_cvKillShot, UpdateConVarsHook);
	UpdateConVarsHook(g_cvKillShot, "level/bell_normal.wav", "level/bell_normal.wav");

	AutoExecConfig(true, "dingshot");
}

bool IsClientValid(int client) {
	if (client >= 1 && client <= MaxClients) {
		if (IsClientConnected(client)) {
			 if (IsClientInGame(client)) {
				return true;
			 }
		}
	}

	return false;
}

public UpdateConVarsHook(Handle convar, const char[] oldCv, const char[] newCv) {
	GetConVarName(convar, g_sB, sizeof(g_sB));

	if (StrEqual(g_sB, "ds_headshot")) {
		GetConVarString(g_cvHeadShot, g_HeadShot, sizeof(g_HeadShot));
	}

	else if (StrEqual(g_sB, "ds_killshot")) {
		GetConVarString(g_cvKillShot, g_KillShot, sizeof(g_KillShot));
	}
}

public HeadShotHook(Handle event, const char[] name, bool dontBroadcast) {
	int hitgroup;

	if (strcmp(name, "infected_death") == 0) {
		hitgroup = GetEventInt(event, "headshot");
		g_sB = g_KillShot;
	}

	else {
		hitgroup = GetEventInt(event, "hitgroup");
		g_sB = g_HeadShot;
	}

	PrecacheSound(g_sB, false);

	int attacker = GetEventInt(event, "attacker");
	int type = GetEventInt(event, "type");
	int client = GetClientOfUserId(attacker);

	if (IsClientValid(client) && hitgroup == 1 && type != 8) {  // 8 == death by fire...
		EmitSoundToClient(client, g_sB, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
	}
}
