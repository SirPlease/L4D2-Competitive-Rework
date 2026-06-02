/**
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 */

#pragma semicolon 1
#pragma newdecls required

#include <colors>
#include <survivor_mvp>
#include <sourcemod>

public Plugin myinfo =
{
	name        = "Survivor MVP Test",
	author      = "Lechuga",
	description = "Test MVP functions",
	version     = "1.0",
	url         = ""
};

public void OnPluginStart()
{
	LoadTranslations("survivor_mvp_test.phrases");
	RegConsoleCmd("sm_mvptest", Cmd_MVP, "Shows all available stats for Survivor MVP");
}

public Action Cmd_MVP(int client, int args)
{
	if( args < 0 )
	{
		return Plugin_Handled;
	}

	int 
		GetMVP			= SURVMVP_GetMVP(),
		GetMVPDmgCount	= SURVMVP_GetMVPDmgCount(client),
		GetMVPKills		= SURVMVP_GetMVPKills(client),
		GetMVPCI		= SURVMVP_GetMVPCI(),
		GetMVPCIKills	= SURVMVP_GetMVPCIKills(client);

	float
		GetMVPDmgPercent	= SURVMVP_GetMVPDmgPercent(client),
		GetMVPCIPercent		= SURVMVP_GetMVPCIPercent(client);

	CPrintToChat(client, "%t", "SurvivorMVPTest_CurrentRoundMVP", GetMVP);
	CPrintToChat(client, "%t", "SurvivorMVPTest_DamageClient", GetMVPDmgCount);
	CPrintToChat(client, "%t", "SurvivorMVPTest_SIKillsClient", GetMVPKills);
	CPrintToChat(client, "%t", "SurvivorMVPTest_DamagePercentClient", GetMVPDmgPercent);
	CPrintToChat(client, "%t", "SurvivorMVPTest_CurrentRoundMVPClientCommon", GetMVPCI);
	CPrintToChat(client, "%t", "SurvivorMVPTest_CommonKillsClient", GetMVPCIKills);
	CPrintToChat(client, "%t", "SurvivorMVPTest_CIPercentClient", GetMVPCIPercent);
	return Plugin_Handled;
}