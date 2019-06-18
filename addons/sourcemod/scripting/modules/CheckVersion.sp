#pragma semicolon 1

#include <sourcemod>
#include <socket>

#define CV_DEBUG 0


#define 		CV_VERSION			PLUGIN_VERSION
#define			CV_VERSION_MAXLEN	32
const	Float:	CV_NOTIFYTIME		= 10.0;

new 	Handle:	CV_hNotify;
new 	bool:	CV_IsNewMatch 		= true;
new 	bool:	CV_bNotify	 		= true;
new 	bool:	CV_bHaveNotified	= false;

CV_OnModuleStart()
{
	CV_hNotify = CreateConVarEx("match_checkversion","0","Check the current running version of Confogl to Confogl's homepage. Will notify players if the server is running an outdated version of Confogl");
	HookConVarChange(CV_hNotify,CV_ConVarChange);
	
	CV_bNotify = GetConVarBool(CV_hNotify);
}

public CV_ConVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	CV_bNotify = GetConVarBool(CV_hNotify);
}

CV_OnClientPutInServer()
{
	if(!IsPluginEnabled()){return;}
	new bool:bIsAMatchActive = IsAMatchActive();
	if(bIsAMatchActive && CV_IsNewMatch)
	{
		CV_IsNewMatch = false;
		
		if (CV_bNotify && !CV_bHaveNotified && StrContains(CV_VERSION, "BETA", false) > -1)
		{
			CV_bHaveNotified=true;
			CreateTimer(CV_NOTIFYTIME,CV_NotifyPlayersBeta);
		}
		else
		{
			new Handle:socket = SocketCreate(SOCKET_TCP, CV_OnSocketError);
			SocketConnect(socket, CV_OnSocketConnected, CV_OnSocketReceive, CV_OnSocketDisconnected, "www.dpi-clan.org", 80);
		}
	}
	else if(!bIsAMatchActive && !CV_IsNewMatch)
	{
		CV_IsNewMatch = true;
		CV_bHaveNotified = false;
	}
}

public CV_OnSocketConnected(Handle:socket, any:arg)
{
	decl String:requestStr[500];
	Format(requestStr, sizeof(requestStr), "GET /%s HTTP/1.0\r\nHost: %s\r\nConnection: close\r\n\r\n", "uploads/confogl/curVersion.txt", "www.dpi-clan.org");
	SocketSend(socket, requestStr);
}

public CV_OnSocketReceive(Handle:socket, String:receiveData[], const dataSize, any:hFile)
{
	new ver_offset, ver_count, itemp;
	if(CV_DEBUG || IsDebugEnabled())
		LogMessage("Recived data: %s", receiveData);
	
	while((itemp = FindPatternInString(receiveData[ver_offset], "\r\n\r\n")) != -1) 
		ver_offset += itemp + 4;
	if(CV_DEBUG || IsDebugEnabled())
		LogMessage("Header end found at %d", ver_offset);
	ver_count = CountCharsInString(receiveData[ver_offset], '\n')+1;
	if(CV_DEBUG || IsDebugEnabled())
		LogMessage("Counted %d current versions", ver_count);
	
	new String:ver_buf[ver_count][CV_VERSION_MAXLEN];
	ExplodeString(receiveData[ver_offset], "\n", ver_buf, ver_count, CV_VERSION_MAXLEN);
	
	for (new i; i < ver_count; i++)
	{
		TrimString(ver_buf[i]);
		if(StrEqual(ver_buf[i], CV_VERSION)) return;
	}
	
	//LogMessage("CONFOGL IS OUTDATED! Update @ http://confogl.googlecode.com/");  //took this out to stop spamming logs -epi
	
	if(CV_bNotify && !CV_bHaveNotified)
	{
		CV_bHaveNotified = true;
		CreateTimer(CV_NOTIFYTIME,CV_NotifyPlayers);
	}
}

public CV_OnSocketDisconnected(Handle:socket, any:arg)
{
	CloseHandle(socket);
}

public CV_OnSocketError(Handle:socket, const errorType, const errorNum, any:hFile)
{
	if (hFile != INVALID_HANDLE) CloseHandle(hFile);
	if (socket != INVALID_HANDLE) CloseHandle(socket);
}

public Action:CV_NotifyPlayers(Handle:timer)
{
	PrintToChatAll("[Confogl] This server is using an old version of Confogl, \"%s\"",CV_VERSION);
	PrintToChatAll("[Confogl] Get the newest version @ confogl.googlecode.com");
}

public Action:CV_NotifyPlayersBeta(Handle:timer)
{
	PrintToChatAll("[Confogl] This server is using a beta version of Confogl, \"%s\"",CV_VERSION);
	PrintToChatAll("[Confogl] Get the newest version @ confogl.googlecode.com");
}
