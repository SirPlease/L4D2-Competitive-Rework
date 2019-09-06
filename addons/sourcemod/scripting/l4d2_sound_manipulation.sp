#include <sceneprocessor>

#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define MAX_ROCHELLESOUND      8
#define MAX_ELLISSOUND         6
#define MAX_NICKSOUND          14
#define MAX_COACHSOUND         18

#define MAX_FRANCISSOUND	   11
#define MAX_ZOEYSOUND		   9
#define MAX_LOUISSOUND		   7
#define MAX_BILLSOUND		   10

Handle cBlockHB;
Handle cBlock4Competitive;
 
public Plugin myinfo = 
{
	name = "Sound Manipulation",
	author = "Sir",
	description = "Allows control over certain sounds",
	version = "1.5",
	url = "https://github.com/SirPlease/SirCoding"
}

char sCoachSound[MAX_COACHSOUND + 1][] = 
{
	"player/survivor/voice/coach/meleeswing01.wav", 
	"player/survivor/voice/coach/meleeswing02.wav", 
	"player/survivor/voice/coach/meleeswing03.wav", 
	"player/survivor/voice/coach/meleeswing04.wav", 
	"player/survivor/voice/coach/meleeswing05.wav", 
	"player/survivor/voice/coach/meleeswing06.wav", 
	"player/survivor/voice/coach/meleeswing07.wav", 
	"player/survivor/voice/coach/meleeswing08.wav", 
	"player/survivor/voice/coach/meleeswing09.wav", 
	"player/survivor/voice/coach/meleeswing10.wav", 
	"player/survivor/voice/coach/meleeswing11.wav", 
	"player/survivor/voice/coach/meleeswing12.wav", 
	"player/survivor/voice/coach/meleeswing13.wav", 
	"player/survivor/voice/coach/meleeswing14.wav", 
	"player/survivor/voice/coach/meleeswing15.wav", 
	"player/survivor/voice/coach/meleeswing16.wav", 
	"player/survivor/voice/coach/meleeswing17.wav", 
	"player/survivor/voice/coach/meleeswing18.wav", 
	"player/survivor/voice/coach/meleeswing19.wav"
};

char sRochelleSound[MAX_ROCHELLESOUND + 1][] = 
{
	"player/survivor/voice/producer/meleeswing01.wav", 
	"player/survivor/voice/producer/meleeswing02.wav", 
	"player/survivor/voice/producer/meleeswing03.wav", 
	"player/survivor/voice/producer/meleeswing04.wav", 
	"player/survivor/voice/producer/meleeswing05.wav", 
	"player/survivor/voice/producer/meleeswing06.wav", 
	"player/survivor/voice/producer/meleeswing07.wav", 
	"player/survivor/voice/producer/meleeswing08.wav", 
	"player/survivor/voice/producer/meleeswing09.wav"
};

char sEllisSound[MAX_ELLISSOUND + 1][] = 
{
	"player/survivor/voice/mechanic/meleeswing01.wav", 
	"player/survivor/voice/mechanic/meleeswing02.wav", 
	"player/survivor/voice/mechanic/meleeswing03.wav", 
	"player/survivor/voice/mechanic/meleeswing04.wav", 
	"player/survivor/voice/mechanic/meleeswing05.wav", 
	"player/survivor/voice/mechanic/meleeswing06.wav", 
	"player/survivor/voice/mechanic/meleeswing07.wav"
};

char sNickSound[MAX_NICKSOUND + 1][] = 
{
	"player/survivor/voice/gambler/meleeswing01.wav", 
	"player/survivor/voice/gambler/meleeswing02.wav", 
	"player/survivor/voice/gambler/meleeswing03.wav", 
	"player/survivor/voice/gambler/meleeswing04.wav", 
	"player/survivor/voice/gambler/meleeswing05.wav", 
	"player/survivor/voice/gambler/meleeswing06.wav", 
	"player/survivor/voice/gambler/meleeswing07.wav", 
	"player/survivor/voice/gambler/meleeswing08.wav", 
	"player/survivor/voice/gambler/meleeswing09.wav", 
	"player/survivor/voice/gambler/meleeswing10.wav", 
	"player/survivor/voice/gambler/meleeswing11.wav", 
	"player/survivor/voice/gambler/meleeswing12.wav", 
	"player/survivor/voice/gambler/meleeswing13.wav", 
	"player/survivor/voice/gambler/meleeswing14.wav", 
	"player/survivor/voice/gambler/meleeswing15.wav"
};

char sFrancisSound[MAX_FRANCISSOUND + 1][] = 
{
	"player/survivor/voice/biker/hurtminor02.wav", 
	"player/survivor/voice/biker/hurtminor04.wav", 
	"player/survivor/voice/biker/hurtminor07.wav", 
	"player/survivor/voice/biker/hurtminor08.wav", 
	"player/survivor/voice/biker/positivenoise02.wav", 
	"player/survivor/voice/biker/shoved01.wav", 
	"player/survivor/voice/biker/shoved02.wav", 
	"player/survivor/voice/biker/shoved03.wav", 
	"player/survivor/voice/biker/shoved04.wav", 
	"player/survivor/voice/biker/shoved05.wav", 
	"player/survivor/voice/biker/shoved06.wav", 
	"player/survivor/voice/biker/shoved07.wav"
};

char sZoeySound[MAX_ZOEYSOUND + 1][] = 
{
	"player/survivor/voice/teengirl/hordeatttack10.wav", 
	"player/survivor/voice/teengirl/hordeattack29.wav", 
	"player/survivor/voice/teengirl/hurtminor03.wav", 
	"player/survivor/voice/teengirl/shoved01.wav", 
	"player/survivor/voice/teengirl/shoved02.wav", 
	"player/survivor/voice/teengirl/shoved03.wav", 
	"player/survivor/voice/teengirl/shoved04.wav", 
	"player/survivor/voice/teengirl/shoved05.wav", 
	"player/survivor/voice/teengirl/shoved06.wav", 
	"player/survivor/voice/teengirl/shoved14.wav"
};

char sLouisSound[MAX_LOUISSOUND + 1][] = 
{
	"player/survivor/voice/manager/hurtminor02.wav", 
	"player/survivor/voice/manager/hurtminor05.wav", 
	"player/survivor/voice/manager/hurtminor06.wav", 
	"player/survivor/voice/manager/shoved01.wav", 
	"player/survivor/voice/manager/shoved02.wav", 
	"player/survivor/voice/manager/shoved03.wav", 
	"player/survivor/voice/manager/shoved04.wav", 
	"player/survivor/voice/manager/shoved05.wav" 
};

char sBillSound[MAX_BILLSOUND + 1][] = 
{
	"player/survivor/voice/namvet/hurtminor02.wav", 
	"player/survivor/voice/namvet/hurtminor05.wav", 
	"player/survivor/voice/namvet/hurtminor07.wav", 
	"player/survivor/voice/namvet/hurtminor08.wav", 
	"player/survivor/voice/namvet/shoved01.wav", 
	"player/survivor/voice/namvet/shoved02.wav", 
	"player/survivor/voice/namvet/shoved03.wav", 
	"player/survivor/voice/namvet/shoved04.wav", 
	"player/survivor/voice/namvet/shoved05.wav", 
	"player/survivor/voice/namvet/positivenoise03.wav", 
	"player/survivor/voice/namvet/reactionstartled01.wav"
};

public void OnPluginStart()
{
	cBlockHB = CreateConVar("sound_block_hb", "0", "Block the Heartbeat Sound, very useful for 1v1 matchmodes");
	cBlock4Competitive = CreateConVar("sound_block_for_comp", "0", "Block a lot of Random noises and voice lines");

	// Event Hook
	HookEvent("weapon_fire", Event_WeaponFire);
	
	// Sound Hook
	AddNormalSoundHook(view_as<NormalSHook>(SoundHook));
}


public void OnMapStart()
{
	for (int i = 0; i <= MAX_ROCHELLESOUND; i++)
	{
		PrefetchSound(sRochelleSound[i]);
		PrecacheSound(sRochelleSound[i], true);
	}
	
	for (int i = 0; i <= MAX_NICKSOUND; i++)
	{
		PrefetchSound(sNickSound[i]);
		PrecacheSound(sNickSound[i], true);
	}
	
	for (int i = 0; i <= MAX_ELLISSOUND; i++)
	{
		PrefetchSound(sEllisSound[i]);
		PrecacheSound(sEllisSound[i], true);
	}
	
	for (int i = 0; i <= MAX_COACHSOUND; i++)
	{
		PrefetchSound(sCoachSound[i]);
		PrecacheSound(sCoachSound[i], true);
	}
	
	for (int i = 0; i <= MAX_FRANCISSOUND; i++)
	{
		PrefetchSound(sFrancisSound[i]);
		PrecacheSound(sFrancisSound[i], true);
	}
	
	for (int i = 0; i <= MAX_LOUISSOUND; i++)
	{
		PrefetchSound(sLouisSound[i]);
		PrecacheSound(sLouisSound[i], true);
	}
	
	for (int i = 0; i <= MAX_ZOEYSOUND; i++)
	{
		PrefetchSound(sZoeySound[i]);
		PrecacheSound(sZoeySound[i], true);
	}
	
	for (int i = 0; i <= MAX_BILLSOUND; i++)
	{
		PrefetchSound(sBillSound[i]);
		PrecacheSound(sBillSound[i], true);
	}
}

public Action Event_WeaponFire(Handle event, const char[] name, bool dontBroadcast)
{
	char weapon[64];
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (StrEqual(weapon, "melee") && IsPlayerAlive(client) && GetClientTeam(client) == 2 && !IsActorBusy(client))
	{
		char clientModel[42];
		GetClientModel(client, clientModel, sizeof(clientModel));

		//
		// Make sure the Survivors have their Melee Sounds!
		//
		
		// L4D2 Survivors
		
		//Coach
		if (StrEqual(clientModel, "models/survivors/survivor_coach.mdl"))
		{
			int rndPick = GetRandomInt(0, MAX_COACHSOUND);
			EmitSoundToAll(sCoachSound[rndPick], client, SNDCHAN_VOICE);
		}
		//Nick
		else if (StrEqual(clientModel, "models/survivors/survivor_gambler.mdl"))
		{
			int rndPick = GetRandomInt(0, MAX_NICKSOUND);
			EmitSoundToAll(sNickSound[rndPick], client, SNDCHAN_VOICE);
		}
		//Rochelle
		else if (StrEqual(clientModel, "models/survivors/survivor_producer.mdl"))
		{
			int rndPick = GetRandomInt(0, MAX_ROCHELLESOUND);
			EmitSoundToAll(sRochelleSound[rndPick], client, SNDCHAN_VOICE);
		}
		//Ellis
		else if (StrEqual(clientModel, "models/survivors/survivor_mechanic.mdl"))
		{
			int rndPick = GetRandomInt(0, MAX_ELLISSOUND);
			EmitSoundToAll(sEllisSound[rndPick], client, SNDCHAN_VOICE);
		}
		
		// L4D1 survivors
		
		// Louis
		else if (StrEqual(clientModel, "models/survivors/survivor_manager.mdl"))
		{
			int rndPick = GetRandomInt(0, MAX_LOUISSOUND);
			EmitSoundToAll(sLouisSound[rndPick], client, SNDCHAN_VOICE);
		}
		// Zoey
		else if (StrEqual(clientModel, "models/survivors/survivor_teenangst.mdl"))
		{
			int rndPick = GetRandomInt(0, MAX_ZOEYSOUND);
			EmitSoundToAll(sZoeySound[rndPick], client, SNDCHAN_VOICE);
		}
		// Bill
		else if (StrEqual(clientModel, "models/survivors/survivor_namvet.mdl"))
		{
			int rndPick = GetRandomInt(0, MAX_BILLSOUND);
			EmitSoundToAll(sBillSound[rndPick], client, SNDCHAN_VOICE);
		}
		//Francis
		else if (StrEqual(clientModel, "models/survivors/survivor_biker.mdl"))
		{
			int rndPick = GetRandomInt(0, MAX_FRANCISSOUND);
			EmitSoundToAll(sFrancisSound[rndPick], client, SNDCHAN_VOICE);
		}

		//No Matching Survivors
		else return;
	}
	return;
}

public Action SoundHook(int clients[64], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity)
{
	// Heartbeat
	if (GetConVarBool(cBlockHB) && StrEqual(sample, "player/heartbeatloop.wav", false)) return Plugin_Stop;

	// Competitive Stuff
	if (GetConVarBool(cBlock4Competitive))
	{
		// World
		if (StrContains(sample, "World", true) != -1  ||
		// Look...
		StrContains(sample, "look", false) != -1 ||
		// Ask..
		StrContains(sample, "ask", false) != -1   ||
		// Follow Me..
		StrContains(sample, "followme", false) != -1 ||
		// Follow Me..
		StrContains(sample, "gettingrevived", false) != -1 ||
		// Item..
		StrContains(sample, "alertgiveitem", false) != -1 ||
		// I'm with you..
		StrContains(sample, "imwithyou", false) != -1 ||
		// Laughter..
		StrContains(sample, "laughter", false) != -1 ||
		// Name..
		StrContains(sample, "name", false) != -1 ||
		// Lead on..
		StrContains(sample, "leadon", false) != -1 ||
		// Move On..
		StrContains(sample, "moveon", false) != -1 ||
		// FF..
		StrContains(sample, "friendlyfire", false) != -1 ||
		// Blood Splat..
		StrContains(sample, "splat", false) != -1) return Plugin_Stop;
	}
	return Plugin_Continue;
}