#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

# ══════════════════════════════════════════════════════════════
# CONFIGURATION
# ══════════════════════════════════════════════════════════════
# All settings have sensible defaults. Override any variable by
# passing  -c /path/to/config.sh  on the command line.
# Variables marked CHANGE_ME *must* be set before --install.
# ══════════════════════════════════════════════════════════════

DEFAULT_L4D2_SERVER_COUNT="8"
DEFAULT_L4D2_GAME_PORTS="12001 12002 12003 12004 12005 12006 12007 12008"
DEFAULT_L4D2_BACKEND_PORTS="12009 12010 12011 12012 12013 12014 12015 12016"
DEFAULT_L4D2_CONTAINER_PREFIX="anne"
DEFAULT_L4D2_HOSTNAME_START_INDEX="27"
DEFAULT_L4D2_HOSTNAME_PREFIX="Anne Server #"
DEFAULT_L4D2_BASE_IMAGE_URL="docker.1panel.live/morzlee/l4d2:latest"
DEFAULT_L4D2_BASE_CONTAINER_NAME="l4d2base"
DEFAULT_L4D2_PROD_IMAGE_NAME="morzlee/l4d2:base"
DEFAULT_L4D2_GIT_DIR="/home/louis/CompetitiveWithAnne"
DEFAULT_L4D2_GIT_PROXY_URL="https://gh-proxy.org/https://github.com/fantasylidong/CompetitiveWithAnne.git"

# ── Network ──────────────────────────────────────────────────
L4D2_SERVER_IP="${L4D2_SERVER_IP:-}"
L4D2_BIND_IP="${L4D2_BIND_IP:-}"

# ── Server Layout ────────────────────────────────────────────
L4D2_SERVER_COUNT="${L4D2_SERVER_COUNT:-$DEFAULT_L4D2_SERVER_COUNT}"
L4D2_GAME_PORTS="${L4D2_GAME_PORTS:-$DEFAULT_L4D2_GAME_PORTS}"
L4D2_BACKEND_PORTS="${L4D2_BACKEND_PORTS:-$DEFAULT_L4D2_BACKEND_PORTS}"
L4D2_CONTAINER_PREFIX="${L4D2_CONTAINER_PREFIX:-$DEFAULT_L4D2_CONTAINER_PREFIX}"
L4D2_HOSTNAME_START_INDEX="${L4D2_HOSTNAME_START_INDEX:-$DEFAULT_L4D2_HOSTNAME_START_INDEX}"
L4D2_HOSTNAME_PREFIX="${L4D2_HOSTNAME_PREFIX:-$DEFAULT_L4D2_HOSTNAME_PREFIX}"

# ── Docker Images ────────────────────────────────────────────
L4D2_BASE_IMAGE_URL="${L4D2_BASE_IMAGE_URL:-$DEFAULT_L4D2_BASE_IMAGE_URL}"
L4D2_BASE_CONTAINER_NAME="${L4D2_BASE_CONTAINER_NAME:-$DEFAULT_L4D2_BASE_CONTAINER_NAME}"
L4D2_PROD_IMAGE_NAME="${L4D2_PROD_IMAGE_NAME:-$DEFAULT_L4D2_PROD_IMAGE_NAME}"

# ── Git Repository ───────────────────────────────────────────
L4D2_GIT_DIR="${L4D2_GIT_DIR:-$DEFAULT_L4D2_GIT_DIR}"
L4D2_GIT_PROXY_URL="${L4D2_GIT_PROXY_URL:-$DEFAULT_L4D2_GIT_PROXY_URL}"

# ── Game Runtime ─────────────────────────────────────────────
L4D2_TIMEZONE="${L4D2_TIMEZONE:-Asia/Shanghai}"
L4D2_MAP_UPLOAD_DIR="${L4D2_MAP_UPLOAD_DIR:-/map/uploads}"
L4D2_DEFAULT_MAP="${L4D2_DEFAULT_MAP:-c2m1_highway}"
L4D2_REGION="${L4D2_REGION:-255}"
L4D2_PLUGIN="${L4D2_PLUGIN:-zone}"
L4D2_CLOUD="${L4D2_CLOUD:-true}"

# ── Map Uploader Docker ─────────────────────────────────────
L4D2_MAP_UPLOADER_ENABLE="${L4D2_MAP_UPLOADER_ENABLE:-false}"
L4D2_MAP_UPLOADER_DIR="${L4D2_MAP_UPLOADER_DIR:-}"
L4D2_MAP_UPLOADER_IMAGE_NAME="${L4D2_MAP_UPLOADER_IMAGE_NAME:-morzlee/vpk-uploader:local}"
L4D2_MAP_UPLOADER_CONTAINER_NAME="${L4D2_MAP_UPLOADER_CONTAINER_NAME:-vpk-uploader}"
L4D2_MAP_UPLOADER_BIND_IP="${L4D2_MAP_UPLOADER_BIND_IP:-0.0.0.0}"
L4D2_MAP_UPLOADER_PORT="${L4D2_MAP_UPLOADER_PORT:-8080}"
L4D2_MAP_UPLOADER_DATA_DIR="${L4D2_MAP_UPLOADER_DATA_DIR:-/opt/vpk-uploader/data}"
L4D2_MAP_UPLOADER_RULES_FILE="${L4D2_MAP_UPLOADER_RULES_FILE:-}"
L4D2_MAP_UPLOADER_PUBLIC_BASE_URL="${L4D2_MAP_UPLOADER_PUBLIC_BASE_URL:-}"
L4D2_MAP_UPLOADER_APP_SECRET="${L4D2_MAP_UPLOADER_APP_SECRET:-CHANGE_ME}"
L4D2_MAP_UPLOADER_ADMIN_USER="${L4D2_MAP_UPLOADER_ADMIN_USER:-admin}"
L4D2_MAP_UPLOADER_ADMIN_PASS="${L4D2_MAP_UPLOADER_ADMIN_PASS:-CHANGE_ME}"
L4D2_MAP_UPLOADER_MAX_UPLOAD_MB="${L4D2_MAP_UPLOADER_MAX_UPLOAD_MB:-1024}"
L4D2_MAP_UPLOADER_MAX_TOTAL_UPLOAD_MB="${L4D2_MAP_UPLOADER_MAX_TOTAL_UPLOAD_MB:-0}"
L4D2_MAP_UPLOADER_GUEST_TTL_HOURS="${L4D2_MAP_UPLOADER_GUEST_TTL_HOURS:-24}"

# ── Steam Settings (CHANGE_ME) ───────────────────────────────
L4D2_STEAM_GROUP="${L4D2_STEAM_GROUP:-CHANGE_ME}"
L4D2_STEAM_ADMIN="${L4D2_STEAM_ADMIN:-CHANGE_ME}"
L4D2_OPTIONAL_STEAM_ID="${L4D2_OPTIONAL_STEAM_ID:-}"

# ── Database & RCON (CHANGE_ME) ──────────────────────────────
L4D2_MYSQL_HOST="${L4D2_MYSQL_HOST:-CHANGE_ME}"
L4D2_MYSQL_PORT="${L4D2_MYSQL_PORT:-12345}"
L4D2_MYSQL_USER="${L4D2_MYSQL_USER:-CHANGE_ME}"
L4D2_MYSQL_PASSWORD="${L4D2_MYSQL_PASSWORD:-CHANGE_ME}"
L4D2_RCON_PASSWORD="${L4D2_RCON_PASSWORD:-CHANGE_ME}"

# ── Go Proxy Settings ───────────────────────────────────────
L4D2_GO_PROXY_ENABLE="${L4D2_GO_PROXY_ENABLE:-false}"
L4D2_GO_PROXY_TRANSPARENT_REDIRECT="${L4D2_GO_PROXY_TRANSPARENT_REDIRECT:-false}"
L4D2_GO_PROXY_URL="${L4D2_GO_PROXY_URL:-https://binaries.l4d2node.org/a2s-proxy-go-linux-amd64}"
L4D2_GO_PROXY_VERSION_URL="${L4D2_GO_PROXY_VERSION_URL:-https://binaries.l4d2node.org/a2s-proxy-go-linux-amd64.version}"
L4D2_GO_PROXY_BIN="${L4D2_GO_PROXY_BIN:-/usr/local/bin/a2s-proxy-go}"
L4D2_GO_PROXY_CONFIG="${L4D2_GO_PROXY_CONFIG:-/etc/a2s-proxy-go/config.json}"
L4D2_GO_PROXY_REDIRECT_BIN="${L4D2_GO_PROXY_REDIRECT_BIN:-/usr/local/bin/a2s-proxy-redirect.sh}"
L4D2_GO_PROXY_FORCE_DOWNLOAD="${L4D2_GO_PROXY_FORCE_DOWNLOAD:-false}"
L4D2_GO_PROXY_BACKEND_IP="${L4D2_GO_PROXY_BACKEND_IP:-}"
L4D2_GO_PROXY_CACHE_TTL_SECONDS="${L4D2_GO_PROXY_CACHE_TTL_SECONDS:-2}"
L4D2_GO_PROXY_PLAYER_CACHE_TTL_SECONDS="${L4D2_GO_PROXY_PLAYER_CACHE_TTL_SECONDS:-2}"
L4D2_GO_PROXY_RULES_CACHE_TTL_SECONDS="${L4D2_GO_PROXY_RULES_CACHE_TTL_SECONDS:-10}"
L4D2_GO_PROXY_SESSION_IDLE_SECONDS="${L4D2_GO_PROXY_SESSION_IDLE_SECONDS:-30}"
L4D2_GO_PROXY_WORKER_COUNT="${L4D2_GO_PROXY_WORKER_COUNT:-64}"
L4D2_GO_PROXY_QUEUE_SIZE="${L4D2_GO_PROXY_QUEUE_SIZE:-4096}"
L4D2_GO_PROXY_SOCKET_BUFFER_BYTES="${L4D2_GO_PROXY_SOCKET_BUFFER_BYTES:-4194304}"
L4D2_GO_PROXY_MAX_SESSIONS="${L4D2_GO_PROXY_MAX_SESSIONS:-4096}"
L4D2_GO_PROXY_MAX_SESSIONS_PER_IP="${L4D2_GO_PROXY_MAX_SESSIONS_PER_IP:-32}"
L4D2_GO_PROXY_BYPASS_CACHE_IPS="${L4D2_GO_PROXY_BYPASS_CACHE_IPS:-}"
L4D2_GO_PROXY_BYPASS_CACHE_PROBE="${L4D2_GO_PROXY_BYPASS_CACHE_PROBE:-false}"
L4D2_GO_PROXY_MASTER_REGISTER="${L4D2_GO_PROXY_MASTER_REGISTER:-false}"
L4D2_GO_PROXY_MASTER_ADDR="${L4D2_GO_PROXY_MASTER_ADDR:-}"                  # Empty = default hl2master.steampowered.com:27011
L4D2_GO_PROXY_MASTER_INTERVAL="${L4D2_GO_PROXY_MASTER_INTERVAL:-300}"       # Heartbeat interval in seconds
L4D2_GO_PROXY_DEBUG="${L4D2_GO_PROXY_DEBUG:-false}"
L4D2_GO_PROXY_STATS_INTERVAL="${L4D2_GO_PROXY_STATS_INTERVAL:-10}"
L4D2_GO_PROXY_STATS_LOG_FILE="${L4D2_GO_PROXY_STATS_LOG_FILE:-}"
L4D2_GO_PROXY_STATS_THRESHOLD="${L4D2_GO_PROXY_STATS_THRESHOLD:-100}"

# ── A2S Firewall Settings ───────────────────────────────────
L4D2_A2S_FIREWALL_ENABLE="${L4D2_A2S_FIREWALL_ENABLE:-true}"
L4D2_A2S_FIREWALL_PORTS="${L4D2_A2S_FIREWALL_PORTS:-auto}"
L4D2_A2S_PLAYER_RATE="${L4D2_A2S_PLAYER_RATE:-15/second}"
L4D2_A2S_PLAYER_BURST="${L4D2_A2S_PLAYER_BURST:-10}"
L4D2_A2S_INFO_RATE="${L4D2_A2S_INFO_RATE:-15/second}"
L4D2_A2S_INFO_BURST="${L4D2_A2S_INFO_BURST:-10}"
L4D2_A2S_RULES_RATE="${L4D2_A2S_RULES_RATE:-10/second}"
L4D2_A2S_RULES_BURST="${L4D2_A2S_RULES_BURST:-5}"
L4D2_A2S_OTHER_RATE="${L4D2_A2S_OTHER_RATE:-10/second}"
L4D2_A2S_OTHER_BURST="${L4D2_A2S_OTHER_BURST:-5}"
L4D2_A2S_BAN_SECONDS="${L4D2_A2S_BAN_SECONDS:-60}"
L4D2_A2S_BAN_HITCOUNT="${L4D2_A2S_BAN_HITCOUNT:-3}"
L4D2_A2S_HASH_EXPIRE_MS="${L4D2_A2S_HASH_EXPIRE_MS:-60000}"
L4D2_A2S_LOG_LIMIT="${L4D2_A2S_LOG_LIMIT:-5/min}"

# ── Master SNAT Settings ────────────────────────────────────
L4D2_MASTER_SNAT_ENABLE="${L4D2_MASTER_SNAT_ENABLE:-false}"
L4D2_MASTER_SNAT_DEST="${L4D2_MASTER_SNAT_DEST:-hl2master.steampowered.com:27011}"
L4D2_MASTER_SNAT_BIN="${L4D2_MASTER_SNAT_BIN:-/usr/local/bin/a2s-master-snat.sh}"

# ── Misc ─────────────────────────────────────────────────────
L4D2_APT_MIRROR="${L4D2_APT_MIRROR:-}"
L4D2_ASSUME_YES="${L4D2_ASSUME_YES:-0}"
L4D2_REMOVE_BASE_IMAGE="${L4D2_REMOVE_BASE_IMAGE:-1}"
L4D2_REMOVE_RUNTIME_IMAGE="${L4D2_REMOVE_RUNTIME_IMAGE:-1}"

# ══════════════════════════════════════════════════════════════
# INTERNAL STATE
# ══════════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

OS_ID=unknown
OS_VERSION_ID=unknown
OS_CODENAME=
TEMP_FILES=()
GAME_PORTS_ARRAY=()
BACKEND_PORTS_ARRAY=()
PROXY_LISTEN_PORTS_ARRAY=()
A2S_PORT_ITEMS=()
A2S_PORT_CHUNKS=()

# ══════════════════════════════════════════════════════════════
# UTILITIES
# ══════════════════════════════════════════════════════════════

log() { echo -e "${BLUE}[INFO]${NC} $*"; }
ok() { echo -e "${GREEN}[OK]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
err() { echo -e "${RED}[ERR]${NC} $*" >&2; }
die() {
  err "$*"
  exit 1
}

cleanup() {
  if ((${#TEMP_FILES[@]} > 0)); then
    rm -f "${TEMP_FILES[@]}" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

check_cmd() {
  command -v "$1" >/dev/null 2>&1
}

require_root() {
  [[ "$(id -u)" -eq 0 ]] || die "Please run as root or with sudo."
}

require_systemd() {
  check_cmd systemctl || die "systemctl is required for service management."
}

source_config_file() {
  local config_file="$1"
  [[ -n "$config_file" ]] || die "Config file path is empty."
  [[ -f "$config_file" ]] || die "Config file not found: $config_file"
  # shellcheck source=/dev/null
  source "$config_file"
  ok "Loaded config override: $config_file"
}

configure_needrestart() {
  if [[ -d /etc/needrestart/conf.d ]]; then
    printf "%s\n" "\$nrconf{restart} = 'a';" >/etc/needrestart/conf.d/50-l4d2-autorestart.conf
  fi
}

value_or_default() {
  local value="$1"
  local fallback="$2"
  if [[ -n "$value" ]]; then
    printf '%s\n' "$value"
  else
    printf '%s\n' "$fallback"
  fi
}

legacy_value_to_words() {
  local name="$1"
  local declaration count i value
  local values=()
  declaration="$(declare -p "$name" 2>/dev/null || true)"
  [[ -n "$declaration" ]] || return 0

  if [[ "$declaration" == declare\ -a* || "$declaration" == declare\ -ax* ]]; then
    eval "count=\${#${name}[@]}"
    for ((i = 0; i < count; i++)); do
      eval "value=\${${name}[${i}]}"
      values+=("$value")
    done
    printf '%s\n' "${values[*]}"
    return
  fi

  eval "value=\${${name}:-}"
  value="${value//,/ }"
  printf '%s\n' "$value"
}

word_count() {
  local raw="$1"
  local words=()
  raw="${raw//,/ }"
  read -r -a words <<<"$raw"
  printf '%s\n' "${#words[@]}"
}

write_shell_assignment() {
  local name="$1"
  local value
  eval "value=\${${name}}"
  printf '%s=%q\n' "$name" "$value"
}

load_legacy_env_file() {
  local legacy_file="$1"
  [[ -n "$legacy_file" ]] || die "Legacy config file path is empty."
  [[ -f "$legacy_file" ]] || die "Legacy config file not found: $legacy_file"

  local temp_file
  temp_file="$(mktemp)"
  TEMP_FILES+=("$temp_file")

  grep -E '^[[:space:]]*(export[[:space:]]+)?(SERVER_IP|GAME_PORTS|BACKEND_PORTS|BASE_IMAGE_URL|BASE_CONTAINER_NAME|CONTAINER_NAME|PROD_IMAGE_NAME|GIT_DIR|GIT_PROXY_URL|HOSTNAME_START_INDEX|HOSTNAME_PREFIX|HOSTNAME_STR|CONTAINER_PREFIX|STEAM_GROUP|STEAM_ADMIN|MYSQL_HOST|MYSQL_PORT|MYSQL_USER|MYSQL_PASSWORD|RCON_PASSWORD|OPTIONAL_STEAM_ID)[[:space:]]*=' "$legacy_file" >"$temp_file" || true
  [[ -s "$temp_file" ]] || die "No supported legacy config assignments found in: $legacy_file"

  local state_file
  state_file="$(mktemp)"
  TEMP_FILES+=("$state_file")

  (
    set -euo pipefail
    HOST_NUM="__L4D2_HOST_NUM__"
    source "$temp_file"

    if [[ "$L4D2_SERVER_IP" == "" && -n "${SERVER_IP:-}" ]]; then
      L4D2_SERVER_IP="$SERVER_IP"
    fi
    local legacy_game_ports legacy_backend_ports
    legacy_game_ports="$(legacy_value_to_words GAME_PORTS)"
    if [[ -n "$legacy_game_ports" ]]; then
      if [[ "$L4D2_GAME_PORTS" == "$DEFAULT_L4D2_GAME_PORTS" ]]; then
        L4D2_GAME_PORTS="$legacy_game_ports"
      fi
      if [[ "$L4D2_SERVER_COUNT" == "$DEFAULT_L4D2_SERVER_COUNT" ]]; then
        L4D2_SERVER_COUNT="$(word_count "$legacy_game_ports")"
      fi
    fi
    legacy_backend_ports="$(legacy_value_to_words BACKEND_PORTS)"
    if [[ -n "$legacy_backend_ports" ]]; then
      if [[ "$L4D2_BACKEND_PORTS" == "$DEFAULT_L4D2_BACKEND_PORTS" ]]; then
        L4D2_BACKEND_PORTS="$legacy_backend_ports"
      fi
      if [[ "$L4D2_SERVER_COUNT" == "$DEFAULT_L4D2_SERVER_COUNT" ]]; then
        L4D2_SERVER_COUNT="$(word_count "$legacy_backend_ports")"
      fi
    fi
    if [[ "$L4D2_BASE_IMAGE_URL" == "$DEFAULT_L4D2_BASE_IMAGE_URL" && -n "${BASE_IMAGE_URL:-}" ]]; then
      L4D2_BASE_IMAGE_URL="$BASE_IMAGE_URL"
    fi
    if [[ "$L4D2_BASE_CONTAINER_NAME" == "$DEFAULT_L4D2_BASE_CONTAINER_NAME" ]]; then
      L4D2_BASE_CONTAINER_NAME="$(value_or_default "${BASE_CONTAINER_NAME:-${CONTAINER_NAME:-}}" "$L4D2_BASE_CONTAINER_NAME")"
    fi
    if [[ "$L4D2_PROD_IMAGE_NAME" == "$DEFAULT_L4D2_PROD_IMAGE_NAME" && -n "${PROD_IMAGE_NAME:-}" ]]; then
      L4D2_PROD_IMAGE_NAME="$PROD_IMAGE_NAME"
    fi
    if [[ "$L4D2_GIT_DIR" == "$DEFAULT_L4D2_GIT_DIR" && -n "${GIT_DIR:-}" ]]; then
      L4D2_GIT_DIR="$GIT_DIR"
    fi
    if [[ "$L4D2_GIT_PROXY_URL" == "$DEFAULT_L4D2_GIT_PROXY_URL" && -n "${GIT_PROXY_URL:-}" ]]; then
      L4D2_GIT_PROXY_URL="$GIT_PROXY_URL"
    fi
    if [[ "$L4D2_HOSTNAME_START_INDEX" == "$DEFAULT_L4D2_HOSTNAME_START_INDEX" && -n "${HOSTNAME_START_INDEX:-}" ]]; then
      L4D2_HOSTNAME_START_INDEX="$HOSTNAME_START_INDEX"
    fi
    if [[ "$L4D2_HOSTNAME_PREFIX" == "$DEFAULT_L4D2_HOSTNAME_PREFIX" && -n "${HOSTNAME_PREFIX:-}" ]]; then
      L4D2_HOSTNAME_PREFIX="$HOSTNAME_PREFIX"
    fi
    if [[ "$L4D2_HOSTNAME_PREFIX" == "$DEFAULT_L4D2_HOSTNAME_PREFIX" && -n "${HOSTNAME_STR:-}" ]]; then
      L4D2_HOSTNAME_PREFIX="${HOSTNAME_STR%%__L4D2_HOST_NUM__*}"
      [[ -n "$L4D2_HOSTNAME_PREFIX" ]] || L4D2_HOSTNAME_PREFIX="$DEFAULT_L4D2_HOSTNAME_PREFIX"
    fi
    if [[ "$L4D2_CONTAINER_PREFIX" == "$DEFAULT_L4D2_CONTAINER_PREFIX" && -n "${CONTAINER_PREFIX:-}" ]]; then
      L4D2_CONTAINER_PREFIX="$CONTAINER_PREFIX"
    fi
    if [[ "$L4D2_STEAM_GROUP" == "CHANGE_ME" && -n "${STEAM_GROUP:-}" ]]; then
      L4D2_STEAM_GROUP="$STEAM_GROUP"
    fi
    if [[ "$L4D2_STEAM_ADMIN" == "CHANGE_ME" && -n "${STEAM_ADMIN:-}" ]]; then
      L4D2_STEAM_ADMIN="$STEAM_ADMIN"
    fi
    if [[ -z "$L4D2_OPTIONAL_STEAM_ID" && -n "${OPTIONAL_STEAM_ID:-}" ]]; then
      L4D2_OPTIONAL_STEAM_ID="$OPTIONAL_STEAM_ID"
    fi
    if [[ "$L4D2_MYSQL_HOST" == "CHANGE_ME" && -n "${MYSQL_HOST:-}" ]]; then
      L4D2_MYSQL_HOST="$MYSQL_HOST"
    fi
    if [[ "$L4D2_MYSQL_PORT" == "12345" && -n "${MYSQL_PORT:-}" ]]; then
      L4D2_MYSQL_PORT="$MYSQL_PORT"
    fi
    if [[ "$L4D2_MYSQL_USER" == "CHANGE_ME" && -n "${MYSQL_USER:-}" ]]; then
      L4D2_MYSQL_USER="$MYSQL_USER"
    fi
    if [[ "$L4D2_MYSQL_PASSWORD" == "CHANGE_ME" && -n "${MYSQL_PASSWORD:-}" ]]; then
      L4D2_MYSQL_PASSWORD="$MYSQL_PASSWORD"
    fi
    if [[ "$L4D2_RCON_PASSWORD" == "CHANGE_ME" && -n "${RCON_PASSWORD:-}" ]]; then
      L4D2_RCON_PASSWORD="$RCON_PASSWORD"
    fi

    for name in \
      L4D2_SERVER_IP L4D2_SERVER_COUNT L4D2_GAME_PORTS L4D2_BACKEND_PORTS \
      L4D2_BASE_IMAGE_URL L4D2_BASE_CONTAINER_NAME L4D2_PROD_IMAGE_NAME \
      L4D2_GIT_DIR L4D2_GIT_PROXY_URL L4D2_HOSTNAME_START_INDEX L4D2_HOSTNAME_PREFIX L4D2_CONTAINER_PREFIX \
      L4D2_STEAM_GROUP L4D2_STEAM_ADMIN L4D2_OPTIONAL_STEAM_ID \
      L4D2_MYSQL_HOST L4D2_MYSQL_PORT L4D2_MYSQL_USER L4D2_MYSQL_PASSWORD L4D2_RCON_PASSWORD; do
      write_shell_assignment "$name"
    done
  ) >"$state_file"

  source "$state_file"
  ok "Loaded legacy config values: $legacy_file"
}

# ══════════════════════════════════════════════════════════════
# CONFIG LOADING
# ══════════════════════════════════════════════════════════════

load_config() {
  # Variables are already set in the CONFIGURATION block above.
  # If -c config.sh was given, it was sourced before this function,
  # so any overrides are already in effect.

  apply_legacy_config_aliases

  local raw_game_ports raw_backend_ports
  raw_game_ports="${L4D2_GAME_PORTS//,/ }"
  raw_backend_ports="${L4D2_BACKEND_PORTS//,/ }"
  read -r -a GAME_PORTS_ARRAY <<<"$raw_game_ports"
  read -r -a BACKEND_PORTS_ARRAY <<<"$raw_backend_ports"
  PROXY_LISTEN_PORTS_ARRAY=()
  local i proxy_count
  proxy_count="${#GAME_PORTS_ARRAY[@]}"
  if ((proxy_count > ${#BACKEND_PORTS_ARRAY[@]})); then
    proxy_count="${#BACKEND_PORTS_ARRAY[@]}"
  fi
  for ((i = 0; i < proxy_count; i++)); do
    if is_enabled "$L4D2_GO_PROXY_TRANSPARENT_REDIRECT"; then
      PROXY_LISTEN_PORTS_ARRAY+=("${BACKEND_PORTS_ARRAY[$i]}")
    else
      PROXY_LISTEN_PORTS_ARRAY+=("${GAME_PORTS_ARRAY[$i]}")
    fi
  done
}

apply_legacy_config_aliases() {
  if [[ -z "$L4D2_SERVER_IP" && -n "${SERVER_IP:-}" ]]; then
    L4D2_SERVER_IP="$SERVER_IP"
  fi
  local legacy_game_ports legacy_backend_ports
  legacy_game_ports="$(legacy_value_to_words GAME_PORTS)"
  if [[ -n "$legacy_game_ports" ]]; then
    if [[ "$L4D2_GAME_PORTS" == "$DEFAULT_L4D2_GAME_PORTS" ]]; then
      L4D2_GAME_PORTS="$legacy_game_ports"
    fi
    if [[ "$L4D2_SERVER_COUNT" == "$DEFAULT_L4D2_SERVER_COUNT" ]]; then
      L4D2_SERVER_COUNT="$(word_count "$legacy_game_ports")"
    fi
  fi
  legacy_backend_ports="$(legacy_value_to_words BACKEND_PORTS)"
  if [[ -n "$legacy_backend_ports" ]]; then
    if [[ "$L4D2_BACKEND_PORTS" == "$DEFAULT_L4D2_BACKEND_PORTS" ]]; then
      L4D2_BACKEND_PORTS="$legacy_backend_ports"
    fi
    if [[ "$L4D2_SERVER_COUNT" == "$DEFAULT_L4D2_SERVER_COUNT" ]]; then
      L4D2_SERVER_COUNT="$(word_count "$legacy_backend_ports")"
    fi
  fi
  if [[ "$L4D2_BASE_IMAGE_URL" == "$DEFAULT_L4D2_BASE_IMAGE_URL" && -n "${BASE_IMAGE_URL:-}" ]]; then
    L4D2_BASE_IMAGE_URL="$BASE_IMAGE_URL"
  fi
  if [[ "$L4D2_BASE_CONTAINER_NAME" == "$DEFAULT_L4D2_BASE_CONTAINER_NAME" && -n "${BASE_CONTAINER_NAME:-}" ]]; then
    L4D2_BASE_CONTAINER_NAME="$BASE_CONTAINER_NAME"
  fi
  if [[ "$L4D2_BASE_CONTAINER_NAME" == "$DEFAULT_L4D2_BASE_CONTAINER_NAME" && -n "${CONTAINER_NAME:-}" ]]; then
    L4D2_BASE_CONTAINER_NAME="$CONTAINER_NAME"
  fi
  if [[ "$L4D2_PROD_IMAGE_NAME" == "$DEFAULT_L4D2_PROD_IMAGE_NAME" && -n "${PROD_IMAGE_NAME:-}" ]]; then
    L4D2_PROD_IMAGE_NAME="$PROD_IMAGE_NAME"
  fi
  if [[ "$L4D2_GIT_DIR" == "$DEFAULT_L4D2_GIT_DIR" && -n "${GIT_DIR:-}" ]]; then
    L4D2_GIT_DIR="$GIT_DIR"
  fi
  if [[ "$L4D2_GIT_PROXY_URL" == "$DEFAULT_L4D2_GIT_PROXY_URL" && -n "${GIT_PROXY_URL:-}" ]]; then
    L4D2_GIT_PROXY_URL="$GIT_PROXY_URL"
  fi
  if [[ "$L4D2_HOSTNAME_START_INDEX" == "$DEFAULT_L4D2_HOSTNAME_START_INDEX" && -n "${HOSTNAME_START_INDEX:-}" ]]; then
    L4D2_HOSTNAME_START_INDEX="$HOSTNAME_START_INDEX"
  fi
  if [[ "$L4D2_HOSTNAME_PREFIX" == "$DEFAULT_L4D2_HOSTNAME_PREFIX" && -n "${HOSTNAME_PREFIX:-}" ]]; then
    L4D2_HOSTNAME_PREFIX="$HOSTNAME_PREFIX"
  fi
  if [[ "$L4D2_HOSTNAME_PREFIX" == "$DEFAULT_L4D2_HOSTNAME_PREFIX" && -n "${HOSTNAME_STR:-}" ]]; then
    L4D2_HOSTNAME_PREFIX="${HOSTNAME_STR%%\$\{HOST_NUM\}*}"
    [[ -n "$L4D2_HOSTNAME_PREFIX" ]] || L4D2_HOSTNAME_PREFIX="$DEFAULT_L4D2_HOSTNAME_PREFIX"
  fi
  if [[ "$L4D2_CONTAINER_PREFIX" == "$DEFAULT_L4D2_CONTAINER_PREFIX" && -n "${CONTAINER_PREFIX:-}" ]]; then
    L4D2_CONTAINER_PREFIX="$CONTAINER_PREFIX"
  fi
  if [[ "$L4D2_STEAM_GROUP" == "CHANGE_ME" && -n "${STEAM_GROUP:-}" ]]; then
    L4D2_STEAM_GROUP="$STEAM_GROUP"
  fi
  if [[ "$L4D2_STEAM_ADMIN" == "CHANGE_ME" && -n "${STEAM_ADMIN:-}" ]]; then
    L4D2_STEAM_ADMIN="$STEAM_ADMIN"
  fi
  if [[ -z "$L4D2_OPTIONAL_STEAM_ID" && -n "${OPTIONAL_STEAM_ID:-}" ]]; then
    L4D2_OPTIONAL_STEAM_ID="$OPTIONAL_STEAM_ID"
  fi
  if [[ "$L4D2_MYSQL_HOST" == "CHANGE_ME" && -n "${MYSQL_HOST:-}" ]]; then
    L4D2_MYSQL_HOST="$MYSQL_HOST"
  fi
  if [[ "$L4D2_MYSQL_PORT" == "12345" && -n "${MYSQL_PORT:-}" ]]; then
    L4D2_MYSQL_PORT="$MYSQL_PORT"
  fi
  if [[ "$L4D2_MYSQL_USER" == "CHANGE_ME" && -n "${MYSQL_USER:-}" ]]; then
    L4D2_MYSQL_USER="$MYSQL_USER"
  fi
  if [[ "$L4D2_MYSQL_PASSWORD" == "CHANGE_ME" && -n "${MYSQL_PASSWORD:-}" ]]; then
    L4D2_MYSQL_PASSWORD="$MYSQL_PASSWORD"
  fi
  if [[ "$L4D2_RCON_PASSWORD" == "CHANGE_ME" && -n "${RCON_PASSWORD:-}" ]]; then
    L4D2_RCON_PASSWORD="$RCON_PASSWORD"
  fi
}

is_enabled() {
  local value
  value="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
  case "$value" in
    1 | true | yes | on)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

require_not_placeholder() {
  local name="$1"
  local value="${!name:-}"
  [[ -n "$value" ]] || die "$name is required. Set it in the CONFIGURATION block or via -c config.sh."
  [[ "$value" != CHANGE_ME* ]] || die "$name is still CHANGE_ME. Set it in the CONFIGURATION block or via -c config.sh."
}

# ══════════════════════════════════════════════════════════════
# VALIDATION
# ══════════════════════════════════════════════════════════════

validate_port() {
  local name="$1"
  local value="$2"
  [[ "$value" =~ ^[0-9]+$ ]] || die "$name must be a number: $value"
  ((value >= 1 && value <= 65535)) || die "$name must be between 1 and 65535: $value"
}

validate_docker_name() {
  local name="$1"
  local value="$2"
  [[ "$value" =~ ^[A-Za-z0-9][A-Za-z0-9_.-]*$ ]] || die "$name is not a valid Docker name: $value"
}

validate_rate() {
  local name="$1"
  local value="$2"
  [[ "$value" =~ ^[0-9]+/(second|minute|hour|day)$ ]] || die "$name must look like 15/second: $value"
}

validate_positive_number() {
  local name="$1"
  local value="$2"
  [[ "$value" =~ ^[0-9]+$ ]] || die "$name must be a number: $value"
  ((value > 0)) || die "$name must be greater than 0: $value"
}

validate_nonnegative_number() {
  local name="$1"
  local value="$2"
  [[ "$value" =~ ^[0-9]+$ ]] || die "$name must be a number: $value"
}

json_escape() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  value="${value//$'\n'/\\n}"
  value="${value//$'\r'/\\r}"
  value="${value//$'\t'/\\t}"
  printf '%s' "$value"
}

json_string_array_from_words() {
  local raw="$1"
  raw="${raw//,/ }"
  local items=()
  local item
  for item in $raw; do
    [[ -n "$item" ]] || continue
    items+=("$(json_escape "$item")")
  done

  printf '['
  local i
  for ((i = 0; i < ${#items[@]}; i++)); do
    if ((i > 0)); then
      printf ', '
    fi
    printf '"%s"' "${items[$i]}"
  done
  printf ']'
}

add_unique_a2s_port_item() {
  local item="$1"
  local existing
  if ((${#A2S_PORT_ITEMS[@]} > 0)); then
    for existing in "${A2S_PORT_ITEMS[@]}"; do
      [[ "$existing" != "$item" ]] || return 0
    done
  fi
  A2S_PORT_ITEMS+=("$item")
}

validate_port_item() {
  local item="$1"
  local left right
  if [[ "$item" == *:* ]]; then
    left="${item%%:*}"
    right="${item#*:}"
    validate_port "L4D2_A2S_FIREWALL_PORTS" "$left"
    validate_port "L4D2_A2S_FIREWALL_PORTS" "$right"
    ((left <= right)) || die "Invalid A2S port range: $item"
  else
    validate_port "L4D2_A2S_FIREWALL_PORTS" "$item"
  fi
}

build_a2s_port_chunks() {
  A2S_PORT_ITEMS=()
  A2S_PORT_CHUNKS=()

  local raw item i chunk chunk_count
  if [[ -z "$L4D2_A2S_FIREWALL_PORTS" || "$L4D2_A2S_FIREWALL_PORTS" == "auto" ]]; then
    for ((i = 0; i < L4D2_SERVER_COUNT; i++)); do
      add_unique_a2s_port_item "${GAME_PORTS_ARRAY[$i]}"
      add_unique_a2s_port_item "${PROXY_LISTEN_PORTS_ARRAY[$i]}"
    done
  else
    raw="${L4D2_A2S_FIREWALL_PORTS//,/ }"
    for item in $raw; do
      validate_port_item "$item"
      add_unique_a2s_port_item "$item"
    done
  fi

  ((${#A2S_PORT_ITEMS[@]} > 0)) || die "No A2S firewall ports configured."

  chunk=""
  chunk_count=0
  for item in "${A2S_PORT_ITEMS[@]}"; do
    if [[ -z "$chunk" ]]; then
      chunk="$item"
    else
      chunk+=",$item"
    fi
    chunk_count=$((chunk_count + 1))
    if ((chunk_count == 15)); then
      A2S_PORT_CHUNKS+=("$chunk")
      chunk=""
      chunk_count=0
    fi
  done
  [[ -z "$chunk" ]] || A2S_PORT_CHUNKS+=("$chunk")
}

validate_config() {
  [[ "$L4D2_SERVER_COUNT" =~ ^[0-9]+$ ]] || die "L4D2_SERVER_COUNT must be a number."
  ((L4D2_SERVER_COUNT >= 1)) || die "L4D2_SERVER_COUNT must be at least 1."
  ((L4D2_SERVER_COUNT <= ${#GAME_PORTS_ARRAY[@]})) || die "L4D2_SERVER_COUNT exceeds L4D2_GAME_PORTS length."
  ((L4D2_SERVER_COUNT <= ${#BACKEND_PORTS_ARRAY[@]})) || die "L4D2_SERVER_COUNT exceeds L4D2_BACKEND_PORTS length."
  [[ "$L4D2_HOSTNAME_START_INDEX" =~ ^[0-9]+$ ]] || die "L4D2_HOSTNAME_START_INDEX must be a number."
  [[ "$L4D2_GIT_DIR" == /* ]] || die "L4D2_GIT_DIR must be an absolute path."
  [[ "$L4D2_MAP_UPLOAD_DIR" == /* ]] || die "L4D2_MAP_UPLOAD_DIR must be an absolute path."
  [[ "$L4D2_GO_PROXY_BIN" == /* ]] || die "L4D2_GO_PROXY_BIN must be an absolute path."
  [[ "$L4D2_GO_PROXY_CONFIG" == /* ]] || die "L4D2_GO_PROXY_CONFIG must be an absolute path."
  [[ "$L4D2_GO_PROXY_REDIRECT_BIN" == /* ]] || die "L4D2_GO_PROXY_REDIRECT_BIN must be an absolute path."
  [[ "$L4D2_MASTER_SNAT_BIN" == /* ]] || die "L4D2_MASTER_SNAT_BIN must be an absolute path."
  validate_docker_name L4D2_CONTAINER_PREFIX "$L4D2_CONTAINER_PREFIX"
  validate_docker_name L4D2_BASE_CONTAINER_NAME "$L4D2_BASE_CONTAINER_NAME"
  validate_docker_name L4D2_MAP_UPLOADER_CONTAINER_NAME "$L4D2_MAP_UPLOADER_CONTAINER_NAME"
  validate_port "L4D2_MAP_UPLOADER_PORT" "$L4D2_MAP_UPLOADER_PORT"
  [[ "$L4D2_MAP_UPLOADER_DATA_DIR" == /* ]] || die "L4D2_MAP_UPLOADER_DATA_DIR must be an absolute path."
  [[ -z "$L4D2_MAP_UPLOADER_DIR" || "$L4D2_MAP_UPLOADER_DIR" == /* ]] || die "L4D2_MAP_UPLOADER_DIR must be an absolute path."
  [[ -z "$L4D2_MAP_UPLOADER_RULES_FILE" || "$L4D2_MAP_UPLOADER_RULES_FILE" == /* ]] || die "L4D2_MAP_UPLOADER_RULES_FILE must be an absolute path."
  [[ ! "$L4D2_MAP_UPLOADER_BIND_IP" =~ [[:space:]] ]] || die "L4D2_MAP_UPLOADER_BIND_IP must not contain whitespace."
  validate_positive_number L4D2_MAP_UPLOADER_MAX_UPLOAD_MB "$L4D2_MAP_UPLOADER_MAX_UPLOAD_MB"
  validate_nonnegative_number L4D2_MAP_UPLOADER_MAX_TOTAL_UPLOAD_MB "$L4D2_MAP_UPLOADER_MAX_TOTAL_UPLOAD_MB"
  validate_nonnegative_number L4D2_MAP_UPLOADER_GUEST_TTL_HOURS "$L4D2_MAP_UPLOADER_GUEST_TTL_HOURS"

  local i port seen=" "
  for ((i = 0; i < L4D2_SERVER_COUNT; i++)); do
    port="${GAME_PORTS_ARRAY[$i]}"
    validate_port "L4D2_GAME_PORTS[$i]" "$port"
    [[ "$seen" != *" $port "* ]] || die "Duplicate port: $port"
    seen+="$port "

    port="${BACKEND_PORTS_ARRAY[$i]}"
    validate_port "L4D2_BACKEND_PORTS[$i]" "$port"
    [[ "$seen" != *" $port "* ]] || die "Duplicate port: $port"
    seen+="$port "
  done

  validate_port "L4D2_MYSQL_PORT" "$L4D2_MYSQL_PORT"
  validate_positive_number L4D2_GO_PROXY_CACHE_TTL_SECONDS "$L4D2_GO_PROXY_CACHE_TTL_SECONDS"
  validate_positive_number L4D2_GO_PROXY_PLAYER_CACHE_TTL_SECONDS "$L4D2_GO_PROXY_PLAYER_CACHE_TTL_SECONDS"
  validate_positive_number L4D2_GO_PROXY_RULES_CACHE_TTL_SECONDS "$L4D2_GO_PROXY_RULES_CACHE_TTL_SECONDS"
  validate_positive_number L4D2_GO_PROXY_SESSION_IDLE_SECONDS "$L4D2_GO_PROXY_SESSION_IDLE_SECONDS"
  validate_positive_number L4D2_GO_PROXY_WORKER_COUNT "$L4D2_GO_PROXY_WORKER_COUNT"
  validate_positive_number L4D2_GO_PROXY_QUEUE_SIZE "$L4D2_GO_PROXY_QUEUE_SIZE"
  validate_positive_number L4D2_GO_PROXY_SOCKET_BUFFER_BYTES "$L4D2_GO_PROXY_SOCKET_BUFFER_BYTES"
  validate_positive_number L4D2_GO_PROXY_MAX_SESSIONS "$L4D2_GO_PROXY_MAX_SESSIONS"
  validate_positive_number L4D2_GO_PROXY_MAX_SESSIONS_PER_IP "$L4D2_GO_PROXY_MAX_SESSIONS_PER_IP"

  if is_enabled "$L4D2_GO_PROXY_TRANSPARENT_REDIRECT"; then
    is_enabled "$L4D2_GO_PROXY_ENABLE" || die "L4D2_GO_PROXY_TRANSPARENT_REDIRECT requires L4D2_GO_PROXY_ENABLE=true."
  fi

  if is_enabled "$L4D2_MASTER_SNAT_ENABLE"; then
    is_enabled "$L4D2_GO_PROXY_ENABLE" || die "L4D2_MASTER_SNAT_ENABLE requires L4D2_GO_PROXY_ENABLE=true."
    if is_enabled "$L4D2_GO_PROXY_TRANSPARENT_REDIRECT"; then
      die "L4D2_MASTER_SNAT_ENABLE is not used with L4D2_GO_PROXY_TRANSPARENT_REDIRECT=true."
    fi
    [[ "$L4D2_MASTER_SNAT_DEST" == *:* ]] || die "L4D2_MASTER_SNAT_DEST must look like host:port."
    local snat_dest_host snat_dest_port
    snat_dest_host="${L4D2_MASTER_SNAT_DEST%:*}"
    snat_dest_port="${L4D2_MASTER_SNAT_DEST##*:}"
    [[ -n "$snat_dest_host" ]] || die "L4D2_MASTER_SNAT_DEST host is empty."
    validate_port "L4D2_MASTER_SNAT_DEST port" "$snat_dest_port"
    if is_enabled "$L4D2_GO_PROXY_MASTER_REGISTER"; then
      warn "L4D2_MASTER_SNAT_ENABLE=true works best with L4D2_GO_PROXY_MASTER_REGISTER=false to avoid duplicate master registration."
    fi
  fi

  if is_enabled "$L4D2_A2S_FIREWALL_ENABLE"; then
    validate_rate L4D2_A2S_PLAYER_RATE "$L4D2_A2S_PLAYER_RATE"
    validate_rate L4D2_A2S_INFO_RATE "$L4D2_A2S_INFO_RATE"
    validate_rate L4D2_A2S_RULES_RATE "$L4D2_A2S_RULES_RATE"
    validate_rate L4D2_A2S_OTHER_RATE "$L4D2_A2S_OTHER_RATE"
    validate_positive_number L4D2_A2S_PLAYER_BURST "$L4D2_A2S_PLAYER_BURST"
    validate_positive_number L4D2_A2S_INFO_BURST "$L4D2_A2S_INFO_BURST"
    validate_positive_number L4D2_A2S_RULES_BURST "$L4D2_A2S_RULES_BURST"
    validate_positive_number L4D2_A2S_OTHER_BURST "$L4D2_A2S_OTHER_BURST"
    validate_positive_number L4D2_A2S_BAN_SECONDS "$L4D2_A2S_BAN_SECONDS"
    validate_positive_number L4D2_A2S_BAN_HITCOUNT "$L4D2_A2S_BAN_HITCOUNT"
    validate_positive_number L4D2_A2S_HASH_EXPIRE_MS "$L4D2_A2S_HASH_EXPIRE_MS"
    build_a2s_port_chunks
  fi
}

require_deploy_config() {
  require_not_placeholder L4D2_STEAM_GROUP
  require_not_placeholder L4D2_STEAM_ADMIN
  require_not_placeholder L4D2_MYSQL_HOST
  require_not_placeholder L4D2_MYSQL_USER
  require_not_placeholder L4D2_MYSQL_PASSWORD
  require_not_placeholder L4D2_RCON_PASSWORD
}

# ══════════════════════════════════════════════════════════════
# OS DETECTION
# ══════════════════════════════════════════════════════════════

detect_os() {
  if [[ -f /etc/os-release ]]; then
    # shellcheck source=/dev/null
    . /etc/os-release
    OS_ID="${ID:-unknown}"
    OS_VERSION_ID="${VERSION_ID:-unknown}"
    OS_CODENAME="${VERSION_CODENAME:-}"
  fi

  case "$OS_ID" in
    debian | ubuntu)
      ok "Detected OS: ${OS_ID} ${OS_VERSION_ID}"
      ;;
    *)
      die "This script supports Debian and Ubuntu only. Detected: ${OS_ID}"
      ;;
  esac
}

default_route_ip() {
  ip route get 1.1.1.1 2>/dev/null | awk '/src/ {for (i=1; i<=NF; i++) if ($i == "src") {print $(i+1); exit}}' || true
}

public_ip() {
  if check_cmd curl; then
    curl -fsSL --max-time 5 https://ifconfig.me 2>/dev/null || \
      curl -fsSL --max-time 5 https://api.ipify.org 2>/dev/null || true
  fi
}

is_ipv4() {
  [[ "$1" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]
}

detect_server_ips() {
  local detected_public detected_bind

  if [[ -z "$L4D2_SERVER_IP" ]]; then
    detected_public="$(public_ip)"
    if ! is_ipv4 "$detected_public"; then
      detected_public="$(default_route_ip)"
    fi
    is_ipv4 "$detected_public" || die "Could not detect L4D2_SERVER_IP. Set it via -c config.sh."
    L4D2_SERVER_IP="$detected_public"
    ok "Detected server IP: $L4D2_SERVER_IP"
  else
    ok "Using configured server IP: $L4D2_SERVER_IP"
  fi

  if [[ -z "$L4D2_BIND_IP" ]]; then
    detected_bind="$(default_route_ip)"
    if ! is_ipv4 "$detected_bind"; then
      detected_bind="$L4D2_SERVER_IP"
    fi
    is_ipv4 "$detected_bind" || die "Could not detect L4D2_BIND_IP. Set it via -c config.sh."
    L4D2_BIND_IP="$detected_bind"
    ok "Detected bind IP: $L4D2_BIND_IP"
  else
    ok "Using configured bind IP: $L4D2_BIND_IP"
  fi
}

# ══════════════════════════════════════════════════════════════
# SYSTEM INSTALLATION
# ══════════════════════════════════════════════════════════════

apt_install() {
  apt-get \
    -o Dpkg::Options::=--force-confdef \
    -o Dpkg::Options::=--force-confold \
    install -y --no-install-recommends "$@"
}

configure_apt_mirror() {
  [[ "$L4D2_APT_MIRROR" == "tencent" ]] || return
  [[ -n "$OS_CODENAME" ]] || die "Could not determine OS codename for mirror setup."

  log "Writing Tencent apt mirror list."
  case "$OS_ID" in
    ubuntu)
      cat >/etc/apt/sources.list.d/l4d2-tencent.list <<EOF
deb https://mirrors.cloud.tencent.com/ubuntu/ ${OS_CODENAME} main restricted universe multiverse
deb https://mirrors.cloud.tencent.com/ubuntu/ ${OS_CODENAME}-updates main restricted universe multiverse
deb https://mirrors.cloud.tencent.com/ubuntu/ ${OS_CODENAME}-backports main restricted universe multiverse
deb https://mirrors.cloud.tencent.com/ubuntu/ ${OS_CODENAME}-security main restricted universe multiverse
EOF
      ;;
    debian)
      local components major
      components="main contrib non-free"
      major="${OS_VERSION_ID%%.*}"
      if [[ "$major" =~ ^[0-9]+$ ]] && ((major >= 12)); then
        components+=" non-free-firmware"
      fi
      cat >/etc/apt/sources.list.d/l4d2-tencent.list <<EOF
deb https://mirrors.cloud.tencent.com/debian/ ${OS_CODENAME} ${components}
deb https://mirrors.cloud.tencent.com/debian/ ${OS_CODENAME}-updates ${components}
deb https://mirrors.cloud.tencent.com/debian-security/ ${OS_CODENAME}-security ${components}
EOF
      ;;
  esac
}

install_docker() {
  if check_cmd docker; then
    ok "Docker is already installed."
  else
    log "Installing Docker from Debian/Ubuntu packages."
    apt_install docker.io
  fi

  systemctl enable docker >/dev/null 2>&1 || true
  systemctl start docker
  systemctl is-active --quiet docker || die "Docker service is not active."
}

install_system_env() {
  require_root
  require_systemd
  detect_os
  configure_needrestart
  configure_apt_mirror

  log "Installing system dependencies."
  apt-get update
  local packages=(
    ca-certificates \
    curl \
    wget \
    gnupg \
    lsb-release \
    iproute2 \
    iptables \
    jq \
    htop \
    nload \
    kmod \
    git
  )

  apt_install "${packages[@]}"

  configure_needrestart
  install_docker

  install -d -m 0755 "$L4D2_MAP_UPLOAD_DIR"
  ok "System environment is ready."
}

install_map_uploader_system_env() {
  require_root
  require_systemd
  detect_os
  configure_needrestart
  configure_apt_mirror

  if ! check_cmd docker; then
    log "Installing Docker dependencies for map uploader."
    apt-get update
  fi
  install_docker

  install -d -m 0755 "$L4D2_MAP_UPLOADER_DATA_DIR"
  install -d -m 0755 "$L4D2_MAP_UPLOAD_DIR"
  ok "Map uploader system environment is ready."
}

# ══════════════════════════════════════════════════════════════
# GO PROXY
# ══════════════════════════════════════════════════════════════

latest_go_proxy_version() {
  [[ -n "$L4D2_GO_PROXY_VERSION_URL" ]] || return 1
  local latest
  latest="$(curl -fsSL --max-time 10 "$L4D2_GO_PROXY_VERSION_URL" 2>/dev/null | tr -d '[:space:]')"
  [[ -n "$latest" ]] || return 1
  printf '%s\n' "$latest"
}

installed_go_proxy_version() {
  [[ -x "$L4D2_GO_PROXY_BIN" ]] || return 1
  "$L4D2_GO_PROXY_BIN" --version 2>/dev/null | head -n1 | tr -d '[:space:]'
}

go_proxy_needs_download() {
  is_enabled "$L4D2_GO_PROXY_FORCE_DOWNLOAD" && return 0
  [[ -x "$L4D2_GO_PROXY_BIN" ]] || return 0

  local latest installed
  latest="$(latest_go_proxy_version || true)"
  [[ -n "$latest" ]] || return 1
  installed="$(installed_go_proxy_version || true)"
  [[ -n "$installed" ]] || return 0
  [[ "$installed" != "$latest" ]]
}

install_go_proxy() {
  require_root
  require_systemd
  detect_server_ips

  if go_proxy_needs_download; then
    local latest
    latest="$(latest_go_proxy_version || true)"
    if [[ -n "$latest" ]]; then
      log "Installing A2S Go proxy from: $L4D2_GO_PROXY_URL (latest: $latest)"
    else
      log "Installing A2S Go proxy from: $L4D2_GO_PROXY_URL"
    fi
    install -d -m 0755 "$(dirname "$L4D2_GO_PROXY_BIN")"
    local tmp_bin
    tmp_bin="$(mktemp)"
    TEMP_FILES+=("$tmp_bin")
    curl -fsSL "$L4D2_GO_PROXY_URL" -o "$tmp_bin"
    install -m 0755 "$tmp_bin" "$L4D2_GO_PROXY_BIN"
  else
    local installed latest
    installed="$(installed_go_proxy_version || true)"
    latest="$(latest_go_proxy_version || true)"
    if [[ -n "$installed" && -n "$latest" ]]; then
      ok "A2S Go proxy is up to date: $installed"
    else
      ok "A2S Go proxy binary already exists: $L4D2_GO_PROXY_BIN"
    fi
  fi

  log "Writing A2S Go proxy config."
  install -d -m 0755 "$(dirname "$L4D2_GO_PROXY_CONFIG")"
  local backend_ip
  backend_ip="$L4D2_GO_PROXY_BACKEND_IP"
  if [[ -z "$backend_ip" ]]; then
    backend_ip="$L4D2_SERVER_IP"
  fi
  local bypass_ips_json bypass_probe_json
  bypass_ips_json="$(json_string_array_from_words "$L4D2_GO_PROXY_BYPASS_CACHE_IPS")"
  bypass_probe_json=false
  if is_enabled "$L4D2_GO_PROXY_BYPASS_CACHE_PROBE"; then
    bypass_probe_json=true
  fi
  local debug_json
  debug_json=false
  if is_enabled "$L4D2_GO_PROXY_DEBUG"; then
    debug_json=true
  fi
  local stats_log_file_json
  stats_log_file_json="$(json_escape "$L4D2_GO_PROXY_STATS_LOG_FILE")"
  cat >"$L4D2_GO_PROXY_CONFIG" <<EOF
{
  "cache_ttl_seconds": ${L4D2_GO_PROXY_CACHE_TTL_SECONDS},
  "player_cache_ttl_seconds": ${L4D2_GO_PROXY_PLAYER_CACHE_TTL_SECONDS},
  "rules_cache_ttl_seconds": ${L4D2_GO_PROXY_RULES_CACHE_TTL_SECONDS},
  "session_idle_timeout_seconds": ${L4D2_GO_PROXY_SESSION_IDLE_SECONDS},
  "worker_count": ${L4D2_GO_PROXY_WORKER_COUNT},
  "queue_size": ${L4D2_GO_PROXY_QUEUE_SIZE},
  "socket_buffer_bytes": ${L4D2_GO_PROXY_SOCKET_BUFFER_BYTES},
  "max_sessions": ${L4D2_GO_PROXY_MAX_SESSIONS},
  "max_sessions_per_ip": ${L4D2_GO_PROXY_MAX_SESSIONS_PER_IP},
  "bypass_cache_ips": ${bypass_ips_json},
  "bypass_cache_probe": ${bypass_probe_json},
  "stats_interval_seconds": ${L4D2_GO_PROXY_STATS_INTERVAL},
  "stats_log_file": "${stats_log_file_json}",
  "stats_attack_threshold": ${L4D2_GO_PROXY_STATS_THRESHOLD},
  "debug": ${debug_json},
  "servers": [
EOF

  local i comma master_enabled master_addr_json master_interval proxy_backend_port rewrite_info_port
  master_enabled=false
  if is_enabled "$L4D2_GO_PROXY_MASTER_REGISTER"; then
    master_enabled=true
  fi
  master_addr_json="$(json_escape "$L4D2_GO_PROXY_MASTER_ADDR")"
  master_interval="$L4D2_GO_PROXY_MASTER_INTERVAL"
  if [[ ! "$master_interval" =~ ^[0-9]+$ ]] || ((master_interval <= 0)); then
    master_interval=300
  fi

  for ((i = 0; i < L4D2_SERVER_COUNT; i++)); do
    comma=","
    if ((i == L4D2_SERVER_COUNT - 1)); then
      comma=""
    fi
    proxy_backend_port="${BACKEND_PORTS_ARRAY[$i]}"
    rewrite_info_port=true
    if is_enabled "$L4D2_GO_PROXY_TRANSPARENT_REDIRECT"; then
      proxy_backend_port="${GAME_PORTS_ARRAY[$i]}"
      rewrite_info_port=false
    fi
    cat >>"$L4D2_GO_PROXY_CONFIG" <<EOF
    {
      "name": "${L4D2_CONTAINER_PREFIX}$((i + 1))",
      "listen_addr": "${L4D2_BIND_IP}:${PROXY_LISTEN_PORTS_ARRAY[$i]}",
      "backend_addr": "${backend_ip}:${proxy_backend_port}",
      "rewrite_info_port": ${rewrite_info_port},
      "master": {
        "enabled": ${master_enabled},
        "addr": "${master_addr_json}",
        "interval_seconds": ${master_interval},
        "fields": {
          "region": ${L4D2_REGION}
        }
      }
    }${comma}
EOF
  done

  cat >>"$L4D2_GO_PROXY_CONFIG" <<EOF
  ]
}
EOF

  cat >/etc/systemd/system/a2s-proxy-go.service <<EOF
[Unit]
Description=A2S Go proxy for L4D2
After=network-online.target docker.service
Wants=network-online.target

[Service]
Type=simple
ExecStart=${L4D2_GO_PROXY_BIN} -config ${L4D2_GO_PROXY_CONFIG}
Restart=always
RestartSec=5s
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable a2s-proxy-go >/dev/null
  if systemctl restart a2s-proxy-go; then
    ok "A2S Go proxy is running."
  else
    warn "A2S Go proxy did not start yet. If ports are being migrated, deploy/restart the game containers and retry."
  fi
}

# ══════════════════════════════════════════════════════════════
# A2S TRANSPARENT REDIRECT
# ══════════════════════════════════════════════════════════════

install_go_proxy_redirect() {
  require_root
  require_systemd
  detect_server_ips

  local iptables_bin
  iptables_bin="$(command -v iptables || true)"
  [[ -n "$iptables_bin" ]] || die "iptables is not installed. Run --install first."

  log "Writing A2S transparent redirect rules."
  install -d -m 0755 "$(dirname "$L4D2_GO_PROXY_REDIRECT_BIN")"
  cat >"$L4D2_GO_PROXY_REDIRECT_BIN" <<EOF
#!/usr/bin/env bash
set -euo pipefail

PATH=/usr/sbin:/usr/bin:/sbin:/bin
IPT="${iptables_bin}"
CHAIN="A2S_PROXY_REDIRECT"

GAME_PORTS=(
EOF
  local i
  for ((i = 0; i < L4D2_SERVER_COUNT; i++)); do
    printf "  '%s'\n" "${GAME_PORTS_ARRAY[$i]}" >>"$L4D2_GO_PROXY_REDIRECT_BIN"
  done
  cat >>"$L4D2_GO_PROXY_REDIRECT_BIN" <<'EOF'
)

PROXY_PORTS=(
EOF
  for ((i = 0; i < L4D2_SERVER_COUNT; i++)); do
    printf "  '%s'\n" "${PROXY_LISTEN_PORTS_ARRAY[$i]}" >>"$L4D2_GO_PROXY_REDIRECT_BIN"
  done
  cat >>"$L4D2_GO_PROXY_REDIRECT_BIN" <<'EOF'
)

ipt() {
  "$IPT" -w "$@"
}

ensure_chain() {
  ipt -t nat -N "$CHAIN" 2>/dev/null || ipt -t nat -F "$CHAIN"
}

remove_refs() {
  while ipt -t nat -D PREROUTING -j "$CHAIN" 2>/dev/null; do
    :
  done
}

add_a2s_redirect() {
  local game_port="$1"
  local proxy_port="$2"
  local byte="$3"
  ipt -t nat -A "$CHAIN" -p udp --dport "$game_port" \
    -m u32 --u32 "0>>22&0x3C@8=0xFFFFFFFF && 0>>22&0x3C@12&0xFF000000=0x${byte}000000" \
    -j REDIRECT --to-ports "$proxy_port"
}

add_steam_details_redirect() {
  local game_port="$1"
  local proxy_port="$2"
  ipt -t nat -A "$CHAIN" -p udp --dport "$game_port" \
    -m u32 --u32 "0>>22&0x3C@8=0xFFFFFFFF && 0>>22&0x3C@12=0x00000000 && 0>>22&0x3C@16=0xC3080000 && 0>>22&0x3C@24=0x00496E65 && 0>>22&0x3C@28=0x74536561 && 0>>22&0x3C@32=0x72636853 && 0>>22&0x3C@36=0x65727665 && 0>>22&0x3C@40=0x72446574 && 0>>22&0x3C@44=0x61696C73" \
    -j REDIRECT --to-ports "$proxy_port"
}

apply_rules() {
  remove_refs
  ensure_chain
  local i game_port proxy_port
  for i in "${!GAME_PORTS[@]}"; do
    game_port="${GAME_PORTS[$i]}"
    proxy_port="${PROXY_PORTS[$i]}"
    add_a2s_redirect "$game_port" "$proxy_port" 54
    add_a2s_redirect "$game_port" "$proxy_port" 55
    add_a2s_redirect "$game_port" "$proxy_port" 56
    add_a2s_redirect "$game_port" "$proxy_port" 57
    add_a2s_redirect "$game_port" "$proxy_port" 69
    add_steam_details_redirect "$game_port" "$proxy_port"
  done
  ipt -t nat -A "$CHAIN" -j RETURN
  ipt -t nat -I PREROUTING 1 -j "$CHAIN"
}

remove_rules() {
  remove_refs
  ipt -t nat -F "$CHAIN" 2>/dev/null || true
  ipt -t nat -X "$CHAIN" 2>/dev/null || true
}

status_rules() {
  echo "========== A2S Transparent Redirect =========="
  echo "Mappings:"
  local i
  for i in "${!GAME_PORTS[@]}"; do
    echo "  game ${GAME_PORTS[$i]} A2S -> proxy ${PROXY_PORTS[$i]}"
  done
  echo
  echo "========== nat PREROUTING =========="
  ipt -t nat -L PREROUTING -n -v --line-numbers || true
  echo
  echo "========== $CHAIN =========="
  ipt -t nat -L "$CHAIN" -n -v --line-numbers || true
  echo
  echo "========== $CHAIN raw =========="
  ipt -t nat -S "$CHAIN" || true
}

case "${1:-apply}" in
  apply | start | reload)
    apply_rules
    ;;
  remove | stop)
    remove_rules
    ;;
  status)
    status_rules
    ;;
  *)
    echo "Usage: $0 [apply|remove|status]" >&2
    exit 2
    ;;
esac
EOF

  chmod 0755 "$L4D2_GO_PROXY_REDIRECT_BIN"

  cat >/etc/systemd/system/a2s-proxy-redirect.service <<EOF
[Unit]
Description=A2S transparent redirect to Go proxy
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=${L4D2_GO_PROXY_REDIRECT_BIN} apply
ExecReload=${L4D2_GO_PROXY_REDIRECT_BIN} reload
ExecStop=${L4D2_GO_PROXY_REDIRECT_BIN} remove

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable a2s-proxy-redirect >/dev/null
  systemctl restart a2s-proxy-redirect
  ok "A2S transparent redirect is running."
}

remove_go_proxy_redirect() {
  require_root
  if check_cmd systemctl; then
    systemctl stop a2s-proxy-redirect >/dev/null 2>&1 || true
    systemctl disable a2s-proxy-redirect >/dev/null 2>&1 || true
  fi
  if [[ -x "$L4D2_GO_PROXY_REDIRECT_BIN" ]]; then
    "$L4D2_GO_PROXY_REDIRECT_BIN" remove || true
  fi
  rm -f /etc/systemd/system/a2s-proxy-redirect.service
  rm -f "$L4D2_GO_PROXY_REDIRECT_BIN"
  if check_cmd systemctl; then
    systemctl daemon-reload
  fi
  ok "A2S transparent redirect removed."
}

# ══════════════════════════════════════════════════════════════
# MASTER SNAT
# ══════════════════════════════════════════════════════════════

install_master_snat() {
  require_root
  require_systemd
  detect_server_ips

  local iptables_bin dest_host dest_port src_ip
  iptables_bin="$(command -v iptables || true)"
  [[ -n "$iptables_bin" ]] || die "iptables is not installed. Run --install first."

  dest_host="${L4D2_MASTER_SNAT_DEST%:*}"
  dest_port="${L4D2_MASTER_SNAT_DEST##*:}"
  validate_port "L4D2_MASTER_SNAT_DEST port" "$dest_port"
  getent ahostsv4 "$dest_host" >/dev/null || die "Could not resolve master server: $dest_host"
  src_ip="$L4D2_SERVER_IP"

  log "Writing master SNAT script for ${dest_host}:${dest_port}."
  install -d -m 0755 "$(dirname "$L4D2_MASTER_SNAT_BIN")"
  cat >"$L4D2_MASTER_SNAT_BIN" <<EOF
#!/usr/bin/env bash
set -euo pipefail

PATH=/usr/sbin:/usr/bin:/sbin:/bin
IPT="${iptables_bin}"
CHAIN="A2S_MASTER_SNAT"
DEST_HOST="${dest_host}"
DEST_PORT="${dest_port}"
SRC_IP="${src_ip}"

BACKEND_PORTS=(
EOF
  local i
  for ((i = 0; i < L4D2_SERVER_COUNT; i++)); do
    printf "  '%s'\n" "${BACKEND_PORTS_ARRAY[$i]}" >>"$L4D2_MASTER_SNAT_BIN"
  done
  cat >>"$L4D2_MASTER_SNAT_BIN" <<'EOF'
)

PUBLIC_PORTS=(
EOF
  for ((i = 0; i < L4D2_SERVER_COUNT; i++)); do
    printf "  '%s'\n" "${GAME_PORTS_ARRAY[$i]}" >>"$L4D2_MASTER_SNAT_BIN"
  done
  cat >>"$L4D2_MASTER_SNAT_BIN" <<'EOF'
)

ipt() {
  "$IPT" -w "$@"
}

resolve_dest_ip() {
  getent ahostsv4 "$DEST_HOST" | awk '{print $1; exit}'
}

ensure_chain() {
  ipt -t nat -N "$CHAIN" 2>/dev/null || ipt -t nat -F "$CHAIN"
}

remove_refs() {
  while ipt -t nat -D POSTROUTING -j "$CHAIN" 2>/dev/null; do
    :
  done
}

apply_rules() {
  remove_refs
  ensure_chain
  local i backend_port public_port dest_ip
  dest_ip="$(resolve_dest_ip)"
  [[ -n "$dest_ip" ]] || {
    echo "Could not resolve master server: $DEST_HOST" >&2
    exit 1
  }
  for i in "${!BACKEND_PORTS[@]}"; do
    backend_port="${BACKEND_PORTS[$i]}"
    public_port="${PUBLIC_PORTS[$i]}"
    ipt -t nat -A "$CHAIN" -p udp -d "$dest_ip" --dport "$DEST_PORT" --sport "$backend_port" \
      -j SNAT --to-source "${SRC_IP}:${public_port}"
  done
  ipt -t nat -A "$CHAIN" -j RETURN
  ipt -t nat -I POSTROUTING 1 -j "$CHAIN"
}

remove_rules() {
  remove_refs
  ipt -t nat -F "$CHAIN" 2>/dev/null || true
  ipt -t nat -X "$CHAIN" 2>/dev/null || true
}

status_rules() {
  local dest_ip
  dest_ip="$(resolve_dest_ip || true)"
  echo "========== Master SNAT Debug =========="
  echo "Destination: ${DEST_HOST}:${DEST_PORT}"
  echo "Resolved IP: ${dest_ip:-unresolved}"
  echo "SNAT source IP: ${SRC_IP}"
  echo "Mappings:"
  local i
  for i in "${!BACKEND_PORTS[@]}"; do
    echo "  backend ${BACKEND_PORTS[$i]} -> public ${PUBLIC_PORTS[$i]}"
  done
  echo
  echo "========== nat POSTROUTING =========="
  ipt -t nat -L POSTROUTING -n -v --line-numbers || true
  echo
  echo "========== $CHAIN =========="
  ipt -t nat -L "$CHAIN" -n -v --line-numbers || true
  echo
  echo "========== $CHAIN raw =========="
  ipt -t nat -S "$CHAIN" || true
}

case "${1:-apply}" in
  apply | start | reload)
    apply_rules
    ;;
  remove | stop)
    remove_rules
    ;;
  status)
    status_rules
    ;;
  *)
    echo "Usage: $0 [apply|remove|status]" >&2
    exit 2
    ;;
esac
EOF

  chmod 0755 "$L4D2_MASTER_SNAT_BIN"

  cat >/etc/systemd/system/a2s-master-snat.service <<EOF
[Unit]
Description=A2S master heartbeat SNAT rules
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=${L4D2_MASTER_SNAT_BIN} apply
ExecReload=${L4D2_MASTER_SNAT_BIN} reload
ExecStop=${L4D2_MASTER_SNAT_BIN} remove

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable a2s-master-snat >/dev/null
  systemctl restart a2s-master-snat
  ok "A2S master SNAT is running."
}

# ══════════════════════════════════════════════════════════════
# A2S FIREWALL
# ══════════════════════════════════════════════════════════════

install_a2s_firewall() {
  require_root
  require_systemd

  local iptables_bin modprobe_bin chunk
  iptables_bin="$(command -v iptables || true)"
  [[ -n "$iptables_bin" ]] || die "iptables is not installed. Run --install first."
  modprobe_bin="$(command -v modprobe || true)"
  [[ -n "$modprobe_bin" ]] || die "modprobe is not installed. Run --install first."

  log "Writing A2S firewall script for ports: ${A2S_PORT_ITEMS[*]}"
  cat >/usr/local/bin/a2s-firewall.sh <<EOF
#!/usr/bin/env bash
set -euo pipefail

PATH=/usr/sbin:/usr/bin:/sbin:/bin

IPT="${iptables_bin}"
MODPROBE="${modprobe_bin}"
CHAIN="A2S_DEFENSE"
DROP_CHAIN="A2S_DROP_LOG"
RECENT_NAME="A2S_ATTACKER"
HASH_EXPIRE_MS="${L4D2_A2S_HASH_EXPIRE_MS}"
BAN_SECONDS="${L4D2_A2S_BAN_SECONDS}"
BAN_HITCOUNT="${L4D2_A2S_BAN_HITCOUNT}"
LOG_LIMIT="${L4D2_A2S_LOG_LIMIT}"
PLAYER_RATE="${L4D2_A2S_PLAYER_RATE}"
PLAYER_BURST="${L4D2_A2S_PLAYER_BURST}"
INFO_RATE="${L4D2_A2S_INFO_RATE}"
INFO_BURST="${L4D2_A2S_INFO_BURST}"
RULES_RATE="${L4D2_A2S_RULES_RATE}"
RULES_BURST="${L4D2_A2S_RULES_BURST}"
OTHER_RATE="${L4D2_A2S_OTHER_RATE}"
OTHER_BURST="${L4D2_A2S_OTHER_BURST}"

PORT_CHUNKS=(
EOF
  for chunk in "${A2S_PORT_CHUNKS[@]}"; do
    printf "  '%s'\n" "$chunk" >>/usr/local/bin/a2s-firewall.sh
  done
  cat >>/usr/local/bin/a2s-firewall.sh <<'EOF'
)

ipt() {
  "$IPT" -w "$@"
}

load_modules() {
  local module
  for module in xt_u32 xt_hashlimit xt_recent xt_multiport; do
    "$MODPROBE" "$module" 2>/dev/null || true
  done
}

ensure_chain() {
  local chain="$1"
  ipt -N "$chain" 2>/dev/null || ipt -F "$chain"
}

remove_input_refs() {
  while ipt -D INPUT -j "$CHAIN" 2>/dev/null; do
    :
  done
}

add_blacklist_rules() {
  local ports
  for ports in "${PORT_CHUNKS[@]}"; do
    ipt -A "$CHAIN" -p udp -m multiport --dports "$ports" \
      -m recent --update --seconds "$BAN_SECONDS" --hitcount "$BAN_HITCOUNT" --name "$RECENT_NAME" \
      -j "$DROP_CHAIN"
  done
}

add_signature_rules() {
  local name="$1"
  local byte="$2"
  local rate="$3"
  local burst="$4"
  local ports

  for ports in "${PORT_CHUNKS[@]}"; do
    ipt -A "$CHAIN" -p udp -m multiport --dports "$ports" \
      -m u32 --u32 "0>>22&0x3C@8=0xFFFFFFFF && 0>>22&0x3C@12&0xFF000000=0x${byte}000000" \
      -m hashlimit --hashlimit-name "$name" --hashlimit-mode srcip \
      --hashlimit-above "$rate" --hashlimit-burst "$burst" --hashlimit-htable-expire "$HASH_EXPIRE_MS" \
      -m recent --set --name "$RECENT_NAME" \
      -j "$DROP_CHAIN"
  done
}

apply_rules() {
  echo "[$(date)] Loading A2S defense rules into INPUT chain."
  load_modules
  remove_input_refs
  ensure_chain "$CHAIN"
  ensure_chain "$DROP_CHAIN"

  ipt -A "$DROP_CHAIN" -m limit --limit "$LOG_LIMIT" -j LOG --log-prefix "A2S_DROP: " --log-level 4
  ipt -A "$DROP_CHAIN" -j DROP

  add_blacklist_rules
  add_signature_rules A2S_PLAYER 55 "$PLAYER_RATE" "$PLAYER_BURST"
  add_signature_rules A2S_INFO 54 "$INFO_RATE" "$INFO_BURST"
  add_signature_rules A2S_RULES 56 "$RULES_RATE" "$RULES_BURST"
  add_signature_rules A2S_69 69 "$OTHER_RATE" "$OTHER_BURST"
  add_signature_rules A2S_57 57 "$OTHER_RATE" "$OTHER_BURST"
  ipt -A "$CHAIN" -j RETURN

  ipt -I INPUT 1 -j "$CHAIN"
  echo "[$(date)] A2S defense rules loaded."
}

remove_rules() {
  echo "[$(date)] Removing A2S defense rules."
  remove_input_refs
  ipt -F "$CHAIN" 2>/dev/null || true
  ipt -F "$DROP_CHAIN" 2>/dev/null || true
  ipt -X "$CHAIN" 2>/dev/null || true
  ipt -X "$DROP_CHAIN" 2>/dev/null || true
}

status_rules() {
  echo "========== INPUT =========="
  ipt -L INPUT -n -v --line-numbers || true
  echo
  echo "========== $CHAIN =========="
  ipt -L "$CHAIN" -n -v --line-numbers || true
  echo
  echo "========== $DROP_CHAIN =========="
  ipt -L "$DROP_CHAIN" -n -v --line-numbers || true
  echo
  echo "========== recent: $RECENT_NAME =========="
  cat "/proc/net/xt_recent/$RECENT_NAME" 2>/dev/null || true
}

case "${1:-apply}" in
  apply | start | reload)
    apply_rules
    ;;
  remove | stop)
    remove_rules
    ;;
  status)
    status_rules
    ;;
  *)
    echo "Usage: $0 [apply|remove|status]" >&2
    exit 2
    ;;
esac
EOF

  chmod 0755 /usr/local/bin/a2s-firewall.sh

  cat >/usr/local/bin/a2s-monitor.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

watch -n 2 '
echo "========== A2S Defense Status =========="
echo
echo "--- INPUT Chain ---"
iptables -L INPUT -n -v --line-numbers 2>/dev/null | head -8
echo
echo "--- A2S_DEFENSE Chain ---"
iptables -L A2S_DEFENSE -n -v --line-numbers 2>/dev/null
echo
echo "--- Blocked Attackers ---"
cat /proc/net/xt_recent/A2S_ATTACKER 2>/dev/null || echo "No attackers tracked"
echo
echo "--- Hashlimit: A2S_PLAYER ---"
cat /proc/net/ipt_hashlimit/A2S_PLAYER 2>/dev/null | head -20
echo
echo "--- Hashlimit: A2S_INFO ---"
cat /proc/net/ipt_hashlimit/A2S_INFO 2>/dev/null | head -20
echo
echo "--- Recent Logs ---"
journalctl -k -n 200 --no-pager 2>/dev/null | grep "A2S_DROP" | tail -5 || true
'
EOF
  chmod 0755 /usr/local/bin/a2s-monitor.sh

  cat >/etc/systemd/system/a2s-firewall.service <<'EOF'
[Unit]
Description=A2S Attack Defense Rules for L4D2 Host Networking
After=network.target
Wants=network.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/bin/a2s-firewall.sh apply
ExecReload=/usr/local/bin/a2s-firewall.sh reload
ExecStop=/usr/local/bin/a2s-firewall.sh remove

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable a2s-firewall >/dev/null
  systemctl restart a2s-firewall
  ok "A2S firewall is running."
}

# ══════════════════════════════════════════════════════════════
# DOCKER CONTAINERS
# ══════════════════════════════════════════════════════════════

container_exists() {
  docker inspect "$1" >/dev/null 2>&1
}

init_base_container() {
  require_root
  log "Preparing base container: $L4D2_BASE_CONTAINER_NAME"

  if ! docker image inspect "$L4D2_BASE_IMAGE_URL" >/dev/null 2>&1; then
    log "Pulling base image: $L4D2_BASE_IMAGE_URL"
    docker pull "$L4D2_BASE_IMAGE_URL"
  else
    ok "Base image exists locally."
  fi

  if ! container_exists "$L4D2_BASE_CONTAINER_NAME"; then
    log "Creating persistent base container."
    docker run -d \
      --name "$L4D2_BASE_CONTAINER_NAME" \
      --restart unless-stopped \
      --entrypoint /bin/sh \
      "$L4D2_BASE_IMAGE_URL" \
      -c 'while :; do sleep 3600; done'
  else
    log "Starting existing base container."
    docker start "$L4D2_BASE_CONTAINER_NAME" >/dev/null 2>&1 || true
  fi

  docker exec "$L4D2_BASE_CONTAINER_NAME" sh -lc 'command -v git >/dev/null 2>&1' || \
    die "git is not available inside base container."
  docker exec "$L4D2_BASE_CONTAINER_NAME" git config --global --replace-all safe.directory "$L4D2_GIT_DIR" || true

  if docker exec "$L4D2_BASE_CONTAINER_NAME" test -d "${L4D2_GIT_DIR}/.git"; then
    if [[ -n "$L4D2_GIT_PROXY_URL" ]]; then
      docker exec "$L4D2_BASE_CONTAINER_NAME" git -C "$L4D2_GIT_DIR" remote set-url origin "$L4D2_GIT_PROXY_URL"
      ok "Git remote URL updated inside base container."
    fi
  else
    die "Repository not found inside base container: ${L4D2_GIT_DIR}/.git"
  fi
}

list_game_containers() {
  docker ps -a --format '{{.Names}}' | awk -v prefix="$L4D2_CONTAINER_PREFIX" '
    index($0, prefix) == 1 {
      suffix = substr($0, length(prefix) + 1)
      if (suffix ~ /^[0-9]+$/) print $0
    }
  '
}

remove_game_containers() {
  local names=()
  mapfile -t names < <(list_game_containers)
  if ((${#names[@]} > 0)); then
    log "Removing old game containers: ${names[*]}"
    docker rm -f "${names[@]}" >/dev/null 2>&1 || true
  else
    ok "No old game containers found."
  fi
}

prepare_runtime_dir() {
  local runtime_dir
  runtime_dir=/run/l4d2-docker
  if [[ ! -d /run ]]; then
    runtime_dir=/tmp/l4d2-docker
  fi
  install -d -m 0700 "$runtime_dir"
  printf '%s\n' "$runtime_dir"
}

validate_env_value() {
  local key="$1"
  local value="$2"
  [[ "$value" != *$'\n'* && "$value" != *$'\r'* ]] || die "Docker env value contains a newline: $key"
}

write_container_env() {
  local env_file="$1"
  shift
  : >"$env_file"
  chmod 600 "$env_file"

  local pair key value
  for pair in "$@"; do
    key="${pair%%=*}"
    value="${pair#*=}"
    validate_env_value "$key" "$value"
    printf '%s\n' "$pair" >>"$env_file"
  done
}

update_and_deploy() {
  require_root
  detect_server_ips
  log "Updating code and deploying game containers."

  docker start "$L4D2_BASE_CONTAINER_NAME" >/dev/null 2>&1 || true

  log "Running git pull inside base container."
  docker exec "$L4D2_BASE_CONTAINER_NAME" git -C "$L4D2_GIT_DIR" pull --ff-only || \
    die "git pull failed inside base container."

  remove_game_containers

  if [[ "$L4D2_REMOVE_RUNTIME_IMAGE" == "1" ]]; then
    log "Removing old runtime image tag: $L4D2_PROD_IMAGE_NAME"
    docker rmi "$L4D2_PROD_IMAGE_NAME" >/dev/null 2>&1 || true
  else
    warn "Keeping old runtime image layers; docker commit will retag: $L4D2_PROD_IMAGE_NAME"
  fi

  log "Committing base container to runtime image: $L4D2_PROD_IMAGE_NAME"
  docker commit "$L4D2_BASE_CONTAINER_NAME" "$L4D2_PROD_IMAGE_NAME" >/dev/null

  if is_enabled "$L4D2_GO_PROXY_ENABLE" && is_enabled "$L4D2_GO_PROXY_TRANSPARENT_REDIRECT" && check_cmd systemctl; then
    log "Stopping A2S proxy before binding srcds to public game ports."
    systemctl stop a2s-proxy-go >/dev/null 2>&1 || true
    systemctl stop a2s-proxy-redirect >/dev/null 2>&1 || true
  fi

  local runtime_dir
  runtime_dir="$(prepare_runtime_dir)"

  log "Starting game containers."
  local i port public_port name host_num hostname env_file
  for ((i = 0; i < L4D2_SERVER_COUNT; i++)); do
    port="${GAME_PORTS_ARRAY[$i]}"
    public_port="$port"
    if is_enabled "$L4D2_GO_PROXY_ENABLE" && ! is_enabled "$L4D2_GO_PROXY_TRANSPARENT_REDIRECT"; then
      port="${BACKEND_PORTS_ARRAY[$i]}"
    fi
    name="${L4D2_CONTAINER_PREFIX}$((i + 1))"
    host_num=$((L4D2_HOSTNAME_START_INDEX + i))
    hostname="${L4D2_HOSTNAME_PREFIX}${host_num}"
    env_file="$(mktemp "${runtime_dir}/${name}.env.XXXXXX")"
    TEMP_FILES+=("$env_file")

    write_container_env "$env_file" \
      "IP=${L4D2_SERVER_IP}" \
      "TZ=${L4D2_TIMEZONE}" \
      "cloud=${L4D2_CLOUD}" \
      "mysql=${L4D2_MYSQL_HOST}" \
      "mysqlport=${L4D2_MYSQL_PORT}" \
      "mysqluser=${L4D2_MYSQL_USER}" \
      "mysqlpassword=${L4D2_MYSQL_PASSWORD}" \
      "password=${L4D2_RCON_PASSWORD}" \
      "steamgroup=${L4D2_STEAM_GROUP}" \
      "PORT=${port}" \
      "hostname=${hostname}" \
      "MAP=${L4D2_DEFAULT_MAP}" \
      "REGION=${L4D2_REGION}" \
      "plugin=${L4D2_PLUGIN}" \
      "steam64=${L4D2_STEAM_ADMIN}"

    if [[ -n "$L4D2_OPTIONAL_STEAM_ID" ]]; then
      validate_env_value steamid "$L4D2_OPTIONAL_STEAM_ID"
      printf '%s\n' "steamid=${L4D2_OPTIONAL_STEAM_ID}" >>"$env_file"
    fi

    if is_enabled "$L4D2_GO_PROXY_ENABLE" && is_enabled "$L4D2_GO_PROXY_TRANSPARENT_REDIRECT"; then
      log "Starting ${name} on public game port ${port}; A2S queries redirect to proxy ${PROXY_LISTEN_PORTS_ARRAY[$i]}."
    elif is_enabled "$L4D2_GO_PROXY_ENABLE"; then
      log "Starting ${name} backend on port ${port}; proxy listens on ${public_port}."
    else
      log "Starting ${name} on port ${port}."
    fi
    docker run -d \
      --entrypoint /bin/bash \
      --ulimit core=0 \
      --net host \
      --memory-swap 1000m \
      -m 700m \
      --env-file "$env_file" \
      -v "${L4D2_MAP_UPLOAD_DIR}:/map" \
      --name "$name" \
      --restart always \
      "$L4D2_PROD_IMAGE_NAME" \
      entrypoint.sh >/dev/null

    rm -f "$env_file"
  done

  ok "Game containers deployed."

  if is_enabled "$L4D2_MAP_UPLOADER_ENABLE"; then
    deploy_map_uploader
  else
    warn "Map uploader Docker is disabled by config."
  fi

  if is_enabled "$L4D2_GO_PROXY_ENABLE" && check_cmd systemctl; then
    systemctl restart a2s-proxy-go || true
    if is_enabled "$L4D2_GO_PROXY_TRANSPARENT_REDIRECT"; then
      systemctl restart a2s-proxy-redirect || true
    fi
  fi
}

# ══════════════════════════════════════════════════════════════
# MAP UPLOADER DOCKER
# ══════════════════════════════════════════════════════════════

default_map_uploader_dir() {
  local candidate
  candidate="$(cd "$SCRIPT_DIR/../.." && pwd)/vpk-uploader-web-docker"
  if [[ -d "$candidate" ]]; then
    printf '%s\n' "$candidate"
  fi
}

resolve_map_uploader_dir() {
  if [[ -n "$L4D2_MAP_UPLOADER_DIR" ]]; then
    printf '%s\n' "$L4D2_MAP_UPLOADER_DIR"
    return
  fi
  default_map_uploader_dir
}

require_map_uploader_config() {
  require_not_placeholder L4D2_MAP_UPLOADER_APP_SECRET
  require_not_placeholder L4D2_MAP_UPLOADER_ADMIN_PASS
}

map_uploader_public_base_url() {
  if [[ -n "$L4D2_MAP_UPLOADER_PUBLIC_BASE_URL" ]]; then
    printf '%s\n' "$L4D2_MAP_UPLOADER_PUBLIC_BASE_URL"
    return
  fi

  local host
  host="$L4D2_SERVER_IP"
  if [[ -z "$host" ]]; then
    host="$L4D2_BIND_IP"
  fi
  if [[ -z "$host" || "$host" == "0.0.0.0" ]]; then
    host="localhost"
  fi
  printf 'http://%s:%s\n' "$host" "$L4D2_MAP_UPLOADER_PORT"
}

deploy_map_uploader() {
  require_root
  detect_server_ips
  require_map_uploader_config

  local uploader_dir rules_file public_base_url runtime_dir env_file
  uploader_dir="$(resolve_map_uploader_dir)"

  rules_file="$L4D2_MAP_UPLOADER_RULES_FILE"
  if [[ -n "$uploader_dir" && -z "$rules_file" && -f "$uploader_dir/rules.yml" ]]; then
    rules_file="$uploader_dir/rules.yml"
  fi
  [[ -z "$rules_file" || -f "$rules_file" ]] || die "Map uploader rules file not found: $rules_file"

  install -d -m 0755 "$L4D2_MAP_UPLOADER_DATA_DIR"
  install -d -m 0755 "$L4D2_MAP_UPLOAD_DIR"

  if [[ -n "$uploader_dir" ]]; then
    [[ -d "$uploader_dir" ]] || die "Map uploader directory not found: $uploader_dir"
    [[ -f "$uploader_dir/Dockerfile" ]] || die "Map uploader Dockerfile not found: $uploader_dir/Dockerfile"
    log "Building map uploader image from: $uploader_dir"
    docker build -t "$L4D2_MAP_UPLOADER_IMAGE_NAME" "$uploader_dir"
  elif docker image inspect "$L4D2_MAP_UPLOADER_IMAGE_NAME" >/dev/null 2>&1; then
    ok "Using existing map uploader image: $L4D2_MAP_UPLOADER_IMAGE_NAME"
  else
    log "Pulling map uploader image: $L4D2_MAP_UPLOADER_IMAGE_NAME"
    docker pull "$L4D2_MAP_UPLOADER_IMAGE_NAME"
  fi

  if container_exists "$L4D2_MAP_UPLOADER_CONTAINER_NAME"; then
    log "Removing old map uploader container: $L4D2_MAP_UPLOADER_CONTAINER_NAME"
    docker rm -f "$L4D2_MAP_UPLOADER_CONTAINER_NAME" >/dev/null 2>&1 || true
  fi

  public_base_url="$(map_uploader_public_base_url)"
  runtime_dir="$(prepare_runtime_dir)"
  env_file="$(mktemp "${runtime_dir}/${L4D2_MAP_UPLOADER_CONTAINER_NAME}.env.XXXXXX")"
  TEMP_FILES+=("$env_file")

  write_container_env "$env_file" \
    "APP_SECRET=${L4D2_MAP_UPLOADER_APP_SECRET}" \
    "ADMIN_USER=${L4D2_MAP_UPLOADER_ADMIN_USER}" \
    "ADMIN_PASS=${L4D2_MAP_UPLOADER_ADMIN_PASS}" \
    "MAX_UPLOAD_MB=${L4D2_MAP_UPLOADER_MAX_UPLOAD_MB}" \
    "MAX_TOTAL_UPLOAD_MB=${L4D2_MAP_UPLOADER_MAX_TOTAL_UPLOAD_MB}" \
    "DEFAULT_GUEST_TTL_HOURS=${L4D2_MAP_UPLOADER_GUEST_TTL_HOURS}" \
    "PUBLIC_BASE_URL=${public_base_url}" \
    "TZ=${L4D2_TIMEZONE}"

  log "Starting map uploader on ${L4D2_MAP_UPLOADER_BIND_IP}:${L4D2_MAP_UPLOADER_PORT}."
  local docker_args=(
    run -d
    --name "$L4D2_MAP_UPLOADER_CONTAINER_NAME"
    --restart unless-stopped
    --env-file "$env_file"
    -p "${L4D2_MAP_UPLOADER_BIND_IP}:${L4D2_MAP_UPLOADER_PORT}:8080"
    -v "${L4D2_MAP_UPLOADER_DATA_DIR}:/app/data"
    -v "${L4D2_MAP_UPLOAD_DIR}:/app/data/uploads"
  )

  if [[ -n "$rules_file" ]]; then
    docker_args+=(-v "${rules_file}:/app/rules.yml:ro")
  fi

  docker_args+=("$L4D2_MAP_UPLOADER_IMAGE_NAME")
  docker "${docker_args[@]}" >/dev/null

  rm -f "$env_file"
  ok "Map uploader is running: ${public_base_url}"
  ok "Uploaded server VPK files are shared with game containers via: ${L4D2_MAP_UPLOAD_DIR}"
}

remove_map_uploader() {
  require_root
  if check_cmd docker; then
    docker rm -f "$L4D2_MAP_UPLOADER_CONTAINER_NAME" >/dev/null 2>&1 || true
  fi
  ok "Map uploader container removed."
}

# ══════════════════════════════════════════════════════════════
# RESTART / STATUS / UNINSTALL
# ══════════════════════════════════════════════════════════════

restart_all() {
  require_root
  local i name
  log "Restarting game containers."
  for ((i = 1; i <= L4D2_SERVER_COUNT; i++)); do
    name="${L4D2_CONTAINER_PREFIX}${i}"
    if container_exists "$name"; then
      docker restart "$name" >/dev/null
    else
      warn "Container not found: $name"
    fi
  done

  if check_cmd systemctl; then
    if is_enabled "$L4D2_MASTER_SNAT_ENABLE"; then
      systemctl reload a2s-master-snat || systemctl restart a2s-master-snat || true
    fi
    if is_enabled "$L4D2_GO_PROXY_ENABLE"; then
      systemctl restart a2s-proxy-go || true
    fi
    if is_enabled "$L4D2_GO_PROXY_ENABLE" && is_enabled "$L4D2_GO_PROXY_TRANSPARENT_REDIRECT"; then
      systemctl reload a2s-proxy-redirect || systemctl restart a2s-proxy-redirect || true
    fi
    if is_enabled "$L4D2_A2S_FIREWALL_ENABLE"; then
      systemctl reload a2s-firewall || systemctl restart a2s-firewall || true
    fi
  fi

  if is_enabled "$L4D2_MAP_UPLOADER_ENABLE"; then
    if container_exists "$L4D2_MAP_UPLOADER_CONTAINER_NAME"; then
      docker restart "$L4D2_MAP_UPLOADER_CONTAINER_NAME" >/dev/null
    else
      warn "Map uploader container not found: $L4D2_MAP_UPLOADER_CONTAINER_NAME"
    fi
  fi
  ok "Restart finished."
}

join_by() {
  local IFS="$1"
  shift
  echo "$*"
}

show_status() {
  echo
  echo "================ Docker containers ================"
  if check_cmd docker; then
    docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}" || true
  else
    warn "Docker is not installed."
  fi

  echo
  echo "================ Base container ================"
  if check_cmd docker; then
    docker ps -a --filter "name=^/${L4D2_BASE_CONTAINER_NAME}$" --format "table {{.Names}}\t{{.Image}}\t{{.Status}}" || true
  fi

  echo
  echo "================ Map uploader ================"
  if check_cmd docker; then
    docker ps -a --filter "name=^/${L4D2_MAP_UPLOADER_CONTAINER_NAME}$" --format "table {{.Names}}\t{{.Image}}\t{{.Ports}}\t{{.Status}}" || true
  else
    warn "Docker is not installed."
  fi
  if is_enabled "$L4D2_MAP_UPLOADER_ENABLE"; then
    echo "URL: $(map_uploader_public_base_url)"
    echo "Data dir: ${L4D2_MAP_UPLOADER_DATA_DIR}"
    echo "Shared map dir: ${L4D2_MAP_UPLOAD_DIR}"
  else
    warn "Map uploader Docker is disabled by config."
  fi

  echo
  echo "================ A2S Go proxy ================"
  if check_cmd systemctl; then
    systemctl --no-pager --full status a2s-proxy-go || true
  else
    warn "systemctl is not available."
  fi
  if [[ -f "$L4D2_GO_PROXY_CONFIG" ]]; then
    echo
    echo "A2S Go proxy config: $L4D2_GO_PROXY_CONFIG"
  fi

  echo
  echo "================ A2S transparent redirect ================"
  if check_cmd systemctl; then
    systemctl --no-pager --full status a2s-proxy-redirect || true
  else
    warn "systemctl is not available."
  fi
  if [[ -x "$L4D2_GO_PROXY_REDIRECT_BIN" ]]; then
    "$L4D2_GO_PROXY_REDIRECT_BIN" status || true
  fi

  echo
  echo "================ Master SNAT ================"
  if check_cmd systemctl; then
    systemctl --no-pager --full status a2s-master-snat || true
  else
    warn "systemctl is not available."
  fi
  if [[ -x "$L4D2_MASTER_SNAT_BIN" ]]; then
    "$L4D2_MASTER_SNAT_BIN" status || true
  fi

  echo
  echo "================ A2S firewall ================"
  if check_cmd systemctl; then
    systemctl --no-pager --full status a2s-firewall || true
  else
    warn "systemctl is not available."
  fi
  if [[ -x /usr/local/bin/a2s-firewall.sh ]]; then
    /usr/local/bin/a2s-firewall.sh status || true
  fi

  echo
  echo "================ Listening ports ================"
  if check_cmd ss; then
    local active_game_ports active_proxy_ports all_ports port_regex
    active_game_ports=("${GAME_PORTS_ARRAY[@]:0:${L4D2_SERVER_COUNT}}")
    active_proxy_ports=("${PROXY_LISTEN_PORTS_ARRAY[@]:0:${L4D2_SERVER_COUNT}}")
    all_ports=("${active_game_ports[@]}" "${active_proxy_ports[@]}")
    if is_enabled "$L4D2_MAP_UPLOADER_ENABLE"; then
      all_ports+=("$L4D2_MAP_UPLOADER_PORT")
    fi
    port_regex="$(join_by '|' "${all_ports[@]}")"
    ss -lntup | grep -E "(:|])(${port_regex})([[:space:]]|$)" || true
  else
    warn "ss is not available."
  fi

  echo
  warn "Server count: ${L4D2_SERVER_COUNT}"
  warn "Open these ports in the cloud firewall/security group, at least UDP:"
  if is_enabled "$L4D2_GO_PROXY_ENABLE"; then
    if is_enabled "$L4D2_GO_PROXY_TRANSPARENT_REDIRECT"; then
      echo "  Public game ports: ${GAME_PORTS_ARRAY[*]:0:${L4D2_SERVER_COUNT}}"
      echo "  Internal A2S proxy ports: ${PROXY_LISTEN_PORTS_ARRAY[*]:0:${L4D2_SERVER_COUNT}}"
    else
      echo "  Public proxy/game ports: ${GAME_PORTS_ARRAY[*]:0:${L4D2_SERVER_COUNT}}"
      echo "  Backend ports are internal only: ${BACKEND_PORTS_ARRAY[*]:0:${L4D2_SERVER_COUNT}}"
    fi
  else
    echo "  Game ports: ${GAME_PORTS_ARRAY[*]:0:${L4D2_SERVER_COUNT}}"
    echo "  Backend ports: ${BACKEND_PORTS_ARRAY[*]:0:${L4D2_SERVER_COUNT}}"
  fi
}

debug_master_snat() {
  require_root
  detect_server_ips

  local dest_host dest_port dest_ip duration filter backend_filter public_filter i tcpdump_bin
  dest_host="${L4D2_MASTER_SNAT_DEST%:*}"
  dest_port="${L4D2_MASTER_SNAT_DEST##*:}"
  validate_port "L4D2_MASTER_SNAT_DEST port" "$dest_port"
  dest_ip="$(getent ahostsv4 "$dest_host" | awk '{print $1; exit}')"

  echo "========== Master SNAT Debug =========="
  echo "Destination: ${dest_host}:${dest_port}"
  echo "Resolved IP: ${dest_ip:-unresolved}"
  echo "Server IP: ${L4D2_SERVER_IP}"
  echo "Backend ports: ${BACKEND_PORTS_ARRAY[*]:0:${L4D2_SERVER_COUNT}}"
  echo "Public ports: ${GAME_PORTS_ARRAY[*]:0:${L4D2_SERVER_COUNT}}"
  echo

  if [[ -x "$L4D2_MASTER_SNAT_BIN" ]]; then
    "$L4D2_MASTER_SNAT_BIN" status || true
  else
    warn "Master SNAT script not found: $L4D2_MASTER_SNAT_BIN"
  fi

  echo
  echo "========== recent service logs =========="
  if check_cmd journalctl; then
    journalctl -u a2s-master-snat -n 80 --no-pager || true
  fi

  tcpdump_bin="$(command -v tcpdump || true)"
  if [[ -z "$tcpdump_bin" || -z "$dest_ip" ]]; then
    warn "tcpdump or resolved master IP is unavailable; skipping packet capture."
    return
  fi

  duration="${L4D2_DEBUG_SNIFF_SECONDS:-30}"
  validate_positive_number L4D2_DEBUG_SNIFF_SECONDS "$duration"
  backend_filter=""
  public_filter=""
  for ((i = 0; i < L4D2_SERVER_COUNT; i++)); do
    if [[ -n "$backend_filter" ]]; then
      backend_filter+=" or "
      public_filter+=" or "
    fi
    backend_filter+="src port ${BACKEND_PORTS_ARRAY[$i]}"
    public_filter+="src port ${GAME_PORTS_ARRAY[$i]}"
  done
  filter="udp and host ${dest_ip} and port ${dest_port} and ((${backend_filter}) or (${public_filter}))"

  echo
  echo "========== tcpdump ${duration}s =========="
  echo "Filter: ${filter}"
  timeout "$duration" "$tcpdump_bin" -ni any -vv "$filter" || true
}

uninstall_all() {
  require_root
  warn "Removing proxy services, game containers, and images."

  if check_cmd systemctl; then
    systemctl stop a2s-master-snat >/dev/null 2>&1 || true
    systemctl disable a2s-master-snat >/dev/null 2>&1 || true
    systemctl stop a2s-proxy-go >/dev/null 2>&1 || true
    systemctl disable a2s-proxy-go >/dev/null 2>&1 || true
    systemctl stop a2s-proxy-redirect >/dev/null 2>&1 || true
    systemctl disable a2s-proxy-redirect >/dev/null 2>&1 || true
    systemctl stop a2s-firewall >/dev/null 2>&1 || true
    systemctl disable a2s-firewall >/dev/null 2>&1 || true
  fi
  rm -f /etc/systemd/system/a2s-master-snat.service
  rm -f /etc/systemd/system/a2s-proxy-go.service
  rm -f /etc/systemd/system/a2s-proxy-redirect.service
  rm -f /etc/systemd/system/a2s-firewall.service
  rm -f /usr/local/bin/a2s-firewall.sh
  rm -f /usr/local/bin/a2s-monitor.sh
  rm -f "$L4D2_MASTER_SNAT_BIN"
  rm -f "$L4D2_GO_PROXY_REDIRECT_BIN"
  rm -f "$L4D2_GO_PROXY_BIN"
  rm -rf "$(dirname "$L4D2_GO_PROXY_CONFIG")"

  if check_cmd docker; then
    remove_game_containers
    docker rm -f "$L4D2_MAP_UPLOADER_CONTAINER_NAME" >/dev/null 2>&1 || true
    docker rm -f "$L4D2_BASE_CONTAINER_NAME" >/dev/null 2>&1 || true
    docker rmi "$L4D2_MAP_UPLOADER_IMAGE_NAME" >/dev/null 2>&1 || true
    docker rmi "$L4D2_PROD_IMAGE_NAME" >/dev/null 2>&1 || true
    if [[ "$L4D2_REMOVE_BASE_IMAGE" == "1" ]]; then
      docker rmi "$L4D2_BASE_IMAGE_URL" >/dev/null 2>&1 || true
    fi
  fi

  if check_cmd systemctl; then
    systemctl daemon-reload
  fi
  ok "Uninstall finished."
}

confirm_uninstall() {
  if [[ "$L4D2_ASSUME_YES" == "1" ]]; then
    return
  fi

  local answer
  read -r -p "Remove all L4D2 Docker deployment resources? Type yes to continue: " answer
  [[ "$answer" == "yes" ]] || die "Cancelled."
}

# ══════════════════════════════════════════════════════════════
# HELP & MAIN
# ══════════════════════════════════════════════════════════════

show_help() {
  cat <<EOF
Usage: $0 [-c config.sh] [--legacy-config old-script.sh] [command]

Commands:
  --install     Install dependencies, optional A2S firewall/proxy, and deploy
  --install-uploader Build and run the map uploader Docker container
  --remove-uploader  Stop and remove only the map uploader Docker container
  --install-a2s Install or reload only the A2S firewall
  --remove-a2s  Stop and remove only the A2S firewall
  --install-redirect Install or reload only transparent A2S redirect
  --remove-redirect  Stop and remove only transparent A2S redirect
  --install-snat Install or reload only the master heartbeat SNAT rules
  --remove-snat  Stop and remove only the master heartbeat SNAT rules
  --debug-snat   Show SNAT rules and sniff srcds master heartbeat packets
  --update      git pull in the base container, rebuild image, and redeploy
  --restart     Restart game containers and enabled network services
  --status      Show Docker, uploader, proxy, SNAT, A2S firewall, and port status
  --uninstall   Remove related services, containers, and images
  --help        Show this help

Options:
  -c FILE       Source FILE to override any L4D2_* configuration variable
  --legacy-config FILE
                Read supported env values from an old management script safely

Config:
  All defaults are embedded in the script header.
  Default local file: scripts/l4d2-docker.env
  Env file override: L4D2_ENV_FILE=/path/to/config.sh $0 --install
  Legacy migration: $0 --legacy-config /path/to/old-manager.sh --install
EOF
}

main() {
  local default_env_file
  default_env_file="${SCRIPT_DIR}/l4d2-docker.env"
  if [[ -f "$default_env_file" ]]; then
    source_config_file "$default_env_file"
  fi
  if [[ -n "${L4D2_ENV_FILE:-}" ]]; then
    source_config_file "$L4D2_ENV_FILE"
  fi
  if [[ -n "${L4D2_LEGACY_ENV_FILE:-}" ]]; then
    load_legacy_env_file "$L4D2_LEGACY_ENV_FILE"
  fi

  # Parse optional config files before the command.
  while [[ "${1:-}" == "-c" || "${1:-}" == "--config" || "${1:-}" == "--legacy-config" ]]; do
    case "${1:-}" in
      -c | --config)
        local option_name="$1"
        shift
        local config_file="${1:-}"
        [[ -n "$config_file" ]] || die "$option_name requires a config file argument."
        source_config_file "$config_file"
        shift
        ;;
      --legacy-config)
        shift
        local legacy_config_file="${1:-}"
        [[ -n "$legacy_config_file" ]] || die "--legacy-config requires a file argument."
        load_legacy_env_file "$legacy_config_file"
        shift
        ;;
    esac
  done

  local command="${1:-}"
  case "$command" in
    --install)
      load_config
      validate_config
      require_deploy_config
      install_system_env
      if is_enabled "$L4D2_A2S_FIREWALL_ENABLE"; then
        install_a2s_firewall
      else
        warn "A2S firewall is disabled by config."
      fi
      if is_enabled "$L4D2_GO_PROXY_ENABLE"; then
        install_go_proxy
      else
        warn "A2S Go proxy is disabled by config."
      fi
      if is_enabled "$L4D2_GO_PROXY_ENABLE" && is_enabled "$L4D2_GO_PROXY_TRANSPARENT_REDIRECT"; then
        install_go_proxy_redirect
      else
        remove_go_proxy_redirect
      fi
      if is_enabled "$L4D2_MASTER_SNAT_ENABLE"; then
        install_master_snat
      else
        warn "A2S master SNAT is disabled by config."
      fi
      init_base_container
      update_and_deploy
      show_status
      ;;
    --install-uploader)
      load_config
      validate_config
      install_map_uploader_system_env
      deploy_map_uploader
      show_status
      ;;
    --remove-uploader)
      load_config
      validate_config
      require_root
      remove_map_uploader
      show_status
      ;;
    --install-a2s)
      load_config
      validate_config
      require_root
      install_a2s_firewall
      show_status
      ;;
    --remove-a2s)
      load_config
      validate_config
      require_root
      if check_cmd systemctl; then
        systemctl stop a2s-firewall >/dev/null 2>&1 || true
        systemctl disable a2s-firewall >/dev/null 2>&1 || true
      fi
      if [[ -x /usr/local/bin/a2s-firewall.sh ]]; then
        /usr/local/bin/a2s-firewall.sh remove || true
      fi
      rm -f /etc/systemd/system/a2s-firewall.service
      rm -f /usr/local/bin/a2s-firewall.sh
      rm -f /usr/local/bin/a2s-monitor.sh
      if check_cmd systemctl; then
        systemctl daemon-reload
      fi
      ok "A2S firewall removed."
      ;;
    --install-redirect)
      load_config
      validate_config
      require_root
      install_go_proxy_redirect
      show_status
      ;;
    --remove-redirect)
      load_config
      validate_config
      remove_go_proxy_redirect
      show_status
      ;;
    --install-snat)
      load_config
      validate_config
      require_root
      install_master_snat
      show_status
      ;;
    --remove-snat)
      load_config
      validate_config
      require_root
      if check_cmd systemctl; then
        systemctl stop a2s-master-snat >/dev/null 2>&1 || true
        systemctl disable a2s-master-snat >/dev/null 2>&1 || true
      fi
      if [[ -x "$L4D2_MASTER_SNAT_BIN" ]]; then
        "$L4D2_MASTER_SNAT_BIN" remove || true
      fi
      rm -f /etc/systemd/system/a2s-master-snat.service
      rm -f "$L4D2_MASTER_SNAT_BIN"
      if check_cmd systemctl; then
        systemctl daemon-reload
      fi
      ok "A2S master SNAT removed."
      ;;
    --debug-snat)
      load_config
      validate_config
      debug_master_snat
      ;;
    --update)
      load_config
      validate_config
      require_deploy_config
      require_root
      if is_enabled "$L4D2_MASTER_SNAT_ENABLE"; then
        install_master_snat
      fi
      init_base_container
      update_and_deploy
      if is_enabled "$L4D2_GO_PROXY_ENABLE"; then
        install_go_proxy
      fi
      if is_enabled "$L4D2_GO_PROXY_ENABLE" && is_enabled "$L4D2_GO_PROXY_TRANSPARENT_REDIRECT"; then
        install_go_proxy_redirect
      else
        remove_go_proxy_redirect
      fi
      show_status
      ;;
    --restart)
      load_config
      validate_config
      require_root
      restart_all
      show_status
      ;;
    --status)
      load_config
      validate_config
      show_status
      ;;
    --uninstall)
      load_config
      validate_config
      require_root
      confirm_uninstall
      uninstall_all
      ;;
    --help | -h | help)
      show_help
      ;;
    *)
      show_help
      exit 1
      ;;
  esac
}

main "$@"
