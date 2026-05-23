# L4D2 Server Browser

一个用 Rust 编写的求生之路 2 刷服/查服工具，默认打开原生 GUI，也保留命令行查询模式。它可以从 Steam Master Server、手动分组和 SourceBans 订阅链接收集服务器地址，再对每个服务器发送 `A2S_INFO` 查询，输出分组、服务器名、地图、人数、延迟、VAC、标签等信息。

## Usage

直接启动 GUI：

```bash
./l4d2-server-browser
```

Windows 下双击 `l4d2-server-browser.exe` 会直接打开原生 GUI，release 版不会额外弹出控制台窗口。macOS 下载包里会包含 `L4D2 Server Browser.app`，双击 `.app` 即可使用。

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

会直接打开桌面窗口。GUI 支持添加服务器、添加 SourceBans 订阅、刷新服务器列表、执行 RCON 命令、读取 CVAR/公开 rules。

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

# 订阅 SourceBans 服务器列表
cargo run --release -- --sourcebans 'Anne=https://example.com/sourcebans'

# 使用配置文件
cargo run --release -- --config browser.example.toml

# 只看某个分组
cargo run --release -- --config browser.example.toml --only-group 'Anne'

```

## Config

配置文件使用 TOML。示例见 `browser.example.toml`：

```toml
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
name = "Anne SourceBans"
url = "https://example.com/sourcebans"
```

`sourcebans.url` 可以填站点根路径，也可以直接填 `index.php?p=servers`。工具会从页面里提取 `IP:port` 和 `steam://connect/...` 链接。

## GUI / RCON

GUI 模式是原生桌面窗口，不启动网页服务。新增服务器和 SourceBans 订阅会写入 `--config` 指定的 TOML 文件；如果没有传 `--config`，默认写入系统用户配置目录。

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

macOS 压缩包会同时包含命令行二进制和 `L4D2 Server Browser.app`；普通使用直接打开 `.app`。Windows 压缩包里的 `.exe` 默认就是 GUI 程序。

## Notes

- 默认 master server 是 `hl2master.steampowered.com:27011`。
- 默认过滤条件是 `\appid\550`。
- 这是查询工具，不会对服务器发送高频请求；每个服务器最多做一次 `A2S_INFO` 查询，遇到 challenge 会按协议补发一次。
- SourceBans 订阅只读取公开服务器列表页面，不需要数据库权限。
