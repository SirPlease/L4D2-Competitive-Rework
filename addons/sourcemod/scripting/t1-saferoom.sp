#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

#define L4D2_TEAM_SURVIVOR 2

new bool:g_bSpawnedMelee;
new g_iRound = 2;

public Plugin:myinfo =
{
	name = "[L4D] T1 in the saferrom",
	author = "Altair Sossai",
	description = "Gives t1 to survivors at the start of each round.",
	version = "1.1.2",
	url = "http://forums.alliedmods.net"
}

public OnPluginStart()
{
    HookEvent("round_start", Event_RoundStart);
}

public void OnRoundIsLive()
{
    ReloadAllWeapons();
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    g_bSpawnedMelee = false;
    
    if(g_iRound == 2 && IsVersus()) 
        g_iRound = 1; 
    else 
        g_iRound = 2;
    
    CreateTimer( 1.0, Timer_SpawnMelee );
    
    return Plugin_Continue;
}

public Action:Timer_SpawnMelee( Handle:timer )
{
    new client = GetInGameClient();

    if(client != 0 && !g_bSpawnedMelee)
    {
        decl Float:SpawnPosition[3], Float:SpawnAngle[3];

        GetClientAbsOrigin(client, SpawnPosition);
        
        SpawnPosition[2] += 20; 
        SpawnAngle[0] = 90.0;
        
        SpawnEntity("weapon_pumpshotgun", SpawnPosition, SpawnAngle);
        SpawnEntity("weapon_shotgun_chrome", SpawnPosition, SpawnAngle);
        SpawnEntity("weapon_smg", SpawnPosition, SpawnAngle);
        SpawnEntity("weapon_smg_silenced", SpawnPosition, SpawnAngle);
        
        g_bSpawnedMelee = true;
    }
    else
    {
        if(!g_bSpawnedMelee) 
            CreateTimer(1.0, Timer_SpawnMelee);
    }
}

stock SpawnEntity(String:EntityName[128], Float:Position[3], Float:Angle[3])
{
    decl Float:SpawnPosition[3], Float:SpawnAngle[3];
    SpawnPosition = Position;
    SpawnAngle = Angle;
    
    SpawnPosition[0] += (-10 + GetRandomInt(0, 20));
    SpawnPosition[1] += (-10 + GetRandomInt(0, 20));
    SpawnPosition[2] += GetRandomInt(0, 10);
    SpawnAngle[1] = GetRandomFloat(0.0, 360.0);

    new Spawn = CreateEntityByName(EntityName);

    DispatchSpawn(Spawn);
    TeleportEntity(Spawn, SpawnPosition, SpawnAngle, NULL_VECTOR );
}

stock GetInGameClient()
{
    for( new x = 1; x <= GetClientCount( true ); x++ )
        if( IsClientInGame( x ) && GetClientTeam( x ) == 2 )
            return x;

    return 0;
}

stock bool:IsVersus()
{
    new String:GameMode[32];
    GetConVarString( FindConVar( "mp_gamemode" ), GameMode, 32 );
    if( StrContains( GameMode, "versus", false ) != -1 ) return true;
    return false;
}

public ReloadAllWeapons()
{
    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsClientInGame(client) || IsFakeClient(client) || !SurvivorTeam(client))
            continue;

        new flags = GetCommandFlags("give");
        SetCommandFlags("give", flags ^ FCVAR_CHEAT);
        FakeClientCommand(client, "give ammo");
        SetCommandFlags("give", flags);
	}
}

public bool SurvivorTeam(int client)
{
	int clientTeam = GetClientTeam(client);
	
	return clientTeam == L4D2_TEAM_SURVIVOR;
}