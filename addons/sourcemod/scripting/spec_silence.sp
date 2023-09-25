#include <sourcemod>
#include <sdktools>
#include <readyup>
#include <pause>

ConVar hCvarSpecSilence;

bool bSpecSilence = false;

public Plugin myinfo =
{
	name		= "L4D2 - SPEC Silence",
	author		= "Altair Sossai",
	description = "Does not allow spected to send public messages during games",
	version		= "1.0.0",
	url			= "https://github.com/altair-sossai/l4d2-zone-server"
};

public void OnPluginStart()
{
	hCvarSpecSilence = CreateConVar("l4d2_spec_silence_enabled", "1", "Does not allow spected to send public messages during games");

	bSpecSilence = GetConVarBool(hCvarSpecSilence);

	RegAdminCmd("sm_specsilence", SpecSilenceCommand, ADMFLAG_BAN);
}

public Action SpecSilenceCommand(int client, int args)
{
	ToggleSpecSilence();

	return Plugin_Handled;
}

public Action OnClientSayCommand(int client, const char[] command, const char[] args)
{
	if (!bSpecSilence || !IsClientInGame(client) || IsFakeClient(client) || IsInReady() || IsInPause())
		return Plugin_Continue;
		
	bool say = strcmp(command, "say", false) == 0;
	if (!say)
		return Plugin_Continue;

	bool spec = GetClientTeam(client) == 1;
	if (!spec)
		return Plugin_Continue;

	bool admin = GetAdminFlag(GetUserAdmin(client), Admin_Changemap);
	if (admin)
		return Plugin_Continue;

	PrintToChat(client, "\x01Spectators can only send public messages before \x04!ready\x01 or during \x04!pause\x01");

	return Plugin_Stop;
}

public void ToggleSpecSilence()
{
	SetSpecSilence(!bSpecSilence);
}

public void SetSpecSilence(bool enabled)
{
	if (enabled == bSpecSilence)
		return;

	bSpecSilence = enabled;

	if (enabled)
		PrintToChatAll("\x01SPEC silence: \x04ON");
	else
		PrintToChatAll("\x01SPEC silence: \x04OFF");
}