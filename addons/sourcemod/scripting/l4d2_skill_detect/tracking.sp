#if defined _skill_detect_tracking_included
	#endinput
#endif
#define _skill_detect_tracking_included

public Action Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	g_iRocksBeingThrownCount = 0;

	for (int i = 1; i <= MaxClients; i++)
	{
		g_bIsHopping[i] = false;

		for (int j = 1; j <= MaxClients; j++)
		{
			g_fVictimLastShove[i][j] = 0.0;
		}
	}
	return Plugin_Continue;
}

public Action Event_RoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	// clean trie, new cars will be created
	ClearTrie(g_hCarTrie);
	return Plugin_Continue;
}

public Action Event_PlayerHurt(Handle event, const char[] name, bool dontBroadcast)
{
	int victim	 = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	int zClass;

	int damage	   = GetEventInt(event, "dmg_health");
	int damagetype = GetEventInt(event, "type");

	if (IsValidInfected(victim))
	{
		zClass		 = GetEntProp(victim, Prop_Send, "m_zombieClass");
		int health	 = GetEventInt(event, "health");
		int hitgroup = GetEventInt(event, "hitgroup");

		if (damage < 1)
			return Plugin_Continue;

		switch (zClass)
		{
			case ZC_HUNTER:
			{
				// if it's not a survivor doing the work, only get the remaining health
				if (!IsValidSurvivor(attacker))
				{
					g_iHunterLastHealth[victim] = health;
					return Plugin_Continue;
				}

				// if the damage done is greater than the health we know the hunter to have remaining, reduce the damage done
				if (g_iHunterLastHealth[victim] > 0 && damage > g_iHunterLastHealth[victim])
				{
					damage						= g_iHunterLastHealth[victim];
					g_iHunterOverkill[victim]	= g_iHunterLastHealth[victim] - damage;
					g_iHunterLastHealth[victim] = 0;
				}

				/*
					handle old shotgun blast: too long ago? not the same blast
				*/
				if (g_iHunterShotDmg[victim][attacker] > 0 && (GetGameTime() - g_fHunterShotStart[victim][attacker]) > SHOTGUN_BLAST_TIME)
					g_fHunterShotStart[victim][attacker] = 0.0;

				/*
					m_isAttemptingToPounce is set to 0 here if the hunter is actually skeeted
					so the g_fHunterTracePouncing[victim] value indicates when the hunter was last seen pouncing in traceattack
					(should be DIRECTLY before this event for every shot).
				*/
				bool isPouncing = view_as<bool>(GetEntProp(victim, Prop_Send, "m_isAttemptingToPounce") || g_fHunterTracePouncing[victim] != 0.0 && (GetGameTime() - g_fHunterTracePouncing[victim]) < 0.001);

				if (isPouncing)
				{
					if (damagetype & DMG_BUCKSHOT)
					{
						// first pellet hit?
						if (g_fHunterShotStart[victim][attacker] == 0.0)
						{
							// new shotgun blast
							g_fHunterShotStart[victim][attacker] = GetGameTime();
							g_fHunterLastShot[victim]			 = g_fHunterShotStart[victim][attacker];
						}
						g_iHunterShotDmg[victim][attacker] += damage;
						g_iHunterShotDmgTeam[victim] += damage;

						if (health == 0)
						{
							g_bHunterKilledPouncing[victim] = true;
						}
					}
					else if (damagetype & (DMG_BLAST | DMG_PLASMA) && health == 0)
					{
						// direct GL hit?
						/*
							direct hit is DMG_BLAST | DMG_PLASMA
							indirect hit is DMG_AIRBOAT
						*/

						char		  weaponB[32];
						strWeaponType weaponTypeB;
						GetEventString(event, "weapon", weaponB, sizeof(weaponB));

						if (GetTrieValue(g_hTrieWeapons, weaponB, weaponTypeB) && weaponTypeB == WPTYPE_GL)
						{
							if (g_cvarAllowGLSkeet.BoolValue)
								HandleSkeet(attacker, victim, false, false, true);
						}
					}
					else if (damagetype & DMG_BULLET && health == 0 && hitgroup == HITGROUP_HEAD) {
						// headshot with bullet based weapon (only single shots) -- only snipers
						char		  weaponA[32];
						strWeaponType weaponTypeA;
						GetEventString(event, "weapon", weaponA, sizeof(weaponA));

						if (GetTrieValue(g_hTrieWeapons, weaponA, weaponTypeA) && (weaponTypeA == WPTYPE_SNIPER || weaponTypeA == WPTYPE_MAGNUM))
						{
							if (damage >= g_iPounceInterrupt)
							{
								g_iHunterShotDmgTeam[victim] = 0;
								if (g_cvarAllowSniper.BoolValue)
									HandleSkeet(attacker, victim, false, true);
								
								ResetHunter(victim);
							}
							else
							{
								// hurt skeet
								if (g_cvarAllowSniper.BoolValue)
									HandleNonSkeet(attacker, victim, damage, (g_iHunterOverkill[victim] + g_iHunterShotDmgTeam[victim] > g_iPounceInterrupt), false, true);

								ResetHunter(victim);
							}
						}

						// already handled hurt skeet above
						// g_bHunterKilledPouncing[victim] = true;
					}
					else if (damagetype & DMG_SLASH || damagetype & DMG_CLUB)
					{
						// melee skeet
						if (damage >= g_iPounceInterrupt)
						{
							g_iHunterShotDmgTeam[victim] = 0;
							if (g_cvarAllowMelee.BoolValue)
								HandleSkeet(attacker, victim, true);

							ResetHunter(victim);
							// g_bHunterKilledPouncing[victim] = true;
						}
						else if (health == 0)
						{
							// hurt skeet (always overkill)
							if (g_cvarAllowMelee.BoolValue)
								HandleNonSkeet(attacker, victim, damage, true, true, false);

							ResetHunter(victim);
						}
					}
				}
				else if (health == 0)
				{
					// make sure we don't mistake non-pouncing hunters as 'not skeeted'-warnable
					g_bHunterKilledPouncing[victim] = false;
				}

				// store last health seen for next damage event
				g_iHunterLastHealth[victim] = health;
			}

			case ZC_CHARGER:
			{
				if (IsValidSurvivor(attacker))
				{
					// check for levels
					if (health == 0 && (damagetype & DMG_CLUB || damagetype & DMG_SLASH))
					{
						int iChargeHealth = g_cvarChargerHealth.IntValue;
						int abilityEnt	  = GetEntPropEnt(victim, Prop_Send, "m_customAbility");
						if (IsValidEntity(abilityEnt) && GetEntProp(abilityEnt, Prop_Send, "m_isCharging"))
						{
							// fix fake damage?
							if (g_cvarHideFakeDamage.BoolValue)
								damage = iChargeHealth - g_iChargerHealth[victim];

							// charger was killed, was it a full level?
							if (damage > (iChargeHealth * 0.65))
								HandleLevel(attacker, victim);
							else
								HandleLevelHurt(attacker, victim, damage);
						}
					}
				}

				// store health for next damage it takes
				if (health > 0)
					g_iChargerHealth[victim] = health;
			}

			case ZC_SMOKER:
			{
				if (!IsValidSurvivor(attacker))
					return Plugin_Continue;
				g_iSmokerVictimDamage[victim] += damage;
			}
		}
	}
	else if (IsValidInfected(attacker))
	{
		zClass = GetEntProp(attacker, Prop_Send, "m_zombieClass");

		switch (zClass)
		{
			case ZC_HUNTER:
			{
				// a hunter pounce landing is DMG_CRUSH
				if (damagetype & DMG_CRUSH)
					g_iPounceDamage[attacker] = damage;
			}

			case ZC_TANK:
			{
				char weapon[10];
				GetEventString(event, "weapon", weapon, sizeof(weapon));

				if (StrEqual(weapon, "tank_rock"))
				{
					// find rock entity through tank
					if (g_iTankRock[attacker])
					{
						// remember that the rock wasn't shot
						char rock_key[10];
						FormatEx(rock_key, sizeof(rock_key), "%x", g_iTankRock[attacker]);
						int rock_array[3];
						rock_array[rckDamage] = -1;
						SetTrieArray(g_hRockTrie, rock_key, rock_array, sizeof(rock_array), true);
					}

					if (IsValidSurvivor(victim))
						HandleRockEaten(attacker, victim);
				}
				return Plugin_Continue;
			}
		}
	}

	// check for deathcharge flags
	if (IsValidSurvivor(victim))
	{
		// debug
		if (damagetype & DMG_DROWN || damagetype & DMG_FALL)
			g_iVictimMapDmg[victim] += damage;

		if (damagetype & DMG_DROWN && damage >= MIN_DC_TRIGGER_DMG)
			g_iVictimFlags[victim] = g_iVictimFlags[victim] | VICFLG_HURTLOTS;
		else if (damagetype & DMG_FALL && damage >= MIN_DC_FALL_DMG)
			g_iVictimFlags[victim] = g_iVictimFlags[victim] | VICFLG_HURTLOTS;
	}

	return Plugin_Continue;
}

public Action Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsValidInfected(client))
		return Plugin_Continue;
	int zClass			  = GetEntProp(client, Prop_Send, "m_zombieClass");

	g_fSpawnTime[client]  = GetGameTime();
	g_fPinTime[client][0] = 0.0;
	g_fPinTime[client][1] = 0.0;

	switch (zClass)
	{
		case ZC_BOOMER:
		{
			g_bBoomerHitSomebody[client] = false;
			g_iBoomerGotShoved[client]	 = 0;
		}
		case ZC_SMOKER:
		{
			g_bSmokerClearCheck[client]	  = false;
			g_iSmokerVictim[client]		  = 0;
			g_iSmokerVictimDamage[client] = 0;
		}
		case ZC_HUNTER:
		{
			SDKHook(client, SDKHook_TraceAttack, TraceAttack_Hunter);

			g_fPouncePosition[client][0] = 0.0;
			g_fPouncePosition[client][1] = 0.0;
			g_fPouncePosition[client][2] = 0.0;
		}
		case ZC_JOCKEY:
		{
			SDKHook(client, SDKHook_TraceAttack, TraceAttack_Jockey);

			g_fPouncePosition[client][0] = 0.0;
			g_fPouncePosition[client][1] = 0.0;
			g_fPouncePosition[client][2] = 0.0;
		}
		case ZC_CHARGER:
		{
			SDKHook(client, SDKHook_TraceAttack, TraceAttack_Charger);

			g_iChargerHealth[client] = g_cvarChargerHealth.IntValue;
		}
	}

	return Plugin_Continue;
}

// player about to get incapped
public Action Event_IncapStart(Handle event, const char[] name, bool dontBroadcast)
{
	// test for deathcharges

	int	   client	 = GetClientOfUserId(GetEventInt(event, "userid"));
	// int attacker = GetClientOfUserId( GetEventInt(event, "attacker") );
	int	   attackent = GetEventInt(event, "attackerentid");
	int	   dmgtype	 = GetEventInt(event, "type");

	char   classname[24];
	strOEC classnameOEC;
	if (IsValidEntity(attackent))
	{
		GetEdictClassname(attackent, classname, sizeof(classname));
		if (GetTrieValue(g_hTrieEntityCreated, classname, classnameOEC))
		{
			g_iVictimFlags[client] = g_iVictimFlags[client] | VICFLG_TRIGGER;
		}
	}

	float flow = GetSurvivorDistance(client);
	// PrintDebug("Incap Pre on [%N]: attk: %i / %i (%s) - dmgtype: %i - flow: %.1f", client, attacker, attackent, classname, dmgtype, flow );

	// drown is damage type
	if (dmgtype & DMG_DROWN)
		g_iVictimFlags[client] = g_iVictimFlags[client] | VICFLG_DROWN;

	if (flow < WEIRD_FLOW_THRESH)
		g_iVictimFlags[client] = g_iVictimFlags[client] | VICFLG_WEIRDFLOW;

	return Plugin_Continue;
}

// trace attacks on hunters
public Action TraceAttack_Hunter(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& ammotype, int hitbox, int hitgroup)
{
	// track pinning
	g_iSpecialVictim[victim] = GetEntPropEnt(victim, Prop_Send, "m_pounceVictim");

	if (!IsValidSurvivor(attacker) || !IsValidEdict(inflictor))
		return Plugin_Continue;

	// track flight
	if (GetEntProp(victim, Prop_Send, "m_isAttemptingToPounce"))
		g_fHunterTracePouncing[victim] = GetGameTime();
	else
		g_fHunterTracePouncing[victim] = 0.0;

	return Plugin_Continue;
}

public Action TraceAttack_Charger(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& ammotype, int hitbox, int hitgroup)
{
	// track pinning
	int victimA = GetEntPropEnt(victim, Prop_Send, "m_carryVictim");

	if (victimA != -1)
		g_iSpecialVictim[victim] = victimA;
	else
		g_iSpecialVictim[victim] = GetEntPropEnt(victim, Prop_Send, "m_pummelVictim");

	return Plugin_Continue;
}

public Action TraceAttack_Jockey(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& ammotype, int hitbox, int hitgroup)
{
	// track pinning
	g_iSpecialVictim[victim] = GetEntPropEnt(victim, Prop_Send, "m_jockeyVictim");
	return Plugin_Continue;
}

public Action Event_PlayerDeath(Handle hEvent, const char[] name, bool dontBroadcast)
{
	int victim	 = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));

	if (IsValidInfected(victim))
	{
		int zClass = GetEntProp(victim, Prop_Send, "m_zombieClass");

		switch (zClass)
		{
			case ZC_HUNTER:
			{
				if (!IsValidSurvivor(attacker))
					return Plugin_Continue;

				if (g_iHunterShotDmgTeam[victim] > 0 && g_bHunterKilledPouncing[victim])
				{
					// skeet?
					if (g_iHunterShotDmgTeam[victim] > g_iHunterShotDmg[victim][attacker] && g_iHunterShotDmgTeam[victim] >= g_iPounceInterrupt)
						// team skeet
						HandleSkeet(-2, victim);
					else if (g_iHunterShotDmg[victim][attacker] >= g_iPounceInterrupt)
						// single player skeet
						HandleSkeet(attacker, victim);
					else if (g_iHunterOverkill[victim] > 0)
						// overkill? might've been a skeet, if it wasn't on a hurt hunter (only for shotguns)
						HandleNonSkeet(attacker, victim, g_iHunterShotDmgTeam[victim], (g_iHunterOverkill[victim] + g_iHunterShotDmgTeam[victim] > g_iPounceInterrupt));
					else
						// not a skeet at all
						HandleNonSkeet(attacker, victim, g_iHunterShotDmg[victim][attacker]);
				}
				else 
				{
					// check whether it was a clear
					if (g_iSpecialVictim[victim] > 0)
						HandleClear(attacker, victim, g_iSpecialVictim[victim], ZC_HUNTER, (GetGameTime() - g_fPinTime[victim][0]), -1.0);
				}

				ResetHunter(victim);
			}

			case ZC_SMOKER:
			{
				if (!IsValidSurvivor(attacker))
					return Plugin_Continue;

				if (g_bSmokerClearCheck[victim] && g_iSmokerVictim[victim] == attacker && g_iSmokerVictimDamage[victim] >= g_cvarSelfClearThresh.IntValue)
					HandleSmokerSelfClear(attacker, victim);
				else
				{
					g_bSmokerClearCheck[victim] = false;
					g_iSmokerVictim[victim]		= 0;
				}
			}

			case ZC_JOCKEY:
			{
				// check whether it was a clear
				if (g_iSpecialVictim[victim] > 0)
					HandleClear(attacker, victim, g_iSpecialVictim[victim], ZC_JOCKEY, (GetGameTime() - g_fPinTime[victim][0]), -1.0);
			}

			case ZC_CHARGER:
			{
				// is it someone carrying a survivor (that might be DC'd)?
				// switch charge victim to 'impact' check (reset checktime)
				if (IsValidClientInGame(g_iChargeVictim[victim]))
					g_fChargeTime[g_iChargeVictim[victim]] = GetGameTime();

				// check whether it was a clear
				if (g_iSpecialVictim[victim] > 0)
					HandleClear(attacker, victim, g_iSpecialVictim[victim], ZC_CHARGER, (g_fPinTime[victim][1] > 0.0) ? (GetGameTime() - g_fPinTime[victim][1]) : -1.0, (GetGameTime() - g_fPinTime[victim][0]));
			}
		}
	}
	else if (IsValidSurvivor(victim))
	{
		// check for deathcharges
		// new atkent = GetEventInt(hEvent, "attackerentid");
		int dmgtype = GetEventInt(hEvent, "type");

		// PrintDebug("Died [%N]: attk: %i / %i - dmgtype: %i", victim, attacker, atkent, dmgtype );

		if (dmgtype & DMG_FALL)
			g_iVictimFlags[victim] = g_iVictimFlags[victim] | VICFLG_FALL;
		else if (IsValidInfected(attacker) && attacker != g_iVictimCharger[victim])
			// if something other than the charger killed them, remember (not a DC)
			g_iVictimFlags[victim] = g_iVictimFlags[victim] | VICFLG_KILLEDBYOTHER;
	}

	return Plugin_Continue;
}

public Action Event_PlayerShoved(Handle event, const char[] name, bool dontBroadcast)
{
	int victim	 = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	PrintDebug("Shove from %i on %i", attacker, victim);

	if (!IsValidSurvivor(attacker) || !IsValidInfected(victim))
		return Plugin_Continue;

	int zClass = GetEntProp(victim, Prop_Send, "m_zombieClass");
	PrintDebug(" --> Shove from %N on %N (class: %i) -- (last shove time: %.2f / %.2f)", attacker, victim, zClass, g_fVictimLastShove[victim][attacker], ( GetGameTime() - g_fVictimLastShove[victim][attacker] ) );

	// track on boomers
	if (zClass == ZC_BOOMER)
		g_iBoomerGotShoved[victim]++;
	else 
	{
		// check for clears
		switch (zClass)
		{
			case ZC_HUNTER:
			{
				if (GetEntPropEnt(victim, Prop_Send, "m_pounceVictim") > 0)
					HandleClear(attacker, victim, GetEntPropEnt(victim, Prop_Send, "m_pounceVictim"), ZC_HUNTER, (GetGameTime() - g_fPinTime[victim][0]), -1.0, true);
			}
			case ZC_JOCKEY:
			{
				if (GetEntPropEnt(victim, Prop_Send, "m_jockeyVictim") > 0)
					HandleClear(attacker, victim, GetEntPropEnt(victim, Prop_Send, "m_jockeyVictim"), ZC_JOCKEY, (GetGameTime() - g_fPinTime[victim][0]), -1.0, true);
			}
		}
	}

	if (g_fVictimLastShove[victim][attacker] == 0.0 || (GetGameTime() - g_fVictimLastShove[victim][attacker]) >= SHOVE_TIME)
	{
		if (GetEntProp(victim, Prop_Send, "m_isAttemptingToPounce"))
			HandleDeadstop(attacker, victim);

		HandleShove(attacker, victim, zClass);
		g_fVictimLastShove[victim][attacker] = GetGameTime();
	}

	// check for shove on smoker by pull victim
	if (g_iSmokerVictim[victim] == attacker)
		g_bSmokerShoved[victim] = true;

	PrintDebug("shove by %i on %i", attacker, victim );
	return Plugin_Continue;
}

public Action Event_LungePounce(Handle event, const char[] name, bool dontBroadcast)
{
	int client			  = GetClientOfUserId(GetEventInt(event, "userid"));
	int victim			  = GetClientOfUserId(GetEventInt(event, "victim"));

	g_fPinTime[client][0] = GetGameTime();

	// clear hunter-hit stats (not skeeted)
	ResetHunter(client);

	// check if it was a DP
	// ignore if no real pounce start pos
	if (g_fPouncePosition[client][0] == 0.0
		&& g_fPouncePosition[client][1] == 0.0
		&& g_fPouncePosition[client][2] == 0.0)
	{
		return Plugin_Continue;
	}

	float endPos[3];
	GetClientAbsOrigin(client, endPos);
	float fHeight  = g_fPouncePosition[client][2] - endPos[2];

	// from pounceannounce:
	// distance supplied isn't the actual 2d vector distance needed for damage calculation. See more about it at
	// http://forums.alliedmods.net/showthread.php?t=93207

	float fMin	   = g_cvarMinPounceDistance.FloatValue;
	float fMax	   = g_cvarMaxPounceDistance.FloatValue;
	float fMaxDmg  = g_cvarMaxPounceDamage.FloatValue;

	// calculate 2d distance between previous position and pounce position
	int	  distance = RoundToNearest(GetVectorDistance(g_fPouncePosition[client], endPos));

	// get damage using hunter damage formula
	// check if this is accurate, seems to differ from actual damage done!
	float fDamage  = (((float(distance) - fMin) / (fMax - fMin)) * fMaxDmg) + 1.0;

	// apply bounds
	if (fDamage < 0.0)
		fDamage = 0.0;
	else if (fDamage > fMaxDmg + 1.0) 
		fDamage = fMaxDmg + 1.0;

	Handle pack = CreateDataPack();
	WritePackCell(pack, client);
	WritePackCell(pack, victim);
	WritePackFloat(pack, fDamage);
	WritePackFloat(pack, fHeight);
	CreateTimer(0.05, Timer_HunterDP, pack);

	return Plugin_Continue;
}

public Action Timer_HunterDP(Handle timer, Handle pack)
{
	ResetPack(pack);
	int	  client  = ReadPackCell(pack);
	int	  victim  = ReadPackCell(pack);
	float fDamage = ReadPackFloat(pack);
	float fHeight = ReadPackFloat(pack);
	CloseHandle(pack);

	HandleHunterDP(client, victim, g_iPounceDamage[client], fDamage, fHeight);
	return Plugin_Continue;
}

public Action Event_PlayerJumped(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (IsValidInfected(client))
	{
		int zClass = GetEntProp(client, Prop_Send, "m_zombieClass");
		if (zClass != ZC_JOCKEY)
			return Plugin_Continue;
		// where did jockey jump from?
		GetClientAbsOrigin(client, g_fPouncePosition[client]);
	}
	else if (IsValidSurvivor(client))
	{
		// could be the start or part of a hopping streak

		float fPos[3];
		float fVel[3];
		GetClientAbsOrigin(client, fPos);
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVel);
		fVel[2] = 0.0;	  // safeguard

		float fLengthNew;
		float fLengthOld;
		fLengthNew			= GetVectorLength(fVel);

		g_bHopCheck[client] = false;

		if (!g_bIsHopping[client])
		{
			if (fLengthNew >= g_cvarBHopMinInitSpeed.FloatValue)
			{
				// starting potential hop streak
				g_fHopTopVelocity[client] = fLengthNew;
				g_bIsHopping[client]	  = true;
				g_iHops[client]			  = 0;
			}
		}
		else
		{
			// check for hopping streak
			fLengthOld = GetVectorLength(g_fLastHop[client]);

			// if they picked up speed, count it as a hop, otherwise, we're done hopping
			if (fLengthNew - fLengthOld > HOP_ACCEL_THRESH || fLengthNew >= g_cvarBHopContSpeed.FloatValue)
			{
				g_iHops[client]++;

				// this should always be the case...
				if (fLengthNew > g_fHopTopVelocity[client])
				{
					g_fHopTopVelocity[client] = fLengthNew;
				}

				// PrintToChat( client, "bunnyhop %i: speed: %.1f / increase: %.1f", g_iHops[client], fLengthNew, fLengthNew - fLengthOld );
			}
			else
			{
				g_bIsHopping[client] = false;

				if (g_iHops[client])
				{
					HandleBHopStreak(client, g_iHops[client], g_fHopTopVelocity[client]);
					g_iHops[client] = 0;
				}
			}
		}

		g_fLastHop[client][0] = fVel[0];
		g_fLastHop[client][1] = fVel[1];
		g_fLastHop[client][2] = fVel[2];

		if (g_iHops[client] != 0)
		{
			// check when the player returns to the ground
			CreateTimer(HOP_CHECK_TIME, Timer_CheckHop, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		}
	}

	return Plugin_Continue;
}

public Action Timer_CheckHop(Handle timer, any client)
{
	// player back to ground = end of hop (streak)?

	if (!IsValidClientInGame(client) || !IsPlayerAlive(client))
	{
		// streak stopped by dying / teamswitch / disconnect?
		return Plugin_Stop;
	}
	else if (GetEntityFlags(client) & FL_ONGROUND)
	{
		float fVel[3];
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVel);
		fVel[2]				= 0.0;	  // safeguard

		// PrintToChatAll("grounded %i: vel length: %.1f", client, GetVectorLength(fVel) );

		g_bHopCheck[client] = true;

		CreateTimer(HOPEND_CHECK_TIME, Timer_CheckHopStreak, client, TIMER_FLAG_NO_MAPCHANGE);

		return Plugin_Stop;
	}

	return Plugin_Continue;
}

public Action Timer_CheckHopStreak(Handle timer, any client)
{
	if (!IsValidClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Continue;

	// check if we have any sort of hop streak, and report
	if (g_bHopCheck[client] && g_iHops[client])
	{
		HandleBHopStreak(client, g_iHops[client], g_fHopTopVelocity[client]);
		g_bIsHopping[client]	  = false;
		g_iHops[client]			  = 0;
		g_fHopTopVelocity[client] = 0.0;
	}

	g_bHopCheck[client] = false;

	return Plugin_Continue;
}

public Action Event_PlayerJumpApex(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (g_bIsHopping[client])
	{
		float fVel[3];
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVel);
		fVel[2]		  = 0.0;
		float fLength = GetVectorLength(fVel);

		if (fLength > g_fHopTopVelocity[client])
		{
			g_fHopTopVelocity[client] = fLength;
		}
	}
	return Plugin_Continue;
}

public Action Event_JockeyRide(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int victim = GetClientOfUserId(GetEventInt(event, "victim"));

	if (!IsValidInfected(client) || !IsValidSurvivor(victim))
		return Plugin_Continue;
	g_fPinTime[client][0] = GetGameTime();

	// minimum distance travelled?
	// ignore if no real pounce start pos
	if (g_fPouncePosition[client][0] == 0.0 && g_fPouncePosition[client][1] == 0.0 && g_fPouncePosition[client][2] == 0.0)
		return Plugin_Continue;
	float endPos[3];
	GetClientAbsOrigin(client, endPos);
	float fHeight = g_fPouncePosition[client][2] - endPos[2];

	// PrintToChatAll("jockey height: %.3f", fHeight);

	// (high) pounce
	HandleJockeyDP(client, victim, fHeight);

	return Plugin_Continue;
}

public Action Event_AbilityUse(Handle event, const char[] name, bool dontBroadcast)
{
	// track hunters pouncing
	int	 client = GetClientOfUserId(GetEventInt(event, "userid"));
	char abilityName[64];
	GetEventString(event, "ability", abilityName, sizeof(abilityName));

	if (!IsValidClientInGame(client))
		return Plugin_Continue;

	strAbility ability;
	if (!GetTrieValue(g_hTrieAbility, abilityName, ability))
		return Plugin_Continue;

	switch (ability)
	{
		case ABL_HUNTERLUNGE:
		{
			// hunter started a pounce
			ResetHunter(client);
			GetClientAbsOrigin(client, g_fPouncePosition[client]);
		}

		case ABL_ROCKTHROW:
		{
			// tank throws rock
			g_iRocksBeingThrown[g_iRocksBeingThrownCount] = client;

			// safeguard
			if (g_iRocksBeingThrownCount < 9) { g_iRocksBeingThrownCount++; }
		}
	}

	return Plugin_Continue;
}

// charger carrying
public Action Event_ChargeCarryStart(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int victim = GetClientOfUserId(GetEventInt(event, "victim"));

	if (!IsValidInfected(client))
		return Plugin_Continue;

	PrintDebug("Charge carry start: %i - %i -- time: %.2f", client, victim, GetGameTime());

	g_fChargeTime[client] = GetGameTime();
	g_fPinTime[client][0] = g_fChargeTime[client];
	g_fPinTime[client][1] = 0.0;

	if (!IsValidSurvivor(victim))
		return Plugin_Continue;

	g_iChargeVictim[client]	 = victim;			  // store who we're carrying (as long as this is set, it's not considered an impact charge flight)
	g_iVictimCharger[victim] = client;			  // store who's charging whom
	g_iVictimFlags[victim]	 = VICFLG_CARRIED;	  // reset flags for checking later - we know only this now
	g_fChargeTime[victim]	 = g_fChargeTime[client];
	g_iVictimMapDmg[victim]	 = 0;

	GetClientAbsOrigin(victim, g_fChargeVictimPos[victim]);

	// CreateTimer( CHARGE_CHECK_TIME, Timer_ChargeCheck, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE );
	CreateTimer(CHARGE_CHECK_TIME, Timer_ChargeCheck, victim, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

public Action Event_ChargeImpact(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int victim = GetClientOfUserId(GetEventInt(event, "victim"));

	if (!IsValidInfected(client) || !IsValidSurvivor(victim))
		return Plugin_Continue;

	// remember how many people the charger bumped into, and who, and where they were
	GetClientAbsOrigin(victim, g_fChargeVictimPos[victim]);

	g_iVictimCharger[victim] = client;			 // store who we've bumped up
	g_iVictimFlags[victim]	 = 0;				 // reset flags for checking later
	g_fChargeTime[victim]	 = GetGameTime();	 // store time per victim, for impacts
	g_iVictimMapDmg[victim]	 = 0;

	CreateTimer(CHARGE_CHECK_TIME, Timer_ChargeCheck, victim, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

public Action Event_ChargePummelStart(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!IsValidInfected(client))
		return Plugin_Continue;

	g_fPinTime[client][1] = GetGameTime();
	return Plugin_Continue;
}

public Action Event_ChargeCarryEnd(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (client < 1 || client > MaxClients)
		return Plugin_Continue;

	g_fPinTime[client][1] = GetGameTime();

	// delay so we can check whether charger died 'mid carry'
	CreateTimer(0.1, Timer_ChargeCarryEnd, client, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

public Action Timer_ChargeCarryEnd(Handle timer, any client)
{
	// set charge time to 0 to avoid deathcharge timer continuing
	g_iChargeVictim[client] = 0;	// unset this so the repeated timer knows to stop for an ongroundcheck
	return Plugin_Continue;
}

public Action Timer_ChargeCheck(Handle timer, any client)
{
	// if something went wrong with the survivor or it was too long ago, forget about it
	if (!IsValidSurvivor(client) || !g_iVictimCharger[client] || g_fChargeTime[client] == 0.0 || (GetGameTime() - g_fChargeTime[client]) > MAX_CHARGE_TIME)
		return Plugin_Stop;

	// we're done checking if either the victim reached the ground, or died
	if (!IsPlayerAlive(client))
	{
		// player died (this was .. probably.. a death charge)
		g_iVictimFlags[client] = g_iVictimFlags[client] | VICFLG_AIRDEATH;

		// check conditions now
		CreateTimer(0.0, Timer_DeathChargeCheck, client, TIMER_FLAG_NO_MAPCHANGE);

		return Plugin_Stop;
	}
	else if (GetEntityFlags(client) & FL_ONGROUND && g_iChargeVictim[g_iVictimCharger[client]] != client)
	{
		// survivor reached the ground and didn't die (yet)
		// the client-check condition checks whether the survivor is still being carried by the charger
		//      (in which case it doesn't matter that they're on the ground)

		// check conditions with small delay (to see if they still die soon)
		CreateTimer(CHARGE_END_CHECK, Timer_DeathChargeCheck, client, TIMER_FLAG_NO_MAPCHANGE);

		return Plugin_Stop;
	}

	return Plugin_Continue;
}

public Action Timer_DeathChargeCheck(Handle timer, any client)
{
	if (!IsValidClientInGame(client))
		return Plugin_Continue;

	// check conditions.. if flags match up, it's a DC
	PrintDebug("Checking charge victim: %i - %i - flags: %i (alive? %i)", g_iVictimCharger[client], client, g_iVictimFlags[client], IsPlayerAlive(client));

	int flags = g_iVictimFlags[client];

	if (!IsPlayerAlive(client))
	{
		float pos[3];
		GetClientAbsOrigin(client, pos);
		float fHeight = g_fChargeVictimPos[client][2] - pos[2];

		/*
			it's a deathcharge when:
				the survivor is dead AND
					they drowned/fell AND took enough damage or died in mid-air
					AND not killed by someone else
					OR is in an unreachable spot AND dropped at least X height
					OR took plenty of map damage

			old.. need?
				fHeight > g_cvarDeathChargeHeight.FloatValue
		*/
		if (((flags & VICFLG_DROWN || flags & VICFLG_FALL) && (flags & VICFLG_HURTLOTS || flags & VICFLG_AIRDEATH) || (flags & VICFLG_WEIRDFLOW && fHeight >= MIN_FLOWDROPHEIGHT) || g_iVictimMapDmg[client] >= MIN_DC_TRIGGER_DMG) && !(flags & VICFLG_KILLEDBYOTHER))
			HandleDeathCharge(g_iVictimCharger[client], client, fHeight, GetVectorDistance(g_fChargeVictimPos[client], pos, false), view_as<bool>(flags & VICFLG_CARRIED));
	}
	else if ((flags & VICFLG_WEIRDFLOW || g_iVictimMapDmg[client] >= MIN_DC_RECHECK_DMG) && !(flags & VICFLG_WEIRDFLOWDONE)) {
		// could be incapped and dying more slowly
		// flag only gets set on preincap, so don't need to check for incap
		g_iVictimFlags[client] = g_iVictimFlags[client] | VICFLG_WEIRDFLOWDONE;

		CreateTimer(CHARGE_END_RECHECK, Timer_DeathChargeCheck, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Continue;
}

stock void ResetHunter(int client)
{
	g_iHunterShotDmgTeam[client] = 0;

	for (int i = 1; i <= MaxClients; i++)
	{
		g_iHunterShotDmg[client][i]	  = 0;
		g_fHunterShotStart[client][i] = 0.0;
	}
	g_iHunterOverkill[client] = 0;
}

// entity creation
public void OnEntityCreated(int entity, const char[] classname)
{
	if (entity < 1 || !IsValidEntity(entity) || !IsValidEdict(entity))
		return;
	// track infected / witches, so damage on them counts as hits

	strOEC classnameOEC;
	if (!GetTrieValue(g_hTrieEntityCreated, classname, classnameOEC))
		return;

	switch (classnameOEC)
	{
		case OEC_TANKROCK:
		{
			char rock_key[10];
			FormatEx(rock_key, sizeof(rock_key), "%x", entity);
			int rock_array[3];

			// store which tank is throwing what rock
			int tank = ShiftTankThrower();

			if (IsValidClientInGame(tank))
			{
				g_iTankRock[tank]	= entity;
				rock_array[rckTank] = tank;
			}
			SetTrieArray(g_hRockTrie, rock_key, rock_array, sizeof(rock_array), true);

			SDKHook(entity, SDKHook_TraceAttack, TraceAttack_Rock);
			SDKHook(entity, SDKHook_Touch, OnTouch_Rock);
		}

		case OEC_CARALARM:
		{
			char car_key[10];
			FormatEx(car_key, sizeof(car_key), "%x", entity);

			SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage_Car);
			SDKHook(entity, SDKHook_Touch, OnTouch_Car);

			SDKHook(entity, SDKHook_Spawn, OnEntitySpawned_CarAlarm);
		}

		case OEC_CARGLASS:
		{
			SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage_CarGlass);
			SDKHook(entity, SDKHook_Touch, OnTouch_CarGlass);

			// SetTrieValue(g_hCarTrie, car_key, );
			SDKHook(entity, SDKHook_Spawn, OnEntitySpawned_CarAlarmGlass);
		}
	}
}

public void OnEntitySpawned_CarAlarm(int entity)
{
	if (!IsValidEntity(entity))
		return;
	char car_key[10];
	FormatEx(car_key, sizeof(car_key), "%x", entity);

	char target[48];
	GetEntPropString(entity, Prop_Data, "m_iName", target, sizeof(target));

	SetTrieValue(g_hCarTrie, target, entity);
	SetTrieValue(g_hCarTrie, car_key, 0);	 // who shot the car?

	HookSingleEntityOutput(entity, "OnCarAlarmStart", Hook_CarAlarmStart);
}

public void OnEntitySpawned_CarAlarmGlass(int entity)
{
	if (!IsValidEntity(entity))
		return;
	// glass is parented to a car, link the two through the trie
	// find parent and save both
	char car_key[10];
	FormatEx(car_key, sizeof(car_key), "%x", entity);

	char parent[48];
	GetEntPropString(entity, Prop_Data, "m_iParent", parent, sizeof(parent));
	int parentEntity;

	// find targetname in trie
	if (GetTrieValue(g_hCarTrie, parent, parentEntity))
	{
		// if valid entity, save the parent entity
		if (IsValidEntity(parentEntity))
		{
			SetTrieValue(g_hCarTrie, car_key, parentEntity);

			char car_key_p[10];
			FormatEx(car_key_p, sizeof(car_key_p), "%x_A", parentEntity);
			int testEntity;

			if (GetTrieValue(g_hCarTrie, car_key_p, testEntity))
				// second glass
				FormatEx(car_key_p, sizeof(car_key_p), "%x_B", parentEntity);

			SetTrieValue(g_hCarTrie, car_key_p, entity);
		}
	}
}

// entity destruction
public void OnEntityDestroyed(int entity)
{
	char witch_key[10];
	FormatEx(witch_key, sizeof(witch_key), "%x", entity);

	int rock_array[3];
	if (GetTrieArray(g_hRockTrie, witch_key, rock_array, sizeof(rock_array)))
	{
		// tank rock
		CreateTimer(ROCK_CHECK_TIME, Timer_CheckRockSkeet, entity);
		SDKUnhook(entity, SDKHook_TraceAttack, TraceAttack_Rock);
		return;
	}

	int witch_array[MAXPLAYERS + DMGARRAYEXT];
	if (GetTrieArray(g_hWitchTrie, witch_key, witch_array, sizeof(witch_array)))
	{
		// witch
		//  delayed deletion, to avoid potential problems with crowns not detecting
		CreateTimer(WITCH_DELETE_TIME, Timer_WitchKeyDelete, entity);
		SDKUnhook(entity, SDKHook_OnTakeDamagePost, OnTakeDamagePost_Witch);
		return;
	}
}

public Action Timer_WitchKeyDelete(Handle timer, any witch)
{
	char witch_key[10];
	FormatEx(witch_key, sizeof(witch_key), "%x", witch);
	RemoveFromTrie(g_hWitchTrie, witch_key);
	return Plugin_Continue;
}

public Action Timer_CheckRockSkeet(Handle timer, any rock)
{
	int	 rock_array[3];
	char rock_key[10];
	FormatEx(rock_key, sizeof(rock_key), "%x", rock);

	if (!GetTrieArray(g_hRockTrie, rock_key, rock_array, sizeof(rock_array)))
		return Plugin_Continue;

	RemoveFromTrie(g_hRockTrie, rock_key);

	// if rock didn't hit anyone / didn't touch anything, it was shot
	if (rock_array[rckDamage] > 0)
		HandleRockSkeeted(rock_array[rckSkeeter], rock_array[rckTank]);

	return Plugin_Continue;
}

// boomer got somebody
public Action Event_PlayerBoomed(Handle event, const char[] name, bool dontBroadcast)
{
	int	 attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	bool byBoom	  = GetEventBool(event, "by_boomer");

	if (byBoom && IsValidInfected(attacker))
	{
		g_bBoomerHitSomebody[attacker] = true;

		// check if it was vomit spray
		bool byExplosion			   = GetEventBool(event, "exploded");
		if (!byExplosion)
		{
			// count amount of booms
			if (!g_iBoomerVomitHits[attacker])
				// check for boom count later
				CreateTimer(VOMIT_DURATION_TIME, Timer_BoomVomitCheck, attacker, TIMER_FLAG_NO_MAPCHANGE);

			g_iBoomerVomitHits[attacker]++;
		}
	}
	return Plugin_Continue;
}

// check how many booms landed
public Action Timer_BoomVomitCheck(Handle timer, any client)
{
	HandleVomitLanded(client, g_iBoomerVomitHits[client]);
	g_iBoomerVomitHits[client] = 0;
	return Plugin_Continue;
}

// boomers that didn't bile anyone
public Action Event_BoomerExploded(Handle event, const char[] name, bool dontBroadcast)
{
	int	 client = GetClientOfUserId(GetEventInt(event, "userid"));
	bool biled	= GetEventBool(event, "splashedbile");
	if (!biled && !g_bBoomerHitSomebody[client])
	{
		int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		if (IsValidSurvivor(attacker))
			HandlePop(attacker, client, g_iBoomerGotShoved[client], (GetGameTime() - g_fSpawnTime[client]));
	}
	return Plugin_Continue;
}

// crown tracking
public Action Event_WitchSpawned(Handle event, const char[] name, bool dontBroadcast)
{
	int witch = GetEventInt(event, "witchid");

	SDKHook(witch, SDKHook_OnTakeDamagePost, OnTakeDamagePost_Witch);

	int	 witch_dmg_array[MAXPLAYERS + DMGARRAYEXT];
	char witch_key[10];
	FormatEx(witch_key, sizeof(witch_key), "%x", witch);
	witch_dmg_array[MAXPLAYERS + WTCH_HEALTH] = g_cvarWitchHealth.IntValue;
	SetTrieArray(g_hWitchTrie, witch_key, witch_dmg_array, MAXPLAYERS + DMGARRAYEXT, false);
	return Plugin_Continue;
}

public Action Event_WitchKilled(Handle event, const char[] name, bool dontBroadcast)
{
	int witch	 = GetEventInt(event, "witchid");
	int attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	SDKUnhook(witch, SDKHook_OnTakeDamagePost, OnTakeDamagePost_Witch);

	if (!IsValidSurvivor(attacker))
		return Plugin_Continue;

	bool   bOneShot = GetEventBool(event, "oneshot");

	// is it a crown / drawcrown?
	Handle pack		= CreateDataPack();
	WritePackCell(pack, attacker);
	WritePackCell(pack, witch);
	WritePackCell(pack, (bOneShot) ? 1 : 0);
	CreateTimer(WITCH_CHECK_TIME, Timer_CheckWitchCrown, pack);

	return Plugin_Continue;
}

public Action Event_WitchHarasserSet(Handle event, const char[] name, bool dontBroadcast)
{
	int	 witch = GetEventInt(event, "witchid");

	char witch_key[10];
	FormatEx(witch_key, sizeof(witch_key), "%x", witch);
	int witch_dmg_array[MAXPLAYERS + DMGARRAYEXT];

	if (!GetTrieArray(g_hWitchTrie, witch_key, witch_dmg_array, MAXPLAYERS + DMGARRAYEXT))
	{
		for (int i = 0; i <= MAXPLAYERS; i++)
		{
			witch_dmg_array[i] = 0;
		}
		witch_dmg_array[MAXPLAYERS + WTCH_HEALTH]	= g_cvarWitchHealth.IntValue;
		witch_dmg_array[MAXPLAYERS + WTCH_STARTLED] = 1;	// harasser set
		SetTrieArray(g_hWitchTrie, witch_key, witch_dmg_array, MAXPLAYERS + DMGARRAYEXT, false);
	}
	else
	{
		witch_dmg_array[MAXPLAYERS + WTCH_STARTLED] = 1;	// harasser set
		SetTrieArray(g_hWitchTrie, witch_key, witch_dmg_array, MAXPLAYERS + DMGARRAYEXT, true);
	}
	return Plugin_Continue;
}

public Action OnTakeDamageByWitch(int victim, int& attacker, int& inflictor, float& damage, int& damagetype)
{
	// if a survivor is hit by a witch, note it in the witch damage array (maxplayers+2 = 1)
	if (IsValidSurvivor(victim) && damage > 0.0)
	{
		// not a crown if witch hit anyone for > 0 damage
		if (IsWitch(attacker))
		{
			char witch_key[10];
			FormatEx(witch_key, sizeof(witch_key), "%x", attacker);
			int witch_dmg_array[MAXPLAYERS + DMGARRAYEXT];

			if (!GetTrieArray(g_hWitchTrie, witch_key, witch_dmg_array, MAXPLAYERS + DMGARRAYEXT))
			{
				for (int i = 0; i <= MAXPLAYERS; i++)
				{
					witch_dmg_array[i] = 0;
				}
				witch_dmg_array[MAXPLAYERS + WTCH_HEALTH]	= g_cvarWitchHealth.IntValue;
				witch_dmg_array[MAXPLAYERS + WTCH_GOTSLASH] = 1;	// failed
				SetTrieArray(g_hWitchTrie, witch_key, witch_dmg_array, MAXPLAYERS + DMGARRAYEXT, false);
			}
			else
			{
				witch_dmg_array[MAXPLAYERS + WTCH_GOTSLASH] = 1;	// failed
				SetTrieArray(g_hWitchTrie, witch_key, witch_dmg_array, MAXPLAYERS + DMGARRAYEXT, true);
			}
		}
	}
	return Plugin_Continue;
}

public void OnTakeDamagePost_Witch(int victim, int attacker, int inflictor, float damage, int damagetype)
{
	// only called for witches, so no check required

	char witch_key[10];
	FormatEx(witch_key, sizeof(witch_key), "%x", victim);
	int witch_dmg_array[MAXPLAYERS + DMGARRAYEXT];

	if (!GetTrieArray(g_hWitchTrie, witch_key, witch_dmg_array, MAXPLAYERS + DMGARRAYEXT))
	{
		for (int i = 0; i <= MAXPLAYERS; i++)
		{
			witch_dmg_array[i] = 0;
		}
		witch_dmg_array[MAXPLAYERS + WTCH_HEALTH] = g_cvarWitchHealth.IntValue;
		SetTrieArray(g_hWitchTrie, witch_key, witch_dmg_array, MAXPLAYERS + DMGARRAYEXT, false);
	}

	// store damage done to witch
	if (IsValidSurvivor(attacker))
	{
		witch_dmg_array[attacker] += RoundToFloor(damage);
		witch_dmg_array[MAXPLAYERS + WTCH_HEALTH] -= RoundToFloor(damage);

		// remember last shot
		if (g_fWitchShotStart[attacker] == 0.0 || (GetGameTime() - g_fWitchShotStart[attacker]) > SHOTGUN_BLAST_TIME)
		{
			// reset last shot damage count and attacker
			g_fWitchShotStart[attacker]					 = GetGameTime();
			witch_dmg_array[MAXPLAYERS + WTCH_CROWNER]	 = attacker;
			witch_dmg_array[MAXPLAYERS + WTCH_CROWNSHOT] = 0;
			witch_dmg_array[MAXPLAYERS + WTCH_CROWNTYPE] = (damagetype & DMG_BUCKSHOT) ? 1 : 0;	   // only allow shotguns
		}

		// continued blast, add up
		witch_dmg_array[MAXPLAYERS + WTCH_CROWNSHOT] += RoundToFloor(damage);

		SetTrieArray(g_hWitchTrie, witch_key, witch_dmg_array, MAXPLAYERS + DMGARRAYEXT, true);
	}
	else
	{
		// store all chip from other sources than survivor in [0]
		witch_dmg_array[0] += RoundToFloor(damage);
		// witch_dmg_array[MAXPLAYERS+1] -= RoundToFloor(damage);
		SetTrieArray(g_hWitchTrie, witch_key, witch_dmg_array, MAXPLAYERS + DMGARRAYEXT, true);
	}
}

public Action Timer_CheckWitchCrown(Handle timer, Handle pack)
{
	ResetPack(pack);
	int	 attacker = ReadPackCell(pack);
	int	 witch	  = ReadPackCell(pack);
	bool bOneShot = view_as<bool>(ReadPackCell(pack));
	CloseHandle(pack);

	CheckWitchCrown(witch, attacker, bOneShot);
	return Plugin_Continue;
}

stock void CheckWitchCrown(int witch, int attacker, bool bOneShot = false)
{
	char witch_key[10];
	FormatEx(witch_key, sizeof(witch_key), "%x", witch);
	int witch_dmg_array[MAXPLAYERS + DMGARRAYEXT];
	if (!GetTrieArray(g_hWitchTrie, witch_key, witch_dmg_array, MAXPLAYERS + DMGARRAYEXT))
	{
		PrintDebug("Witch Crown Check: Error: Trie entry missing (entity: %i, oneshot: %i)", witch, bOneShot);
		return;
	}

	int chipDamage	 = 0;
	int iWitchHealth = g_cvarWitchHealth.IntValue;

	if (bOneShot)
		witch_dmg_array[MAXPLAYERS + WTCH_CROWNTYPE] = 1;

	if (witch_dmg_array[MAXPLAYERS + WTCH_GOTSLASH] || !witch_dmg_array[MAXPLAYERS + WTCH_CROWNTYPE])
	{
		PrintDebug("Witch Crown Check: Failed: bungled: %i / crowntype: %i (entity: %i)",
				   witch_dmg_array[MAXPLAYERS + WTCH_GOTSLASH],
				   witch_dmg_array[MAXPLAYERS + WTCH_CROWNTYPE],
				   witch);
		PrintDebug("Witch Crown Check: Further details: attacker: %N, attacker dmg: %i, teamless dmg: %i",
				   attacker,
				   witch_dmg_array[attacker],
				   witch_dmg_array[0]);
		return;
	}

	PrintDebug("Witch Crown Check: crown shot: %i, harrassed: %i (full health: %i / drawthresh: %i / oneshot %i)",
			   witch_dmg_array[MAXPLAYERS + WTCH_CROWNSHOT],
			   witch_dmg_array[MAXPLAYERS + WTCH_STARTLED],
			   iWitchHealth,
			   g_cvarDrawCrownThresh.IntValue,
			   bOneShot);

	// full crown? unharrassed
	if (!witch_dmg_array[MAXPLAYERS + WTCH_STARTLED] && (bOneShot || witch_dmg_array[MAXPLAYERS + WTCH_CROWNSHOT] >= iWitchHealth))
	{
		// make sure that we don't count any type of chip
		if (g_cvarHideFakeDamage.BoolValue)
		{
			chipDamage = 0;
			for (int i = 0; i <= MAXPLAYERS; i++)
			{
				if (i == attacker) { continue; }
				chipDamage += witch_dmg_array[i];
			}
			witch_dmg_array[attacker] = iWitchHealth - chipDamage;
		}
		HandleCrown(attacker, witch_dmg_array[attacker]);
	}
	else if (witch_dmg_array[MAXPLAYERS + WTCH_CROWNSHOT] >= g_cvarDrawCrownThresh.IntValue)
	{
		// draw crown: harassed + over X damage done by one survivor -- in ONE shot

		for (int i = 0; i <= MAXPLAYERS; i++)
		{
			if (i == attacker)
				// count any damage done before final shot as chip
				chipDamage += witch_dmg_array[i] - witch_dmg_array[MAXPLAYERS + WTCH_CROWNSHOT];
			else
				chipDamage += witch_dmg_array[i];
		}

		// make sure that we don't count any type of chip
		if (g_cvarHideFakeDamage.BoolValue)
		{
			// unlikely to happen, but if the chip was A LOT
			if (chipDamage >= iWitchHealth)
			{
				chipDamage									 = iWitchHealth - 1;
				witch_dmg_array[MAXPLAYERS + WTCH_CROWNSHOT] = 1;
			}
			else
				witch_dmg_array[MAXPLAYERS + WTCH_CROWNSHOT] = iWitchHealth - chipDamage;
			// re-check whether it qualifies as a drawcrown:
			if (witch_dmg_array[MAXPLAYERS + WTCH_CROWNSHOT] < g_cvarDrawCrownThresh.IntValue)
				return;
		}

		// plus, set final shot as 'damage', and the rest as chip
		HandleDrawCrown(attacker, witch_dmg_array[MAXPLAYERS + WTCH_CROWNSHOT], chipDamage);
	}

	// remove trie
}

// tank rock
public Action TraceAttack_Rock(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& ammotype, int hitbox, int hitgroup)
{
	if (IsValidSurvivor(attacker))
	{
		/*
			can't really use this for precise detection, though it does
			report the last shot -- the damage report is without distance falloff
		*/
		char rock_key[10];
		int	 rock_array[3];
		FormatEx(rock_key, sizeof(rock_key), "%x", victim);
		GetTrieArray(g_hRockTrie, rock_key, rock_array, sizeof(rock_array));
		rock_array[rckDamage] += RoundToFloor(damage);
		rock_array[rckSkeeter] = attacker;
		SetTrieArray(g_hRockTrie, rock_key, rock_array, sizeof(rock_array), true);
	}
	return Plugin_Continue;
}

public void OnTouch_Rock(int entity)
{
	// remember that the rock wasn't shot
	char rock_key[10];
	FormatEx(rock_key, sizeof(rock_key), "%x", entity);
	int rock_array[3];
	rock_array[rckDamage] = -1;
	SetTrieArray(g_hRockTrie, rock_key, rock_array, sizeof(rock_array), true);

	SDKUnhook(entity, SDKHook_Touch, OnTouch_Rock);
}

// smoker tongue cutting & self clears
public Action Event_TonguePullStopped(Handle event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	int victim	 = GetClientOfUserId(GetEventInt(event, "victim"));
	int smoker	 = GetClientOfUserId(GetEventInt(event, "smoker"));
	int reason	 = GetEventInt(event, "release_type");

	if (!IsValidSurvivor(attacker) || !IsValidInfected(smoker))
		return Plugin_Continue;
	// clear check -  if the smoker itself was not shoved, handle the clear
	HandleClear(attacker, smoker, victim,
				ZC_SMOKER,
				(g_fPinTime[smoker][1] > 0.0) ? (GetGameTime() - g_fPinTime[smoker][1]) : -1.0,
				(GetGameTime() - g_fPinTime[smoker][0]),
				view_as<bool>(reason != CUT_SLASH && reason != CUT_KILL));

	if (attacker != victim)
		return Plugin_Continue;

	if (reason == CUT_KILL)
		g_bSmokerClearCheck[smoker] = true;
	else if (g_bSmokerShoved[smoker])
		HandleSmokerSelfClear(attacker, smoker, true);
	else if (reason == CUT_SLASH)	 // note: can't trust this to actually BE a slash..
	{
		// check weapon
		char weapon[32];
		GetClientWeapon(attacker, weapon, 32);

		// this doesn't count the chainsaw, but that's no-skill anyway
		if (StrEqual(weapon, "weapon_melee", false))
			HandleTongueCut(attacker, smoker);
	}

	return Plugin_Continue;
}

public Action Event_TongueGrab(Handle event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	int victim	 = GetClientOfUserId(GetEventInt(event, "victim"));

	if (IsValidInfected(attacker) && IsValidSurvivor(victim))
	{
		// new pull, clean damage
		g_bSmokerClearCheck[attacker]	= false;
		g_bSmokerShoved[attacker]		= false;
		g_iSmokerVictim[attacker]		= victim;
		g_iSmokerVictimDamage[attacker] = 0;
		g_fPinTime[attacker][0]			= GetGameTime();
		g_fPinTime[attacker][1]			= 0.0;
	}

	return Plugin_Continue;
}

public Action Event_ChokeStart(Handle event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(GetEventInt(event, "userid"));

	if (g_fPinTime[attacker][0] == 0.0) { g_fPinTime[attacker][0] = GetGameTime(); }
	g_fPinTime[attacker][1] = GetGameTime();
	return Plugin_Continue;
}

public Action Event_ChokeStop(Handle event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	int victim	 = GetClientOfUserId(GetEventInt(event, "victim"));
	int smoker	 = GetClientOfUserId(GetEventInt(event, "smoker"));
	int reason	 = GetEventInt(event, "release_type");

	if (!IsValidSurvivor(attacker) || !IsValidInfected(smoker))
		return Plugin_Continue;

	// if the smoker itself was not shoved, handle the clear
	HandleClear(attacker, smoker, victim,
				ZC_SMOKER,
				(g_fPinTime[smoker][1] > 0.0) ? (GetGameTime() - g_fPinTime[smoker][1]) : -1.0,
				(GetGameTime() - g_fPinTime[smoker][0]),
				view_as<bool>(reason != CUT_SLASH && reason != CUT_KILL));
	return Plugin_Continue;
}

// car alarm handling
public void Hook_CarAlarmStart(const char[] output, int caller, int activator, float delay)
{
	// char car_key[10];
	// FormatEx(car_key, sizeof(car_key), "%x", entity);

	PrintDebug("calarm trigger: caller %i / activator %i / delay: %.2f", caller, activator, delay);
}

public Action Event_CarAlarmGoesOff(Handle event, const char[] name, bool dontBroadcast)
{
	g_fLastCarAlarm = GetGameTime();
	return Plugin_Continue;
}

public Action OnTakeDamage_Car(int victim, int& attacker, int& inflictor, float& damage, int& damagetype)
{
	if (!IsValidSurvivor(attacker))
		return Plugin_Continue;
	/*
		boomer popped on alarmed car =
			DMG_BLAST_SURFACE| DMG_BLAST
		and inflictor is the boomer

		melee slash/club =
			DMG_SLOWBURN|DMG_PREVENT_PHYSICS_FORCE + DMG_CLUB or DMG_SLASH
		shove is without DMG_SLOWBURN
	*/

	CreateTimer(0.01, Timer_CheckAlarm, victim, TIMER_FLAG_NO_MAPCHANGE);

	char car_key[10];
	FormatEx(car_key, sizeof(car_key), "%x", victim);
	SetTrieValue(g_hCarTrie, car_key, attacker);

	if (damagetype & DMG_BLAST)
	{
		if (IsValidInfected(inflictor) && GetEntProp(inflictor, Prop_Send, "m_zombieClass") == ZC_BOOMER)
		{
			g_iLastCarAlarmReason[attacker] = CALARM_BOOMER;
			g_iLastCarAlarmBoomer			= inflictor;
		}
		else 
			g_iLastCarAlarmReason[attacker] = CALARM_EXPLOSION;
	}
	else if (damage == 0.0 && (damagetype & DMG_CLUB || damagetype & DMG_SLASH) && !(damagetype & DMG_SLOWBURN))
		g_iLastCarAlarmReason[attacker] = CALARM_TOUCHED;
	else
		g_iLastCarAlarmReason[attacker] = CALARM_HIT;

	return Plugin_Continue;
}

public void OnTouch_Car(int entity, int client)
{
	if (!IsValidSurvivor(client))
		return;

	CreateTimer(0.01, Timer_CheckAlarm, entity, TIMER_FLAG_NO_MAPCHANGE);

	char car_key[10];
	FormatEx(car_key, sizeof(car_key), "%x", entity);
	SetTrieValue(g_hCarTrie, car_key, client);

	g_iLastCarAlarmReason[client] = CALARM_TOUCHED;

	return;
}

public Action OnTakeDamage_CarGlass(int victim, int& attacker, int& inflictor, float& damage, int& damagetype)
{
	// check for either: boomer pop or survivor
	if (!IsValidSurvivor(attacker))
		return Plugin_Continue;

	char car_key[10];
	FormatEx(car_key, sizeof(car_key), "%x", victim);
	int parentEntity;

	if (GetTrieValue(g_hCarTrie, car_key, parentEntity))
	{
		CreateTimer(0.01, Timer_CheckAlarm, parentEntity, TIMER_FLAG_NO_MAPCHANGE);

		FormatEx(car_key, sizeof(car_key), "%x", parentEntity);
		SetTrieValue(g_hCarTrie, car_key, attacker);

		if (damagetype & DMG_BLAST)
		{
			if (IsValidInfected(inflictor) && GetEntProp(inflictor, Prop_Send, "m_zombieClass") == ZC_BOOMER)
			{
				g_iLastCarAlarmReason[attacker] = CALARM_BOOMER;
				g_iLastCarAlarmBoomer			= inflictor;
			}
			else 
				g_iLastCarAlarmReason[attacker] = CALARM_EXPLOSION;
		}
		else if (damage == 0.0 && (damagetype & DMG_CLUB || damagetype & DMG_SLASH) && !(damagetype & DMG_SLOWBURN))
			g_iLastCarAlarmReason[attacker] = CALARM_TOUCHED;
		else
			g_iLastCarAlarmReason[attacker] = CALARM_HIT;
	}

	return Plugin_Continue;
}

public void OnTouch_CarGlass(int entity, int client)
{
	if (!IsValidSurvivor(client))
		return;
	char car_key[10];
	FormatEx(car_key, sizeof(car_key), "%x", entity);
	int parentEntity;

	if (GetTrieValue(g_hCarTrie, car_key, parentEntity))
	{
		CreateTimer(0.01, Timer_CheckAlarm, parentEntity, TIMER_FLAG_NO_MAPCHANGE);

		FormatEx(car_key, sizeof(car_key), "%x", parentEntity);
		SetTrieValue(g_hCarTrie, car_key, client);

		g_iLastCarAlarmReason[client] = CALARM_TOUCHED;
	}

	return;
}

public Action Timer_CheckAlarm(Handle timer, any entity)
{
	// PrintToChatAll( "checking alarm: time: %.3f", GetGameTime() - g_fLastCarAlarm );

	if ((GetGameTime() - g_fLastCarAlarm) < CARALARM_MIN_TIME)
	{
		// got a match, drop stuff from trie and handle triggering
		char car_key[10];
		int	 testEntity;
		int	 survivor = -1;

		// remove car glass
		FormatEx(car_key, sizeof(car_key), "%x_A", entity);
		if (GetTrieValue(g_hCarTrie, car_key, testEntity))
		{
			RemoveFromTrie(g_hCarTrie, car_key);
			SDKUnhook(testEntity, SDKHook_OnTakeDamage, OnTakeDamage_CarGlass);
			SDKUnhook(testEntity, SDKHook_Touch, OnTouch_CarGlass);
		}
		FormatEx(car_key, sizeof(car_key), "%x_B", entity);
		if (GetTrieValue(g_hCarTrie, car_key, testEntity))
		{
			RemoveFromTrie(g_hCarTrie, car_key);
			SDKUnhook(testEntity, SDKHook_OnTakeDamage, OnTakeDamage_CarGlass);
			SDKUnhook(testEntity, SDKHook_Touch, OnTouch_CarGlass);
		}

		// remove car
		FormatEx(car_key, sizeof(car_key), "%x", entity);
		if (GetTrieValue(g_hCarTrie, car_key, survivor))
		{
			RemoveFromTrie(g_hCarTrie, car_key);
			SDKUnhook(entity, SDKHook_OnTakeDamage, OnTakeDamage_Car);
			SDKUnhook(entity, SDKHook_Touch, OnTouch_Car);
		}

		// check for infected assistance
		int infected = 0;
		if (IsValidSurvivor(survivor))
		{
			if (g_iLastCarAlarmReason[survivor] == CALARM_BOOMER)
				infected = g_iLastCarAlarmBoomer;
			else if (IsValidInfected(GetEntPropEnt(survivor, Prop_Send, "m_carryAttacker")))
				infected = GetEntPropEnt(survivor, Prop_Send, "m_carryAttacker");
			else if (IsValidInfected(GetEntPropEnt(survivor, Prop_Send, "m_jockeyAttacker")))
				infected = GetEntPropEnt(survivor, Prop_Send, "m_jockeyAttacker");
			else if (IsValidInfected(GetEntPropEnt(survivor, Prop_Send, "m_tongueOwner")))
				infected = GetEntPropEnt(survivor, Prop_Send, "m_tongueOwner");
		}

		HandleCarAlarmTriggered(survivor, infected, (IsValidClientInGame(survivor)) ? g_iLastCarAlarmReason[survivor] : CALARM_UNKNOWN);
	}
	return Plugin_Continue;
}
