#if defined _readyup_native_included
 #endinput
#endif
#define _readyup_native_included

#include "footer.inc" // MAX_FOOTER_LEN
//#include "player.inc" // compiled in main script, whatever

any Native_AddStringToReadyFooter(Handle plugin, int numParams)
{
	if (inReadyUp)
	{
		char buffer[MAX_FOOTER_LEN];
		GetNativeString(1, buffer, sizeof(buffer));
		return nativeFooter.Add(buffer);
	}
	return -1;
}

any Native_EditFooterStringAtIndex(Handle plugin, int numParams)
{
	if (inReadyUp)
	{
		char buffer[MAX_FOOTER_LEN];
		GetNativeString(2, buffer, sizeof(buffer));
		int index = GetNativeCell(1);
		return nativeFooter.Edit(index, buffer);
	}
	return false;
}

any Native_FindIndexOfFooterString(Handle plugin, int numParams)
{
	if (inReadyUp)
	{
		char buffer[MAX_FOOTER_LEN];
		GetNativeString(1, buffer, sizeof(buffer));
		return nativeFooter.Find(buffer);
	}
	return -1;
}

any Native_GetFooterStringAtIndex(Handle plugin, int numParams)
{
	if (inReadyUp)
	{
		int index = GetNativeCell(1), maxlen = GetNativeCell(3);
		SetNativeString(2, nativeFooter.Get(index), maxlen, true);
		return true;
	}

	return false;
}

any Native_IsInReady(Handle plugin, int numParams)
{
	return inReadyUp;
}

any Native_ToggleReadyPanel(Handle plugin, int numParams)
{
	if (inReadyUp)
	{
		// TODO: Inform the client(s) that panel is supressed?
		bool hide = !GetNativeCell(1);
		
		int client = GetNativeCell(2);
		if (client && IsClientInGame(client))
		{
			return SetPlayerHiddenPanel(client, hide);
		}
		else
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && !IsFakeClient(i))
				{
					SetPlayerHiddenPanel(i, hide);
				}
			}
			return true;
		}
	}
	return false;
}