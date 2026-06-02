#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>

public Plugin myinfo =
{
	name = "Super Stagger Solver",
	author = "CanadaRox, A1m (fix), Sir (rework), Forgetest",
	description = "Blocks all button presses and restarts animations during stumbles",
	version = "2.4",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void L4D_OnShovedBySurvivor_Post(int client, int victim, const float vecDir[3])
{
	L4D2_OnStagger_Post(victim, client);
}

public void L4D2_OnStagger_Post(int client, int source)
{
	// Interesting to note is that this might not be needed.
	// Issues might be caused by other plugins messing with the current stagger/anim prior to Post.
	// Do with this information what you want.
	if (GetClientTeam(client) != 3)
		return;

	if (!L4D_IsPlayerStaggering(client))
		return;
	
	PlayerAnimState anim = PlayerAnimState.FromPlayer(client);
	if(IsTank(client))
	{
		if (IsTankThrowingRock(client)) // handled by plugin "rock_stumble_block"
			return;

		switch (anim.GetMainActivity())
		{
			case L4D2_ACT_TERROR_HULK_VICTORY,
				L4D2_ACT_TERROR_HULK_VICTORY_B,
				L4D2_ACT_TERROR_RAGE_AT_ENEMY,
				L4D2_ACT_TERROR_RAGE_AT_KNOCKDOWN:
			{
				SetEntPropFloat(client, Prop_Send, "m_flCycle", 1.0);
			}
			case L4D2_ACT_TERROR_CLIMB_24_FROM_STAND,
				L4D2_ACT_TERROR_CLIMB_36_FROM_STAND,
				L4D2_ACT_TERROR_CLIMB_48_FROM_STAND,
				L4D2_ACT_TERROR_CLIMB_50_FROM_STAND,
				L4D2_ACT_TERROR_CLIMB_60_FROM_STAND,
				L4D2_ACT_TERROR_CLIMB_70_FROM_STAND,
				L4D2_ACT_TERROR_CLIMB_72_FROM_STAND,
				L4D2_ACT_TERROR_CLIMB_84_FROM_STAND,
				L4D2_ACT_TERROR_CLIMB_96_FROM_STAND,
				L4D2_ACT_TERROR_CLIMB_108_FROM_STAND,
				L4D2_ACT_TERROR_CLIMB_115_FROM_STAND,
				L4D2_ACT_TERROR_CLIMB_120_FROM_STAND,
				L4D2_ACT_TERROR_CLIMB_130_FROM_STAND,
				L4D2_ACT_TERROR_CLIMB_132_FROM_STAND,
				L4D2_ACT_TERROR_CLIMB_144_FROM_STAND,
				L4D2_ACT_TERROR_CLIMB_150_FROM_STAND,
				L4D2_ACT_TERROR_CLIMB_156_FROM_STAND,
				L4D2_ACT_TERROR_CLIMB_166_FROM_STAND,
				L4D2_ACT_TERROR_CLIMB_168_FROM_STAND:
			{
				return;
			}
			default:
			{
				anim.ResetMainActivity();
			}
		}

		return;
	}
	
	anim.m_bIsTonguing = false;
	anim.m_bIsSpitting = false;
			
	anim.ResetMainActivity();
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
	int ability = GetEntPropEnt(client, Prop_Send, "m_customAbility");
	if (ability == -1)
		return false;
	
	return CThrow__IsActive(ability) || CThrow__SelectingTankAttack(ability);
}

bool IsTank(int client)
{
	return GetEntProp(client, Prop_Send, "m_zombieClass") == 8;
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
	static int s_iOffs_m_bSelectingAttack = -1;
	if (s_iOffs_m_bSelectingAttack == -1)
		s_iOffs_m_bSelectingAttack = FindSendPropInfo("CThrow", "m_hasBeenUsed") + 28;
	
	return GetEntData(ability, s_iOffs_m_bSelectingAttack, 1) > 0;
}