#if defined _l4d_stats_api_included
	#endinput
#endif
#define _l4d_stats_api_included

// 对外 native、forward 和 Top100 缓存 API。

//Startup
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	//API
	RegPluginLibrary("l4d_stats");
	
	CreateNative("l4dstats_GetClientScore", Native_GetClientScore);
	CreateNative("l4dstats_GetClientQuarterScore", Native_GetClientQuarterScore);
	CreateNative("l4dstats_GetClientQuarterPlayTime", Native_GetClientQuarterPlayTime);
	CreateNative("l4dstats_GetClientQuarterRank", Native_GetClientQuarterRank);
	CreateNative("l4dstats_GetCurrentQuarter", Native_GetCurrentQuarter);
	CreateNative("l4dstats_AdddClientScore", Native_AddClientScore);
	CreateNative("l4dstats_AddClientScore", Native_AddClientScore);
	CreateNative("l4dstats_GetClientPlayTime", Native_GetClientPlayTime);
	CreateNative("l4dstats_IsTopPlayer", Native_IsTopPlayer);
	CreateNative("l4dstats_IsQuarterTopPlayer", Native_IsQuarterTopPlayer);

	//forward
	AnnounceGameTime = CreateGlobalForward("l4dstats_AnnounceGameTime", ET_Ignore,Param_Cell);
	SuccessGetPlayerTime = CreateGlobalForward("l4dstats_SuccessGetPlayerTime", ET_Ignore,Param_Cell);

	return APLRes_Success;
}

//API
public int Native_GetClientScore(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	if (client < 1 || client > MaxClients)
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
	}
	if (!IsClientConnected(client))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not connected", client);
	}
	if(IsFakeClient(client)){
		return ThrowNativeError(SP_ERROR_NATIVE, "Client %d is A bot", client);
	}
	
	return ClientPoints[client];
}

public int Native_GetClientPlayTime(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	if (client < 1 || client > MaxClients)
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
	}
	if (!IsClientConnected(client))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not connected", client);
	}
	if(IsFakeClient(client)){
		return ThrowNativeError(SP_ERROR_NATIVE, "Client %d is A bot", client);
	}
	
	return ClientPlayTime[client];
}

public int Native_GetClientQuarterScore(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	if (client < 1 || client > MaxClients)
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
	}
	if (!IsClientConnected(client))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not connected", client);
	}
	if(IsFakeClient(client)){
		return ThrowNativeError(SP_ERROR_NATIVE, "Client %d is A bot", client);
	}
	
	QuarterRank_EnsureCurrentQuarter();
	return ClientQuarterPoints[client];
}

public int Native_GetClientQuarterPlayTime(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	if (client < 1 || client > MaxClients)
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
	}
	if (!IsClientConnected(client))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not connected", client);
	}
	if(IsFakeClient(client)){
		return ThrowNativeError(SP_ERROR_NATIVE, "Client %d is A bot", client);
	}
	
	QuarterRank_EnsureCurrentQuarter();
	return ClientQuarterPlayTime[client];
}

public int Native_GetClientQuarterRank(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	if (client < 1 || client > MaxClients)
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
	}
	if (!IsClientConnected(client))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not connected", client);
	}
	if(IsFakeClient(client)){
		return ThrowNativeError(SP_ERROR_NATIVE, "Client %d is A bot", client);
	}
	
	QuarterRank_EnsureCurrentQuarter();
	return ClientQuarterRank[client];
}

public int Native_GetCurrentQuarter(Handle plugin, int numParams)
{
	return QuarterRank_GetCurrentQuarter();
}

public int Native_IsTopPlayer(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int ranklimit = GetNativeCell(2);
	if (client < 1 || client > MaxClients)
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
	}
	if (!IsClientConnected(client))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not connected", client);
	}
	if(IsFakeClient(client)){
		return ThrowNativeError(SP_ERROR_NATIVE, "Client %d is A bot", client);
	}
	if(ranklimit<1 || ranklimit>100){
		return ThrowNativeError(SP_ERROR_NATIVE, "rank limit value wrong");
	}

	if(ClientPoints[client] >= CheckPlayerPoint[ranklimit-1] && CheckPlayerPoint[ranklimit-1]> 0)
		return 1;
	else
		return 0;
}

public int Native_IsQuarterTopPlayer(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int ranklimit = GetNativeCell(2);
	if (client < 1 || client > MaxClients)
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
	}
	if (!IsClientConnected(client))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not connected", client);
	}
	if(IsFakeClient(client)){
		return ThrowNativeError(SP_ERROR_NATIVE, "Client %d is A bot", client);
	}
	if(ranklimit < 1 || ranklimit > 100){
		return ThrowNativeError(SP_ERROR_NATIVE, "rank limit value wrong");
	}

	QuarterRank_EnsureCurrentQuarter();
	if(ClientQuarterPoints[client] >= CheckQuarterPlayerPoint[ranklimit - 1] && CheckQuarterPlayerPoint[ranklimit - 1] > 0)
		return 1;
	else
		return 0;
}

// Find a player from Top 100 ranking Points.
public GetTop100PlayerScore()
{
	if (db == INVALID_HANDLE)
		return;

	decl String:query[512];
	Format(query, sizeof(query), "SELECT (%s) as totalpoints FROM %splayers ORDER BY totalpoints DESC LIMIT 100", DB_PLAYERS_TOTALPOINTS, DbPrefix);
	SQL_TQuery(db, GetTop100PlayersScore, query,0);
}

// Send the Top 10 player's info to the client.
public GetTop100PlayersScore(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("GetPlayerScore failed! Reason: %s", error);
		return;
	}
	
	int i=0;
	while (SQL_FetchRow(hndl))
	{
		CheckPlayerPoint[i++] = SQL_FetchInt(hndl, 0);
	}
}

public int Native_AddClientScore(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	if (client < 1 || client > MaxClients)
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
	}
	if (!IsClientConnected(client))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not connected", client);
	}
	if(IsFakeClient(client)){
		return ThrowNativeError(SP_ERROR_NATIVE, "Client %d is A bot", client);
	}
	
	int Score = GetNativeCell(2);
	decl String:Reason[MAX_LINE_WIDTH];
	strcopy(Reason, sizeof(Reason), "native_add_score");
	if (numParams >= 3)
	{
		GetNativeString(3, Reason, sizeof(Reason));
		TrimString(Reason);
		if (Reason[0] == '\0')
			strcopy(Reason, sizeof(Reason), "native_add_score");
	}

	ScoreLog_SetContext(Reason, "native=l4dstats_AddClientScore");
	if (Stats_AwardClientScore(client, Score))
		ClientPoints[client] += Score;
	else
		ScoreLog_ClearContext();
	return ClientPoints[client];
}
