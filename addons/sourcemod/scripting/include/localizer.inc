/**
 * Localizer.inc | API | Using instrinsic in-game translation #phrases
 *
 * Copyright (C) 2022 Stanislav "Dragokas" Polshyn
 *
 * This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with this program.  If not, see <http://www.gnu.org/licenses/>.
 **/

//{ #region Declares
#if defined _localizer_included
 #endinput
#endif
#define _localizer_included

#define LOCALIZER_VERSION "0.93"

#include <sourcemod>
#include <sdktools>
#include <profiler>
#include <regex>

#define LC_USE_SQLITE 1

enum LC_INSTALL_MODE {
	LC_INSTALL_MODE_NONE				= 0,
	LC_INSTALL_MODE_DATABASE 			= 1,
	LC_INSTALL_MODE_FULLCACHE			= 2,
	LC_INSTALL_MODE_TRANSLATIONFILE		= 4,
	LC_INSTALL_MODE_CUSTOM				= 8
}

enum LC_OP_STATE
{
	LC_OP_STATE_WAIT,
	LC_OP_STATE_SIGNAL
}

enum LC_OP_TYPE
{
	LC_OP_TYPE_DECODE,
	LC_OP_TYPE_CACHE
}

enum LC_OP_FLAG
{
	LC_OP_FLAG_NONE		= 0,
	LC_OP_FLAG_RESET 	= 1,
	LC_OP_FLAG_DELAY	= 2
}

enum LC_CACHE
{
	LC_CACHE_DATABASE = 1,	// L1
	LC_CACHE_RAM	  = 2	// L2 - StringMap
}

//#define LC_PROFILER // uncomment to measure the performance

char LC_LANGUAGE_KEY[] =			"Language";
char LC_RESOURCE_ENCODED_DIR[] =	"resource";
char LC_RESOURCE_ENCODED_PL_DIR[] =	"../platform/resource";
char LC_RESOURCE_DECODED_DIR[] =	"resource/utf8";
char LC_RESOURCE_INDEX_FILE[] =		"resource/utf8/_index.txt";
char LC_TRANSLATION_FILE[] = 		"localizer.phrases.txt";
#define LC_DATABASE_NAME			"localizer"
#define LC_DATABASE_KEY				"localizer_key"
#define LC_DATABASE_TABLE			"localizer_phrases"
#define LC_CONVAR_NAME				"sm_localizer_inc"
#define LC_MAX_LANG_COUNT			64
#define LC_MAX_LANG_FILE_LENGTH 	64
#define LC_MAX_PHRASE_LENGTH		128
#define LC_MAX_TRANSLATION_LENGTH	3072
#define LC_THREAD_EXECUTION_TIME	0.3
#define LC_THREAD_WAIT_TIME			0.1
#define LC_MAX_SIGNAL_WAIT_TIME		60.0
#define LC_MAX_PATH_LANG_ENCODED	LC_MAX_LANG_FILE_LENGTH+sizeof(LC_RESOURCE_ENCODED_DIR)+1
#define LC_MAX_PATH_LANG_DECODED	LC_MAX_LANG_FILE_LENGTH+sizeof(LC_RESOURCE_DECODED_DIR)+1

Database 		g_hLcDB;
StringMap 		g_hMapLcPhrase[LC_MAX_LANG_COUNT], // weird, can't declare dynamic array statically
				g_hMapLcStamp,
				g_hMapLcEnglishFile; // for english ghosts (in CSGO)
ArrayStack 		g_hLcStackEncoded,
				g_hLcStackCache;
PrivateForward	g_fwdLcOnPhrasesProcessingCompleted;
Profiler		g_hLcProf;
Regex			g_rLcCaptures;
ConVar			g_hCvarLcState;
Handle			g_hTimerLcState;
bool			g_bLcDecodeInProgress,
				g_bLcIndexChanged,
				g_bLcReady;
int				g_iLcServerLanguage,
				g_iLcQueueTx;
LC_INSTALL_MODE g_iLcInstallMode;
EngineVersion	g_iLcEngine;

typedef g_typLcNotifier = function void();
// #endregion Declares }

//{ #region Stocks
/* ==============================================================================
			Stocks
================================================================================*/

methodmap Localizer < Handle
{
	/**
	 * Called whenever new instance of Localizer methodmap is created.
	 * This will make an installation of Localizer.
	 *
	 * @param install_mode	Optional method of installation:
	 *
	 *						LC_INSTALL_MODE_DATABASE (default)
	 *							 - saves phrases to a database.
	 *						LC_INSTALL_MODE_FULLCACHE (experimental)
	 *							 - pre-caches all phrases making the fastest query, but consuming a lot of memory.
	 *						LC_INSTALL_MODE_TRANSLATIONFILE (experimental, not fully implemented)
	 *							 - save phrases to translation file.
	 *							 - phrases are available via %T %t specifiers only.
	 *							 - do not use own's Localizer Print* methods within this installation mode.
	 *						LC_INSTALL_MODE_CUSTOM
	 *							 - no installation is performed, no objects are initialized at startup.
	 *							 - it is intended to use with Localizer.Uninstall() method only.
	 *
	 * @return				New instance of this methodmap.
	 * 
	 * @note	For LC_INSTALL_MODE_DATABASE and LC_INSTALL_MODE_TRANSLATIONFILE, installation is shared between plugins.
	 *			To access the translation functionality as soon as possible, register a hook via Localizer.Delegate_InitCompleted() method.
	 *			To free the resources use Localizer.Close() method.
	 *			To uninstall Localizer completely, use Localizer.Uninstall() method.
	 */
	public Localizer(LC_INSTALL_MODE install_mode = LC_INSTALL_MODE_DATABASE)
	{
		Loc_Init(install_mode);
		return view_as<Localizer>(g_hLcProf);
	}
	
	/**
	 * Returns the installation mode used
	 */
    property LC_INSTALL_MODE InstallMode
    {
        public get() { return g_iLcInstallMode; }
    }

	/**
	 * Creates a single use hook, notifying that Localizer is fully initialized
	 *
	 * @note Translation can only be retrieved after this hook is raised
	 *
	 * @param func			Callback name having the following prototype: public void Foo()
	 */
	public void Delegate_InitCompleted(g_typLcNotifier func)
	{
		g_fwdLcOnPhrasesProcessingCompleted.AddFunction(GetMyHandle(), func);
	}
	
	/**
	 * Informs if Localizer is fully initialized.
	 *
	 * @return 	True if Localizer is ready to translate phrases, false if initialization has still proceeded.
	 */
	public bool IsReady()
	{
		return g_bLcReady;
	}
	
	/**
	 * Sends a message to the server console.
	 *
	 * @param format        Formatting rules (allows to accept #phrase).
	 * @param ...           Variable number of format parameters.
	 *
	 * @note	If phrase translation doesn't exist, it defaults to server language translation.
	 */
	public void PrintToServer(char[] format, any ...)
	{
		char translation[LC_MAX_TRANSLATION_LENGTH];
		SetGlobalTransTarget(LANG_SERVER);
		VFormat(translation, sizeof(translation), format, 2 +1);
		Loc_ReplacePhrases(translation, sizeof(translation), g_iLcServerLanguage);
		PrintToServer("%s", translation);
	}

	/**
	 * Replies to a message in a command.
	 *
	 * A client index of 0 will use PrintToServer().
	 * If the command was from the console, PrintToConsole() is used.
	 * If the command was from chat, PrintToChat() is used.
	 *
	 * @param client        Client index, or 0 for server.
	 * @param format        Formatting rules (allows to accept #phrase).
	 * @param ...           Variable number of format parameters.
	 *
	 * @note	If phrase translation doesn't exist, it defaults to server language translation.
	 * @error   If the client is not connected or invalid.
	 */
	public void ReplyToCommand(int client, const char[] format, any ...)
	{
		char translation[LC_MAX_TRANSLATION_LENGTH];
		SetGlobalTransTarget(client);
		VFormat(translation, sizeof(translation), format, 3 +1);
		Loc_ReplacePhrases(translation, sizeof(translation), client == 0 ? g_iLcServerLanguage : GetClientLanguage(client));
		ReplyToCommand(client, "%s", translation);
	}
	
	/**
	 * Prints a message to a specific client in the chat area.
	 *
	 * @param client        Client index.
	 * @param format        Formatting rules (allows to accept #phrase).
	 * @param ...           Variable number of format parameters.
	 *
	 * @note	If phrase translation doesn't exist, it defaults to server language translation.
	 * @error   Invalid client index, or client not in game.
	 */
	public void PrintToChat(int client, const char[] format, any ...)
	{
		char translation[LC_MAX_TRANSLATION_LENGTH];
		SetGlobalTransTarget(client);
		VFormat(translation, sizeof(translation), format, 3 +1);
		Loc_ReplacePhrases(translation, sizeof(translation), GetClientLanguage(client));
		PrintToChat(client, "%s", translation);
	}
	
	/**
	 * Prints a message to all clients in the chat area.
	 *
	 * @param format        Formatting rules (allows to accept #phrase).
	 * @param ...           Variable number of format parameters.
	 *
	 * @note	If phrase translation doesn't exist, it defaults to server language translation.
	 */
	public void PrintToChatAll(char[] format, any ...)
	{
		char translation[LC_MAX_TRANSLATION_LENGTH];
		for( int i = 1; i <= MaxClients; i++ )
	    {
	        if( IsClientInGame(i) && !IsFakeClient(i) )
	        {
				SetGlobalTransTarget(i);
				VFormat(translation, sizeof(translation), format, 2 +1);
				Loc_ReplacePhrases(translation, sizeof(translation), GetClientLanguage(i));
				PrintToChat(i, "%s", translation);
			}
		}
	}
	
	/**
	 * Prints a message to a specific client with a hint box.
	 *
	 * @param client        Client index.
	 * @param format        Formatting rules (allows to accept #phrase).
	 * @param ...           Variable number of format parameters.
	 *
	 * @note	If phrase translation doesn't exist, it defaults to server language translation.
	 * @error   Invalid client index, or client not in game.
	 */
	public void PrintHintText(int client, const char[] format, any ...)
	{
		char translation[LC_MAX_TRANSLATION_LENGTH];
		SetGlobalTransTarget(client);
		VFormat(translation, sizeof(translation), format, 3 +1);
		Loc_ReplacePhrases(translation, sizeof(translation), GetClientLanguage(client));
		PrintHintText(client, "%s", translation);
	}
	
	/**
	 * Prints a message to all clients with a hint box.
	 *
	 * @param format        Formatting rules (allows to accept #phrase).
	 * @param ...           Variable number of format parameters.
	 *
	 * @note	If phrase translation doesn't exist, it defaults to server language translation.
	 */
	public void PrintHintTextToAll(char[] format, any ...)
	{
		char translation[LC_MAX_TRANSLATION_LENGTH];
		for( int i = 1; i <= MaxClients; i++ )
	    {
	        if( IsClientInGame(i) && !IsFakeClient(i) )
	        {
				SetGlobalTransTarget(i);
				VFormat(translation, sizeof(translation), format, 2 +1);
				Loc_ReplacePhrases(translation, sizeof(translation), GetClientLanguage(i));
				PrintHintText(i, "%s", translation);
			}
		}
	}
	
	/**
	 * Prints a message to a specific client in the center of the screen.
	 *
	 * @param client        Client index.
	 * @param format        Formatting rules (allows to accept #phrase).
	 * @param ...           Variable number of format parameters.
	 *
	 * @note	If phrase translation doesn't exist, it defaults to server language translation.
	 * @error   Invalid client index, or client not in game.
	 */
	public void PrintCenterText(int client, const char[] format, any ...)
	{
		char translation[LC_MAX_TRANSLATION_LENGTH];
		SetGlobalTransTarget(client);
		VFormat(translation, sizeof(translation), format, 3 +1);
		Loc_ReplacePhrases(translation, sizeof(translation), GetClientLanguage(client));
		PrintCenterText(client, "%s", translation);
	}
	
	/**
	 * Prints a message to all clients in the center of the screen.
	 *
	 * @param format        Formatting rules (allows to accept #phrase).
	 * @param ...           Variable number of format parameters.
	 *
	 * @note	If phrase translation doesn't exist, it defaults to server language translation.
	 */
	public void PrintCenterTextAll(char[] format, any ...)
	{
		char translation[LC_MAX_TRANSLATION_LENGTH];
		for( int i = 1; i <= MaxClients; i++ )
	    {
	        if( IsClientInGame(i) && !IsFakeClient(i) )
	        {
				SetGlobalTransTarget(i);
				VFormat(translation, sizeof(translation), format, 2 +1);
				Loc_ReplacePhrases(translation, sizeof(translation), GetClientLanguage(i));
				PrintCenterText(i, "%s", translation);
			}
		}
	}
	
	/**
	 * Sends a message to a client's console.
	 *
	 * @param client        Client index.
	 * @param format        Formatting rules (allows to accept #phrase).
	 * @param ...           Variable number of format parameters.
	 *
	 * @note	If phrase translation doesn't exist, it defaults to server language translation.
	 * @error   If the client is not connected an error will be thrown.
	 */
	public void PrintToConsole(int client, const char[] format, any ...)
	{
		char translation[LC_MAX_TRANSLATION_LENGTH];
		SetGlobalTransTarget(client);
		VFormat(translation, sizeof(translation), format, 3 +1);
		Loc_ReplacePhrases(translation, sizeof(translation), GetClientLanguage(client));
		PrintToConsole(client, "%s", translation);
	}
	
	/**
	 * Sends a message to every client's console.
	 *
	 * @param format        Formatting rules (allows to accept #phrase).
	 * @param ...           Variable number of format parameters.
	 *
	 * @note	If phrase translation doesn't exist, it defaults to server language translation.
	 */
	public void PrintToConsoleAll(char[] format, any ...)
	{
		char translation[LC_MAX_TRANSLATION_LENGTH];
		for( int i = 1; i <= MaxClients; i++ )
	    {
	        if( IsClientInGame(i) && !IsFakeClient(i) )
	        {
				SetGlobalTransTarget(i);
				VFormat(translation, sizeof(translation), format, 2 +1);
				Loc_ReplacePhrases(translation, sizeof(translation), GetClientLanguage(i));
				PrintToConsole(i, "%s", translation);
			}
		}
	}
	
	/**
	 * Formats a string according to the SourceMod format rules (see documentation).
	 *
	 * @param buffer        Destination string buffer.
	 * @param maxlength     Maximum length of output string buffer.
	 * @param format        Formatting rules (allows to accept #phrase).
	 * @param ...           Variable number of format parameters.
	 *
	 * @return              Number of cells written.
	 *
	 * @note	If phrase translation doesn't exist, it defaults to server language translation.
	 */
	public int Format(char[] buffer, int maxlength, const char[] format, any...)
	{
		VFormat(buffer, maxlength, format, 4 +1);
		Loc_ReplacePhrases(buffer, maxlength, g_iLcServerLanguage);
		return strlen(buffer);
	}
	
	/**
	 * Translates a single #phrase according to client's or spicified language.
	 *
	 * @param phrase        A single #phrase to be translated.
	 * @param buffer        Destination string buffer. Input and output buffers cannot be the same!
	 * @param maxlength     Maximum length of output string buffer.
	 * @param client     	Optional client index which language to translate to (default: LANG_SERVER).
	 * @param lang_name     Optional full language name to translate to (default: empty).
	 * @param lang_code     Optional alphabetic language code to translate to (default: empty).
	 * @param default_text	Optional default string to use if phrase doesn't exist (default: empty).
	 *
	 * @return              True if phrase is translated, false otherwise.
	 *
	 * @note	If phrase doesn't found, the empty string is returned in buffer.
	 * @error	If #phrase length is <= 1.
	 */
	public bool PhraseTranslateToLang(char[] phrase, char[] buffer, int maxlength, int client = LANG_SERVER, char[] lang_name = NULL_STRING, char[] lang_code = NULL_STRING, char[] default_text = NULL_STRING )
	{
		int lang_num = Loc_GetLanguageNum(client, lang_name, lang_code);
		if( Loc_GetPhrase(lang_num, phrase[1], buffer, maxlength, false, false) )
		{
			return true;
		}
		else {
			strcopy(buffer, maxlength, default_text);
			return false;
		}
	}
	
	/**
	 * Translates a single #phrase to client's or spicified language.
	 *
	 * @param phrase        A single #phrase.
	 * @param buffer        Destination string buffer.
	 * @param maxlength     Maximum length of output string buffer.
	 * @param client     	Optional client index which language to translate to (default: LANG_SERVER).
	 * @param lang_name     Optional full language name to translate to (default: empty).
	 * @param lang_code     Optional alphabetic language code to translate to (default: empty).
	 *
	 * @return              True if phrase is translated, false otherwise.
	 *
	 * @note	If phrase doesn't found, the empty string is returned in buffer.
	 * @error	If #phrase length is <= 1.
	 */
	public bool PhraseExists(char[] phrase, int client = LANG_SERVER, char[] lang_name = "", char[] lang_code = "")
	{
		int lang_num = Loc_GetLanguageNum(client, lang_name, lang_code);
		char translation[LC_MAX_TRANSLATION_LENGTH];
		return Loc_GetPhrase(lang_num, phrase[1], translation, sizeof(translation), false, false);
	}
	
	/**
	 * Checks if a #phrase had precache in RAM (Cache L2).
	 *
	 * @param phrase        A single #phrase.
	 * @param client     	Optional client index of phrase language (default: LANG_SERVER).
	 * @param lang_name     Optional full language name of phrase (default: empty).
	 * @param lang_code     Optional alphabetic language code of phrase (default: empty).
	 *
	 * @return              True if phrase is precached, false otherwise.
	 *
	 * @error	If #phrase length is <= 1.
	 */
	public bool PhrasePrecached(char[] phrase, int client = LANG_SERVER, char[] lang_name = "", char[] lang_code = "")
	{
		int lang_num = Loc_GetLanguageNum(client, lang_name, lang_code);
		char translation[LC_MAX_TRANSLATION_LENGTH];		
		return g_hMapLcPhrase[lang_num].GetString(phrase[1], translation, sizeof(translation));
	}
	
	/**
	 * Precaches a #phrase to RAM (Cache L2) for faster access later.
	 *
	 * @param phrase        A single #phrase.
	 *
	 * @return              True if phrase is precached, false if phrase doesn't found.
	 *
	 * @note	This precache is only actual for installation mode 'LC_INSTALL_MODE_DATABASE' (default).
	 * @error	If #phrase length is <= 1.
	 */
	public bool PrecachePhrase(char[] phrase)
	{
		int lang_num = Loc_GetLanguageNum(LANG_SERVER, "", "");
		char translation[LC_MAX_TRANSLATION_LENGTH];
		return Loc_GetPhrase(lang_num, phrase[1], translation, sizeof(translation), true, true);
	}
	
	//TODO
	/**
	 * Precaches an arbitrary translation file to use it the same way if it were intrinsic translation phrases.
	 *
	 * @param phrase        A single #phrase.
	 *
	 * @return              True if phrase is precached, false if phrase doesn't found.
	 *
	 * @note	This precache is only actual for installation mode 'LC_INSTALL_MODE_DATABASE' (default).
	 * @error	If #phrase length is <= 1.
	 */
	public bool PrecacheTranslationFile(char[] file, LC_CACHE cache = LC_CACHE_RAM)
	{
		
		return true;
	}
	
	/**
	 * Adds a new #phrase and translation.
	 *
	 * @param phrase        A single #phrase.
	 * @param translation   Translation of phrase.
	 * @param client     	Optional client index which language is used in provided translation (default: LANG_SERVER).
	 * @param lang_name     Optional full language name of provided translation (default: empty).
	 * @param lang_code     Optional alphabetic language code of provided translation (default: empty).
	 * @param bOverwrite    Optional, specify if you want to overwrite phrase that is already exists (default: yes).
	 * @param bAsync        Optional, spefify if you want this operation to be asynchronous (default: no).
	 *
	 * @note	This #phrase will not survive the server reboot if installation mode == LC_INSTALL_MODE_FULLCACHE.
	 * @error	If #phrase length is <= 1.
	 */
	public void PhraseAdd(char[] phrase, char[] translation, int client = LANG_SERVER, char[] lang_name = "", char[] lang_code = "", 
		bool bOverwrite = true, bool bAsync = false)
	{
		int lang_num = Loc_GetLanguageNum(client, lang_name, lang_code);
		Loc_AddPhrase(lang_num, phrase[1], translation, bOverwrite, bAsync);
	}
	
	/**
	 * Adds a new #phrase and translation to a temporarily cache L2 (StringMap).
	 *
	 * @param phrase        A single #phrase.
	 * @param translation   Translation of phrase.
	 * @param client     	Optional client index which language is used in provided translation (default: LANG_SERVER).
	 * @param lang_name     Optional full language name of provided translation (default: empty).
	 * @param lang_code     Optional alphabetic language code of provided translation (default: empty).
	 * @param bOverwrite    Optional, specify if you want to overwrite phrase that is already exists (default: yes).
	 *
	 * @note	This #phrase will not survive the server reboot.
	 * @error	If #phrase length is <= 1.
	 */
	public void PhraseAddTemp(char[] phrase, char[] translation, int client = LANG_SERVER, char[] lang_name = "", char[] lang_code = "", 
		bool bOverwrite = true)
	{
		int lang_num = Loc_GetLanguageNum(client, lang_name, lang_code);
		g_hMapLcPhrase[lang_num].SetString(phrase, translation, bOverwrite);
	}
	
	/**
	 * Removes a #phrase and all its translations.
	 *
	 * @param phrase        A single #phrase.
	 *
	 * @note	This will not survive the server reboot if installation mode == LC_INSTALL_MODE_FULLCACHE.
	 *			For other modes, if you removes a pre-built (resource) phrase, it can only be restored on resource update,
	 *			or via Localizer.Uninstall() method with a full re-installation.
	 * @error	If #phrase length is <= 1.
	 */
	public void PhraseRemove(char[] phrase)
	{
		SQL_Loc_RemovePhrase(phrase[1]);
		for( int i = 0; i < GetLanguageCount(); i++ )
		{
			if( g_hMapLcPhrase[i] )
			{
				g_hMapLcPhrase[i].Remove(phrase[1]);
			}
		}
	}
	
	/**
	 * Generates SM compatible translation file from all L2 (StringMap) pre-cached phrases.
	 * Note: for convenience, translation files are also mirrored to folder: "translations/localizer/"
	 *
	 * @return				True if at least default server language file is successfully generated, false otherwise.
	 *
	 * @note	To dump all resource phrases, you have to initialize Localizer with installation mode == LC_INSTALL_MODE_FULLCACHE.
	 *			File is stored in location: ./translations/localizer.phrases.txt
	 *			You can use it to observe and study desired phrases for further using via default installation mode. 
	 *			Or you can load this file with Localizer.LoadTranslations() method and use translations via %T %t specifiers.
	 */
	public bool DumpAll()
    {
    	bool result;
    	int count;
    	g_hLcProf.Start();
    	
    	result = Loc_Dump(LANG_SERVER, count);
    	
    	for( int i = 0; i < GetLanguageCount(); i++ )
    	{
    		if( i != LANG_SERVER )
    		{
    			Loc_Dump(i, count);
    		}
    	}
    	g_hLcProf.Stop();
    	#if defined LC_PROFILER
			PrintToServer(">> Profiler report for: %s (%i phrases): %.2f sec.", "Dumping" , count, g_hLcProf.Time);
		#endif
		return result;
    }
	
	/**
	 * Loads previously dumped localizer.phrases.txt file via SM LoadTranslations() method.
	 *
	 * @return				True if translations are loaded, false if translation file doesn't found.
	 *
	 * @note	You can use translations via %T %t specifiers in any SM Print* and similar methods passing "#phrase" as an argument.
	 */
	public bool LoadTranslations()
	{
		return Loc_LoadTranslations();
	}
	
	/**
	 * Uninstall Localizer from the server completely.
	 *
	 * @note	Database table, translation files and decoded resource files ('utf8' dir) will be removed.
	 *			You should call Localizer.Close() method manually to free the remaining resources.
	 */
	public void Uninstall()
	{
		if( g_hCvarLcState && g_hCvarLcState.IntValue == view_as<int>(LC_OP_STATE_WAIT) )
		{
			return;
		}
		Loc_DeleteDirectory(LC_RESOURCE_DECODED_DIR);
		SQL_Loc_RemoveTable();
		Loc_RemoveTranslationFiles();
		g_iLcInstallMode = LC_INSTALL_MODE_NONE;
	}
	
	/**
	 * Frees resources allocated by Localizer instance.
	 */
	public void Close()
	{
		for( int i = 0; i < sizeof(g_hMapLcPhrase); i++ ) {
			if( g_hMapLcPhrase[i] != null)
				delete g_hMapLcPhrase[i];
		}
		delete g_hMapLcStamp;
		delete g_hMapLcEnglishFile;
		delete g_hLcStackEncoded;
		delete g_hLcStackCache;
		delete g_hTimerLcState;
		delete g_hLcProf;
		g_fwdLcOnPhrasesProcessingCompleted.RemoveAllFunctions(GetMyHandle());
		//delete g_fwdLcOnPhrasesProcessingCompleted; // disabled: potential crash, if executed in mid-call
		delete g_rLcCaptures;
		//delete g_hLcDB; // disabled: for safe, because database can still execute threaded operations
		g_iLcInstallMode = LC_INSTALL_MODE_NONE;
	}
}

/**
 * In-line formats a string according to the SourceMod format rules (see documentation).
 *
 * @param client        Client index.
 * @param format        Formatting rules (allows to accept #phrase).
 * @param ...           Variable number of format parameters.
 *
 * @return				Char array with resulting string.
 *
 * @note				If a phrase doesn't found, original #phrase is stay untouched.
 * @error               Invalid client index, or client not in game.
 */
stock char[] Loc_Translate(int client, const char[] format, any ...) // weird, can't declare it within methodmap due to array-based return type
{
	char translation[LC_MAX_TRANSLATION_LENGTH];
	SetGlobalTransTarget(client);
	VFormat(translation, sizeof(translation), format, 3);
	Loc_ReplacePhrases(translation, sizeof(translation), client == 0 ? g_iLcServerLanguage : GetClientLanguage(client));
	return translation;
}
 
/**
 * In-line translates a single #phrase according to client's or spicified language.
 *
 * @param phrase        A single #phrase to be translated.
 * @param client     	Optional client index which language to translate to (default: LANG_SERVER).
 * @param lang_name     Optional full language name to translate to (default: empty).
 * @param lang_code     Optional alphabetic language code to translate to (default: empty).
 *
 * @return              Char array with a translation.
 *
 * @note	If phrase doesn't found, the empty string is returned.
 * @error	If #phrase length is <= 1.
 */
stock char[] Loc_TranslateToLang(char[] phrase, int client = LANG_SERVER, char[] lang_name = "", char[] lang_code = "" )
{
	char translation[LC_MAX_TRANSLATION_LENGTH];
	int lang_num = Loc_GetLanguageNum(client, lang_name, lang_code);
	Loc_GetPhrase(lang_num, phrase[1], translation, sizeof(translation), false, false);
	return translation;
}

// #endregion Stocks }

/* ==============================================================================
			Private functions
================================================================================*/

//{ #region Initialize
void Loc_Init(LC_INSTALL_MODE install_mode)
{
	/*
	// TODO
	
	g_hLcGlobalProf = new Profiler();
	#if defined LC_PROFILER
		if( !(install_mode & LC_INSTALL_MODE_CUSTOM) )
		{
			g_hLcGlobalProf.Start();
		}
	#endif
	*/
	
	g_iLcInstallMode = install_mode;
	g_iLcEngine = GetEngineVersion();
	g_hCvarLcState = FindConVar(LC_CONVAR_NAME); // inter-plugin sync. mechanism
	Loc_RegisterCommands();
	
	// TODO: remove it
	if( g_hCvarLcState )
	{
		g_hCvarLcState.SetInt(1);
	}
	
	if( !(install_mode & LC_INSTALL_MODE_CUSTOM) )
	{
		Loc_InitObjects();
		if( g_hCvarLcState && g_hCvarLcState.IntValue == view_as<int>(LC_OP_STATE_WAIT) )
		{
			#if defined LC_PROFILER
				PrintToServer("[Localizer] [h:%i] Pausing execution", GetMyHandle());
			#endif
			g_hCvarLcState.AddChangeHook(Loc_StateChanged);
			Loc_SetStateWatchDog();
		}
		else {
			if( !g_hCvarLcState )
			{
				char value[4];
				IntToString(view_as<int>(LC_OP_STATE_WAIT), value, sizeof(value));
				g_hCvarLcState = CreateConVar(LC_CONVAR_NAME, value, "Signal for other plugins to continue initialization", FCVAR_SPONLY | FCVAR_DONTRECORD );
			}
			Loc_StartProcessing();
		}
	}
}

bool Loc_InitObjects()
{
	int count = GetLanguageCount();
	for( int i = 0; i < count; i++ ) {
		delete g_hMapLcPhrase[i];
		g_hMapLcPhrase[i] = new StringMap();
	}
	delete g_hMapLcStamp;
	delete g_hLcStackEncoded;
	delete g_hLcStackCache;
	g_hMapLcStamp = new StringMap();
	g_hMapLcEnglishFile = new StringMap();
	g_hLcStackEncoded = new ArrayStack(ByteCountToCells(LC_MAX_LANG_FILE_LENGTH));
	g_hLcStackCache = new ArrayStack(ByteCountToCells(LC_MAX_LANG_FILE_LENGTH));
	if( !g_hLcProf )
	{
		g_hLcProf = new Profiler();
	}
	if( !g_fwdLcOnPhrasesProcessingCompleted )
	{
		g_fwdLcOnPhrasesProcessingCompleted = new PrivateForward(ET_Ignore);
	}
	//example: "#hulkzombie.start-ledge\\climb", but not greedy for "#hulkzombie.start-ledge\\climb."
	//
	if( !g_rLcCaptures )
	{
		g_rLcCaptures = new Regex("#\\w+([\\.\\-\\\\]\\w+)*");
	}
	g_iLcServerLanguage = GetServerLanguage();
	return true;
}

void Loc_RegisterCommands()
{
	static bool IsListen;
	if( !IsListen )
	{
		if( CommandExists("sm_localizer_list") )
		{
			AddCommandListener(CmdListener_Loc_List, "sm_localizer_list");
		}
		else {
			RegAdminCmd("sm_localizer_list", Cmd_Loc_List, ADMFLAG_ROOT, "Lists plugin names that using Localizer API, show API version and installation mode");
		}
		IsListen = true;
	}
}

public Action CmdListener_Loc_List(int client, const char[] command, int argc)
{
	Loc_ShowConsumer(client);
	return Plugin_Continue;
}

public Action Cmd_Loc_List(int client, int argc)
{
	Loc_ShowConsumer(client);
	return Plugin_Handled;
}

void Loc_ShowConsumer(int client)
{
	char name[64];
	GetPluginFilename(INVALID_HANDLE, name, sizeof(name));
	ReplyToCommand(client, "%s | Install mode: %s | API Version: %s", name, Loc_InstallMode_ToString(), LOCALIZER_VERSION);
}

public void Loc_StateChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if( view_as<LC_OP_STATE>(convar.IntValue) == LC_OP_STATE_SIGNAL )
	{
		#if defined LC_PROFILER
			PrintToServer("[Localizer] [h:%i] Received signal => continue execution", GetMyHandle());
		#endif
		delete g_hTimerLcState;
		g_hCvarLcState.RemoveChangeHook(Loc_StateChanged);
		convar.SetInt(view_as<int>(LC_OP_STATE_WAIT));		// pause the next plugin in chain
		Loc_StartProcessing();
	}
	else {
		#if defined LC_PROFILER
			PrintToServer("[Localizer] [h:%i] Restarting Dog", GetMyHandle());
		#endif
		Loc_SetStateWatchDog();
	}
}

void Loc_SetStateWatchDog()
{
	delete g_hTimerLcState;
	g_hTimerLcState = CreateTimer(LC_MAX_SIGNAL_WAIT_TIME, Timer_Loc_SignalWatchDog);
}

public Action Timer_Loc_SignalWatchDog(Handle timer)
{
	PrintToServer("[Localizer] [h:%i] WatchDog raised !!!", GetMyHandle());
	g_hTimerLcState = null;
	g_hCvarLcState.SetInt(view_as<int>(LC_OP_STATE_SIGNAL));
	return Plugin_Continue;
}

void Loc_StartProcessing()
{
	CreateDirectory(LC_RESOURCE_DECODED_DIR, 0o755);
	
	Loc_ReadIndexFile();
	
	switch( g_iLcInstallMode )
	{
		case LC_INSTALL_MODE_DATABASE:
		{
			SQL_Loc_DB_Connect();
		}
		case LC_INSTALL_MODE_FULLCACHE:
		{
			Loc_GetPhraseFiles("");
		}
		case LC_INSTALL_MODE_TRANSLATIONFILE:
		{
			Loc_LoadTranslations();
			Loc_GetPhraseFiles("");
		}
	}
}
// #endregion Initialize }

//{ #region Forwards
/* ==============================================================================
			Forwards
================================================================================*/

void OnPhrasesProcessingCompleted_CallDelayed() // wait for DB to finish last threaded operation
{
	CreateTimer(LC_THREAD_WAIT_TIME, Timer_Loc_OnPhrasesProcessingCompleted);
}

public Action Timer_Loc_OnPhrasesProcessingCompleted(Handle timer)
{
	Forward_OnPhrasesProcessingCompleted();
	return Plugin_Continue;
}

void Forward_OnPhrasesProcessingCompleted()
{
	if( g_bLcIndexChanged )
	{
		Loc_WriteIndexFile();
	}
	if( g_iLcInstallMode == LC_INSTALL_MODE_DATABASE )
	{
		SQL_Loc_SetIndex("", 0, .bFinishPending = true);
	}
	else if( g_iLcInstallMode == LC_INSTALL_MODE_TRANSLATIONFILE )
	{
		// TODO
	}
	
	g_hCvarLcState.SetInt(view_as<int>(LC_OP_STATE_SIGNAL));
	
	g_bLcReady = true;
	
	#if defined LC_PROFILER
		if( g_iLcInstallMode == LC_INSTALL_MODE_DATABASE )
		{
			g_hLcProf.Stop();
			PrintToServer(">> Profiler report for: %s: %.2f sec.", "Pending database" , g_hLcProf.Time);
		}
		PrintToServer(">>> Phrases processing is completed.");
	#endif
	
	RequestFrame(Forward_OnPhrasesProcessingCompleted_Frame);
}

void Forward_OnPhrasesProcessingCompleted_Frame()
{
	Action result;
	Call_StartForward(g_fwdLcOnPhrasesProcessingCompleted);
	Call_Finish(result);
	
	/* // no sense, since we can't call it by name anyway
	if( GetFunctionByName(null, "OnPhrasesProcessingCompleted") != INVALID_FUNCTION )
	{
		Call_StartFunction(null, OnPhrasesProcessingCompleted);
		Call_Finish(result);
	}
	*/
}

// #endregion Forward }

//{ #region Parser
/* ==============================================================================
			Parser
================================================================================*/

void Loc_ReadIndexFile()
{
	g_hMapLcStamp.Clear();
	
	int p, iStamp;
	char str[LC_MAX_TRANSLATION_LENGTH];
	File hr = OpenFile(LC_RESOURCE_INDEX_FILE, "rt");
	if( hr )
	{
		while( !hr.EndOfFile() && hr.ReadLine(str, sizeof(str)) )
		{
			if( -1 != (p = FindCharInString(str, '|')) )
			{
				str[p] = 0;
				iStamp = StringToInt(str[p+1]);
				g_hMapLcStamp.SetValue(str[0], iStamp, true);
			}
		}
		hr.Close();
	}
}

void Loc_WriteIndexFile()
{
	char name[128], str[128];
	int iStamp;
	File hFile = OpenFile(LC_RESOURCE_INDEX_FILE, "wt");
	if( hFile ) {
		StringMapSnapshot hSnap = g_hMapLcStamp.Snapshot();
		if( hSnap )
		{
			for( int i = 0; i < hSnap.Length; i++ )
			{
				hSnap.GetKey(i, name, sizeof(name));
				g_hMapLcStamp.GetValue(name, iStamp);
				FormatEx(str, sizeof(str), "%s|%i", name, iStamp);
				hFile.WriteLine(str);
			}
			delete hSnap;
		}
		hFile.Close();
	}
}

void Loc_GetPhraseFiles(char[] search)
{
	DirectoryListing hDir;
	char sFile[LC_MAX_LANG_FILE_LENGTH], prefix[32], guess[LC_MAX_LANG_FILE_LENGTH];
	int iCount, iLen, n, iLenSearch = strlen(search);
	FileType fileType;
	StringMap hUniqPrefix = new StringMap();
	
	hDir = OpenDirectory(LC_RESOURCE_ENCODED_DIR, true);
	if( hDir )
	{
		while( hDir.GetNext(sFile, sizeof(sFile), fileType) )
		{
			if( fileType == FileType_File )
			{
				if( strncmp(sFile, search, iLenSearch, false) == 0 )
				{
					iLen = strlen(sFile);
					if( iLen > 4 )
					{
						if( strcmp(sFile[iLen-4], ".txt", false) == 0 )
						{
							n = FindCharInString(sFile, '_');
							
							if( n != -1 ) // some text files aren't #prases
							{
								if( strcmp(sFile[n+1], "latam.txt") != 0 &&
									strcmp(sFile[n+1], "pirate.txt") != 0 )
								{
									strcopy(prefix, n+1, sFile);
									hUniqPrefix.SetString(prefix, sFile, false);

									g_hLcStackEncoded.PushString(sFile);
									++ iCount;
								}
							}
						}
					}
				}
			}
		}
		delete hDir;
	}
	
	// Retrieving files having no _english.txt companion
	// Seen in CS:GO
	//
	StringMapSnapshot hSnap = hUniqPrefix.Snapshot();
	if( hSnap )
	{
		for( int i = 0; i < hSnap.Length; i++ )
		{
			hSnap.GetKey(i, prefix, sizeof(prefix));
			FormatEx(guess, sizeof(guess), "%s/%s_english.txt", LC_RESOURCE_ENCODED_DIR, prefix);
			if( !FileExists(guess, true) ) // phrases set has no english para?
			{
				// push the first file of the set to a separate stack to process [english] fallback phrases.
				hUniqPrefix.GetString(prefix, sFile, sizeof(sFile));
				g_hMapLcEnglishFile.SetValue(sFile, 0);
			}
		}
		delete hSnap;
	}
	delete hUniqPrefix;
	
	if( !g_bLcDecodeInProgress )
	{
		#if defined LC_PROFILER
			PrintToServer(">>> Start processing of %i files...", iCount);
			PrintToServer("Installation mode: %s", Loc_InstallMode_ToString());
		#endif
		Loc_StackProcessingDecode(LC_OP_FLAG_RESET | LC_OP_FLAG_DELAY);
	}
}

public Action Timer_Loc_StackProcessingDecode(Handle timer, LC_OP_FLAG flags)
{
	Loc_StackProcessingDecode(flags);
	return Plugin_Continue;
}

void Loc_StackProcessingDecode(LC_OP_FLAG flags)
{
	float time;
	bool bUpdated;
	int iFileSize;
	static float total_time, max_time;
	static int iCount, total_file_size, max_size;
	static char sFile[LC_MAX_LANG_FILE_LENGTH];
	
	#pragma unused total_file_size, total_time
	
	g_bLcDecodeInProgress = true;
	
	if( flags & LC_OP_FLAG_RESET ) {
		total_time = 0.0;
		max_time = 0.0;
		iCount = 0;
		total_file_size = 0;
		max_size = 0;
	}
	if( flags & LC_OP_FLAG_DELAY ) {
		CreateTimer(LC_THREAD_WAIT_TIME, Timer_Loc_StackProcessingDecode, LC_OP_FLAG_NONE);
		return;
	}
	
	while( time < LC_THREAD_EXECUTION_TIME )
	{
		if( g_hLcStackEncoded.Empty )
		{
			#if defined LC_PROFILER
				Loc_PrintProfiler(iCount, total_file_size, max_size, total_time, max_time, LC_OP_TYPE_DECODE);
			#endif
			Loc_StackProcessingCache(LC_OP_FLAG_RESET | LC_OP_FLAG_DELAY);
			return;
		}
		g_hLcStackEncoded.PopString(sFile, sizeof(sFile));
		
		g_hLcProf.Start();
		bUpdated = Loc_DecodeFile(sFile, iFileSize);
		g_hLcStackCache.PushString(sFile);
		
		g_hLcProf.Stop();
		time += g_hLcProf.Time;
		
		if( max_time < g_hLcProf.Time ) max_time = g_hLcProf.Time;
		if( bUpdated ) {
			total_file_size += iFileSize;
			if( max_size < iFileSize ) max_size = iFileSize;
			total_time += g_hLcProf.Time;
			++ iCount;
		}
	}
	CreateTimer(LC_THREAD_WAIT_TIME, Timer_Loc_StackProcessingDecode, LC_OP_FLAG_NONE);
}

public Action Timer_Loc_StackProcessingCache(Handle timer, LC_OP_FLAG flags)
{
	Loc_StackProcessingCache(flags);
	return Plugin_Continue;
}

void Loc_StackProcessingCache(LC_OP_FLAG flags)
{
	float time;
	bool bUpdated;
	int iFileSize;
	static float total_time, max_time;
	static int iCount, total_file_size, max_size;
	static char sFile[LC_MAX_LANG_FILE_LENGTH];
	
	#pragma unused total_file_size, total_time
	
	if( flags & LC_OP_FLAG_RESET ) {
		total_time = 0.0;
		max_time = 0.0;
		total_file_size = 0;
		max_size = 0;
		iCount = 0;
	}
	if( flags & LC_OP_FLAG_DELAY ) {
		CreateTimer(LC_THREAD_WAIT_TIME, Timer_Loc_StackProcessingCache, LC_OP_FLAG_NONE);
		return;
	}
	
	while( time < LC_THREAD_EXECUTION_TIME )
	{
		if( g_hLcStackCache.Empty )
		{
			g_bLcDecodeInProgress = false;
			#if defined LC_PROFILER
				Loc_PrintProfiler(iCount, total_file_size, max_size, total_time, max_time, LC_OP_TYPE_CACHE );
			#endif
			
			if( !g_hLcStackEncoded.Empty )
			{
				Loc_StackProcessingDecode(LC_OP_FLAG_DELAY);
			}
			else {
				if( g_iLcInstallMode & LC_INSTALL_MODE_DATABASE )
				{
					#if defined LC_PROFILER
						g_hLcProf.Start();
					#endif
					if( !SQL_Loc_InsertBatch(0, "", "", .bFinishPending = true) )
					{
						OnPhrasesProcessingCompleted_CallDelayed();
					}
				}
				else if( g_iLcInstallMode & LC_INSTALL_MODE_FULLCACHE )
				{
					Forward_OnPhrasesProcessingCompleted();
				}
				else if( g_iLcInstallMode & LC_INSTALL_MODE_TRANSLATIONFILE )
				{
					Loc_LoadTranslations();
					Forward_OnPhrasesProcessingCompleted();
				}
			}
			return;
		}
		g_hLcStackCache.PopString(sFile, sizeof(sFile));
		g_hLcProf.Start();
		bUpdated = Loc_CacheFile(sFile, iFileSize);
		g_hLcProf.Stop();
		
		time += g_hLcProf.Time;
		
		if( max_time < g_hLcProf.Time ) max_time = g_hLcProf.Time;
		if( bUpdated )
		{
			total_time += g_hLcProf.Time;
			total_file_size += iFileSize;
			if( max_size < iFileSize ) max_size = iFileSize;
			++ iCount;
		}
	}
	CreateTimer(LC_THREAD_WAIT_TIME, Timer_Loc_StackProcessingCache, LC_OP_FLAG_NONE);
}

#if defined LC_PROFILER
void Loc_PrintProfiler(int iCount, int total_file_size, int max_size, float time, float max_time, LC_OP_TYPE op_type)
{
	float size_max_mb = max_size / 1024.0 / 1024.0;
	float size_mb = total_file_size / 1024.0 / 1024.0;
	float speed = size_mb / time;
	PrintToServer(">> Profiler report for: %s (%i items, %.1f MB), max file: %.2f MB", op_type == LC_OP_TYPE_DECODE ? "Decode" : "Cache", iCount, size_mb, size_max_mb);
	PrintToServer("avg speed: %.2f MB/sec.", speed);
	PrintToServer("max time per file: %.2f sec.", max_time);
	PrintToServer("total time elapsed: %.2f sec.", time);
	if( iCount > 0 ) {
		if( size_max_mb + 0.2*size_max_mb > speed ) { // assuming, 1 sec. is the maximum time allowed (-20% reserved)
			PrintToServer("Performance - problem !!! (%.2f MB +20%% > %.2f MB/sec)", size_max_mb, speed);
		}
		else {
			PrintToServer("Performance - OK.");
		}
	}
}
#endif

bool Loc_CacheFile(char[] sFile, int &iFileSize)
{
	bool shouldParse;
	int iOldSize, value;
	char sourceFile[LC_MAX_PATH_LANG_DECODED];
	bool use_fallback = g_hMapLcEnglishFile.GetValue(sFile, value);
	FormatEx(sourceFile, sizeof(sourceFile), "%s/%s", LC_RESOURCE_DECODED_DIR, sFile);
	iFileSize = FileSize(sourceFile);
	
	switch( g_iLcInstallMode )
	{
		case LC_INSTALL_MODE_DATABASE:
		{
			iOldSize = SQL_Loc_GetIndex(sFile);
			if( iOldSize != iFileSize )
			{
				shouldParse = true;
			}
		}
		case LC_INSTALL_MODE_FULLCACHE:
		{
			shouldParse = true;
		}
		case LC_INSTALL_MODE_TRANSLATIONFILE:
		{
			// TODO
		}
	}
	
	if( shouldParse )
	{
		Loc_ParseFile(sourceFile, use_fallback);
		
		if( g_iLcInstallMode == LC_INSTALL_MODE_DATABASE )
		{
			SQL_Loc_SetIndex(sFile, iFileSize);
		}
		else if( g_iLcInstallMode == LC_INSTALL_MODE_TRANSLATIONFILE )
		{
			// TODO
		}
		return true;
	}
	return false;
}

void Loc_ParseFile(char[] sFile, bool use_fallback)
{
	int pa /*absolute*/, pr /*relative*/, pc /*current*/, ps = -1 /*start*/, tok /*token number*/, qts /*quote started?*/;
	int p[2] = {-1, ...} /*result tok #0,1*/, p_len[2] /*length of found*/;
	int iLangIndex = -1;
	char str[LC_MAX_TRANSLATION_LENGTH];
	File hr = OpenFile(sFile, "rt");
	if( hr )
	{
		while( !hr.EndOfFile() && hr.ReadLine(str, sizeof(str)) )
		{
			pa = 0;	ps = -1; p[0] = -1;	p[1] = -1; qts = 0; tok = 0;
			
			while( -1 != (pr = FindCharInString(str[pa], '"')) )
			{
				pc = pa+pr;
				if( ps == -1 ) ps = pc + 1;
				if( qts ) {
					if( str[pc-1] != '\\' ) { // skip screened quote
						str[pc] = '\0';
						p[tok] = ps;
						p_len[tok] = pc - ps;
						if( tok == 1 ) break;
						qts = 0;
						ps = -1;
						++ tok;
					}
				}
				else {
					qts = 1;
				}
				pa += pr + 1;
			}
			// TODO: Add multiline translations support
			if( p[0] != -1 && p[1] != -1 && str[p[0]] != 0 && str[p[1]] != 0 && !( p_len[1] == 1 && str[p[1]] == ' ') )
			{
				if( Loc_OnProcessKeyValue(str[p[0]], str[p[1]], iLangIndex, use_fallback) == Plugin_Stop )
				{
					PrintToServer("[Localizer] [WARN] File %s is skipped. Reason: language name is not recognized.", sFile);
					break;
				}
			}
		}
		delete hr;
	}
}

Action Loc_OnProcessKeyValue(char[] key, char[] value, int &lang_num, bool use_fallback)
{
	int indent;
	bool isFallback;
	
	if( key[0] == '[' )
	{
		if( use_fallback ) // for CSGO: "[english]phrase" "translation"
		{
			indent = 9;
			isFallback = true;
		}
		else {
			return Plugin_Continue;
		}
	}
	
	if( lang_num == -1 )
	{
		if( strcmp(key, LC_LANGUAGE_KEY) == 0 )
		{
			lang_num = GetLanguageByName(value);
			if( lang_num == -1 )
				return Plugin_Stop;
		}
	}
	else {
		if( key[indent+0] == '#' )
		{
			Loc_AddPhrase(isFallback ? LANG_SERVER : lang_num, key[indent+1], value, false, true, true);
		}
		else {
			Loc_AddPhrase(isFallback ? LANG_SERVER : lang_num, key[indent+0], value, false, true, true);
		}
	}
	return Plugin_Continue;
}

void Loc_AddPhrase(int lang_num, char[] phrase, char[] translation, bool bOverwrite = false, bool bAsync = true, bool batch = false)
{
	if( g_iLcInstallMode & LC_INSTALL_MODE_DATABASE )
	{
		if( batch ) // walkaround for IDatabase handles leak #1505
		{
			SQL_Loc_InsertBatch(lang_num, phrase, translation, bOverwrite);
		}
		else {
			SQL_Loc_Insert(lang_num, phrase, translation, bOverwrite, bAsync);
		}
	}
	else if( g_iLcInstallMode & LC_INSTALL_MODE_FULLCACHE )
	{
		g_hMapLcPhrase[lang_num].SetString(phrase, translation, bOverwrite);
	}
	else if( g_iLcInstallMode & LC_INSTALL_MODE_TRANSLATIONFILE )
	{
		// TODO
	}
}

bool Loc_DecodeFile(char[] sFile, int &iFileSize)
{
	char targetFile[LC_MAX_PATH_LANG_DECODED];
	char sourceFile[LC_MAX_PATH_LANG_ENCODED];
	FormatEx(sourceFile, sizeof(sourceFile), "%s/%s", LC_RESOURCE_ENCODED_DIR, sFile);
	FormatEx(targetFile, sizeof(targetFile), "%s/%s", LC_RESOURCE_DECODED_DIR, sFile);
	int iOldSize;
	iFileSize = FileSize(sourceFile, true);
	g_hMapLcStamp.GetValue(sFile, iOldSize); // Valve update happened ?
	
	if( iFileSize != iOldSize || !FileExists(targetFile) )
	{
		Loc_ConvertFile_UTF16LE_UTF8(sourceFile, targetFile);
		g_hMapLcStamp.SetValue(sFile, iFileSize, true);
		g_bLcIndexChanged = true;
		return true;
	}
	iFileSize = 0;
	return false;
}

bool Loc_ConvertFile_UTF16LE_UTF8(char[] sourceFile, char[] targetFile)
{
	//PrintToServer("Decode: %s", sourceFile);
	
	bool use_valve_fs = !(g_iLcEngine == Engine_CSGO); // walkaround CSGO engine (SM?) ERROR_HANDLE_EOF bug #1567

	File hr = OpenFile(sourceFile, "rb", use_valve_fs);
	
	if( !hr && g_iLcEngine == Engine_CSGO )
	{
		// FIXIT: remove this hardcoded string walkaround as soon as ERROR_HANDLE_EOF bug will be fixed
		int n = FindCharInString(sourceFile, '/', true);
		if( n != -1 )
		{
			Format(sourceFile, LC_MAX_PATH_LANG_ENCODED, "%s/%s", LC_RESOURCE_ENCODED_PL_DIR, sourceFile[n+1]);
			hr = OpenFile(sourceFile, "rb", false);
		}
	}
	if( hr )
	{
		// TODO: Add profiler control
		
		File hw = OpenFile(targetFile, "wb", false);
		if( hw )
		{
			// Note: it seems various buffer sizes doesn't affect performance too much
			// 
			int bytesRead, bytesWrite, buff[512/* MUST MOD 4*/], out[sizeof(buff)*3/* MUST MULTIPLY 3*/];
			
			while( !hr.EndOfFile() )
			{
				bytesRead = hr.Read(buff, sizeof(buff), 2);
				Loc_WideCharToMultiByte(buff, bytesRead, out, bytesWrite);
				hw.Write(out, bytesWrite, 1);
			}
			delete hw;
		}
		delete hr;
	}
	return true;
}

// Note: Little Endian only.
//
void Loc_WideCharToMultiByte(const int[] input, int maxlen, int[] output, int &bytesWrite)
{
	static int i, n, high_surrogate;
	n = 0;
	high_surrogate = 0;
	for( i = 0; i < maxlen; i++ ) { 
		if( high_surrogate ) // for characters in range 0x10000 <= X <= 0x10FFFF
		{
			int data;
			data = ((high_surrogate - 0xD800) << 10) + (input[i]/*Low surrogate*/ - 0xDC00) + 0x10000;
			output[n++] = ((data >> 18) & 0x07) | 0xF0;
			output[n++] = ((data >> 12) & 0x3F) | 0x80;
			output[n++] = ((data >> 6) & 0x3F) | 0x80;
			output[n++] = (data & 0x3F) | 0x80;
			high_surrogate = 0;
		}
		else if( input[i] < 0x80 ) {
			output[n++] = input[i];
		}
		else if( input[i] < 0x800 ) {
			output[n++] = ((input[i] >> 6) & 0x1F) | 0xC0;
			output[n++] = (input[i] & 0x3F) | 0x80;
		} else if( input[i] <= 0xFFFF ) {
			if( 0xD800 <= input[i] <= 0xDFFF ) {
				high_surrogate = input[i];
				continue;
			}
			output[n++] = ((input[i] >> 12) & 0x0F) | 0xE0;
			output[n++] = ((input[i] >> 6) & 0x3F) | 0x80;
			output[n++] = (input[i] & 0x3F) | 0x80;
		}
	}
	bytesWrite = n;
}
// #endregion Parser }

//{ #region Helpers
/* ==============================================================================
			Helpers
================================================================================*/

void Loc_DeleteDirectory(char[] sDir)
{
	DirectoryListing hDir;
	char sFile[PLATFORM_MAX_PATH];
	FileType fileType;
	
	hDir = OpenDirectory(sDir, false);
	if( hDir )
	{
		while( hDir.GetNext(sFile, sizeof(sFile), fileType) )
		{
			if( fileType == FileType_File )
			{
				Format(sFile, sizeof(sFile), "%s/%s", sDir, sFile);
				DeleteFile(sFile, false);
			}
		}
		delete hDir;
	}
	RemoveDir(sDir);
}

bool Loc_CopyFile(char[] SourceFile, char[] TargetFile)
{
	bool result = false;
	Handle hr = OpenFile(SourceFile, "rb", false);	
	if( hr )
	{
		Handle hw = OpenFile(TargetFile, "wb", false);	
		if( hw )
		{
			int bytesRead, buff[64];
			
			while( !IsEndOfFile(hr) )
			{
				bytesRead = ReadFile(hr, buff, sizeof(buff), 1);
				WriteFile(hw, buff, bytesRead, 1);
			}
			delete hw;
			result = true;
		}
		delete hr;
	}
	return result;
}

bool Loc_Dump(int lang_num, int &count = 0)
{
	char translation[LC_MAX_TRANSLATION_LENGTH];
	char phrase[LC_MAX_PHRASE_LENGTH];
	char code[8], name[1];
	
	GetLanguageInfo(lang_num, code, sizeof(code), name, sizeof(name));
	
	StringMapSnapshot hSnap = g_hMapLcPhrase[lang_num].Snapshot();
	
	char dumpPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, dumpPath, PLATFORM_MAX_PATH, "translations/localizer");
	if( !DirExists(dumpPath) )
	{
		CreateDirectory(dumpPath, 0o755);
	}
	if( !StrEqual(code, "en") )
	{
		Format(dumpPath, PLATFORM_MAX_PATH, "%s/%s", dumpPath, code);
		
		if( !DirExists(dumpPath) )
		{
			CreateDirectory(dumpPath, 0o755);
		}
	}
	
	char dstFile[PLATFORM_MAX_PATH];
	char dstDumpFile[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, dstFile, PLATFORM_MAX_PATH, "translations/%s/%s", StrEqual(code, "en") ? "" : code, LC_TRANSLATION_FILE);
	BuildPath(Path_SM, dstDumpFile, PLATFORM_MAX_PATH, "translations/localizer/%s/%s", StrEqual(code, "en") ? "" : code, LC_TRANSLATION_FILE);
	
	File hFile = OpenFile(dstFile, "wt");
	if( !hFile ) {
		LogError("Cannot open file for writing: %s", dstFile);
		return false;
	}
	
	hFile.WriteLine("\"Phrases\"\n{");
	
	char buffer[LC_MAX_PHRASE_LENGTH+24];
	
	for( int i = 0; i < hSnap.Length; i++ )
	{
		hSnap.GetKey(i, phrase, sizeof(phrase));
		if( phrase[0] )
		{
			g_hMapLcPhrase[lang_num].GetString(phrase, translation, sizeof(translation));
			
			// WriteLine's own format buffer cannot hold more than ~2048 bytes, so we're forced to use WriteString() here instead
			FormatEx(buffer, sizeof(buffer), "\t\"#%s\"\n\t{\n\t\t\"%s\"\t\"", phrase, code);
			hFile.WriteString(buffer, false);
			hFile.WriteString(translation, false);
			hFile.WriteString("\"\n\t}\n", false);
			++ count;
		}
	}
	hFile.WriteLine("}");
	delete hFile;
	delete hSnap;
	
	Loc_CopyFile(dstFile, dstDumpFile);
	return true;
}

int Loc_GetLanguageNum(int client = LANG_SERVER, char[] lang_name = "", char[] lang_code = "")
{
	int lang_num;
	if( lang_name[0] )
	{
		lang_num = GetLanguageByName(lang_name);
	}
	else if( lang_code[0] )
	{
		lang_num = GetLanguageByCode(lang_code);
	}
	else {
		lang_num = client == 0 ? GetServerLanguage() : GetClientLanguage(client);
	}
	return lang_num;
}

void Loc_ReplacePhrases(char[] str, int len, int lang_num)
{
	if( lang_num == -1 )
		return;
	
	static char phrase[LC_MAX_PHRASE_LENGTH];
	static char translation[LC_MAX_TRANSLATION_LENGTH];
	
	int matches = g_rLcCaptures.MatchAll(str);
	if( matches )
	{
		for( int i = matches - 1; i >= 0; i-- )
		{
			g_rLcCaptures.GetSubString(0, phrase, sizeof(phrase), i);
			
			if( Loc_GetPhrase(lang_num, phrase[1], translation, sizeof(translation), true) )
			{
				ReplaceStringEx(str, len, phrase, translation);
			}
		}
	}
}

stock bool Loc_GetPhrase(int lang_num, char[] phrase, char[] translation, int maxlength, bool default_on_fail = false, bool use_cache = true)
{
	static char tr[LC_MAX_TRANSLATION_LENGTH];
	static char tr_def[LC_MAX_TRANSLATION_LENGTH];
	
	bool useL2 = use_cache || ( g_iLcInstallMode & LC_INSTALL_MODE_FULLCACHE );
	
	if( useL2 && g_hMapLcPhrase[lang_num].GetString(phrase, translation, maxlength) )
	{
		return true;
	}
	else {
		if( g_iLcInstallMode & LC_INSTALL_MODE_DATABASE )
		{
			if( SQL_Loc_Query(lang_num, phrase, translation, maxlength) )
			{
				if( use_cache )
				{
					g_hMapLcPhrase[lang_num].SetString(phrase, translation);
					
					if( lang_num == LANG_SERVER )
					{
						strcopy(tr_def, LC_MAX_TRANSLATION_LENGTH, translation);
					}
					else {
						Loc_GetPhrase(LANG_SERVER, phrase, tr_def, LC_MAX_TRANSLATION_LENGTH);
					}
					
					for( int i = 0; i < GetLanguageCount(); i++ ) // pre-cache all languages of this phrase in advance
	    			{
	    				if( i != lang_num )
	    				{
		    				if( SQL_Loc_Query(i, phrase, tr, sizeof(tr)) )
	    					{
	    						g_hMapLcPhrase[i].SetString(phrase, tr);
	    					}
	    					else {
	    						g_hMapLcPhrase[i].SetString(phrase, tr_def);
	    					}
	    				}
					}
				}
				return true;
			}
			else {
				if( default_on_fail )
				{
					return Loc_GetPhrase(LANG_SERVER, phrase, translation, maxlength);
				}
			}
		}
		else if( g_iLcInstallMode & LC_INSTALL_MODE_FULLCACHE )
		{
			if( default_on_fail )
			{
				if( lang_num != LANG_SERVER )
				{
					if( g_hMapLcPhrase[LANG_SERVER].GetString(phrase, translation, maxlength) )
					{
						return true;
					}
				}
			}
		}
	}
	translation[0] = 0;
	return false;
}

bool Loc_LoadTranslations()
{
	char dstFile[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, dstFile, PLATFORM_MAX_PATH, "translations/%s", LC_TRANSLATION_FILE);
	
	if( FileExists(dstFile) )
	{
		g_hLcProf.Start();
		LoadTranslations(LC_TRANSLATION_FILE);
		InsertServerCommand("sm_reload_translations");
		ServerExecute();
		g_hLcProf.Stop();
    	#if defined LC_PROFILER
			PrintToServer(">> Profiler report for: %s: %.2f sec.", "LoadTranslations", g_hLcProf.Time);
		#endif
		return true;
	}
	LogError("Attempt to load translation file without dumping first: %s", dstFile);
	return false;
}

void Loc_RemoveTranslationFiles()
{
	char code[8], name[1], dstFile[PLATFORM_MAX_PATH];
	
	for( int i = 0; i < GetLanguageCount(); i++ )
	{
		GetLanguageInfo(i, code, sizeof(code), name, sizeof(name));
		BuildPath(Path_SM, dstFile, PLATFORM_MAX_PATH, "translations/%s/%s", StrEqual(code, "en") ? "" : code, LC_TRANSLATION_FILE);
		DeleteFile(dstFile);
	}
}

char[] Loc_InstallMode_ToString()
{
	char str[32];
	str =
		g_iLcInstallMode == LC_INSTALL_MODE_DATABASE ? "DATABASE" :
		g_iLcInstallMode == LC_INSTALL_MODE_FULLCACHE ? "FULLCACHE" :
		g_iLcInstallMode == LC_INSTALL_MODE_TRANSLATIONFILE ? "TRANSLATIONFILE" :
		g_iLcInstallMode == LC_INSTALL_MODE_CUSTOM ? "SKIP" :
		"Unknown";
	return str;
}
// #endregion Helpers }

//{ #region Database
/* ==============================================================================
			Database
================================================================================*/

void SQL_Loc_DB_Connect(bool uninstall = false)
{
	char error[256];
	if( !g_hLcDB )
	{
		#if LC_USE_SQLITE
			g_hLcDB = SQLite_UseDatabase("sourcemod-local", error, sizeof(error));
		#else
			g_hLcDB = SQL_DefConnect(error, sizeof(error), true);
		#endif
		SQL_Loc_OnDBConnect(g_hLcDB, error, uninstall);
	}
	else {
		SQL_Loc_OnDBConnect(g_hLcDB, "", uninstall);
	}
	g_iLcQueueTx = 0;
}

public void SQL_Loc_OnDBConnect(Database db, const char[] error, any data)
{
	if( db == null || error[0] )
	{
		SetFailState("OnDBConnect: %s", error);
		return;
	}
	if( data )
	{
		SQL_Loc_RemoveTable();
	}
	else {
		Loc_CreateTables();
	}
}

void Loc_CreateTables()
{
	char query[640];
	FormatEx(query, sizeof(query), "CREATE TABLE IF NOT EXISTS `" ... LC_DATABASE_TABLE ... "` (\
		`lang` INTEGER UNSIGNED NOT NULL default 0, \
		`phrase` VARCHAR(%i) NOT NULL, \
		`translation` VARCHAR(%i) NOT NULL, \
		PRIMARY KEY (lang, phrase) );", LC_MAX_PHRASE_LENGTH, LC_MAX_TRANSLATION_LENGTH);
	
	g_hLcDB.Query(SQL_Loc_Callback_TableCreate, query);
}

public void SQL_Loc_Callback_TableCreate(Database db, DBResultSet hQuery, const char[] error, any data)
{
	if (!db || !hQuery) { LogError(error); return; }
	
	g_hLcDB.SetCharset("utf8");
	
	Loc_GetPhraseFiles("");
}

/*
	Queue INSERT/REPLACE query operation to transaction until safe limit per 1 tx will be reached.
	
	@bOverwrite - true is REPLACE, false - INSERT
	@bFinishPending - to force execution of transaction
	
	@return - indicates whether we can wait a callback:
		true if transaction executed and callback is awaiting,
		false - when query is only queued or no queue exists to finish pending operation.
*/
bool SQL_Loc_InsertBatch(int lang_num, char[] phrase, char[] translation, bool bOverwrite = false, bool bFinishPending = false)
{
	const int MAX_SAFE_QUERIES_PER_TRANSACTION = 1000; /* should be < 2388 otherwise #pragma dynamic increase is required
														to prevent "Not enough space on the heap" error.
														Split is also required to prevent IQuery handles leak (overflow) */
	
	static Transaction tx;
	static int queries;
	
	if( bFinishPending )
	{
		if( queries )
		{
			++ g_iLcQueueTx;
			g_hLcDB.Execute(tx, SQL_Loc_Tx_Success, SQL_Loc_Tx_Failure);
			queries = 0;
			return true;
		}
		return false;
	}
	if( !queries )
	{
		tx = new Transaction();
	}
	
	static char query[2*(LC_MAX_PHRASE_LENGTH+LC_MAX_TRANSLATION_LENGTH+100)+1];
	
	if( bOverwrite )
	{
		g_hLcDB.Format(query, sizeof(query), "REPLACE INTO `" ... LC_DATABASE_TABLE ... "` (lang, phrase, translation) \
			VALUES (%i, '%s', '%s');", lang_num, phrase, translation);
	}
	else {
		g_hLcDB.Format(query, sizeof(query), "INSERT INTO `" ... LC_DATABASE_TABLE ... "` (lang, phrase, translation) \
			VALUES (%i, '%s', '%s') ON CONFLICT DO NOTHING;", lang_num, phrase, translation);
	}
	
	tx.AddQuery(query);
	++ queries;
	
	if( queries >= MAX_SAFE_QUERIES_PER_TRANSACTION )
	{
		++ g_iLcQueueTx;
		g_hLcDB.Execute(tx, SQL_Loc_Tx_Success, SQL_Loc_Tx_Failure);
		queries = 0;
		return true;
	}
	return false;
}

void SQL_Loc_Insert(int lang_num, char[] phrase, char[] translation, bool bOverwrite = false, bool bAsync = true)
{
	static char query[2*(LC_MAX_PHRASE_LENGTH+LC_MAX_TRANSLATION_LENGTH+100)+1];
	
	if( bOverwrite )
	{
		g_hLcDB.Format(query, sizeof(query), "REPLACE INTO `" ... LC_DATABASE_TABLE ... "` (lang, phrase, translation) \
			VALUES (%i, '%s', '%s');", lang_num, phrase, translation);
	}
	else {
		g_hLcDB.Format(query, sizeof(query), "INSERT INTO `" ... LC_DATABASE_TABLE ... "` (lang, phrase, translation) \
			VALUES (%i, '%s', '%s') ON CONFLICT DO NOTHING;", lang_num, phrase, translation);
	}
	
	if( bAsync )
	{
		g_hLcDB.Query(SQL_Loc_Callback, query);
	}
	else {
		SQL_LockDatabase(g_hLcDB);
		DBResultSet hQuery = SQL_Query(g_hLcDB, query);
		SQL_UnlockDatabase(g_hLcDB);
		delete hQuery;
	}
}

void SQL_Loc_RemovePhrase(char[] phrase)
{
	char query[2*(LC_MAX_PHRASE_LENGTH+50)+1];
	g_hLcDB.Format(query, sizeof(query), "DELETE FROM `" ... LC_DATABASE_TABLE ... "` WHERE UPPER(phrase) = UPPER('%s');", phrase);
	g_hLcDB.Query(SQL_Loc_Callback, query);
}

void SQL_Loc_RemoveTable()
{
	if( g_hLcDB )
	{
		char query[100];
		FormatEx(query, sizeof(query), "DROP TABLE IF EXISTS `" ... LC_DATABASE_TABLE ... "`;");
		g_hLcDB.Query(SQL_Loc_Callback, query); // DBPrio_High is interfere here for some reason
	}
	else {
		SQL_Loc_DB_Connect(true);
	}
}

void SQL_Loc_Callback(Database db, DBResultSet hQuery, const char[] error, any data)
{
	if (!db || !hQuery) { LogError(error); return; }
}

public bool SQL_Loc_Query(int lang_num, char[] phrase, char[] translation, int maxlength)
{
	static DBStatement hUserStmt;
	if( hUserStmt == null )
    {
        char error[255];
        hUserStmt = SQL_PrepareQuery(g_hLcDB, "SELECT translation FROM `" ... LC_DATABASE_TABLE ... "` \
        	WHERE lang = ? AND UPPER(phrase) = UPPER(?);", error, sizeof(error));
    }
	
	SQL_BindParamInt(hUserStmt, 0, lang_num, true);
	SQL_BindParamString(hUserStmt, 1, phrase, false);
	
	SQL_LockDatabase(g_hLcDB);
	SQL_Execute(hUserStmt);
	SQL_UnlockDatabase(g_hLcDB);
	
	if( SQL_FetchRow(hUserStmt) )
	{
		SQL_FetchString(hUserStmt, 0, translation, maxlength);
		return true;
	}
	
	/* // alternate
	static char query[1024];
	Format(query, sizeof(query), 
		"SELECT translation FROM `" ... LC_DATABASE_TABLE ... "` WHERE lang = %i AND phrase = '%s';", lang_num, phrase);
	
	SQL_LockDatabase(g_hLcDB);
	DBResultSet hQuery = SQL_Query(g_hLcDB, query);
	SQL_UnlockDatabase(g_hLcDB);
	
	if( hQuery )
	{
		if( SQL_FetchRow(hQuery) )
		{
			SQL_FetchString(hQuery, 0, translation, maxlength);
			return true;
		}
	}
	*/
	
	translation[0] = 0;
	return false;
}

public void SQL_Loc_Tx_Success(Database db, any data, int numQueries, DBResultSet[] results, any[] queryData)
{
	-- g_iLcQueueTx;
	
	if( !g_bLcDecodeInProgress && g_iLcQueueTx == 0 )
	{
		OnPhrasesProcessingCompleted_CallDelayed();
	}
}

public void SQL_Loc_Tx_Failure(Database db, any data, int numQueries, const char[] error, int failIndex, any[] queryData)
{
	-- g_iLcQueueTx;
	LogError(error);
}

int SQL_Loc_GetIndex(char[] name)
{
	char str[16];
	if( SQL_Loc_Query(0, name, str, sizeof(str)) )
	{
		return StringToInt(str);
	}
	return 0;
}

void SQL_Loc_SetIndex(char[] name, int iStamp, bool bFinishPending = false)
{
	static StringMap hMap;
	if( bFinishPending )
	{
		if( !hMap )
		{
			return;
		}
		char str[16], _name[128];
		StringMapSnapshot hSnap = hMap.Snapshot();
		if( hSnap )
		{
			for( int i = 0; i < hSnap.Length; i++ )
			{
				hSnap.GetKey(i, _name, sizeof(_name));
				hMap.GetValue(_name, iStamp);
				IntToString(iStamp, str, sizeof(str));
				SQL_Loc_Insert(0, _name, str, true, true);
			}
			delete hSnap;
		}
		delete hMap;
	}
	else {
		if( !hMap )
		{
			hMap = new StringMap();
		}
		hMap.SetValue(name, iStamp, true); // we must wait until transactions are really finished before populating the index
	}
}
// #endregion Database }
