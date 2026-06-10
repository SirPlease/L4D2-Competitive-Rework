# L4D2 Docker 一键部署脚本说明

本文档对应 `scripts/l4d2-docker.sh`，用于在 Debian/Ubuntu 服务器上一键部署、更新、重启和维护 Anne L4D2 Docker 服务器。

脚本支持从旧版管理脚本读取环境变量，也支持生成新版 `scripts/l4d2-docker.env` 配置文件，方便后续日常更新。

## 适用场景

- 首次部署 L4D2 Docker 服务器
- 从旧版 `sqproxy` 脚本迁移到新版 `a2s-proxy-go`
- 日常 `git pull`、重建镜像、重启游戏容器
- 安装或更新 A2S Go Proxy、A2S 防火墙、透明 A2S redirect/SNAT
- 可选部署地图上传器容器

## 文件说明

```text
scripts/l4d2-docker.sh          一键部署脚本
scripts/l4d2-docker.env         本机私有配置文件，包含密码，不要公开
scripts/l4d2-docker.env.example 配置示例
```

`scripts/l4d2-docker.sh` 和 `scripts/l4d2-docker.env` 是本地部署文件，默认已被 `.gitignore` 忽略。

## 系统要求

- Debian 或 Ubuntu
- root 权限或 `sudo`
- systemd
- Docker 会由脚本自动安装
- 云安全组至少放行公网游戏端口的 UDP

## 从旧脚本迁移

如果你手上有旧版一键脚本，推荐先生成新版 env：

```bash
cd /home/louis/CompetitiveWithAnne
bash scripts/l4d2-docker.sh --legacy-config /path/to/old-script.sh --print-env > scripts/l4d2-docker.env
chmod 600 scripts/l4d2-docker.env
```

生成后先检查配置：

```bash
nano scripts/l4d2-docker.env
```

旧脚本中常见变量会被自动转换：

```text
SERVER_IP             -> L4D2_SERVER_IP 和 L4D2_BIND_IP
GAME_PORTS            -> L4D2_GAME_PORTS
BACKEND_PORTS         -> L4D2_BACKEND_PORTS
BASE_IMAGE_URL        -> L4D2_BASE_IMAGE_URL
BASE_CONTAINER_NAME   -> L4D2_BASE_CONTAINER_NAME
PROD_IMAGE_NAME       -> L4D2_PROD_IMAGE_NAME
GIT_DIR               -> L4D2_GIT_DIR
GIT_PROXY_URL         -> L4D2_GIT_PROXY_URL
HOSTNAME_START_INDEX  -> L4D2_HOSTNAME_START_INDEX
CONTAINER_PREFIX      -> L4D2_CONTAINER_PREFIX
STEAM_GROUP           -> L4D2_STEAM_GROUP
STEAM_ADMIN           -> L4D2_STEAM_ADMIN
MYSQL_*               -> L4D2_MYSQL_*
RCON_PASSWORD         -> L4D2_RCON_PASSWORD
OPTIONAL_STEAM_ID     -> L4D2_OPTIONAL_STEAM_ID
```

`L4D2_SERVER_IP` 是给 Steam/玩家看的公网地址，`L4D2_BIND_IP` 是本机实际监听地址。NAT 机器上通常 `L4D2_SERVER_IP` 是公网 IP，`L4D2_BIND_IP` 是内网 IP；A2S Go Proxy 默认会通过 `L4D2_BIND_IP` 回查本机 srcds。

如果旧脚本里检测到 `sqproxy`，新版脚本会自动启用 `L4D2_GO_PROXY_ENABLE=true`。`--install` / `--update` 会在安装 `a2s-proxy-go` 前停止旧的 `sqproxy` systemd 服务，清理 `/etc/sqproxy`，并尝试删除旧 `tc`/eBPF/qdisc 残留，避免旧网络规则继续影响 Steam 服务器列表。

迁移时还会自动处理端口：

- 旧 `BACKEND_PORTS` 不再作为游戏后端端口使用
- 从旧 `BACKEND_PORTS` 中选第一个作为地图上传器端口
- 重新随机生成同数量的游戏后端端口，范围为 10000 以上
- 默认开启地图上传器，并限制总上传大小为 5120 MB

生成 env 后，脚本会把上传器端口写到：

```bash
L4D2_MAP_UPLOADER_PORT=旧_BACKEND_PORTS_中的第一个端口
```

## 首次安装

确认 `scripts/l4d2-docker.env` 已填好后运行：

```bash
sudo bash scripts/l4d2-docker.sh --install
```

首次安装会执行：

- 安装系统依赖和 Docker
- 清理旧 `sqproxy` 网络状态
- 安装 A2S 防火墙
- 下载并安装 `a2s-proxy-go`
- 生成 `/etc/a2s-proxy-go/config.json`
- 如果启用 A2S only 模式，生成透明 A2S redirect/SNAT 规则
- 初始化基础容器
- 拉取仓库更新并重建运行镜像
- 启动全部游戏容器

## 日常更新

平时更新服务器内容用：

```bash
sudo bash scripts/l4d2-docker.sh --update
```

该命令会：

- 清理旧 `sqproxy` 网络状态
- 重建 A2S firewall / redirect/SNAT 规则
- 启动基础容器
- 在基础容器内执行 `git pull --ff-only`
- 重建运行镜像
- 删除并重建游戏容器
- 如果地图上传器启用，拉取/构建上传器镜像并重建上传器容器
- 更新或重启 A2S Go Proxy
- 显示当前状态

如果只想重启容器和相关服务：

```bash
sudo bash scripts/l4d2-docker.sh --restart
```

查看状态：

```bash
bash scripts/l4d2-docker.sh --status
```

## A2S Go Proxy

默认下载地址：

```text
L4D2_GO_PROXY_URL=https://anne.trygek.com/file_download.php?name=a2s-proxy-go
L4D2_GO_PROXY_VERSION_URL=https://anne.trygek.com/file_download.php?name=version
```

常用配置：

```bash
L4D2_GO_PROXY_ENABLE=true
L4D2_GO_PROXY_FORCE_DOWNLOAD=false
```

强制重新下载 Go Proxy：

```bash
sudo L4D2_GO_PROXY_FORCE_DOWNLOAD=true bash scripts/l4d2-docker.sh --update
```

手动只安装或刷新 Go Proxy，可以运行完整更新；脚本会先读取远端 `version` 文件，再通过本地二进制的 `-version` 输出判断是否需要更新。下载完成后也会校验二进制实际版本必须等于远端 `version`。

如果远端 `version` 不可用，脚本会尝试使用本地候选二进制；如果本地候选版本高于已安装版本，也会自动覆盖安装。如果远端 `version` 可用但下载失败，本地候选必须与远端版本一致才会被使用：

```text
scripts/a2s-proxy-go
scripts/a2s_proxy_go
/usr/local/bin/a2s-proxy-go
/usr/local/bin/a2s_proxy_go
```

也可以自己指定候选路径：

```bash
L4D2_GO_PROXY_LOCAL_CANDIDATES="/root/a2s-proxy-go /opt/bin/a2s_proxy_go"
```

## srcds 查询限速配置写入位置

启用 Go Proxy 后，脚本会写入以下 `sm_cvar`，避免本机 A2S 代理查询后端时被 srcds 限速：

```text
sm_cvar sv_max_queries_sec_global 1000
sm_cvar sv_max_queries_sec 100
sm_cvar sv_max_queries_window 30
```

写入文件可自定义：

```bash
L4D2_SRCDS_QUERY_CFG_FILE=/home/louis/CompetitiveWithAnne/cfg/server.cfg
```

如果留空，默认写入容器内：

```text
${L4D2_GIT_DIR}/cfg/server.cfg
```

这适合 base 容器还没有复制插件到 `/home/louis/l4d2/left4dead2/cfg` 的阶段。

## 端口模式

旧前置代理模式：

```bash
L4D2_GO_PROXY_ENABLE=true
L4D2_GO_PROXY_MODE=front-proxy
L4D2_GO_PROXY_TRANSPARENT_REDIRECT=false
```

这种模式下：

- `L4D2_GAME_PORTS` 是公网入口端口
- `L4D2_BACKEND_PORTS` 是游戏容器后端端口
- Go Proxy 监听公网入口端口并转发到后端端口
- 这是兼容旧前置代理行为的模式，不再作为默认推荐

A2S only 模式：

```bash
L4D2_GO_PROXY_ENABLE=true
L4D2_GO_PROXY_MODE=a2s-only
L4D2_GO_PROXY_TRANSPARENT_REDIRECT=true
```

这种模式下：

- srcds 直接监听公网游戏端口
- iptables 只把 A2S 查询包重定向到 Go Proxy
- iptables 会把 Go Proxy 回客户端的 UDP 源端口改回公网游戏端口
- 非 A2S 游戏流量仍直接进入 srcds
- `BACKEND_PORTS` 只作为 Go Proxy 内部监听端口，不再作为游戏后端端口
- Go Proxy 默认回查 `L4D2_BIND_IP:L4D2_GAME_PORTS`，如果你的 srcds 只能通过其他本机地址访问，可以设置 `L4D2_GO_PROXY_BACKEND_IP`
- `0x57` / `0x69` 会进入 Go Proxy 后直接丢弃，不再查询后端，也不回应客户端

从老 `sqproxy` 脚本迁移时，默认会进入 A2S only 模式。如果旧配置里残留 `L4D2_GO_PROXY_TRANSPARENT_REDIRECT=false`，默认 `L4D2_GO_PROXY_MODE=a2s-only` 会在加载配置时自动改回 true。只有明确设置 `L4D2_GO_PROXY_MODE=front-proxy` 时，Go Proxy 才会占用公网游戏端口，游戏容器改用 backend 端口。

## A2S 防火墙

默认启用：

```bash
L4D2_A2S_FIREWALL_ENABLE=true
L4D2_A2S_FIREWALL_PORTS=auto
L4D2_A2S_INFO_RATE=200/second
L4D2_A2S_INFO_BURST=300
L4D2_A2S_PLAYER_RATE=160/second
L4D2_A2S_PLAYER_BURST=240
L4D2_A2S_RULES_RATE=120/second
L4D2_A2S_RULES_BURST=180
L4D2_A2S_BAN_HITCOUNT=50
L4D2_A2S_BAN_SECONDS=10
```

这组默认值按单机 8 个求生服放宽过，优先保证 Steam 组页面能扫到服务器。如果 Steam 组页面服务器仍然变少，可以先执行 `--remove-a2s` 临时验证；确认是防火墙导致后，再提高 `L4D2_A2S_*_RATE` / `L4D2_A2S_*_BURST`，或降低封禁时间。

单独安装或刷新：

```bash
sudo bash scripts/l4d2-docker.sh --install-a2s
```

移除：

```bash
sudo bash scripts/l4d2-docker.sh --remove-a2s
```

## 地图上传器

启用地图上传器：

```bash
L4D2_MAP_UPLOADER_ENABLE=true
L4D2_MAP_UPLOADER_IMAGE_NAME=docker.trygek.com/morzlee/vpk-uploader:latest
L4D2_MAP_UPLOADER_REFRESH_IMAGE=false
L4D2_MAP_UPLOADER_PORT=13009
L4D2_MAP_UPLOADER_MAX_TOTAL_UPLOAD_MB=5120
L4D2_MAP_UPLOADER_APP_SECRET=CHANGE_ME
L4D2_MAP_UPLOADER_ADMIN_PASS=CHANGE_ME
```

安装：

```bash
sudo bash scripts/l4d2-docker.sh --install-uploader
```

日常 `--update` 也会重建上传器容器。默认只删除旧上传器容器，然后用本地已有镜像启动新容器，不会重新拉取镜像。如果需要强制刷新远程镜像，设置 `L4D2_MAP_UPLOADER_REFRESH_IMAGE=true`，脚本会删除旧容器和旧镜像，再 `docker pull` 新镜像并启动新容器。如果 `L4D2_MAP_UPLOADER_DIR` 指向本地上传器源码目录，则会本地 `docker build`。

移除：

```bash
sudo bash scripts/l4d2-docker.sh --remove-uploader
```

上传目录默认会共享给游戏容器：

```text
L4D2_MAP_UPLOADER_DATA_DIR=/opt/vpk-uploader/data
L4D2_MAP_UPLOAD_DIR=/opt/vpk-uploader/data/uploads
L4D2_GAME_MAP_MOUNT_DIR=/map
```

含义：

- 上传器容器内最终服务器版 VPK 目录是 `/app/data/uploads`
- 宿主机对应目录是 `L4D2_MAP_UPLOAD_DIR`
- 游戏容器会把同一个宿主目录挂到 `L4D2_GAME_MAP_MOUNT_DIR`

默认情况下，上传器写入的最终 VPK 会立刻出现在游戏容器的 `/map` 目录。

## 常用命令速查

```bash
# 查看帮助
bash scripts/l4d2-docker.sh --help

# 从旧脚本生成新版配置
bash scripts/l4d2-docker.sh --legacy-config /path/to/old-script.sh --print-env > scripts/l4d2-docker.env

# 首次安装
sudo bash scripts/l4d2-docker.sh --install

# 日常更新
sudo bash scripts/l4d2-docker.sh --update

# 重启
sudo bash scripts/l4d2-docker.sh --restart

# 查看状态
bash scripts/l4d2-docker.sh --status

# 卸载
sudo bash scripts/l4d2-docker.sh --uninstall
```

## 注意事项

- `scripts/l4d2-docker.env` 包含数据库密码、RCON 密码等敏感信息，不要发到公网。
- 修改端口后，需要同步检查云安全组、防火墙和容器端口。
- 旧 `sqproxy` 迁移到 Go Proxy 后，不建议再手动启动 `sqproxy`。
- 如果 `--update` 失败，优先查看 `docker ps -a`、`journalctl -u a2s-proxy-go` 和 `bash scripts/l4d2-docker.sh --status`。
- 首次部署或迁移后，建议用 Steam 服务端浏览器和游戏客户端都测试一次公网入口端口。
