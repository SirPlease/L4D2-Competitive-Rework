#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
//#include <sdkhooks>

#define PLUGIN_VERSION "1.0.1"

public Plugin myinfo = 
{
    name = "[L4D2] Fix Jockey Hitbox",
    author = "Forgetest",
    description = "Fix jockey hitbox issues when riding survivors.",
    version = PLUGIN_VERSION,
    url = "https://github.com/Target5150/MoYu_Server_Stupid_Plugins"
};

public void OnPluginStart()
{
    HookEvent("jockey_ride", Event_JockeyRide);
}

void Event_JockeyRide(Event event, const char[] name, bool dontBroadcast)
{
    int victim = GetClientOfUserId(event.GetInt("victim"));
    if (victim && IsClientInGame(victim))
    {
        // Fix bounding box
        if (GetEntityFlags(victim) & FL_DUCKING)
        {
            SetEntityFlags(victim, GetEntityFlags(victim) & ~FL_DUCKING);
        }
    }
}

// not implemented, and not likely to be implemented, need more investigations

    /*int client = GetClientOfUserId(event.GetInt("userid"));
    if (client && IsClientInGame(client))
    {
        // Fix model unaligned with hitbox
        // -
        // TODO:
        // Improvements? Because changing model scale inevitably brings model collisions.
        // Ideal solution would be offseting the model to be a bit lower than usual.
        // -
        // Question:
        // m_flModelScale also changes the size of hitbox. Is it good for competitive scene?
		
        float flModelScale = GetCharacterScale(GetEntProp(victim, Prop_Send, "m_survivorCharacter"));
        PrintToChatAll("GetCharacterScale = %f", flModelScale);
		
        if (flModelScale != 1.0)
        {
            // convert model scaling into height offset only
            float vecOrigin[3];
			
            vecOrigin[0] = 0.0;
            vecOrigin[1] = 0.0;
            vecOrigin[2] = 71.0 * (flModelScale - 1.0); // hardcode that bbox max 71.0 here as nowhere else defined
			
            PrintToChatAll("flModelScale = %f, flOffset = %f", flModelScale, vecOrigin[2]);
			
            char buffer[64];
            if ( GetEntPropFloat(client, Prop_Send, "m_vecOrigin[2]") != vecOrigin[2] )
            {
                FormatEx(buffer, sizeof(buffer), "Ent(%i).SetLocalOrigin(Vector(0,0,%f))", client, vecOrigin[2]);
                L4D2_ExecVScriptCode(buffer);
            }
			
            if ( GetEntPropFloat(client, Prop_Send, "m_flModelScale") != 1.0 )
            {
                FormatEx(buffer, sizeof(buffer), "Ent(%i).SetModelScale(1.0,0.0)", client);
                L4D2_ExecVScriptCode(buffer);
                SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.0);
            }
        }
        //CreateTimer(0.6, SDK_OnPostThink_Post, client);
        //SDKHook(client, SDKHook_PostThinkPost, SDK_OnPostThink_Post);
    }
}

Action SDK_OnPostThink_Post(Handle tiemr, int client)
{
    int victim = -1;
	
    if ( IsClientInGame(client)
        && GetClientTeam(client) == 3
        && IsPlayerAlive(client)
        && GetEntProp(client, Prop_Send, "m_zombieClass") == 5
        && (victim = GetEntPropEnt(client, Prop_Send, "m_jockeyVictim")) != -1 )
    {
        float flModelScale = GetCharacterScale(GetEntProp(victim, Prop_Send, "m_survivorCharacter"));
        PrintToChatAll("GetCharacterScale = %f", flModelScale);
		
        if (flModelScale != 1.0)
        {
            // convert model scaling into height offset only
            float vecOrigin[3];
			
            vecOrigin[0] = 0.0;
            vecOrigin[1] = 0.0;
            vecOrigin[2] = 71.0 * (flModelScale - 1.0); // hardcode that bbox max 71.0 here as nowhere else defined
			
            PrintToChatAll("flModelScale = %f, flOffset = %f", flModelScale, vecOrigin[2]);
			
            char buffer[64];
            if ( GetEntPropFloat(client, Prop_Send, "m_vecOrigin[2]") != vecOrigin[2] )
            {
                FormatEx(buffer, sizeof(buffer), "Ent(%i).SetLocalOrigin(Vector(0,0,%f))", client, vecOrigin[2]);
                L4D2_ExecVScriptCode(buffer);
            }
			
            if ( GetEntPropFloat(client, Prop_Send, "m_flModelScale") != 1.0 )
            {
                FormatEx(buffer, sizeof(buffer), "Ent(%i).SetModelScale(1.0,0.0)", client);
                L4D2_ExecVScriptCode(buffer);
                SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.0);
            }
        }
		
        //return;
    }
	
    //SDKUnhook(client, SDKHook_PostThinkPost, SDK_OnPostThink_Post);
}

float GetCharacterScale(int survivorCharacter)
{
    static const float s_flScales[] = {
        0.888,	// Rochelle
        1.05,	// Coach
        0.955,	// Ellis
        1.0,	// Bill
        0.888	// Zoey
    };
	
    int index = ConvertToExternalCharacter(survivorCharacter) - 1;
	
    return (index >= 0 && index <= 4) ? s_flScales[index] : 1.0;
}

int ConvertToExternalCharacter(int survivorCharacter)
{
    if (L4D2_GetSurvivorSetMod() == 1)
    {
        if (survivorCharacter >= 0)
        {
            switch (survivorCharacter)
            {
                case 2: return 7;
                case 3: return 6;
                default: return survivorCharacter + 4;
            }
        }
    }
	
    return survivorCharacter;
}*/