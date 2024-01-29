#if defined __confogl_configs_included
	#endinput
#endif
#define __confogl_configs_included

#define CONFIGS_MODULE_NAME				"Configs"

static const char
	customCfgDir[] = "cfgogl";

static char
	DirSeparator = '\0',
	configsPath[PLATFORM_MAX_PATH] = "\0",
	cfgPath[PLATFORM_MAX_PATH] = "\0",
	customCfgPath[PLATFORM_MAX_PATH] = "\0",
	customCfgName[PLATFORM_MAX_PATH] = "\0";

static ConVar
	hCustomConfig = null;

void Configs_APL()
{
	CreateNative("LGO_BuildConfigPath", _native_BuildConfigPath);
	CreateNative("LGO_ExecuteConfigCfg", _native_ExecConfigCfg);
	CreateNative("LGO_GetConfigName", _native_GetConfigName);
}

void Configs_OnModuleStart()
{
	InitPaths();

	hCustomConfig = CreateConVarEx("customcfg", "", "DONT TOUCH THIS CVAR! This is more magic bullshit!", FCVAR_DONTRECORD|FCVAR_UNLOGGED);

	char cfgString[PLATFORM_MAX_PATH];
	hCustomConfig.GetString(cfgString, sizeof(cfgString));
	SetCustomCfg(cfgString);

	hCustomConfig.RestoreDefault();
}

static void InitPaths()
{
	BuildPath(Path_SM, configsPath, sizeof(configsPath), "configs/confogl/");
	BuildPath(Path_SM, cfgPath, sizeof(cfgPath), "../../cfg/");

	DirSeparator = cfgPath[(strlen(cfgPath) - 1)];
}

bool SetCustomCfg(const char[] cfgname)
{
	if (!strlen(cfgname)) {
		customCfgPath[0] = 0;
		hCustomConfig.RestoreDefault();

		if (IsDebugEnabled()) {
			LogMessage("[%s] Custom Config Path Reset - Using Default", CONFIGS_MODULE_NAME);
		}

		return true;
	}

	Format(customCfgPath, sizeof(customCfgPath), "%s%s%c%s", cfgPath, customCfgDir, DirSeparator, cfgname);
	if (!DirExists(customCfgPath)) {
		Debug_LogError(CONFIGS_MODULE_NAME, "Custom config directory %s does not exist!", customCfgPath);
		// Revert customCfgPath
		customCfgPath[0] = 0;
		return false;
	}

	int thislen = strlen(customCfgPath);
	if ((thislen + 1) < sizeof(customCfgPath)) {
		customCfgPath[thislen] = DirSeparator;
		customCfgPath[(thislen + 1)] = 0;
	} else {
		Debug_LogError(CONFIGS_MODULE_NAME, "Custom config directory %s path too long!", customCfgPath);
		customCfgPath[0] = 0;
		return false;
	}

	strcopy(customCfgName, sizeof(customCfgName), cfgname);
	hCustomConfig.SetString(cfgname);

	return true;
}

void BuildConfigPath(char[] buffer, const int maxlength, const char[] sFileName)
{
	if (customCfgPath[0]) {
		Format(buffer, maxlength, "%s%s", customCfgPath, sFileName);

		if (FileExists(buffer)) {
			if (IsDebugEnabled()) {
				LogMessage("[%s] Built custom config path: %s", CONFIGS_MODULE_NAME, buffer);
			}

			return;
		} else {
			if (IsDebugEnabled()) {
				LogMessage("[%s] Custom config not available: %s", CONFIGS_MODULE_NAME, buffer);
			}
		}
	}

	Format(buffer, maxlength, "%s%s", configsPath, sFileName);
	if (IsDebugEnabled()) {
		LogMessage("[%s] Built default config path: %s", CONFIGS_MODULE_NAME, buffer);
	}
}

void ExecuteCfg(const char[] sFileName)
{
	if (strlen(sFileName) == 0) {
		return;
	}

	char sFilePath[PLATFORM_MAX_PATH];

	if (customCfgPath[0]) {
		Format(sFilePath, sizeof(sFilePath), "%s%s", customCfgPath, sFileName);

		if (FileExists(sFilePath)) {
			if (IsDebugEnabled()) {
				LogMessage("[%s] Executing custom cfg file %s", CONFIGS_MODULE_NAME, sFilePath);
			}

			ServerCommand("exec %s%s", customCfgPath[strlen(cfgPath)], sFileName);

			return;
		} else {
			if (IsDebugEnabled()) {
				LogMessage("[%s] Couldn't find custom cfg file %s, trying default", CONFIGS_MODULE_NAME, sFilePath);
			}
		}
	}

	Format(sFilePath, sizeof(sFilePath), "%s%s", cfgPath, sFileName);

	if (FileExists(sFilePath)) {
		if (IsDebugEnabled()) {
			LogMessage("[%s] Executing default config %s", CONFIGS_MODULE_NAME, sFilePath);
		}

		ServerCommand("exec %s", sFileName);
	} else {
		Debug_LogError(CONFIGS_MODULE_NAME, "Could not execute server config \"%s\", file not found", sFilePath);
	}
}

static int _native_BuildConfigPath(Handle plugin, int numParams)
{
	int iLen = 0;
	GetNativeStringLength(3, iLen);

	int iNewLen = iLen + 1;
	char[] sFileName = new char[iNewLen];
	GetNativeString(3, sFileName, iNewLen);

	iLen = GetNativeCell(2);

	char[] sBuf = new char[iLen];
	BuildConfigPath(sBuf, iLen, sFileName);
	SetNativeString(1, sBuf, iLen);

	return 1;
}

static int _native_ExecConfigCfg(Handle plugin, int numParams)
{
	int iLen = 0;
	GetNativeStringLength(1, iLen);

	int iNewLen = iLen + 1;
	char[] sFileName = new char[iNewLen];
	GetNativeString(1, sFileName, iNewLen);

	ExecuteCfg(sFileName);

	return 1;
}

static int _native_GetConfigName(Handle plugin, int numParams)
{
	SetNativeString(1, customCfgName, GetNativeCell(2), true);
	return 1;
}
