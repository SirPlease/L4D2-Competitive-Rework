StringMap g_hChatColors;

void AddChatColors()
{
    if (!g_hChatColors) {
        g_hChatColors = new StringMap();
    }

    AddChatColor("default", "\x01");
    AddChatColor("teamcolor", "\x03");

    switch (GetEngineVersion()) {
        case Engine_CSS, Engine_DODS, Engine_HL2DM, Engine_Insurgency, Engine_SDK2013, Engine_TF2: {
            AddChatColor("aliceblue", "\x07F0F8FF");
            AddChatColor("allies", "\x074D7942");
            AddChatColor("ancient", "\x07EB4B4B");
            AddChatColor("antiquewhite", "\x07FAEBD7");
            AddChatColor("aqua", "\x0700FFFF");
            AddChatColor("aquamarine", "\x077FFFD4");
            AddChatColor("arcana", "\x07ADE55C");
            AddChatColor("axis", "\x07FF4040");
            AddChatColor("azure", "\x07007FFF");
            AddChatColor("beige", "\x07F5F5DC");
            AddChatColor("bisque", "\x07FFE4C4");
            AddChatColor("black", "\x07000000");
            AddChatColor("blanchedalmond", "\x07FFEBCD");
            AddChatColor("blue", "\x0799CCFF");
            AddChatColor("blueviolet", "\x078A2BE2");
            AddChatColor("brown", "\x07A52A2A");
            AddChatColor("burlywood", "\x07DEB887");
            AddChatColor("cadetblue", "\x075F9EA0");
            AddChatColor("chartreuse", "\x077FFF00");
            AddChatColor("chocolate", "\x07D2691E");
            AddChatColor("collectors", "\x07AA0000");
            AddChatColor("common", "\x07B0C3D9");
            AddChatColor("community", "\x0770B04A");
            AddChatColor("coral", "\x07FF7F50");
            AddChatColor("cornflowerblue", "\x076495ED");
            AddChatColor("cornsilk", "\x07FFF8DC");
            AddChatColor("corrupted", "\x07A32C2E");
            AddChatColor("crimson", "\x07DC143C");
            AddChatColor("cyan", "\x0700FFFF");
            AddChatColor("darkblue", "\x0700008B");
            AddChatColor("darkcyan", "\x07008B8B");
            AddChatColor("darkgoldenrod", "\x07B8860B");
            AddChatColor("darkgray", "\x07A9A9A9");
            AddChatColor("darkgrey", "\x07A9A9A9");
            AddChatColor("darkgreen", "\x07006400");
            AddChatColor("darkkhaki", "\x07BDB76B");
            AddChatColor("darkmagenta", "\x078B008B");
            AddChatColor("darkolivegreen", "\x07556B2F");
            AddChatColor("darkorange", "\x07FF8C00");
            AddChatColor("darkorchid", "\x079932CC");
            AddChatColor("darkred", "\x078B0000");
            AddChatColor("darksalmon", "\x07E9967A");
            AddChatColor("darkseagreen", "\x078FBC8F");
            AddChatColor("darkslateblue", "\x07483D8B");
            AddChatColor("darkslategray", "\x072F4F4F");
            AddChatColor("darkslategrey", "\x072F4F4F");
            AddChatColor("darkturquoise", "\x0700CED1");
            AddChatColor("darkviolet", "\x079400D3");
            AddChatColor("deeppink", "\x07FF1493");
            AddChatColor("deepskyblue", "\x0700BFFF");
            AddChatColor("dimgray", "\x07696969");
            AddChatColor("dimgrey", "\x07696969");
            AddChatColor("dodgerblue", "\x071E90FF");
            AddChatColor("exalted", "\x07CCCCCD");
            AddChatColor("firebrick", "\x07B22222");
            AddChatColor("floralwhite", "\x07FFFAF0");
            AddChatColor("forestgreen", "\x07228B22");
            AddChatColor("frozen", "\x074983B3");
            AddChatColor("fuchsia", "\x07FF00FF");
            AddChatColor("fullblue", "\x070000FF");
            AddChatColor("fullred", "\x07FF0000");
            AddChatColor("gainsboro", "\x07DCDCDC");
            AddChatColor("genuine", "\x074D7455");
            AddChatColor("ghostwhite", "\x07F8F8FF");
            AddChatColor("gold", "\x07FFD700");
            AddChatColor("goldenrod", "\x07DAA520");
            AddChatColor("gray", "\x07CCCCCC");
            AddChatColor("grey", "\x07CCCCCC");
            AddChatColor("green", "\x073EFF3E");
            AddChatColor("greenyellow", "\x07ADFF2F");
            AddChatColor("haunted", "\x0738F3AB");
            AddChatColor("honeydew", "\x07F0FFF0");
            AddChatColor("hotpink", "\x07FF69B4");
            AddChatColor("immortal", "\x07E4AE33");
            AddChatColor("indianred", "\x07CD5C5C");
            AddChatColor("indigo", "\x074B0082");
            AddChatColor("ivory", "\x07FFFFF0");
            AddChatColor("khaki", "\x07F0E68C");
            AddChatColor("lavender", "\x07E6E6FA");
            AddChatColor("lavenderblush", "\x07FFF0F5");
            AddChatColor("lawngreen", "\x077CFC00");
            AddChatColor("legendary", "\x07D32CE6");
            AddChatColor("lemonchiffon", "\x07FFFACD");
            AddChatColor("lightblue", "\x07ADD8E6");
            AddChatColor("lightcoral", "\x07F08080");
            AddChatColor("lightcyan", "\x07E0FFFF");
            AddChatColor("lightgoldenrodyellow", "\x07FAFAD2");
            AddChatColor("lightgray", "\x07D3D3D3");
            AddChatColor("lightgrey", "\x07D3D3D3");
            AddChatColor("lightgreen", "\x0799FF99");
            AddChatColor("lightpink", "\x07FFB6C1");
            AddChatColor("lightsalmon", "\x07FFA07A");
            AddChatColor("lightseagreen", "\x0720B2AA");
            AddChatColor("lightskyblue", "\x0787CEFA");
            AddChatColor("lightslategray", "\x07778899");
            AddChatColor("lightslategrey", "\x07778899");
            AddChatColor("lightsteelblue", "\x07B0C4DE");
            AddChatColor("lightyellow", "\x07FFFFE0");
            AddChatColor("lime", "\x0700FF00");
            AddChatColor("limegreen", "\x0732CD32");
            AddChatColor("linen", "\x07FAF0E6");
            AddChatColor("magenta", "\x07FF00FF");
            AddChatColor("maroon", "\x07800000");
            AddChatColor("mediumaquamarine", "\x0766CDAA");
            AddChatColor("mediumblue", "\x070000CD");
            AddChatColor("mediumorchid", "\x07BA55D3");
            AddChatColor("mediumpurple", "\x079370D8");
            AddChatColor("mediumseagreen", "\x073CB371");
            AddChatColor("mediumslateblue", "\x077B68EE");
            AddChatColor("mediumspringgreen", "\x0700FA9A");
            AddChatColor("mediumturquoise", "\x0748D1CC");
            AddChatColor("mediumvioletred", "\x07C71585");
            AddChatColor("midnightblue", "\x07191970");
            AddChatColor("mintcream", "\x07F5FFFA");
            AddChatColor("mistyrose", "\x07FFE4E1");
            AddChatColor("moccasin", "\x07FFE4B5");
            AddChatColor("mythical", "\x078847FF");
            AddChatColor("navajowhite", "\x07FFDEAD");
            AddChatColor("navy", "\x07000080");
            AddChatColor("normal", "\x07B2B2B2");
            AddChatColor("oldlace", "\x07FDF5E6");
            AddChatColor("olive", "\x079EC34F");
            AddChatColor("olivedrab", "\x076B8E23");
            AddChatColor("orange", "\x07FFA500");
            AddChatColor("orangered", "\x07FF4500");
            AddChatColor("orchid", "\x07DA70D6");
            AddChatColor("palegoldenrod", "\x07EEE8AA");
            AddChatColor("palegreen", "\x0798FB98");
            AddChatColor("paleturquoise", "\x07AFEEEE");
            AddChatColor("palevioletred", "\x07D87093");
            AddChatColor("papayawhip", "\x07FFEFD5");
            AddChatColor("peachpuff", "\x07FFDAB9");
            AddChatColor("peru", "\x07CD853F");
            AddChatColor("pink", "\x07FFC0CB");
            AddChatColor("plum", "\x07DDA0DD");
            AddChatColor("powderblue", "\x07B0E0E6");
            AddChatColor("purple", "\x07800080");
            AddChatColor("rare", "\x074B69FF");
            AddChatColor("red", "\x07FF4040");
            AddChatColor("rosybrown", "\x07BC8F8F");
            AddChatColor("royalblue", "\x074169E1");
            AddChatColor("saddlebrown", "\x078B4513");
            AddChatColor("salmon", "\x07FA8072");
            AddChatColor("sandybrown", "\x07F4A460");
            AddChatColor("seagreen", "\x072E8B57");
            AddChatColor("seashell", "\x07FFF5EE");
            AddChatColor("selfmade", "\x0770B04A");
            AddChatColor("sienna", "\x07A0522D");
            AddChatColor("silver", "\x07C0C0C0");
            AddChatColor("skyblue", "\x0787CEEB");
            AddChatColor("slateblue", "\x076A5ACD");
            AddChatColor("slategray", "\x07708090");
            AddChatColor("slategrey", "\x07708090");
            AddChatColor("snow", "\x07FFFAFA");
            AddChatColor("springgreen", "\x0700FF7F");
            AddChatColor("steelblue", "\x074682B4");
            AddChatColor("strange", "\x07CF6A32");
            AddChatColor("tan", "\x07D2B48C");
            AddChatColor("teal", "\x07008080");
            AddChatColor("thistle", "\x07D8BFD8");
            AddChatColor("tomato", "\x07FF6347");
            AddChatColor("turquoise", "\x0740E0D0");
            AddChatColor("uncommon", "\x07B0C3D9");
            AddChatColor("unique", "\x07FFD700");
            AddChatColor("unusual", "\x078650AC");
            AddChatColor("valve", "\x07A50F79");
            AddChatColor("vintage", "\x07476291");
            AddChatColor("violet", "\x07EE82EE");
            AddChatColor("wheat", "\x07F5DEB3");
            AddChatColor("white", "\x07FFFFFF");
            AddChatColor("whitesmoke", "\x07F5F5F5");
            AddChatColor("yellow", "\x07FFFF00");
            AddChatColor("yellowgreen", "\x079ACD32");
        }
        case Engine_Left4Dead, Engine_Left4Dead2: {
            AddChatColor("lightgreen", "\x03");
            AddChatColor("yellow", "\x04");
            AddChatColor("green", "\x05");
        }
        case Engine_CSGO: {
            AddChatColor("red", "\x07");
            AddChatColor("lightred", "\x0F");
            AddChatColor("darkred", "\x02");
            AddChatColor("bluegrey", "\x0A");
            AddChatColor("blue", "\x0B");
            AddChatColor("darkblue", "\x0C");
            AddChatColor("purple", "\x03");
            AddChatColor("orchid", "\x0E");
            AddChatColor("yellow", "\x09");
            AddChatColor("gold", "\x10");
            AddChatColor("lightgreen", "\x05");
            AddChatColor("green", "\x04");
            AddChatColor("lime", "\x06");
            AddChatColor("grey", "\x08");
            AddChatColor("grey2", "\x0D");
        }
        default: {
            AddChatColor("lightgreen", "\x03");
            AddChatColor("green", "\x04");
            AddChatColor("olive", "\x05");
        }
    }

    AddChatColor("engine 1", "\x01");
    AddChatColor("engine 2", "\x02");
    AddChatColor("engine 3", "\x03");
    AddChatColor("engine 4", "\x04");
    AddChatColor("engine 5", "\x05");
    AddChatColor("engine 6", "\x06");
    AddChatColor("engine 7", "\x07");
    AddChatColor("engine 8", "\x08");
    AddChatColor("engine 9", "\x09");
    AddChatColor("engine 10", "\x0A");
    AddChatColor("engine 11", "\x0B");
    AddChatColor("engine 12", "\x0C");
    AddChatColor("engine 13", "\x0D");
    AddChatColor("engine 14", "\x0E");
    AddChatColor("engine 15", "\x0F");
    AddChatColor("engine 16", "\x10");
}

static void AddChatColor(const char[] name, const char[] color)
{
    g_hChatColors.SetString(name, color);
}

static int PreFormat(char[] buffer, int maxlength)
{
    if (GetEngineVersion() == Engine_CSGO) {
        return FormatEx(buffer, maxlength, " %c", 1);
    }

    return FormatEx(buffer, maxlength, "%c", 1);
}

void ProcessChatColors(const char[] message, char[] buffer, int maxlength)
{
    char name[32], color[10];
    int buf_idx = PreFormat(buffer, maxlength);
    int i, name_len;

    while (message[i] && buf_idx < maxlength - 1) {
        if (message[i] != '{' || (name_len = FindCharInString(message[i + 1], '}')) == -1) {
            buffer[buf_idx++] = message[i++];
            continue;
        }

        strcopy(name, name_len + 1, message[i + 1]);

        if (name[0] == '#') {
            buf_idx += FormatEx(buffer[buf_idx], maxlength - buf_idx, "%c%s", (name_len == 9) ? 8 : 7, name[1]);
        } else if (g_hChatColors.GetString(name, color, sizeof(color))) {
            buf_idx += strcopy(buffer[buf_idx], maxlength - buf_idx, color);
        } else {
            buf_idx += FormatEx(buffer[buf_idx], maxlength - buf_idx, "{%s}", name);
        }

        i += name_len + 2;
    }

    buffer[buf_idx] = '\0';
}

void SayText2(int client, const char[] message)
{
    Handle msg = StartMessageOne("SayText2", client, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS);

    if (GetUserMessageType() == UM_Protobuf) {
        Protobuf pb = UserMessageToProtobuf(msg);
        pb.SetInt("ent_idx", client);
        pb.SetBool("chat", true);
        pb.SetString("msg_name", message);
        pb.AddString("params", "");
        pb.AddString("params", "");
        pb.AddString("params", "");
        pb.AddString("params", "");
    } else {
        BfWrite bf = UserMessageToBfWrite(msg);
        bf.WriteByte(client);
        bf.WriteByte(true);
        bf.WriteString(message);
    }

    EndMessage();
}
