#!/usr/bin/env bash
set -euo pipefail

MYSQL_PORT="${MYSQL_PORT:-12345}"
MYSQL_BIND_ADDRESS="${MYSQL_BIND_ADDRESS:-0.0.0.0}"
MYSQL_PACKAGE="${MYSQL_PACKAGE:-mysql-server}"
MYSQL_SERVICE="${MYSQL_SERVICE:-mysql}"
MYSQL_DATABASES="${MYSQL_DATABASES:-}"
MYSQL_SERVER_ID="${MYSQL_SERVER_ID:-}"
MYSQL_ENABLE_NATIVE_PASSWORD="${MYSQL_ENABLE_NATIVE_PASSWORD:-auto}"
ALLOW_UNSUPPORTED_57_TO_84="${ALLOW_UNSUPPORTED_57_TO_84:-0}"

OLD_DB_HOST="${OLD_DB_HOST:-}"
OLD_DB_PORT="${OLD_DB_PORT:-3306}"
OLD_DB_ADMIN_USER="${OLD_DB_ADMIN_USER:-root}"
OLD_DB_ADMIN_PASS="${OLD_DB_ADMIN_PASS:-}"

CLONE_USERS="${CLONE_USERS:-1}"
CLONE_ROOT_REMOTE="${CLONE_ROOT_REMOTE:-1}"
SETUP_REPLICATION="${SETUP_REPLICATION:-1}"
REQUIRE_REPLICATION="${REQUIRE_REPLICATION:-1}"
REPL_USER="${REPL_USER:-cwa_repl}"
REPL_PASS="${REPL_PASS:-}"
REPL_ALLOWED_HOST="${REPL_ALLOWED_HOST:-%}"
REPLICA_READ_ONLY="${REPLICA_READ_ONLY:-1}"
DROP_EXISTING_DATABASES="${DROP_EXISTING_DATABASES:-0}"
UFW_ALLOW="${UFW_ALLOW:-1}"
LOCAL_MYSQL_CNF="${LOCAL_MYSQL_CNF:-}"

WORK_DIR="${WORK_DIR:-/root/mysql-clone-$(date +%Y%m%d-%H%M%S)}"

die() {
  echo "ERROR: $*" >&2
  exit 1
}

log() {
  echo "==> $*"
}

need_root() {
  [[ "$(id -u)" -eq 0 ]] || die "please run as root"
}

prompt_if_empty() {
  local var_name="$1"
  local prompt="$2"
  local value="${!var_name:-}"

  if [[ -n "$value" ]]; then
    return
  fi
  if [[ ! -t 0 ]]; then
    die "$var_name is required in non-interactive mode"
  fi

  read -r -p "$prompt: " value
  [[ -n "$value" ]] || die "$var_name cannot be empty"
  printf -v "$var_name" '%s' "$value"
}

prompt_secret_if_empty() {
  local var_name="$1"
  local prompt="$2"
  local value="${!var_name:-}"

  if [[ -n "$value" ]]; then
    return
  fi
  if [[ ! -t 0 ]]; then
    die "$var_name is required in non-interactive mode"
  fi

  read -r -s -p "$prompt: " value
  echo
  [[ -n "$value" ]] || die "$var_name cannot be empty"
  printf -v "$var_name" '%s' "$value"
}

sql_literal() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\'/\'\'}"
  printf "'%s'" "$value"
}

account_expr() {
  printf "%s@%s" "$(sql_literal "$1")" "$(sql_literal "$2")"
}

sql_identifier() {
  local value="$1"
  value="${value//\`/\`\`}"
  printf "\`%s\`" "$value"
}

random_password() {
  local value
  set +o pipefail
  value="$(tr -dc 'A-Za-z0-9_@%+=:.,-' </dev/urandom | head -c 32)"
  set -o pipefail
  printf "%s" "$value"
}

derive_server_id() {
  if [[ -n "$MYSQL_SERVER_ID" ]]; then
    echo "$MYSQL_SERVER_ID"
    return
  fi

  local ip_addr
  ip_addr="$(hostname -I 2>/dev/null | awk '{print $1}' || true)"
  if [[ "$ip_addr" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
    local sid
    sid="$(( (${BASH_REMATCH[1]} << 24) + (${BASH_REMATCH[2]} << 16) + (${BASH_REMATCH[3]} << 8) + ${BASH_REMATCH[4]} ))"
    [[ "$sid" -eq 0 ]] && sid=1
    echo "$sid"
    return
  fi

  local random_id
  random_id="$(od -An -N4 -tu4 /dev/urandom | tr -d ' ')"
  [[ "$random_id" -eq 0 ]] && random_id=1
  echo "$random_id"
}

split_databases() {
  local raw="$1"
  raw="${raw//,/ }"
  # shellcheck disable=SC2206
  DB_ARRAY=($raw)
}

version_major_minor() {
  local version="$1"
  if [[ "$version" =~ ^([0-9]+)\.([0-9]+) ]]; then
    printf "%s.%s" "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
  fi
}

should_enable_native_password() {
  case "$MYSQL_ENABLE_NATIVE_PASSWORD" in
    1|true|TRUE|yes|YES|on|ON)
      return 0
      ;;
    0|false|FALSE|no|NO|off|OFF)
      return 1
      ;;
  esac

  command -v mysqld >/dev/null 2>&1 || return 1
  mysqld --verbose --help 2>/dev/null | grep -q -- "mysql-native-password"
}

install_mysql() {
  command -v apt-get >/dev/null 2>&1 || die "this script currently supports Debian/Ubuntu with apt-get"

  log "Installing MySQL package: $MYSQL_PACKAGE"
  export DEBIAN_FRONTEND=noninteractive
  apt-get update
  apt-get install -y "$MYSQL_PACKAGE" mysql-client gzip

  systemctl enable "$MYSQL_SERVICE" >/dev/null 2>&1 || true
}

write_mysql_config() {
  local server_id="$1"
  local config_dir="/etc/mysql/mysql.conf.d"
  local config_file="$config_dir/99-cwa-mysql.cnf"

  [[ -d "$config_dir" ]] || config_dir="/etc/mysql/conf.d"
  config_file="$config_dir/99-cwa-mysql.cnf"

  log "Writing MySQL config: $config_file"
  cat >"$config_file" <<EOF
[mysqld]
port = $MYSQL_PORT
bind-address = $MYSQL_BIND_ADDRESS
server-id = $server_id
log_bin = mysql-bin
binlog_format = ROW
relay_log = mysql-relay-bin
log_slave_updates = ON
skip_name_resolve = ON

# Conservative defaults for a 4-core / 4GB database host.
max_connections = 100
table_open_cache = 2048
thread_cache_size = 64
tmp_table_size = 64M
max_heap_table_size = 64M
max_allowed_packet = 256M
innodb_buffer_pool_size = 1536M
innodb_log_file_size = 256M
expire_logs_days = 7
EOF

  if should_enable_native_password; then
    cat >>"$config_file" <<EOF

# SourceMod/L4D2 plugins often use older MySQL client libraries.
# MySQL 8.4 disables mysql_native_password by default, so keep it available for cloned accounts.
mysql_native_password = ON
EOF
  fi

  if [[ "$REPLICA_READ_ONLY" == "1" && "$SETUP_REPLICATION" == "1" ]]; then
    cat >>"$config_file" <<EOF
read_only = ON
super_read_only = ON
EOF
  fi
}

restart_mysql() {
  log "Restarting MySQL"
  systemctl restart "$MYSQL_SERVICE"
  systemctl is-active --quiet "$MYSQL_SERVICE" || die "MySQL service is not active after restart"
}

allow_firewall_port() {
  if [[ "$UFW_ALLOW" != "1" ]]; then
    return
  fi

  if command -v ufw >/dev/null 2>&1 && ufw status | grep -qi "Status: active"; then
    log "Allowing TCP port $MYSQL_PORT in ufw"
    ufw allow "$MYSQL_PORT/tcp"
  fi
}

make_old_client_config() {
  OLD_CNF="$(mktemp)"
  chmod 600 "$OLD_CNF"
  cat >"$OLD_CNF" <<EOF
[client]
protocol=tcp
host=$OLD_DB_HOST
port=$OLD_DB_PORT
user=$OLD_DB_ADMIN_USER
password=$OLD_DB_ADMIN_PASS
default-character-set=utf8mb4
EOF
}

setup_mysql_commands() {
  old_mysql=(mysql --defaults-extra-file="$OLD_CNF" --batch --raw --skip-column-names)
  old_mysqldump=(mysqldump --defaults-extra-file="$OLD_CNF")

  if [[ -n "$LOCAL_MYSQL_CNF" ]]; then
    local_mysql=(mysql --defaults-extra-file="$LOCAL_MYSQL_CNF")
  else
    local_mysql=(mysql --protocol=socket -uroot)
  fi
}

check_connections() {
  log "Checking old MySQL connection"
  OLD_MYSQL_VERSION="$("${old_mysql[@]}" -e "SELECT VERSION();")"
  log "Old MySQL version: $OLD_MYSQL_VERSION"

  log "Checking local MySQL connection"
  LOCAL_MYSQL_VERSION="$("${local_mysql[@]}" -N -B -e "SELECT VERSION();")"
  log "Local MySQL version: $LOCAL_MYSQL_VERSION"
}

validate_version_path() {
  local old_major_minor local_major_minor
  old_major_minor="$(version_major_minor "$OLD_MYSQL_VERSION")"
  local_major_minor="$(version_major_minor "$LOCAL_MYSQL_VERSION")"

  if [[ "$old_major_minor" == "5.7" && "$local_major_minor" =~ ^([0-9]+)\.([0-9]+)$ ]]; then
    local local_major="${BASH_REMATCH[1]}"
    local local_minor="${BASH_REMATCH[2]}"

    if (( local_major > 8 || (local_major == 8 && local_minor >= 4) )) && [[ "$ALLOW_UNSUPPORTED_57_TO_84" != "1" ]]; then
      die "old MySQL is 5.7 but local MySQL is $LOCAL_MYSQL_VERSION. MySQL does not support skipping 8.0 in the 5.7 -> 8.4 upgrade path. Install MySQL 8.0 on the new server first, or rerun with ALLOW_UNSUPPORTED_57_TO_84=1 if you accept the risk."
    fi
  fi
}

disable_local_read_only_for_restore() {
  log "Disabling local read-only mode for restore"
  "${local_mysql[@]}" -e "SET GLOBAL super_read_only = OFF;" >/dev/null 2>&1 || true
  "${local_mysql[@]}" -e "SET GLOBAL read_only = OFF;" >/dev/null 2>&1 || true
}

detect_databases() {
  if [[ -n "$MYSQL_DATABASES" ]]; then
    split_databases "$MYSQL_DATABASES"
    return
  fi

  log "Detecting non-system databases from old MySQL"
  mapfile -t DB_ARRAY < <("${old_mysql[@]}" -e "SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME NOT IN ('mysql','information_schema','performance_schema','sys') ORDER BY SCHEMA_NAME;")
  [[ "${#DB_ARRAY[@]}" -gt 0 ]] || die "no non-system databases found on old MySQL"
}

check_old_binlog() {
  if [[ "$SETUP_REPLICATION" != "1" ]]; then
    return
  fi

  log "Checking old MySQL binary log status"
  local status
  status="$("${old_mysql[@]}" -e "SHOW MASTER STATUS;" 2>/dev/null || true)"
  if [[ -z "$status" ]]; then
    status="$("${old_mysql[@]}" -e "SHOW BINARY LOG STATUS;" 2>/dev/null || true)"
  fi

  if [[ -z "$status" ]]; then
    if [[ "$REQUIRE_REPLICATION" == "1" ]]; then
      die "old MySQL binary log is not enabled or current user cannot read it. Enable log_bin/server_id on old MySQL first, then rerun. Use SETUP_REPLICATION=0 to clone only."
    fi
    log "Old MySQL binary log is unavailable; continuing without replication"
    SETUP_REPLICATION=0
  fi
}

create_replication_user_on_old() {
  if [[ "$SETUP_REPLICATION" != "1" ]]; then
    return
  fi

  if [[ -z "$REPL_PASS" ]]; then
    REPL_PASS="$(random_password)"
  fi

  local account
  account="$(account_expr "$REPL_USER" "$REPL_ALLOWED_HOST")"

  log "Creating/updating replication user on old MySQL: $REPL_USER@$REPL_ALLOWED_HOST"
  "${old_mysql[@]}" <<SQL
CREATE USER IF NOT EXISTS $account IDENTIFIED BY $(sql_literal "$REPL_PASS");
ALTER USER $account IDENTIFIED BY $(sql_literal "$REPL_PASS");
GRANT REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO $account;
FLUSH PRIVILEGES;
SQL

  cat >"$WORK_DIR/replication-account.txt" <<EOF
replication_user=$REPL_USER
replication_allowed_host=$REPL_ALLOWED_HOST
replication_password=$REPL_PASS
EOF
  chmod 600 "$WORK_DIR/replication-account.txt"
}

clone_mysql_users() {
  if [[ "$CLONE_USERS" != "1" ]]; then
    return
  fi

  local users_sql="$WORK_DIR/mysql-users-and-grants.sql"
  local filter_root="AND user <> 'root'"
  if [[ "$CLONE_ROOT_REMOTE" == "1" ]]; then
    filter_root=""
  fi

  log "Dumping old MySQL users and grants"
  cat >"$users_sql" <<'SQL'
SET @@SESSION.SQL_LOG_BIN = 0;
SQL

  local user_list_query
  user_list_query="
SELECT user, host
FROM mysql.user
WHERE user <> ''
  AND user NOT IN ('mysql.sys','mysql.session','mysql.infoschema','debian-sys-maint')
  AND NOT (user = 'root' AND host IN ('localhost','127.0.0.1','::1'))
  $filter_root
ORDER BY user, host;"

  while IFS=$'\t' read -r user host; do
    [[ -n "$user" && -n "$host" ]] || continue

    local account create_stmt
    account="$(account_expr "$user" "$host")"
    create_stmt="$("${old_mysql[@]}" -e "SHOW CREATE USER $account;" | cut -f2- || true)"

    if [[ -z "$create_stmt" ]]; then
      echo "-- Skipped $user@$host because SHOW CREATE USER failed" >>"$users_sql"
      continue
    fi

    {
      echo "DROP USER IF EXISTS $account;"
      echo "$create_stmt;"
      "${old_mysql[@]}" -e "SHOW GRANTS FOR $account;" | sed 's/$/;/'
      echo
    } >>"$users_sql"
  done < <("${old_mysql[@]}" -e "$user_list_query")

  echo "FLUSH PRIVILEGES;" >>"$users_sql"

  log "Applying cloned users and grants to local MySQL"
  "${local_mysql[@]}" <"$users_sql"
}

drop_existing_databases_if_requested() {
  if [[ "$DROP_EXISTING_DATABASES" != "1" ]]; then
    return
  fi

  log "Dropping existing target databases before restore"
  for db in "${DB_ARRAY[@]}"; do
    "${local_mysql[@]}" -e "DROP DATABASE IF EXISTS $(sql_identifier "$db");"
  done
}

dump_databases_from_old() {
  DUMP_FILE="$WORK_DIR/mysql-dump.sql.gz"

  local dump_args=(
    --single-transaction
    --quick
    --routines
    --events
    --triggers
    --hex-blob
    --compress
    --default-character-set=utf8mb4
    --databases
  )

  if mysqldump --help 2>/dev/null | grep -q -- "--set-gtid-purged"; then
    dump_args+=(--set-gtid-purged=OFF)
  fi

  if [[ "$SETUP_REPLICATION" == "1" ]]; then
    dump_args+=(--master-data=2)
  fi

  log "Dumping databases from old MySQL: ${DB_ARRAY[*]}"
  "${old_mysqldump[@]}" "${dump_args[@]}" "${DB_ARRAY[@]}" | gzip -1 >"$DUMP_FILE"
  chmod 600 "$DUMP_FILE"
}

extract_replication_position() {
  if [[ "$SETUP_REPLICATION" != "1" ]]; then
    return
  fi

  local change_line
  change_line="$(gzip -dc "$DUMP_FILE" | grep -m1 -E 'CHANGE (MASTER|REPLICATION SOURCE) TO' || true)"
  MASTER_LOG_FILE="$(sed -n "s/.*MASTER_LOG_FILE='\([^']*\)'.*/\1/p" <<<"$change_line")"
  MASTER_LOG_POS="$(sed -n "s/.*MASTER_LOG_POS=\([0-9][0-9]*\).*/\1/p" <<<"$change_line")"

  if [[ -z "$MASTER_LOG_FILE" || -z "$MASTER_LOG_POS" ]]; then
    MASTER_LOG_FILE="$(sed -n "s/.*SOURCE_LOG_FILE='\([^']*\)'.*/\1/p" <<<"$change_line")"
    MASTER_LOG_POS="$(sed -n "s/.*SOURCE_LOG_POS=\([0-9][0-9]*\).*/\1/p" <<<"$change_line")"
  fi

  [[ -n "$MASTER_LOG_FILE" && -n "$MASTER_LOG_POS" ]] || die "could not parse replication coordinates from dump"
  log "Replication position: $MASTER_LOG_FILE:$MASTER_LOG_POS"
}

restore_databases_locally() {
  log "Restoring dump into local MySQL"
  {
    echo "SET @@SESSION.SQL_LOG_BIN = 0;"
    gzip -dc "$DUMP_FILE"
  } | "${local_mysql[@]}"
}

configure_replication_on_local() {
  if [[ "$SETUP_REPLICATION" != "1" ]]; then
    return
  fi

  log "Configuring local MySQL as replica of old MySQL"
  local source_sql="$WORK_DIR/change-replication-source.sql"
  local master_sql="$WORK_DIR/change-master.sql"

  cat >"$source_sql" <<SQL
SET GLOBAL super_read_only = OFF;
SET GLOBAL read_only = OFF;
STOP REPLICA;
RESET REPLICA ALL;
CHANGE REPLICATION SOURCE TO
  SOURCE_HOST = $(sql_literal "$OLD_DB_HOST"),
  SOURCE_PORT = $OLD_DB_PORT,
  SOURCE_USER = $(sql_literal "$REPL_USER"),
  SOURCE_PASSWORD = $(sql_literal "$REPL_PASS"),
  SOURCE_LOG_FILE = $(sql_literal "$MASTER_LOG_FILE"),
  SOURCE_LOG_POS = $MASTER_LOG_POS,
  SOURCE_CONNECT_RETRY = 10;
START REPLICA;
SQL

  cat >"$master_sql" <<SQL
SET GLOBAL super_read_only = OFF;
SET GLOBAL read_only = OFF;
STOP SLAVE;
RESET SLAVE ALL;
CHANGE MASTER TO
  MASTER_HOST = $(sql_literal "$OLD_DB_HOST"),
  MASTER_PORT = $OLD_DB_PORT,
  MASTER_USER = $(sql_literal "$REPL_USER"),
  MASTER_PASSWORD = $(sql_literal "$REPL_PASS"),
  MASTER_LOG_FILE = $(sql_literal "$MASTER_LOG_FILE"),
  MASTER_LOG_POS = $MASTER_LOG_POS,
  MASTER_CONNECT_RETRY = 10;
START SLAVE;
SQL

  if ! "${local_mysql[@]}" <"$source_sql" 2>"$WORK_DIR/change-replication-source.err"; then
    log "New replication syntax failed; retrying old MySQL syntax"
    "${local_mysql[@]}" <"$master_sql"
  fi

  if [[ "$REPLICA_READ_ONLY" == "1" ]]; then
    "${local_mysql[@]}" -e "SET GLOBAL read_only = ON; SET GLOBAL super_read_only = ON;"
  fi
}

show_replication_status() {
  if [[ "$SETUP_REPLICATION" != "1" ]]; then
    return
  fi

  sleep 3
  log "Replica status"
  if ! "${local_mysql[@]}" -e "SHOW REPLICA STATUS\\G" 2>/dev/null | tee "$WORK_DIR/replica-status.txt"; then
    "${local_mysql[@]}" -e "SHOW SLAVE STATUS\\G" | tee "$WORK_DIR/replica-status.txt"
  fi
}

print_summary() {
  log "Done"
  echo "Local MySQL port: $MYSQL_PORT"
  echo "Cloned databases: ${DB_ARRAY[*]}"
  echo "Work dir: $WORK_DIR"
  if [[ "$SETUP_REPLICATION" == "1" ]]; then
    echo "Replication: old MySQL -> this new MySQL"
    echo "Replication account file: $WORK_DIR/replication-account.txt"
    echo "Check status: mysql -uroot -e 'SHOW REPLICA STATUS\\G' || mysql -uroot -e 'SHOW SLAVE STATUS\\G'"
    if [[ "$REPLICA_READ_ONLY" == "1" ]]; then
      echo "Replica read_only is ON. Disable read_only/super_read_only before writing directly to the new database."
    fi
  else
    echo "Replication: skipped"
  fi
}

usage() {
  cat <<'EOF'
Usage:
  sudo OLD_DB_HOST=old.example.com OLD_DB_ADMIN_USER=root OLD_DB_ADMIN_PASS='old-pass' \
    MYSQL_DATABASES='Anne,chat,sourcebans,l4d2stats' \
    bash scripts/mysql-install-clone-replica.sh

Important variables:
  OLD_DB_HOST             old MySQL host, required
  OLD_DB_PORT             old MySQL port, default 3306
  OLD_DB_ADMIN_USER       old MySQL admin user, default root
  OLD_DB_ADMIN_PASS       old MySQL admin password, prompted if empty
  MYSQL_PORT              new MySQL port, default 12345
  MYSQL_DATABASES         comma/space separated DB list; empty means all non-system DBs
  SETUP_REPLICATION       1 to configure old -> new replication, default 1
  REQUIRE_REPLICATION     1 to fail if old binlog is unavailable, default 1
  CLONE_USERS             1 to clone MySQL accounts/grants, default 1
  CLONE_ROOT_REMOTE       1 to clone root@remote accounts but never root@localhost, default 1
  REPL_USER               replication user created on old MySQL, default cwa_repl
  REPL_PASS               replication password; generated if empty
  REPL_ALLOWED_HOST       host part for replication user on old MySQL, default %
  REPLICA_READ_ONLY       1 keeps new MySQL read-only while it follows old, default 1
  MYSQL_ENABLE_NATIVE_PASSWORD
                          auto/1/0; auto enables mysql_native_password when the server supports it
  ALLOW_UNSUPPORTED_57_TO_84
                          1 to bypass the guard against direct 5.7 -> 8.4+ migration, default 0
EOF
}

main() {
  if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    exit 0
  fi

  need_root
  prompt_if_empty OLD_DB_HOST "Old MySQL host"
  prompt_secret_if_empty OLD_DB_ADMIN_PASS "Old MySQL admin password"

  mkdir -p "$WORK_DIR"
  chmod 700 "$WORK_DIR"

  trap '[[ -n "${OLD_CNF:-}" && -f "$OLD_CNF" ]] && rm -f "$OLD_CNF"' EXIT

  local server_id
  server_id="$(derive_server_id)"

  install_mysql
  write_mysql_config "$server_id"
  restart_mysql
  allow_firewall_port

  make_old_client_config
  setup_mysql_commands
  check_connections
  validate_version_path
  disable_local_read_only_for_restore
  detect_databases
  check_old_binlog
  create_replication_user_on_old
  clone_mysql_users
  drop_existing_databases_if_requested
  dump_databases_from_old
  extract_replication_position
  restore_databases_locally
  configure_replication_on_local
  show_replication_status
  print_summary
}

main "$@"
