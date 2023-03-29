#include <sourcemod>
#include <sdktools>
#include <readyup>
#include <pause>

public Plugin myinfo =
{
	name		= "L4D2 - SPEC Silence",
	author		= "Altair Sossai",
	description = "Does not allow spected to send public messages during games",
	version		= "1.0.0",
	url			= "https://github.com/altair-sossai/l4d2-zone-server"
};

public Action OnClientSayCommand(int client, const char[] command, const char[] args)
{
	if (!IsClientInGame(client) || IsFakeClient(client) || IsInReady() || IsInPause())
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