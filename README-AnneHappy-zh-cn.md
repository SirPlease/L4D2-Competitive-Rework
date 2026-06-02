# **AnneHappy 插件带上对抗插件包**
* 为了保持插件包结构和上游一样方便同步，这个插件包将不会带有nav修改文件和跳舞插件的模型与声音，~~AnneHappy的Nav修改文件请到我的[anne项目](https://github.com/fantasylidong/anne)中下载~~ 新解决方案，到[release页面](https://github.com/fantasylidong/CompetitiveWithAnne/releases)下载整合插件包，里面有
* 当前版本已经是进入stable模式，大部分核心插件更新可以通过join插件自动更新，不用那么频繁检测是否有更新了
* 如果没有数据库，建议下[release页面](https://github.com/fantasylidong/CompetitiveWithAnne/releases)里的norank版本或者nomysql版本,nomysql有关数据库插件全部删除，norank版本只保留sourcebans插件，积分插件
* norank版本是用电信服的rpg插件，只删除了排名，作弊检测和sourcebans插件，缺点就是每次进服务器需要自己设置出门近战，不想自己写了，有需求的写完可以pull request到我的项目里
* nomysql版本是删除了所有和数据库相关的插件


## **AnneHappy 会自动更新的核心插件**
- Path_SM/plugins/optional/AnneHappy/ai_boomer_2.smx"
- Path_SM/plugins/optional/AnneHappy/ai_charger_2.smx"
- Path_SM/plugins/optional/AnneHappy/ai_hunter_2.smx"
- Path_SM/plugins/optional/AnneHappy/ai_smoker3.smx"
- Path_SM/plugins/optional/AnneHappy/ai_spitter_2.smx"
- Path_SM/plugins/optional/AnneHappy/ai_jockey_2.smx"
- Path_SM/plugins/optional/AnneHappy/ai_tank3.smx"
- Path_SM/plugins/optional/AnneHappy/infected_control.smx"
- Path_SM/plugins/optional/AnneHappy/text.smx"
- Path_SM/plugins/optional/AnneHappy/server.smx"
- Path_SM/plugins/optional/AnneHappy/SI_Target_limit.smx"
- Path_SM/plugins/optional/AnneHappy/l4d_target_override.smx"
- Path_SM/plugins/optional/AnneHappy/l4d2_Anne_stuck_tank_teleport.smx"
- Path_SM/plugins/extend/join.smx"
- Path_SM/plugins/extend/server_name.smx"

## **关于新增模式:**

> **AnneHappy新加模式:**
* **AnneHappy 普通药役模式**
* **Hunters 1vHT模式**
* **AllCharget 牛牛冲刺大赛模式**
* **Witch Party模式** 
* **Alone 单人装逼模式**
* **AnneHappy 硬核药役模式***


---

## **目录结构**
* 运行时插件 `.smx` 放在 `addons/sourcemod/plugins/`，保持和上游 `master` 一样的 SourceMod 插件目录结构
* AnneHappy 专属定制插件放在 `addons/sourcemod/plugins/optional/AnneHappy/`；通用或上游同步插件即使被 Anne 模式加载，也优先放在 `addons/sourcemod/plugins/optional/`
* 常规扩展插件放在 `addons/sourcemod/plugins/extend/`
* 项目 SourcePawn 源码 `.sp` 按插件相对路径镜像放在 `addons/sourcemod/scripting/`，例如 `plugins/extend/join.smx` 对应 `scripting/extend/join.sp`
* AnneHappy 专属定制源码放在 `addons/sourcemod/scripting/optional/AnneHappy/`，例如 `infected_control.sp` 的拆分模块放在 `addons/sourcemod/scripting/optional/AnneHappy/infected_control/`
* SourceMod 官方自带插件源码保留在 `addons/sourcemod/scripting/sourcemod/`，作为上游结构例外
* 使用 `scripts/spcomp-docker.sh` 编译时，不传第二个参数会按源码相对路径把 `.smx` 写回对应插件目录；发布 release 时也按这个规则重新编译并覆盖
* 仓库里没有 `.sp` 的旧二进制插件会在 release 时原样保留，不参与重新编译

---

## **重要内容**
* Anne 专属定制插件放到 `plugins/optional/AnneHappy`，源码位于 `scripting/optional/AnneHappy`；通用插件放到 `plugins/optional`，源码位于 `scripting/optional`
* 其中`plugins/extend`文件夹中的插件为电信服扩展所用，包括帽子、积分和商店娱乐等功能（默认启用）
* 本插件尽量在不影响Zonemod同步上游更新的基础进行更新（方便自己偷懒）
* 如果需要数据库，请使用项目里的database.sql创表，并且根据wiki里的文档进行数据库调优（尤其是服务器较多的情况）
* 正常情况下，请不要加载任何一个test插件文件夹内的插件，你加载一个文件夹内的一个插件，sourcemod的bug可能会把那个文件夹内的所有插件全部加载（感谢Harry提醒，我确实碰到这个问题）
* 对抗模式默认不开启mod，如果需要玩对抗请手动关闭mod
* 常规要加载的拓展插件放到 `plugins/extend` 文件夹，测试插件放到 `plugins/disabled/test` 文件夹，投票加载卸载和通用模式插件放到 `plugins/optional` 文件夹，Anne 专属定制插件放到 `plugins/optional/AnneHappy` 文件夹
---

## **已知问题:**
* 小刀为TLS更新前的原版小刀，正常对抗模式将不再刷新小刀，只有药役模式才会刷新小刀
* AnneHappy模式过关统计会把这一章节所有统计信息全部记录，因为对抗模式每回合不会清除统计信息（原来的方式不能正确载入对抗地图和对抗的梯子和nav）【我觉得这是Feature不是Bug，笑，反正普通信息mvp插件能够正常记录了，所以也不准备修改了】

## **无数据库服务器安装问题:**
> 由于我的数据库不会对外放开，所以有些插件你需要删除或者自建数据库[数据库脚本在项目内]
- extend/l4d_stats.smx 积分插件，需要数据库，很多插件也依赖这个插件提供的积分，不过后面经过修改，这些依赖于这个积分插件的插件
也能在无积分插件情况下运行了
- chat-processor.smx 聊天语句处理插件，称号插件的前置插件
- extend/hextags.smx 称号插件 其中自定义称号需要rpg插件， 积分插件相互配合才能使用，无积分的情况下你可以直接去configs/hextags.cfg文件内增加自定义称号
- extend/lilac.smx 会保存检测记录到数据库l4d2_stats数据库
- extend/sbpp_******.smx sourcebans插件，方便进行所有服务器封禁
- extend/rpg.smx 商店插件，会自动检测依赖，没数据库也能用，或者你自己改用原来anne的，问题不大
- extend/chatlog.smx 数据库聊天记录插件
- extend/l4d_hats.smx 插件，最新帽子插件修改版，增加了数据库功能和forward处理，无积分插件也能使用，但是需要自己配置好l4d_hats配置
- extend/l4d2_item_hint.smx 标点插件，禁用了一部分功能，增加了光圈标点的聊天栏提示，也需要积分功能搭配限制，无积分插件也能使用
- disabled/specrate.smx 旁观30tick插件，更改后4人旁观数以内，30w积分的玩家也能100tick旁观，超过4人旁观，除管理员外其他旁观玩家一律30tick
- extendd/veterans.smx 时长检测插件，部分依赖于l4d_stats.smx插件的时长信息，能够自定义想玩游戏玩家的时长限制，不满足时长的，只能旁观，join.smx插件依赖这个插件提供是否是steamm组成员的信息
- extend/join.smx 玩家加入离开提示，换队作用，motd展示功能（不是组员会有提示，需要veterans插件作为前置）

## **Issue 发起说明**
请先阅读完README-AnneHappy-zh-cn.md后再发起任何issue
发起issue请进来仔细描述问题，最好能提供错误的log和怎么复现的，拒绝无效Issue
	
## **感谢人员:**

> **Foundation/Advanced Work:**
* morzlee 本分支创建者及维护者
* Caibiiii 原分支创建者
* HoongDou 原分支创建者
* Moyu 原分支创建者

> **Additional Plugins/Extensions:**
* GlowingTree880 特感能力加强的巨大贡献者
* umlka 完美解决了coop_base_versus问题
* fdxx 使用了一部分fdxx的插件

> **Competitive Mapping Rework:**
* Derpduck, morzlee 地图修改

> **Testing/Issue Reporting:**
* Too many to list, keep up the great work in reporting issues!
* 所有电信服玩家，因为没有时间游玩测试，大部分bug都是由他们反馈给我

**注意事项:** 如果你的作品被使用了，而我却忘了归功于你，我真诚地向你道歉。 
我已经尽力将名单上的每个人都包括在内，只要创建一个问题，并说出你所制作/贡献的插件/扩展，我就会确保适当地记入你的名字。
