/*
    SourceMod Anti-Cheat
    Copyright (C) 2011-2016 SMAC Development Team
    Copyright (C) 2007-2011 CodingDirect LLC
	
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#if defined _smac_cvars_included
  #endinput
#endif
#define _smac_cvars_included

#define MAX_CVAR_NAME_LEN PLATFORM_MAX_PATH
#define MAX_CVAR_VALUE_LEN PLATFORM_MAX_PATH

#define Cvar_Order "1"
#define Cvar_Name "2"
#define Cvar_CompType "3"
#define Cvar_Action "4"
#define Cvar_Value "5"
#define Cvar_Value2 "6"
#define Cvar_ReplicatedTime "7"

enum CvarOrder {
    Order_First = 0,
    Order_Last,
    Order_MAX
}

enum CvarComp {
    Comp_Invalid = -1,
    Comp_Equal = 0,
    Comp_StrEqual,
    Comp_Replicated,
    Comp_Greater,
    Comp_Less,
    Comp_Between,
    Comp_Outside,
    Comp_NonExist
}

enum CvarAction {
    Action_Invalid = -1,
    Action_Warn = 0,
    Action_Mute,
    Action_Kick,
    Action_Ban
}

stock bool IsValidConVarName(const char[] name)
{
    if (name[0] == '\0')
    {
        return false;
    }

    int length = strlen(name);

    for (int i = 0; i < length; i++)
    {
        if (!IsValidConVarChar(name[i]))
        {
            return false;
        }
    }

    return true;
}

// Useful for older engines (original, Dark Messiah, and Episode 1, etc) which do not automatically replicate.
stock void ReplicateToAll(Handle convar, const char[] value)
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i))
        {
            SendConVarValue(i, convar, value);
        }
    }
}

stock void SetTimer(Handle &hTimer, Handle hNewTimer = INVALID_HANDLE)
{
    Handle hTemp = hTimer;
    hTimer = hNewTimer;

    if (hTemp != INVALID_HANDLE)
    {
        CloseHandle(hTemp);
    }
}

stock void GetQueryResultString(ConVarQueryResult CResult, char[] sResult, int iSize)
{
    switch (CResult)
    {
        case ConVarQuery_Okay:
        {
            strcopy(sResult, iSize, "Okay");
        }
        case ConVarQuery_NotFound:
        {
            strcopy(sResult, iSize, "Not Found");
        }
        case ConVarQuery_NotValid:
        {
            strcopy(sResult, iSize, "Not Valid");
        }
        case ConVarQuery_Protected:
        {
            strcopy(sResult, iSize, "Protected");
        }
        default:
        {
            FormatEx(sResult, iSize, "Unknown (%d)", CResult);
        }
    }
}

stock CvarComp GetCompTypeInt(const char[] sCompType)
{
    if (StrEqual(sCompType, "equal"))
    {
        return Comp_Equal;
    }
    if (StrEqual(sCompType, "strequal"))
    {
        return Comp_StrEqual;
    }
    if (StrEqual(sCompType, "replicated"))
    {
        return Comp_Replicated;
    }
    if (StrEqual(sCompType, "greater"))
    {
        return Comp_Greater;
    }
    if (StrEqual(sCompType, "less"))
    {
        return Comp_Less;
    }
    if (StrEqual(sCompType, "between"))
    {
        return Comp_Between;
    }
    if (StrEqual(sCompType, "outside"))
    {
        return Comp_Outside;
    }
    if (StrEqual(sCompType, "nonexist"))
    {
        return Comp_NonExist;
    }

    return Comp_Invalid;
}

stock void GetCompTypeString(CvarComp CCompType, char[] sCompType,int iSize)
{
    switch (CCompType)
    {
        case Comp_Equal:
        {
            strcopy(sCompType, iSize, "equal");
        }
        case Comp_StrEqual:
        {
            strcopy(sCompType, iSize, "strequal");
        }
        case Comp_Replicated:
        {
            strcopy(sCompType, iSize, "replicated");
        }
        case Comp_Greater:
        {
            strcopy(sCompType, iSize, "greater");
        }
        case Comp_Less:
        {
            strcopy(sCompType, iSize, "less");
        }
        case Comp_Between:
        {
            strcopy(sCompType, iSize, "between");
        }
        case Comp_Outside:
        {
            strcopy(sCompType, iSize, "outside");
        }
        case Comp_NonExist:
        {
            strcopy(sCompType, iSize, "nonexist");
        }
        default:
        {
            strcopy(sCompType, iSize, "");
        }
    }
}

stock CvarAction GetCActionInt(const char[] sAction)
{
    if (StrEqual(sAction, "warn"))
    {
        return Action_Warn;
    }
    if (StrEqual(sAction, "mute"))
    {
        return Action_Mute;
    }
    if (StrEqual(sAction, "kick"))
    {
        return Action_Kick;
    }
    if (StrEqual(sAction, "ban"))
    {
        return Action_Ban;
    }
    return Action_Invalid;
}

stock void GetCActionString(CvarAction CAction, char[] sAction,int iSize)
{
    switch (CCompType)
    {
        case Action_Warn:
        {
            strcopy(sAction, iSize, "warn");
        }
        case Action_Mute:
        {
            strcopy(sAction, iSize, "mute");
        }
        case Action_Kick:
        {
            strcopy(sAction, iSize, "kick");
        }
        case Action_Ban:
        {
            strcopy(sAction, iSize, "ban");
        }
        default:
        {
            strcopy(sAction, iSize, "");
        }
    }
}