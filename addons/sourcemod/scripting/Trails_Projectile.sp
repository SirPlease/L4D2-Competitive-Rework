#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <l4d2util>
#pragma semicolon 1

//	Colors || Цвета                                                                                                                                                 
// 	http://www.stm.dp.ua/web-design/color-html.php                                         
// 	{цвет,цвет,цвет,прозрачность} || {color,color,color,transparent} "0 - 255"              
//  Grenade Trails (Fredd) https://forums.alliedmods.net/showthread.php?p=594091

#define pipeColor      {255,48,48,255}  // Firebrick1
#define molotovColor   {255,255,0,255}  // Yellow
#define vomiteColor    {50,205,50,255}  // LimeGreen
#define grenadeColor   {160,32,240,255} // Purple
#define tankrockColor  {255,0,255,255}  // Magenta

new Sprite1;
new Sprite2;

float g_fwidth = 2.0;

new Handle:TrailsProjectileEnabled;

public Plugin:myinfo =
{
    name = "Trails_Projectile",
    author = "Fredd, Mister Game Over",
    description = "Trails Projectile",
    version = "1.0",
    url = "https://vk.com/club151027520"
}

public OnPluginStart()
{
    TrailsProjectileEnabled	=	CreateConVar("trails_enables",	"1",	"Enables/Disables plugin",	FCVAR_NOTIFY);		
}
    
public OnMapStart()
{
    Sprite1 = PrecacheModel("materials/sprites/laserbeam.vmt");    
    //Sprite2 = PrecacheModel("materials/sprites/glow.vmt");  
    Sprite2 = Sprite1;
}

// ищем действие которое нам нужно || List Entities (Projectile)
// https://developer.valvesoftware.com/wiki/List_of_L4D2_Entities
// pipe bomb projectile         || полёт бомбы
// molotov projectile           || полёт молотова
// grenade launcher projectile  || полёт гранаты
// vomitjar projectile          || полёт банки с желчью 
// tank rock                    || полёт камня
// Float:2.0 = Time Live Trail  || время жизни трейла
        
public OnEntityCreated(Entity, const String:Classname[])
{
    if(GetConVarInt(TrailsProjectileEnabled) != 1)
        return;
        
    if(strcmp(Classname, "pipe_bomb_projectile") == 0)
    {
        switch(GetRandomInt(1,2))
        {
            case 1:
            {
                TE_SetupBeamFollow(Entity, Sprite1, 0, Float:2.0, g_fwidth, g_fwidth, 5,  pipeColor); 
                TE_SendToInf();   								
            }		
            case 2:
            {
                TE_SetupBeamFollow(Entity, Sprite2, 0, Float:2.0, g_fwidth, g_fwidth, 5,  pipeColor);
                TE_SendToInf();   								   								
            }
        }	
    }
    else if(strcmp(Classname, "molotov_projectile") == 0)
    {
        switch(GetRandomInt(1,2))
        {
            case 1:
            {
                TE_SetupBeamFollow(Entity, Sprite1, 0, Float:2.0, g_fwidth, g_fwidth, 5, molotovColor);
                TE_SendToInf();   								
            }		
            case 2:
            {
                TE_SetupBeamFollow(Entity, Sprite2, 0, Float:2.0, g_fwidth, g_fwidth, 5, molotovColor);
                TE_SendToInf();   								
            }
        }	
    }
    else if(strcmp(Classname, "vomitjar_projectile") == 0)
    {
        switch(GetRandomInt(1,2))
        {
            case 1:
            {
                TE_SetupBeamFollow(Entity, Sprite1, 0, Float:2.0, g_fwidth, g_fwidth, 5, vomiteColor);
                TE_SendToInf();   								
            }		
            case 2:
            {
                TE_SetupBeamFollow(Entity, Sprite2, 0, Float:2.0, g_fwidth, g_fwidth, 5, vomiteColor);
                TE_SendToInf();   								  								
            }
        }	
    }          
    else if(strcmp(Classname, "grenade_launcher_projectile") == 0)
    {
        switch(GetRandomInt(1,2))
        {
            case 1:
            {
                TE_SetupBeamFollow(Entity, Sprite1, 0, Float:2.0, g_fwidth, g_fwidth, 5,  grenadeColor);
                TE_SendToInf();   								
            }		
            case 2:
            {
                TE_SetupBeamFollow(Entity, Sprite2, 0, Float:2.0, g_fwidth, g_fwidth, 5,  grenadeColor);
                TE_SendToInf();   															
            }
        }	
    }   
    else if(strcmp(Classname, "tank_rock") == 0)
    {
        switch(GetRandomInt(1,2))
        {
            case 1:
            {
                TE_SetupBeamFollow(Entity, Sprite1, 0, Float:2.0, g_fwidth, g_fwidth, 5, tankrockColor);
                TE_SendToInf();   		
            }		
            case 2:
            {
                TE_SetupBeamFollow(Entity, Sprite2, 0, Float:2.0, g_fwidth, g_fwidth, 5, tankrockColor);
                TE_SendToInf();   								
            }
        }	
    }       
    return;
}

void TE_SendToInf()
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsSurvivor(i) && !IsFakeClient(i)){
            TE_SendToClient(i);
        }
    }
}

