#pragma semicolon 1
#pragma newdecls required

#define MAX_PATCH_SIZE 255
#define MAX_PATCH_NAME_LENGTH 63
#define MAX_VALUE_LENGTH (MAX_PATCH_SIZE * 4)

Handle
	hGameConfig,
	hPatchAppliedForward;

bool 
	bIsWindows;

ArrayList 
	hPatchNames,
	hPatchAddresses,
	hPatchBytes;

public Plugin myinfo = 
{
	name = "Code patcher",
	author = "Jahze?", //new syntax A1m`, fix unload error
	version = "1.1",
	description = "Code patcher",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework" 
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("IsPatchApplied", IsPatchApplied);
	CreateNative("GetPatchAddress", GetPatchAddress);
	CreateNative("IsPlatformWindows", IsPlatformWindows);
	
	RegPluginLibrary("code_patcher");
	return APLRes_Success;
}

public void OnPluginStart()
{
	hPatchAppliedForward = CreateGlobalForward("OnPatchApplied", ET_Ignore, Param_String);
	hGameConfig = LoadGameConfigFile("code_patcher");

	if (hGameConfig == INVALID_HANDLE) {
		SetFailState("Could not load gamedata");
	}
	
	bIsWindows = GameConfGetOffset(hGameConfig, "Platform") != 0;

	hPatchNames = new ArrayList(ByteCountToCells(MAX_PATCH_NAME_LENGTH + 1));
	hPatchAddresses = new ArrayList();
	hPatchBytes = new ArrayList(ByteCountToCells(MAX_PATCH_SIZE + 1));

	RegServerCmd("codepatch_list", CodePatchListCommand);
	RegServerCmd("codepatch_patch", CodePatchPatchCommand);
	RegServerCmd("codepatch_unpatch", CodePatchUnpatchCommand);
}

public void OnPluginEnd()
{
	int size = hPatchNames.Length;

	char name[MAX_PATCH_NAME_LENGTH + 1];
	
	/*
	 * The reverse loop resolves the errors when unloading the plugin
	*/
	for (int i = size - 1; i != -1; --i) {
		hPatchNames.GetString(i, name, sizeof(name));
		RevertPatch(name);
	}
	
	if (hGameConfig != null) {
		delete hGameConfig;
	}
}

public Action CodePatchListCommand(int args)
{
	char name[MAX_PATCH_NAME_LENGTH + 1];
	char bytes[MAX_PATCH_SIZE];
	char formattedBytes[MAX_PATCH_SIZE * 3];

	int iSize = hPatchNames.Length;

	if (iSize == 0) {
		PrintToServer("No patches applied");
		return;
	}

	for (int i = 0; i < iSize; ++i) {
		int nBytes = GetBytes(hPatchBytes, bytes, i);
		FormatBytes(bytes, nBytes, formattedBytes);
		
		hPatchNames.GetString(i, name, sizeof(name));

		Address addr = hPatchAddresses.Get(i);
		
		PrintToServer("%d. %s\t0x%x: %s", i+1, name, addr, formattedBytes);
	}
}

public Action CodePatchPatchCommand(int args)
{
	if (GetCmdArgs() != 1) {
		PrintToServer("syntax: codepatch_patch <patch_name>");
		return;
	}

	char name[MAX_PATCH_NAME_LENGTH + 1];
	GetCmdArg(1, name, sizeof(name));

	int patchId = FindPatch(name);

	if (patchId != -1) {
		PrintToServer("Patch '%s' is already loaded", name);
		return;
	}

	char key[MAX_PATCH_NAME_LENGTH + 32];
	char value[MAX_VALUE_LENGTH + 1];

	Format(key, sizeof(key), "%s_signature", name);
	if (!GameConfGetKeyValue(hGameConfig, key, value, sizeof(value))) {
		PrintToServer("Could not find key '%s'", key);
		return;
	}

	Address addr = GameConfGetAddress(hGameConfig, value);
	if (!addr) {
		PrintToServer("Could not load signature '%s'", value);
		return;
	}

	Format(key, sizeof(key), "%s_offset", name);
	if (!GameConfGetKeyValue(hGameConfig, key, value, sizeof(value))) {
		PrintToServer("Could not find key '%s'", key);
		return;
	}

	int offset = GameConfGetOffset(hGameConfig, value);
	if (offset == -1) {
		PrintToServer("Could not load offset '%s'", value);
		return;
	}

	Format(key, sizeof(key), "%s_length_%s", name, (bIsWindows) ? "windows" : "linux");
	if (!GameConfGetKeyValue(hGameConfig, key, value, sizeof(value))) {
		PrintToServer("Could not find key '%s'", key);
		return;
	}

	int length = StringToInt(value);

	if (length < 1 || length > MAX_PATCH_SIZE) {
		PrintToServer("Too %s patch bytes for '%s'", (length < 1) ? "few" : "many", name);
		return;
	}

	Format(key, sizeof(key), "%s_bytes_%s", name, (bIsWindows) ? "windows" : "linux");
	
	if (!GameConfGetKeyValue(hGameConfig, key, value, sizeof(value))) {
		PrintToServer("Could not find key '%s'", key);
		return;
	}

	char[] bytes = new char[length];
	
	if (!ParseBytes(value, bytes, length)) {
		PrintToServer("Failed to parse patch bytes for '%s'", name);
		return;
	}

	addr += view_as<Address>(offset);

	ApplyPatch(name, addr, bytes, length);

	char formattedBytes[MAX_PATCH_SIZE * 3];
	FormatBytes(bytes, length, formattedBytes);

	PrintToServer("Applied patch '%s' [ %s] at 0x%x", name, formattedBytes, addr);
}

public Action CodePatchUnpatchCommand(int args)
{
	if (GetCmdArgs() != 1) {
		PrintToServer("syntax: codepatch_unpatch <patch_name>");
		return;
	}

	char name[MAX_PATCH_NAME_LENGTH + 1];
	GetCmdArg(1, name, sizeof(name));

	int patchId = FindPatch(name);

	if (patchId == -1) {
		PrintToServer("Patch '%s' is not loaded", name);
		return;
	}

	RevertPatch(name);

	PrintToServer("Reverted patch '%s'", name);
}

static int GetPackedByte(int cell, int i)
{
	return (cell >> ((3 - i) * 8)) & 0xff;
}

static int SetPackedByte(int cell, int i, int byte)
{
	int mask = 0xff << ((3 - i) * 8);
	return (cell & ~mask) | (byte << ((3 - i) * 8));
}

static int GetBytes(ArrayList array, char[] bytes, int idx)
{
	int cell = array.Get(idx, 0);
	int count = GetPackedByte(cell, 0);
	int j = 0;

	for (int i = 1; i <= count; ++i) {
		if (i % 4 == 0) {
			cell = array.Get(idx, i / 4);
		}
		
		bytes[j++] = GetPackedByte(cell, i % 4);
	}

	return count;
}

static void PushBytes(ArrayList array, char[] bytes, int count)
{
	int nCells = ByteCountToCells(count + 1);
	int[] cells = new int[nCells];

	cells[0] = SetPackedByte(cells[0], 0, count);

	int j = 0;

	for (int i = 1; i <= count; ++i)
	{
		if (i % 4 == 0) {
			++j;
		}
		
		cells[j] = SetPackedByte(cells[j], i % 4, bytes[i - 1]);
	}

	array.PushArray(cells, nCells);
}

static void FormatBytes(const char[] bytes, int nBytes, char[] output)
{
	int j = 0;

	for (int i = 0; i < nBytes; ++i) {
		int hinibble = (bytes[i] >> 4) & 0x0f;
		int lonibble = bytes[i] & 0xf;

		if (hinibble > 9) {
			output[j++] = 'a' + (hinibble - 10);
		} else {
			output[j++] = '0' + hinibble;
		}
		
		if (lonibble > 9) {
			output[j++] = 'a' + (lonibble - 10);
		} else {
			output[j++] = '0' + lonibble;
		}
		
		output[j++] = ' ';
	}

	output[j++] = '\0';
}

static bool ParseBytes(const char[] value, char[] bytes, int count)
{
	int length = strlen(value);

	if (length != count * 4) {
		return false;
	}
	
	char hex[3];
	int j = 0;

	for (int i = 0; i < length; i += 4) {
		if (value[i] != '\\') {
			return false;
		}
		
		if (value[i + 1] != 'x') {
			return false;
		}
		
		hex[0] = value[i + 2];
		hex[1] = value[i + 3];
		hex[2] = 0;

		bytes[j++] = StringToInt(hex, 16);
	}

	return true;
}

static void WriteBytesToMemory(Address addr, const char[] bytes, int count)
{
	for (int i = 0; i < count; ++i) {
		StoreToAddress(addr + view_as<Address>(i), bytes[i] & 0xff, NumberType_Int8);
	}
}

static void ReadBytesFromMemory(Address addr, char[] bytes, int count)
{
	for (int i = 0; i < count; ++i) {
		bytes[i] = LoadFromAddress(addr + view_as<Address>(i), NumberType_Int8);
	}
}

static int FindPatch(const char[] name)
{
	char iterName[MAX_PATCH_NAME_LENGTH];

	int size = hPatchNames.Length;

	for (int i = 0; i < size; ++i) {
		hPatchNames.GetString(i, iterName, sizeof(iterName));
		
		if (StrEqual(name, iterName)) {
			return i;
		}
	}

	return -1;
}

static void ApplyPatch(const char[] name, Address addr, const char[] bytes, int length)
{
	char[] oldBytes = new char[length];

	ReadBytesFromMemory(addr, oldBytes, length);
	WriteBytesToMemory(addr, bytes, length);
	
	hPatchNames.PushString(name);
	hPatchAddresses.Push(addr);

	PushBytes(hPatchBytes, oldBytes, length);

	Call_StartForward(hPatchAppliedForward);
	Call_PushString(name);
	Call_Finish();
}

static bool RevertPatch(const char[] name)
{
	int patchId = FindPatch(name);

	if (patchId == -1) {
		return false;
	}
	
	char bytes[MAX_PATCH_SIZE];
	int count = GetBytes(hPatchBytes, bytes, patchId);

	Address addr = hPatchAddresses.Get(patchId);
	
	WriteBytesToMemory(addr, bytes, count);
	
	hPatchNames.Erase(patchId);
	hPatchAddresses.Erase(patchId);
	hPatchBytes.Erase(patchId);
	
	return true;
}

/* Natives */
public int IsPatchApplied(Handle plugin, int numParams)
{
	int length;
	GetNativeStringLength(1, length);

	if (length <= 0) {
		return false;
	}
	
	char[] name = new char[length + 1];
	GetNativeString(1, name, length + 1);

	bool bIsPatchApplied = (FindPatch(name) != -1);

	return bIsPatchApplied;
}

public int GetPatchAddress(Handle plugin, int numParams)
{
	int length;
	GetNativeStringLength(1, length);

	if (length <= 0) {
		return view_as<int>(Address_Null);
	}

	char[] name = new char[length + 1];

	GetNativeString(1, name, length + 1);

	int patchId = FindPatch(name);

	if (patchId == -1) {
		return view_as<int>(Address_Null);
	}

	return hPatchAddresses.Get(patchId);
}

public int IsPlatformWindows(Handle plugin, int numParams)
{
	return bIsWindows;
}
