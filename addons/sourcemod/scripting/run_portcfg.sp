#include <sourcemod>

ConVar g_cPort;

public void OnPluginStart(){
    g_cPort = FindConVar("hostport");
    RegServerCmd("sm_execportcfg", CMD_RunPortCfg);
    RegServerCmd("sm_addadmin", CMD_AddAdmin);
    CMD_RunPortCfg(0)
}

public Action CMD_RunPortCfg(int args){
    PrintToServer("exec serverport_%i.cfg", g_cPort.IntValue);
    ServerCommand("exec serverport_%i.cfg", g_cPort.IntValue);
    PrintToServer("exec spcontrol_server/serverport_%i.cfg", g_cPort.IntValue);
    ServerCommand("exec spcontrol_server/serverport_%i.cfg", g_cPort.IntValue);
    return Plugin_Handled;
}

public Action CMD_AddAdmin(int args){
    if (args < 1)
    {
        PrintToServer("用法: sm_addadmin \"<steamid>\"");
        return Plugin_Handled;
    }

    // 获取命令参数，即要添加的客户端的steamid
    char steamid[64];
    GetCmdArg(1, steamid, sizeof(steamid));
    if (FindAdminByIdentity("steam", steamid) != INVALID_ADMIN_ID)
    {
        PrintToServer("%s 已经是管理员了。", steamid);
        return Plugin_Handled;
    }
    char regname[64];
    Format(regname, sizeof(regname), "addbycommand_%i", GetRandomInt(1, 100000))
    AdminId admin = CreateAdmin(regname);
    BindAdminIdentity(admin, AUTHMETHOD_STEAM, steamid);

    SetAdminFlag(admin, Admin_Root, true);

    PrintToServer("成功将 %s 添加为管理员。", steamid);
    return Plugin_Handled;
}
