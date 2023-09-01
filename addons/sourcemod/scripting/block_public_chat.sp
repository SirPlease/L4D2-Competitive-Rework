#include <sourcemod>
#include <sdktools>
#include <readyup>
#include <pause>

public Plugin myinfo =
{
	name		= "L4D2 - Block public chat",
	author		= "Altair Sossai",
	description = "Block public chat",
	version		= "1.0.0",
	url			= "https://github.com/altair-sossai/l4d2-zone-server"
};

bool blocked = false;

public void OnPluginStart()
{
	RegAdminCmd("sm_publicchat", PublicChatCommand, ADMFLAG_BAN);
}

public Action PublicChatCommand(int client, int args)
{
	ToggleBlocked();

	return Plugin_Handled;
}

public Action OnClientSayCommand(int client, const char[] command, const char[] args)
{
	if (!blocked || !IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Continue;
		
	bool say = strcmp(command, "say", false) == 0;
	if (!say)
		return Plugin_Continue;

	bool admin = GetAdminFlag(GetUserAdmin(client), Admin_Changemap);
	if (admin)
		return Plugin_Continue;

	PrintToChat(client, "\x01Public messages are blocked");

	return Plugin_Stop;
}

public void ToggleBlocked()
{
    blocked = !blocked;

    if (blocked)
        PrintToChatAll("\x01Public chat: \x04OFF");
    else
        PrintToChatAll("\x01Public chat: \x04ON");
}