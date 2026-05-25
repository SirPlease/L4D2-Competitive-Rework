# 电信服刷服器

一个用 Rust 编写的求生之路 2 刷服/查服工具，默认打开原生 GUI，也保留命令行查询模式。它可以从 Steam Master Server、手动分组和网页订阅链接收集服务器地址，再对每个服务器发送 `A2S_INFO` 查询，输出分组、服务器名、地图、人数、延迟、VAC、标签等信息。

## Usage

直接启动 GUI：

```bash
./l4d2-server-browser
```

Windows 下双击 `l4d2-server-browser.exe` 会直接打开原生 GUI，release 版不会额外弹出控制台窗口。macOS 下载包里会包含 `电信服刷服器.app`，双击 `.app` 即可使用。

GUI 没有传 `--config` 时，会把配置写到用户配置目录：

- macOS: `~/Library/Application Support/L4D2 Server Browser/l4d2-browser.toml`
- Linux: `~/.config/l4d2-server-browser/l4d2-browser.toml`
- Windows: `%APPDATA%\L4D2 Server Browser\l4d2-browser.toml`

命令行查询模式需要显式传参数，例如：

```bash
cd tools/l4d2_server_browser
cargo run --release -- --limit 100
```

开发环境启动原生 GUI：

```bash
cargo run --release -- --gui --config browser.example.toml
```

会直接打开桌面窗口。GUI 支持添加服务器、添加网页订阅、刷新服务器列表、执行 RCON 命令、读取 CVAR/公开 rules。
如果配置了 AnneWeb API，还可以用 Steam 登录后发送全服消息，并通过 API 查询在线玩家的总积分、总时长、PPM 和季度积分。

常用参数：

```bash
# 输出 JSON，方便给其他脚本处理
cargo run --release -- --limit 200 --json

# 追加 master server 过滤条件
cargo run --release -- --extra-filter '\secure\1\empty\1'

# 只拉取地址，不查询服务器详情
cargo run --release -- --no-info --limit 500

# 按名称或地图过滤
cargo run --release -- --name anne --map c2m1

# 手动加分组
cargo run --release -- --group '我的服务器=1.2.3.4:27015,1.2.3.4:27016'

# 订阅网页服务器列表
cargo run --release -- --sourcebans 'Anne=https://example.com/sourcebans'

# 普通网页也可以订阅，只要页面或同源 JS 里包含 IP:端口 / 域名:端口
cargo run --release -- --subscription 'Kita=https://www.kitasoda.com/#/serverList'

# 使用配置文件
cargo run --release -- --config browser.example.toml

# 只看某个分组
cargo run --release -- --config browser.example.toml --only-group 'Anne'

```

## Config

配置文件使用 TOML。示例见 `browser.example.toml`：

```toml
[gui]
language = "zh-CN"

[updater]
auto_check = true

[api]
base_url = "https://anne.trygek.com"
# Steam 登录后会自动写入 token。
# token = "aw_xxx"

[master]
enabled = true
group = "公网大厅"
address = "hl2master.steampowered.com:27011"
region = "all"
filter = "\\appid\\550"
extra_filter = ["\\secure\\1"]
limit = 200

[[groups]]
name = "我的服务器"
servers = [
  "127.0.0.1:27015",
  "steam://connect/127.0.0.1:27016",
]

[[sourcebans]]
name = "Anne 网页订阅"
url = "https://example.com/sourcebans"
```

`sourcebans` 是兼容旧版本的配置字段，现在也用于普通网页订阅。`sourcebans.url` 可以填 SourceBans 站点根路径、直接填 `index.php?p=servers`，也可以填普通网页链接。普通网页链接会原样请求；工具会从页面正文和同源 `.js` / `.json` / `.txt` / `.csv` 资源里提取 `IP:port`、`域名:port` 和 `steam://connect/...` 链接。

## GUI / RCON

GUI 模式是原生桌面窗口，不启动网页服务。新增服务器和网页订阅会写入 `--config` 指定的 TOML 文件；如果没有传 `--config`，默认写入系统用户配置目录。

左侧使用标签页管理配置：

- `添加服务器`：添加手动服务器，并显示已保存的服务器列表。
- `网页订阅`：新增、修改、删除网页订阅。

右侧服务器列表支持按分组标签筛选，点 `全部服务器` 会恢复显示所有分组；也可以点击选中服务器。选中后，底部会直接显示该服务器的 RCON 和 CVAR / Rules 面板；CVAR / Rules 会主动查询一次，RCON 只需要输入密码和命令后执行。详情卡片会把域名解析成实际 IP，并通过 `ip-api.com` 查询运营商、组织、ASN 和地区；结果只在本次运行内缓存，避免刷新列表时批量请求外部 API。

GUI 启动时会自动加载系统 CJK 字体，避免 Windows/Linux 上中文显示成方块；界面图标尽量使用程序绘制或普通文字，不依赖 emoji 字体。界面支持 i18n，目前内置 `简体中文` 和 `English`，可在顶部语言下拉框切换；选择会保存到配置文件：

```toml
[gui]
language = "zh-CN"

[updater]
auto_check = true
```

GUI 会在启动时检查 GitHub Release 是否有新版本，也可以点击顶部的“检查更新”。发现新版本后，点击“打开下载页”进入 Release 页面下载对应平台压缩包。

## AnneWeb API / Steam 登录

`[api].base_url` 指向 NewAnneWeb 站点。点击 GUI 里的“Steam 登录”后，工具会打开网页授权；授权完成后 token 会保存到本地配置。

全服消息不会使用服务器 RCON。GUI 调用 NewAnneWeb 的 `/api/server/broadcast.php`，网页端写入 `chat` 数据库的 `anne_global_chat` 表，`global_chat.smx` 会按自己的轮询规则广播给所有服务器。GUI 会额外调用 `/api/server/broadcast_history.php` 读取最近 1 小时全服消息；网页端会把 `since` 限制在 60 到 3600 秒、`limit` 限制在 1 到 200，避免大范围拉取聊天表。

玩家统计使用 `/api/player/online.php` 一次读取最近 2 分钟在线统计，再由 GUI 按 A2S 玩家名本地匹配，避免逐个请求玩家接口。

RCON 使用 Source RCON TCP 协议。读取 CVAR 有两种方式：

- 填 RCON 密码和 CVAR 名称：通过 RCON 执行对应命令，适合读取私有 cvar。
- 不填 RCON 密码：通过 `A2S_RULES` 读取服务器公开 rules，可留空名称读取全部公开项。

## Release Build

仓库包含 `.github/workflows/l4d2_server_browser.yml`。它会构建这些平台的执行文件并上传 artifact：

- `x86_64-unknown-linux-gnu`
- `x86_64-apple-darwin`
- `aarch64-apple-darwin`
- `x86_64-pc-windows-msvc`

手动运行 workflow 可以下载构建产物。推送 `l4d2-browser-v*` tag 时会自动创建 GitHub Release。

macOS 压缩包会同时包含命令行二进制和 `电信服刷服器.app`；普通使用直接打开 `.app`。Windows 压缩包里的 `.exe` 默认就是 GUI 程序。

## Notes

- 默认 master server 是 `hl2master.steampowered.com:27011`。
- 默认过滤条件是 `\appid\550`。
- 这是查询工具，不会对服务器发送高频请求；每个服务器最多做一次 `A2S_INFO` 查询，遇到 challenge 会按协议补发一次。
- 网页订阅只读取公开页面和同源静态资源，不需要数据库权限；遇到网站的人机验证或登录墙时，抓取会被对方页面限制。
- IP 网络解析使用 `ip-api.com` 免费 JSON 接口：无需 API key，但免费版仅 HTTP、45 次/分钟且不允许商用。
