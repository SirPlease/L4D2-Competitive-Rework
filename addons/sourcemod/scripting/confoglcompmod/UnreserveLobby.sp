#if defined __unreserve_lobby_included
	#endinput
#endif
#define __unreserve_lobby_included

#define UL_MODULE_NAME			"UnreserveLobby"

static ConVar
	UL_hEnable = null;

void UL_OnModuleStart()
{
	UL_hEnable = CreateConVarEx("match_killlobbyres", "1", \
		"Sets whether the plugin will clear lobby reservation once a match have begun", \
		_, true, 0.0, true, 1.0 \
	);

	RegAdminCmd("sm_killlobbyres", UL_KillLobbyRes, ADMFLAG_BAN, "Forces the plugin to kill lobby reservation");
}

void UL_OnClientPutInServer()
{
	if (!IsPluginEnabled() || !UL_hEnable.BoolValue) {
		return;
	}

	L4D_LobbyUnreserve();
}

static Action UL_KillLobbyRes(int client, int args)
{
	L4D_LobbyUnreserve();
	ReplyToCommand(client, "[Confogl] Removed lobby reservation.");

	return Plugin_Handled;
}
