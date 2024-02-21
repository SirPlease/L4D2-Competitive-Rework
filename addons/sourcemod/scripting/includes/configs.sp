#pragma semicolon 1
#include <sourcemod>

#if defined __CONFOGL_CONFIGS__
#endinput
#endif

#define __CONFOGL_CONFIGS__

static const String:customCfgDir[] = "cfgogl";

static Handle:hCustomConfig;
static String:configsPath[PLATFORM_MAX_PATH];
static String:cfgPath[PLATFORM_MAX_PATH];
static String:customCfgPath[PLATFORM_MAX_PATH];
static DirSeparator;

Configs_OnModuleStart()
{
	InitPaths();
	hCustomConfig = CreateConVarEx("customcfg", "", "DONT TOUCH THIS CVAR! This is more magic bullshit!",FCVAR_DONTRECORD|FCVAR_UNLOGGED);
	decl String:cfgString[64];
	GetConVarString(hCustomConfig, cfgString, sizeof(cfgString));
	SetCustomCfg(cfgString);
	ResetConVar(hCustomConfig);
}
Configs_APL()
{
	CreateNative("LGO_BuildConfigPath", _native_BuildConfigPath);
	CreateNative("LGO_ExecuteConfigCfg", _native_ExecConfigCfg);
}

InitPaths()
{
	BuildPath(Path_SM, configsPath, sizeof(configsPath), "configs/confogl/");
	BuildPath(Path_SM, cfgPath, sizeof(cfgPath), "../../cfg/");
	DirSeparator= cfgPath[strlen(cfgPath)-1];
}

bool:SetCustomCfg(const String:cfgname[])
{
	if(!strlen(cfgname))
	{
		customCfgPath[0]=0;
		ResetConVar(hCustomConfig);
		if(IsDebugEnabled())
		{
			LogMessage("[Configs] Custom Config Path Reset - Using Default");
		}
		return true;
	}
	
	Format(customCfgPath, sizeof(customCfgPath), "%s%s%c%s", cfgPath, customCfgDir, DirSeparator, cfgname);
	if(!DirExists(customCfgPath))
	{
		LogError("[Configs] Custom config directory %s does not exist!", customCfgPath);
		// Revert customCfgPath
		customCfgPath[0]=0;
		return false;
	}
	new thislen = strlen(customCfgPath);
	if(thislen+1 < sizeof(customCfgPath))
	{
		customCfgPath[thislen] = DirSeparator;
		customCfgPath[thislen+1] = 0;
	}
	else
	{
		LogError("[Configs] Custom config directory %s path too long!", customCfgPath);
		customCfgPath[0]=0;
		return false;
	}
	
	SetConVarString(hCustomConfig, cfgname);
	
	return true;	
}

BuildConfigPath(String:buffer[], maxlength, const String:sFileName[])
{
	if(customCfgPath[0])
	{
		Format(buffer, maxlength, "%s%s", customCfgPath, sFileName);
		if(FileExists(buffer))
		{
			if(IsDebugEnabled())
			{
				LogMessage("[Configs] Built custom config path: %s", buffer);
			}
			return;
		}
		else
		{
			if(IsDebugEnabled())
			{
				LogMessage("[Configs] Custom config not available: %s", buffer);
			}
		}
	}
	
	Format(buffer, maxlength, "%s%s", configsPath, sFileName);
	if(IsDebugEnabled())
	{
			LogMessage("[Configs] Built default config path: %s", buffer);
	}
	
}

ExecuteCfg(const String:sFileName[])
{
	if(strlen(sFileName) == 0)
	{
		return;
	}
	
	decl String:sFilePath[PLATFORM_MAX_PATH];
	
	if(customCfgPath[0])
	{
		Format(sFilePath, sizeof(sFilePath), "%s%s", customCfgPath, sFileName);
		if(FileExists(sFilePath))
		{
			if(IsDebugEnabled())
			{
				LogMessage("[Configs] Executing custom cfg file %s", sFilePath);
			}
			ServerCommand("exec %s%s", customCfgPath[strlen(cfgPath)], sFileName);
			
			return;
		}
		else
		{
			if(IsDebugEnabled())
			{
				LogMessage("[Configs] Couldn't find custom cfg file %s, trying default", sFilePath);
			}
		}
	}
	
	Format(sFilePath, sizeof(sFilePath), "%s%s", cfgPath, sFileName);
	
	
	if(FileExists(sFilePath))
	{
		if(IsDebugEnabled())
		{
			LogMessage("[Configs] Executing default config %s", sFilePath);
		}
		ServerCommand("exec %s", sFileName);
	}
	else
	{
		LogError("[Configs] Could not execute server config \"%s\", file not found", sFilePath);
	}
}

public _native_BuildConfigPath(Handle:plugin, numParams)
{
	decl len;
	GetNativeStringLength(3, len);
	new String:filename[len+1];
	GetNativeString(3, filename, len+1);
		
	len = GetNativeCell(2);
	new String:buf[len];
	BuildConfigPath(buf, len, filename);
	
	SetNativeString(1, buf, len);
}

public _native_ExecConfigCfg(Handle:plugin, numParams)
{
	decl len;	
	GetNativeStringLength(1, len);
	new String:filename[len+1];
	GetNativeString(1, filename, len+1);
	
	ExecuteCfg(filename);
}
