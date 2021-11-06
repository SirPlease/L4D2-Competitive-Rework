#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#define L4D2UTIL_STOCKS_ONLY 1
#include <l4d2util>
#include <left4dhooks> //#include <l4d2_direct>

#define ANIM_HUNTER_LENGTH 2.2					// frames: 64, fps: 30, length: 2.133
#define ANIM_CHARGER_STANDARD_LENGTH 2.9		// frames: 85, fps 30, length: 2.833
#define ANIM_CHARGER_SLAMMED_WALL_LENGTH 3.9	// frames 116 fps 30 = 3.867
#define ANIM_CHARGER_SLAMMED_GROUND_LENGTH 4.0	// frames 119 fps 30 = 3.967

#define ANIM_EVENT_CHARGER_GETUP 78

#define GETUP_TIMER_INTERVAL 0.5

enum
{
	eINDEX_HUNTER = 0,							//index for getup anim on hunter clears
	eINDEX_CHARGER = 1,							//index for getup anim on post-slam clears
	eINDEX_CHARGER_WALL = 2,					//index for getup anim on mid-slam clears against walls
	eINDEX_CHARGER_GROUND = 3,					//index for getup anim on mid-slam clears against ground (after long charges)
	
	eINDEX_SIZE
};

//incapped animations: 0 = single-pistol, 1 = dual pistols
enum
{
	eSINGLE_PISTOL = 0,							//index for getup anim on hunter clears
	eDUAL_PISTOLS = 1,							//index for getup anim on post-slam clears
	
	eINCAP_ANIMATIONS_SIZE
};

int
	bArClientAlreadyChecked[MAXPLAYERS + 1]; //in the rare event of it being a game with multiple chargers and 2+ getting cleared on slam

static const int 
	getUpAnimations[SurvivorCharacter_Size][eINDEX_SIZE] =
	{
		// l4d2 
		// 0: Nick, 1: Rochelle, 2: Coach, 3: Ellis
		{620, 667, 671, 672}, //Nick
		{629, 674, 678, 679}, //Rochelle
		{621, 656, 660, 661}, //Coach
		{625, 671, 675, 676}, //Ellis
		
		// l4d1
		// 4: Bill, 5: Zoey, 6: Louis, 7: Francis
		{528, 759, 763, 764}, //Bill
		{537, 819, 823, 824}, //Zoey
		{528, 759, 763, 764}, //Louis
		{531, 762, 766, 767} //Francis
	},
	//incapped animations: 0 = single-pistol, 1 = dual pistols
	incapAnimations[SurvivorCharacter_Size][eINCAP_ANIMATIONS_SIZE] =
	{
		// l4d2
		// 0: Nick, 1: Rochelle, 2: Coach, 3: Ellis
		{612, 613}, //Nick
		{621, 622}, //Rochelle
		{613, 614}, //Coach
		{617, 618}, //Ellis
		
		// l4d1
		// 4: Bill, 5: Zoey, 6: Louis, 7: Francis
		{520, 521}, //Bill
		{525, 526}, //Zoey
		{520, 521}, //Louis
		{523, 524} //Francis
	};

public Plugin myinfo = 
{
	name = "L4D2 Get-Up Fix",
	author = "Blade, ProdigySim, DieTeetasse, Stabby, Jahze, A1m`", //Add support sm1.11 - A1m`
	description = "Double/no/self-clear get-up fix.",
	version = "1.7.4",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework/"
};

public void OnPluginStart()
{
	HookEvent("pounce_end", Event_PounceOrPummel);
	HookEvent("charger_pummel_end", Event_PounceOrPummel);
	HookEvent("charger_killed", ChargerKilled);
}

public void Event_PounceOrPummel(Event hEvent, const char[] eName, bool dontBroadcast)
{
	int client = GetClientOfUserId(hEvent.GetInt("victim"));
	if (client > 0 && IsClientInGame(client)) {
		CreateTimer(0.1, Timer_ProcessClient, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Timer_ProcessClient(Handle hTimer, any client)
{
	ProcessClient(client);
	return Plugin_Stop;
}

void ProcessClient(int client)
{
	int charIndex = IdentifySurvivor(client);
	if (charIndex == SurvivorCharacter_Invalid) {
		return;
	}

	int sequence = GetEntProp(client, Prop_Send, "m_nSequence");
	
	// charger or hunter get up animation?
	if (sequence != getUpAnimations[charIndex][eINDEX_HUNTER] && sequence != getUpAnimations[charIndex][eINDEX_CHARGER]
		&&  sequence != getUpAnimations[charIndex][eINDEX_CHARGER_GROUND] && sequence != getUpAnimations[charIndex][eINDEX_CHARGER_WALL]
	) {
		if (sequence != incapAnimations[charIndex][eSINGLE_PISTOL] && sequence != incapAnimations[charIndex][eDUAL_PISTOLS]) {
			L4D2Direct_DoAnimationEvent(client, ANIM_EVENT_CHARGER_GETUP);
		}
		return;
	}

	// create stack with client and sequence
	ArrayStack tempStack = new ArrayStack(3);
	tempStack.Push(client);
	tempStack.Push(sequence);
	
	float fTime = 0.0;

	if (sequence == getUpAnimations[charIndex][eINDEX_HUNTER]) {
		fTime = ANIM_HUNTER_LENGTH;
	} else if (sequence == getUpAnimations[charIndex][eINDEX_CHARGER]) {
		fTime = ANIM_CHARGER_STANDARD_LENGTH;
	} else if (sequence == getUpAnimations[charIndex][eINDEX_CHARGER_WALL]) {
		fTime = ANIM_CHARGER_SLAMMED_WALL_LENGTH - 2.5 * GetEntPropFloat(client, Prop_Send, "m_flCycle");
	} else {
		fTime = ANIM_CHARGER_SLAMMED_GROUND_LENGTH - 2.5 * GetEntPropFloat(client, Prop_Send, "m_flCycle");
	}
	
	CreateTimer(fTime, Timer_CheckClient, tempStack, TIMER_FLAG_NO_MAPCHANGE | TIMER_HNDL_CLOSE);
}

public Action Timer_CheckClient(Handle hTimer, ArrayStack tempStack)
{
	int oldSequence = tempStack.Pop();
	int client = tempStack.Pop();

	int charIndex = IdentifySurvivor(client);
	if (charIndex == SurvivorCharacter_Invalid) {
		return Plugin_Stop;
	}

	int newSequence = GetEntProp(client, Prop_Send, "m_nSequence");
	
	// not the same animation?
	if (newSequence == oldSequence) {
		return Plugin_Stop;
	}
	
	float duration = 0.0;
	
	// charger or hunter get up animation?
	if (newSequence == getUpAnimations[charIndex][eINDEX_HUNTER]) {
		duration = ANIM_HUNTER_LENGTH;
	} else if (newSequence == getUpAnimations[charIndex][eINDEX_CHARGER]) {
		duration = ANIM_CHARGER_STANDARD_LENGTH;
	} else if (newSequence == getUpAnimations[charIndex][eINDEX_CHARGER_WALL]) {
		duration = ANIM_CHARGER_SLAMMED_WALL_LENGTH;
	} else if (newSequence == getUpAnimations[charIndex][eINDEX_CHARGER_GROUND]) {
		duration = ANIM_CHARGER_SLAMMED_GROUND_LENGTH;
	} else {
		return Plugin_Stop;
	}

	SetEntPropFloat(client, Prop_Send, "m_flCycle", duration); // Apply!
	return Plugin_Stop;
}

public void ChargerKilled(Event hEvent, const char[] eName, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(hEvent.GetInt("attacker"));

	if (attacker > 0 && attacker <= MaxClients) {
		CreateTimer(GETUP_TIMER_INTERVAL, GetupTimer, attacker, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action GetupTimer(Handle hTimer, any attacker)
{
	for (int i = 1; i <= MaxClients; i++) {
		if (IsSurvivor(i) && !bArClientAlreadyChecked[i]) {
			int seq = GetEntProp(i, Prop_Send, "m_nSequence");
			int character = IdentifySurvivor(i);
			
			if (character == SurvivorCharacter_Invalid) {
				return Plugin_Stop;
			}
			
			if (seq == getUpAnimations[character][eINDEX_CHARGER_WALL]) {
				if (i == attacker) {
					SetEntPropFloat(attacker, Prop_Send, "m_flCycle", ANIM_CHARGER_SLAMMED_WALL_LENGTH);
				} else {
					bArClientAlreadyChecked[i] = true;
					CreateTimer(ANIM_CHARGER_SLAMMED_WALL_LENGTH, ResetAlreadyCheckedBool, i, TIMER_FLAG_NO_MAPCHANGE);
					ProcessClient(i);
				}
				
				break;
			} else if (seq == getUpAnimations[character][eINDEX_CHARGER_GROUND]) {
				if (i == attacker) {
					SetEntPropFloat(attacker, Prop_Send, "m_flCycle", ANIM_CHARGER_SLAMMED_GROUND_LENGTH);
				} else {
					bArClientAlreadyChecked[i] = true;
					CreateTimer(ANIM_CHARGER_SLAMMED_GROUND_LENGTH, ResetAlreadyCheckedBool, i, TIMER_FLAG_NO_MAPCHANGE);
					ProcessClient(i);
				}
				
				break;
			}
		}
	}

	return Plugin_Stop;
}

public Action ResetAlreadyCheckedBool(Handle hTimer, any client)
{
	bArClientAlreadyChecked[client] = false;
	return Plugin_Stop;
}
