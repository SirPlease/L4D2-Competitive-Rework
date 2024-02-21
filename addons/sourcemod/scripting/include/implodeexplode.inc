/**
 * vim: set ts=4 :
 * =============================================================================
 * Implode/Explode functions for ArrayLists and StringMaps
 * Allow you to implode/explode strings directly to ADT functions
 *
 * Implode/Explode (C)2016 Powerlord (Ross Bemrose).  All rights reserved.
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 * Version: $Id$
 */
#if defined _implodeexplode_included_
  #endinput
#endif
#define _implodeexplode_included_

enum ImplodePart
{
	ImplodePart_Key,
	ImplodePart_Value,
	ImplodePart_Both,
}

/**
 * Breaks a string into pieces and stores each piece into an ArrayList.
 *
 * @param text				The string to split.
 * @param split				The string to use as a split delimiter.
 * @param buffers			An ArrayList of strings.
 * @param maxStringLength	Maximum length of each string buffer.
 * @return					Number of strings retrieved.
 */
stock int ExplodeStringToArrayList(const char[] text, const char[] split, ArrayList buffers, int maxStringLength)
{
	int reloc_idx, idx, total;
	
	if (buffers == null || !split[0])
	{
		return 0;
	}
	
	char[] item = new char[maxStringLength];
	while ((idx = SplitString(text[reloc_idx], split, item, maxStringLength)) != -1)
	{
		reloc_idx += idx;
		++total;
		buffers.PushString(item);
	}
	++total;
	buffers.PushString(text[reloc_idx]);
	
	return buffers.Length;
}

/**
 * Get the size of a string needed to store all the keys, values, or both of a StringMap
 *
 * @param strings					An ArrayList of strings.
 * @param joinLength				The length of the join string to insert between each string.
 * @param valueMaxLength			Maximum length for value strings, defaults to PLATFORM_MAX_PATH. Used temporarily.
 * @return							Length this StringMap would take to be represented
 */
stock int GetArrayListImplodeSize(ArrayList strings, int joinLength, int valueMaxLength=PLATFORM_MAX_PATH)
{
	if (strings == null)
	{
		ThrowError("ArrayList is not initialized.");
	}

	int numStrings = 0;
	int size = 0;
	
	numStrings = strings.Length;

	for (int i=0; i<numStrings; i++)
	{
		char[] item = new char[valueMaxLength];
		strings.GetString(i, item, valueMaxLength);
		size += strlen(item);

		if (i != numStrings-1)
		{
			size += joinLength;
		}
	}
	// for string terminator
	size += 1;
	
	return size;
}

/**
 * Joins an ArrayList of strings into one string, with a "join" string inserted in
 * between each given string.  This function complements ExplodeStringToArrayList.
 *
 * @param strings		An ArrayList of strings.
 * @param join			The join string to insert between each string.
 * @param buffer		Output buffer to write the joined string to.
 * @param maxLength		Maximum length of the output buffer.
 * @return				Number of bytes written to the output buffer.
 */
stock int ImplodeArrayListStrings(ArrayList strings, const char[] join, char[] buffer, int maxLength)
{
	int total, length, part_length;
	int join_length = strlen(join);
	int numStrings;
	
	if (strings == null)
	{
		ThrowError("ArrayList is not initialized.");
	}

	numStrings = strings.Length;

	for (int i=0; i<numStrings; i++)
	{
		char[] item = new char[maxLength - total];
		strings.GetString(i, item, maxLength - total);
		length = strcopy(buffer[total], maxLength - total, item);
		total += length;
		if (length < part_length)
		{
			break;
		}
		if (i != numStrings - 1)
		{
			length = strcopy(buffer[total], maxLength-total, join);
			total += length;
			if (length < join_length)
			{
				break;
			}
		}
	}
	return total;
}

/**
 * Breaks a string into pieces and stores each piece into a StringMap.
 * You must specify which part of the StringMap you're expecting.
 *
 * @param text				The string to split.
 * @param split				The string to use as a split delimiter.
 * @param buffers			A StringMap of strings.
 * @param maxStringLength	Maximum length of each string buffer.
 * @param part				Which part you're expecting. ImplodePart_Key and ImplodePart_Key
 *							are treated identically and use the same value for both.
 * @param keyValueSeparator	Required for ImplodePart_Both, keys and values are separated with it.
 * @return					Number of strings retrieved.
 */
stock int ExplodeStringToStringMap(const char[] text, const char[] split, StringMap buffers, int maxStringLength, ImplodePart part, const char[] keyValueSeparator="")
{
	int reloc_idx, idx, total;
	
	if (buffers == null || !split[0])
	{
		return 0;
	}
	
	if (part == ImplodePart_Both && !keyValueSeparator[0])
	{
		ThrowError("keyValueSeparator must be specified if using both parts");
	}
	
	if (buffers == null)
	{
		buffers = new StringMap();
	}
	
	char[] item = new char[maxStringLength];
	while ((idx = SplitString(text[reloc_idx], split, item, maxStringLength)) > -1)
	{
		reloc_idx += idx;
		++total;
		AssignExplodeStringMap(buffers, item, maxStringLength, part, keyValueSeparator);
	}
	
	++total;
	AssignExplodeStringMap(buffers, text[reloc_idx], maxStringLength, part, keyValueSeparator);
	return total;
}

/**
 * An internal function used for ExplodeStringToStringMap
 */
stock static void AssignExplodeStringMap(StringMap buffers, const char[] item, int maxStringLength, ImplodePart part, const char[] keyValueSeparator)
{
	switch (part)
	{
		case ImplodePart_Key, ImplodePart_Value:
		{
			buffers.SetString(item, item);
		}
		
		case ImplodePart_Both:
		{
			char[][] inner = new char[2][maxStringLength];
			ExplodeString(item, keyValueSeparator, inner, 2, maxStringLength);
			buffers.SetString(inner[0], inner[1]);
		}
	}
}

/**
 * Get the size of a string needed to store all the keys, values, or both of a StringMap
 *
 * @param strings					A StringMap of strings.
 * @param joinLength				The length of the join string to insert between each string.
 * @param part						Which part you want to turn into a list (keys, values, or both)
 * @param keyValueSeparatorLength	Required for ImplodePart_Both, keys and values are separated with it.
 * @param valueMaxLength			Maximum length for value strings, defaults to PLATFORM_MAX_PATH. Used temporarily for non ImplodePart_Key implodes.
 * @return							Length this StringMap would take to be represented
 */
stock int GetStringMapImplodeSize(StringMap strings, int joinLength, ImplodePart part, int keyValueSeparatorLength=0, int valueMaxLength=PLATFORM_MAX_PATH)
{
	if (strings == null)
	{
		ThrowError("StringMap is not initialized.");
	}
	
	int numStrings = 0;
	int size = 0;
	
	numStrings = strings.Size;

	StringMapSnapshot snapshot = strings.Snapshot();
	
	for (int i=0; i<numStrings; i++)
	{
		int len = snapshot.KeyBufferSize(i);
		
		if (part != ImplodePart_Value)
		{
			// subtract 1 for the nul terminator
			size += len-1;
		}
		
		if (part == ImplodePart_Both)
		{
			size += keyValueSeparatorLength;
		}

		if (part != ImplodePart_Key)
		{
			char[] key = new char[len];
			snapshot.GetKey(i, key, len);
			
			char[] value = new char[valueMaxLength];
			strings.GetString(key, value, valueMaxLength);
			size += strlen(value);
		}

		if (i != numStrings-1)
		{
			size += joinLength;
		}
	}
	// for string terminator
	size += 1;
	
	delete snapshot;
	
	return size;
}

/**
 * Joins a StringMap of strings into one string, with a "join" string inserted in
 * between each given string.  This function complements ExplodeStringToStringMap.
 *
 * @param strings			A StringMap of strings.
 * @param join				The join string to insert between each string.
 * @param buffer			Output buffer to write the joined string to.
 * @param maxLength			Maximum length of the output buffer.
 * @param part				Which part you want to turn into a list (keys, values, or both)
 * @param keyValueSeparator	Required for ImplodePart_Both, keys and values are separated with it.
 * @return					Number of bytes written to the output buffer.
 */
stock int ImplodeStringMapToString(StringMap strings, const char[] join, char[] buffer, int maxLength, ImplodePart part, const char[] keyValueSeparator="")
{
	int total, length, part_length;
	int join_length = strlen(join);
	int numStrings;
	
	if (strings == null)
	{
		ThrowError("StringMap is not initialized.");
	}
	
	if (part == ImplodePart_Both && !keyValueSeparator[0])
	{
		ThrowError("keyValueSeparator must be specified if using both parts");
	}
	
	numStrings = strings.Size;
	StringMapSnapshot snapshot = strings.Snapshot();
	
	for (int i=0; i<numStrings; i++)
	{
		int len = snapshot.KeyBufferSize(i);
		char[] key = new char[len];
		snapshot.GetKey(i, key, len);

		if (part != ImplodePart_Value)
		{
			length = strcopy(buffer[total], maxLength-total, key);
			total += length;
		}
			
		if (part == ImplodePart_Both)
		{
			length = strcopy(buffer[total], maxLength-total, keyValueSeparator);
			total += length;
		}
		
		if (part != ImplodePart_Key)
		{
			char[] value = new char[maxLength];
			strings.GetString(key, value, maxLength);
			length = strcopy(buffer[total], maxLength-total, value);
			total += length;
		}
		
		if (length < part_length)
		{
			break;
		}
		
		if (i != numStrings-1)
		{
			length = strcopy(buffer[total], maxLength-total, join);
			total += length;
			
			if (length < join_length)
			{
				break;
			}
		}
	}
	
	delete snapshot;
	
	return total;
}
