#pragma semicolon 1

#include <sourcemod>
#include <builtinvotes>
#include <colors>

new Handle:g_hVote;
new String:g_sSlots[32];
new Handle:hMinSlots;
new Handle:hMaxSlots;
new MaxSlots;
new MinSlots;

public Plugin:myinfo =
{
	name = "Slots?! Voter",
	description = "Slots Voter",
	author = "Sir",
	version = "",
	url = ""
};

public OnPluginStart()
{
	RegConsoleCmd("sm_slots", SlotsRequest);
	hMinSlots = CreateConVar("sm_slot_vote_min", "1", "mininum amount of slots you wish players to be able to vote for? (No lower than 1)");
	hMaxSlots = CreateConVar("sm_slot_vote_max", "16", "Maximum amount of slots you wish players to be able to vote for? (DON'T GO HIGHER THAN 30)");
	MaxSlots = GetConVarInt(hMaxSlots);
	MinSlots = GetConVarInt(hMinSlots);
	HookConVarChange(hMaxSlots, CVarChanged);
	HookConVarChange(hMaxSlots, CVarChanged);
}

public Action:SlotsRequest(client, args)
{
	if (client < 0)
	{
		return Plugin_Handled;
	}
	if (args == 1)
	{
		new String:sSlots[64];
		GetCmdArg(1, sSlots, sizeof(sSlots));
		new Int = StringToInt(sSlots);
		if (Int > MaxSlots)
		{
			CPrintToChat(client, "{blue}[{default}Slots{blue}] {default}你不能在这个服务器上开超过 {olive}%i {default}的位置", MaxSlots);
		}
		else
		{
			if(client == 0)
			{
				CPrintToChatAll("{blue}[{default}Slots{blue}] {olive}管理员 {default}将服务器位置设为 {blue}%i {default}个", Int);
				SetConVarInt(FindConVar("sv_maxplayers"), Int);
				SetConVarInt(FindConVar("sv_visiblemaxplayers"), Int);
			}
			else if (GetUserAdmin(client) != INVALID_ADMIN_ID )
			{
				CPrintToChatAll("{blue}[{default}Slots{blue}] {olive}管理员 {default}将服务器位置设为 {blue}%i {default}个", Int);
				SetConVarInt(FindConVar("sv_maxplayers"), Int);
				SetConVarInt(FindConVar("sv_visiblemaxplayers"), Int);
			}
			else if (Int < MinSlots)
			{
				CPrintToChat(client, "{blue}[{default}Slots{blue}] {default}你不能将服务器位置设为小于{blue}%i {default}个.", MinSlots);
			}
			else if (StartSlotVote(client, sSlots))
			{
				strcopy(g_sSlots, sizeof(g_sSlots), sSlots);
				FakeClientCommand(client, "Vote Yes");
			}
		}
	}
	else
	{
		CPrintToChat(client, "{blue}[{default}Slots{blue}] {default}用法: {olive}!slots {default}<{olive}你想要设置的服务器位置数量{default}> {blue}| {default}例子: {olive}!slots 8");
	}
	return Plugin_Handled;
}

bool:StartSlotVote(client, String:Slots[])
{
	if (GetClientTeam(client) == 1)
	{
		PrintToChat(client, "旁观者不允许使用命令.");
		return false;
	}

	if (IsNewBuiltinVoteAllowed())
	{
		new iNumPlayers;
		decl iPlayers[MaxClients];
		for (new i=1; i<=MaxClients; i++)
		{
			if (!IsClientInGame(i) || IsFakeClient(i) || (GetClientTeam(i) == 1))
			{
				continue;
			}
			iPlayers[iNumPlayers++] = i;
		}
		
		new String:sBuffer[64];
		g_hVote = CreateBuiltinVote(VoteActionHandler, BuiltinVoteType_Custom_YesNo, BuiltinVoteAction_Cancel | BuiltinVoteAction_VoteEnd | BuiltinVoteAction_End);
		Format(sBuffer, sizeof(sBuffer), "限制服务器位置到 '%s' 个?", Slots);
		SetBuiltinVoteArgument(g_hVote, sBuffer);
		SetBuiltinVoteInitiator(g_hVote, client);
		SetBuiltinVoteResultCallback(g_hVote, SlotVoteResultHandler);
		DisplayBuiltinVote(g_hVote, iPlayers, iNumPlayers, 20);
		return true;
	}

	PrintToChat(client, "投票功能暂时不能使用.");
	return false;
}

public void SlotVoteResultHandler(Handle vote, int num_votes, int num_clients, const int[][] client_info, int num_items, const int[][] item_info)
{
	for (new i=0; i<num_items; i++)
	{
		if (item_info[i][BUILTINVOTEINFO_ITEM_INDEX] == BUILTINVOTES_VOTE_YES)
		{
			if (item_info[i][BUILTINVOTEINFO_ITEM_VOTES] > (num_votes / 2))
			{
				new Slots = StringToInt(g_sSlots, 10);
				DisplayBuiltinVotePass(vote, "限制服务器位置...");
				SetConVarInt(FindConVar("sv_maxplayers"), Slots);
				SetConVarInt(FindConVar("sv_visiblemaxplayers"), Slots);
				return;
			}
		}
	}
	DisplayBuiltinVoteFail(vote, BuiltinVoteFail_Loses);
}

public VoteActionHandler(Handle:vote, BuiltinVoteAction:action, param1, param2)
{
	switch (action)
	{
		case BuiltinVoteAction_End:
		{
			g_hVote = INVALID_HANDLE;
			CloseHandle(vote);
		}
		case BuiltinVoteAction_Cancel:
		{
			DisplayBuiltinVoteFail(vote, BuiltinVoteFailReason:param1);
		}
	}
}

public CVarChanged(Handle:cvar, String:oldValue[], String:newValue[])
{
	MaxSlots = GetConVarInt(hMaxSlots);
	MinSlots = GetConVarInt(hMinSlots);
}

