#include <custom_fakelag>
#include <console>

public Plugin:myinfo = 
{
  name = "Per-Player Fakelag",
  author = "ProdigySim",
  description = "Set a custom fake latency per player",
  version = "1.0",
  url = "https://github.com/ProdigySim/custom_fakelag"
};


public OnPluginStart()
{
  RegAdminCmd("sm_fakelag", FakeLagCmd, view_as<int>(Admin_Config), "Set fake lag for a player");
  RegAdminCmd("sm_printlag", PrintLagCmd, view_as<int>(Admin_Config), "Print Current FakeLag");
}

public Action FakeLagCmd(int client, int args) {
  if(args < 1) {
    ReplyToCommand(client, "Usage: sm_fakelag <target> <millseconds>");
    return Plugin_Handled;
  }
  char targetStr[256];
  GetCmdArg(1, targetStr, sizeof(targetStr))
  int target = FindTarget(client, targetStr, true);
  if(target < 0) {
    ReplyToCommand(client, "Unable to find target \"%s\"");
    return Plugin_Handled;
  }
  if(!IsClientInGame(target)) {
    ReplyToCommand(client, "Player %N is not in game yet.", target);
    return Plugin_Handled;
  }
  if (IsFakeClient(target)) {
    ReplyToCommand(client, "Player %N is a fake client and can't be lagged.", target);
    return Plugin_Handled;
  }

  int lagAmount = GetCmdArgInt_Plugin(2);
  CFakeLag_SetPlayerLatency(target, lagAmount * 1.0);
  ShowActivity2(client, "[SM]", "给 %N 添加 %dms 延迟 ", target, lagAmount);
  return Plugin_Handled;
}


// DEBUG: See the value of s_FakeLag
public Action PrintLagCmd(int client, int args) {
	for(int i = 1; i < MaxClients; i++) {
    if(IsClientInGame(i) && !IsFakeClient(i))
    {
      ReplyToCommand(client, "%N: %fms", i, CFakeLag_GetPlayerLatency(i))
    }
  }

	return Plugin_Handled;
}

stock int GetCmdArgInt_Plugin(int argnum) {
    char str[12];
    GetCmdArg(argnum, str, sizeof(str));

    return StringToInt(str);
}