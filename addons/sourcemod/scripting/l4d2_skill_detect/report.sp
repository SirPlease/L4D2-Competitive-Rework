#if defined _skill_detect_report_included
	#endinput
#endif
#define _skill_detect_report_included

// boomer pop
stock void HandlePop(int attacker, int victim, int shoveCount, float timeAlive)
{
	// report?
	if (g_cvarReport.BoolValue && g_cvarRepPop.BoolValue)
	{
		if (IsValidClientInGame(attacker) && IsValidClientInGame(victim) && !IsFakeClient(victim))
			CPrintToChatAll("%t %t", "Tag+", "Popped", attacker, victim);
		else if (IsValidClientInGame(attacker))
			CPrintToChatAll("%t %t", "Tag+", "PoppedBot", attacker);
	}

	Call_StartForward(g_hForwardBoomerPop);
	Call_PushCell(attacker);
	Call_PushCell(victim);
	Call_PushCell(shoveCount);
	Call_PushFloat(timeAlive);
	Call_Finish();
}

// charger level
stock void HandleLevel(int attacker, int victim)
{
	// report?
	if (g_cvarReport.BoolValue && g_cvarRepLevel.BoolValue)
	{
		if (IsValidClientInGame(attacker) && IsValidClientInGame(victim) && !IsFakeClient(victim))
			CPrintToChatAll("%t %t", "Tag+++", "Leveled", attacker, victim);
		else if (IsValidClientInGame(attacker))
			CPrintToChatAll("%t %t", "Tag+++", "LeveledBot", attacker);
	}

	// call forward
	Call_StartForward(g_hForwardLevel);
	Call_PushCell(attacker);
	Call_PushCell(victim);
	Call_Finish();
}
// charger level hurt
stock void HandleLevelHurt(int attacker, int victim, int damage)
{
	// report?
	if (g_cvarReport.BoolValue && g_cvarRepHurtLevel.BoolValue)
	{
		if (IsValidClientInGame(attacker) && IsValidClientInGame(victim) && !IsFakeClient(victim))
			CPrintToChatAll("%t %t", "Tag+", "LeveledHurt", attacker, victim, damage);
		else if (IsValidClientInGame(attacker))
			CPrintToChatAll("%t %t", "Tag+", "LeveledHurtBot", attacker, damage);
	}

	// call forward
	Call_StartForward(g_hForwardLevelHurt);
	Call_PushCell(attacker);
	Call_PushCell(victim);
	Call_PushCell(damage);
	Call_Finish();
}

// deadstops
stock void HandleDeadstop(int attacker, int victim)
{
	// report?
	if (g_cvarReport.BoolValue && g_cvarRepDeadStop.BoolValue)
	{
		if (IsValidClientInGame(attacker) && IsValidClientInGame(victim) && !IsFakeClient(victim))
			CPrintToChatAll("%t %t", "Tag+", "Deadstopped", attacker, victim);
		else if (IsValidClientInGame(attacker))
			CPrintToChatAll("%t %t", "Tag+", "DeadstoppedBot", attacker);
	}

	Call_StartForward(g_hForwardHunterDeadstop);
	Call_PushCell(attacker);
	Call_PushCell(victim);
	Call_Finish();
}

stock void HandleShove(int attacker, int victim, int zombieClass)
{
	// report?
	if (g_cvarReport.BoolValue && g_cvarRepShove.BoolValue)
	{
		if (IsValidClientInGame(attacker) && IsValidClientInGame(victim) && !IsFakeClient(victim))
			CPrintToChatAll("%t %t", "Tag+", "Shoved", attacker, victim);
		else if (IsValidClientInGame(attacker))
			CPrintToChatAll("%t %t", "Tag+", "ShovedBot", attacker);
	}

	Call_StartForward(g_hForwardSIShove);
	Call_PushCell(attacker);
	Call_PushCell(victim);
	Call_PushCell(zombieClass);
	Call_Finish();
}

// real skeet
stock void HandleSkeet(int attacker, int victim, bool bMelee = false, bool bSniper = false, bool bGL = false)
{
	// report?
	if (g_cvarReport.BoolValue && g_cvarRepSkeet.BoolValue)
	{
		if (attacker == -2)
		{
			// team skeet sets to -2
			if (IsValidClientInGame(victim) && !IsFakeClient(victim))
				CPrintToChatAll("%t %t", "Tag+", "TeamSkeeted", victim);
			else
				CPrintToChatAll("%t %t", "Tag+", "TeamSkeetedBot");
		}
		else if (IsValidClientInGame(attacker) && IsValidClientInGame(victim) && !IsFakeClient(victim))
			CPrintToChatAll("%t %t", "Tag++", "Skeeted", attacker, (bMelee) ? Melee() : ((bSniper) ? Headshot() : ((bGL) ? Grenade() : "")), victim);
		else if (IsValidClientInGame(attacker))
			CPrintToChatAll("%t %t", "Tag+", "SkeetedBot", attacker, (bMelee) ? Melee() : ((bSniper) ? Headshot() : ((bGL) ? Grenade() : "")));
	}

	// call forward
	if (bSniper)
	{
		Call_StartForward(g_hForwardSkeetSniper);
		Call_PushCell(attacker);
		Call_PushCell(victim);
		Call_Finish();
	}
	else if (bGL)
	{
		Call_StartForward(g_hForwardSkeetGL);
		Call_PushCell(attacker);
		Call_PushCell(victim);
		Call_Finish();
	}
	else if (bMelee)
	{
		Call_StartForward(g_hForwardSkeetMelee);
		Call_PushCell(attacker);
		Call_PushCell(victim);
		Call_Finish();
	}
	else
	{
		Call_StartForward(g_hForwardSkeet);
		Call_PushCell(attacker);
		Call_PushCell(victim);
		Call_Finish();
	}
}

// hurt skeet / non-skeet
//  NOTE: bSniper not set yet, do this
stock void HandleNonSkeet(int attacker, int victim, int damage, bool bOverKill = false, bool bMelee = false, bool bSniper = false)
{
	// report?
	if (g_cvarReport.BoolValue && g_cvarRepHurtSkeet.BoolValue)
	{
		char buffer[64];
		Format(buffer, sizeof(buffer), "%t", "Unchipped");
		if (IsValidClientInGame(victim))
			CPrintToChatAll("%t %t", "Tag+", "HurtSkeet", victim, damage, (bOverKill) ? buffer : "");
		else
			CPrintToChatAll("%t %t", "Tag+", "HurtSkeetBot", damage, (bOverKill) ? buffer : "");
	}

	// call forward
	if (bSniper)
	{
		Call_StartForward(g_hForwardSkeetSniperHurt);
		Call_PushCell(attacker);
		Call_PushCell(victim);
		Call_PushCell(damage);
		Call_PushCell(bOverKill);
		Call_Finish();
	}
	else if (bMelee)
	{
		Call_StartForward(g_hForwardSkeetMeleeHurt);
		Call_PushCell(attacker);
		Call_PushCell(victim);
		Call_PushCell(damage);
		Call_PushCell(bOverKill);
		Call_Finish();
	}
	else
	{
		Call_StartForward(g_hForwardSkeetHurt);
		Call_PushCell(attacker);
		Call_PushCell(victim);
		Call_PushCell(damage);
		Call_PushCell(bOverKill);
		Call_Finish();
	}
}

// crown
void HandleCrown(int attacker, int damage)
{
	// report?
	if (g_cvarReport.BoolValue && g_cvarRepCrow.BoolValue)
	{
		if (IsValidClientInGame(attacker))
			CPrintToChatAll("%t %t", "Tag++", "CrownedWitch", attacker, damage);
		else
			CPrintToChatAll("%t", "CrownedWitch2");
	}

	// call forward
	Call_StartForward(g_hForwardCrown);
	Call_PushCell(attacker);
	Call_PushCell(damage);
	Call_Finish();
}
// drawcrown
void HandleDrawCrown(int attacker, int damage, int chipdamage)
{
	// report?
	if (g_cvarReport.BoolValue && g_cvarRepDrawCrow.BoolValue)
	{
		if (IsValidClientInGame(attacker))
			CPrintToChatAll("%t %t", "Tag++", "DrawCrowned", attacker, damage, chipdamage);
		else
			CPrintToChatAll("%t %t", "DrawCrowned2", damage, chipdamage);
	}

	// call forward
	Call_StartForward(g_hForwardDrawCrown);
	Call_PushCell(attacker);
	Call_PushCell(damage);
	Call_PushCell(chipdamage);
	Call_Finish();
}

// smoker clears
void HandleTongueCut(int attacker, int victim)
{
	// report?
	if (g_cvarReport.BoolValue && g_cvarRepTongueCut.BoolValue)
	{
		if (IsValidClientInGame(attacker) && IsValidClientInGame(victim) && !IsFakeClient(victim))
			CPrintToChatAll("%t %t", "Tag+++", "CutTongue", attacker, victim);
		else if (IsValidClientInGame(attacker))
			CPrintToChatAll("%t %t", "Tag+++", "CutTongueBot", attacker);
	}

	// call forward
	Call_StartForward(g_hForwardTongueCut);
	Call_PushCell(attacker);
	Call_PushCell(victim);
	Call_Finish();
}

void HandleSmokerSelfClear(int attacker, int victim, bool withShove = false)
{
	// report?
	if (g_cvarReport.BoolValue && g_cvarRepSelfClear.BoolValue && (!withShove || g_cvarRepSelfClearShove.BoolValue))
	{
		char Buffer[64];
		Format(Buffer, sizeof(Buffer), "%t", "Shoving");

		if (IsValidClientInGame(attacker) && IsValidClientInGame(victim) && !IsFakeClient(victim))
			CPrintToChatAll("%t %t", "Tag++", "SelfClearedTongue", attacker, victim, (withShove) ? Buffer : "");
		else if (IsValidClientInGame(attacker))
			CPrintToChatAll("%t %t", "Tag++", "SelfClearedTongueBot", attacker, (withShove) ? Buffer : "");
	}

	// call forward
	Call_StartForward(g_hForwardSmokerSelfClear);
	Call_PushCell(attacker);
	Call_PushCell(victim);
	Call_PushCell(withShove);
	Call_Finish();
}

// rocks
void HandleRockEaten(int attacker, int victim)
{
	Call_StartForward(g_hForwardRockEaten);
	Call_PushCell(attacker);
	Call_PushCell(victim);
	Call_Finish();
}
void HandleRockSkeeted(int attacker, int victim)
{
	// report?
	if (g_cvarReport.BoolValue && g_cvarRepRockSkeet.BoolValue)
	{
		if (!IsValidClientInGame(attacker))
			return;

		if (g_cvarRepRockName.BoolValue && IsValidClientInGame(victim) && !IsFakeClient(victim))
			CPrintToChatAll("%t %t", "Tag+", "SkeetedRock", attacker, victim);
		else
			CPrintToChatAll("%t %t", "Tag+", "SkeetedRockBot", attacker);
	}

	Call_StartForward(g_hForwardRockSkeeted);
	Call_PushCell(attacker);
	Call_PushCell(victim);
	Call_Finish();
}

// highpounces
stock void HandleHunterDP(int attacker, int victim, int actualDamage, float calculatedDamage, float height, bool playerIncapped = false)
{
	// report?
	if (g_cvarReport.BoolValue && g_cvarRepHunterDP.BoolValue && height >= g_cvarHunterDPThresh.FloatValue && !playerIncapped)
	{
		if (IsValidClientInGame(attacker) && IsValidClientInGame(victim) && !IsFakeClient(attacker))
			CPrintToChatAll("%t %t", "Tag++", "HunterHP", attacker, victim, RoundFloat(calculatedDamage), RoundFloat(height));
		else if (IsValidClientInGame(victim))
			CPrintToChatAll("%t %t", "Tag++", "HunterHPBot", victim, RoundFloat(calculatedDamage), RoundFloat(height));
	}

	Call_StartForward(g_hForwardHunterDP);
	Call_PushCell(attacker);
	Call_PushCell(victim);
	Call_PushCell(actualDamage);
	Call_PushFloat(calculatedDamage);
	Call_PushFloat(height);
	Call_PushCell((height >= g_cvarHunterDPThresh.FloatValue) ? 1 : 0);
	Call_PushCell((playerIncapped) ? 1 : 0);
	Call_Finish();
}
stock void HandleJockeyDP(int attacker, int victim, float height)
{
	// report?
	if (g_cvarReport.BoolValue && g_cvarRepJockeyDP.BoolValue && height >= g_cvarJockeyDPThresh.FloatValue)
	{
		if (IsValidClientInGame(attacker) && IsValidClientInGame(victim) && !IsFakeClient(attacker))
			CPrintToChatAll("%t %t", "Tag+++", "JockeyHP", attacker, victim, RoundFloat(height));
		else if (IsValidClientInGame(victim))
			CPrintToChatAll("%t %t", "Tag+++", "JockeyHPBot", victim, RoundFloat(height));
	}

	Call_StartForward(g_hForwardJockeyDP);
	Call_PushCell(victim);
	Call_PushCell(attacker);
	Call_PushFloat(height);
	Call_PushCell((height >= g_cvarJockeyDPThresh.FloatValue) ? 1 : 0);
	Call_Finish();
}

// deathcharges
stock void HandleDeathCharge(int attacker, int victim, float height, float distance, bool bCarried = true)
{
	// report?
	if (g_cvarReport.BoolValue && g_cvarRepDeathCharge.BoolValue && height >= g_cvarDeathChargeHeight.FloatValue)
	{
		char Buffer[64];
		Format(Buffer, sizeof(Buffer), "%t", "Bowling");

		if (IsValidClientInGame(attacker) && IsValidClientInGame(victim) && !IsFakeClient(attacker))
			CPrintToChatAll("%t %t", "Tag++++", "DeathCharged", attacker, victim, (bCarried) ? "" : Buffer, RoundFloat(height));
		else if (IsValidClientInGame(victim))
			CPrintToChatAll("%t %t", "Tag++++", "DeathChargedBot", victim, (bCarried) ? "" : Buffer, RoundFloat(height));
	}

	Call_StartForward(g_hForwardDeathCharge);
	Call_PushCell(attacker);
	Call_PushCell(victim);
	Call_PushFloat(height);
	Call_PushFloat(distance);
	Call_PushCell((bCarried) ? 1 : 0);
	Call_Finish();
}

// SI clears    (cleartimeA = pummel/pounce/ride/choke, cleartimeB = tongue drag, charger carry)
stock void HandleClear(int attacker, int victim, int pinVictim, int zombieClass, float clearTimeA, float clearTimeB, bool bWithShove = false)
{
	// sanity check:
	if (clearTimeA < 0 && clearTimeA != -1.0)
		clearTimeA = 0.0;

	if (clearTimeB < 0 && clearTimeB != -1.0)
		clearTimeB = 0.0;

	PrintDebug("Clear: %i freed %i from %i: time: %.2f / %.2f -- class: %s (with shove? %i)", attacker, pinVictim, victim, clearTimeA, clearTimeB, g_csSIClassName[zombieClass], bWithShove);

	if (g_cvarRepInstanClear.IntValue && attacker != pinVictim)
	{
		float fMinTime	 = g_cvarInstaTime.FloatValue;
		float fClearTime = clearTimeA;
		if (zombieClass == ZC_CHARGER || zombieClass == ZC_SMOKER) { fClearTime = clearTimeB; }

		if (fClearTime != -1.0 && fClearTime <= fMinTime)
		{
			if (IsValidClientInGame(attacker) && IsValidClientInGame(victim) && !IsFakeClient(victim))
			{
				if (IsValidClientInGame(pinVictim))
					CPrintToChatAll("%t %t", "Tag+", "SIClear", attacker, pinVictim, victim, g_csSIClassName[zombieClass], fClearTime);
				else
					CPrintToChatAll("%t %t", "Tag+", "SIClearTeammate", attacker, victim, g_csSIClassName[zombieClass], fClearTime);
			}
			else if (IsValidClientInGame(attacker))
			{
				if (IsValidClientInGame(pinVictim))
					CPrintToChatAll("%t %t", "Tag+", "SIClearBot", attacker, pinVictim, g_csSIClassName[zombieClass], fClearTime);
				else
					CPrintToChatAll("%t %t", "Tag+", "SIClearTeammateBot", attacker, g_csSIClassName[zombieClass], fClearTime);
			}
		}
	}

	Call_StartForward(g_hForwardClear);
	Call_PushCell(attacker);
	Call_PushCell(victim);
	Call_PushCell(pinVictim);
	Call_PushCell(zombieClass);
	Call_PushFloat(clearTimeA);
	Call_PushFloat(clearTimeB);
	Call_PushCell((bWithShove) ? 1 : 0);
	Call_Finish();
}

// booms
stock void HandleVomitLanded(int attacker, int boomCount)
{
	Call_StartForward(g_hForwardVomitLanded);
	Call_PushCell(attacker);
	Call_PushCell(boomCount);
	Call_Finish();
}

// bhaps
stock void HandleBHopStreak(int survivor, int streak, float maxVelocity)
{
	if (g_cvarRepBhopStreak.BoolValue && IsValidClientInGame(survivor) && !IsFakeClient(survivor) && streak >= g_cvarBHopMinStreak.IntValue)
		CPrintToChat(survivor, "%t %t", "Tag+", "BunnyHop", streak, (streak > 1) ? PluralCount() : "", maxVelocity);

	Call_StartForward(g_hForwardBHopStreak);
	Call_PushCell(survivor);
	Call_PushCell(streak);
	Call_PushFloat(maxVelocity);
	Call_Finish();
}

// car alarms
stock void HandleCarAlarmTriggered(int survivor, int infected, int reason)
{
	if (g_cvarRepCarAlarm.BoolValue && IsValidClientInGame(survivor) && !IsFakeClient(survivor))
	{
		if (reason == CALARM_HIT)
			CPrintToChatAll("%t %t", "Tag+", "CalarmHit", survivor);
		else if (reason == CALARM_TOUCHED)
		{
			// if a survivor touches an alarmed car, it might be due to a special infected...
			if (IsValidInfected(infected))
			{
				if (!IsFakeClient(infected))
					CPrintToChatAll("%t %t", "Tag+", "CalarmTouched", infected, survivor);
				else
				{
					switch (GetEntProp(infected, Prop_Send, "m_zombieClass"))
					{
						case ZC_SMOKER:
							CPrintToChatAll("%t %t", "Tag+", "CalarmTouchedHunter", survivor);
						case ZC_JOCKEY:
							CPrintToChatAll("%t %t", "Tag+", "CalarmTouchedJockey", survivor);
						case ZC_CHARGER:
							CPrintToChatAll("%t %t", "Tag+", survivor);
						default:
							CPrintToChatAll("%t %t", "Tag+", "CalarmTouchedInfected", survivor);
					}
				}
			}
			else
				CPrintToChatAll("%t %t", "Tag+", "CalarmTouchedBot", survivor);
		}
		else if (reason == CALARM_EXPLOSION)
			CPrintToChatAll("%t %t", "Tag+", "CalarmExplosion", survivor);
		else if (reason == CALARM_BOOMER)
		{
			if (IsValidInfected(infected) && !IsFakeClient(infected))
				CPrintToChatAll("%t %t", "Tag+", "CalarmBoomer", survivor, infected);
			else
				CPrintToChatAll("%t %t", "Tag+", "CalarmBoomerBot", survivor);
		}
		else
			CPrintToChatAll("%t %t", "Tag+", "Calarm", survivor);
	}

	Call_StartForward(g_hForwardAlarmTriggered);
	Call_PushCell(survivor);
	Call_PushCell(infected);
	Call_PushCell(reason);
	Call_Finish();
}

char[] Melee()
{
	char sBuffer[32];
	Format(sBuffer, sizeof(sBuffer), "%t", "Melee");
	return sBuffer;
}

char[] Headshot()
{
	char sBuffer[32];
	Format(sBuffer, sizeof(sBuffer), "%t", "HeadShot");
	return sBuffer;
}

char[] Grenade()
{
	char sBuffer[32];
	Format(sBuffer, sizeof(sBuffer), "%t", "Grenade");
	return sBuffer;
}

char[] PluralCount()
{
	char sBuffer[32];
	Format(sBuffer, sizeof(sBuffer), "%t", "PluralCount");
	return sBuffer;
}

