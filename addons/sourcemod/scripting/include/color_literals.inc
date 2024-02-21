/**
 * Constant colors include.
 * A lightweight replacement for other colors includes.
 * 
 * Converts colors to color codes at compile time, instead of adding overhead with a color
 * mapping at runtime.
 * 
 * To use these colors, use the string literal concatenation operator (...) to insert them in
 * your chat messages.  No additional process or checks are performed at run-time, so make sure
 * your target game(s) are compatible with these constants.
 * 
 * Should support the same games that More Colors supports:
 * https://forums.alliedmods.net/showthread.php?t=185016
 */

#if defined __stocksoup_color_literals_included
	#endinput
#endif

#define __stocksoup_color_literals_included

#define COLOR_DEFAULT              "\x01"
#define COLOR_PLAYER               "\x02"
#define COLOR_TEAM                 "\x03"
#define COLOR_LOCATION             "\x04"

#define COLOR_ALICEBLUE            "\x07F0F8FF"
#define COLOR_ANTIQUEWHITE         "\x07FAEBD7"
#define COLOR_AQUA                 "\x0700FFFF"
#define COLOR_AQUAMARINE           "\x077FFFD4"
#define COLOR_AZURE                "\x07007FFF"
#define COLOR_BEIGE                "\x07F5F5DC"
#define COLOR_BISQUE               "\x07FFE4C4"
#define COLOR_BLACK                "\x07000000"
#define COLOR_BLANCHEDALMOND       "\x07FFEBCD"
#define COLOR_BLUEVIOLET           "\x078A2BE2"
#define COLOR_BROWN                "\x07A52A2A"
#define COLOR_BURLYWOOD            "\x07DEB887"
#define COLOR_CADETBLUE            "\x075F9EA0"
#define COLOR_CHARTREUSE           "\x077FFF00"
#define COLOR_CHOCOLATE            "\x07D2691E"
#define COLOR_CORAL                "\x07FF7F50"
#define COLOR_CORNFLOWERBLUE       "\x076495ED"
#define COLOR_CORNSILK             "\x07FFF8DC"
#define COLOR_CRIMSON              "\x07DC143C"
#define COLOR_CYAN                 "\x0700FFFF"
#define COLOR_DARKBLUE             "\x0700008B"
#define COLOR_DARKCYAN             "\x07008B8B"
#define COLOR_DARKGOLDENROD        "\x07B8860B"
#define COLOR_DARKGRAY             "\x07A9A9A9"
#define COLOR_DARKGREY             "\x07A9A9A9"
#define COLOR_DARKGREEN            "\x07006400"
#define COLOR_DARKKHAKI            "\x07BDB76B"
#define COLOR_DARKMAGENTA          "\x078B008B"
#define COLOR_DARKOLIVEGREEN       "\x07556B2F"
#define COLOR_DARKORANGE           "\x07FF8C00"
#define COLOR_DARKORCHID           "\x079932CC"
#define COLOR_DARKRED              "\x078B0000"
#define COLOR_DARKSALMON           "\x07E9967A"
#define COLOR_DARKSEAGREEN         "\x078FBC8F"
#define COLOR_DARKSLATEBLUE        "\x07483D8B"
#define COLOR_DARKSLATEGRAY        "\x072F4F4F"
#define COLOR_DARKSLATEGREY        "\x072F4F4F"
#define COLOR_DARKTURQUOISE        "\x0700CED1"
#define COLOR_DARKVIOLET           "\x079400D3"
#define COLOR_DEEPPINK             "\x07FF1493"
#define COLOR_DEEPSKYBLUE          "\x0700BFFF"
#define COLOR_DIMGRAY              "\x07696969"
#define COLOR_DIMGREY              "\x07696969"
#define COLOR_DODGERBLUE           "\x071E90FF"
#define COLOR_FIREBRICK            "\x07B22222"
#define COLOR_FLORALWHITE          "\x07FFFAF0"
#define COLOR_FORESTGREEN          "\x07228B22"
#define COLOR_FUCHSIA              "\x07FF00FF"
#define COLOR_FULLBLUE             "\x070000FF"
#define COLOR_FULLRED              "\x07FF0000"
#define COLOR_GAINSBORO            "\x07DCDCDC"
#define COLOR_GHOSTWHITE           "\x07F8F8FF"
#define COLOR_GOLD                 "\x07FFD700"
#define COLOR_GOLDENROD            "\x07DAA520"
#define COLOR_GREY                 "\x07CCCCCC"
#define COLOR_GREEN                "\x073EFF3E"
#define COLOR_GREENYELLOW          "\x07ADFF2F"
#define COLOR_HONEYDEW             "\x07F0FFF0"
#define COLOR_HOTPINK              "\x07FF69B4"
#define COLOR_INDIANRED            "\x07CD5C5C"
#define COLOR_INDIGO               "\x074B0082"
#define COLOR_IVORY                "\x07FFFFF0"
#define COLOR_KHAKI                "\x07F0E68C"
#define COLOR_LAVENDER             "\x07E6E6FA"
#define COLOR_LAVENDERBLUSH        "\x07FFF0F5"
#define COLOR_LAWNGREEN            "\x077CFC00"
#define COLOR_LEMONCHIFFON         "\x07FFFACD"
#define COLOR_LIGHTBLUE            "\x07ADD8E6"
#define COLOR_LIGHTCORAL           "\x07F08080"
#define COLOR_LIGHTCYAN            "\x07E0FFFF"
#define COLOR_LIGHTGOLDENRODYELLOW "\x07FAFAD2"
#define COLOR_LIGHTGRAY            "\x07D3D3D3"
#define COLOR_LIGHTGREY            "\x07D3D3D3"
#define COLOR_LIGHTGREEN           "\x0799FF99"
#define COLOR_LIGHTPINK            "\x07FFB6C1"
#define COLOR_LIGHTSALMON          "\x07FFA07A"
#define COLOR_LIGHTSEAGREEN        "\x0720B2AA"
#define COLOR_LIGHTSKYBLUE         "\x0787CEFA"
#define COLOR_LIGHTSLATEGRAY       "\x07778899"
#define COLOR_LIGHTSLATEGREY       "\x07778899"
#define COLOR_LIGHTSTEELBLUE       "\x07B0C4DE"
#define COLOR_LIGHTYELLOW          "\x07FFFFE0"
#define COLOR_LIME                 "\x0700FF00"
#define COLOR_LIMEGREEN            "\x0732CD32"
#define COLOR_LINEN                "\x07FAF0E6"
#define COLOR_MAGENTA              "\x07FF00FF"
#define COLOR_MAROON               "\x07800000"
#define COLOR_MEDIUMAQUAMARINE     "\x0766CDAA"
#define COLOR_MEDIUMBLUE           "\x070000CD"
#define COLOR_MEDIUMORCHID         "\x07BA55D3"
#define COLOR_MEDIUMPURPLE         "\x079370D8"
#define COLOR_MEDIUMSEAGREEN       "\x073CB371"
#define COLOR_MEDIUMSLATEBLUE      "\x077B68EE"
#define COLOR_MEDIUMSPRINGGREEN    "\x0700FA9A"
#define COLOR_MEDIUMTURQUOISE      "\x0748D1CC"
#define COLOR_MEDIUMVIOLETRED      "\x07C71585"
#define COLOR_MIDNIGHTBLUE         "\x07191970"
#define COLOR_MINTCREAM            "\x07F5FFFA"
#define COLOR_MISTYROSE            "\x07FFE4E1"
#define COLOR_MOCCASIN             "\x07FFE4B5"
#define COLOR_NAVAJOWHITE          "\x07FFDEAD"
#define COLOR_NAVY                 "\x07000080"
#define COLOR_OLDLACE              "\x07FDF5E6"
#define COLOR_OLIVE                "\x079EC34F"
#define COLOR_OLIVEDRAB            "\x076B8E23"
#define COLOR_ORANGE               "\x07FFA500"
#define COLOR_ORANGERED            "\x07FF4500"
#define COLOR_ORCHID               "\x07DA70D6"
#define COLOR_PALEGOLDENROD        "\x07EEE8AA"
#define COLOR_PALEGREEN            "\x0798FB98"
#define COLOR_PALETURQUOISE        "\x07AFEEEE"
#define COLOR_PALEVIOLETRED        "\x07D87093"
#define COLOR_PAPAYAWHIP           "\x07FFEFD5"
#define COLOR_PEACHPUFF            "\x07FFDAB9"
#define COLOR_PERU                 "\x07CD853F"
#define COLOR_PINK                 "\x07FFC0CB"
#define COLOR_PLUM                 "\x07DDA0DD"
#define COLOR_POWDERBLUE           "\x07B0E0E6"
#define COLOR_PURPLE               "\x07800080"
#define COLOR_ROSYBROWN            "\x07BC8F8F"
#define COLOR_ROYALBLUE            "\x074169E1"
#define COLOR_SADDLEBROWN          "\x078B4513"
#define COLOR_SALMON               "\x07FA8072"
#define COLOR_SANDYBROWN           "\x07F4A460"
#define COLOR_SEAGREEN             "\x072E8B57"
#define COLOR_SEASHELL             "\x07FFF5EE"
#define COLOR_SIENNA               "\x07A0522D"
#define COLOR_SILVER               "\x07C0C0C0"
#define COLOR_SKYBLUE              "\x0787CEEB"
#define COLOR_SLATEBLUE            "\x076A5ACD"
#define COLOR_SLATEGRAY            "\x07708090"
#define COLOR_SLATEGREY            "\x07708090"
#define COLOR_SNOW                 "\x07FFFAFA"
#define COLOR_SPRINGGREEN          "\x0700FF7F"
#define COLOR_STEELBLUE            "\x074682B4"
#define COLOR_TAN                  "\x07D2B48C"
#define COLOR_TEAL                 "\x07008080"
#define COLOR_THISTLE              "\x07D8BFD8"
#define COLOR_TOMATO               "\x07FF6347"
#define COLOR_TURQUOISE            "\x0740E0D0"
#define COLOR_VIOLET               "\x07EE82EE"
#define COLOR_WHEAT                "\x07F5DEB3"
#define COLOR_WHITE                "\x07FFFFFF"
#define COLOR_WHITESMOKE           "\x07F5F5F5"
#define COLOR_YELLOW               "\x07FFFF00"
#define COLOR_YELLOWGREEN          "\x079ACD32"

#define COLOR_BLUE                 "\x0799CCFF" // same as BLU/Counter-Terrorist team color
#define COLOR_GRAY                 "\x07CCCCCC" // same as spectator team color
#define COLOR_RED                  "\x07FF4040" // same as RED/Terrorist team color

#define COLOR_ALLIES               "\x074D7942" // same as Allies team in DoD:S
#define COLOR_AXIS                 "\x07FF4040" // same as Axis team in DoD:S

#define COLOR_ANCIENT              "\x07EB4B4B" // same as Ancient item rarity in Dota 2
#define COLOR_ARCANA               "\x07ADE55C" // same as Arcana item rarity in Dota 2
#define COLOR_COMMON               "\x07B0C3D9" // same as Common item rarity in Dota 2
#define COLOR_CORRUPTED            "\x07A32C2E" // same as Corrupted item quality in Dota 2
#define COLOR_EXALTED              "\x07CCCCCD" // same as Exalted item quality in Dota 2
#define COLOR_FROZEN               "\x074983B3" // same as Frozen item quality in Dota 2
#define COLOR_IMMORTAL             "\x07E4AE33" // same as Immortal item rarity in Dota 2
#define COLOR_LEGENDARY            "\x07D32CE6" // same as Legendary item rarity in Dota 2
#define COLOR_MYTHICAL             "\x078847FF" // same as Mythical item rarity in Dota 2
#define COLOR_RARE                 "\x074B69FF" // same as Rare item rarity in Dota 2
#define COLOR_UNCOMMON             "\x07B0C3D9" // same as Uncommon item rarity in Dota 2

#define COLOR_COLLECTORS           "\x07AA0000" // same as Collector's item quality in TF2
#define COLOR_COMMUNITY            "\x0770B04A" // same as Community item quality in TF2
#define COLOR_GENUINE              "\x074D7455" // same as Genuine item quality in TF2
#define COLOR_HAUNTED              "\x0738F3AB" // same as Haunted item quality in TF2
#define COLOR_NORMAL               "\x07B2B2B2" // same as Normal item quality in TF2
#define COLOR_SELFMADE             "\x0770B04A" // same as Self-Made item quality in TF2
#define COLOR_STRANGE              "\x07CF6A32" // same as Strange item quality in TF2
#define COLOR_UNIQUE               "\x07FFD700" // same as Unique item quality in TF2
#define COLOR_UNUSUAL              "\x078650AC" // same as Unusual item quality in TF2
#define COLOR_VALVE                "\x07A50F79" // same as Valve item quality in TF2
#define COLOR_VINTAGE              "\x07476291" // same as Vintage item quality in TF2

/**
 * CS:GO's limited color palette.
 * 
 * https://forums.alliedmods.net/showpost.php?p=2271350&postcount=1047
 * https://i.imgur.com/E3PgWVI.png
 */
#define CSGO_COLOR_GREEN           "\x04"
#define CSGO_COLOR_OLIVE           "\x05"
#define CSGO_COLOR_LIME            "\x06"
#define CSGO_COLOR_LIGHTRED        "\x07"
#define CSGO_COLOR_GRAY            "\x08"
#define CSGO_COLOR_GREY            "\x08"
#define CSGO_COLOR_YELLOW          "\x09"
#define CSGO_COLOR_BLUEGRAY        "\x0A"
#define CSGO_COLOR_BLUEGREY        "\x0A"
#define CSGO_COLOR_LIGHTBLUE       "\x0B"
#define CSGO_COLOR_DARKBLUE        "\x0C"
#define CSGO_COLOR_BLUEGRAY2       "\x0D"
#define CSGO_COLOR_BLUEGREY2       "\x0D"
#define CSGO_COLOR_ORCHID          "\x0E"
#define CSGO_COLOR_SALMON          "\x0F"
#define CSGO_COLOR_ORANGE          "\x10"

#define CHAT_SOURCE_SERVER 0
#define CHAT_SOURCE_SELF -1

/**
 * Prints a colored message.
 * 
 * See: http://www.teamfortress.com/post.php?id=7946
 * 
 * In games that support the full color range, messages can be colorized by using \x07 followed
 * by a hex code in RRGGBB format, or \x08 followed by a hex code in RRGGBBAA format.  You can
 * also use the COLOR_* constants from this include file.
 * 
 * Default colors include \x01-\x04, representing normal, player name color, team color, and
 * location color.
 * 
 * The team color (\x03) is based on a source player's current team.  This function treats the
 * server as the source; use the `PrintColoredChat*Ex` stock functions to have better control
 * over the source.
 * 
 * CS:GO supports other single-byte colors from \x05 to \x10.  You can also use the CSGO_COLOR_*
 * constants from this include file.
 * 
 * This is intended as a replacement to `PrintToChat`, as using that function with color codes
 * outputs the hex values to the client's developer console.
 */
stock void PrintColoredChat(int client, const char[] format, any ...) {
	char messageBuffer[192];
	SetGlobalTransTarget(client);
	VFormat(messageBuffer, sizeof(messageBuffer), format, 3);
	SetGlobalTransTarget(LANG_SERVER);
	
	PrintColoredChatEx(client, CHAT_SOURCE_SERVER, "%s", messageBuffer);
}

/**
 * Prints a colored message to all players.
 */
stock void PrintColoredChatAll(const char[] format, any ...) {
	char messageBuffer[192];
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsClientInGame(i)) {
			continue;
		}
		
		SetGlobalTransTarget(i);
		VFormat(messageBuffer, sizeof(messageBuffer), format, 2);
		
		PrintColoredChatEx(i, CHAT_SOURCE_SERVER, "%s", messageBuffer);
	}
	SetGlobalTransTarget(LANG_SERVER);
}

/**
 * Prints a colored message to all players, with the option of setting a source player.
 * CHAT_SOURCE_SELF treats the client as the source, meaning the team color is that of the
 * source player's.
 */
stock void PrintColoredChatEx(int client, int source = CHAT_SOURCE_SELF, const char[] format,
		any ...) {
	source = source == CHAT_SOURCE_SELF? client : source;
	
	// https://forums.alliedmods.net/showpost.php?p=1909951&postcount=4
	char modifiedFormat[192] = COLOR_DEFAULT, messageBuffer[192];
	
	if (strncmp(format, modifiedFormat, 1) != 0) {
		// prefix doesn't match, prepend with default color
		StrCat(modifiedFormat, sizeof(modifiedFormat), format);
	} else {
		strcopy(modifiedFormat, sizeof(modifiedFormat), format);
	}
	
	SetGlobalTransTarget(client);
	VFormat(messageBuffer, sizeof(messageBuffer), modifiedFormat, 4);
	SetGlobalTransTarget(LANG_SERVER);
	
	Handle buffer = StartMessageOne("SayText2", client, USERMSG_RELIABLE | USERMSG_BLOCKHOOKS);
	switch (GetUserMessageType()) {
		case UM_BitBuf: {
			BfWrite bitbuf = UserMessageToBfWrite(buffer);
			
			bitbuf.WriteByte(source);
			bitbuf.WriteByte(true);
			bitbuf.WriteString(messageBuffer);
		}
		case UM_Protobuf: {
			Protobuf protobuf = UserMessageToProtobuf(buffer);
			
			protobuf.SetBool("chat", true);
			protobuf.SetInt("ent_idx", source);
			
			protobuf.SetString("msg_name", messageBuffer);
			protobuf.AddString("params", "");
			protobuf.AddString("params", "");
			protobuf.AddString("params", "");
			protobuf.AddString("params", "");
		}
	}
	
	EndMessage();
}

/**
 * Prints colored chat to all players, using a specific client as the source.
 * CHAT_SOURCE_SELF treats each client as the message's source.
 */
stock void PrintColoredChatAllEx(int source = CHAT_SOURCE_SELF, const char[] format, any ...) {
	char messageBuffer[192];
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsClientInGame(i)) {
			continue;
		}
		
		SetGlobalTransTarget(i);
		VFormat(messageBuffer, sizeof(messageBuffer), format, 3);
		
		PrintColoredChatEx(i, source, "%s", messageBuffer);
	}
	SetGlobalTransTarget(LANG_SERVER);
}

/**
 * Strips color characters from a message.
 * 
 * If bStripHexCodes is true, \x07 and \x08 will also remove the RGB(A) characters that follow,
 * and \n is treated as a newline (if not stripping hex codes, newline is assumed to be a
 * color as is the case in CS:GO).
 */
stock int StripColorChars(const char[] input, char[] output, int maxlen,
		bool bStripHexCodes = true) {
	char[] outputBuffer = new char[maxlen];
	int i, o, l = strlen(input);
	while (i < l && o < maxlen) {
		bool bIsColorChar = input[i] < 32 && (input[i] != '\n' || !bStripHexCodes);
		
		if (bIsColorChar) {
			if (bStripHexCodes) {
				switch (input[i]) {
					case '\x07': {
						i += 6; // RRGGBB
					}
					case '\x08': {
						i += 8; // RRGGBBAA
					}
				}
			}
			i++;
		}
		outputBuffer[o++] = input[i++];
	}
	return strcopy(output, maxlen, outputBuffer);
}

/**
 * Map CS:GO-compatible colors to RGB colors that are supported in the other games.
 * 
 * CS:GO-compatible colors are defined as a subset of single, non-printable characters
 * (see CSGO_COLOR_*).
 * 
 * An ArrayList handle can be passed in with manually-defined replacement strings.  \x01 maps
 * to the first index in the array (0), \x02 to the second, etc.
 */
stock int MapCSGOColorTextToRGB(const char[] input, char[] output, int maxlen,
		ArrayList colorMap = null) {
	if (!colorMap) {
		colorMap = GetDefaultColorMap();
	}
	
	char[] outputBuffer = new char[maxlen];
	int i, o, l = strlen(input);
	while (i < l && o < maxlen) {
		int mappedColor = input[i] - 1;
		if (mappedColor < colorMap.Length) {
			i++;
			
			char color[12];
			colorMap.GetString(mappedColor, color, sizeof(color));
			
			StrCat(outputBuffer, maxlen, color);
			o = strlen(outputBuffer);
		} else {
			outputBuffer[o++] = input[i++];
		}
	}
	return strcopy(output, maxlen, outputBuffer);
}

/** 
 * Returns a singleton ArrayList containing a default color mapping for CS:GO colors, allocating
 * a new handle if it currently does not exist.
 */
static stock ArrayList GetDefaultColorMap() {
	static ArrayList s_ColorMap;
	
	if (!s_ColorMap) {
		s_ColorMap = new ArrayList(ByteCountToCells(12));
		
		s_ColorMap.PushString(COLOR_DEFAULT);
		s_ColorMap.PushString(COLOR_PLAYER);
		s_ColorMap.PushString(COLOR_TEAM);
		s_ColorMap.PushString(COLOR_LOCATION);
		s_ColorMap.PushString(COLOR_OLIVE);
		s_ColorMap.PushString(COLOR_GREENYELLOW);
		s_ColorMap.PushString(COLOR_CRIMSON);
		s_ColorMap.PushString(COLOR_LIGHTGRAY);
		s_ColorMap.PushString(COLOR_YELLOW);
		s_ColorMap.PushString(COLOR_LIGHTSTEELBLUE);
		s_ColorMap.PushString(COLOR_LIGHTBLUE);
		s_ColorMap.PushString(COLOR_DODGERBLUE);
		s_ColorMap.PushString(COLOR_SLATEGRAY);
		s_ColorMap.PushString(COLOR_ORCHID);
		s_ColorMap.PushString(COLOR_SALMON);
		s_ColorMap.PushString(COLOR_ORANGE);
	}
	return s_ColorMap;
}