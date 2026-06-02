/**
 * SourceScramble Manager
 * 
 * A loader for simple memory patches.
 */
#pragma semicolon 1
#include <sourcemod>

#pragma newdecls required

#include <sourcescramble>

#define PLUGIN_VERSION "1.2.0"
public Plugin myinfo = {
	name = "Source Scramble Manager",
	author = "nosoop",
	description = "Helper plugin to load simple assembly patches from a configuration file.",
	version = PLUGIN_VERSION,
	url = "https://github.com/nosoop/SMExt-SourceScramble"
}

public void OnPluginStart() {
	SMCParser parser = new SMCParser();
	
	parser.OnKeyValue = PatchMemConfigEntry;
	
	char configFile[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, configFile, sizeof(configFile), "configs/sourcescramble_manager.cfg");
	
	parser.ParseFile(configFile);
	
	char configDirectory[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, configDirectory, sizeof(configDirectory), "configs/sourcescramble");
	
	if (DirExists(configDirectory)) {
		char fileEntry[PLATFORM_MAX_PATH];
		DirectoryListing configFiles = OpenDirectory(configDirectory);
		FileType dirEntryType;
		while (configFiles.GetNext(fileEntry, sizeof(fileEntry), dirEntryType)) {
			if (dirEntryType != FileType_File) {
				continue;
			}
			
			Format(configFile, sizeof(configFile), "%s/%s", configDirectory, fileEntry);
			parser.ParseFile(configFile);
		}
	}
	
	delete parser;
}

public SMCResult PatchMemConfigEntry(SMCParser smc, const char[] key, const char[] value,
		bool key_quotes, bool value_quotes) {
	Handle hGameConf = LoadGameConfigFile(key);
	if (!hGameConf) {
		LogError("Failed to load gamedata (%s).", key);
		return SMCParse_Continue;
	}
	
	// patches are cleaned up when the plugin is unloaded
	MemoryPatch patch = MemoryPatch.CreateFromConf(hGameConf, value);
	
	delete hGameConf;
	
	if (!patch.Validate()) {
		PrintToServer("[sourcescramble] Failed to verify patch \"%s\" from \"%s\"", value, key);
	} else if (patch.Enable()) {
		PrintToServer("[sourcescramble] Enabled patch \"%s\" from \"%s\" at address: 0x%08X",
				value, key, patch.Address);
	}
	return SMCParse_Continue;
}
