#pragma semicolon 1

#define MAX_PATCH_SIZE 255
#define MAX_PATCH_NAME_LENGTH 63
#define MAX_VALUE_LENGTH (MAX_PATCH_SIZE*4)

new Handle:hGameConfig;
new bool:bIsWindows;

new Handle:hPatchNames;
new Handle:hPatchAddresses;
new Handle:hPatchBytes;

new Handle:hPatchAppliedForward;

static GetPackedByte(cell, i)
{
	return (cell >> ((3-i)*8)) & 0xff;
}

static SetPackedByte(cell, i, byte)
{
	new mask = 0xff << ((3-i)*8);
	return (cell & ~mask) | (byte << ((3-i)*8));
}

static GetBytes(Handle:array, String:bytes[], idx)
{
	new cell = GetArrayCell(array, idx, 0);
	new count = GetPackedByte(cell, 0);
	new j = 0;

	for (new i = 1; i <= count; ++i)
	{
		if (i % 4 == 0)
			cell = GetArrayCell(array, idx, i/4);

		bytes[j++] = GetPackedByte(cell, i % 4);
	}

	return count;
}

static PushBytes(Handle:array, String:bytes[], count)
{
	new nCells = ByteCountToCells(count + 1);
	new cells[nCells];

	cells[0] = SetPackedByte(cells[0], 0, count);

	new j = 0;

	for (new i = 1; i <= count; ++i)
	{
		if (i % 4 == 0)
			++j;

		cells[j] = SetPackedByte(cells[j], i % 4, bytes[i-1]);
	}

	PushArrayArray(array, cells, nCells);
}

static FormatBytes(const String:bytes[], nBytes, String:output[])
{
	new j = 0;

	for (new i = 0; i < nBytes; ++i)
	{
		new hinibble = (bytes[i] >> 4) & 0x0f;
		new lonibble = bytes[i] & 0xf;

		if (hinibble > 9)
			output[j++] = 'a' + (hinibble-10);
		else
			output[j++] = '0' + hinibble;

		if (lonibble > 9)
			output[j++] = 'a' + (lonibble-10);
		else
			output[j++] = '0' + lonibble;

		output[j++] = ' ';
	}

	output[j++] = '\0';
}

static bool:ParseBytes(const String:value[], String:bytes[], count)
{
	new length = strlen(value);

	if (length != count * 4)
		return false;

	decl String:hex[3];
	new j = 0;

	for (new i = 0; i < length; i += 4)
	{
		if (value[i] != '\\')
			return false;

		if (value[i+1] != 'x')
			return false;

		hex[0] = value[i+2];
		hex[1] = value[i+3];
		hex[2] = 0;

		bytes[j++] = StringToInt(hex, 16);
	}

	return true;
}

static WriteBytesToMemory(Address:addr, const String:bytes[], count)
{
	for (new i = 0; i < count; ++i)
		StoreToAddress(addr + Address:i, bytes[i] & 0xff, NumberType_Int8);
}

static ReadBytesFromMemory(Address:addr, String:bytes[], count)
{
	for (new i = 0; i < count; ++i)
		bytes[i] = LoadFromAddress(addr + Address:i, NumberType_Int8);
}

static FindPatch(const String:name[])
{
	decl String:iterName[MAX_PATCH_NAME_LENGTH];

	new size = GetArraySize(hPatchNames);

	for (new i = 0; i < size; ++i)
	{
		GetArrayString(hPatchNames, i, iterName, sizeof(iterName));

		if (StrEqual(name, iterName))
			return i;
	}

	return -1;
}

static ApplyPatch(const String:name[], Address:addr, const String:bytes[], length)
{
	decl String:oldBytes[length];

	ReadBytesFromMemory(addr, oldBytes, length);
	WriteBytesToMemory(addr, bytes, length);

	PushArrayString(hPatchNames, name);
	PushArrayCell(hPatchAddresses, addr);
	PushBytes(hPatchBytes, oldBytes, length);

	new Action:result;

	Call_StartForward(hPatchAppliedForward);
	Call_PushString(name);
	Call_Finish(_:result);
}

static bool:RevertPatch(const String:name[])
{
	new patchId = FindPatch(name);

	if (patchId == -1)
		return false;

	decl String:bytes[MAX_PATCH_SIZE];
	new count = GetBytes(hPatchBytes, bytes, patchId);

	new Address:addr = GetArrayCell(hPatchAddresses, patchId);

	WriteBytesToMemory(addr, bytes, count);

	RemoveFromArray(hPatchNames, patchId);
	RemoveFromArray(hPatchAddresses, patchId);
	RemoveFromArray(hPatchBytes, patchId);

	return true;
}

public OnPluginStart()
{
	hPatchAppliedForward = CreateGlobalForward("OnPatchApplied", ET_Event, Param_String);
	hGameConfig = LoadGameConfigFile("code_patcher");

	if (hGameConfig == INVALID_HANDLE)
		SetFailState("Could not load gamedata");

	bIsWindows = GameConfGetOffset(hGameConfig, "Platform") != 0;

	hPatchNames = CreateArray(ByteCountToCells(MAX_PATCH_NAME_LENGTH+1));
	hPatchAddresses = CreateArray();
	hPatchBytes = CreateArray(ByteCountToCells(MAX_PATCH_SIZE+1));

	RegServerCmd("codepatch_list", CodePatchListCommand);
	RegServerCmd("codepatch_patch", CodePatchPatchCommand);
	RegServerCmd("codepatch_unpatch", CodePatchUnpatchCommand);

	// Waterslowdown Optimization fix. (Stupid Valve check)
	ServerCommand("codepatch_patch slowdown");
}

public OnPluginEnd()
{
	new size = GetArraySize(hPatchNames);

	decl String:name[MAX_PATCH_NAME_LENGTH+1];

	for (new i = 0; i < size; ++i)
	{
		GetArrayString(hPatchNames, i, name, sizeof(name));
		RevertPatch(name);
	}
}

public Action:CodePatchListCommand(args)
{
	decl String:name[MAX_PATCH_NAME_LENGTH+1];
	decl String:bytes[MAX_PATCH_SIZE];
	decl String:formattedBytes[MAX_PATCH_SIZE*3];

	new size = GetArraySize(hPatchNames);

	if (size == 0)
	{
		PrintToServer("No patches applied");
		return;
	}

	for (new i = 0; i < size; ++i)
	{
		new nBytes = GetBytes(hPatchBytes, bytes, i);
		FormatBytes(bytes, nBytes, formattedBytes);

		GetArrayString(hPatchNames, i, name, sizeof(name));
		new Address:addr = GetArrayCell(hPatchAddresses, i);

		PrintToServer("%d. %s\t0x%x: %s", i+1, name, addr, formattedBytes);
	}
}

public Action:CodePatchPatchCommand(args)
{
	if (GetCmdArgs() != 1)
	{
		PrintToServer("syntax: codepatch_patch <patch_name>");
		return;
	}

	decl String:name[MAX_PATCH_NAME_LENGTH+1];
	GetCmdArg(1, name, sizeof(name));

	new patchId = FindPatch(name);

	if (patchId != -1)
	{
		PrintToServer("Patch '%s' is already loaded", name);
		return;
	}

	decl String:key[MAX_PATCH_NAME_LENGTH+32];
	decl String:value[MAX_VALUE_LENGTH+1];

	Format(key, sizeof(key), "%s_signature", name);
	if (! GameConfGetKeyValue(hGameConfig, key, value, sizeof(value)))
	{
		PrintToServer("Could not find key '%s'", key);
		return;
	}

	new Address:addr = GameConfGetAddress(hGameConfig, value);
	if (! addr)
	{
		PrintToServer("Could not load signature '%s'", value);
		return;
	}

	Format(key, sizeof(key), "%s_offset", name);
	if (! GameConfGetKeyValue(hGameConfig, key, value, sizeof(value)))
	{
		PrintToServer("Could not find key '%s'", key);
		return;
	}

	new offset = GameConfGetOffset(hGameConfig, value);
	if (offset == -1)
	{
		PrintToServer("Could not load offset '%s'", value);
		return;
	}

	Format(key, sizeof(key), "%s_length_%s", name, bIsWindows ? "windows" : "linux");
	if (! GameConfGetKeyValue(hGameConfig, key, value, sizeof(value)))
	{
		PrintToServer("Could not find key '%s'", key);
		return;
	}

	new length = StringToInt(value);

	if (length < 1 || length > MAX_PATCH_SIZE)
	{
		PrintToServer("Too %s patch bytes for '%s'", length < 1 ? "few" : "many", name);
		return;
	}

	Format(key, sizeof(key), "%s_bytes_%s", name, bIsWindows ? "windows" : "linux");
	if (! GameConfGetKeyValue(hGameConfig, key, value, sizeof(value)))
	{
		PrintToServer("Could not find key '%s'", key);
		return;
	}

	decl String:bytes[length];

	if (! ParseBytes(value, bytes, length))
	{
		PrintToServer("Failed to parse patch bytes for '%s'", name);
		return;
	}

	addr += Address:offset;

	ApplyPatch(name, addr, bytes, length);

	decl String:formattedBytes[MAX_PATCH_SIZE*3];
	FormatBytes(bytes, length, formattedBytes);

	PrintToServer("Applied patch '%s' [ %s] at 0x%x", name, formattedBytes, addr);
}

public Action:CodePatchUnpatchCommand(args)
{
	if (GetCmdArgs() != 1)
	{
		PrintToServer("syntax: codepatch_unpatch <patch_name>");
		return;
	}

	decl String:name[MAX_PATCH_NAME_LENGTH+1];
	GetCmdArg(1, name, sizeof(name));

	new patchId = FindPatch(name);

	if (patchId == -1)
	{
		PrintToServer("Patch '%s' is not loaded", name);
		return;
	}

	RevertPatch(name);

	PrintToServer("Reverted patch '%s'", name);
}

public IsPatchApplied(Handle:plugin, nArgs)
{
	new length;
	GetNativeStringLength(1, length);
 
 	if (length <= 0)
 		return _:false;
 
 	decl String:name[length + 1];
 	GetNativeString(1, name, length + 1);

 	new patchId = FindPatch(name);

 	return patchId != -1;
}

public GetPatchAddress(Handle:plugin, nArgs)
{
	new length;
	GetNativeStringLength(1, length);
 
 	if (length <= 0)
 		return _:Address_Null;
 
 	decl String:name[length + 1];
 	GetNativeString(1, name, length + 1);

 	new patchId = FindPatch(name);

 	if (patchId == -1)
 		return _:Address_Null;

 	return GetArrayCell(hPatchAddresses, patchId);
}

public IsPlatformWindows(Handle:plugin, nArgs)
{
	return _:bIsWindows;
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("IsPatchApplied", IsPatchApplied);
	CreateNative("GetPatchAddress", GetPatchAddress);
	CreateNative("IsPlatformWindows", IsPlatformWindows);
	RegPluginLibrary("code_patcher");
}