/*  SM Translator
 *
 *  Copyright (C) 2018 Francisco 'Franc1sco' García
 * 
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option) 
 * any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT 
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with 
 * this program. If not, see http://www.gnu.org/licenses/.
 */

#include <sdktools>
#include <ripext>
#include <SteamWorks>
#include <colors>
#include <logger>

#define VER "1.0.1"
#define SHORT_LEN 5
#define Language_NotSupport "NONE"

ConVar g_hTranslateApi;
ConVar g_hTranslateApiKey,g_hTranslateApiAuth;

Logger log;

public Plugin myinfo =
{
    name = "SM Translator",
    description = "Translate chat messages",
    author = "Franc1sco franug, Sir.P",
    version = VER,
    url = "http://steamcommunity.com/id/franug"
};

char ServerLang[5];
char ServerCompleteLang[32];

bool g_translator[MAXPLAYERS + 1];

char baiduapi[] = "https://aip.baidubce.com/rpc/2.0/mt/texttrans/v1?access_token="
char deeplapi[] = "https://api-free.deepl.com/v2/translate"
char deeplproapi[] = "https://api.deepl.com/v2/translate"
char g_cApiKey[256], g_cApiAuth[256], g_cApiToken[256];


enum TranslateSource{
    Translator_None,
    Translator_Baidu,
    Translator_DeepL,
    Translator_DeepLPro
}

enum TranslateLanguage{
    LA_None,
    LA_English,
    LA_Arabic,
    LA_Brazilian,
    LA_Bulgarian,
    LA_Czech,
    LA_Danish,
    LA_Dutch,
    LA_Finnish,
    LA_French,
    LA_German,
    LA_Greek,
    LA_Hebrew,
    LA_Hungarian,
    LA_Italian,
    LA_Japanese,
    LA_KoreanA,
    LA_Korean,
    LA_Latvian,
    LA_Lithuanian,
    LA_Norwegian,
    LA_Polish,
    LA_Portuguese,
    LA_Romanian,
    LA_Russian,
    LA_SChinese,
    LA_Slovak,
    LA_Spanish,
    LA_Swedish,
    LA_TChinese,
    LA_Thai,
    LA_Turkish,
    LA_Ukrainian,
    LA_Vietnamese,
    LA_Auto,
    LA_Size,
};
char ShortInSM[LA_Size][SHORT_LEN] = {
    Language_NotSupport,
    "en", 
    "ar", 
    "pt", 
    "bg", 
    "cze", 
    "da", 
    "nl", 
    "fi", 
    "fr", 
    "de",
    "el", 
    "he", 
    "hu", 
    "it", 
    "jp", 
    "ko", 
    "ko", 
    "lv", 
    "lt", 
    "no",
    "pl", 
    "pt_p", 
    "ro", 
    "ru", 
    "chi", 
    "sk", 
    "es", 
    "sv", 
    "zho",
    "th", 
    "tr", 
    "ua", 
    "vi",
    Language_NotSupport
}
char ShortInBaidu[LA_Size][SHORT_LEN] = {
    Language_NotSupport,
    "en",
    "ara",
    "pt",
    "bul",
    "cs",
    "dan",
    "nl",
    "fin",
    "fra",
    "de",
    "el",
    "heb",
    "hu",
    "it",
    "jp",
    "kor",
    "kor",
    "lav",
    "lit",
    "nor",
    "pl",
    "pt",
    "rom",
    "ru",
    "zh",
    "sk",
    "spa",
    "swe",
    "cht",
    "th",
    "tr",
    "ukr",
    "vie",
    "auto"
}

char ShortInDeepL[LA_Size][SHORT_LEN] = {
    Language_NotSupport,
    "EN",
    Language_NotSupport,
    "PT-BR",
    "BG",
    "CS",
    "DA",
    "NL",
    "FI",
    "FR",
    "DE",
    "EL",
    Language_NotSupport,
    "HU",
    "IT",
    "JA",
    "KO",
    "KO",
    "LV",
    "LT",
    "NB",
    Language_NotSupport,
    "PT",
    "RO",
    "RU",
    "ZH",
    Language_NotSupport,
    "SK",
    "SV",
    "ZH", // No support. Use Simplified Chinese instead.
    Language_NotSupport,
    "TR",
    "UK",
    Language_NotSupport,
    Language_NotSupport // auto does not need to pass a parameter
}

enum struct TranslateObject{
    char message[255];
    int sayer;
    bool team;  
    TranslateLanguage src;
    TranslateLanguage dst[MAXPLAYERS];  //目标语言 不重复
    TranslateLanguage clients[MAXPLAYERS];  //需要翻译的玩家 会重复

    bool IsDstLangAdded(TranslateLanguage la){
        for (int i = 0; i < sizeof(this.dst); i++){
            if (this.dst[i] == la) return true
        }
        return false
    }

    bool AddDstLanguage(TranslateLanguage la, int client){
        this.clients[client] = la;
        for (int i = 0; i < sizeof(this.dst); i++){
            if (this.dst[i] == LA_None) {
                if (!this.IsDstLangAdded(la)) {
                    this.dst[i] = la; 
                    log.debug("目标语言添加：%s/第%i", ShortInSM[la], i);
                }
                break;
            }
            
        }
        return true;
    }   
}
TranslateObject g_TlQueue[15];
int g_TlQueuePos = 0;
TranslateSource g_TlSource;
public void OnPluginStart()
{
    log = new Logger("sm_translator", LoggerType_NewLogFile);
    log.IgnoreLevel = LogType_Debug;
    log.SetLogPrefix("[Rework]");
    if (log.FileSize > 1024*1024*5) log.DelLogFile();
    LoadTranslations("sm_translator.phrases.txt");

    CreateConVar("sm_translator_version", VER, "SM Translator Version", FCVAR_SPONLY|FCVAR_NOTIFY);
    g_hTranslateApi = CreateConVar("sm_translator_api", "1", "SM Translator Api, 0=Disable, 1=Baidu, 2=DeepL api free 3=DeepL api pro");
    g_hTranslateApiKey = CreateConVar("sm_translator_apikey", "beLX1eoWGvtlzU0GGG542Tox", "SM Translator Apikey, for baidu api");
    g_hTranslateApiAuth = CreateConVar("sm_translator_apiauth", "znhKVCi8l1gN4V1tssD4TaIa9iwKs2Ek", "SM Translator Apikey, for baidu api and deepl (':fx' is not required)");
    AddCommandListener(Command_Say, "say");	
    AddCommandListener(Command_Say, "say_team");	
    GetLanguageInfo(GetServerLanguage(), ServerLang, 3, ServerCompleteLang, 32);

    RegConsoleCmd("sm_translator", Command_Translator);
    
    for(int i = 1; i <= MaxClients; i++)
        {
            if(IsClientInGame(i) && !IsFakeClient(i))
            {
                OnClientPostAdminCheck(i);
            }
        }
    OnCvarChanged(g_hTranslateApi, "", "");

    g_hTranslateApi.AddChangeHook(OnCvarChanged);
    g_hTranslateApiKey.AddChangeHook(OnCvarChanged);
    g_hTranslateApiAuth.AddChangeHook(OnCvarChanged);

}

public void OnCvarChanged(ConVar convar, const char[] oldValue, const char[] newValue){
    g_TlSource = view_as<TranslateSource>(g_hTranslateApi.IntValue);
    g_hTranslateApiKey.GetString(g_cApiKey, sizeof(g_cApiKey));
    g_hTranslateApiAuth.GetString(g_cApiAuth, sizeof(g_cApiAuth));

    if (g_TlSource == Translator_Baidu){
        GetAccessToken(g_cApiKey, g_cApiAuth);
    }
}

public Action Command_Translator(int client, int args)
{
    DoMenu(client);
    return Plugin_Handled;
}

public void OnClientPostAdminCheck(int client)
{
    g_translator[client] = false;
    CreateTimer(4.0, Timer_ShowMenu, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_ShowMenu(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);
    
    if (!client || !IsClientInGame(client))return Plugin_Continue;
    
    if (GetServerLanguage() == GetClientLanguage(client))return Plugin_Continue;

    CPrintToChat(client, "{lightgreen}[TRANSLATOR]{green} %t", "Type in chat !translator for open again this menu", client);
    DoMenu(client);
    return Plugin_Continue;
}

void DoMenu(int client)
{
    char temp[128];
    
    Menu menu = new Menu(Menu_select);
    menu.SetTitle("%t", "This server have a translation plugin so you can talk in your own language and it will be translated to others.Use translator?",client);
    
    Format(temp, sizeof(temp), "%t", "Yes, I want to use chat in my native language",client);
    menu.AddItem("yes", temp);
    
    
    Format(temp, sizeof(temp), "%t (%s)","No, I want to use chat in the official server language by my own", ServerCompleteLang);
    menu.AddItem("no", temp);
    menu.Display(client, MENU_TIME_FOREVER);
}

public int Menu_select(Menu menu, MenuAction action, int client, int param)
{
    if (action == MenuAction_Select)
    {
        char selection[128];
        menu.GetItem(param, selection, sizeof(selection));
        
        if (StrEqual(selection, "yes"))g_translator[client] = true;
        else g_translator[client] = false;
        
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }
    return 0;
}

TranslateLanguage GetTLangFromChar(const char[] la, char[][] LaGroup){
    for (TranslateLanguage i = LA_None; i < LA_Size; i++){
        if (StrEqual(LaGroup[i], la)) return i;
    }
    return LA_None;
}

public Action Command_Say(int client, const char[] command, int args)
{
    if (!IsValidClient(client)) return Plugin_Continue;

    char buffer[255];
    GetCmdArgString(buffer,sizeof(buffer));
    StripQuotes(buffer);
    
    if (strlen(buffer) < 1)return Plugin_Continue;
    
    char commands[255];
    
    GetCmdArg(1, commands, sizeof(commands));
    ReplaceString(commands, sizeof(commands), "!", "sm_", false);
    ReplaceString(commands, sizeof(commands), "/", "sm_", false);
    
    if (CommandExists(commands))return Plugin_Continue;
    log.debug("Command_Say: %N, %s", client, command);

    char temp[6];
    
    TranslateObject tlobj;

    strcopy(tlobj.message, sizeof(tlobj.message), buffer);
    tlobj.sayer = client;
    GetLanguageInfo(GetClientLanguage(client), temp, 6);
    tlobj.src = GetTLangFromChar(temp, ShortInSM);
    tlobj.team = StrEqual("say_team", command);
    if (g_translator[tlobj.sayer]) tlobj.AddDstLanguage(GetTLangFromChar(ServerLang, ShortInSM), tlobj.sayer);
    bool shouldtl = false;


    // Foreign 发言玩家是外国人，翻译该玩家说的话给其他非外国人
    if(GetServerLanguage() != GetClientLanguage(client))
    {
        if (!g_translator[client])return Plugin_Continue;
        log.debug("发言人使用非服务器语言");
        for(int i = 1; i <= MaxClients; i++)
        {
            if(IsClientInGame(i) && !IsFakeClient(i) && GetClientLanguage(client) != GetClientLanguage(i))
            {
                GetLanguageInfo(GetClientLanguage(i), temp, 6); // get Foreign language
                tlobj.AddDstLanguage(GetTLangFromChar(temp, ShortInSM), i);
                shouldtl = true;// Translate not Foreign msg to Foreign player
            }
        }
    }
    else // Not foreign 发言玩家不是外国人，翻译该玩家的话给其他外国人 
    {
        log.debug("发言人使用服务器语言");
        for(int i = 1; i <= MaxClients; i++)
        {
            if(IsClientInGame(i) && !IsFakeClient(i) &&  i != client)
            {
                if (!g_translator[i]) continue;
                GetLanguageInfo(GetClientLanguage(i), temp, 6); // get Foreign language
                tlobj.AddDstLanguage(GetTLangFromChar(temp, ShortInSM), i);
                shouldtl = true; // Translate not Foreign msg to Foreign player
            }
        }
    }
    if (shouldtl) {
        char _temp[512], _temp2[512];
        for (int i = 0; i < sizeof(tlobj.dst); i++){
            if (tlobj.dst[i] != LA_None) {
                Format(_temp, sizeof(_temp), "%s|%s", _temp,ShortInSM[tlobj.dst[i]]);
            }
        }
        for (int i = 1; i < sizeof(tlobj.clients); i++){
            if (tlobj.clients[i] != LA_None){
                Format(_temp2, sizeof(_temp2),"%s|%N(%i)",  _temp2, i, i);
            }
        }
        CreateRequest(tlobj); 
        log.debug("创建新翻译对象：%i", g_TlQueuePos);
        log.debug("message: \"%s\" \nsayer: %N(%i)\nteam: %i\nsrc: %s \ndst:%s \nplayer: %s", tlobj.message, tlobj.sayer, tlobj.sayer, tlobj.team, ShortInSM[tlobj.src],
            _temp, _temp2);
    }
    return Plugin_Continue;
}


void GetAccessToken(char[] client_id, char[] client_secret)
{
    Handle request = SteamWorks_CreateHTTPRequest(k_EHTTPMethodPOST, "https://aip.baidubce.com/oauth/2.0/token");
    SteamWorks_SetHTTPRequestGetOrPostParameter(request, "grant_type", "client_credentials");
    SteamWorks_SetHTTPRequestGetOrPostParameter(request, "client_id", client_id);
    SteamWorks_SetHTTPRequestGetOrPostParameter(request, "client_secret", client_secret);
    SteamWorks_SetHTTPCallbacks(request, Callback_TokenGeted);
    SteamWorks_SendHTTPRequest(request);
}
public int Callback_TokenGeted(Handle request, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode)
{
    int iBufferSize;
    SteamWorks_GetHTTPResponseBodySize(request, iBufferSize);
    
    // ==================处理返回json==================
    char[] result = new char[iBufferSize];  
    SteamWorks_GetHTTPResponseBodyData(request, result, iBufferSize);
    delete request;
    char[] t = new char[iBufferSize]; 
    JSONObject json;
    log.debug("Translator: 获取token api 返回 - %s", result);
    json = JSONObject.FromString(result);
    json.GetString("access_token", t, iBufferSize);
    log.debug("Translator: access_token - %s", t);
    Format(g_cApiToken, sizeof(g_cApiToken), "%s", t);
    delete json;
    log.debug("Translator: API Authed: %s%s", baiduapi, g_cApiToken);
    return 0;
}

void CreateRequest(TranslateObject tlobj){
    
    log.debug("CreateRequest开始处理翻译对象：%i", g_TlQueuePos);
    log.debug("\nmessage: \"%s\" \nsayer: %N\nteam: %i\n src: %s", tlobj.message, tlobj.sayer, tlobj.team, ShortInSM[tlobj.src]);
    g_TlQueue[g_TlQueuePos] = tlobj;

    char body[16536];
    // 遍历每种目标语言，构建请求体
    log.debug("调用api对所有需要语言进行翻译:")
    for (int i = 0; i < sizeof(tlobj.dst); i++){
        if (tlobj.dst[i] == LA_None) continue;
        HTTPRequest request;
        switch (g_TlSource){
            case Translator_Baidu:{
                char url[256];
                Format(url, sizeof(url), "%s%s", baiduapi, g_cApiToken);
                request = new HTTPRequest(url);
            }
            case Translator_DeepL:{
                request = new HTTPRequest(deeplapi);
                request.SetHeader("Authorization", "DeepL-Auth-Key %s:fx", g_cApiAuth);
                log.debug("Authorization: DeepL-Auth-Key %s", g_cApiAuth);
            }
            case Translator_DeepLPro:{
                request = new HTTPRequest(deeplproapi);
                request.SetHeader("Authorization", "DeepL-Auth-Key %s:fx", g_cApiAuth);
                log.debug("Authorization: DeepL-Auth-Key %s", g_cApiAuth);
            }
            default:
                return;
        }
        request.SetHeader("Content-Type", "application/json");
        request.SetHeader("Accept", "application/json");
        request.SetHeader("User-Agent", "SM Translator/"...VER);
        log.debug("翻译至%s", ShortInSM[tlobj.dst[i]])
        JSONObject bodyjson = new JSONObject();
        JSONArray _text = new JSONArray();
        switch (g_TlSource){
            case Translator_Baidu:{
                bodyjson.SetString("from", ShortInBaidu[LA_Auto]);
                bodyjson.SetString("to", ShortInBaidu[tlobj.dst[i]]);
                bodyjson.SetString("q", tlobj.message);
                log.debug("[baidu]目标: %s, 文本: \"%s\"", ShortInBaidu[tlobj.dst[i]], tlobj.message);
            }
            case Translator_DeepL, Translator_DeepLPro:{
                if (_text.PushString(tlobj.message)) bodyjson.Set("text", _text);
                else {log.error("_text.PushString Failed"); return;}
                bodyjson.SetString("target_lang", ShortInDeepL[tlobj.dst[i]]);
                log.debug("[deepl]目标: %s, 文本: \"%s\"", ShortInDeepL[tlobj.dst[i]], tlobj.message);
                
            }
        }
        bodyjson.ToString(body, 16536);
        log.debug("body: %s", body);
        request.Post(bodyjson, OnHttpResponse, g_TlQueuePos);
        delete bodyjson;
        delete _text;
    }
    if (++g_TlQueuePos > (sizeof(g_TlQueue)-1)){
        g_TlQueuePos = 0;
    }
    return;
}
public void OnHttpResponse(HTTPResponse response, any value){
    log.debug("解析返回内容")
    int pos = view_as<int>(value);
    char result[255];
    char dstbuff[5];
    if (response.Status != HTTPStatus_OK) {
        log.error("翻译异常：HTTP %i", response.Status);
        return;
    }
    char sData[1024];
    response.Data.ToString(sData, sizeof(sData));
    log.info("翻译api返回: %s", sData);
    JSONObject json;
    TranslateLanguage dst;
    json = view_as<JSONObject>(response.Data);
    switch (g_TlSource){
        case Translator_Baidu:{
            if (json.HasKey("error_msg")){
                json.GetString("error_msg", result, sizeof(result));
                log.error("翻译异常：%s | ", result);
                delete json; 
            }
            else if (json.HasKey("result"))
            {
                JSONObject t_json = view_as<JSONObject>(json.Get("result"));
                t_json.GetString("to", dstbuff, sizeof(dstbuff));
                JSONArray t_jsona = view_as<JSONArray>(t_json.Get("trans_result"));
                JSONObject t_json2 = view_as<JSONObject>(t_jsona.Get(0));
                t_json2.GetString("dst", result, sizeof(result));
                delete t_json;
                delete t_jsona;
                delete t_json2;
                dst = GetTLangFromChar(dstbuff, ShortInBaidu);
            }
        }
        case Translator_DeepL, Translator_DeepLPro:{
            if (json.HasKey("translations")){
                JSONArray t_jsona = view_as<JSONArray>(json.Get("translations"));
                JSONObject t_json2 = view_as<JSONObject>(t_jsona.Get(0));
                t_json2.GetString("text", result, sizeof(result));
                t_json2.GetString("detected_source_language", dstbuff, sizeof(dstbuff));
                dst = GetTLangFromChar(dstbuff, ShortInDeepL);
            }
        }
    }
    log.debug("翻译结果：%s \"%s\"", ShortInSM[dst], result);
    log.debug("解析所有需要输出至的玩家:");
    // 输出翻译结果
    for(int i = 1; i <= MaxClients; i++){
        if (!IsClientInGame(i)) continue;
        if (g_TlQueue[pos].clients[i] == LA_None) continue;
        log.debug("%N - 语言: %s - 开始匹配", i, ShortInSM[g_TlQueue[pos].clients[i]]);
        // 跳过自己
        //if (i == g_TlQueue[pos].sayer) continue;
        // 如果为队内发言，则仅队友和旁观可见翻译
        if (g_TlQueue[pos].team && (GetClientTeam(i) != GetClientTeam(g_TlQueue[pos].sayer) && GetClientTeam(i) != 1)) continue;
        // 如果该玩家的语言符合该次翻译语言，就输出给这个玩家
        char _color[5];
        switch (GetClientTeam(g_TlQueue[pos].sayer)){
            case 1:
                strcopy(_color, sizeof(_color), "lime");
            case 2:
                strcopy(_color, sizeof(_color), "blue");
            case 3:
                strcopy(_color, sizeof(_color), "red");
        }

        if (g_TlQueue[pos].clients[i] == dst){
            log.debug("为%N提供翻译", i);
            CPrintToChat(i, "%s{%s}%N <translated>{default}: %s",
                g_TlQueue[pos].team ? "(TEAM)" : "",
                _color,
                g_TlQueue[pos].sayer, 
                result
            );
        }
    }
    
}

stock bool IsValidClient(int client, bool bAllowBots = false, bool bAllowDead = true)
{
    if (!(1 <= client <= MaxClients) || !IsClientInGame(client) || (IsFakeClient(client) && !bAllowBots) || IsClientSourceTV(client) || IsClientReplay(client) || (!bAllowDead && !IsPlayerAlive(client)))
    {
        return false;
    }
    return true;
}