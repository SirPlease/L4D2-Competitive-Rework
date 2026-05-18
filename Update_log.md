# **L4D2 AnneHappy Rework Update log**
# **L4D2 AnneHappy Rework 更新记录**

## **更新记录:**

### ** 2022年11月更新记录**
#### 前言
新插件包的目的是为了更快的获取上游更新，降低我的维护成本，当第一版本插件完成后，我的更新就只需要更新特感等功能性插件
其他的插件来源于上游的更新，可以更专注于**摸鱼**
社区插件的更新能够得到马上的同步
#### 插件更新记录
- ai_tank2.sp 增加了梯子检测功能，并且删除了tank后退动作的连跳处理，修复了tank可能会纵云梯大跳的问题
- ai_jockey_new.sp 修复了猴子被推后马上就能通过使用跳跃功能来恢复重新使用技能导致的问题
- infected_control.smx 将5种模式的4种刷特合并为1个插件处理，
					   适配目标选择插件，选择生还者构建刷特坐标系的时候不能选目标已满的玩家
					   特感的生成顺序改为由队列进行处理，解决一波可能刷同样的特感[主要是boomer和spitter]的问题
					   原来的射线刷特方法取消，改为获取"logic_script"的值来判断[也还是射线处理，但是效率比原来快，而且效果更好]
					   检测env_physics_blocker的阻拦属性，原来不能生成的地方现在很大可能也能生成了
					   射线类型改变，由MASK_NPCSOLID_BRUSHONLY类型更改为MASK_PLAYERSOLID，能最大程度上增加可刷特位置
					   修复原来刷特IsPlayerStuck的射线过滤器的bug，会导致新版插件把射线改为MASK_PLAYERSOLID后导致的卡在新加的物件上
					   倒地玩家的视线不会影响特感的传送(相当于倒地生还视线不如狗）
					   增加最大刷特距离的控制
- server.smx 分开为2个插件join.smx 和 server.smx，其中join.smx主要处理加入游戏后换队的问题，server.smx处理Anne等模式下特殊的一些功能
- l4d_target_override.smx 升级为最新版本，增加了targeted功能，能限制生还者被选为目标的数量
- SI_Target_limit.smx 目标选择插件适配新版l4d_target_override插件，自动控制控制型特感选相同生还者为目标的数量
- vote.smx 投票cfg插件增加cvar来控制投票文件
- l4d2_Anne_stuck_tank_teleport.smx 救援关不启用跑男惩罚
- text.smx插件会进行Cvar的检测，一次来避免插件加载顺序导致的无法启动的问题
- rpg.smx 增加皮肤功能，且增加自动检测依赖启用不同功能的能力,修复关闭帽子无法保存到数据库的问题
- specrates, hextags, rpg, l4d_hats,l4d2_item_hint.smx ,veterans增加检测积分插件的功能，没有积分插件也不影响使用
- l4d2_weapon_attributes.smx 增加霰弹枪装填速度的Cvar控制，需要WeaponHandling作为前置插件(加载顺序无影响)
- 对抗插件全部更新最新版本，部分插件改用i18n汉化，英语汉语翻译都有(具体汉化插件和i18n汉化请看项目)
- AnneHappy、AnneHappyPlus枪械uzi削弱
当前版本武器伤害具体如下
[AnneHappy](https://github.com/fantasylidong/CompetitiveWithAnne/blob/master/cfg/vote/weapon/AnneHappy.cfg)
[AnneHappyPlus](https://github.com/fantasylidong/CompetitiveWithAnne/blob/master/cfg/vote/weapon/AnneHappyPlus.cfg)
[ZoneMod](https://github.com/fantasylidong/CompetitiveWithAnne/blob/master/cfg/vote/weapon/zonemod.cfg)

#### 一些重要特感和生还数据：
生还者速度：220
坦克速度： 225
坦克连跳加速度： 60
坦克停止距离： 135
坦克近战攻击距离： 75
小僵尸数量：z_common_limit 24 (大于原AnneHappy的21只，小于zonemod的30只）
被胖子喷产生的小僵尸数量： 1个 13 2个 25 3个35 4个45
尸潮发生时同时存在的小僵尸数量： 45 （大于原AnneHappy的50只，小于zonemod的50只）
其他不太重要数据请在对应模式的shared_cvars.cfg文件
特感增强的数据在对应模式的shared_settings.cfg文件

#### 性能问题
当前刷特版本不多人运动情况下，开20T服务器依旧在90帧以上，最小帧1%也在60帧以上
但是一旦超过4人，20T根本就无法稳定了，8人运动基本在12~14T能基本在90帧以上，最小帧1%在50以上
以上性能测试为r5 3900x 测试，云服高特情况可能还要打个7折起步
综上，正常情况下刷特应该已经不成为性能瓶颈，6人运动腾讯轻量云服12t基本达到瓶颈（预估）

#### 结论
目前版本的难度还是相当大的，4特带一个新手的压力都不小，5特带一个新手难度就比较大了，6特带一个新手不靠卡克基本很难通过c2
所以建议新手玩家多玩玩4，5特之后再去6特混野
各个服主也可以根据自己喜好设置不同的难度，大部分的都可以通过控制Cvar来控制难度
部分可能需要源码的，所有源码也已经开源，其中AnneHappy为主的插件在scripts/AnneHappy/文件夹
拓展性为主的插件在scripts/extend/文件夹
如果发现有问题，请发issue

### 2022年11月6日更新记录
#### 刷特插件infected_control.smx
- 修改传送时生成位置错误的逻辑
- 增加sdkcalls限制[默认5个]，这个参数很多特的时候消耗比较大，谨慎添加更多！这个代表最多5只特感可以进入传送找位流程，以后可能不会单独用sdkcall处理传送，会先处死，然后进入传送队列，放到ongameframe中处理
#### ai_tank_2.smx插件
- tank插件优化了梯子处理逻辑，将在生还者出安全区的时候遍历所有entity找到所有梯子实体，保存好梯子的起始位置，去除高度的影响下来判断距离，距离小于150的就处在梯子附近，tank将无法锁定视角
#### l4d2_Anne_stuck_tank_teleport插件
- 新版本的可见函数对于tank无效，改回原来的逻辑
#### 结构优化
- 多人模式将共用annehappy模式的shared_cvar.cfg和shared_plugins.cfg
- 单人模式将共用alone模式的map_cvar
- 卸载大部分annehappy不需要的插件
- server的网络参数设置将只应用与annehappy比赛模式，对抗的网络参数强制使用cfg/confogl_rates.cfg文件，对抗原来的gamemode参数已经加到confogl_personalize.cfg，原来的对抗模式参数anne.vpk基本已经删除完
#### 特感加智插件
- 特感处于stargger状态下不进行操作
#### server_name插件
- 服务器名插件模式检测更改为对l4d_ready_cfg_name cvar的检测，不再使用sv_tags处理，适配对抗的readyup插件名字设置
#### join插件
- 增加了服务器核心插件自动更新功能，不过还是建议多看看插件包是不是有更新
#### 插件汉化
- 不少插件增加汉化显示
#### 地图修改
- 部分同步上游地图参数导致牢房减弱，修改回来
#### confoglcompmod.smx
- 防打服狗，我在这个插件增加了平时服务器默认隐藏的参数，有人加载模式后就会删除隐藏，如果高防服务器可以修改源码重新编译一下，等打服狗死了我会用自动更新把这个插件修改为正常
- 还有一些小修复，具体看[commit log](https://github.com/fantasylidong/CompetitiveWithAnne/commits/master)
#### advertisement.smx
- 不同模式的广告文本加载不同
#### vote.cfg
- 支持不同模式选用不同的投票cfg文件

### 2022年11月10日更新记录
#### 刷特插件infected_control.smx
- 修复刷特插件传送出现问题
#### ai_tank_2.smx插件
- 修复delete handle产生的报错
- 修改梯子检测方式
#### survivor_mvp
- 删除团灭更换模式
#### userhook.smx
- 拓展测试插件增减usermessage hook 插件
#### confoglcompmod.smx
- 已经取消隐藏的处理
还有一些小修复，具体看[commit log](https://github.com/fantasylidong/CompetitiveWithAnne/commits/master)
#### versus_coop_mode.smx
对抗模式玩战役，完美修复，谢谢[钵钵鸡大佬](https://github.com/umlka/) 倾力支持
PS：这种处理方式相比原来的换成写实处理有以下几点好处
- 永远是对抗模式地图，比如c5m3会一直是pathA，而且对抗的梯子或者nav修复都存在
- hunter的属性会为对抗属性，原来的改为写实处理第二回合会导致hunter变为战役属性，会使hunter特别难爆
- 可以更改回合重启时间，加快坐牢速度（建议改为1，太低了玩家能在包被删除前偷包）
- 回合结算时能看到整章节的数据，谁偷懒一目了然


### 2022年11月17日更新记录
#### 刷特插件infected_control.smx
- 修复一个位置多刷引起的刷很多同种类特感问题，跑男针对模式
#### hitstatic survivor_mvp l4d_stats
- 更改灭团处理方式，新的versus_coop_mode引起
#### l4d2_script_hud 插件
- 如果tank或者witch不生成，不显示他的进度为固定，而是直接不显示，Static改为固定，进度加上%分号
#### ai_jockey_new更新
- 进攻性更强
#### ai_hunter_new更新
- 顺便可以开启无蓄力hunter
#### join插件
- 增加自动更新插件开关
#### SI_Target_limit
- 适配刷特插件的跑男针对
#### L4D2 Weapon Attributes
- 同步上游更新，去除l4d2_smg_reload_tweak.smx
#### 其他 
- 救援关全部关闭流程克，只启用第一个事件克，三方图使用server插件更改，同步上游fix更新，单人模式传送时间改为默认3秒

### 2022年11月30日更新记录
#### mapinfo更改
- 官图增加很多阴间位置tank的流程ban，同步上游对抗的map和stripper更新
#### ai_jockey_2
- 猴子更改为树树子猴子2.0，修了一点bug，削弱了猴子一部分属性
#### ai_boomer_2
- 胖子更改为树树子胖子2.0
#### specrates
- 修复4人旁观情况下30w积分玩家没有100tick旁观问题
#### l4d2_stats
- 修复因提出特感导致的ht血量错误的问题
#### server
- 增加团灭次数显示
#### rpg
- 恢复因新版coop_base_versus模式引起的每回合白嫖资格消失，增加被黑伤害显示插件
#### l4d_boss_vote
- tank位置投票增加限制，8特以下需要团灭5次才能投票（管理员免疫）
#### infected_control
- 刷特插件传送距离改为动态的，防止部分地方600距离找不到刷新位置导致刷特进程卡住

### 2022年12月8日更新记录

#### infected_control插件
- 删除传送最小距离Convar，传送最小距离和生成最小距离一样，为了增加传送进程的特感生成速度，把特感传送当前距离改为每tick增加20距离快速找位置(生成为每tick增加5距离）
- 增加一个Native（float GetNextSpawnTime()），提供下一次特感生成时间，方便其他插件调用
- 修复1vht和witchparty模式可能少特的问题

#### text插件
- 适配新版infected_control插件，增加狡猾tank的开启关闭显示

#### join插件
- 增加踢出家庭共享账户的功能，需要SteamWorks拓展
- 增加大厅自动删除的Convar

#### specrates插件
- 修改旁观插件的分数插件依赖处理不正确的问题

#### ai_jockey_2插件
- 修改jocker2的一些设置，减低向后跳概率，增加高跳概率

#### l4d_boss_vote插件
- 修复9特以上无法投票的功能

#### 其他
- 增加大量对抗插件的i18n翻译

### 2022年12月15日更新记录
#### infected_control插件
- 特感进度在生还者前或者和最近可移动生还者很近（小于特感生成距离）都不传送
- 确认为跑男的距离由1000更改为1200，更改刷特插件踢出死亡特感方式（感谢树树子）
- 跑男增加一个判定条件，最远那个人如果超过所有特感大于1200也会开启跑男模式
- 跑男模式下只要没被看到就能传送
- 传送检测函数增加限制，必须隔生还者超过或者位置在于最远生还者后方才可以使用
- 刷特不允许在CHECKPOINT的nav属性里刷

#### ai_jockey_2插件
- 同步上游更新并修改合理设置

#### l4d_stats 插件
- 地图记录功能数据库新增5列，分别是sinum(特感数量), sitime(特感生成时间), mode(1 Anne 2 WitchParty 3 AllCharger 4 Alone 5 1vht), usebuy(1用了商店, 0没用商店), anneversion 完成使用的Anne版本
- 未开局团灭不扣分
- 有效检查更改为rpg插件的native

#### rpg插件
- 增加一个forward，如果有玩家b数小于500发出
- 增加2个native，方便其他插件查看用户属性和全局属性

#### L4d2-Si-Push-When-Spawn
- 测试一个插件，特感生成在高出跳出来

#### 1v1 1vai
- 1v1插件支持pve模式，1vai删除无关代码

#### specrates
specrates插件增加一个convar设置100tick旁观人数 vote插件增加限制旁观tick投票

#### l4d2_tank_announce
l4d2_tank_announce增大tank生成时的声音

#### join插件
- 更新链接控制Cvar更改为0-4，0为不自动更新

#### survivor_mvp
- 友伤出安全门清空
- join插件增加一个convar控制大厅属性，默认不开启

#### ai_tank_2
- 增加狡猾tank，tank会在特感生成前8秒内才会压制，和消耗冲突

#### punch_angle
- 枪械抖动增加rpg属性限制，也是通过rpg插件的native函数限制

#### 其他
- 更新Leftdhooks
- 1-3人运动僵尸量减少，5-8人不变（单人在1v1zonemod基础上下调40%小僵尸，双人在2v2基础上降低30%小僵尸，三人在3v3基础上降低25%僵尸量，4人在4v4基础上降低20%僵尸量，5人在正常药役大概增加15-20%，6人在正常药役大概增加30-35%，7人在正常药役大概增加50%，且有双口水，8人在正常药役大概增加65-70%，且有双口水）
witchparty 和 allcharger模式在普通药役的基础上小僵尸再减少17-23%
- 同步上游更新
- 数据库创表文件因为地图记录增加选项需要更改

### 2023年1月1日更新记录
#### infected_control插件
- 增加一个ConVar inf_EnableAutoSpawnTime来控制是否开启自动增加时间
- 自动增加时间效果为，当特感数量低于特感上限/4向下取整+1的数量，或者猴子猎人牛全死或者达到刷特间隔/2时间后，再开启刷特，杀的越快，刷的波数越多，鼓励玩家更有变化的玩，而不是死站桩，站桩依旧有效，但是会面临更多的波数（相当于保底是以前的刷特难度）
- 固定时间效果为： 刷特间隔1.5倍后刷特，16s的话，和原来难度是一样的，24s刷特(原来是小于9s+4s，否则加8s）
- 两种模式可以投票选择，默认自动时间刷特
- 刷特仁慈一点，有tank的时候或者倒地或死亡的人数过半刷特时间不小于设置时间*1.25(16s就是20s）
- 支持暂停功能
- 修复新版本获取下一波特感时间的功能

#### text插件
- 适配新版刷特，提示为固定6特16秒或者自动6特16秒
- 更换模式检测方式

#### ai_boomer_2
- 强喷功能更新，大大降低胖子喷不到人的几率，而且让胖子转动，显得很合理（其实真合理，不过用插件改变不了胖子的喷射路径，只能用这种办法
- 有高度差计算不准确的问题也修了，站高处也能被强制喷了
- 2023/1/8日更新，将胖子喷到第一人后选取喷吐范围内目标按距离升序排序更改为按照胖子视角与当前生还方向角度升序排序
- 2023/1/14日更新，修复四个生还者扎堆无法喷完所有生还者的情况，增加强制被喷前的二次检测
- 2023/1/17日更新，增加每个目标按照角度动态计算喷吐帧数功能

#### ai_jockey_2
- 继续降低高跳角度，降低高跳速度
- 更改冻结之后高跳的速度向量，不要跳太高，而且不要跳过头，推CD加一个限制条件看能否限制猴子落地后快速起跳

#### rpg
- 自动检测有没有数据库，有无数据库都可以运行，修复因为无数据库导致的崩服问题
- 无数据库的缺点，每次进服都需要自己设置出门近战武器

#### l4d_stats
- 更换模式检测方式
- 增加lastannemode列，方便网页显示玩家正在玩的具体模式
- 增加auto列，方便anne23-01版本排行榜写成
- AnneHappy模式关闭tank连跳，无法获得额外加分

#### ai_tank_2
- 恢复检测会不会摔死，但是不消耗情况下不检测是不是会撞墙
- 狡猾tank改为刷特时间的一半或者8s，主要防止时间断情况下消耗能力可能不恢复的问题

#### l4d_hats
- 将排名插件改为可选插件，无排名插件的情况下也能正常运行

#### ai_spitter_2
- 更新ai_spitter_2
- 基于 1.0 版本改造更新，精简代码，优化部分逻辑，增加被控目标优先级功能
- ai_SpitterPinnedPr：6,3,1,5 被控目标的优先级，口水会优先吐优先级高的目标，如果看不到目标则使用默认目标（特感编号，逗号分割）

#### text
- text插件增加生还满人自动关闭高级人机功能
- 增加卸载action拓展功能

#### server
- 增减一个delbot管理员命令，用于多人装逼模式里删除bot的能力
- 对addbot命令增加限制

#### l4d_tongue_block_fix
- 增加smoker可以穿过si拉人，一旦拉成功，可以穿过si和tank的能力

#### l4d_tank_damage_announce
- Tank Damage Announce 2.0, 2023/1/17 日重写，支持显示真正吃铁的情况
- tank_damage_enable：1 是否开启坦克伤害统计
- tank_damage_force_kill_announce：0 坦克被卡死或强制处死是否显示坦克伤害统计
- tank_damage_print_livetime：1 伤害统计是否显示坦克存活时间
- tank_damage_failed_announce：1 生还者团灭时且坦克在场是否显示伤害统计
- tank_damage_print_zero：1 显示坦克伤害统计时是否允许显示对坦克零伤的玩家

注：
	2.0 版本中的铁指具有 m_hasTankGlow 属性且 m_hasTankGlow 属性值为 1，在坦克视野中有光圈显示的物品，如警报车、垃圾桶等
	已兼容多坦克情况

#### SpecListener
- 增加一个插件方便旁观者知道谁在说话

#### show_mic
- 旁观者显示正在讲话的所有人
- 生还者只显示正在说话的旁观者

#### remove
- 如果是救援图，先把包改为药，然后再根据情况处理药和电击器
- 非救援图先处理药，再对包和电击进行修改

#### 其他
- 修改特感增强里检测是否在地面的方式
- 修正一点翻译错误
- 同步上游更新
- 同步率更改为0.024（小僵尸再也看不出有闪现异样），对抗模式保持正常0.014【如果你服务器卡请继续增加同步频率，到你服务器不卡的程度】
- 不加载fixes/l4d2_shove_fix.smx插件

### 2023-03月更新
#### 其他
- 同步zonemod 2.8.1更新
- Anne武器：喷子没改，机枪换弹时间设定同步zonemod
- Anne地图：c7m1 改为固定克，第二节车厢门在第一节车厢门打开之后20秒自动打开

### 2025-10月更新
#### 其他
- 同步上游全部更新
- l4dtoolz更改为fdxx版本
- 增加战役模式和写实模式，其中战役模式占用了写实模式（Anne.vpk更改了写实模式的base模式，从realism改为了coop,所以纯净写实模式实际为纯净战役模式），所以战役模式左上角会显示写实模式，在steam大厅里会显示AnneCoop，写实模式依旧用的写实模式，不过在coop基础上把写实的convar写到了shared_cvar.cfg文件中
- 优化了shared_plugin.cfg里的部分插件增减，增加Coop枪械
- 部分没有源码插件功能合并到server.smx插件里（黑白提醒）,join.smx(屏蔽SM平台提示),l4d_info_editor名称不对，应该为l4d2_melee_spawn_control
- 更新sourcemod到1.12.7195版本
- 还有很多细小更新已经不太记得了，有兴趣可以翻找commit log。

#### 更换地图插件更改
- 不再启用 l4d2_mapchoose.smx（切图）和l4d2_abbw_votemap.smx（换写死的三方）
- 管理员菜单增加adminmenu_mission_list.smx，可以方便更换三方图。 thanks Hoongdou
- 增加l4d2_nativevote.smx,l4d2_source_keyvalues.smx作为更换三方图的前置插件
- l4d2_map_vote.smx为投票下一张三方图插件，map_changer.smx为切换地图插件，两者相辅相成

#### Anne刷特插件infected_control.smx
- 本次刷特插件改动特别大，基本已经抛弃了原Caibiii的找点框架，换成了fdxx的找点框架，并且在fdxx框架里尽可能恢复原Anne插件的功能，然后优化了fdxx的找点框架，大幅降低运行开销，增加了评分系统，分散度系统，高度，距离权重，后面会跟着一篇AI写的详细介绍。

#### 战役刷特 l4d2_dirspawn.smx
- 采用脚本刷特，可以更改特感数量和特感最低刷新时间，支持按照人数增减特感

#### 黑名单插件 l4d2_blacklist.smx
- 普通玩家有3个人的屏蔽名额
- 管理员玩家有10个人的屏蔽名额
- 屏蔽是双向的
- 本次对局内新加的屏蔽人不会直接踢出，只有屏蔽人自己退出对局后再次加入才会设计屏蔽检查

#### rpg插件 rpg.smx
- 增加了很多插件的调度和个性化保存，包括伤害显示、命中反馈、枪械抖动设置

#### 积分插件 l4dstat.smx
- 修改了很多评分细则
- 旁观和娱乐模式不增加在线时长(除了Anne和Anne硬核计入时长)
- 娱乐模式分数平衡
- 硬核模式暂时免疫团灭分

#### ai_tank3.smx 
- 同步树树子上游更新

#### ai_smoker3.smx
- 同步树树子上游更新

### 2026年4月16日-5月16日更新记录
#### 基础环境与上游同步
- SourceMod 更新到 1.12.0.7230，同步 bin、extensions、基础插件和 spcomp 编译器。
- left4dhooks 更新到 1.166，同步 gamedata、include、插件主体和测试/forwards/natives 相关源码。
- 更新 SourceScramble 扩展和 include。
- ZoneMod 更新到 2.9.1a，同步 matchmodes、zonemod/zoneretro/zonehunters/zh/zm 等模式配置。
- 同步 confoglcompmod 更新，修复 `confogl_addcvar` 在 Windows 下的问题，并更新 BossSpawning 逻辑。
- 新增 `scripts/spcomp-docker.sh`，方便 macOS 下通过 Docker 编译 SourcePawn 插件。
- 更新 GitHub Actions 检查与编译流程，包括 `check_plugins.yml` 和 `CompetitiveWithAnne.yml`。

#### 通用修复插件
- `l4d2_fix_changelevel.smx` 切换为 Forgetest 版本，支持部分地图名解析，并替换原 `l4d2_changelevel` 相关 gamedata/include/插件加载项。
- 新增并加载 `l4d2_fix_tank_rock_handoff.smx`，修复 Tank Rocks 在控制权转移时的问题，后续补了一次小修。
- 新增 `l4d2_block_autoaim.smx`，用于 Patch Aim Assist，并加入 `cfg/generalfixes.cfg`。
- `l4d2_hittable_control.smx` 修复 hittable 伤害错误作用到 common 的问题，并增加 breakable hittable fallback。
- `l4d_prop_touching_rules.txt` 更新。
- `l4d2util` 的 SurvivorCharacter enum 重命名，避免和 left4dhooks 冲突；同步影响到 `l4d2_ellis_hunter_bandaid_fix`、`l4d2_getup_slide_fix` 及 archive 里的相关源码。
- `lerpmonitor.smx` 修复通过把 lerp 改到 101 解除硬直的操作，并同步 allcharger、alone、AnneHappy、AnneHappy Hardcore、hunters、witchparty 的相关 shared_settings。
- `1v1.smx` 简化逻辑并修复单人模式问题；同步 `1v1_skeetstats`、`l4d2_skill_detect`、`l4d_boss_percent`、`match_vote` 的翻译和小修复。

#### AnneHappy 与扩展插件
- `l4d_stats.smx` 大幅重构，拆分为多个 include 模块，新增带新奖励、无商店奖励、分数日志、季度排名、回合状态、玩家状态和数据库持久化等模块。
- `l4d_stats.smx` 修复保护队友分数翻倍、部分刷分选项、PPM/KPM 重置和地图记录名单不完整的问题。
- `l4d_stats.smx` 优化季度排名显示，地图记录增加完整玩家名单，数据库结构和 `database.sql` 同步更新。
- 新增 `database_performance_migration.sql`，优化数据库性能，降低统计插件和高峰期插件的数据库压力。
- `rpg.smx` 调整评分逻辑，去除牛牛冲锋和 witchparty 的强势通过分，并修复可能导致刷分的选项。
- `global_chat.smx` 新增全服聊天插件，接入数据库配置，优化全服输出格式，修复全服聊天问题；新增 `!qfmenu` 让玩家控制是否查看全服信息，并增加找队友限制。
- `join.smx` 修复赞助页面和赞助流程，新增 `anne_donate.cfg`，优化 IP 页面显示；fantasydong 组和 Anne 电信服免除广告。
- `l4d2_door_lock.smx` 新增锁门相关功能，增加玩家加载锁安全帽设置，修复强行开始问题，并增加出门前不允许 Bot 活动的限制。
- `network_quality_hint.smx` 新增网络延迟检测插件，方便玩家切换到正确运营商的三线 IP，并优化 `cfg/sourcemod/network_quality_hint.cfg`、`cfg/confogl_rates.cfg` 和 `cfg/server.cfg` 参数。
- `l4d_player_count_unload_mode.smx` 优化高峰期判定，改为统计服务器有人数量且没有大于 60% 的情况；降低数据库压力、调整提示语句并修复高峰期相关 bug。
- `l4d2_hitsound.smx` 新增只对特感生效的开关，并修复命中反馈配置有时整关丢失的问题。
- `l4d2_blacklist.smx` 修复未使用数据库的问题。
- `chatlog.smx`、`l4d2_damage_show.smx`、`veterans.smx`、`server.smx` 修复数据库错误或增加数据库重连处理。
- `server_name.smx` 修复单人模式错误，并减少 `SteamWorks_SetGameDescription` 调用，避免疑似调用过多导致的崩服问题。
- `rygive.smx` 修复可能导致刷分的相关逻辑。

#### 地图、Stripper 与 Nav
- 同步 2026 年 4 月地图更新和后续 stripper review，覆盖 zonemod、zonemod_anne、nextmod、deadman、acemodrv、neomod、apex、eq、pmelite 等多个目录的大量地图 cfg。
- zonemod_anne 同步上游 zonemod 地图改动，包含官图、三方图和多种自定义战役地图的 stripper 更新。
- Carried Off 更新：同步 `cwm1_intro`、`cwm2_warehouse`、`cwm3_drain`、`cwm4_building`，并新增 `cwm1_intro_navfixes.nut`、`cwm2_warehouse_navfixes.nut`。
- Open Road 3 更新：修复 `x1m3_city`，新增 `x1m3_city_navfixes.nut`。
- Detour Ahead 3 更新：修复 `cdta_03warehouse` 导航、fire escape pathing 和 sewer drop tank ban，新增 `cdta_03warehouse_navfixes.nut`，并同步相关 mapinfo。
- 更新 `OutSkirts.cfg`、`versus_3.cfg`、`x1m3_city.cfg`、`cdta_03warehouse.cfg` 等单图修复。
- 同步 `cfg/cfgogl/*/mapinfo.txt` 和多个模式的 shared_plugins/confogl_plugins，保证地图、插件加载和模式配置一致。

#### 配置、广告与文档
- 更新 `README.md` 和相关说明，配合 ZoneMod 版本与默认网页显示调整。
- 更新 `addons/sourcemod/configs/advertisements*.txt`，增加赞助引导语。
- 更新 `addons/sourcemod/configs/databases.cfg`，配合全服聊天、统计、伤害显示等插件的数据库连接与重连。
- 更新 `.gitignore`，减少无关文件进入版本管理。

### 2026年5月17日更新记录
#### AnneHappy 动态特感难度
- 新增 `annehappy_dynamic_ai_difficulty.smx`，根据当前生还者队伍的 `l4d_stats` PPM 自动定档，并在生还者离开安全门前完成计算；出门后本回合难度锁定，不再随投票或数据变化即时调整。
- 队伍定档 PPM 使用当前真人生还者的个人 PPM 算术平均，每个玩家权重一致，避免高积分或长时长玩家单独把整队难度拉高。
- 动态难度分为简单、普通、困难、专家、极限 5 档，默认阈值采用当前可用样本分位：P60=`30.89`、P75=`43.23`、P90=`63.70`、P95=`77.57`。
- 当前季度 PPM 因季度时长晚于季度分数上线而失真，默认关闭季度优先；保留 `ah_ai_dynamic_use_quarter_stats`，后续完整季度可改为“季度样本 >= 5 小时使用季度 PPM，否则回退总榜 PPM”。
- 支持从数据库表 `ai_dynamic_ppm_thresholds` 读取每日预计算分位阈值；网页或定时任务可每天凌晨 4 点写入，插件只读取已计算好的结果，读取失败或过期时回退本地 cfg 阈值。
- 新增 `addons/sourcemod/configs/AnneHappy/dynamic_ai_difficulty.cfg`，将各档特感和 Tank 属性拆成独立配置，方便后续不用改源码直接调档位数值。
- 动态难度只调整特感和 Tank 行为属性，不改刷特数量、刷特间隔、刷点距离、传送检测等章节固定节奏。
- 动态难度锁定后会按 `ah_ai_dynamic_enforce_interval` 定期重刷当前档位 cvar，防止旧投票或手动 `sm_cvar` 把普通/简单档覆盖成极限属性。
- 投票菜单移除旧的 `hard_on/hard_off` 和 `crouch_on/crouch_off` 直改 cvar 入口，统一通过 `固定特感难度` 分类管理档位。
- Tank、Boomer、Charger、Spitter、Jockey、Hunter、Smoker 按档位区分关键行为参数；Jockey 抢控保持关闭，由 `target_override` 控制目标。
- 极限档 Hunter 启用 `l4d2_hunter_patch` 的 `convert_leap=1` 和 `crouch_pounce=2`，非极限档固定关闭该强化，避免档位切换后状态残留。
- `ai_hunter_2.smx` 增加对 `l4d2_hunter_patch` 开关变化的监听，动态难度运行时切换极限档时会同步刷新 Hunter 蹲扑兼容参数。
- 极限档 Tank 从最初高压参数略微削弱，降低贴脸停跳压迫、连跳速度上限/冲量；投石距离和翻越/爬梯速率回到专家档，减少卡住或动画状态异常风险。
- 删除旧 AITank3 已无效或不再使用的配置项，例如 `ai_TankSneakTime`、`ai_TankAirAngleRestrict`、`ai_Tank_Bhop`。
- 新增命令 `sm_aippm` 查看当前 PPM、阈值来源和锁定状态；新增 `sm_aidiff 0-5` 支持自动/固定简单/固定普通/固定困难/固定专家/固定极限。

#### 投票菜单与模式加载
- AnneHappy、AnneHappy Hardcore、AnneHappy Shotgun、多人模式、单人模式的投票菜单新增独立分类 `固定特感难度`，可直接投票执行 `sm_aidiff 0-5`；coop 模式不启用该投票项。
- 出门前投票固定难度会立即影响当前回合；出门后投票只记录为下一回合设置，当前回合保持锁定难度不变。
- 动态难度插件已加入 AnneHappy、AnneHappy Hardcore、AnneHappy Shotgun、AllCharger、Alone、Hunters、WitchParty 等相关模式加载流程，避免投票菜单中 `sm_aidiff` 命令不可用。

#### text 插件显示
- `text.smx` 增加动态难度显示，`!xx`、回合开始提示和玩家进服提示会显示 `动态难度[自动-专家]` 或 `动态难度[固定-极限]`。
- 动态难度插件新增当前难度状态 cvar：`ah_ai_dynamic_current_level`、`ah_ai_dynamic_current_mode`、`ah_ai_dynamic_current_ppm`、`ah_ai_dynamic_current_locked`，供 `text.smx` 和后续其他插件读取。

#### l4d_stats 接口
- `l4d_stats` 新增季度游玩时间 native，动态难度可在未来完整季度中使用季度积分 / 季度时长计算玩家 PPM。
- 季度排名数据结构增加 `playtime` 字段，并在季度查询与写入流程中同步维护。

#### 文档与配置
- 新增 `docs/annehappy_dynamic_ai_difficulty.md`，记录 PPM 分档、数据库阈值表结构、动态难度配置说明、投票/命令用法和特感属性差异。
- 新增 `cfg/sourcemod/annehappy_dynamic_ai_difficulty.cfg` 作为默认 cvar 配置，方便服务器直接调整阈值来源、季度统计开关和固定难度模式。
