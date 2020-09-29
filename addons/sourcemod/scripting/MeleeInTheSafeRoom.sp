#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define VERSION "2.0.7"

new Handle:g_hEnabled;
new Handle:g_hWeaponRandom;
new Handle:g_hWeaponRandomAmount;
new Handle:g_hWeaponBaseballBat;
new Handle:g_hWeaponCricketBat;
new Handle:g_hWeaponCrowbar;
new Handle:g_hWeaponElecGuitar;
new Handle:g_hWeaponFireAxe;
new Handle:g_hWeaponFryingPan;
new Handle:g_hWeaponGolfClub;
new Handle:g_hWeaponKnife;
new Handle:g_hWeaponKatana;
new Handle:g_hWeaponMachete;
new Handle:g_hWeaponRiotShield;
new Handle:g_hWeaponTonfa;

new bool:g_bSpawnedMelee;

new g_iMeleeClassCount = 0;
new g_iMeleeRandomSpawn[20];
new g_iRound = 2;

new String:g_sMeleeClass[16][32];

public Plugin:myinfo =
{
    name = "Melee In The Saferoom",
    author = "N3wton",
    description = "Spawns a selection of melee weapons in the saferoom, at the start of each round.",
    version = VERSION
};

public OnPluginStart()
{
    decl String:GameName[12];
    GetGameFolderName(GameName, sizeof(GameName));
    if( !StrEqual(GameName, "left4dead2") )
        SetFailState( "Melee In The Saferoom is only supported on left 4 dead 2." );
        
    CreateConVar( "l4d2_MITSR_Version",     VERSION, "The version of Melee In The Saferoom"); 
    g_hEnabled              = CreateConVar( "l4d2_MITSR_Enabled",       "1", "Should the plugin be enabled"); 
    g_hWeaponRandom         = CreateConVar( "l4d2_MITSR_Random",        "1", "Spawn Random Weapons (1) or custom list (0)"); 
    g_hWeaponRandomAmount   = CreateConVar( "l4d2_MITSR_Amount",        "8", "Number of weapons to spawn if l4d2_MITSR_Random is 1"); 
    g_hWeaponBaseballBat    = CreateConVar( "l4d2_MITSR_BaseballBat",   "1", "Number of baseball bats to spawn (l4d2_MITSR_Random must be 0)");
    g_hWeaponCricketBat     = CreateConVar( "l4d2_MITSR_CricketBat",    "1", "Number of cricket bats to spawn (l4d2_MITSR_Random must be 0)");
    g_hWeaponCrowbar        = CreateConVar( "l4d2_MITSR_Crowbar",   "1", "Number of crowbars to spawn (l4d2_MITSR_Random must be 0)");
    g_hWeaponElecGuitar     = CreateConVar( "l4d2_MITSR_ElecGuitar",    "1", "Number of electric guitars to spawn (l4d2_MITSR_Random must be 0)");
    g_hWeaponFireAxe            = CreateConVar( "l4d2_MITSR_FireAxe",       "1", "Number of fireaxes to spawn (l4d2_MITSR_Random must be 0)");
    g_hWeaponFryingPan      = CreateConVar( "l4d2_MITSR_FryingPan", "1", "Number of frying pans to spawn (l4d2_MITSR_Random must be 0)");
    g_hWeaponGolfClub       = CreateConVar( "l4d2_MITSR_GolfClub",  "1", "Number of golf clubs to spawn (l4d2_MITSR_Random must be 0)");
    g_hWeaponKnife          = CreateConVar( "l4d2_MITSR_Knife",     "1", "Number of knifes to spawn (l4d2_MITSR_Random must be 0)");
    g_hWeaponKatana         = CreateConVar( "l4d2_MITSR_Katana",        "1", "Number of katanas to spawn (l4d2_MITSR_Random must be 0)");
    g_hWeaponMachete            = CreateConVar( "l4d2_MITSR_Machete",       "1", "Number of machetes to spawn (l4d2_MITSR_Random must be 0)");
    g_hWeaponRiotShield     = CreateConVar( "l4d2_MITSR_RiotShield",    "1", "Number of riot shields to spawn (l4d2_MITSR_Random must be 0)");
    g_hWeaponTonfa          = CreateConVar( "l4d2_MITSR_Tonfa",     "1", "Number of tonfas to spawn (l4d2_MITSR_Random must be 0)");
    
    HookEvent( "round_start", Event_RoundStart );
    
    RegAdminCmd("sm_melee", Command_SMMelee, ADMFLAG_KICK, "Lists all melee weapons spawnable in current campaign" );
}

public Action:Command_SMMelee(client, args)
{
    for( new i = 0; i < g_iMeleeClassCount; i++ )
    {
        PrintToChat( client, "%d : %s", i, g_sMeleeClass[i] );
    }
}

public OnMapStart()
{
    PrecacheModel( "models/weapons/melee/v_bat.mdl", true );
    PrecacheModel( "models/weapons/melee/v_cricket_bat.mdl", true );
    PrecacheModel( "models/weapons/melee/v_crowbar.mdl", true );
    PrecacheModel( "models/weapons/melee/v_electric_guitar.mdl", true );
    PrecacheModel( "models/weapons/melee/v_fireaxe.mdl", true );
    PrecacheModel( "models/weapons/melee/v_frying_pan.mdl", true );
    PrecacheModel( "models/weapons/melee/v_golfclub.mdl", true );
    PrecacheModel( "models/weapons/melee/v_katana.mdl", true );
    PrecacheModel( "models/weapons/melee/v_machete.mdl", true );
    PrecacheModel( "models/weapons/melee/v_tonfa.mdl", true );
    
    PrecacheModel( "models/weapons/melee/w_bat.mdl", true );
    PrecacheModel( "models/weapons/melee/w_cricket_bat.mdl", true );
    PrecacheModel( "models/weapons/melee/w_crowbar.mdl", true );
    PrecacheModel( "models/weapons/melee/w_electric_guitar.mdl", true );
    PrecacheModel( "models/weapons/melee/w_fireaxe.mdl", true );
    PrecacheModel( "models/weapons/melee/w_frying_pan.mdl", true );
    PrecacheModel( "models/weapons/melee/w_golfclub.mdl", true );
    PrecacheModel( "models/weapons/melee/w_katana.mdl", true );
    PrecacheModel( "models/weapons/melee/w_machete.mdl", true );
    PrecacheModel( "models/weapons/melee/w_tonfa.mdl", true );
    PrecacheModel( "models/w_models/weapons/w_sniper_scout.mdl");
    PrecacheModel( "models/v_models/v_snip_scout.mdl");
    
    PrecacheGeneric( "scripts/melee/baseball_bat.txt", true );
    PrecacheGeneric( "scripts/melee/cricket_bat.txt", true );
    PrecacheGeneric( "scripts/melee/crowbar.txt", true );
    PrecacheGeneric( "scripts/melee/electric_guitar.txt", true );
    PrecacheGeneric( "scripts/melee/fireaxe.txt", true );
    PrecacheGeneric( "scripts/melee/frying_pan.txt", true );
    PrecacheGeneric( "scripts/melee/golfclub.txt", true );
    PrecacheGeneric( "scripts/melee/katana.txt", true );
    PrecacheGeneric( "scripts/melee/machete.txt", true );
    PrecacheGeneric( "scripts/melee/tonfa.txt", true );

    new index = CreateEntityByName("weapon_sniper_scout");
    DispatchSpawn(index);
    RemoveEdict(index);
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    if( !GetConVarBool( g_hEnabled ) ) return Plugin_Continue;
    
    g_bSpawnedMelee = false;
    
    if( g_iRound == 2 && IsVersus() ) g_iRound = 1; else g_iRound = 2;
    
    GetMeleeClasses();
    
    CreateTimer( 1.0, Timer_SpawnMelee );
    
    return Plugin_Continue;
}

public Action:Timer_SpawnMelee( Handle:timer )
{
    new client = GetInGameClient();

    if( client != 0 && !g_bSpawnedMelee )
    {
        decl Float:SpawnPosition[3], Float:SpawnAngle[3];
        GetClientAbsOrigin( client, SpawnPosition );
        SpawnPosition[2] += 20; SpawnAngle[0] = 90.0;
        
        if( GetConVarBool( g_hWeaponRandom ) )
        {
            new i = 0;
            while( i < GetConVarInt( g_hWeaponRandomAmount ) )
            {
                new RandomMelee = GetRandomInt( 0, g_iMeleeClassCount-1 );
                if( IsVersus() && g_iRound == 2 ) RandomMelee = g_iMeleeRandomSpawn[i]; 
                SpawnMelee( g_sMeleeClass[RandomMelee], SpawnPosition, SpawnAngle );
                if( IsVersus() && g_iRound == 1 ) g_iMeleeRandomSpawn[i] = RandomMelee;
                i++;
            }
            g_bSpawnedMelee = true;
        }
        else
        {
            SpawnCustomList( SpawnPosition, SpawnAngle );
            g_bSpawnedMelee = true;
        }
    }
    else
    {
        if( !g_bSpawnedMelee ) CreateTimer( 1.0, Timer_SpawnMelee );
    }
}

stock SpawnCustomList( Float:Position[3], Float:Angle[3] )
{
    decl String:ScriptName[32];
    
    //Spawn Basseball Bats
    if( GetConVarInt( g_hWeaponBaseballBat ) > 0 )
    {
        for( new i = 0; i < GetConVarInt( g_hWeaponBaseballBat ); i++ )
        {
            GetScriptName( "baseball_bat", ScriptName );
            SpawnMelee( ScriptName, Position, Angle );
        }
    }
    
    //Spawn Cricket Bats
    if( GetConVarInt( g_hWeaponCricketBat ) > 0 )
    {
        for( new i = 0; i < GetConVarInt( g_hWeaponCricketBat ); i++ )
        {
            GetScriptName( "cricket_bat", ScriptName );
            SpawnMelee( ScriptName, Position, Angle );
        }
    }
    
    //Spawn Crowbars
    if( GetConVarInt( g_hWeaponCrowbar ) > 0 )
    {
        for( new i = 0; i < GetConVarInt( g_hWeaponCrowbar ); i++ )
        {
            GetScriptName( "crowbar", ScriptName );
            SpawnMelee( ScriptName, Position, Angle );
        }
    }
    
    //Spawn Electric Guitars
    if( GetConVarInt( g_hWeaponElecGuitar ) > 0 )
    {
        for( new i = 0; i < GetConVarInt( g_hWeaponElecGuitar ); i++ )
        {
            GetScriptName( "electric_guitar", ScriptName );
            SpawnMelee( ScriptName, Position, Angle );
        }
    }
    
    //Spawn Fireaxes
    if( GetConVarInt( g_hWeaponFireAxe ) > 0 )
    {
        for( new i = 0; i < GetConVarInt( g_hWeaponFireAxe ); i++ )
        {
            GetScriptName( "fireaxe", ScriptName );
            SpawnMelee( ScriptName, Position, Angle );
        }
    }
    
    //Spawn Frying Pans
    if( GetConVarInt( g_hWeaponFryingPan ) > 0 )
    {
        for( new i = 0; i < GetConVarInt( g_hWeaponFryingPan ); i++ )
        {
            GetScriptName( "frying_pan", ScriptName );
            SpawnMelee( ScriptName, Position, Angle );
        }
    }
    
    //Spawn Golfclubs
    if( GetConVarInt( g_hWeaponGolfClub ) > 0 )
    {
        for( new i = 0; i < GetConVarInt( g_hWeaponGolfClub ); i++ )
        {
            GetScriptName( "golfclub", ScriptName );
            SpawnMelee( ScriptName, Position, Angle );
        }
    }
    
    //Spawn Knifes
    if( GetConVarInt( g_hWeaponKnife ) > 0 )
    {
        for( new i = 0; i < GetConVarInt( g_hWeaponKnife ); i++ )
        {
            GetScriptName( "hunting_knife", ScriptName );
            SpawnMelee( ScriptName, Position, Angle );
        }
    }
    
    //Spawn Katanas
    if( GetConVarInt( g_hWeaponKatana ) > 0 )
    {
        for( new i = 0; i < GetConVarInt( g_hWeaponKatana ); i++ )
        {
            GetScriptName( "katana", ScriptName );
            SpawnMelee( ScriptName, Position, Angle );
        }
    }
    
    //Spawn Machetes
    if( GetConVarInt( g_hWeaponMachete ) > 0 )
    {
        for( new i = 0; i < GetConVarInt( g_hWeaponMachete ); i++ )
        {
            GetScriptName( "machete", ScriptName );
            SpawnMelee( ScriptName, Position, Angle );
        }
    }
    
    //Spawn RiotShields
    if( GetConVarInt( g_hWeaponRiotShield ) > 0 )
    {
        for( new i = 0; i < GetConVarInt( g_hWeaponRiotShield ); i++ )
        {
            GetScriptName( "riotshield", ScriptName );
            SpawnMelee( ScriptName, Position, Angle );
        }
    }
    
    //Spawn Tonfas
    if( GetConVarInt( g_hWeaponTonfa ) > 0 )
    {
        for( new i = 0; i < GetConVarInt( g_hWeaponTonfa ); i++ )
        {
            GetScriptName( "tonfa", ScriptName );
            SpawnMelee( ScriptName, Position, Angle );
        }
    }
}

stock SpawnMelee( const String:Class[32], Float:Position[3], Float:Angle[3] )
{
    decl Float:SpawnPosition[3], Float:SpawnAngle[3];
    SpawnPosition = Position;
    SpawnAngle = Angle;
    
    SpawnPosition[0] += ( -10 + GetRandomInt( 0, 20 ) );
    SpawnPosition[1] += ( -10 + GetRandomInt( 0, 20 ) );
    SpawnPosition[2] += GetRandomInt( 0, 10 );
    SpawnAngle[1] = GetRandomFloat( 0.0, 360.0 );

    new MeleeSpawn = CreateEntityByName( "weapon_melee" );
    DispatchKeyValue( MeleeSpawn, "melee_script_name", Class );
    DispatchSpawn( MeleeSpawn );
    TeleportEntity(MeleeSpawn, SpawnPosition, SpawnAngle, NULL_VECTOR );
}

stock SpawnScout(Float:Position[3], Float:Angle[3])
{
    decl Float:SpawnPosition[3], Float:SpawnAngle[3];
    SpawnPosition = Position;
    SpawnAngle = Angle;
    
    SpawnPosition[0] += ( -10 + GetRandomInt( 0, 20 ) );
    SpawnPosition[1] += ( -10 + GetRandomInt( 0, 20 ) );
    SpawnPosition[2] += GetRandomInt( 0, 10 );
    SpawnAngle[1] = GetRandomFloat( 0.0, 360.0 );

    new Spawn = CreateEntityByName("weapon_sniper_scout");
    DispatchSpawn(Spawn);
    TeleportEntity(Spawn, SpawnPosition, SpawnAngle, NULL_VECTOR );
}

stock GetMeleeClasses()
{
    new MeleeStringTable = FindStringTable( "MeleeWeapons" );
    g_iMeleeClassCount = GetStringTableNumStrings( MeleeStringTable );
    
    for( new i = 0; i < g_iMeleeClassCount; i++ )
    {
        ReadStringTable( MeleeStringTable, i, g_sMeleeClass[i], 32 );
    }   
}

stock GetScriptName( const String:Class[32], String:ScriptName[32] )
{
    for( new i = 0; i < g_iMeleeClassCount; i++ )
    {
        if( StrContains( g_sMeleeClass[i], Class, false ) == 0 )
        {
            Format( ScriptName, 32, "%s", g_sMeleeClass[i] );
            return;
        }
    }
    Format( ScriptName, 32, "%s", g_sMeleeClass[0] );   
}

stock GetInGameClient()
{
    for( new x = 1; x <= GetClientCount( true ); x++ )
    {
        if( IsClientInGame( x ) && GetClientTeam( x ) == 2 )
        {
            return x;
        }
    }
    return 0;
}

stock bool:IsVersus()
{
    new String:GameMode[32];
    GetConVarString( FindConVar( "mp_gamemode" ), GameMode, 32 );
    if( StrContains( GameMode, "versus", false ) != -1 ) return true;
    return false;
}