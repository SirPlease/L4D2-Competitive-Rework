#pragma semicolon 1
#pragma newdecls required

#define VERSION "0.2"

#include <sourcemod>
#include <sdktools>

Handle
	g_hSDKGetName,
	g_hSDKSetName,
	g_hSDKGetDataType,
	g_hSDKGetString,
	g_hSDKSetString,
	g_hSDKSetStringValue,
	g_hSDKGetInt,
	g_hSDKSetInt,
	g_hSDKGetFloat,
	g_hSDKSetFloat,
	g_hSDKGetPtr,
	g_hSDKSetPtr,
	g_hSDKFindKey,
	g_hSDKGetFirstSubKey,
	g_hSDKGetNextKey,
	g_hSDKGetFirstTrueSubKey,
	g_hSDKGetNextTrueSubKey,
	g_hSDKGetFirstValue,
	g_hSDKGetNextValue,
	g_hSDKSaveToFile;

Address
	g_pFileSystem;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() != Engine_Left4Dead2) 
		LogError("Plugin only supports L4D2");

	CreateNative("SourceKeyValues.IsNull", Native_IsNull);
	CreateNative("SourceKeyValues.GetName", Native_GetName);
	CreateNative("SourceKeyValues.SetName", Native_SetName);
	CreateNative("SourceKeyValues.GetDataType", Native_GetDataType);
	CreateNative("SourceKeyValues.GetString", Native_GetString);
	CreateNative("SourceKeyValues.SetString", Native_SetString);
	CreateNative("SourceKeyValues.SetStringValue", Native_SetStringValue);
	CreateNative("SourceKeyValues.GetInt", Native_GetInt);
	CreateNative("SourceKeyValues.SetInt", Native_SetInt);
	CreateNative("SourceKeyValues.GetFloat", Native_GetFloat);
	CreateNative("SourceKeyValues.SetFloat", Native_SetFloat);
	CreateNative("SourceKeyValues.GetPtr", Native_GetPtr);
	CreateNative("SourceKeyValues.SetPtr", Native_SetPtr);
	CreateNative("SourceKeyValues.FindKey", Native_FindKey);
	CreateNative("SourceKeyValues.GetFirstSubKey", Native_GetFirstSubKey);
	CreateNative("SourceKeyValues.GetNextKey", Native_GetNextKey);
	CreateNative("SourceKeyValues.GetFirstTrueSubKey", Native_GetFirstTrueSubKey);
	CreateNative("SourceKeyValues.GetNextTrueSubKey", Native_GetNextTrueSubKey);
	CreateNative("SourceKeyValues.GetFirstValue", Native_GetFirstValue);
	CreateNative("SourceKeyValues.GetNextValue", Native_GetNextValue);
	CreateNative("SourceKeyValues.SaveToFile", Native_SaveToFile);

	RegPluginLibrary("l4d2_source_keyvalues");

	return APLRes_Success;
}

public Plugin myinfo =
{
	name = "L4D2 Source KeyValues",
	author = "fdxx",
	description = "Call the game's own KeyValues function",
	version = VERSION,
	url = "https://github.com/fdxx/l4d2_source_keyvalues"
}

public void OnPluginStart()
{
	Init();
	CreateConVar("l4d2_source_keyvalues_version", VERSION, "version", FCVAR_NONE | FCVAR_DONTRECORD);
}

// public native bool IsNull();
any Native_IsNull(Handle plugin, int numParams)
{
	return view_as<Address>(GetNativeCell(1)) == Address_Null;
}

// public native void GetName(char[] name, int maxlength);
any Native_GetName(Handle plugin, int numParams)
{
	int maxlength = GetNativeCell(3);
	char[] name = new char[maxlength];
	SDKCall(g_hSDKGetName, GetNativeCell(1), name, maxlength);
	SetNativeString(2, name, maxlength);
	return 0;
}

// public native void SetName(const char[] setName);
any Native_SetName(Handle plugin, int numParams)
{
	int maxlength;
	GetNativeStringLength(2, maxlength);
	maxlength += 1;
	char[] setName = new char[maxlength];
	GetNativeString(2, setName, maxlength);
	SDKCall(g_hSDKSetName, GetNativeCell(1), setName);
	return 0;
}

// public native DataType GetDataType(const char[] key);
any Native_GetDataType(Handle plugin, int numParams)
{
	if (!IsNativeParamNullString(2)) {
		int maxlength;
		GetNativeStringLength(2, maxlength);
		maxlength += 1;
		char[] key = new char[maxlength];
		GetNativeString(2, key, maxlength);
		return SDKCall(g_hSDKGetDataType, GetNativeCell(1), key);
	}
	return SDKCall(g_hSDKGetDataType, GetNativeCell(1), NULL_STRING);
}

// public native void GetString(const char[] key, char[] value, int maxlength, const char[] defvalue = "");
any Native_GetString(Handle plugin, int numParams)
{
	int keyLength, valueLength, defvalueLength;

	valueLength = GetNativeCell(4);
	char[] value = new char[valueLength];

	GetNativeStringLength(5, defvalueLength);
	defvalueLength += 1;
	char[] defvalue = new char[defvalueLength];
	GetNativeString(5, defvalue, defvalueLength);

	if (!IsNativeParamNullString(2)) {
		GetNativeStringLength(2, keyLength);
		keyLength += 1;
		char[] key = new char[keyLength];
		GetNativeString(2, key, keyLength);
		SDKCall(g_hSDKGetString, GetNativeCell(1), value, valueLength, key, defvalue);
	}
	else
		SDKCall(g_hSDKGetString, GetNativeCell(1), value, valueLength, NULL_STRING, defvalue);
	
	SetNativeString(3, value, valueLength);
	return 0;
}

// public native void SetString(const char[] key, const char[] value);
any Native_SetString(Handle plugin, int numParams)
{
	int keyLength, valueLength;

	GetNativeStringLength(2, keyLength);
	keyLength += 1;
	char[] key = new char[keyLength];
	GetNativeString(2, key, keyLength);

	GetNativeStringLength(3, valueLength);
	valueLength += 1;
	char[] value = new char[valueLength];
	GetNativeString(3, value, valueLength);

	SDKCall(g_hSDKSetString, GetNativeCell(1), key, value);
	return 0;
}

// public native void SetStringValue(const char[] value);
any Native_SetStringValue(Handle plugin, int numParams)
{
	int maxlength;
	GetNativeStringLength(2, maxlength);
	maxlength += 1;
	char[] value = new char[maxlength];
	GetNativeString(2, value, maxlength);
	SDKCall(g_hSDKSetStringValue, GetNativeCell(1), value);
	return 0;
}

// public native int GetInt(const char[] key, int defvalue = 0);
any Native_GetInt(Handle plugin, int numParams)
{
	if (!IsNativeParamNullString(2)) {
		int keyLength;
		GetNativeStringLength(2, keyLength);
		keyLength += 1;
		char[] key = new char[keyLength];
		GetNativeString(2, key, keyLength);
		return SDKCall(g_hSDKGetInt, GetNativeCell(1), key, GetNativeCell(3));
	}
	return SDKCall(g_hSDKGetInt, GetNativeCell(1), NULL_STRING, GetNativeCell(3));
}

// public native void SetInt(const char[] key, int value);
any Native_SetInt(Handle plugin, int numParams)
{
	int keyLength;
	GetNativeStringLength(2, keyLength);
	keyLength += 1;
	char[] key = new char[keyLength];
	GetNativeString(2, key, keyLength);

	SDKCall(g_hSDKSetInt, GetNativeCell(1), key, GetNativeCell(3));
	return 0;
}

// public native float GetFloat(const char[] key, float defvalue = 0.0);
any Native_GetFloat(Handle plugin, int numParams)
{
	if (!IsNativeParamNullString(2)) {
		int keyLength;
		GetNativeStringLength(2, keyLength);
		keyLength += 1;
		char[] key = new char[keyLength];
		GetNativeString(2, key, keyLength);
		return SDKCall(g_hSDKGetFloat, GetNativeCell(1), key, GetNativeCell(3));
	}
	return SDKCall(g_hSDKGetFloat, GetNativeCell(1), NULL_STRING, GetNativeCell(3));
}

// public native void SetFloat(const char[] key, float value);
any Native_SetFloat(Handle plugin, int numParams)
{
	int keyLength;
	GetNativeStringLength(2, keyLength);
	keyLength += 1;
	char[] key = new char[keyLength];
	GetNativeString(2, key, keyLength);

	SDKCall(g_hSDKSetFloat, GetNativeCell(1), key, GetNativeCell(3));
	return 0;
}

// public native Address GetPtr(const char[] key, Address defvalue = Address_Null);
any Native_GetPtr(Handle plugin, int numParams)
{
	if (!IsNativeParamNullString(2)) {
		int keyLength;
		GetNativeStringLength(2, keyLength);
		keyLength += 1;
		char[] key = new char[keyLength];
		GetNativeString(2, key, keyLength);
		return SDKCall(g_hSDKGetPtr, GetNativeCell(1), key, GetNativeCell(3));
	}
	return SDKCall(g_hSDKGetPtr, GetNativeCell(1), NULL_STRING, GetNativeCell(3));
}

// public native void SetPtr(const char[] key, Address value);
any Native_SetPtr(Handle plugin, int numParams)
{
	int keyLength;
	GetNativeStringLength(2, keyLength);
	keyLength += 1;
	char[] key = new char[keyLength];
	GetNativeString(2, key, keyLength);

	SDKCall(g_hSDKSetPtr, GetNativeCell(1), key, GetNativeCell(3));
	return 0;
}

// public native SourceKeyValues FindKey(const char[] key, bool bCreate = false);
any Native_FindKey(Handle plugin, int numParams)
{
	int keyLength;
	GetNativeStringLength(2, keyLength);
	keyLength += 1;
	char[] key = new char[keyLength];
	GetNativeString(2, key, keyLength);

	if (GetNativeCell(1))
		return SDKCall(g_hSDKFindKey, GetNativeCell(1), key, GetNativeCell(3));
	return 0;
}

// public native SourceKeyValues GetFirstSubKey();
any Native_GetFirstSubKey(Handle plugin, int numParams)
{
	if (GetNativeCell(1))
		return SDKCall(g_hSDKGetFirstSubKey, GetNativeCell(1));
	return 0;
}

// public native SourceKeyValues GetNextKey();
any Native_GetNextKey(Handle plugin, int numParams)
{
	if (GetNativeCell(1))
		return SDKCall(g_hSDKGetNextKey, GetNativeCell(1));
	return 0;
}

// public native SourceKeyValues GetFirstTrueSubKey();
any Native_GetFirstTrueSubKey(Handle plugin, int numParams)
{
	if (GetNativeCell(1))
		return SDKCall(g_hSDKGetFirstTrueSubKey, GetNativeCell(1));
	return 0;
}

// public native SourceKeyValues GetNextTrueSubKey();
any Native_GetNextTrueSubKey(Handle plugin, int numParams)
{
	if (GetNativeCell(1))
		return SDKCall(g_hSDKGetNextTrueSubKey, GetNativeCell(1));
	return 0;
}

// public native SourceKeyValues GetFirstValue();
any Native_GetFirstValue(Handle plugin, int numParams)
{
	if (GetNativeCell(1))
		return SDKCall(g_hSDKGetFirstValue, GetNativeCell(1));
	return 0;
}

// public native SourceKeyValues GetNextValue();
any Native_GetNextValue(Handle plugin, int numParams)
{
	if (GetNativeCell(1))
		return SDKCall(g_hSDKGetNextValue, GetNativeCell(1));
	return 0;
}

// public native bool SaveToFile(const char[] file);
any Native_SaveToFile(Handle plugin, int numParams)
{
	int length;
	GetNativeStringLength(2, length);
	length += 1;
	char[] file = new char[length];
	GetNativeString(2, file, length);

	return SDKCall(g_hSDKSaveToFile, GetNativeCell(1), g_pFileSystem, file, NULL_STRING);
}

void Init()
{
	char sBuffer[128];

	strcopy(sBuffer, sizeof sBuffer, "l4d2_source_keyvalues");
	GameData hGameData = new GameData(sBuffer);
	if (hGameData == null)
		SetFailState("Failed to load \"%s.txt\" file", sBuffer);

	// ------- address ------- 
	strcopy(sBuffer, sizeof sBuffer, "fileSystem");
	Address fileSystem = hGameData.GetAddress(sBuffer);
	if (fileSystem == Address_Null)
		SetFailState("Failed to get address: \"%s\"", sBuffer);
	g_pFileSystem = fileSystem + view_as<Address>(4);


	// ------- Prep SDKCall ------- 
	strcopy(sBuffer, sizeof sBuffer, "KeyValues::GetName");
	StartPrepSDKCall(SDKCall_Raw);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, sBuffer))
		SetFailState("Failed to find signature: \"%s\"", sBuffer);
	PrepSDKCall_SetReturnInfo(SDKType_String, SDKPass_Pointer);
	g_hSDKGetName = EndPrepSDKCall();
	if (g_hSDKGetName == null)
		SetFailState("Failed to create SDKCall: \"%s\"", sBuffer);

	strcopy(sBuffer, sizeof sBuffer, "KeyValues::SetName");
	StartPrepSDKCall(SDKCall_Raw);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, sBuffer))
		SetFailState("Failed to find signature: \"%s\"", sBuffer);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	g_hSDKSetName = EndPrepSDKCall();
	if (g_hSDKSetName == null)
		SetFailState("Failed to create SDKCall: \"%s\"", sBuffer);

	strcopy(sBuffer, sizeof sBuffer, "KeyValues::GetDataType");
	StartPrepSDKCall(SDKCall_Raw);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, sBuffer))
		SetFailState("Failed to find signature: \"%s\"", sBuffer);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_hSDKGetDataType = EndPrepSDKCall();
	if (g_hSDKGetDataType == null)
		SetFailState("Failed to create SDKCall: \"%s\"", sBuffer);

	strcopy(sBuffer, sizeof sBuffer, "KeyValues::GetString");
	StartPrepSDKCall(SDKCall_Raw);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, sBuffer))
		SetFailState("Failed to find signature: \"%s\"", sBuffer);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_String, SDKPass_Pointer);
	g_hSDKGetString = EndPrepSDKCall();
	if (g_hSDKGetString == null)
		SetFailState("Failed to create SDKCall: \"%s\"", sBuffer);

	strcopy(sBuffer, sizeof sBuffer, "KeyValues::SetString");
	StartPrepSDKCall(SDKCall_Raw);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, sBuffer))
		SetFailState("Failed to find signature: \"%s\"", sBuffer);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	g_hSDKSetString = EndPrepSDKCall();
	if (g_hSDKSetString == null)
		SetFailState("Failed to create SDKCall: \"%s\"", sBuffer);

	strcopy(sBuffer, sizeof sBuffer, "KeyValues::SetStringValue");
	StartPrepSDKCall(SDKCall_Raw);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, sBuffer))
		SetFailState("Failed to find signature: \"%s\"", sBuffer);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	g_hSDKSetStringValue = EndPrepSDKCall();
	if (g_hSDKSetStringValue == null)
		SetFailState("Failed to create SDKCall: \"%s\"", sBuffer);

	strcopy(sBuffer, sizeof sBuffer, "KeyValues::GetInt");
	StartPrepSDKCall(SDKCall_Raw);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, sBuffer))
		SetFailState("Failed to find signature: \"%s\"", sBuffer);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_hSDKGetInt = EndPrepSDKCall();
	if (g_hSDKGetInt == null)
		SetFailState("Failed to create SDKCall: \"%s\"", sBuffer);

	strcopy(sBuffer, sizeof sBuffer, "KeyValues::SetInt");
	StartPrepSDKCall(SDKCall_Raw);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, sBuffer))
		SetFailState("Failed to find signature: \"%s\"", sBuffer);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	g_hSDKSetInt = EndPrepSDKCall();
	if (g_hSDKSetInt == null)
		SetFailState("Failed to create SDKCall: \"%s\"", sBuffer);

	strcopy(sBuffer, sizeof sBuffer, "KeyValues::GetFloat");
	StartPrepSDKCall(SDKCall_Raw);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, sBuffer))
		SetFailState("Failed to find signature: \"%s\"", sBuffer);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_Float, SDKPass_Plain);
	g_hSDKGetFloat = EndPrepSDKCall();
	if (g_hSDKGetFloat == null)
		SetFailState("Failed to create SDKCall: \"%s\"", sBuffer);

	strcopy(sBuffer, sizeof sBuffer, "KeyValues::SetFloat");
	StartPrepSDKCall(SDKCall_Raw);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, sBuffer))
		SetFailState("Failed to find signature: \"%s\"", sBuffer);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	g_hSDKSetFloat = EndPrepSDKCall();
	if (g_hSDKSetFloat == null)
		SetFailState("Failed to create SDKCall: \"%s\"", sBuffer); 

	strcopy(sBuffer, sizeof sBuffer, "KeyValues::GetPtr");
	StartPrepSDKCall(SDKCall_Raw);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, sBuffer))
		SetFailState("Failed to find signature: \"%s\"", sBuffer);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_hSDKGetPtr = EndPrepSDKCall();
	if (g_hSDKGetPtr == null)
		SetFailState("Failed to create SDKCall: \"%s\"", sBuffer);

	strcopy(sBuffer, sizeof sBuffer, "KeyValues::SetPtr");
	StartPrepSDKCall(SDKCall_Raw);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, sBuffer))
		SetFailState("Failed to find signature: \"%s\"", sBuffer);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	g_hSDKSetPtr = EndPrepSDKCall();
	if (g_hSDKSetPtr == null)
		SetFailState("Failed to create SDKCall: \"%s\"", sBuffer);

	strcopy(sBuffer, sizeof sBuffer, "KeyValues::FindKey");
	StartPrepSDKCall(SDKCall_Raw);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, sBuffer))
		SetFailState("Failed to find signature: \"%s\"", sBuffer);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_hSDKFindKey = EndPrepSDKCall();
	if (g_hSDKFindKey == null)
		SetFailState("Failed to create SDKCall: \"%s\"", sBuffer);

	strcopy(sBuffer, sizeof sBuffer, "KeyValues::GetFirstSubKey");
	StartPrepSDKCall(SDKCall_Raw);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, sBuffer))
		SetFailState("Failed to find signature: \"%s\"", sBuffer);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_hSDKGetFirstSubKey = EndPrepSDKCall();
	if (g_hSDKGetFirstSubKey == null)
		SetFailState("Failed to create SDKCall: \"%s\"", sBuffer);

	strcopy(sBuffer, sizeof sBuffer, "KeyValues::GetNextKey");
	StartPrepSDKCall(SDKCall_Raw);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, sBuffer))
		SetFailState("Failed to find signature: \"%s\"", sBuffer);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_hSDKGetNextKey = EndPrepSDKCall();
	if (g_hSDKGetNextKey == null)
		SetFailState("Failed to create SDKCall: \"%s\"", sBuffer);

	strcopy(sBuffer, sizeof sBuffer, "KeyValues::GetFirstTrueSubKey");
	StartPrepSDKCall(SDKCall_Raw);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, sBuffer))
		SetFailState("Failed to find signature: \"%s\"", sBuffer);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_hSDKGetFirstTrueSubKey = EndPrepSDKCall();
	if (g_hSDKGetFirstTrueSubKey == null)
		SetFailState("Failed to create SDKCall: \"%s\"", sBuffer);

	strcopy(sBuffer, sizeof sBuffer, "KeyValues::GetNextTrueSubKey");
	StartPrepSDKCall(SDKCall_Raw);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, sBuffer))
		SetFailState("Failed to find signature: \"%s\"", sBuffer);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_hSDKGetNextTrueSubKey = EndPrepSDKCall();
	if (g_hSDKGetNextTrueSubKey == null)
		SetFailState("Failed to create SDKCall: \"%s\"", sBuffer);

	strcopy(sBuffer, sizeof sBuffer, "KeyValues::GetFirstValue");
	StartPrepSDKCall(SDKCall_Raw);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, sBuffer))
		SetFailState("Failed to find signature: \"%s\"", sBuffer);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_hSDKGetFirstValue = EndPrepSDKCall();
	if (g_hSDKGetFirstValue == null)
		SetFailState("Failed to create SDKCall: \"%s\"", sBuffer);

	strcopy(sBuffer, sizeof sBuffer, "KeyValues::GetNextValue");
	StartPrepSDKCall(SDKCall_Raw);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, sBuffer))
		SetFailState("Failed to find signature: \"%s\"", sBuffer);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_hSDKGetNextValue = EndPrepSDKCall();
	if (g_hSDKGetNextValue == null)
		SetFailState("Failed to create SDKCall: \"%s\"", sBuffer);

	strcopy(sBuffer, sizeof sBuffer, "KeyValues::SaveToFile");
	StartPrepSDKCall(SDKCall_Raw);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, sBuffer))
		SetFailState("Failed to find signature: \"%s\"", sBuffer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
	g_hSDKSaveToFile = EndPrepSDKCall();
	if (g_hSDKSaveToFile == null)
		SetFailState("Failed to create SDKCall: \"%s\"", sBuffer);

	delete hGameData;
}

