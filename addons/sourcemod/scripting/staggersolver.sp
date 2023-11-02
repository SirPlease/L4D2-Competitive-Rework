#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>

public Plugin myinfo =
{
	name = "Super Stagger Solver",
	author = "CanadaRox, A1m (fix), Sir (rework), Forgetest",
	description = "Blocks all button presses and restarts animations during stumbles",
	version = "2.3",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void L4D_OnShovedBySurvivor_Post(int client, int victim, const float vecDir[3])
{
	L4D2_OnStagger_Post(victim, client);
}

public void L4D2_OnStagger_Post(int client, int source)
{
	if (!L4D_IsPlayerStaggering(client))
		return;
	
	if (IsTankThrowingRock(client)) // handled by plugin "rock_stumble_block"
		return;
	
	PlayerAnimState anim = PlayerAnimState.FromPlayer(client);
	
	switch (anim.GetMainActivity())
	{
		case L4D2_ACT_TERROR_HULK_VICTORY,
			L4D2_ACT_TERROR_HULK_VICTORY_B,
			L4D2_ACT_TERROR_RAGE_AT_ENEMY,
			L4D2_ACT_TERROR_RAGE_AT_KNOCKDOWN:
		{
			SetEntPropFloat(client, Prop_Send, "m_flCycle", 1.0);
		}
		default:
		{
			anim.m_bIsTonguing = false;
			anim.m_bIsSpitting = false;
			
			anim.ResetMainActivity();
		}
	}
}

public Action OnPlayerRunCmd(int client, int &buttons)
{
	if (IsClientInGame(client) 
	&& IsPlayerAlive(client)
	&& L4D_IsPlayerStaggering(client))
	{
		/*
			* If you shove an SI that's on the ladder, the player won't be able to move at all until killed.
			* This is why we only apply this method when the SI is not on a ladder.
		*/
		if (GetEntityMoveType(client) != MOVETYPE_LADDER) {
			buttons = 0;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

bool IsTankThrowingRock(int client)
{
	if (!IsTank(client))
		return false;
	
	int ability = GetEntPropEnt(client, Prop_Send, "m_customAbility");
	if (ability == -1)
		return false;
	
	return CThrow__IsActive(ability) || CThrow__SelectingTankAttack(ability);
}

bool IsTank(int client)
{
	static int s_iTankClass = -1;
	if (s_iTankClass == -1)
	{
		s_iTankClass = L4D_IsEngineLeft4Dead() ? 5 : 8;
	}
	
	return GetClientTeam(client) == 3
		&& GetEntProp(client, Prop_Send, "m_zombieClass") == s_iTankClass;
}

bool CThrow__IsActive(int ability)
{
	CountdownTimer ct = CThrow__GetThrowTimer(ability);
	if (!CTimer_HasStarted(ct))
		return false;
	
	return CTimer_IsElapsed(ct) ? false : true;
}

CountdownTimer CThrow__GetThrowTimer(int ability)
{
	static int s_iOffs_m_throwTimer = -1;
	if (s_iOffs_m_throwTimer == -1)
		s_iOffs_m_throwTimer = FindSendPropInfo("CThrow", "m_hasBeenUsed") + 4;
	
	return view_as<CountdownTimer>(
		GetEntityAddress(ability) + view_as<Address>(s_iOffs_m_throwTimer)
	);
}

bool CThrow__SelectingTankAttack(int ability)
{
	if (L4D_IsEngineLeft4Dead())
		return false;
	
	static int s_iOffs_m_bSelectingAttack = -1;
	if (s_iOffs_m_bSelectingAttack == -1)
		s_iOffs_m_bSelectingAttack = FindSendPropInfo("CThrow", "m_hasBeenUsed") + 28;
	
	return GetEntData(ability, s_iOffs_m_bSelectingAttack, 1) > 0;
}