#pragma semicolon 1
#include <sourcemod>

#define CVAR_PREFIX			"confogl_"
#define CVAR_FLAGS			FCVAR_NONE
#define CVAR_PRIVATE		(FCVAR_DONTRECORD|FCVAR_PROTECTED)

Handle:CreateConVarEx(const String:name[], const String:defaultValue[], const String:description[]="", flags=0, bool:hasMin=false, Float:min=0.0, bool:hasMax=false, Float:max=0.0)
{
	decl String:sBuffer[128], Handle:cvar;
	Format(sBuffer,sizeof(sBuffer),"%s%s",CVAR_PREFIX,name);
	flags = flags | CVAR_FLAGS;
	cvar = CreateConVar(sBuffer,defaultValue,description,flags,hasMin,min,hasMax,max);
	
	return cvar;
}

Handle:FindConVarEx(const String:name[])
{
	decl String:sBuffer[128];
	Format(sBuffer,sizeof(sBuffer),"%s%s",CVAR_PREFIX,name);
	return FindConVar(sBuffer);
}

new bool:bIsPluginEnabled = false;

bool:IsHumansOnServer()
{
	for(new i=1;i<=MaxClients;i++)
	{
		if(IsClientConnected(i) && !IsFakeClient(i))
		{
			return true;
		}
	}
	return false;
}

bool:IsVersus()
{
	decl String:GameMode[32];
	GetConVarString(FindConVar("mp_gamemode"), GameMode, sizeof(GameMode));
	if(StrContains(GameMode, "versus", false) != -1)
	{
		return true;
	}
	return false;
}

bool:IsScavenge()
{
	decl String:GameMode[32];
	GetConVarString(FindConVar("mp_gamemode"), GameMode, sizeof(GameMode));
	if(StrContains(GameMode, "scavenge", false) != -1)
	{
		return true;
	}
	return false;
}

bool:IsPluginEnabled(bool:bSetStatus=false,bool:bStatus=false)
{
	if(bSetStatus)
	{
		bIsPluginEnabled = bStatus;
	}
	return bIsPluginEnabled;
}

stock GetSurvivorPermanentHealth(client)
{
	return GetEntProp(client, Prop_Send, "m_iHealth");
}

stock GetSurvivorTempHealth(client)
{
	new temphp = RoundToCeil(GetEntPropFloat(client, Prop_Send, "m_healthBuffer") - ((GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime")) * GetConVarFloat(FindConVar("pain_pills_decay_rate")))) - 1;
	return temphp > 0 ? temphp : 0;
}

stock GetSurvivorIncapCount(client)
{
	return GetEntProp(client, Prop_Send, "m_currentReviveCount");
}

stock bool:IsSurvivor(client)
{
	return IsClientInGame(client) && GetClientTeam(client) == 2;
}

stock ZeroVector(Float:vector[3])
{
	vector=NULL_VECTOR;
}

stock AddToVector(Float:to[3], Float:from[3])
{
	to[0]+=from[0];
	to[1]+=from[1];
	to[2]+=from[2];
}

stock CopyVector(Float:to[3], Float:from[3])
{
	to=from;
}

stock GetURandomIntRange(min, max) { return RoundToNearest((GetURandomFloat() * (max-min))+min); }

/**
 * Finds the first occurrence of a pattern in another string.
 *
 * @param str			String to search in.
 * @param pattern		String pattern to search for
 * @param reverse		False (default) to search forward, true to search 
 *						backward.
 * @return				The index of the first character of the first 
 *						occurrence of the pattern in the string, or -1 if the 
 *						character was not found.
 */
stock FindPatternInString(const String:str[], const String:pattern[], bool:reverse = false)
{
	new i, c, len;
	
	len = strlen(pattern);
	c = pattern[0];
	while(i < len && (i = FindCharInString(str[i], c, reverse)) != -1)
		if(strncmp(str[i], pattern, len))
			return i;
	return -1;
}

/**
 * Counts the number of occurences of pattern in another string.
 *
 * @param str			String to search in.
 * @param pattern		String pattern to search for
 * @param overlap		False (default) to count only non-overlapping  
 *						occurences, true to count matches within other
 *						occurences.
 * @return				The number of occurences of the pattern in the string
 */
stock CountPatternsInString(const String:str[], const String:pattern[], bool:overlap=false)
{
	new off, i, delta, cnt, len = strlen(str);
	delta = overlap ? strlen(pattern) : 1;
	while(i < len && (off = FindPatternInString(str[i], pattern)) != -1)
	{
		cnt++;
		i+=off+delta;
	}
	return cnt;
}

/**
 * Counts the number of occurences of pattern in another string.
 *
 * @param str			String to search in.
 * @param c				Character to search for.
 * @return				The number of occurences of the pattern in the string
 */
stock CountCharsInString(const String:str[], c)
{
	new off, i, cnt, len = strlen(str);

	while(i < len && (off = FindCharInString(str[i], c)) != -1)
	{
		cnt++;
		i+=off+1;
	}
	return cnt;
}