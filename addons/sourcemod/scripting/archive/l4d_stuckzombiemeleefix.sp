#include <sourcemod>
#include <sdktools>
#define DEBUG 0

#define PLUGIN_VERSION "1.0.5"

public Plugin:myinfo = 
{
	name = "Stuck Zombie Melee Fix",
	author = "AtomicStryker",
	description = "Smash nonstaggering Zombies",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=932416"
}

public OnPluginStart()
{
	HookEvent("entity_shoved", Event_EntShoved);
	AddNormalSoundHook(NormalSHook:HookSound_Callback); //my melee hook since they didnt include an event for it
	
	CreateConVar("l4d_stuckzombiemeleefix_version", PLUGIN_VERSION, " Version of L4D Stuck Zombie Melee Fix on this server ", FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
}

new bool:MeleeDelay[MAXPLAYERS+1];

public Action HookSound_Callback(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, \
				float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	//to work only on melee sounds, its 'swish' or 'weaponswing'
	if (StrContains(sample, "Swish", false) == -1) return Plugin_Continue;
	//so the client has the melee sound playing. OMG HES MELEEING!

	if (entity > MaxClients) return Plugin_Continue; // bugfix for some people on L4D2

	//add in a 1 second delay so this doesnt fire every frame
	if (MeleeDelay[entity]) return Plugin_Continue; //note 'Entity' means 'client' here
	MeleeDelay[entity] = true;
	CreateTimer(1.0, ResetMeleeDelay, entity);

	#if DEBUG
	PrintToChatAll("Melee detected via soundhook.");
	#endif

	new entid = GetClientAimTarget(entity, false);
	if (entid <= 0) return Plugin_Continue;

	decl String:entclass[96];
	GetEntityNetClass(entid, entclass, sizeof(entclass));
	if (!StrEqual(entclass, "Infected")) return Plugin_Continue;

	decl Float:clientpos[3], Float:entpos[3];
	GetEntityAbsOrigin(entid, entpos);
	GetClientEyePosition(entity, clientpos);
	if (GetVectorDistance(clientpos, entpos) < 50) return Plugin_Continue; //else you could 'jedi melee' Zombies from a distance

	#if DEBUG
	PrintToChatAll("Youre meleeing and looking at Zombie id #%i", entid);
	#endif

	//now to make this Zombie fire a event to be caught by the actual 'fix'

	new Handle:newEvent = CreateEvent("entity_shoved", true);
	SetEventInt(newEvent, "attacker", entity); //the client being called Entity is a bit unfortunate
	SetEventInt(newEvent, "entityid", entid);
	FireEvent(newEvent, true);

	return Plugin_Continue;
}

public Action:ResetMeleeDelay(Handle:timer, any:client)
{
	MeleeDelay[client] = false;
}

public Event_EntShoved(Handle:event, const String:name[], bool:dontBroadcast)
{
	new entid = GetEventInt(event, "entityid"); //get the events shoved entity id
	
	decl String:entclass[96];
	GetEntityNetClass(entid, entclass, sizeof(entclass));
	if (!StrEqual(entclass, "Infected")) return; //make sure it IS a zombie.
	
	new Handle:data = CreateDataPack() //a data pack because i need multiple values saved
	CreateTimer(0.5, CheckForMovement, data); //0.5 seemed both long enough for a normal zombie to stumble away and for a stuck one to DIEEEEE
	
	WritePackCell(data, entid); //save the Zombie id
	
	decl Float:pos[3];
	GetEntityAbsOrigin(entid, pos); //get the Zombies position
	WritePackFloat(data, pos[0]); //save the Zombies position
	WritePackFloat(data, pos[1]);
	WritePackFloat(data, pos[2]);
	
	#if DEBUG
	PrintToChatAll("Meleed Zombie detected.");
	#endif
}

public Action:CheckForMovement(Handle:timer, Handle:data)
{
	ResetPack(data); //this resets our 'reading' position in the data pack, to start from the beginning
	
	new zombieid = ReadPackCell(data); //get the Zombie id
	if (!IsValidEntity(zombieid)) return Plugin_Handled; //did the zombie get disappear somehow?
	
	decl String:entclass[96];
	GetEntityNetClass(zombieid, entclass, sizeof(entclass));
	if (!StrEqual(entclass, "Infected")) return Plugin_Handled; //make sure it STILL IS a zombie.
	
	decl Float:oldpos[3];
	oldpos[0] = ReadPackFloat(data); //get the old Zombie position (half a sec ago)
	oldpos[1] = ReadPackFloat(data);
	oldpos[2] = ReadPackFloat(data);
	
	CloseHandle(data); //Dispose of the Handle. It shouldn't have messed with the family
	
	decl Float:newpos[3];
	GetEntityAbsOrigin(zombieid, newpos); //get the Zombies current position
	
	if (GetVectorDistance(oldpos, newpos) > 5) return Plugin_Handled; //if the positions differ, the zombie was correctly shoved and is now staggering. Plugin End
	
	#if DEBUG
	PrintToChatAll("Stuck meleed Zombie detected.");
	#endif
	
	//now i could simply slay the stuck zombie. but this would also instantkill any zombie you meleed into a corner or against a wall
	//so instead i coded a two-punts-it-doesnt-move-so-slay-it command
	
	new zombiehealth = GetEntProp(zombieid, Prop_Data, "m_iHealth");
	new zombiehealthmax = GetConVarInt(FindConVar("z_health"));
	
	if (zombiehealth - (zombiehealthmax / 2) <= 0) // if the zombies health is less than half
	{
		//SetEntProp(zombieid, Prop_Data, "m_iHealth", 0); //CRUSH HIM!!!!!! - ragdoll bug, unused
		AcceptEntityInput(zombieid, "BecomeRagdoll"); //Damizean pointed this one out, Cheers to him.
		
		#if DEBUG
		PrintToChatAll("Slayed Stuck Zombie.");
		#endif
	}
	
	else SetEntProp(zombieid, Prop_Data, "m_iHealth", zombiehealth - (zombiehealthmax / 2)) //else remove half of its health, so the zombie dies from the next melee blow
		
	return Plugin_Handled;
}

//entity abs origin code from here
//http://forums.alliedmods.net/showpost.php?s=e5dce96f11b8e938274902a8ad8e75e9&p=885168&postcount=3
public Action:GetEntityAbsOrigin(entity,Float:origin[3])
{
	decl Float:mins[3], Float:maxs[3];
	GetEntPropVector(entity,Prop_Send,"m_vecOrigin",origin);
	GetEntPropVector(entity,Prop_Send,"m_vecMins",mins);
	GetEntPropVector(entity,Prop_Send,"m_vecMaxs",maxs);
	
	origin[0] += (mins[0] + maxs[0]) * 0.5;
	origin[1] += (mins[1] + maxs[1]) * 0.5;
	origin[2] += (mins[2] + maxs[2]) * 0.5;
}