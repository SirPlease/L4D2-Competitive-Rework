
#define MSGLENGTH 		151
#define SOUNDFILE_PATH_LEN 		256
#define CHECKFLAG 		ADMFLAG_ROOT


/*****************************************************************


			G L O B A L   V A R S


*****************************************************************/
ConVar g_CvarPlaySound = null;
ConVar g_CvarPlaySoundFile = null;

ConVar g_CvarPlayDiscSound = null;
ConVar g_CvarPlayDiscSoundFile = null;

ConVar g_CvarMapStartNoSound = null;

bool noSoundPeriod = false;

/*****************************************************************


			L I B R A R Y   I N C L U D E S


*****************************************************************/
//#include "cannounce/joinmsg/allow.sp"
//#include "cannounce/joinmsg/disallow.sp"
//#include "cannounce/joinmsg/set.sp"
//#include "cannounce/joinmsg/sound.sp"


/*****************************************************************


			F O R W A R D   P U B L I C S


*****************************************************************/

void SetupJoinMsg()
{
	noSoundPeriod = false;
	
	//cvars
	g_CvarPlaySound = CreateConVar("sm_ca_playsound", "1", "Plays a specified (sm_ca_playsoundfile) sound on player connect");
	g_CvarPlaySoundFile = CreateConVar("sm_ca_playsoundfile", "ambient\\alarms\\klaxon1.wav", "Sound to play on player connect if sm_ca_playsound = 1");

	g_CvarPlayDiscSound = CreateConVar("sm_ca_playdiscsound", "0", "Plays a specified (sm_ca_playdiscsoundfile) sound on player discconnect");
	g_CvarPlayDiscSoundFile = CreateConVar("sm_ca_playdiscsoundfile", "weapons\\cguard\\charging.wav", "Sound to play on player discconnect if sm_ca_playdiscsound = 1");

	g_CvarMapStartNoSound = CreateConVar("sm_ca_mapstartnosound", "30.0", "Time to ignore all player join sounds on a map load");
}

void OnAdminMenuReady_JoinMsg()
{
	//Build the "Player Commands" category
	//TopMenuObject player_commands = FindTopMenuCategory(hTopMenu, ADMINMENU_PLAYERCOMMANDS);
	//
	//if (player_commands != INVALID_TOPMENUOBJECT)
	//{
	//	OnAdminMenuReady_JoinMsg_Allow(player_commands);
	//		
	//	OnAdminMenuReady_JoinMsg_DAllow(player_commands);
	//}
}


void OnMapStart_JoinMsg()
{
	float waitPeriod;
	
	noSoundPeriod = false;
	
	waitPeriod = g_CvarMapStartNoSound.FloatValue;
	
	if( waitPeriod > 0 )
	{
		noSoundPeriod = true;
		CreateTimer(waitPeriod, Timer_MapStartNoSound);	
	}
}

stock void OnPostAdminCheck_JoinMsg(const char[] steamId)
{
	char soundfile[SOUNDFILE_PATH_LEN];
	
	//if enabled and custom sound not already played, play all player sound
	if( g_CvarPlaySound.BoolValue)
	{
		g_CvarPlaySoundFile.GetString(soundfile, sizeof(soundfile));
		
		if( strlen(soundfile) > 0 && !noSoundPeriod)
		{
			EmitSoundToAll( soundfile );
		}
	}
}

void OnClientDisconnect_JoinMsg()
{
	char soundfile[SOUNDFILE_PATH_LEN];
	
	if( g_CvarPlayDiscSound.BoolValue)
	{
		g_CvarPlayDiscSoundFile.GetString(soundfile, sizeof(soundfile));
		
		if( strlen(soundfile) > 0)
		{
			EmitSoundToAll( soundfile );
		}
	}
}


void OnPluginEnd_JoinMsg()
{		
}


public Action Timer_MapStartNoSound(Handle timer)
{	
	noSoundPeriod = false;
	
	return Plugin_Handled;
}


/*****************************************************************


			P L U G I N   F U N C T I O N S


*****************************************************************/
void LoadSoundFilesAll()
{
	char c_soundFile[SOUNDFILE_PATH_LEN];
	char c_soundFileFullPath[SOUNDFILE_PATH_LEN + 6];
	
	char dc_soundFile[SOUNDFILE_PATH_LEN];
	char dc_soundFileFullPath[SOUNDFILE_PATH_LEN + 6];
	
	//download and cache connect sound
	if( g_CvarPlaySound.BoolValue)
	{
		g_CvarPlaySoundFile.GetString(c_soundFile, sizeof(c_soundFile));
		Format(c_soundFileFullPath, sizeof(c_soundFileFullPath), "sound/%s", c_soundFile);
		
		if( FileExists( c_soundFileFullPath ) )
		{
			AddFileToDownloadsTable(c_soundFileFullPath);
			
			PrecacheSound( c_soundFile );
		}
	}
	
	//cache disconnect sound
	if( g_CvarPlayDiscSound.BoolValue)
	{
		g_CvarPlayDiscSoundFile.GetString(dc_soundFile, sizeof(dc_soundFile));
		Format(dc_soundFileFullPath, sizeof(dc_soundFileFullPath), "sound/%s", dc_soundFile);
		
		if( FileExists( dc_soundFileFullPath ) )
		{
			AddFileToDownloadsTable(dc_soundFileFullPath);
			
			PrecacheSound( dc_soundFile );
		}
	}
}