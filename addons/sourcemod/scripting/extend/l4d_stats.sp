#pragma semicolon 1
#include <sourcemod>
#include <clientprefs>
#include <sdktools>
#include <left4dhooks>
#undef REQUIRE_PLUGIN
#include <adminmenu>
#include <rpg>

// 模块加载顺序：常量和全局状态必须先加载，随后是通用工具和业务模块。
#include "l4d_stats/constants.inc"
#include "l4d_stats/state.inc"
#include "l4d_stats/stats_players.inc"
#include "l4d_stats/stats_score.inc"
#include "l4d_stats/new_player_bonus.inc"
#include "l4d_stats/no_buy_bonus.inc"
#include "l4d_stats/score_log.inc"
#include "l4d_stats/quarter_rank.inc"

// Plugin Info
public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = "东，Mikko Andersson (muukis)",
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = "https://github.com/fantasylidong/L4d2_plugins"
};

// 业务模块按插件启动流程、数据层、事件层、命令层、规则层和输出辅助分组。
#include "l4d_stats/api.inc"
#include "l4d_stats/plugin_start.inc"
#include "l4d_stats/admin_menu.inc"
#include "l4d_stats/lifecycle.inc"
#include "l4d_stats/rounds.inc"
#include "l4d_stats/persistence.inc"
#include "l4d_stats/timers.inc"
#include "l4d_stats/events_players.inc"
#include "l4d_stats/events_team.inc"
#include "l4d_stats/commands_menus.inc"
#include "l4d_stats/stats_rules.inc"
#include "l4d_stats/output_rank_timing.inc"
