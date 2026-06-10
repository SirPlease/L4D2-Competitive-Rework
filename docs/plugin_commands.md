# 插件命令索引

本文档汇总仓库中 SourceMod 插件命令，便于查找玩家命令、管理命令和配置文件可用的服务器命令。主表按当前 `cfgogl` 模式配置会加载的插件分组；附录列出仓库存在但当前模式配置没有加载的插件命令。

## 范围和口径

- 主表扫描范围：`cfg/sharedplugins.cfg`、`cfg/generalfixes.cfg` 以及 `cfg/cfgogl/*/confogl_plugins.cfg` 递归 `exec` 后配置引用的 `.smx`。
- 附录扫描范围：`addons/sourcemod/plugins/` 下未放在 `disabled/` 的 `.smx`，但未被当前 `cfgogl` 模式配置引用的插件。
- 命令来源：对应 SourcePawn 源码中的 `RegConsoleCmd`、`RegAdminCmd`、`RegServerCmd` 和 `AddCommandListener`，并递归解析本地 `#include "..."`。
- 未统计：`addons/sourcemod/plugins/disabled/`、`addons/sourcemod/scripting/archive/`、测试插件和只有历史源码但没有启用目录 `.smx` 的内容。
- Anne 系列模式按配置归为：`allcharger`, `alone`, `annehappy`, `annehappy_hardcore`, `annehappy_shotgun`, `coop`, `hunters`, `realism`, `witchparty`。只在这些模式出现的命令放到“Anne 模式专用命令”；至少被一个非 Anne 对抗模式加载的命令放到“对抗通用命令”。
- `sm_xxx` 玩家/管理员命令通常也能在聊天中用 `!xxx` 或 `/xxx` 调用；`say`、`say_team` 标为聊天钩子，不建议当作普通命令使用。
- 权限列保留源码里的 SourceMod `ADMFLAG_*` / `Admin_*` 标志；实际权限还会受到 `admin_overrides.cfg` 等覆盖配置影响。

## 统计

- 当前模式配置引用插件：328 个。
- 主表已抽取命令/监听入口：450 条。
- 对抗通用：384 条。
- Anne 模式专用：66 条。
- 启用目录存在但当前模式配置未加载的插件命令：70 条。
- 未找到源码的未加载启用目录插件：16 个。
- 配置引用但 `addons/sourcemod/plugins/` 启用目录未找到同路径二进制：1 个。
  - `playercommands.smx`；当前仓库里可见的位置是 `addons/sourcemod/plugins/disabled/playercommands.smx`。

## 对抗通用命令

共 384 条命令/监听入口。

| 插件 | 命令 | 类型 | 权限 | 说明 | 出现模式 |
| --- | --- | --- | --- | --- | --- |
| `adminhelp.smx` | `sm_help` | 玩家/控制台 | - | Displays SourceMod commands and descriptions | 34 个模式 |
| `adminhelp.smx` | `sm_searchcmd` | 玩家/控制台 | - | Searches SourceMod commands | 34 个模式 |
| `adminmenu_mission_list.smx` | `sm_adminmap_gentrans` | 管理员 | ADMFLAG_RCON | Force regenerates map translation files. | 34 个模式 |
| `adminmenu_mission_list.smx` | `sm_vpk_reload` | 管理员 | ADMFLAG_RCON | Reloads VPKs and mission list. | 34 个模式 |
| `adminmenu.smx` | `sm_admin` | 管理员 | ADMFLAG_GENERIC | Displays the admin menu | 34 个模式 |
| `basebans.smx` | `sm_abortban` | 玩家/控制台 | - | sm_abortban | 34 个模式 |
| `basebans.smx` | `sm_addban` | 管理员 | ADMFLAG_RCON | sm_addban <time> <steamid> [reason] | 34 个模式 |
| `basebans.smx` | `sm_ban` | 管理员 | ADMFLAG_BAN | sm_ban <#userid\|name> <minutes\|0> [reason] | 34 个模式 |
| `basebans.smx` | `sm_banip` | 管理员 | ADMFLAG_BAN | sm_banip <ip\|#userid\|name> <time> [reason] | 34 个模式 |
| `basebans.smx` | `sm_unban` | 管理员 | ADMFLAG_UNBAN | sm_unban <steamid\|ip> | 34 个模式 |
| `basecomm.smx` | `sm_gag` | 管理员 | ADMFLAG_CHAT | sm_gag <player> - Removes a player's ability to use chat. | 34 个模式 |
| `basecomm.smx` | `sm_mute` | 管理员 | ADMFLAG_CHAT | sm_mute <player> - Removes a player's ability to use voice. | 34 个模式 |
| `basecomm.smx` | `sm_silence` | 管理员 | ADMFLAG_CHAT | sm_silence <player> - Removes a player's ability to use voice or chat. | 34 个模式 |
| `basecomm.smx` | `sm_ungag` | 管理员 | ADMFLAG_CHAT | sm_ungag <player> - Restores a player's ability to use chat. | 34 个模式 |
| `basecomm.smx` | `sm_unmute` | 管理员 | ADMFLAG_CHAT | sm_unmute <player> - Restores a player's ability to use voice. | 34 个模式 |
| `basecomm.smx` | `sm_unsilence` | 管理员 | ADMFLAG_CHAT | sm_unsilence <player> - Restores a player's ability to use voice and chat. | 34 个模式 |
| `basecommands.smx` | `sm_cancelvote` | 管理员 | ADMFLAG_VOTE | sm_cancelvote | 34 个模式 |
| `basecommands.smx` | `sm_cvar` | 管理员 | ADMFLAG_CONVARS | sm_cvar <cvar> [value] | 34 个模式 |
| `basecommands.smx` | `sm_execcfg` | 管理员 | ADMFLAG_CONFIG | sm_execcfg <filename> | 34 个模式 |
| `basecommands.smx` | `sm_kick` | 管理员 | ADMFLAG_KICK | sm_kick <#userid\|name> [reason] | 34 个模式 |
| `basecommands.smx` | `sm_map` | 管理员 | ADMFLAG_CHANGEMAP | sm_map <map> | 34 个模式 |
| `basecommands.smx` | `sm_rcon` | 管理员 | ADMFLAG_RCON | sm_rcon <args> | 34 个模式 |
| `basecommands.smx` | `sm_reloadadmins` | 管理员 | ADMFLAG_BAN | sm_reloadadmins | 34 个模式 |
| `basecommands.smx` | `sm_resetcvar` | 管理员 | ADMFLAG_CONVARS | sm_resetcvar <cvar> | 34 个模式 |
| `basecommands.smx` | `sm_revote` | 玩家/控制台 | - | - | 34 个模式 |
| `basecommands.smx` | `sm_who` | 管理员 | ADMFLAG_GENERIC | sm_who [#userid\|name] | 34 个模式 |
| `confoglcompmod.smx` | `confogl_addcvar` | 服务器配置 | - | Add a ConVar to be set by Confogl | 34 个模式 |
| `confoglcompmod.smx` | `confogl_clientsettings` | 玩家/控制台 | - | List Client settings enforced by confogl | 34 个模式 |
| `confoglcompmod.smx` | `confogl_cvardiff` | 玩家/控制台 | - | List any ConVars that have been changed from their initialized values | 34 个模式 |
| `confoglcompmod.smx` | `confogl_cvarsettings` | 玩家/控制台 | - | List all ConVars being enforced by Confogl | 34 个模式 |
| `confoglcompmod.smx` | `confogl_midata_save` | 管理员 | ADMFLAG_CONFIG | - | 34 个模式 |
| `confoglcompmod.smx` | `confogl_resetclientcvars` | 服务器配置 | - | Remove all tracked client cvars. Cannot be called during matchmode | 34 个模式 |
| `confoglcompmod.smx` | `confogl_resetcvars` | 服务器配置 | - | Resets enforced ConVars.  Cannot be used during a match! | 34 个模式 |
| `confoglcompmod.smx` | `confogl_save_location` | 管理员 | ADMFLAG_CONFIG | - | 34 个模式 |
| `confoglcompmod.smx` | `confogl_setcvars` | 服务器配置 | - | Starts enforcing ConVars that have been added. | 34 个模式 |
| `confoglcompmod.smx` | `confogl_startclientchecking` | 服务器配置 | - | Start checking and enforcing client cvars tracked by this plugin | 34 个模式 |
| `confoglcompmod.smx` | `confogl_trackclientcvar` | 服务器配置 | - | Add a Client CVar to be tracked and enforced by confogl | 34 个模式 |
| `confoglcompmod.smx` | `sm_bonus` | 玩家/控制台 | - | - | 34 个模式 |
| `confoglcompmod.smx` | `sm_fchmatch` | 管理员 | ADMFLAG_CONFIG | Forces the match to be changed | 34 个模式 |
| `confoglcompmod.smx` | `sm_fm` | 管理员 | ADMFLAG_CONFIG | Forces the game to use match mode | 34 个模式 |
| `confoglcompmod.smx` | `sm_forcechangematch` | 管理员 | ADMFLAG_CONFIG | Forces the match to be changed | 34 个模式 |
| `confoglcompmod.smx` | `sm_forcematch` | 管理员 | ADMFLAG_CONFIG | Forces the game to use match mode | 34 个模式 |
| `confoglcompmod.smx` | `sm_health` | 玩家/控制台 | - | - | 34 个模式 |
| `confoglcompmod.smx` | `sm_killlobbyres` | 管理员 | ADMFLAG_BAN | Forces the plugin to kill lobby reservation | 34 个模式 |
| `confoglcompmod.smx` | `sm_resetmatch` | 管理员 | ADMFLAG_CONFIG | Forces match mode to turn off REGRADLESS for always on or forced match | 34 个模式 |
| `extend/advertisements.smx` | `sm_advertisements_reload` | 服务器配置 | - | Reload the advertisements | 34 个模式 |
| `extend/attachments_api.smx` | `sm_attachment_qc` | 管理员 | ADMFLAG_ROOT | Parses .qc files to get model attachment names. Usage: sm_attachment_qc <folder path to .qc files>. Saves to sourcemod/data/attachments_new.cfg. | 34 个模式 |
| `extend/attachments_api.smx` | `sm_attachment_reload` | 管理员 | ADMFLAG_ROOT | Reload the attachments config: sourcemod/data/attachments_api.<game>.cfg. | 34 个模式 |
| `extend/fornite_l4d.smx` | `sm_dance` | 玩家/控制台 | - | - | 34 个模式 |
| `extend/fornite_l4d.smx` | `sm_dances` | 玩家/控制台 | - | - | 34 个模式 |
| `extend/fornite_l4d.smx` | `sm_emote` | 玩家/控制台 | - | - | 34 个模式 |
| `extend/fornite_l4d.smx` | `sm_emotes` | 玩家/控制台 | - | - | 34 个模式 |
| `extend/fornite_l4d.smx` | `sm_setdance` | 管理员 | ADMFLAG_GENERIC | [SM] Usage: sm_setemotes <#userid\|name> [Emote ID] | 34 个模式 |
| `extend/fornite_l4d.smx` | `sm_setdances` | 管理员 | ADMFLAG_GENERIC | [SM] Usage: sm_setemotes <#userid\|name> [Emote ID] | 34 个模式 |
| `extend/fornite_l4d.smx` | `sm_setemote` | 管理员 | ADMFLAG_GENERIC | [SM] Usage: sm_setemotes <#userid\|name> [Emote ID] | 34 个模式 |
| `extend/fornite_l4d.smx` | `sm_setemotes` | 管理员 | ADMFLAG_GENERIC | [SM] Usage: sm_setemotes <#userid\|name> [Emote ID] | 34 个模式 |
| `extend/global_chat.smx` | `sm_qf` | 玩家/控制台 | - | 发送全服聊天: !qf <内容> | 34 个模式 |
| `extend/global_chat.smx` | `sm_qfadmin` | 玩家/控制台 | - | 打开全服聊天接收设置菜单 | 34 个模式 |
| `extend/global_chat.smx` | `sm_qfmenu` | 玩家/控制台 | - | 打开全服聊天接收设置菜单 | 34 个模式 |
| `extend/global_chat.smx` | `sm_quanfu` | 玩家/控制台 | - | 发送全服聊天: !quanfu <内容> | 34 个模式 |
| `extend/global_chat.smx` | `sm_zd` | 玩家/控制台 | - | 发送找队友信息: !zd <内容> | 34 个模式 |
| `extend/global_chat.smx` | `sm_zdmenu` | 玩家/控制台 | - | 打开找队友提示接收设置菜单 | 34 个模式 |
| `extend/global_chat.smx` | `sm_zdy` | 玩家/控制台 | - | 发送找队友信息: !zdy <内容> | 34 个模式 |
| `extend/global_chat.smx` | `sm_zudui` | 玩家/控制台 | - | 发送找队友信息: !zudui <内容> | 34 个模式 |
| `extend/hextags.smx` | `sm_anonymous` | 管理员 | ADMFLAG_GENERIC | Toggle the user-specific tags (SteamID, admin groups/flags will be ignored). | 34 个模式 |
| `extend/hextags.smx` | `sm_ch` | 玩家/控制台 | - | Select your tag! | 34 个模式 |
| `extend/hextags.smx` | `sm_chenghao` | 玩家/控制台 | - | Select your tag! | 34 个模式 |
| `extend/hextags.smx` | `sm_cz` | 玩家/控制台 | - | Reload HexTags plugin config. | 34 个模式 |
| `extend/hextags.smx` | `sm_getteam` | 玩家/控制台 | - | Get current team name | 34 个模式 |
| `extend/hextags.smx` | `sm_reloadtags` | 管理员 | ADMFLAG_GENERIC | Reload HexTags plugin config. | 34 个模式 |
| `extend/hextags.smx` | `sm_tagslist` | 玩家/控制台 | - | Select your tag! | 34 个模式 |
| `extend/hextags.smx` | `sm_toggletags` | 管理员 | ADMFLAG_GENERIC | Toggle the visibility of your tags. | 34 个模式 |
| `extend/join.smx` | `sm_afk` | 玩家/控制台 | - | - | 34 个模式 |
| `extend/join.smx` | `sm_away` | 玩家/控制台 | - | - | 34 个模式 |
| `extend/join.smx` | `sm_donate` | 玩家/控制台 | - | - | 34 个模式 |
| `extend/join.smx` | `sm_donate_reload` | 管理员 | ADMFLAG_CONFIG | Reload donate amount config | 34 个模式 |
| `extend/join.smx` | `sm_finish` | 玩家/控制台 | - | - | 34 个模式 |
| `extend/join.smx` | `sm_inf` | 玩家/控制台 | - | - | 34 个模式 |
| `extend/join.smx` | `sm_infected` | 玩家/控制台 | - | - | 34 个模式 |
| `extend/join.smx` | `sm_ip` | 玩家/控制台 | - | - | 34 个模式 |
| `extend/join.smx` | `sm_jg` | 玩家/控制台 | - | - | 34 个模式 |
| `extend/join.smx` | `sm_join` | 玩家/控制台 | - | - | 34 个模式 |
| `extend/join.smx` | `sm_joingame` | 玩家/控制台 | - | - | 34 个模式 |
| `extend/join.smx` | `sm_joininfected` | 玩家/控制台 | - | - | 34 个模式 |
| `extend/join.smx` | `sm_restartmap` | 管理员 | ADMFLAG_ROOT | restarts map | 34 个模式 |
| `extend/join.smx` | `sm_s` | 玩家/控制台 | - | - | 34 个模式 |
| `extend/join.smx` | `sm_spec` | 玩家/控制台 | - | - | 34 个模式 |
| `extend/join.smx` | `sm_survivor` | 玩家/控制台 | - | - | 34 个模式 |
| `extend/join.smx` | `sm_team2` | 玩家/控制台 | - | - | 34 个模式 |
| `extend/join.smx` | `sm_team3` | 玩家/控制台 | - | - | 34 个模式 |
| `extend/join.smx` | `sm_wanchen` | 玩家/控制台 | - | - | 34 个模式 |
| `extend/join.smx` | `sm_wc` | 玩家/控制台 | - | - | 34 个模式 |
| `extend/join.smx` | `sm_web` | 玩家/控制台 | - | - | 34 个模式 |
| `extend/join.smx` | `sm_zombie` | 玩家/控制台 | - | - | 34 个模式 |
| `extend/l4d_hats.smx` | `sm_hat` | 玩家/控制台 | - | Displays a menu of hats allowing players to change what they are wearing. Optional args: [0 - 128 or hat name or "random"] | 34 个模式 |
| `extend/l4d_hats.smx` | `sm_hatadd` | 管理员 | ADMFLAG_ROOT | Adds specified model to the config (must be the full model path). | 34 个模式 |
| `extend/l4d_hats.smx` | `sm_hatall` | 玩家/控制台 | - | Toggles the visibility of everyone's hats. | 34 个模式 |
| `extend/l4d_hats.smx` | `sm_hatallc` | 管理员 | ADMFLAG_ROOT | Toggle the visibility of all hats on specific players. | 34 个模式 |
| `extend/l4d_hats.smx` | `sm_hatang` | 管理员 | ADMFLAG_ROOT | Shows a menu allowing you to adjust the hat angles (affects all hats/players). | 34 个模式 |
| `extend/l4d_hats.smx` | `sm_hatc` | 管理员 | ADMFLAG_ROOT | Displays a menu listing players, select one to change their hat. | 34 个模式 |
| `extend/l4d_hats.smx` | `sm_hatclient` | 管理员 | ADMFLAG_ROOT | Set a clients hat. Usage: sm_hatclient <#userid\|name> [hat name or hat index: 0-128 (MAX_HATS)]. | 34 个模式 |
| `extend/l4d_hats.smx` | `sm_hatdel` | 管理员 | ADMFLAG_ROOT | Removes a model from the config (either by index or partial name matching). | 34 个模式 |
| `extend/l4d_hats.smx` | `sm_hatlist` | 管理员 | ADMFLAG_ROOT | Displays a list of all the hat models (for use with sm_hatdel). | 34 个模式 |
| `extend/l4d_hats.smx` | `sm_hatload` | 管理员 | ADMFLAG_ROOT | Changes all players hats to the one you have. | 34 个模式 |
| `extend/l4d_hats.smx` | `sm_hatoff` | 玩家/控制台 | - | Toggle to turn on or off the ability of wearing hats. | 34 个模式 |
| `extend/l4d_hats.smx` | `sm_hatoffc` | 管理员 | ADMFLAG_ROOT | Toggle the ability of wearing hats on specific players. | 34 个模式 |
| `extend/l4d_hats.smx` | `sm_hatpos` | 管理员 | ADMFLAG_ROOT | Shows a menu allowing you to adjust the hat position (affects all hats/players). | 34 个模式 |
| `extend/l4d_hats.smx` | `sm_hatrand` | 管理员 | ADMFLAG_ROOT | Randomizes all players hats. | 34 个模式 |
| `extend/l4d_hats.smx` | `sm_hatrandom` | 管理员 | ADMFLAG_ROOT | Randomizes all players hats. | 34 个模式 |
| `extend/l4d_hats.smx` | `sm_hats` | 玩家/控制台 | - | Displays a menu to customize various settings for hats. | 34 个模式 |
| `extend/l4d_hats.smx` | `sm_hatsave` | 管理员 | ADMFLAG_ROOT | Saves the hat position and angels to the hat config. | 34 个模式 |
| `extend/l4d_hats.smx` | `sm_hatshow` | 玩家/控制台 | - | Toggle to see or hide your own hat. Applies to first person view or third person using the optional command argument "tp" e.g. "sm_hatshow tp" | 34 个模式 |
| `extend/l4d_hats.smx` | `sm_hatshowoff` | 玩家/控制台 | - | Hide your own hat. Applies to first person view or third person using the optional command argument "tp" e.g. "sm_hatshowoff tp" | 34 个模式 |
| `extend/l4d_hats.smx` | `sm_hatshowon` | 玩家/控制台 | - | See your own hat. Applies to first person view or third person using the optional command argument "tp" e.g. "sm_hatshowon tp" | 34 个模式 |
| `extend/l4d_hats.smx` | `sm_hatsize` | 管理员 | ADMFLAG_ROOT | Shows a menu allowing you to adjust the hat size (affects all hats/players). | 34 个模式 |
| `extend/l4d_hats.smx` | `sm_hatview` | 玩家/控制台 | - | Toggle to see or hide your own hat. Applies to first person view or third person using the optional command argument "tp" e.g. "sm_hatview tp" | 34 个模式 |
| `extend/l4d_player_count_unload_mode.smx` | `sm_peakstatus` | 管理员 | ADMFLAG_GENERIC | 查看当前全服高峰期判定状态 | 34 个模式 |
| `extend/l4d_stats.smx` | `say` | 聊天钩子 | - | 监听聊天输入；通常用于解析聊天触发或屏蔽命令回显 | 34 个模式 |
| `extend/l4d_stats.smx` | `say_team` | 聊天钩子 | - | 监听聊天输入；通常用于解析聊天触发或屏蔽命令回显 | 34 个模式 |
| `extend/l4d_stats.smx` | `sm_maptimes` | 玩家/控制台 | - | - | 34 个模式 |
| `extend/l4d_stats.smx` | `sm_nextrank` | 玩家/控制台 | - | - | 34 个模式 |
| `extend/l4d_stats.smx` | `sm_qtop10` | 玩家/控制台 | - | - | 34 个模式 |
| `extend/l4d_stats.smx` | `sm_quartertop10` | 玩家/控制台 | - | - | 34 个模式 |
| `extend/l4d_stats.smx` | `sm_rank` | 玩家/控制台 | - | - | 34 个模式 |
| `extend/l4d_stats.smx` | `sm_rank_motd` | 管理员 | ADMFLAG_GENERIC | Set Message Of The Day | 34 个模式 |
| `extend/l4d_stats.smx` | `sm_rankmenu` | 玩家/控制台 | - | - | 34 个模式 |
| `extend/l4d_stats.smx` | `sm_rankmute` | 玩家/控制台 | - | - | 34 个模式 |
| `extend/l4d_stats.smx` | `sm_rankmutetoggle` | 玩家/控制台 | - | - | 34 个模式 |
| `extend/l4d_stats.smx` | `sm_rankvote` | 玩家/控制台 | - | - | 34 个模式 |
| `extend/l4d_stats.smx` | `sm_resetscore` | 玩家/控制台 | - | - | 34 个模式 |
| `extend/l4d_stats.smx` | `sm_showmaptimes` | 玩家/控制台 | - | - | 34 个模式 |
| `extend/l4d_stats.smx` | `sm_showmotd` | 玩家/控制台 | - | - | 34 个模式 |
| `extend/l4d_stats.smx` | `sm_showppm` | 玩家/控制台 | - | - | 34 个模式 |
| `extend/l4d_stats.smx` | `sm_showrank` | 玩家/控制台 | - | - | 34 个模式 |
| `extend/l4d_stats.smx` | `sm_showtimer` | 玩家/控制台 | - | - | 34 个模式 |
| `extend/l4d_stats.smx` | `sm_timedmaps` | 玩家/控制台 | - | - | 34 个模式 |
| `extend/l4d_stats.smx` | `sm_top10` | 玩家/控制台 | - | - | 34 个模式 |
| `extend/l4d_stats.smx` | `sm_top10ppm` | 玩家/控制台 | - | - | 34 个模式 |
| `extend/l4d_stats.smx` | `sm_top10q` | 玩家/控制台 | - | - | 34 个模式 |
| `extend/l4d2_blacklist.smx` | `sm_blmenu` | 玩家/控制台 | - | 打开黑名单菜单 | 34 个模式 |
| `extend/l4d2_blacklist.smx` | `sm_block` | 玩家/控制台 | - | 屏蔽某人: sm_block <#userid\|steam64\|名字> | 34 个模式 |
| `extend/l4d2_blacklist.smx` | `sm_blocklimit` | 玩家/控制台 | - | 查看你的屏蔽上限 | 34 个模式 |
| `extend/l4d2_blacklist.smx` | `sm_blocklist` | 玩家/控制台 | - | 查看屏蔽列表: sm_blocklist [#userid\|steam64\|名字] | 34 个模式 |
| `extend/l4d2_blacklist.smx` | `sm_unblock` | 玩家/控制台 | - | 解除屏蔽: sm_unblock <#userid\|steam64\|名字> | 34 个模式 |
| `extend/l4d2_scripted_hud.smx` | `sm_l4d2_scripted_hud_reload_data` | 管理员 | ADMFLAG_ROOT | Reload the HUD texts set in the data file. | 34 个模式 |
| `extend/l4d2_scripted_hud.smx` | `sm_print_cvars_l4d2_scripted_hud` | 管理员 | ADMFLAG_ROOT | Print the plugin related cvars and their respective values to the console. | 34 个模式 |
| `extend/l4d2_scripted_hud.smx` | `sm_spechudoff` | 玩家/控制台 | - | 打开spechud | 34 个模式 |
| `extend/l4d2_scripted_hud.smx` | `sm_spechudon` | 玩家/控制台 | - | 打开spechud | 34 个模式 |
| `extend/rpg.smx` | `sm_ammo` | 玩家/控制台 | - | 快速买子弹 | 34 个模式 |
| `extend/rpg.smx` | `sm_applytags` | 玩家/控制台 | - | 佩戴自定义称号 | 34 个模式 |
| `extend/rpg.smx` | `sm_buy` | 玩家/控制台 | - | 打开购买菜单(只能在游戏中) | 34 个模式 |
| `extend/rpg.smx` | `sm_chr` | 玩家/控制台 | - | 快速买一把二代单喷 | 34 个模式 |
| `extend/rpg.smx` | `sm_pen` | 玩家/控制台 | - | 快速随机买一把单喷 | 34 个模式 |
| `extend/rpg.smx` | `sm_pill` | 玩家/控制台 | - | 快速买药 | 34 个模式 |
| `extend/rpg.smx` | `sm_pum` | 玩家/控制台 | - | 快速买一把一代单喷 | 34 个模式 |
| `extend/rpg.smx` | `sm_rpg` | 玩家/控制台 | - | 打开购买菜单(只能在游戏中) | 34 个模式 |
| `extend/rpg.smx` | `sm_rpginfo` | 管理员 | ADMFLAG_ROOT | 输出rpg人物信息 | 34 个模式 |
| `extend/rpg.smx` | `sm_setch` | 玩家/控制台 | - | 设置自定义称号 | 34 个模式 |
| `extend/rpg.smx` | `sm_smg` | 玩家/控制台 | - | 快速买smg | 34 个模式 |
| `extend/rpg.smx` | `sm_unsetch` | 玩家/控制台 | - | 设置自定义称号 | 34 个模式 |
| `extend/rpg.smx` | `sm_uzi` | 玩家/控制台 | - | 快速买uzi | 34 个模式 |
| `extend/rygive.smx` | `sm_rygive` | 管理员 | ADMFLAG_CHAT | rygive | 34 个模式 |
| `extend/sbpp_checker.smx` | `sb_reload` | 管理员 | ADMFLAG_RCON | Reload sourcebans config and ban reason menu options | 34 个模式 |
| `extend/sbpp_checker.smx` | `sm_listbans` | 管理员 | ADMFLAG_BAN | - | 34 个模式 |
| `extend/sbpp_checker.smx` | `sm_listcomms` | 管理员 | ADMFLAG_BAN | - | 34 个模式 |
| `extend/sbpp_comms.smx` | `sc_fw_block` | 服务器配置 | - | Blocking player comms by command from sourceban web site | 34 个模式 |
| `extend/sbpp_comms.smx` | `sc_fw_ungag` | 服务器配置 | - | Ungagging player by command from sourceban web site | 34 个模式 |
| `extend/sbpp_comms.smx` | `sc_fw_unmute` | 服务器配置 | - | Unmuting player by command from sourceban web site | 34 个模式 |
| `extend/sbpp_comms.smx` | `sm_comms` | 玩家/控制台 | - | Shows current player communications status | 34 个模式 |
| `extend/sbpp_main.smx` | `say` | 聊天钩子 | - | 监听聊天输入；通常用于解析聊天触发或屏蔽命令回显 | 34 个模式 |
| `extend/sbpp_main.smx` | `say_team` | 聊天钩子 | - | 监听聊天输入；通常用于解析聊天触发或屏蔽命令回显 | 34 个模式 |
| `extend/sbpp_main.smx` | `sb_reload` | 管理员 | ADMFLAG_RCON | Reload sourcebans config and ban reason menu options | 34 个模式 |
| `extend/sbpp_main.smx` | `sm_addban` | 管理员 | ADMFLAG_RCON | sm_addban <time> <steamid> [reason] | 34 个模式 |
| `extend/sbpp_main.smx` | `sm_ban` | 管理员 | ADMFLAG_BAN | sm_ban <#userid\|name> <minutes\|0> [reason] | 34 个模式 |
| `extend/sbpp_main.smx` | `sm_banip` | 管理员 | ADMFLAG_BAN | sm_banip <ip\|#userid\|name> <time> [reason] | 34 个模式 |
| `extend/sbpp_main.smx` | `sm_rehash` | 服务器配置 | - | Reload SQL admins | 34 个模式 |
| `extend/sbpp_main.smx` | `sm_unban` | 管理员 | ADMFLAG_UNBAN | sm_unban <steamid\|ip> [reason] | 34 个模式 |
| `extend/sbpp_report.smx` | `sm_report` | 玩家/控制台 | - | Initialize Report | 34 个模式 |
| `extend/sbpp_sleuth.smx` | `sm_sleuth_reloadlist` | 管理员 | ADMFLAG_ROOT | - | 34 个模式 |
| `extend/SpecListener.smx` | `sm_listen` | 玩家/控制台 | - | - | 34 个模式 |
| `extend/updater.smx` | `sm_updater_check` | 管理员 | ADMFLAG_RCON | Updater - Forces Updater to check for updates. | 34 个模式 |
| `extend/updater.smx` | `sm_updater_forcecheck` | 管理员 | ADMFLAG_RCON | Updater - Forces updater to check for updates without limits | 34 个模式 |
| `extend/updater.smx` | `sm_updater_status` | 管理员 | ADMFLAG_RCON | Updater - View the status of Updater. | 34 个模式 |
| `extend/veterans.smx` | `sm_clear` | 管理员 | ADMFLAG_GENERIC | Clear cache | 34 个模式 |
| `extend/veterans.smx` | `sm_time` | 玩家/控制台 | - | 显示时间 | 34 个模式 |
| `extend/veterans.smx` | `sm_timeall` | 管理员 | ADMFLAG_GENERIC | 显示所有玩家时间 | 34 个模式 |
| `extend/veterans.smx` | `sm_veterans_exclude` | 管理员 | ADMFLAG_GENERIC | Exludes a user from veterans plugin | 34 个模式 |
| `extend/veterans.smx` | `sm_veterans_include` | 管理员 | ADMFLAG_GENERIC | Includes an already excluded user from veterans plugin | 34 个模式 |
| `extend/vote.smx` | `sm_cancelvote` | 管理员 | ADMFLAG_GENERIC | 管理员终止此次投票 | 34 个模式 |
| `extend/vote.smx` | `sm_vote` | 玩家/控制台 | - | - | 34 个模式 |
| `extend/vote.smx` | `sm_voteban` | 玩家/控制台 | - | - | 34 个模式 |
| `extend/vote.smx` | `sm_votekick` | 玩家/控制台 | - | - | 34 个模式 |
| `fixes/l4d2_spit_spread_patch.smx` | `spit_spread_saferoom_except` | 服务器配置 | - | - | 34 个模式 |
| `fixes/sv_consistency_fix.smx` | `sm_consistencycheck` | 管理员 | ADMFLAG_RCON | Performs a consistency check on all players. | 25 个模式 |
| `funcommands.smx` | `sm_beacon` | 管理员 | ADMFLAG_SLAY | sm_beacon <#userid\|name> [0/1] | 34 个模式 |
| `funcommands.smx` | `sm_blind` | 管理员 | ADMFLAG_SLAY | sm_blind <#userid\|name> [amount] - Leave amount off to reset. | 34 个模式 |
| `funcommands.smx` | `sm_burn` | 管理员 | ADMFLAG_SLAY | sm_burn <#userid\|name> [time] | 34 个模式 |
| `funcommands.smx` | `sm_drug` | 管理员 | ADMFLAG_SLAY | sm_drug <#userid\|name> [0/1] | 34 个模式 |
| `funcommands.smx` | `sm_firebomb` | 管理员 | ADMFLAG_SLAY | sm_firebomb <#userid\|name> [0/1] | 34 个模式 |
| `funcommands.smx` | `sm_freeze` | 管理员 | ADMFLAG_SLAY | sm_freeze <#userid\|name> [time] | 34 个模式 |
| `funcommands.smx` | `sm_freezebomb` | 管理员 | ADMFLAG_SLAY | sm_freezebomb <#userid\|name> [0/1] | 34 个模式 |
| `funcommands.smx` | `sm_gravity` | 管理员 | ADMFLAG_SLAY | sm_gravity <#userid\|name> [amount] - Leave amount off to reset. Amount is 0.0 through 5.0 | 34 个模式 |
| `funcommands.smx` | `sm_noclip` | 管理员 | ADMFLAG_SLAY\|ADMFLAG_CHEATS | sm_noclip <#userid\|name> | 34 个模式 |
| `funcommands.smx` | `sm_timebomb` | 管理员 | ADMFLAG_SLAY | sm_timebomb <#userid\|name> [0/1] | 34 个模式 |
| `l4d2_lobby_match_manager.smx` | `sm_lobby_set` | 管理员 | ADMFLAG_ROOT | - | 34 个模式 |
| `l4d2_lobby_match_manager.smx` | `sm_lobby_status` | 管理员 | ADMFLAG_ROOT | - | 34 个模式 |
| `l4d2_map_vote.smx` | `sm_chmap` | 玩家/控制台 | - | - | 34 个模式 |
| `l4d2_map_vote.smx` | `sm_mapnext` | 玩家/控制台 | - | - | 34 个模式 |
| `l4d2_map_vote.smx` | `sm_maps` | 玩家/控制台 | - | - | 34 个模式 |
| `l4d2_map_vote.smx` | `sm_mapvote` | 玩家/控制台 | - | - | 34 个模式 |
| `l4d2_map_vote.smx` | `sm_missions_export` | 管理员 | ADMFLAG_ROOT | - | 34 个模式 |
| `l4d2_map_vote.smx` | `sm_reload_vpk` | 管理员 | ADMFLAG_ROOT | - | 34 个模式 |
| `l4d2_map_vote.smx` | `sm_update_vpk` | 管理员 | ADMFLAG_ROOT | - | 34 个模式 |
| `l4d2_map_vote.smx` | `sm_v3` | 玩家/控制台 | - | - | 34 个模式 |
| `l4d2_map_vote.smx` | `sm_votemap` | 玩家/控制台 | - | - | 34 个模式 |
| `l4d2_map_vote.smx` | `sm_votenext` | 玩家/控制台 | - | - | 34 个模式 |
| `left4dhooks.smx` | `sm_l4dd_detours` | 管理员 | ADMFLAG_ROOT | Lists the currently active forwards and the plugins using them. | 34 个模式 |
| `left4dhooks.smx` | `sm_l4dd_reload` | 管理员 | ADMFLAG_ROOT | Reloads the detour hooks, enabling or disabling depending if they're required by other plugins. | 34 个模式 |
| `left4dhooks.smx` | `sm_l4dd_unreserve` | 管理员 | ADMFLAG_ROOT | Removes lobby reservation. | 34 个模式 |
| `left4dhooks.smx` | `sm_l4dhooks_detours` | 管理员 | ADMFLAG_ROOT | Lists the currently active forwards and the plugins using them. | 34 个模式 |
| `left4dhooks.smx` | `sm_l4dhooks_reload` | 管理员 | ADMFLAG_ROOT | Reloads the detour hooks, enabling or disabling depending if they're required by other plugins. | 34 个模式 |
| `linux_auto_restart.smx` | `sm_restart` | 管理员 | ADMFLAG_ROOT | - | 34 个模式 |
| `map_changer.smx` | `sm_setnext` | 管理员 | ADMFLAG_RCON | 设置下一张地图 | 34 个模式 |
| `match_vote.smx` | `sm_chmatch` | 玩家/控制台 | - | - | 34 个模式 |
| `match_vote.smx` | `sm_match` | 玩家/控制台 | - | - | 34 个模式 |
| `match_vote.smx` | `sm_rmatch` | 玩家/控制台 | - | - | 34 个模式 |
| `optional/1v1_skeetstats.smx` | `say` | 聊天钩子 | - | 监听聊天输入；通常用于解析聊天触发或屏蔽命令回显 | `alone`, `amrv1v1`, `deadman`, `eq1v1`, `hunters`, `zh1v1`, `zm1v1` |
| `optional/1v1_skeetstats.smx` | `say_team` | 聊天钩子 | - | 监听聊天输入；通常用于解析聊天触发或屏蔽命令回显 | `alone`, `amrv1v1`, `deadman`, `eq1v1`, `hunters`, `zh1v1`, `zm1v1` |
| `optional/1v1_skeetstats.smx` | `sm_skeets` | 玩家/控制台 | - | Prints the current skeetstats. | `alone`, `amrv1v1`, `deadman`, `eq1v1`, `hunters`, `zh1v1`, `zm1v1` |
| `optional/8ball.smx` | `sm_8ball` | 玩家/控制台 | - | - | `nextmod`, `nextmod1v1`, `nextmod2v2`, `nextmod3v3` |
| `optional/boomer_horde_equalizer_refactored.smx` | `boomer_horde_amount` | 服务器配置 | - | Usage: boomer_horde_amount <amount of boomed survivors> <amount of horde to spawn> | `annehappy`, `annehappy_hardcore`, `annehappy_shotgun`, `coop`, `realism`, `zm1v1`, `zm2v2`, `zm3v3`, `zonemod` |
| `optional/caster_assister.smx` | `sm_decrease_specspeed` | 玩家/控制台 | - | - | 25 个模式 |
| `optional/caster_assister.smx` | `sm_increase_specspeed` | 玩家/控制台 | - | - | 25 个模式 |
| `optional/caster_assister.smx` | `sm_set_specspeed_increment` | 玩家/控制台 | - | - | 25 个模式 |
| `optional/caster_assister.smx` | `sm_set_specspeed_multi` | 玩家/控制台 | - | - | 25 个模式 |
| `optional/caster_assister.smx` | `sm_set_vertical_increment` | 玩家/控制台 | - | - | 25 个模式 |
| `optional/caster_system.smx` | `sm_add_caster_id` | 管理员 | ADMFLAG_BAN | Used for adding casters to the whitelist -- i.e. who's allowed to self-register as a caster | 25 个模式 |
| `optional/caster_system.smx` | `sm_cast` | 玩家/控制台 | - | Registers the calling player as a caster | 25 个模式 |
| `optional/caster_system.smx` | `sm_caster` | 管理员 | ADMFLAG_BAN | Registers a player as a caster | 25 个模式 |
| `optional/caster_system.smx` | `sm_kickspecs` | 玩家/控制台 | - | Let's vote to kick those Spectators! | 25 个模式 |
| `optional/caster_system.smx` | `sm_notcasting` | 玩家/控制台 | - | Deregister yourself as a caster or allow admins to deregister other players | 25 个模式 |
| `optional/caster_system.smx` | `sm_printcasters` | 管理员 | ADMFLAG_BAN | Used for print casters in the whitelist | 25 个模式 |
| `optional/caster_system.smx` | `sm_remove_caster_id` | 管理员 | ADMFLAG_BAN | Used for removing casters to the whitelist -- i.e. who's allowed to self-register as a caster | 25 个模式 |
| `optional/caster_system.smx` | `sm_resetcasters` | 管理员 | ADMFLAG_BAN | Used to reset casters between matches.  This should be in confogl_off.cfg or equivalent for your system | 25 个模式 |
| `optional/caster_system.smx` | `sm_uncast` | 玩家/控制台 | - | Deregister yourself as a caster or allow admins to deregister other players | 25 个模式 |
| `optional/cfg_motd.smx` | `sm_cfg` | 玩家/控制台 | - | Show a MOTD describing the current config | 19 个模式 |
| `optional/cfg_motd.smx` | `sm_changelog` | 玩家/控制台 | - | Show a MOTD describing the current config | 19 个模式 |
| `optional/changelog.smx` | `sm_changelog` | 玩家/控制台 | - | - | `nextmod`, `nextmod1v1`, `nextmod2v2`, `nextmod3v3` |
| `optional/checkpoint-rage-control.smx` | `saferoom_frustration_tickdown` | 服务器配置 | - | - | 25 个模式 |
| `optional/coinflip.smx` | `sm_cf` | 玩家/控制台 | - | - | 25 个模式 |
| `optional/coinflip.smx` | `sm_coinflip` | 玩家/控制台 | - | - | 25 个模式 |
| `optional/coinflip.smx` | `sm_flip` | 玩家/控制台 | - | - | 25 个模式 |
| `optional/coinflip.smx` | `sm_picknumber` | 玩家/控制台 | - | - | 25 个模式 |
| `optional/coinflip.smx` | `sm_roll` | 玩家/控制台 | - | - | 25 个模式 |
| `optional/current.smx` | `sm_cur` | 玩家/控制台 | - | - | 34 个模式 |
| `optional/current.smx` | `sm_current` | 玩家/控制台 | - | - | 34 个模式 |
| `optional/eq_finale_tanks.smx` | `tank_map_flow_and_second_event` | 服务器配置 | - | - | 30 个模式 |
| `optional/eq_finale_tanks.smx` | `tank_map_only_first_event` | 服务器配置 | - | - | 30 个模式 |
| `optional/finale_tank_blocker.smx` | `finale_tank_default` | 服务器配置 | - | - | `pmelite` |
| `optional/ghost_hurt.smx` | `sm_reset_ghost_hurt` | 服务器配置 | - | Used to reset trigger_hurt_ghost between matches.  This should be in confogl_off.cfg or equivalent for your system | 11 个模式 |
| `optional/holdout_bonus.smx` | `sm_hbonus` | 玩家/控制台 | - | Shows current holdout bonus | `pmelite` |
| `optional/l4d_boss_percent.smx` | `sm_boss` | 玩家/控制台 | - | - | 32 个模式 |
| `optional/l4d_boss_percent.smx` | `sm_tank` | 玩家/控制台 | - | - | 32 个模式 |
| `optional/l4d_boss_percent.smx` | `sm_witch` | 玩家/控制台 | - | - | 32 个模式 |
| `optional/l4d_boss_vote.smx` | `sm_bossvote` | 玩家/控制台 | - | - | 25 个模式 |
| `optional/l4d_boss_vote.smx` | `sm_ftank` | 管理员 | ADMFLAG_BAN | - | 25 个模式 |
| `optional/l4d_boss_vote.smx` | `sm_fwitch` | 管理员 | ADMFLAG_BAN | - | 25 个模式 |
| `optional/l4d_boss_vote.smx` | `sm_voteboss` | 玩家/控制台 | - | - | 25 个模式 |
| `optional/l4d_tank_control_eq.smx` | `sm_boss` | 玩家/控制台 | - | Shows who is becoming the tank. | 25 个模式 |
| `optional/l4d_tank_control_eq.smx` | `sm_givetank` | 管理员 | ADMFLAG_SLAY | Gives the tank to a selected player | 25 个模式 |
| `optional/l4d_tank_control_eq.smx` | `sm_tank` | 玩家/控制台 | - | Shows who is becoming the tank. | 25 个模式 |
| `optional/l4d_tank_control_eq.smx` | `sm_tankshuffle` | 管理员 | ADMFLAG_SLAY | Re-picks at random someone to become tank. | 25 个模式 |
| `optional/l4d_tank_control_eq.smx` | `sm_witch` | 玩家/控制台 | - | Shows who is becoming the tank. | 25 个模式 |
| `optional/l4d_weapon_limits.smx` | `l4d_wlimits_add` | 服务器配置 | - | Add a weapon limit | 23 个模式 |
| `optional/l4d_weapon_limits.smx` | `l4d_wlimits_clear` | 服务器配置 | - | Clears all weapon limits (limits must be locked to be cleared) | 23 个模式 |
| `optional/l4d_weapon_limits.smx` | `l4d_wlimits_lock` | 服务器配置 | - | Locks the limits to improve search speeds | 23 个模式 |
| `optional/l4d2_ghost_warp.smx` | `sm_warp` | 玩家/控制台 | - | - | 25 个模式 |
| `optional/l4d2_ghost_warp.smx` | `sm_warpto` | 玩家/控制台 | - | - | 25 个模式 |
| `optional/l4d2_ghost_warp.smx` | `sm_warptosurvivor` | 玩家/控制台 | - | - | 25 个模式 |
| `optional/l4d2_hybrid_scoremod_zone.smx` | `sm_bonus` | 玩家/控制台 | - | - | 14 个模式 |
| `optional/l4d2_hybrid_scoremod_zone.smx` | `sm_damage` | 玩家/控制台 | - | - | 14 个模式 |
| `optional/l4d2_hybrid_scoremod_zone.smx` | `sm_health` | 玩家/控制台 | - | - | 14 个模式 |
| `optional/l4d2_hybrid_scoremod_zone.smx` | `sm_mapinfo` | 玩家/控制台 | - | - | 14 个模式 |
| `optional/l4d2_hybrid_scoremod.smx` | `sm_bonus` | 玩家/控制台 | - | - | `acemodrv`, `amrv1v1`, `amrv2v2`, `amrv3v3`, `eq`, `eq1v1`, `eq2v2`, `eq3v3` |
| `optional/l4d2_hybrid_scoremod.smx` | `sm_damage` | 玩家/控制台 | - | - | `acemodrv`, `amrv1v1`, `amrv2v2`, `amrv3v3`, `eq`, `eq1v1`, `eq2v2`, `eq3v3` |
| `optional/l4d2_hybrid_scoremod.smx` | `sm_health` | 玩家/控制台 | - | - | `acemodrv`, `amrv1v1`, `amrv2v2`, `amrv3v3`, `eq`, `eq1v1`, `eq2v2`, `eq3v3` |
| `optional/l4d2_hybrid_scoremod.smx` | `sm_mapinfo` | 玩家/控制台 | - | - | `acemodrv`, `amrv1v1`, `amrv2v2`, `amrv3v3`, `eq`, `eq1v1`, `eq2v2`, `eq3v3` |
| `optional/l4d2_ledgeblock.smx` | `ledge_block_square` | 服务器配置 | - | - | `zm1v1`, `zm2v2`, `zm3v3`, `zonemod` |
| `optional/l4d2_ledgeblock.smx` | `ledge_remove_block_square` | 服务器配置 | - | - | `zm1v1`, `zm2v2`, `zm3v3`, `zonemod` |
| `optional/l4d2_map_transitions.smx` | `sm_add_map_transition` | 服务器配置 | - | - | 25 个模式 |
| `optional/l4d2_nobhaps.smx` | `sm_check_bhop` | 玩家/控制台 | - | - | 24 个模式 |
| `optional/l4d2_penalty_bonus.smx` | `sm_bonus` | 玩家/控制台 | - | Prints the current extra bonus(es) for this round. | `deadman`, `pmelite` |
| `optional/l4d2_pickup.smx` | `sm_primary` | 玩家/控制台 | - | - | 29 个模式 |
| `optional/l4d2_pickup.smx` | `sm_secondary` | 玩家/控制台 | - | - | 29 个模式 |
| `optional/l4d2_playstats.smx` | `sm_acc` | 玩家/控制台 | - | Prints accuracy stats for survivors | 28 个模式 |
| `optional/l4d2_playstats.smx` | `sm_ff` | 玩家/控制台 | - | Prints friendly fire stats stats | 28 个模式 |
| `optional/l4d2_playstats.smx` | `sm_mvp` | 玩家/控制台 | - | Prints MVP stats for survivors | 28 个模式 |
| `optional/l4d2_playstats.smx` | `sm_skill` | 玩家/控制台 | - | Prints special skills stats for survivors | 28 个模式 |
| `optional/l4d2_playstats.smx` | `sm_stats` | 玩家/控制台 | - | Prints stats for survivors | 28 个模式 |
| `optional/l4d2_playstats.smx` | `sm_stats_auto` | 玩家/控制台 | - | Sets client-side preference for automatic stats-print at end of round | 28 个模式 |
| `optional/l4d2_playstats.smx` | `statsreset` | 管理员 | ADMFLAG_CHANGEMAP | Resets the statistics. Admins only. | 28 个模式 |
| `optional/l4d2_scoremod.smx` | `say` | 聊天钩子 | - | 监听聊天输入；通常用于解析聊天触发或屏蔽命令回显 | `apex`, `deadman`, `pmelite` |
| `optional/l4d2_scoremod.smx` | `say_team` | 聊天钩子 | - | 监听聊天输入；通常用于解析聊天触发或屏蔽命令回显 | `apex`, `deadman`, `pmelite` |
| `optional/l4d2_scoremod.smx` | `sm_health` | 玩家/控制台 | - | - | `apex`, `deadman`, `pmelite` |
| `optional/l4d2_setscores.smx` | `sm_setscores` | 玩家/控制台 | - | sm_setscores <survivor score> <infected score> | 25 个模式 |
| `optional/l4d2_sounds_blocker.smx` | `ssb_custom_path` | 服务器配置 | - | - | `nextmod`, `nextmod1v1`, `nextmod2v2`, `nextmod3v3` |
| `optional/l4d2_sounds_blocker.smx` | `ssb_whitelist_path` | 服务器配置 | - | - | `nextmod`, `nextmod1v1`, `nextmod2v2`, `nextmod3v3` |
| `optional/l4d2_spitblock.smx` | `spit_block_square` | 服务器配置 | - | - | 25 个模式 |
| `optional/l4d2_spitblock.smx` | `spit_remove_block_square` | 服务器配置 | - | - | 25 个模式 |
| `optional/l4d2_tank_attack_control.smx` | `sm_overhand` | 玩家/控制台 | - | - | 32 个模式 |
| `optional/l4d2_tank_attack_control.smx` | `sm_overonehand` | 玩家/控制台 | - | - | 32 个模式 |
| `optional/l4d2_tank_attack_control.smx` | `sm_underhand` | 玩家/控制台 | - | - | 32 个模式 |
| `optional/l4d2_uncommon_blocker.smx` | `sm_uncinfblock_check` | 管理员 | ADMFLAG_GENERIC | - | 28 个模式 |
| `optional/l4d2_weapon_attributes.smx` | `sm_weapon` | 服务器配置 | - | - | 34 个模式 |
| `optional/l4d2_weapon_attributes.smx` | `sm_weapon_attributes` | 玩家/控制台 | - | - | 34 个模式 |
| `optional/l4d2_weapon_attributes.smx` | `sm_weapon_attributes_reset` | 服务器配置 | - | - | 34 个模式 |
| `optional/l4d2_weapon_attributes.smx` | `sm_weaponstats` | 玩家/控制台 | - | - | 34 个模式 |
| `optional/l4d2_weaponrules.smx` | `l4d2_addweaponrule` | 服务器配置 | - | - | 32 个模式 |
| `optional/l4d2_weaponrules.smx` | `l4d2_resetweaponrules` | 服务器配置 | - | - | 32 个模式 |
| `optional/l4d2lib.smx` | `confogl_midata_save` | 管理员 | ADMFLAG_CONFIG | - | 34 个模式 |
| `optional/l4d2lib.smx` | `confogl_save_location` | 管理员 | ADMFLAG_CONFIG | - | 34 个模式 |
| `optional/lerpmonitor.smx` | `sm_lerps` | 玩家/控制台 | - | List the Lerps of all players in game | 34 个模式 |
| `optional/MeleeInTheSafeRoom.smx` | `sm_melee` | 管理员 | ADMFLAG_KICK | Lists all melee weapons spawnable in current campaign | 13 个模式 |
| `optional/network_quality_hint.smx` | `sm_loss` | 玩家/控制台 | - | Show your network status. | 32 个模式 |
| `optional/network_quality_hint.smx` | `sm_net` | 玩家/控制台 | - | Show your network status. | 32 个模式 |
| `optional/network_quality_hint.smx` | `sm_ping` | 玩家/控制台 | - | Show your network status. | 32 个模式 |
| `optional/panel_text.smx` | `sm_addreadystring` | 服务器配置 | - | Sets the string to add to the ready-up panel | 25 个模式 |
| `optional/panel_text.smx` | `sm_lockstrings` | 服务器配置 | - | Locks the strings | 25 个模式 |
| `optional/panel_text.smx` | `sm_resetstringcount` | 服务器配置 | - | Resets the string count | 25 个模式 |
| `optional/pause.smx` | `sm_forcepause` | 管理员 | ADMFLAG_BAN | Pauses the game and only allows admins to unpause | 32 个模式 |
| `optional/pause.smx` | `sm_forceunpause` | 管理员 | ADMFLAG_BAN | Unpauses the game regardless of team ready status.  Must be used to unpause admin pauses | 32 个模式 |
| `optional/pause.smx` | `sm_hide` | 玩家/控制台 | - | Shows a hidden pause panel | 32 个模式 |
| `optional/pause.smx` | `sm_pause` | 玩家/控制台 | - | Pauses the game | 32 个模式 |
| `optional/pause.smx` | `sm_ready` | 玩家/控制台 | - | Marks your team as ready for an unpause | 32 个模式 |
| `optional/pause.smx` | `sm_s` | 玩家/控制台 | - | Moves you to the spectator team | 32 个模式 |
| `optional/pause.smx` | `sm_show` | 玩家/控制台 | - | Hides the pause panel so other menus can be seen | 32 个模式 |
| `optional/pause.smx` | `sm_spec` | 玩家/控制台 | - | Moves you to the spectator team | 32 个模式 |
| `optional/pause.smx` | `sm_spectate` | 玩家/控制台 | - | Moves you to the spectator team | 32 个模式 |
| `optional/pause.smx` | `sm_toggleready` | 玩家/控制台 | - | Toggles your team's ready status | 32 个模式 |
| `optional/pause.smx` | `sm_unpause` | 玩家/控制台 | - | Marks your team as ready for an unpause | 32 个模式 |
| `optional/pause.smx` | `sm_unready` | 玩家/控制台 | - | Marks your team as ready for an unpause | 32 个模式 |
| `optional/playermanagement.smx` | `sm_fixbots` | 管理员 | ADMFLAG_BAN | sm_fixbots - Spawns survivor bots to match survivor_limit | 27 个模式 |
| `optional/playermanagement.smx` | `sm_s` | 玩家/控制台 | - | Moves you to the spectator team | 27 个模式 |
| `optional/playermanagement.smx` | `sm_spec` | 玩家/控制台 | - | Moves you to the spectator team | 27 个模式 |
| `optional/playermanagement.smx` | `sm_spectate` | 玩家/控制台 | - | Moves you to the spectator team | 27 个模式 |
| `optional/playermanagement.smx` | `sm_swap` | 管理员 | ADMFLAG_KICK | sm_swap <player1> [player2] ... [playerN] - swap all listed players to opposite teams | 27 个模式 |
| `optional/playermanagement.smx` | `sm_swapteams` | 管理员 | ADMFLAG_KICK | sm_swapteams - swap the players between both teams | 27 个模式 |
| `optional/playermanagement.smx` | `sm_swapto` | 管理员 | ADMFLAG_KICK | sm_swapto [force] <teamnum> <player1> [player2] ... [playerN] - swap all listed players to <teamnum> (1,2, or 3) | 27 个模式 |
| `optional/predictable_unloader.smx` | `pred_unload_plugins` | 服务器配置 | - | Unload Plugins! | 34 个模式 |
| `optional/ratemonitor.smx` | `sm_rates` | 玩家/控制台 | - | List netsettings of all players in game | 34 个模式 |
| `optional/readyup.smx` | `sm_forcestart` | 管理员 | ADMFLAG_BAN | Forces the round to start regardless of player ready status. | 34 个模式 |
| `optional/readyup.smx` | `sm_fs` | 管理员 | ADMFLAG_BAN | Forces the round to start regardless of player ready status. | 34 个模式 |
| `optional/readyup.smx` | `sm_hide` | 玩家/控制台 | - | Hides the ready-up panel so other menus can be seen | 34 个模式 |
| `optional/readyup.smx` | `sm_nr` | 玩家/控制台 | - | Mark yourself as not ready if you have set yourself as ready | 34 个模式 |
| `optional/readyup.smx` | `sm_r` | 玩家/控制台 | - | Mark yourself as ready for the round to go live | 34 个模式 |
| `optional/readyup.smx` | `sm_ready` | 玩家/控制台 | - | Mark yourself as ready for the round to go live | 34 个模式 |
| `optional/readyup.smx` | `sm_return` | 玩家/控制台 | - | Return to a valid saferoom spawn if you get stuck during an unfrozen ready-up period | 34 个模式 |
| `optional/readyup.smx` | `sm_show` | 玩家/控制台 | - | Shows a hidden ready-up panel | 34 个模式 |
| `optional/readyup.smx` | `sm_toggleready` | 玩家/控制台 | - | Toggle your ready status | 34 个模式 |
| `optional/readyup.smx` | `sm_unready` | 玩家/控制台 | - | Mark yourself as not ready if you have set yourself as ready | 34 个模式 |
| `optional/slots_vote.smx` | `sm_slots` | 玩家/控制台 | - | - | 33 个模式 |
| `optional/spechud.smx` | `finale_tank_default` | 服务器配置 | - | - | 32 个模式 |
| `optional/spechud.smx` | `sm_spechud` | 玩家/控制台 | - | - | 32 个模式 |
| `optional/spechud.smx` | `sm_tankhud` | 玩家/控制台 | - | - | 32 个模式 |
| `optional/spechud.smx` | `tank_map_flow_and_second_event` | 服务器配置 | - | - | 32 个模式 |
| `optional/spechud.smx` | `tank_map_only_first_event` | 服务器配置 | - | - | 32 个模式 |
| `optional/specrates.smx` | `sm_adminrates` | 管理员 | ADMFLAG_GENERIC | 管理员手动提升：对局128tick/旁观100tick | 24 个模式 |
| `optional/specrates.smx` | `sm_specrates` | 玩家/控制台 | - | 当你分数>=30W时手动设置旁观60tick | 24 个模式 |
| `optional/survivor_mvp.smx` | `say` | 聊天钩子 | - | 监听聊天输入；通常用于解析聊天触发或屏蔽命令回显 | 28 个模式 |
| `optional/survivor_mvp.smx` | `say_team` | 聊天钩子 | - | 监听聊天输入；通常用于解析聊天触发或屏蔽命令回显 | 28 个模式 |
| `optional/survivor_mvp.smx` | `sm_kills` | 玩家/控制台 | - | Prints AnneHappy compact survivor stats | 28 个模式 |
| `optional/survivor_mvp.smx` | `sm_mvp` | 玩家/控制台 | - | Prints the current MVP for the survivor team | 28 个模式 |
| `optional/survivor_mvp.smx` | `sm_mvpme` | 玩家/控制台 | - | Prints the client's own MVP-related stats | 28 个模式 |
| `optional/teamflip.smx` | `sm_teamflip` | 玩家/控制台 | - | - | 25 个模式 |
| `optional/teamflip.smx` | `sm_tf` | 玩家/控制台 | - | - | 25 个模式 |
| `optional/weapon_loadout_vote.smx` | `sm_forcemode` | 管理员 | ADMFLAG_ROOT | Forces the Voting menu | `zh1v1`, `zh2v2`, `zh3v3`, `zonehunters` |
| `optional/weapon_loadout_vote.smx` | `sm_mode` | 玩家/控制台 | - | Opens the Voting menu | `zh1v1`, `zh2v2`, `zh3v3`, `zonehunters` |
| `optional/witch_and_tankifier.smx` | `reset_static_maps` | 服务器配置 | - | - | 32 个模式 |
| `optional/witch_and_tankifier.smx` | `sm_tank_witch_debug_info` | 管理员 | ADMFLAG_KICK | Dump spawn state info | 32 个模式 |
| `optional/witch_and_tankifier.smx` | `static_tank_map` | 服务器配置 | - | - | 32 个模式 |
| `optional/witch_and_tankifier.smx` | `static_witch_map` | 服务器配置 | - | - | 32 个模式 |
| `playercommands.smx` | `sm_rename` | 管理员 | ADMFLAG_SLAY | sm_rename <#userid\|name> | 34 个模式 |
| `playercommands.smx` | `sm_slap` | 管理员 | ADMFLAG_SLAY | sm_slap <#userid\|name> [damage] | 34 个模式 |
| `playercommands.smx` | `sm_slay` | 管理员 | ADMFLAG_SLAY | sm_slay <#userid\|name> | 34 个模式 |

## Anne 模式专用命令

共 66 条命令/监听入口。

| 插件 | 命令 | 类型 | 权限 | 说明 | 出现模式 |
| --- | --- | --- | --- | --- | --- |
| `extend/gnome.smx` | `sm_gnome` | 管理员 | ADMFLAG_ROOT | Spawns a temporary gnome at your crosshair. | `allcharger`, `alone`, `annehappy`, `annehappy_hardcore`, `annehappy_shotgun`, `coop`, `hunters`, `realism`, `witchparty` |
| `extend/gnome.smx` | `sm_gnomeang` | 管理员 | ADMFLAG_ROOT | Displays a menu to adjust the gnome angles your crosshair is over. | `allcharger`, `alone`, `annehappy`, `annehappy_hardcore`, `annehappy_shotgun`, `coop`, `hunters`, `realism`, `witchparty` |
| `extend/gnome.smx` | `sm_gnomedel` | 管理员 | ADMFLAG_ROOT | Removes the gnome you are pointing at and deletes from the config if saved. | `allcharger`, `alone`, `annehappy`, `annehappy_hardcore`, `annehappy_shotgun`, `coop`, `hunters`, `realism`, `witchparty` |
| `extend/gnome.smx` | `sm_gnomeglow` | 管理员 | ADMFLAG_ROOT | Toggle to enable glow on all gnomes to see where they are placed. | `allcharger`, `alone`, `annehappy`, `annehappy_hardcore`, `annehappy_shotgun`, `coop`, `hunters`, `realism`, `witchparty` |
| `extend/gnome.smx` | `sm_gnomekill` | 管理员 | ADMFLAG_ROOT | Removes all gnomes from the current map and deletes them from the config. | `allcharger`, `alone`, `annehappy`, `annehappy_hardcore`, `annehappy_shotgun`, `coop`, `hunters`, `realism`, `witchparty` |
| `extend/gnome.smx` | `sm_gnomelist` | 管理员 | ADMFLAG_ROOT | Display a list gnome positions and the total number of. | `allcharger`, `alone`, `annehappy`, `annehappy_hardcore`, `annehappy_shotgun`, `coop`, `hunters`, `realism`, `witchparty` |
| `extend/gnome.smx` | `sm_gnomepos` | 管理员 | ADMFLAG_ROOT | Displays a menu to adjust the gnome origin your crosshair is over. | `allcharger`, `alone`, `annehappy`, `annehappy_hardcore`, `annehappy_shotgun`, `coop`, `hunters`, `realism`, `witchparty` |
| `extend/gnome.smx` | `sm_gnomesave` | 管理员 | ADMFLAG_ROOT | Spawns a gnome at your crosshair and saves to config. | `allcharger`, `alone`, `annehappy`, `annehappy_hardcore`, `annehappy_shotgun`, `coop`, `hunters`, `realism`, `witchparty` |
| `extend/gnome.smx` | `sm_gnometele` | 管理员 | ADMFLAG_ROOT | Teleport to a gnome (Usage: sm_gnometele <index: 1 to MAX_GNOMES>). | `allcharger`, `alone`, `annehappy`, `annehappy_hardcore`, `annehappy_shotgun`, `coop`, `hunters`, `realism`, `witchparty` |
| `extend/HitStatistics.smx` | `sm_kills` | 玩家/控制台 | - | MVP Statistic | `allcharger`, `alone`, `annehappy`, `annehappy_hardcore`, `annehappy_shotgun`, `coop`, `hunters`, `realism`, `witchparty` |
| `extend/HitStatistics.smx` | `sm_killsme` | 玩家/控制台 | - | MyKills Statistic | `allcharger`, `alone`, `annehappy`, `annehappy_hardcore`, `annehappy_shotgun`, `coop`, `hunters`, `realism`, `witchparty` |
| `extend/l4d_random_beam_item.smx` | `sm_beamadd` | 管理员 | ADMFLAG_ROOT | Add a beam (with default config) to entity at crosshair. | `allcharger`, `alone`, `annehappy`, `annehappy_hardcore`, `annehappy_shotgun`, `coop`, `hunters`, `realism`, `witchparty` |
| `extend/l4d_random_beam_item.smx` | `sm_beaminfo` | 管理员 | ADMFLAG_ROOT | Outputs to the chat the beam info about the entity at your crosshair. | `allcharger`, `alone`, `annehappy`, `annehappy_hardcore`, `annehappy_shotgun`, `coop`, `hunters`, `realism`, `witchparty` |
| `extend/l4d_random_beam_item.smx` | `sm_beamreload` | 管理员 | ADMFLAG_ROOT | Reload the beam configs. | `allcharger`, `alone`, `annehappy`, `annehappy_hardcore`, `annehappy_shotgun`, `coop`, `hunters`, `realism`, `witchparty` |
| `extend/l4d_random_beam_item.smx` | `sm_beamremove` | 管理员 | ADMFLAG_ROOT | Remove plugin beam from entity at crosshair. | `allcharger`, `alone`, `annehappy`, `annehappy_hardcore`, `annehappy_shotgun`, `coop`, `hunters`, `realism`, `witchparty` |
| `extend/l4d_random_beam_item.smx` | `sm_beamremoveall` | 管理员 | ADMFLAG_ROOT | Remove all beams created by the plugin. | `allcharger`, `alone`, `annehappy`, `annehappy_hardcore`, `annehappy_shotgun`, `coop`, `hunters`, `realism`, `witchparty` |
| `extend/l4d_random_beam_item.smx` | `sm_print_cvars_l4d_random_beam_item` | 管理员 | ADMFLAG_ROOT | Print the plugin related cvars and their respective values to the console. | `allcharger`, `alone`, `annehappy`, `annehappy_hardcore`, `annehappy_shotgun`, `coop`, `hunters`, `realism`, `witchparty` |
| `extend/l4d_safe_door_spam.smx` | `sm_door_drop` | 管理员 | ADMFLAG_ROOT | Test command to make a targeted door fall over (will likely only work correctly on Saferoom doors). | `allcharger`, `alone`, `annehappy`, `annehappy_hardcore`, `annehappy_shotgun`, `coop`, `hunters`, `realism`, `witchparty` |
| `extend/l4d_safe_door_spam.smx` | `sm_door_fall` | 管理员 | ADMFLAG_ROOT | Test command to make the first locked saferoom door fall over. | `allcharger`, `alone`, `annehappy`, `annehappy_hardcore`, `annehappy_shotgun`, `coop`, `hunters`, `realism`, `witchparty` |
| `extend/l4d2_damage_show.smx` | `sm_dmgcookie` | 管理员 | Admin_Generic | Dump cookie & current settings | `allcharger`, `alone`, `annehappy`, `annehappy_hardcore`, `annehappy_shotgun`, `coop`, `hunters`, `realism`, `witchparty` |
| `extend/l4d2_damage_show.smx` | `sm_dmgdbprobe` | 管理员 | Admin_Generic | One-shot sync DB probe | `allcharger`, `alone`, `annehappy`, `annehappy_hardcore`, `annehappy_shotgun`, `coop`, `hunters`, `realism`, `witchparty` |
| `extend/l4d2_damage_show.smx` | `sm_dmgdbstat` | 管理员 | Admin_Generic | Show DB status & session charset | `allcharger`, `alone`, `annehappy`, `annehappy_hardcore`, `annehappy_shotgun`, `coop`, `hunters`, `realism`, `witchparty` |
| `extend/l4d2_damage_show.smx` | `sm_dmgforcesavecookie` | 管理员 | Admin_Generic | Force save current settings to cookie | `allcharger`, `alone`, `annehappy`, `annehappy_hardcore`, `annehappy_shotgun`, `coop`, `hunters`, `realism`, `witchparty` |
| `extend/l4d2_damage_show.smx` | `sm_dmgmenu` | 玩家/控制台 | - | 打开伤害数字设置菜单 | `allcharger`, `alone`, `annehappy`, `annehappy_hardcore`, `annehappy_shotgun`, `coop`, `hunters`, `realism`, `witchparty` |
| `extend/l4d2_door_lock.smx` | `sm_lock` | 管理员 | ADMFLAG_GENERIC | Force Saferoom To Be Locked | `allcharger`, `alone`, `annehappy`, `annehappy_hardcore`, `annehappy_shotgun`, `hunters`, `witchparty` |
| `extend/l4d2_door_lock.smx` | `sm_ready` | 玩家/控制台 | - | Set Player's Status To Ready | `allcharger`, `alone`, `annehappy`, `annehappy_hardcore`, `annehappy_shotgun`, `hunters`, `witchparty` |
| `extend/l4d2_door_lock.smx` | `sm_unlock` | 管理员 | ADMFLAG_GENERIC | Force Saferoom To Be Unlocked | `allcharger`, `alone`, `annehappy`, `annehappy_hardcore`, `annehappy_shotgun`, `hunters`, `witchparty` |
| `extend/l4d2_door_lock.smx` | `sm_unready` | 玩家/控制台 | - | Set Player's Status To Unready | `allcharger`, `alone`, `annehappy`, `annehappy_hardcore`, `annehappy_shotgun`, `hunters`, `witchparty` |
| `extend/l4d2_hitsound.smx` | `sm_hitsound_reload` | 管理员 | ADMFLAG_ROOT | 重新从 DB/KV 读取所有在线玩家的偏好 | `allcharger`, `alone`, `annehappy`, `annehappy_hardcore`, `annehappy_shotgun`, `coop`, `hunters`, `realism`, `witchparty` |
| `extend/l4d2_hitsound.smx` | `sm_hitui` | 玩家/控制台 | - | 快速在禁用与套装1间切换覆盖图三项 | `allcharger`, `alone`, `annehappy`, `annehappy_hardcore`, `annehappy_shotgun`, `coop`, `hunters`, `realism`, `witchparty` |
| `extend/l4d2_hitsound.smx` | `sm_snd` | 玩家/控制台 | - | 主菜单：音效/图标套装（玩家）+ 特定开关 + 管理员单独设置 | `allcharger`, `alone`, `annehappy`, `annehappy_hardcore`, `annehappy_shotgun`, `coop`, `hunters`, `realism`, `witchparty` |
| `extend/punch_angle.smx` | `sm_punch` | 玩家/控制台 | - | - | `allcharger`, `alone`, `annehappy`, `annehappy_hardcore`, `annehappy_shotgun`, `coop`, `hunters`, `realism`, `witchparty` |
| `extend/punch_angle.smx` | `sm_recoil` | 玩家/控制台 | - | - | `allcharger`, `alone`, `annehappy`, `annehappy_hardcore`, `annehappy_shotgun`, `coop`, `hunters`, `realism`, `witchparty` |
| `fixes/l4d2_blackscreen_fix.smx` | `sm_get_restricted_strings` | 管理员 | ADMFLAG_ROOT | Get strings from restrict_strings | `allcharger`, `alone`, `annehappy`, `annehappy_hardcore`, `annehappy_shotgun`, `coop`, `hunters`, `realism`, `witchparty` |
| `fixes/l4d2_blackscreen_fix.smx` | `sm_restore_st` | 管理员 | ADMFLAG_ROOT | Restore downloadables stringtable items | `allcharger`, `alone`, `annehappy`, `annehappy_hardcore`, `annehappy_shotgun`, `coop`, `hunters`, `realism`, `witchparty` |
| `optional/AnneHappy/annehappy_dynamic_ai_difficulty.smx` | `sm_aidiff` | 管理员 | ADMFLAG_CONFIG | sm_aidiff <0-5> 设置动态难度；0=自动，1-5=固定难度 | `allcharger`, `alone`, `annehappy`, `annehappy_hardcore`, `annehappy_shotgun`, `hunters`, `witchparty` |
| `optional/AnneHappy/annehappy_dynamic_ai_difficulty.smx` | `sm_aidiff_reload` | 管理员 | ADMFLAG_CONFIG | 重新读取难度配置并应用当前难度 | `allcharger`, `alone`, `annehappy`, `annehappy_hardcore`, `annehappy_shotgun`, `hunters`, `witchparty` |
| `optional/AnneHappy/annehappy_dynamic_ai_difficulty.smx` | `sm_aippm` | 玩家/控制台 | - | 显示当前 AnneHappy 动态难度和 PPM | `allcharger`, `alone`, `annehappy`, `annehappy_hardcore`, `annehappy_shotgun`, `hunters`, `witchparty` |
| `optional/AnneHappy/infected_control.smx` | `sm_navpeek` | 管理员 | ADMFLAG_GENERIC | 查看准星 Nav 的分桶与属性 | `allcharger`, `alone`, `annehappy`, `annehappy_hardcore`, `annehappy_shotgun`, `hunters`, `witchparty` |
| `optional/AnneHappy/infected_control.smx` | `sm_navtest` | 管理员 | ADMFLAG_GENERIC | 测试准星 Nav 能否生成特感及评分 | `allcharger`, `alone`, `annehappy`, `annehappy_hardcore`, `annehappy_shotgun`, `hunters`, `witchparty` |
| `optional/AnneHappy/infected_control.smx` | `sm_np` | 管理员 | ADMFLAG_GENERIC | 查看准星 Nav 的分桶与属性(别名) | `allcharger`, `alone`, `annehappy`, `annehappy_hardcore`, `annehappy_shotgun`, `hunters`, `witchparty` |
| `optional/AnneHappy/infected_control.smx` | `sm_nt` | 管理员 | ADMFLAG_GENERIC | 测试准星 Nav 能否生成特感及评分(别名) | `allcharger`, `alone`, `annehappy`, `annehappy_hardcore`, `annehappy_shotgun`, `hunters`, `witchparty` |
| `optional/AnneHappy/infected_control.smx` | `sm_rebuildnavcache` | 管理员 | ADMFLAG_ROOT | Rebuild Nav bucket cache for current map | `allcharger`, `alone`, `annehappy`, `annehappy_hardcore`, `annehappy_shotgun`, `hunters`, `witchparty` |
| `optional/AnneHappy/infected_control.smx` | `sm_startspawn` | 管理员 | ADMFLAG_ROOT | 管理员重置刷特时钟 | `allcharger`, `alone`, `annehappy`, `annehappy_hardcore`, `annehappy_shotgun`, `hunters`, `witchparty` |
| `optional/AnneHappy/infected_control.smx` | `sm_stopspawn` | 管理员 | ADMFLAG_ROOT | 管理员停止刷特 | `allcharger`, `alone`, `annehappy`, `annehappy_hardcore`, `annehappy_shotgun`, `hunters`, `witchparty` |
| `optional/AnneHappy/l4d_boss_vote.smx` | `sm_bossvote` | 玩家/控制台 | - | - | `allcharger`, `alone`, `annehappy`, `annehappy_hardcore`, `annehappy_shotgun`, `hunters`, `witchparty` |
| `optional/AnneHappy/l4d_boss_vote.smx` | `sm_ftank` | 管理员 | ADMFLAG_BAN | - | `allcharger`, `alone`, `annehappy`, `annehappy_hardcore`, `annehappy_shotgun`, `hunters`, `witchparty` |
| `optional/AnneHappy/l4d_boss_vote.smx` | `sm_fwitch` | 管理员 | ADMFLAG_BAN | - | `allcharger`, `alone`, `annehappy`, `annehappy_hardcore`, `annehappy_shotgun`, `hunters`, `witchparty` |
| `optional/AnneHappy/l4d_boss_vote.smx` | `sm_voteboss` | 玩家/控制台 | - | - | `allcharger`, `alone`, `annehappy`, `annehappy_hardcore`, `annehappy_shotgun`, `hunters`, `witchparty` |
| `optional/AnneHappy/l4d_target_override.smx` | `sm_to_reload` | 管理员 | ADMFLAG_ROOT | Reloads the data config. | `allcharger`, `alone`, `annehappy`, `annehappy_hardcore`, `annehappy_shotgun`, `coop`, `hunters`, `realism`, `witchparty` |
| `optional/AnneHappy/l4d2_ai_ladder_boost.smx` | `sm_ladder_debug` | 管理员 | ADMFLAG_GENERIC | 显示插件调试信息 | `allcharger`, `alone`, `annehappy`, `annehappy_hardcore`, `annehappy_shotgun`, `hunters`, `witchparty` |
| `optional/AnneHappy/l4d2_ai_ladder_boost.smx` | `sm_ladder_status` | 管理员 | ADMFLAG_GENERIC | 显示所有玩家状态 | `allcharger`, `alone`, `annehappy`, `annehappy_hardcore`, `annehappy_shotgun`, `hunters`, `witchparty` |
| `optional/AnneHappy/l4d2_dirspawn.smx` | `sm_dirspawn_apply` | 管理员 | ADMFLAG_GENERIC | sm_dirspawn_apply [总特] [间隔] - 立即应用设置 | `coop`, `realism` |
| `optional/AnneHappy/l4d2_dirspawn.smx` | `sm_dirspawn_genkv` | 管理员 | ADMFLAG_ROOT | sm_dirspawn_genkv [min] [max] - 生成均衡每类上限KV文件到 dirspawn_kv_path | `coop`, `realism` |
| `optional/AnneHappy/l4d2_dynamic_ammo.smx` | `sm_da_recalc` | 管理员 | ADMFLAG_GENERIC | 手动重算并应用 | `coop`, `realism` |
| `optional/AnneHappy/l4d2_hunter_patch.smx` | `sm_hunter_patch_print_cvars` | 管理员 | ADMFLAG_ROOT | - | `alone`, `annehappy`, `annehappy_hardcore`, `annehappy_shotgun`, `hunters`, `witchparty` |
| `optional/AnneHappy/l4d2_med_dynamic.smx` | `sm_srmedkit_apply` | 管理员 | ADMFLAG_GENERIC | Remove saferoom medkits now and distribute by survivor count. | `coop`, `realism` |
| `optional/AnneHappy/server.smx` | `sm_addbot` | 管理员 | ADMFLAG_ROOT | 添加一个生还者Bot（不会被本插件踢） | `allcharger`, `alone`, `annehappy`, `annehappy_hardcore`, `annehappy_shotgun`, `coop`, `hunters`, `realism`, `witchparty` |
| `optional/AnneHappy/server.smx` | `sm_delbot` | 管理员 | ADMFLAG_ROOT | 删除一个未被接管的生还者Bot | `allcharger`, `alone`, `annehappy`, `annehappy_hardcore`, `annehappy_shotgun`, `coop`, `hunters`, `realism`, `witchparty` |
| `optional/AnneHappy/server.smx` | `sm_kicktank` | 管理员 | ADMFLAG_KICK | 有多只Tank时，随机踢至只有一只 | `allcharger`, `alone`, `annehappy`, `annehappy_hardcore`, `annehappy_shotgun`, `coop`, `hunters`, `realism`, `witchparty` |
| `optional/AnneHappy/server.smx` | `sm_kill` | 玩家/控制台 | - | - | `allcharger`, `alone`, `annehappy`, `annehappy_hardcore`, `annehappy_shotgun`, `coop`, `hunters`, `realism`, `witchparty` |
| `optional/AnneHappy/server.smx` | `sm_setbot` | 玩家/控制台 | - | - | `allcharger`, `alone`, `annehappy`, `annehappy_hardcore`, `annehappy_shotgun`, `coop`, `hunters`, `realism`, `witchparty` |
| `optional/AnneHappy/server.smx` | `sm_zs` | 玩家/控制台 | - | - | `allcharger`, `alone`, `annehappy`, `annehappy_hardcore`, `annehappy_shotgun`, `coop`, `hunters`, `realism`, `witchparty` |
| `optional/AnneHappy/text.smx` | `sm_killall` | 管理员 | ADMFLAG_BAN | 处死所有玩家 | `allcharger`, `alone`, `annehappy`, `annehappy_hardcore`, `annehappy_shotgun`, `hunters`, `witchparty` |
| `optional/AnneHappy/text.smx` | `sm_xx` | 玩家/控制台 | - | - | `allcharger`, `alone`, `annehappy`, `annehappy_hardcore`, `annehappy_shotgun`, `hunters`, `witchparty` |
| `optional/servercleanup.smx` | `sm_srvcln_now` | 管理员 | ADMFLAG_ROOT | - | `allcharger`, `alone`, `annehappy`, `annehappy_hardcore`, `annehappy_shotgun`, `coop`, `hunters`, `realism`, `witchparty` |

## Anne 私有武器属性实验插件命令

这些插件目前是私有实验层，通常放在 `plugins/optional/AnneHappy/` 下按需加载。网页后台“玩家武器属性”写入数据库后，由 `l4d2_player_attr_db` 读取并调用 PWA/PMA/PMA-Trace native；调试时也可以直接用下表命令手动设置。

### 生效和默认值链路

- 原生默认：由 `l4d2_weaponinfo_dump` 执行 `sm_widump_all_defaults` 生成 JSON，Web 后台读取 `addons/sourcemod/data/l4d2_weaponinfo_defaults.json`；近战轨迹会额外 dump `scripts/melee/*.txt` 的主/副攻击段，若服务器不能通过 Valve 文件系统读取 VPK 内脚本，可把脚本镜像放到 `addons/sourcemod/data/l4d2_melee_scripts/*.txt`。
- vote 默认：来自 `cfg/vote/weapon` 下当前模式 cfg 的 `sm_weapon <weapon> <attr> <value>` 行，只是全局默认，不是玩家覆盖。
- 玩家覆盖：存入 `l4d2_player_attr_profiles`，游戏服 `l4d2_player_attr_db` 在进服、切枪、定时刷新或手动 reload/apply 时下发。
- 日志：PWA `logs/l4d2_pwa_native_attrs.log`，PMA `logs/l4d2_pma_native_attrs.log`，Trace `logs/l4d2_pma_trace_attrs.log`，DB 协调器 `logs/l4d2_player_attr_db.log`。

### DB 协调器

| 插件 | 命令 | 类型 | 权限 | 说明 |
| --- | --- | --- | --- | --- |
| `optional/AnneHappy/l4d2_player_attr_db.smx` | `sm_pattrdb_reload` | 管理员 | ADMFLAG_ROOT | 重新连接/读取数据库里的玩家属性行，并对在线玩家尝试应用。 |
| `optional/AnneHappy/l4d2_player_attr_db.smx` | `sm_pattrdb_status` | 管理员 | ADMFLAG_ROOT | 显示 DB 插件启用状态、连接状态、缓存行数、最后加载时间和 PWA/PMA/Trace native 是否可用。 |
| `optional/AnneHappy/l4d2_player_attr_db.smx` | `sm_pattrdb_apply <target>` | 管理员 | ADMFLAG_ROOT | 对目标玩家立即按当前持有武器/近战应用已缓存 DB 行。 |

常用流程：

```text
sm plugins load optional/AnneHappy/l4d2_pwa_native_attrs
sm plugins load optional/AnneHappy/l4d2_player_attr_db
sm_pattrdb_status
sm_pattrdb_reload
sm_pattrdb_apply "#userid"
```

### PWA 枪械 per-player 属性

| 插件 | 命令 | 类型 | 权限 | 说明 |
| --- | --- | --- | --- | --- |
| `optional/AnneHappy/l4d2_pwa_native_attrs.smx` | `sm_pwa_set <target> <weapon\|@active> <attr> <value> [attr value]...` | 管理员 | ADMFLAG_ROOT | 手动给目标设置枪械 profile。支持一次写多个属性。 |
| `optional/AnneHappy/l4d2_pwa_native_attrs.smx` | `sm_pwa_clear <target>` | 管理员 | ADMFLAG_ROOT | 清除目标当前 PWA profile。 |
| `optional/AnneHappy/l4d2_pwa_native_attrs.smx` | `sm_pwa_list` | 管理员 | ADMFLAG_ROOT | 列出当前在线玩家的 PWA profile。 |
| `optional/AnneHappy/l4d2_pwa_native_attrs.smx` | `sm_pwa_reload_config` | 管理员 | ADMFLAG_ROOT | 重新读取旧 cfg profile。DB 协调器启用时通常会关闭旧 cfg 自动应用。 |
| `optional/AnneHappy/l4d2_pwa_native_attrs.smx` | `sm_pwa_apply_config <target> <weapon\|@active>` | 管理员 | ADMFLAG_ROOT | 手动应用旧 cfg profile。 |
| `optional/AnneHappy/l4d2_pwa_native_attrs.smx` | `sm_pwa_config_status` | 管理员 | ADMFLAG_ROOT | 查看旧 cfg profile 缓存状态。 |
| `optional/AnneHappy/l4d2_pwa_native_attrs.smx` | `sm_pwa_restore` | 管理员 | ADMFLAG_ROOT | 将被 PWA 碰过的全局 WeaponInfo 属性恢复到缓存基线。 |
| `optional/AnneHappy/l4d2_pwa_native_attrs.smx` | `sm_pwa_tx_audit <target_a> <target_b> <weapon\|@active>` | 管理员 | ADMFLAG_ROOT | 模拟同 tick 嵌套 apply/restore，检查是否串值。 |
| `optional/AnneHappy/l4d2_pwa_native_attrs.smx` | `sm_pwa_return_audit <target> <weapon\|@active>` | 管理员 | ADMFLAG_ROOT | 检查 GetMaxClip1 等返回值覆盖。 |
| `optional/AnneHappy/l4d2_pwa_native_attrs.smx` | `sm_pwa_native_audit <target_a> <target_b> <weapon\|@active> [safe\|all]` | 管理员 | ADMFLAG_ROOT | SDKCall/native detour 矩阵审计。 |
| `optional/AnneHappy/l4d2_pwa_native_attrs.smx` | `sm_pwa_live_fire_audit <target_a> <target_b> <weapon\|@active>` | 管理员 | ADMFLAG_ROOT | 强制同 tick 开火，审计真实开火窗口。 |
| `optional/AnneHappy/l4d2_pwa_native_attrs.smx` | `sm_pwa_live_fire_cancel` | 管理员 | ADMFLAG_ROOT | 取消 live fire 审计并恢复 profile/武器。 |
| `optional/AnneHappy/l4d2_pwa_native_attrs.smx` | `sm_pwa_live_return_audit <target_a> <target_b> <weapon\|@active> [seconds]` | 管理员 | ADMFLAG_ROOT | 观察真实换弹/部署/最大弹夹返回覆盖。 |
| `optional/AnneHappy/l4d2_pwa_native_attrs.smx` | `sm_pwa_live_return_cancel` | 管理员 | ADMFLAG_ROOT | 取消 live return 审计。 |
| `optional/AnneHappy/l4d2_pwa_native_attrs.smx` | `sm_pwa_matrix_audit <target_a> <target_b> <weapon\|@active> [safe\|all\|live\|full]` | 管理员 | ADMFLAG_ROOT | 设置两名玩家不同 profile 并跑矩阵。 |
| `optional/AnneHappy/l4d2_pwa_native_attrs.smx` | `sm_pwa_bot_matrix_audit <bot_a> <bot_b> <weapon> [safe\|all]` | 管理员 | ADMFLAG_ROOT | 给两个 survivor bot 装枪并跑矩阵 smoke。 |
| `optional/AnneHappy/l4d2_pwa_native_attrs.smx` | `sm_pwa_bot_live_smoke <bot_a> <bot_b> <weapon> [live\|full]` | 管理员 | ADMFLAG_ROOT | bot 真实开火 smoke。 |
| `optional/AnneHappy/l4d2_pwa_native_attrs.smx` | `sm_pwa_preflight <target_a> <target_b> <weapon\|@active>` | 管理员 | ADMFLAG_ROOT | 检查依赖、武器和 live fire readiness。 |
| `optional/AnneHappy/l4d2_pwa_native_attrs.smx` | `sm_pwa_preflight_matrix <target_a> <target_b> <weapon\|@active> [safe\|all\|live\|full]` | 管理员 | ADMFLAG_ROOT | 先 preflight，再跑矩阵。 |

常用手动测试：

```text
sm_pwa_set "#userid" @active damage 50 tankdamagemult 2.0
sm_pwa_list
sm_pwa_clear "#userid"
```

### PMA 近战原生属性

| 插件 | 命令 | 类型 | 权限 | 说明 |
| --- | --- | --- | --- | --- |
| `optional/AnneHappy/l4d2_pma_native_attrs.smx` | `sm_pma_set <target> <melee\|@active> <attr> <value> [attr value]...` | 管理员 | ADMFLAG_ROOT | 手动给目标设置近战原生 profile。 |
| `optional/AnneHappy/l4d2_pma_native_attrs.smx` | `sm_pma_clear <target>` | 管理员 | ADMFLAG_ROOT | 清除目标 PMA profile。 |
| `optional/AnneHappy/l4d2_pma_native_attrs.smx` | `sm_pma_list` | 管理员 | ADMFLAG_ROOT | 列出当前 PMA profile。 |
| `optional/AnneHappy/l4d2_pma_native_attrs.smx` | `sm_pma_reload_config` | 管理员 | ADMFLAG_ROOT | 重新读取旧 cfg profile。 |
| `optional/AnneHappy/l4d2_pma_native_attrs.smx` | `sm_pma_apply_config <target> <melee\|@active>` | 管理员 | ADMFLAG_ROOT | 手动应用旧 cfg profile。 |
| `optional/AnneHappy/l4d2_pma_native_attrs.smx` | `sm_pma_config_status` | 管理员 | ADMFLAG_ROOT | 查看旧 cfg profile 缓存状态。 |
| `optional/AnneHappy/l4d2_pma_native_attrs.smx` | `sm_pma_restore` | 管理员 | ADMFLAG_ROOT | 恢复被 PMA 碰过的全局 melee attr 基线。 |
| `optional/AnneHappy/l4d2_pma_native_attrs.smx` | `sm_pma_dump [melee\|@active]` | 管理员 | ADMFLAG_ROOT | dump 指定近战原生属性。 |
| `optional/AnneHappy/l4d2_pma_native_attrs.smx` | `sm_pma_tx_audit <target_a> <target_b> <melee\|@active>` | 管理员 | ADMFLAG_ROOT | 模拟同 tick 近战 apply/restore。 |
| `optional/AnneHappy/l4d2_pma_native_attrs.smx` | `sm_pma_matrix_audit <target_a> <target_b> <melee\|@active>` | 管理员 | ADMFLAG_ROOT | 设置两名玩家不同近战 profile 并跑审计。 |
| `optional/AnneHappy/l4d2_pma_native_attrs.smx` | `sm_pma_live_swing_audit <target_a> <target_b> <melee\|@active>` | 管理员 | ADMFLAG_ROOT | 强制同 tick 挥砍并审计 apply/restore。 |
| `optional/AnneHappy/l4d2_pma_native_attrs.smx` | `sm_pma_bot_live_smoke <bot_a> <bot_b> <melee>` | 管理员 | ADMFLAG_ROOT | bot 近战 live smoke。 |

### PMA-Trace 近战轨迹属性

| 插件 | 命令 | 类型 | 权限 | 说明 |
| --- | --- | --- | --- | --- |
| `optional/AnneHappy/l4d2_pma_trace_attrs.smx` | `sm_pma_trace_attr_set <target> [melee\|@active\|*] <range\|dirscale\|yawbias> <value> [attr value]...` | 管理员 | ADMFLAG_ROOT | 手动设置近战轨迹 profile。 |
| `optional/AnneHappy/l4d2_pma_trace_attrs.smx` | `sm_pma_trace_attr_clear <target>` | 管理员 | ADMFLAG_ROOT | 清除目标 Trace profile。 |
| `optional/AnneHappy/l4d2_pma_trace_attrs.smx` | `sm_pma_trace_attr_list` | 管理员 | ADMFLAG_ROOT | 列出 Trace profile。 |
| `optional/AnneHappy/l4d2_pma_trace_attrs.smx` | `sm_pma_trace_attr_status` | 管理员 | ADMFLAG_ROOT | 查看 Trace counters 和状态。 |
| `optional/AnneHappy/l4d2_pma_trace_attrs.smx` | `sm_pma_trace_attr_reload_config` | 管理员 | ADMFLAG_ROOT | 重新读取旧 cfg profile。 |
| `optional/AnneHappy/l4d2_pma_trace_attrs.smx` | `sm_pma_trace_attr_apply_config <target> <melee\|@active>` | 管理员 | ADMFLAG_ROOT | 手动应用旧 cfg Trace profile。 |
| `optional/AnneHappy/l4d2_pma_trace_attrs.smx` | `sm_pma_trace_attr_live_audit <target_a> <target_b>` | 管理员 | ADMFLAG_ROOT | 强制同 tick 近战轨迹审计。 |
| `optional/AnneHappy/l4d2_pma_trace_attrs.smx` | `sm_pma_trace_attr_bot_live_smoke <bot_a> <bot_b> <melee>` | 管理员 | ADMFLAG_ROOT | bot 轨迹 live smoke。 |

启用方向向量修改：

```text
sm_cvar l4d2_pma_trace_attrs_vector_change 1
sm_pma_trace_attr_set "#userid" @active range 160 dirscale 1.0 yawbias 20
sm_pma_trace_attr_live_audit "#userid_a" "#userid_b"
```

### WeaponInfo dump/probe

| 插件 | 命令 | 类型 | 权限 | 说明 |
| --- | --- | --- | --- | --- |
| `optional/AnneHappy/l4d2_weaponinfo_dump.smx` | `sm_widump <weapon\|@me> [attr]` | 管理员 | ADMFLAG_ROOT | dump 指定枪械 WeaponInfo 属性，`@me` 使用当前武器。 |
| `optional/AnneHappy/l4d2_weaponinfo_dump.smx` | `sm_widump_offsets` | 管理员 | ADMFLAG_ROOT | dump Left4DHooks 暴露的 weapon attribute offset。 |
| `optional/AnneHappy/l4d2_weaponinfo_dump.smx` | `sm_widump_all_defaults [path]` | 管理员 | ADMFLAG_ROOT | 将枪械、近战属性和近战脚本轨迹原生默认值写成 JSON，默认给 Web 后台读取。 |
| `optional/AnneHappy/l4d2_weaponinfo_probe.smx` | `sm_wiprobe_set <target> <weapon\|@active> <attr> <value> [attr value]...` | 管理员 | ADMFLAG_ROOT | 早期 WeaponInfo 原型测试 profile。 |
| `optional/AnneHappy/l4d2_weaponinfo_probe.smx` | `sm_wiprobe_clear <target>` | 管理员 | ADMFLAG_ROOT | 清除 probe profile。 |
| `optional/AnneHappy/l4d2_weaponinfo_probe.smx` | `sm_wiprobe_list` | 管理员 | ADMFLAG_ROOT | 列出 probe profile。 |
| `optional/AnneHappy/l4d2_weaponinfo_probe.smx` | `sm_wiprobe_restore` | 管理员 | ADMFLAG_ROOT | 恢复 probe 碰过的 WeaponInfo 基线。 |

## 附录：未被当前模式配置加载的启用目录插件命令

共 70 条命令/监听入口。

| 插件 | 命令 | 类型 | 权限 | 说明 |
| --- | --- | --- | --- | --- |
| `anticheat/l4d2_nobhaps.smx` | `sm_check_bhop` | 玩家/控制台 | - | - |
| `basechat.smx` | `sm_chat` | 管理员 | ADMFLAG_CHAT | sm_chat <message> - sends message to admins |
| `basechat.smx` | `sm_csay` | 管理员 | ADMFLAG_CHAT | sm_csay <message> - sends centered message to all players |
| `basechat.smx` | `sm_dsay` | 管理员 | ADMFLAG_CHAT | sm_dsay <message> - sends hud message to all players |
| `basechat.smx` | `sm_hsay` | 管理员 | ADMFLAG_CHAT | sm_hsay <message> - sends hint message to all players |
| `basechat.smx` | `sm_msay` | 管理员 | ADMFLAG_CHAT | sm_msay <message> - sends message as a menu panel |
| `basechat.smx` | `sm_psay` | 管理员 | ADMFLAG_CHAT | sm_psay <name or #userid> <message> - sends private message |
| `basechat.smx` | `sm_say` | 管理员 | ADMFLAG_CHAT | sm_say <message> - sends message to all players |
| `basechat.smx` | `sm_tsay` | 管理员 | ADMFLAG_CHAT | sm_tsay [color] <message> - sends top-left message to all players |
| `basetriggers.smx` | `ff` | 玩家/控制台 | - | - |
| `basetriggers.smx` | `motd` | 玩家/控制台 | - | - |
| `basetriggers.smx` | `nextmap` | 玩家/控制台 | - | - |
| `basetriggers.smx` | `timeleft` | 玩家/控制台 | - | - |
| `basevotes.smx` | `sm_vote` | 管理员 | ADMFLAG_VOTE | sm_vote <question> [Answer1] [Answer2] ... [Answer5] |
| `basevotes.smx` | `sm_voteban` | 管理员 | ADMFLAG_VOTE\|ADMFLAG_BAN | sm_voteban <player> [reason] |
| `basevotes.smx` | `sm_votekick` | 管理员 | ADMFLAG_VOTE\|ADMFLAG_KICK | sm_votekick <player> [reason] |
| `basevotes.smx` | `sm_votemap` | 管理员 | ADMFLAG_VOTE\|ADMFLAG_CHANGEMAP | sm_votemap <mapname> [mapname2] ... [mapname5] |
| `clientprefs.smx` | `sm_cookies` | 玩家/控制台 | - | sm_cookies <name> [value] |
| `clientprefs.smx` | `sm_settings` | 玩家/控制台 | - | - |
| `duoren/survivor_chat_select.smx` | `sm_b` | 玩家/控制台 | - | Changes your survivor character into Bill |
| `duoren/survivor_chat_select.smx` | `sm_bill` | 玩家/控制台 | - | Changes your survivor character into Bill |
| `duoren/survivor_chat_select.smx` | `sm_c` | 玩家/控制台 | - | Changes your survivor character into Coach |
| `duoren/survivor_chat_select.smx` | `sm_coach` | 玩家/控制台 | - | Changes your survivor character into Coach |
| `duoren/survivor_chat_select.smx` | `sm_csc` | 管理员 | ADMFLAG_GENERIC | Brings up a menu to select a client's character |
| `duoren/survivor_chat_select.smx` | `sm_csm` | 玩家/控制台 | - | Brings up a menu to select a client's character |
| `duoren/survivor_chat_select.smx` | `sm_e` | 玩家/控制台 | - | Changes your survivor character into Ellis |
| `duoren/survivor_chat_select.smx` | `sm_ellis` | 玩家/控制台 | - | Changes your survivor character into Ellis |
| `duoren/survivor_chat_select.smx` | `sm_f` | 玩家/控制台 | - | Changes your survivor character into Francis |
| `duoren/survivor_chat_select.smx` | `sm_francis` | 玩家/控制台 | - | Changes your survivor character into Francis |
| `duoren/survivor_chat_select.smx` | `sm_l` | 玩家/控制台 | - | Changes your survivor character into Louis |
| `duoren/survivor_chat_select.smx` | `sm_louis` | 玩家/控制台 | - | Changes your survivor character into Louis |
| `duoren/survivor_chat_select.smx` | `sm_n` | 玩家/控制台 | - | Changes your survivor character into Nick |
| `duoren/survivor_chat_select.smx` | `sm_nick` | 玩家/控制台 | - | Changes your survivor character into Nick |
| `duoren/survivor_chat_select.smx` | `sm_r` | 玩家/控制台 | - | Changes your survivor character into Rochelle |
| `duoren/survivor_chat_select.smx` | `sm_rochelle` | 玩家/控制台 | - | Changes your survivor character into Rochelle |
| `duoren/survivor_chat_select.smx` | `sm_z` | 玩家/控制台 | - | Changes your survivor character into Zoey |
| `duoren/survivor_chat_select.smx` | `sm_zoey` | 玩家/控制台 | - | Changes your survivor character into Zoey |
| `optional/AnneHappy/ai_tank_2.smx` | `sm_checkladder` | 管理员 | ADMFLAG_ROOT | 测试当前地图有多少个梯子 |
| `optional/AnneHappy/ai_tank_new.smx` | `sm_con` | 管理员 | ADMFLAG_BAN | - |
| `optional/code_patcher.smx` | `codepatch_list` | 服务器配置 | - | - |
| `optional/code_patcher.smx` | `codepatch_patch` | 服务器配置 | - | - |
| `optional/code_patcher.smx` | `codepatch_unpatch` | 服务器配置 | - | - |
| `optional/l4d2_mixmap.smx` | `sm_addmap` | 服务器配置 | - | - |
| `optional/l4d2_mixmap.smx` | `sm_fmixmap` | 管理员 | ADMFLAG_ROOT | Force start mixmap (arg1 empty for 'default' maps pool) 强制启用mixmap（随机官方地图） |
| `optional/l4d2_mixmap.smx` | `sm_manualmixmap` | 管理员 | ADMFLAG_ROOT | Start mixmap with specified maps 启用mixmap加载特定地图顺序的地图组 |
| `optional/l4d2_mixmap.smx` | `sm_mixmap` | 玩家/控制台 | - | - |
| `optional/l4d2_mixmap.smx` | `sm_tagrank` | 服务器配置 | - | - |
| `sounds.smx` | `sm_play` | 管理员 | ADMFLAG_GENERIC | sm_play <#userid\|name> <filename> |

## 附录：未找到源码的未加载启用目录插件

| 插件 | 备注 |
| --- | --- |
| `optional/AnneHappy/ai_charger_boomer.smx` | 存在 .smx，但未找到同路径源码，无法静态提取命令 |
| `optional/AnneHappy/AI_HardSI_2_old.smx` | 存在 .smx，但未找到同路径源码，无法静态提取命令 |
| `optional/AnneHappy/infected_control10-10.smx` | 存在 .smx，但未找到同路径源码，无法静态提取命令 |
| `optional/AnneHappy/infected_control11-28.smx` | 存在 .smx，但未找到同路径源码，无法静态提取命令 |
| `optional/AnneHappy/infected_control2-2.smx` | 存在 .smx，但未找到同路径源码，无法静态提取命令 |
| `optional/AnneHappy/infected_control22-10.smx` | 存在 .smx，但未找到同路径源码，无法静态提取命令 |
| `optional/AnneHappy/infected_control22-11.smx` | 存在 .smx，但未找到同路径源码，无法静态提取命令 |
| `optional/AnneHappy/infected_control22-12.smx` | 存在 .smx，但未找到同路径源码，无法静态提取命令 |
| `optional/AnneHappy/infected_control22-7.smx` | 存在 .smx，但未找到同路径源码，无法静态提取命令 |
| `optional/AnneHappy/infected_control22-9.smx` | 存在 .smx，但未找到同路径源码，无法静态提取命令 |
| `optional/AnneHappy/infected_control23-1.smx` | 存在 .smx，但未找到同路径源码，无法静态提取命令 |
| `optional/AnneHappy/infected_control24-5.smx` | 存在 .smx，但未找到同路径源码，无法静态提取命令 |
| `optional/AnneHappy/infected_control25-10.smx` | 存在 .smx，但未找到同路径源码，无法静态提取命令 |
| `optional/AnneHappy/infected_control7-7.smx` | 存在 .smx，但未找到同路径源码，无法静态提取命令 |
| `optional/AnneHappy/l4d2_asiai.smx` | 存在 .smx，但未找到同路径源码，无法静态提取命令 |
| `optional/AnneHappy/l4d2_tank_throw.smx` | 存在 .smx，但未找到同路径源码，无法静态提取命令 |

## 维护提示

- 如果新增或移除模式插件，请重新按同样口径扫描配置，避免文档和配置引用清单脱节。
- 如果某个插件只改了源码但没有加入任何 `confogl_plugins.cfg` 或 `sharedplugins.cfg`，它只会出现在附录或不出现。
