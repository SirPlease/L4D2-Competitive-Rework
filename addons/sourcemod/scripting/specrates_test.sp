#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <colors>

#undef REQUIRE_PLUGIN
#include <specrates>
#define REQUIRE_PLUGIN

bool
	g_bSpecRates,
	g_bLateload;

public Plugin myinfo =
{
	name		= "Lightweight Spectating Test",
	author		= "lechuga",
	description = "A simple plugin to test the spectating rates Natives.",
	version		= "1.0.0",
	url			= "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_bLateload = late;
	return APLRes_Success;
}

public void OnAllPluginsLoaded()
{
	g_bSpecRates = LibraryExists("specrates");
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "specrates", true))
		g_bSpecRates = false;
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "specrates", true))
		g_bSpecRates = true;
}

public void OnPluginStart()
{
	LoadTranslations("common.phrases");

	RegAdminCmd("sm_changestatusrates", Cmd_ChangeStatusRates, ADMFLAG_GENERIC);
	RegAdminCmd("sm_getstatusrates", Cmd_GetStatusRates, ADMFLAG_GENERIC);

	if (!g_bLateload)
		return;

	g_bSpecRates = LibraryExists("specrates");
}

Action Cmd_ChangeStatusRates(int client, int args)
{
	if (!g_bSpecRates)
	{
		CReplyToCommand(client, "[{green}SpecRates{default}] {red}Error{default}: SpecRates is not loaded.");
		return Plugin_Handled;
	}

	if (args < 1)
	{
		CReplyToCommand(client, "[{green}SpecRates{default}] {blue}Usage{default}: sm_changestatusrates <target>");
		return Plugin_Handled;
	}

	char buffer[64];
	GetCmdArg(1, buffer, sizeof(buffer));

	int target = FindTarget(client, buffer);
	if (target == -1)
	{
		CReplyToCommand(client, "[{green}SpecRates{default}] {red}Error{default}: Invalid target.");
		return Plugin_Handled;
	}

	StatusRates OldStatus = GetStatusRates(client);
	switch (OldStatus)
	{
		case RatesLimit:
			SetStatusRates(client, RatesFree);
		case RatesFree:
			SetStatusRates(client, RatesLimit);
	}
	CReplyToCommand(client, "[{green}SpecRates{default}] {blue}Success{default}: Status Rates change {olive}%s{default} --> {olive}%s{default} to {blue}%N{default}", OldStatus == RatesLimit ? "Block" : "Free", OldStatus == RatesLimit ? "Free" : "Block", target);
	return Plugin_Handled;
}

Action Cmd_GetStatusRates(int client, int args)
{
	if (!g_bSpecRates)
	{
		CReplyToCommand(client, "[{green}SpecRates{default}] {red}Error{default}: SpecRates is not loaded.");
		return Plugin_Handled;
	}

	if (args < 1)
	{
		CReplyToCommand(client, "[{green}SpecRates{default}] {blue}Usage{default}: sm_changestatusrates <target>");
		return Plugin_Handled;
	}

	char buffer[64];
	GetCmdArg(1, buffer, sizeof(buffer));

	int target = FindTarget(client, buffer);
	if (target == -1)
	{
		CReplyToCommand(client, "[{green}SpecRates{default}] {red}Error{default}: Invalid target.");
		return Plugin_Handled;
	}

	StatusRates OldStatus = GetStatusRates(client);
	CReplyToCommand(client, "[{green}SpecRates{default}] {blue}Success{default}: Status Rates is {olive}%s{default} to {blue}%N{default}", OldStatus == RatesLimit ? "Block" : "Free", target);
	return Plugin_Handled;
}