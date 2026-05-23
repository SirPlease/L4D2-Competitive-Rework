#![cfg_attr(
    all(target_os = "windows", not(debug_assertions)),
    windows_subsystem = "windows"
)]

use clap::{Parser, ValueEnum};
use eframe::egui;
use regex::Regex;
use reqwest::blocking::Client;
use serde::{Deserialize, Serialize};
use std::collections::{BTreeMap, BTreeSet, HashMap, HashSet, VecDeque};
use std::env;
use std::fs;
use std::io::{self, Read, Write};
use std::net::{Ipv4Addr, SocketAddr, SocketAddrV4, TcpStream, ToSocketAddrs, UdpSocket};
use std::path::PathBuf;
use std::sync::{
    mpsc::{self, Receiver, Sender},
    Arc, Mutex,
};
use std::thread;
use std::time::{Duration, Instant};

const DEFAULT_MASTER: &str = "hl2master.steampowered.com:27011";
const DEFAULT_FILTER: &str = "\\appid\\550";
const DEFAULT_MASTER_GROUP: &str = "Steam Master";
const DEFAULT_CONFIG_FILE: &str = "l4d2-browser.toml";
const USER_AGENT: &str = "l4d2-server-browser/0.4";

fn main() {
    if let Err(err) = run() {
        eprintln!("error: {err}");
        std::process::exit(1);
    }
}

fn run() -> Result<(), String> {
    let open_gui_by_default = env::args_os().len() == 1;
    let cli = Cli::parse();
    if cli.gui || open_gui_by_default {
        let config_path = cli.config.clone().unwrap_or_else(default_gui_config_path);
        return start_gui(cli, config_path);
    }

    let config = load_config(cli.config.as_ref())?.unwrap_or_default();
    let (settings, manual_groups, subscriptions) = build_runtime(&cli, config)?;
    let rows = load_server_rows(&settings, &manual_groups, &subscriptions)?;

    if settings.json {
        print_json(&rows)?;
    } else {
        print_table(&rows);
    }

    Ok(())
}

fn default_gui_config_path() -> PathBuf {
    #[cfg(target_os = "windows")]
    {
        if let Some(appdata) = env::var_os("APPDATA") {
            return PathBuf::from(appdata)
                .join("L4D2 Server Browser")
                .join(DEFAULT_CONFIG_FILE);
        }
        if let Some(profile) = env::var_os("USERPROFILE") {
            return PathBuf::from(profile)
                .join("AppData")
                .join("Roaming")
                .join("L4D2 Server Browser")
                .join(DEFAULT_CONFIG_FILE);
        }
    }

    #[cfg(target_os = "macos")]
    {
        if let Some(home) = env::var_os("HOME") {
            return PathBuf::from(home)
                .join("Library")
                .join("Application Support")
                .join("L4D2 Server Browser")
                .join(DEFAULT_CONFIG_FILE);
        }
    }

    #[cfg(all(unix, not(target_os = "macos")))]
    {
        if let Some(xdg_config_home) = env::var_os("XDG_CONFIG_HOME") {
            return PathBuf::from(xdg_config_home)
                .join("l4d2-server-browser")
                .join(DEFAULT_CONFIG_FILE);
        }
        if let Some(home) = env::var_os("HOME") {
            return PathBuf::from(home)
                .join(".config")
                .join("l4d2-server-browser")
                .join(DEFAULT_CONFIG_FILE);
        }
    }

    PathBuf::from(DEFAULT_CONFIG_FILE)
}

#[derive(Parser, Debug, Clone)]
#[command(name = "l4d2-server-browser")]
#[command(about = "Left 4 Dead 2 server browser with groups and SourceBans subscriptions.")]
struct Cli {
    #[arg(long)]
    config: Option<PathBuf>,

    #[arg(long)]
    gui: bool,

    #[arg(long)]
    master: Option<String>,

    #[arg(long)]
    master_group: Option<String>,

    #[arg(long)]
    region: Option<String>,

    #[arg(long)]
    filter: Option<String>,

    #[arg(long)]
    extra_filter: Vec<String>,

    #[arg(long)]
    limit: Option<usize>,

    #[arg(long)]
    jobs: Option<usize>,

    #[arg(long)]
    master_timeout_ms: Option<u64>,

    #[arg(long)]
    server_timeout_ms: Option<u64>,

    #[arg(long)]
    http_timeout_ms: Option<u64>,

    #[arg(long, value_enum)]
    sort: Option<SortKey>,

    #[arg(long)]
    min_players: Option<u8>,

    #[arg(long)]
    name: Option<String>,

    #[arg(long)]
    map: Option<String>,

    #[arg(long)]
    only_group: Option<String>,

    #[arg(long)]
    group: Vec<String>,

    #[arg(long)]
    sourcebans: Vec<String>,

    #[arg(long)]
    sourcebans_url: Vec<String>,

    #[arg(long)]
    no_master: bool,

    #[arg(long)]
    no_info: bool,

    #[arg(long)]
    json: bool,
}

#[derive(Debug, Clone, Copy, ValueEnum)]
enum SortKey {
    Players,
    Ping,
    Name,
    Map,
    Address,
    Group,
}

#[derive(Debug, Clone)]
struct RuntimeSettings {
    master_enabled: bool,
    master: String,
    master_group: String,
    region: u8,
    filter: String,
    limit: usize,
    jobs: usize,
    master_timeout: Duration,
    server_timeout: Duration,
    http_timeout: Duration,
    sort: SortKey,
    min_players: Option<u8>,
    name_filter: Option<String>,
    map_filter: Option<String>,
    group_filter: Option<String>,
    no_info: bool,
    json: bool,
}

impl Default for RuntimeSettings {
    fn default() -> Self {
        Self {
            master_enabled: true,
            master: DEFAULT_MASTER.to_owned(),
            master_group: DEFAULT_MASTER_GROUP.to_owned(),
            region: 0xFF,
            filter: DEFAULT_FILTER.to_owned(),
            limit: 100,
            jobs: 32,
            master_timeout: Duration::from_millis(2500),
            server_timeout: Duration::from_millis(800),
            http_timeout: Duration::from_millis(10_000),
            sort: SortKey::Players,
            min_players: None,
            name_filter: None,
            map_filter: None,
            group_filter: None,
            no_info: false,
            json: false,
        }
    }
}

impl RuntimeSettings {
    fn apply_file_master(&mut self, master: Option<FileMaster>) -> Result<(), String> {
        let Some(master) = master else {
            return Ok(());
        };

        if let Some(enabled) = master.enabled {
            self.master_enabled = enabled;
        }
        if let Some(address) = master.address {
            self.master = non_empty(address, "master.address")?;
        }
        if let Some(group) = master.group {
            self.master_group = non_empty(group, "master.group")?;
        }
        if let Some(region) = master.region {
            self.region = parse_region(&region)?;
        }
        if let Some(filter) = master.filter {
            self.filter = filter;
        }
        for extra in master.extra_filter {
            self.filter.push_str(&extra);
        }
        if let Some(limit) = master.limit {
            self.limit = positive(limit, "master.limit")?;
        }

        Ok(())
    }

    fn apply_cli(&mut self, cli: &Cli) -> Result<(), String> {
        if cli.no_master {
            self.master_enabled = false;
        }
        if let Some(master) = &cli.master {
            self.master = non_empty(master.clone(), "--master")?;
        }
        if let Some(group) = &cli.master_group {
            self.master_group = non_empty(group.clone(), "--master-group")?;
        }
        if let Some(region) = &cli.region {
            self.region = parse_region(region)?;
        }
        if let Some(filter) = &cli.filter {
            self.filter = filter.clone();
        }
        for extra in &cli.extra_filter {
            self.filter.push_str(extra);
        }
        if let Some(limit) = cli.limit {
            self.limit = positive(limit, "--limit")?;
        }
        if let Some(jobs) = cli.jobs {
            self.jobs = positive(jobs, "--jobs")?;
        }
        if let Some(ms) = cli.master_timeout_ms {
            self.master_timeout = Duration::from_millis(positive(ms, "--master-timeout-ms")?);
        }
        if let Some(ms) = cli.server_timeout_ms {
            self.server_timeout = Duration::from_millis(positive(ms, "--server-timeout-ms")?);
        }
        if let Some(ms) = cli.http_timeout_ms {
            self.http_timeout = Duration::from_millis(positive(ms, "--http-timeout-ms")?);
        }
        if let Some(sort) = cli.sort {
            self.sort = sort;
        }
        self.min_players = cli.min_players;
        self.name_filter = cli.name.as_ref().map(|value| value.to_lowercase());
        self.map_filter = cli.map.as_ref().map(|value| value.to_lowercase());
        self.group_filter = cli.only_group.as_ref().map(|value| value.to_lowercase());
        self.no_info = cli.no_info;
        self.json = cli.json;

        Ok(())
    }
}

fn build_runtime(
    cli: &Cli,
    config: BrowserConfig,
) -> Result<
    (
        RuntimeSettings,
        Vec<ManualGroup>,
        Vec<SourceBansSubscription>,
    ),
    String,
> {
    let mut settings = RuntimeSettings::default();
    let mut manual_groups = Vec::new();
    let mut subscriptions = Vec::new();

    settings.apply_file_master(config.master)?;
    manual_groups.extend(
        config
            .groups
            .into_iter()
            .map(ManualGroup::try_from)
            .collect::<Result<Vec<_>, _>>()?,
    );
    subscriptions.extend(
        config
            .sourcebans
            .into_iter()
            .map(SourceBansSubscription::try_from)
            .collect::<Result<Vec<_>, _>>()?,
    );

    settings.apply_cli(cli)?;
    manual_groups.extend(
        cli.group
            .iter()
            .map(|value| parse_cli_group(value))
            .collect::<Result<Vec<_>, _>>()?,
    );
    subscriptions.extend(
        cli.sourcebans
            .iter()
            .map(|value| parse_cli_subscription(value))
            .collect::<Result<Vec<_>, _>>()?,
    );
    subscriptions.extend(cli.sourcebans_url.iter().map(|url| SourceBansSubscription {
        name: sourcebans_group_name(url),
        url: url.to_owned(),
    }));

    Ok((settings, manual_groups, subscriptions))
}

fn load_server_rows(
    settings: &RuntimeSettings,
    manual_groups: &[ManualGroup],
    subscriptions: &[SourceBansSubscription],
) -> Result<Vec<ServerRow>, String> {
    let registry = collect_sources(settings, manual_groups, subscriptions)?;
    if registry.is_empty() {
        return Err("no server addresses found from master, groups, or subscriptions".to_owned());
    }

    let endpoints: Vec<_> = registry
        .into_values()
        .map(|entry| Endpoint {
            display: entry.display,
            socket: entry.socket,
            groups: entry.groups.into_iter().collect(),
        })
        .collect();

    let mut rows = if settings.no_info {
        endpoints
            .into_iter()
            .map(|endpoint| ServerRow {
                endpoint,
                info: None,
                ping: None,
                error: None,
            })
            .collect()
    } else {
        query_servers(endpoints, settings.server_timeout, settings.jobs)
    };

    rows = apply_filters(rows, settings);
    sort_rows(&mut rows, settings.sort);
    Ok(rows)
}

#[derive(Debug, Clone, Deserialize, Serialize, Default)]
struct BrowserConfig {
    #[serde(default)]
    master: Option<FileMaster>,
    #[serde(default)]
    groups: Vec<FileGroup>,
    #[serde(default)]
    sourcebans: Vec<FileSourceBans>,
}

#[derive(Debug, Clone, Deserialize, Serialize, Default)]
struct FileMaster {
    enabled: Option<bool>,
    address: Option<String>,
    group: Option<String>,
    region: Option<String>,
    filter: Option<String>,
    #[serde(default)]
    extra_filter: Vec<String>,
    limit: Option<usize>,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
struct FileGroup {
    name: String,
    servers: Vec<String>,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
struct FileSourceBans {
    name: String,
    url: String,
}

#[derive(Debug, Clone)]
struct ManualGroup {
    name: String,
    servers: Vec<String>,
}

#[derive(Debug, Clone)]
struct SourceBansSubscription {
    name: String,
    url: String,
}

impl TryFrom<FileGroup> for ManualGroup {
    type Error = String;

    fn try_from(value: FileGroup) -> Result<Self, Self::Error> {
        Ok(Self {
            name: non_empty(value.name, "groups.name")?,
            servers: value.servers,
        })
    }
}

impl TryFrom<FileSourceBans> for SourceBansSubscription {
    type Error = String;

    fn try_from(value: FileSourceBans) -> Result<Self, Self::Error> {
        Ok(Self {
            name: non_empty(value.name, "sourcebans.name")?,
            url: non_empty(value.url, "sourcebans.url")?,
        })
    }
}

fn load_config(path: Option<&PathBuf>) -> Result<Option<BrowserConfig>, String> {
    let Some(path) = path else {
        return Ok(None);
    };

    let text = fs::read_to_string(path)
        .map_err(|err| format!("failed to read config {}: {err}", path.display()))?;
    let config = toml::from_str(&text)
        .map_err(|err| format!("failed to parse config {}: {err}", path.display()))?;
    Ok(Some(config))
}

fn load_config_or_default(path: &PathBuf) -> Result<BrowserConfig, String> {
    match fs::read_to_string(path) {
        Ok(text) => toml::from_str(&text)
            .map_err(|err| format!("failed to parse config {}: {err}", path.display())),
        Err(err) if err.kind() == io::ErrorKind::NotFound => Ok(BrowserConfig::default()),
        Err(err) => Err(format!("failed to read config {}: {err}", path.display())),
    }
}

fn save_config(path: &PathBuf, config: &BrowserConfig) -> Result<(), String> {
    if let Some(parent) = path.parent() {
        if !parent.as_os_str().is_empty() {
            fs::create_dir_all(parent).map_err(|err| {
                format!(
                    "failed to create config directory {}: {err}",
                    parent.display()
                )
            })?;
        }
    }

    let text = toml::to_string_pretty(config)
        .map_err(|err| format!("failed to serialize config: {err}"))?;
    fs::write(path, text).map_err(|err| format!("failed to write config {}: {err}", path.display()))
}

fn non_empty(value: String, field: &str) -> Result<String, String> {
    if value.trim().is_empty() {
        Err(format!("{field} cannot be empty"))
    } else {
        Ok(value)
    }
}

fn positive<T>(value: T, field: &str) -> Result<T, String>
where
    T: PartialEq + From<u8> + Copy,
{
    if value == T::from(0) {
        Err(format!("{field} must be greater than zero"))
    } else {
        Ok(value)
    }
}

fn parse_cli_group(value: &str) -> Result<ManualGroup, String> {
    let (name, servers) = split_name_value(value, "--group")?;
    let servers = servers
        .split(|ch| ch == ',' || ch == ';' || ch == ' ')
        .filter(|part| !part.trim().is_empty())
        .map(|part| part.trim().to_owned())
        .collect::<Vec<_>>();

    if servers.is_empty() {
        return Err("--group requires at least one server address".to_owned());
    }

    Ok(ManualGroup { name, servers })
}

fn parse_cli_subscription(value: &str) -> Result<SourceBansSubscription, String> {
    let (name, url) = split_name_value(value, "--sourcebans")?;
    Ok(SourceBansSubscription { name, url })
}

fn split_name_value(value: &str, flag: &str) -> Result<(String, String), String> {
    let (name, value) = value
        .split_once('=')
        .ok_or_else(|| format!("{flag} must use NAME=VALUE"))?;
    let name = non_empty(name.trim().to_owned(), flag)?;
    let value = non_empty(value.trim().to_owned(), flag)?;
    Ok((name, value))
}

fn parse_region(value: &str) -> Result<u8, String> {
    match value.to_ascii_lowercase().as_str() {
        "us-east" | "useast" => Ok(0x00),
        "us-west" | "uswest" => Ok(0x01),
        "south-america" | "southamerica" => Ok(0x02),
        "europe" => Ok(0x03),
        "asia" => Ok(0x04),
        "australia" => Ok(0x05),
        "middle-east" | "middleeast" => Ok(0x06),
        "africa" => Ok(0x07),
        "all" | "rest" | "world" => Ok(0xFF),
        _ => value
            .parse::<u8>()
            .map_err(|_| format!("invalid region: {value}")),
    }
}

fn collect_sources(
    settings: &RuntimeSettings,
    manual_groups: &[ManualGroup],
    subscriptions: &[SourceBansSubscription],
) -> Result<HashMap<SocketAddrV4, RegistryEntry>, String> {
    let mut registry = HashMap::new();

    if settings.master_enabled {
        let master_addr = resolve_ipv4(&settings.master)
            .map_err(|err| format!("failed to resolve master server {}: {err}", settings.master))?;
        let master = MasterClient {
            addr: master_addr,
            timeout: settings.master_timeout,
        };
        for endpoint in master
            .fetch(settings.region, &settings.filter, settings.limit)
            .map_err(|err| format!("master server query failed: {err}"))?
        {
            add_endpoint(&mut registry, endpoint, &settings.master_group);
        }
    }

    for group in manual_groups {
        for server in &group.servers {
            match resolve_endpoint(server) {
                Ok(endpoint) => add_endpoint(&mut registry, endpoint, &group.name),
                Err(err) => eprintln!("warning: skipped {} in group {}: {err}", server, group.name),
            }
        }
    }

    for subscription in subscriptions {
        match fetch_sourcebans_subscription(subscription, settings.http_timeout) {
            Ok(addresses) => {
                for address in addresses {
                    match resolve_endpoint(&address) {
                        Ok(endpoint) => add_endpoint(&mut registry, endpoint, &subscription.name),
                        Err(err) => eprintln!(
                            "warning: skipped {} from SourceBans {}: {err}",
                            address, subscription.url
                        ),
                    }
                }
            }
            Err(err) => eprintln!(
                "warning: SourceBans subscription {} failed: {err}",
                subscription.url
            ),
        }
    }

    Ok(registry)
}

#[derive(Debug, Clone)]
struct RegistryEntry {
    display: String,
    socket: SocketAddrV4,
    groups: BTreeSet<String>,
}

#[derive(Debug, Clone)]
struct Endpoint {
    display: String,
    socket: SocketAddrV4,
    groups: Vec<String>,
}

fn add_endpoint(
    registry: &mut HashMap<SocketAddrV4, RegistryEntry>,
    endpoint: Endpoint,
    group: &str,
) {
    let entry = registry
        .entry(endpoint.socket)
        .or_insert_with(|| RegistryEntry {
            display: endpoint.display,
            socket: endpoint.socket,
            groups: BTreeSet::new(),
        });
    entry.groups.insert(group.to_owned());
}

#[derive(Debug, Clone)]
struct ServerRow {
    endpoint: Endpoint,
    info: Option<ServerInfo>,
    ping: Option<Duration>,
    error: Option<String>,
}

#[derive(Debug, Clone, Serialize)]
struct ServerInfo {
    protocol: u8,
    name: String,
    map: String,
    folder: String,
    game: String,
    app_id: u16,
    players: u8,
    max_players: u8,
    bots: u8,
    server_type: char,
    environment: char,
    private: bool,
    vac: bool,
    version: String,
    port: Option<u16>,
    steam_id: Option<u64>,
    spectator_port: Option<u16>,
    spectator_name: Option<String>,
    keywords: Option<String>,
    game_id: Option<u64>,
}

struct MasterClient {
    addr: SocketAddrV4,
    timeout: Duration,
}

impl MasterClient {
    fn fetch(&self, region: u8, filter: &str, limit: usize) -> io::Result<Vec<Endpoint>> {
        let socket = UdpSocket::bind("0.0.0.0:0")?;
        socket.set_read_timeout(Some(self.timeout))?;
        socket.set_write_timeout(Some(self.timeout))?;

        let mut cursor = "0.0.0.0:0".to_owned();
        let mut results = Vec::new();
        let mut seen = HashSet::new();
        let mut pages = 0usize;

        while results.len() < limit {
            pages += 1;
            if pages > 10_000 {
                break;
            }

            let request = build_master_request(region, &cursor, filter);
            socket.send_to(&request, SocketAddr::V4(self.addr))?;

            let mut buf = [0u8; 1500];
            let size = match socket.recv_from(&mut buf) {
                Ok((size, _from)) => size,
                Err(err)
                    if err.kind() == io::ErrorKind::WouldBlock
                        || err.kind() == io::ErrorKind::TimedOut =>
                {
                    if results.is_empty() {
                        return Err(err);
                    }
                    break;
                }
                Err(err) => return Err(err),
            };

            let page = parse_master_response(&buf[..size])
                .map_err(|err| io::Error::new(io::ErrorKind::InvalidData, err))?;
            if page.is_empty() {
                break;
            }

            let mut advanced = false;
            for addr in page {
                cursor = addr.to_string();
                advanced = true;

                if seen.insert(addr) {
                    results.push(Endpoint {
                        display: addr.to_string(),
                        socket: addr,
                        groups: Vec::new(),
                    });
                    if results.len() >= limit {
                        break;
                    }
                }
            }

            if !advanced {
                break;
            }
        }

        Ok(results)
    }
}

fn build_master_request(region: u8, cursor: &str, filter: &str) -> Vec<u8> {
    let mut request = Vec::with_capacity(3 + cursor.len() + filter.len());
    request.push(0x31);
    request.push(region);
    request.extend_from_slice(cursor.as_bytes());
    request.push(0);
    request.extend_from_slice(filter.as_bytes());
    request.push(0);
    request
}

fn parse_master_response(packet: &[u8]) -> Result<Vec<SocketAddrV4>, String> {
    let offset = if packet.len() >= 6
        && packet.starts_with(&[0xFF, 0xFF, 0xFF, 0xFF])
        && packet[4] == 0x66
    {
        6
    } else {
        return Err("invalid master server response header".to_owned());
    };

    let mut addrs = Vec::new();
    for chunk in packet[offset..].chunks_exact(6) {
        let ip = Ipv4Addr::new(chunk[0], chunk[1], chunk[2], chunk[3]);
        let port = u16::from_be_bytes([chunk[4], chunk[5]]);

        if ip == Ipv4Addr::new(0, 0, 0, 0) && port == 0 {
            continue;
        }

        addrs.push(SocketAddrV4::new(ip, port));
    }

    Ok(addrs)
}

fn fetch_sourcebans_subscription(
    subscription: &SourceBansSubscription,
    timeout: Duration,
) -> Result<Vec<String>, String> {
    let url = normalize_sourcebans_url(&subscription.url)?;
    let client = Client::builder()
        .timeout(timeout)
        .user_agent(USER_AGENT)
        .build()
        .map_err(|err| err.to_string())?;
    let body = client
        .get(url.clone())
        .send()
        .map_err(|err| err.to_string())?
        .error_for_status()
        .map_err(|err| err.to_string())?
        .text()
        .map_err(|err| err.to_string())?;
    let addresses = extract_sourcebans_addresses(&body)?;

    if addresses.is_empty() {
        Err(format!("no server addresses found at {url}"))
    } else {
        Ok(addresses)
    }
}

fn normalize_sourcebans_url(input: &str) -> Result<reqwest::Url, String> {
    let input = input.trim();
    let parse_input = if input.contains("://") {
        input.to_owned()
    } else {
        format!("https://{input}")
    };
    let mut url =
        reqwest::Url::parse(&parse_input).map_err(|err| format!("invalid URL {input}: {err}"))?;
    let has_servers_page = url
        .query_pairs()
        .any(|(key, value)| key.eq_ignore_ascii_case("p") && value.eq_ignore_ascii_case("servers"));

    if has_servers_page {
        return Ok(url);
    }

    if !url.path().ends_with(".php") {
        let mut path = url.path().trim_end_matches('/').to_owned();
        path.push_str("/index.php");
        url.set_path(&path);
    }
    url.query_pairs_mut().append_pair("p", "servers");
    Ok(url)
}

fn extract_sourcebans_addresses(body: &str) -> Result<Vec<String>, String> {
    let body = decode_minimal_html_entities(body);
    let connect_re =
        Regex::new(r#"(?i)steam://connect/([^"'<>\s]+)"#).map_err(|err| err.to_string())?;
    let ip_re = Regex::new(
        r#"\b((?:(?:25[0-5]|2[0-4]\d|1?\d?\d)\.){3}(?:25[0-5]|2[0-4]\d|1?\d?\d)):(\d{2,5})\b"#,
    )
    .map_err(|err| err.to_string())?;
    let host_re = Regex::new(r#"\b([A-Za-z0-9][A-Za-z0-9.-]*\.[A-Za-z]{2,})(?::)(\d{2,5})\b"#)
        .map_err(|err| err.to_string())?;

    let mut seen = BTreeSet::new();
    for capture in connect_re.captures_iter(&body) {
        if let Some(raw) = capture.get(1) {
            let address = raw
                .as_str()
                .split('/')
                .next()
                .unwrap_or(raw.as_str())
                .to_owned();
            seen.insert(address);
        }
    }

    for capture in ip_re.captures_iter(&body) {
        let port = capture
            .get(2)
            .and_then(|value| value.as_str().parse::<u16>().ok());
        if port.is_some() {
            seen.insert(format!("{}:{}", &capture[1], &capture[2]));
        }
    }

    for capture in host_re.captures_iter(&body) {
        let port = capture
            .get(2)
            .and_then(|value| value.as_str().parse::<u16>().ok());
        if port.is_some() {
            seen.insert(format!("{}:{}", &capture[1], &capture[2]));
        }
    }

    Ok(seen.into_iter().collect())
}

fn decode_minimal_html_entities(value: &str) -> String {
    value
        .replace("&amp;", "&")
        .replace("&#38;", "&")
        .replace("&#x26;", "&")
        .replace("&colon;", ":")
        .replace("&#58;", ":")
        .replace("&#x3a;", ":")
        .replace("&#x3A;", ":")
}

fn sourcebans_group_name(url: &str) -> String {
    let parse_input = if url.contains("://") {
        url.to_owned()
    } else {
        format!("https://{url}")
    };

    reqwest::Url::parse(&parse_input)
        .ok()
        .and_then(|url| url.host_str().map(|host| format!("SourceBans:{host}")))
        .unwrap_or_else(|| "SourceBans".to_owned())
}

fn resolve_endpoint(input: &str) -> Result<Endpoint, String> {
    let address = normalize_endpoint_input(input)?;
    let socket =
        resolve_ipv4(&address).map_err(|err| format!("failed to resolve {address}: {err}"))?;

    Ok(Endpoint {
        display: address,
        socket,
        groups: Vec::new(),
    })
}

fn normalize_endpoint_input(input: &str) -> Result<String, String> {
    let mut value = input.trim();
    if let Some(rest) = value.strip_prefix("steam://connect/") {
        value = rest.split('/').next().unwrap_or(rest);
    }

    if value.is_empty() {
        return Err("server address cannot be empty".to_owned());
    }
    if !value.contains(':') {
        return Err("server address must include a port, for example 1.2.3.4:27015".to_owned());
    }

    Ok(value.to_owned())
}

fn resolve_ipv4(input: &str) -> io::Result<SocketAddrV4> {
    input
        .to_socket_addrs()?
        .find_map(|addr| match addr {
            SocketAddr::V4(addr) => Some(addr),
            SocketAddr::V6(_) => None,
        })
        .ok_or_else(|| io::Error::new(io::ErrorKind::NotFound, "no IPv4 address found"))
}

fn query_servers(endpoints: Vec<Endpoint>, timeout: Duration, jobs: usize) -> Vec<ServerRow> {
    if endpoints.is_empty() {
        return Vec::new();
    }

    let queue: VecDeque<_> = endpoints.into_iter().collect();
    let queue = Arc::new(Mutex::new(queue));
    let results = Arc::new(Mutex::new(Vec::new()));
    let worker_count = jobs.min(queue.lock().expect("queue poisoned").len()).max(1);

    let mut workers = Vec::with_capacity(worker_count);
    for _ in 0..worker_count {
        let queue = Arc::clone(&queue);
        let results = Arc::clone(&results);

        workers.push(thread::spawn(move || loop {
            let next = {
                let mut queue = queue.lock().expect("queue poisoned");
                queue.pop_front()
            };

            let endpoint = match next {
                Some(endpoint) => endpoint,
                None => break,
            };

            let row = match query_server_info(endpoint.socket, timeout) {
                Ok((info, ping)) => ServerRow {
                    endpoint,
                    info: Some(info),
                    ping: Some(ping),
                    error: None,
                },
                Err(error) => ServerRow {
                    endpoint,
                    info: None,
                    ping: None,
                    error: Some(error),
                },
            };

            results.lock().expect("results poisoned").push(row);
        }));
    }

    for worker in workers {
        let _ = worker.join();
    }

    let mut results = results.lock().expect("results poisoned");
    std::mem::take(&mut *results)
}

fn query_server_info(
    addr: SocketAddrV4,
    timeout: Duration,
) -> Result<(ServerInfo, Duration), String> {
    let socket = UdpSocket::bind("0.0.0.0:0").map_err(|err| err.to_string())?;
    socket
        .set_read_timeout(Some(timeout))
        .map_err(|err| err.to_string())?;
    socket
        .set_write_timeout(Some(timeout))
        .map_err(|err| err.to_string())?;
    socket
        .connect(SocketAddr::V4(addr))
        .map_err(|err| err.to_string())?;

    let started = Instant::now();
    let request = build_a2s_info_request(None);
    socket.send(&request).map_err(|err| err.to_string())?;

    let mut buf = [0u8; 4096];
    let size = socket.recv(&mut buf).map_err(|err| err.to_string())?;
    let packet = &buf[..size];

    if let Some(challenge) = parse_challenge(packet) {
        let request = build_a2s_info_request(Some(challenge));
        socket.send(&request).map_err(|err| err.to_string())?;
        let size = socket.recv(&mut buf).map_err(|err| err.to_string())?;
        let info = parse_server_info(&buf[..size])?;
        return Ok((info, started.elapsed()));
    }

    let info = parse_server_info(packet)?;
    Ok((info, started.elapsed()))
}

fn build_a2s_info_request(challenge: Option<[u8; 4]>) -> Vec<u8> {
    let mut request = Vec::from(&b"\xFF\xFF\xFF\xFFTSource Engine Query\0"[..]);
    if let Some(challenge) = challenge {
        request.extend_from_slice(&challenge);
    }
    request
}

fn parse_challenge(packet: &[u8]) -> Option<[u8; 4]> {
    if packet.len() >= 9 && packet.starts_with(&[0xFF, 0xFF, 0xFF, 0xFF]) && packet[4] == 0x41 {
        Some([packet[5], packet[6], packet[7], packet[8]])
    } else {
        None
    }
}

fn parse_server_info(packet: &[u8]) -> Result<ServerInfo, String> {
    if packet.len() >= 4 && packet.starts_with(&[0xFE, 0xFF, 0xFF, 0xFF]) {
        return Err("split A2S_INFO response is not supported".to_owned());
    }

    if packet.len() < 5 || !packet.starts_with(&[0xFF, 0xFF, 0xFF, 0xFF]) || packet[4] != 0x49 {
        return Err("invalid A2S_INFO response".to_owned());
    }

    let mut reader = PacketReader::new(&packet[5..]);
    let protocol = reader.u8()?;
    let name = reader.string()?;
    let map = reader.string()?;
    let folder = reader.string()?;
    let game = reader.string()?;
    let app_id = reader.u16_le()?;
    let players = reader.u8()?;
    let max_players = reader.u8()?;
    let bots = reader.u8()?;
    let server_type = reader.u8()? as char;
    let environment = reader.u8()? as char;
    let private = reader.u8()? != 0;
    let vac = reader.u8()? != 0;
    let version = reader.string()?;

    let mut info = ServerInfo {
        protocol,
        name,
        map,
        folder,
        game,
        app_id,
        players,
        max_players,
        bots,
        server_type,
        environment,
        private,
        vac,
        version,
        port: None,
        steam_id: None,
        spectator_port: None,
        spectator_name: None,
        keywords: None,
        game_id: None,
    };

    if reader.remaining() > 0 {
        let edf = reader.u8()?;
        if edf & 0x80 != 0 {
            info.port = Some(reader.u16_le()?);
        }
        if edf & 0x10 != 0 {
            info.steam_id = Some(reader.u64_le()?);
        }
        if edf & 0x40 != 0 {
            info.spectator_port = Some(reader.u16_le()?);
            info.spectator_name = Some(reader.string()?);
        }
        if edf & 0x20 != 0 {
            info.keywords = Some(reader.string()?);
        }
        if edf & 0x01 != 0 {
            info.game_id = Some(reader.u64_le()?);
        }
    }

    Ok(info)
}

struct PacketReader<'a> {
    packet: &'a [u8],
    pos: usize,
}

impl<'a> PacketReader<'a> {
    fn new(packet: &'a [u8]) -> Self {
        Self { packet, pos: 0 }
    }

    fn remaining(&self) -> usize {
        self.packet.len().saturating_sub(self.pos)
    }

    fn u8(&mut self) -> Result<u8, String> {
        if self.remaining() < 1 {
            return Err("unexpected end of packet".to_owned());
        }
        let value = self.packet[self.pos];
        self.pos += 1;
        Ok(value)
    }

    fn u16_le(&mut self) -> Result<u16, String> {
        let bytes = self.take(2)?;
        Ok(u16::from_le_bytes([bytes[0], bytes[1]]))
    }

    fn u64_le(&mut self) -> Result<u64, String> {
        let bytes = self.take(8)?;
        Ok(u64::from_le_bytes([
            bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7],
        ]))
    }

    fn string(&mut self) -> Result<String, String> {
        let start = self.pos;
        let end = self.packet[start..]
            .iter()
            .position(|byte| *byte == 0)
            .map(|offset| start + offset)
            .ok_or_else(|| "unterminated string in packet".to_owned())?;

        self.pos = end + 1;
        Ok(String::from_utf8_lossy(&self.packet[start..end]).into_owned())
    }

    fn take(&mut self, count: usize) -> Result<&'a [u8], String> {
        if self.remaining() < count {
            return Err("unexpected end of packet".to_owned());
        }
        let start = self.pos;
        self.pos += count;
        Ok(&self.packet[start..start + count])
    }
}

fn apply_filters(rows: Vec<ServerRow>, settings: &RuntimeSettings) -> Vec<ServerRow> {
    rows.into_iter()
        .filter(|row| {
            if let Some(needle) = &settings.group_filter {
                let matched = row
                    .endpoint
                    .groups
                    .iter()
                    .any(|group| group.to_lowercase().contains(needle));
                if !matched {
                    return false;
                }
            }

            let Some(info) = &row.info else {
                return settings.min_players.is_none()
                    && settings.name_filter.is_none()
                    && settings.map_filter.is_none();
            };

            if let Some(min_players) = settings.min_players {
                if info.players < min_players {
                    return false;
                }
            }

            if let Some(needle) = &settings.name_filter {
                if !info.name.to_lowercase().contains(needle) {
                    return false;
                }
            }

            if let Some(needle) = &settings.map_filter {
                if !info.map.to_lowercase().contains(needle) {
                    return false;
                }
            }

            true
        })
        .collect()
}

fn sort_rows(rows: &mut [ServerRow], sort: SortKey) {
    match sort {
        SortKey::Players => rows.sort_by(|a, b| {
            players(b)
                .cmp(&players(a))
                .then_with(|| max_players(b).cmp(&max_players(a)))
                .then_with(|| ping_ms(a).cmp(&ping_ms(b)))
                .then_with(|| address_key(a).cmp(&address_key(b)))
        }),
        SortKey::Ping => rows.sort_by(|a, b| {
            ping_ms(a)
                .cmp(&ping_ms(b))
                .then_with(|| players(b).cmp(&players(a)))
                .then_with(|| address_key(a).cmp(&address_key(b)))
        }),
        SortKey::Name => rows.sort_by(|a, b| {
            name_key(a)
                .cmp(&name_key(b))
                .then_with(|| address_key(a).cmp(&address_key(b)))
        }),
        SortKey::Map => rows.sort_by(|a, b| {
            map_key(a)
                .cmp(&map_key(b))
                .then_with(|| players(b).cmp(&players(a)))
                .then_with(|| address_key(a).cmp(&address_key(b)))
        }),
        SortKey::Address => rows.sort_by(|a, b| address_key(a).cmp(&address_key(b))),
        SortKey::Group => rows.sort_by(|a, b| {
            group_key(a)
                .cmp(&group_key(b))
                .then_with(|| players(b).cmp(&players(a)))
                .then_with(|| address_key(a).cmp(&address_key(b)))
        }),
    }
}

fn players(row: &ServerRow) -> u8 {
    row.info.as_ref().map(|info| info.players).unwrap_or(0)
}

fn max_players(row: &ServerRow) -> u8 {
    row.info.as_ref().map(|info| info.max_players).unwrap_or(0)
}

fn ping_ms(row: &ServerRow) -> u128 {
    row.ping.map(|ping| ping.as_millis()).unwrap_or(u128::MAX)
}

fn name_key(row: &ServerRow) -> String {
    row.info
        .as_ref()
        .map(|info| info.name.to_lowercase())
        .unwrap_or_else(|| "~".to_owned())
}

fn map_key(row: &ServerRow) -> String {
    row.info
        .as_ref()
        .map(|info| info.map.to_lowercase())
        .unwrap_or_else(|| "~".to_owned())
}

fn group_key(row: &ServerRow) -> String {
    row.endpoint.groups.join(",").to_lowercase()
}

fn address_key(row: &ServerRow) -> String {
    row.endpoint.socket.to_string()
}

fn print_table(rows: &[ServerRow]) {
    if rows.is_empty() {
        println!("no servers matched");
        return;
    }

    println!(
        "{:<20} {:<21} {:>7} {:>7} {:>4} {:<22} {:<4} {:<7} {}",
        "group", "address", "ping", "players", "bots", "map", "vac", "access", "name"
    );
    println!("{}", "-".repeat(126));

    for row in rows {
        let groups = clip(&row.endpoint.groups.join(","), 20);
        match &row.info {
            Some(info) => {
                let ping = row
                    .ping
                    .map(|duration| duration.as_millis().to_string())
                    .unwrap_or_else(|| "-".to_owned());
                let players = format!("{}/{}", info.players, info.max_players);
                let vac = if info.vac { "yes" } else { "no" };
                let access = if info.private { "private" } else { "public" };

                println!(
                    "{:<20} {:<21} {:>7} {:>7} {:>4} {:<22} {:<4} {:<7} {}",
                    groups,
                    row.endpoint.display,
                    ping,
                    players,
                    info.bots,
                    clip(&info.map, 22),
                    vac,
                    access,
                    clip(&info.name, 48)
                );
            }
            None => {
                let error = row.error.as_deref().unwrap_or("not queried");
                println!(
                    "{:<20} {:<21} {:>7} {:>7} {:>4} {:<22} {:<4} {:<7} {}",
                    groups,
                    row.endpoint.display,
                    "-",
                    "-",
                    "-",
                    "-",
                    "-",
                    "-",
                    clip(error, 48)
                );
            }
        }
    }
}

fn clip(value: &str, width: usize) -> String {
    let mut chars = value.chars();
    let clipped: String = chars.by_ref().take(width).collect();
    if chars.next().is_some() && width > 3 {
        let mut clipped: String = value.chars().take(width - 3).collect();
        clipped.push_str("...");
        clipped
    } else {
        clipped
    }
}

#[derive(Serialize)]
struct JsonRow<'a> {
    address: &'a str,
    socket: String,
    groups: &'a [String],
    ping_ms: Option<u64>,
    info: &'a Option<ServerInfo>,
    error: &'a Option<String>,
}

fn print_json(rows: &[ServerRow]) -> Result<(), String> {
    let payload = rows
        .iter()
        .map(|row| JsonRow {
            address: &row.endpoint.display,
            socket: row.endpoint.socket.to_string(),
            groups: &row.endpoint.groups,
            ping_ms: row.ping.map(|ping| ping.as_millis() as u64),
            info: &row.info,
            error: &row.error,
        })
        .collect::<Vec<_>>();
    let json = serde_json::to_string_pretty(&payload).map_err(|err| err.to_string())?;
    println!("{json}");
    Ok(())
}

#[derive(Clone)]
struct AddServerRequest {
    group: String,
    server: String,
}

#[derive(Clone)]
struct AddSourceBansRequest {
    name: String,
    url: String,
}

#[derive(Clone)]
struct RconCommandRequest {
    address: String,
    password: String,
    command: String,
    timeout_ms: Option<u64>,
}

#[derive(Clone)]
struct CvarRequest {
    address: String,
    password: Option<String>,
    names: Option<Vec<String>>,
    timeout_ms: Option<u64>,
}

#[derive(Clone, Serialize)]
struct ServerRowPayload {
    address: String,
    socket: String,
    groups: Vec<String>,
    ping_ms: Option<u64>,
    info: Option<ServerInfo>,
    error: Option<String>,
}

#[derive(Clone, Serialize)]
struct CvarPayload {
    source: String,
    values: BTreeMap<String, String>,
}

enum GuiMessage {
    Servers(Result<Vec<ServerRowPayload>, String>),
    AddServer(Result<(), String>),
    AddSourceBans(Result<(), String>),
    Rcon(Result<String, String>),
    Cvars(Result<CvarPayload, String>),
}

struct NativeGuiApp {
    cli: Cli,
    config_path: PathBuf,
    tx: Sender<GuiMessage>,
    rx: Receiver<GuiMessage>,
    servers: Vec<ServerRowPayload>,
    server_status: String,
    config_status: String,
    group_name: String,
    server_address: String,
    sourcebans_name: String,
    sourcebans_url: String,
    rcon_address: String,
    rcon_password: String,
    rcon_command_text: String,
    rcon_output: String,
    cvar_address: String,
    cvar_password: String,
    cvar_names: String,
    cvar_output: String,
}

fn start_gui(cli: Cli, config_path: PathBuf) -> Result<(), String> {
    let options = eframe::NativeOptions {
        viewport: egui::ViewportBuilder::default().with_inner_size([1180.0, 760.0]),
        ..Default::default()
    };
    let title = "L4D2 刷服器".to_owned();

    eframe::run_native(
        &title,
        options,
        Box::new(move |_cc| Ok(Box::new(NativeGuiApp::new(cli, config_path)))),
    )
    .map_err(|err| format!("failed to start native GUI: {err}"))
}

impl NativeGuiApp {
    fn new(cli: Cli, config_path: PathBuf) -> Self {
        let (tx, rx) = mpsc::channel();
        let mut app = Self {
            cli,
            config_path,
            tx,
            rx,
            servers: Vec::new(),
            server_status: "等待刷新".to_owned(),
            config_status: String::new(),
            group_name: "我的服务器".to_owned(),
            server_address: String::new(),
            sourcebans_name: "SourceBans".to_owned(),
            sourcebans_url: String::new(),
            rcon_address: String::new(),
            rcon_password: String::new(),
            rcon_command_text: "status".to_owned(),
            rcon_output: String::new(),
            cvar_address: String::new(),
            cvar_password: String::new(),
            cvar_names: "hostname,sv_tags,mp_gamemode".to_owned(),
            cvar_output: String::new(),
        };
        app.config_status = format!("配置文件：{}", app.config_path.display());
        app.refresh_servers();
        app
    }

    fn handle_messages(&mut self, ctx: &egui::Context) {
        while let Ok(message) = self.rx.try_recv() {
            match message {
                GuiMessage::Servers(result) => match result {
                    Ok(rows) => {
                        self.server_status = format!("共 {} 个服务器", rows.len());
                        self.servers = rows;
                    }
                    Err(err) => self.server_status = format!("刷新失败：{err}"),
                },
                GuiMessage::AddServer(result) => match result {
                    Ok(()) => {
                        self.config_status = "服务器已保存".to_owned();
                        self.refresh_servers();
                    }
                    Err(err) => self.config_status = format!("保存服务器失败：{err}"),
                },
                GuiMessage::AddSourceBans(result) => match result {
                    Ok(()) => {
                        self.config_status = "SourceBans 订阅已保存".to_owned();
                        self.refresh_servers();
                    }
                    Err(err) => self.config_status = format!("保存订阅失败：{err}"),
                },
                GuiMessage::Rcon(result) => {
                    self.rcon_output = result.unwrap_or_else(|err| format!("RCON 失败：{err}"));
                }
                GuiMessage::Cvars(result) => {
                    self.cvar_output = match result {
                        Ok(payload) => format_cvar_payload(&payload),
                        Err(err) => format!("读取失败：{err}"),
                    };
                }
            }
            ctx.request_repaint();
        }
    }

    fn refresh_servers(&mut self) {
        self.server_status = "查询中...".to_owned();
        let tx = self.tx.clone();
        let cli = self.cli.clone();
        let config_path = self.config_path.clone();
        thread::spawn(move || {
            let result = load_config_or_default(&config_path)
                .and_then(|config| build_runtime(&cli, config))
                .and_then(|(settings, manual_groups, subscriptions)| {
                    load_server_rows(&settings, &manual_groups, &subscriptions)
                })
                .map(|rows| server_rows_payload(&rows));
            let _ = tx.send(GuiMessage::Servers(result));
        });
    }

    fn save_server(&mut self) {
        self.config_status = "保存服务器中...".to_owned();
        let tx = self.tx.clone();
        let path = self.config_path.clone();
        let input = AddServerRequest {
            group: self.group_name.clone(),
            server: self.server_address.clone(),
        };
        thread::spawn(move || {
            let result = add_server_to_config(&path, input);
            let _ = tx.send(GuiMessage::AddServer(result));
        });
    }

    fn save_sourcebans(&mut self) {
        self.config_status = "保存订阅中...".to_owned();
        let tx = self.tx.clone();
        let path = self.config_path.clone();
        let input = AddSourceBansRequest {
            name: self.sourcebans_name.clone(),
            url: self.sourcebans_url.clone(),
        };
        thread::spawn(move || {
            let result = add_sourcebans_to_config(&path, input);
            let _ = tx.send(GuiMessage::AddSourceBans(result));
        });
    }

    fn run_rcon(&mut self) {
        self.rcon_output = "执行中...".to_owned();
        let tx = self.tx.clone();
        let input = RconCommandRequest {
            address: self.rcon_address.clone(),
            password: self.rcon_password.clone(),
            command: self.rcon_command_text.clone(),
            timeout_ms: Some(2500),
        };
        thread::spawn(move || {
            let timeout = Duration::from_millis(input.timeout_ms.unwrap_or(2500).max(1));
            let result = rcon_command(&input.address, &input.password, &input.command, timeout);
            let _ = tx.send(GuiMessage::Rcon(result));
        });
    }

    fn read_cvars(&mut self) {
        self.cvar_output = "读取中...".to_owned();
        let tx = self.tx.clone();
        let names = self
            .cvar_names
            .split(',')
            .map(|name| name.trim().to_owned())
            .filter(|name| !name.is_empty())
            .collect::<Vec<_>>();
        let input = CvarRequest {
            address: self.cvar_address.clone(),
            password: if self.cvar_password.trim().is_empty() {
                None
            } else {
                Some(self.cvar_password.clone())
            },
            names: Some(names),
            timeout_ms: Some(2500),
        };
        thread::spawn(move || {
            let result = read_cvars(input);
            let _ = tx.send(GuiMessage::Cvars(result));
        });
    }
}

impl eframe::App for NativeGuiApp {
    fn update(&mut self, ctx: &egui::Context, _frame: &mut eframe::Frame) {
        self.handle_messages(ctx);

        egui::TopBottomPanel::top("top_bar").show(ctx, |ui| {
            ui.horizontal(|ui| {
                ui.heading("L4D2 刷服器");
                if ui.button("刷新服务器").clicked() {
                    self.refresh_servers();
                }
            });
            ui.label(&self.config_status);
        });

        egui::SidePanel::left("controls")
            .resizable(true)
            .default_width(360.0)
            .show(ctx, |ui| {
                egui::ScrollArea::vertical().show(ui, |ui| {
                    ui.heading("添加服务器");
                    ui.label("分组");
                    ui.text_edit_singleline(&mut self.group_name);
                    ui.label("服务器地址");
                    ui.text_edit_singleline(&mut self.server_address);
                    if ui.button("保存服务器").clicked() {
                        self.save_server();
                    }

                    ui.separator();
                    ui.heading("SourceBans 订阅");
                    ui.label("订阅名称");
                    ui.text_edit_singleline(&mut self.sourcebans_name);
                    ui.label("页面 URL");
                    ui.text_edit_singleline(&mut self.sourcebans_url);
                    if ui.button("保存订阅").clicked() {
                        self.save_sourcebans();
                    }

                    ui.separator();
                    ui.heading("RCON");
                    ui.label("服务器地址");
                    ui.text_edit_singleline(&mut self.rcon_address);
                    ui.label("RCON 密码");
                    ui.add(egui::TextEdit::singleline(&mut self.rcon_password).password(true));
                    ui.label("命令");
                    ui.text_edit_singleline(&mut self.rcon_command_text);
                    if ui.button("执行命令").clicked() {
                        self.run_rcon();
                    }
                    ui.add(
                        egui::TextEdit::multiline(&mut self.rcon_output)
                            .desired_rows(8)
                            .code_editor(),
                    );

                    ui.separator();
                    ui.heading("CVAR / Rules");
                    ui.label("服务器地址");
                    ui.text_edit_singleline(&mut self.cvar_address);
                    ui.label("RCON 密码，可空");
                    ui.add(egui::TextEdit::singleline(&mut self.cvar_password).password(true));
                    ui.label("CVAR 名称，逗号分隔；公开 rules 可留空");
                    ui.text_edit_singleline(&mut self.cvar_names);
                    if ui.button("读取").clicked() {
                        self.read_cvars();
                    }
                    ui.add(
                        egui::TextEdit::multiline(&mut self.cvar_output)
                            .desired_rows(8)
                            .code_editor(),
                    );
                });
            });

        egui::CentralPanel::default().show(ctx, |ui| {
            ui.horizontal(|ui| {
                ui.heading("服务器列表");
                ui.label(&self.server_status);
            });
            ui.separator();
            egui::ScrollArea::both()
                .auto_shrink([false, false])
                .show(ui, |ui| {
                    egui::Grid::new("servers_grid")
                        .striped(true)
                        .min_col_width(80.0)
                        .show(ui, |ui| {
                            ui.strong("分组");
                            ui.strong("地址");
                            ui.strong("延迟");
                            ui.strong("人数");
                            ui.strong("地图");
                            ui.strong("VAC");
                            ui.strong("服务器名 / 错误");
                            ui.end_row();

                            for row in &self.servers {
                                let (players, map, vac, name) = if let Some(info) = &row.info {
                                    (
                                        format!("{}/{}", info.players, info.max_players),
                                        info.map.clone(),
                                        if info.vac { "yes" } else { "no" }.to_owned(),
                                        info.name.clone(),
                                    )
                                } else {
                                    (
                                        "-".to_owned(),
                                        "-".to_owned(),
                                        "-".to_owned(),
                                        row.error
                                            .clone()
                                            .unwrap_or_else(|| "not queried".to_owned()),
                                    )
                                };
                                ui.label(row.groups.join(","));
                                ui.monospace(&row.address);
                                ui.label(
                                    row.ping_ms
                                        .map(|v| v.to_string())
                                        .unwrap_or_else(|| "-".to_owned()),
                                );
                                ui.label(players);
                                ui.label(map);
                                ui.label(vac);
                                ui.label(name);
                                ui.end_row();
                            }
                        });
                });
        });
    }
}

fn format_cvar_payload(payload: &CvarPayload) -> String {
    let mut output = payload.source.clone();
    for (name, value) in &payload.values {
        output.push('\n');
        output.push_str(name);
        output.push_str(" = ");
        output.push_str(value);
    }
    output
}

fn add_server_to_config(path: &PathBuf, input: AddServerRequest) -> Result<(), String> {
    let group_name = non_empty(input.group.trim().to_owned(), "group")?;
    let server = normalize_endpoint_input(&input.server)?;
    let mut config = load_config_or_default(path)?;

    if let Some(group) = config
        .groups
        .iter_mut()
        .find(|group| group.name == group_name)
    {
        if !group.servers.iter().any(|existing| existing == &server) {
            group.servers.push(server);
        }
    } else {
        config.groups.push(FileGroup {
            name: group_name,
            servers: vec![server],
        });
    }

    save_config(path, &config)
}

fn add_sourcebans_to_config(path: &PathBuf, input: AddSourceBansRequest) -> Result<(), String> {
    let name = non_empty(input.name.trim().to_owned(), "name")?;
    let url = normalize_sourcebans_url(&input.url)?.to_string();
    let mut config = load_config_or_default(path)?;

    if let Some(subscription) = config
        .sourcebans
        .iter_mut()
        .find(|subscription| subscription.name == name)
    {
        subscription.url = url;
    } else {
        config.sourcebans.push(FileSourceBans { name, url });
    }

    save_config(path, &config)
}

fn server_rows_payload(rows: &[ServerRow]) -> Vec<ServerRowPayload> {
    rows.iter()
        .map(|row| ServerRowPayload {
            address: row.endpoint.display.clone(),
            socket: row.endpoint.socket.to_string(),
            groups: row.endpoint.groups.clone(),
            ping_ms: row.ping.map(|ping| ping.as_millis() as u64),
            info: row.info.clone(),
            error: row.error.clone(),
        })
        .collect()
}

#[derive(Debug)]
struct RconPacket {
    id: i32,
    kind: i32,
    body: String,
}

fn rcon_command(
    address: &str,
    password: &str,
    command: &str,
    timeout: Duration,
) -> Result<String, String> {
    let password = non_empty(password.trim().to_owned(), "rcon password")?;
    let command = non_empty(command.trim().to_owned(), "rcon command")?;
    let endpoint = resolve_endpoint(address)?;
    let socket = SocketAddr::V4(endpoint.socket);
    let mut stream = TcpStream::connect_timeout(&socket, timeout)
        .map_err(|err| format!("failed to connect RCON {}: {err}", endpoint.display))?;
    stream
        .set_read_timeout(Some(timeout))
        .map_err(|err| err.to_string())?;
    stream
        .set_write_timeout(Some(timeout))
        .map_err(|err| err.to_string())?;

    write_rcon_packet(&mut stream, 1, 3, &password)?;
    let mut authed = false;
    for _ in 0..8 {
        let packet = read_rcon_packet(&mut stream)?;
        if packet.id == -1 {
            return Err("RCON auth failed".to_owned());
        }
        if packet.id == 1 && packet.kind == 2 {
            authed = true;
            break;
        }
    }
    if !authed {
        return Err("RCON auth response timed out".to_owned());
    }

    write_rcon_packet(&mut stream, 2, 2, &command)?;
    write_rcon_packet(&mut stream, 3, 0, "")?;

    let mut output = String::new();
    for _ in 0..64 {
        match read_rcon_packet(&mut stream) {
            Ok(packet) if packet.id == 3 => break,
            Ok(packet) if packet.id == 2 => output.push_str(&packet.body),
            Ok(packet) if packet.id == -1 => return Err("RCON command rejected".to_owned()),
            Ok(packet) => output.push_str(&packet.body),
            Err(err) if !output.is_empty() => {
                output.push_str(&format!("\n[read stopped: {err}]"));
                break;
            }
            Err(err) => return Err(err),
        }
    }

    Ok(output)
}

fn write_rcon_packet(stream: &mut TcpStream, id: i32, kind: i32, body: &str) -> Result<(), String> {
    let size = 4 + 4 + body.len() + 2;
    if size > i32::MAX as usize {
        return Err("RCON packet too large".to_owned());
    }

    stream
        .write_all(&(size as i32).to_le_bytes())
        .and_then(|_| stream.write_all(&id.to_le_bytes()))
        .and_then(|_| stream.write_all(&kind.to_le_bytes()))
        .and_then(|_| stream.write_all(body.as_bytes()))
        .and_then(|_| stream.write_all(&[0, 0]))
        .map_err(|err| err.to_string())
}

fn read_rcon_packet(stream: &mut TcpStream) -> Result<RconPacket, String> {
    let mut size_buf = [0u8; 4];
    stream
        .read_exact(&mut size_buf)
        .map_err(|err| err.to_string())?;
    let size = i32::from_le_bytes(size_buf);
    if !(10..=1_048_576).contains(&size) {
        return Err(format!("invalid RCON packet size: {size}"));
    }

    let mut payload = vec![0u8; size as usize];
    stream
        .read_exact(&mut payload)
        .map_err(|err| err.to_string())?;
    let id = i32::from_le_bytes([payload[0], payload[1], payload[2], payload[3]]);
    let kind = i32::from_le_bytes([payload[4], payload[5], payload[6], payload[7]]);
    let body_end = payload.len().saturating_sub(2);
    let body = String::from_utf8_lossy(&payload[8..body_end]).into_owned();
    Ok(RconPacket { id, kind, body })
}

fn read_cvars(input: CvarRequest) -> Result<CvarPayload, String> {
    let timeout = Duration::from_millis(input.timeout_ms.unwrap_or(2500).max(1));
    let names = input
        .names
        .unwrap_or_default()
        .into_iter()
        .map(|name| name.trim().to_owned())
        .filter(|name| !name.is_empty())
        .collect::<Vec<_>>();

    if let Some(password) = input
        .password
        .filter(|password| !password.trim().is_empty())
    {
        if names.is_empty() {
            return Err("RCON CVAR read requires at least one cvar name".to_owned());
        }

        let mut values = BTreeMap::new();
        for name in names {
            let output = rcon_command(&input.address, &password, &name, timeout)?;
            values.insert(name, output);
        }
        return Ok(CvarPayload {
            source: "rcon".to_owned(),
            values,
        });
    }

    let endpoint = resolve_endpoint(&input.address)?;
    let mut values = query_server_rules(endpoint.socket, timeout)?;
    if !names.is_empty() {
        let wanted = names
            .into_iter()
            .map(|name| name.to_lowercase())
            .collect::<HashSet<_>>();
        values.retain(|name, _| wanted.contains(&name.to_lowercase()));
    }

    Ok(CvarPayload {
        source: "a2s_rules".to_owned(),
        values,
    })
}

fn query_server_rules(
    addr: SocketAddrV4,
    timeout: Duration,
) -> Result<BTreeMap<String, String>, String> {
    let socket = UdpSocket::bind("0.0.0.0:0").map_err(|err| err.to_string())?;
    socket
        .set_read_timeout(Some(timeout))
        .map_err(|err| err.to_string())?;
    socket
        .set_write_timeout(Some(timeout))
        .map_err(|err| err.to_string())?;
    socket
        .connect(SocketAddr::V4(addr))
        .map_err(|err| err.to_string())?;

    socket
        .send(&build_a2s_rules_request([0xFF, 0xFF, 0xFF, 0xFF]))
        .map_err(|err| err.to_string())?;
    let mut buf = [0u8; 8192];
    let size = socket.recv(&mut buf).map_err(|err| err.to_string())?;
    let packet = &buf[..size];

    if let Some(challenge) = parse_challenge(packet) {
        socket
            .send(&build_a2s_rules_request(challenge))
            .map_err(|err| err.to_string())?;
        let size = socket.recv(&mut buf).map_err(|err| err.to_string())?;
        return parse_rules_response(&buf[..size]);
    }

    parse_rules_response(packet)
}

fn build_a2s_rules_request(challenge: [u8; 4]) -> Vec<u8> {
    let mut request = Vec::from(&b"\xFF\xFF\xFF\xFFV"[..]);
    request.extend_from_slice(&challenge);
    request
}

fn parse_rules_response(packet: &[u8]) -> Result<BTreeMap<String, String>, String> {
    if packet.len() >= 4 && packet.starts_with(&[0xFE, 0xFF, 0xFF, 0xFF]) {
        return Err("split A2S_RULES response is not supported".to_owned());
    }
    if packet.len() < 7 || !packet.starts_with(&[0xFF, 0xFF, 0xFF, 0xFF]) || packet[4] != 0x45 {
        return Err("invalid A2S_RULES response".to_owned());
    }

    let mut reader = PacketReader::new(&packet[5..]);
    let count = reader.u16_le()? as usize;
    let mut values = BTreeMap::new();
    for _ in 0..count {
        if reader.remaining() == 0 {
            break;
        }
        let name = reader.string()?;
        let value = reader.string()?;
        values.insert(name, value);
    }

    Ok(values)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_master_response() {
        let packet = [
            0xFF, 0xFF, 0xFF, 0xFF, 0x66, 0x0A, 1, 2, 3, 4, 0x69, 0x87, 0, 0, 0, 0, 0, 0,
        ];

        let addrs = parse_master_response(&packet).expect("valid master response");
        assert_eq!(
            addrs,
            vec![SocketAddrV4::new(Ipv4Addr::new(1, 2, 3, 4), 27015)]
        );
    }

    #[test]
    fn parses_a2s_info_response() {
        let mut packet = Vec::new();
        packet.extend_from_slice(&[0xFF, 0xFF, 0xFF, 0xFF, 0x49, 17]);
        packet.extend_from_slice(b"Anne Test\0");
        packet.extend_from_slice(b"c2m1_highway\0");
        packet.extend_from_slice(b"left4dead2\0");
        packet.extend_from_slice(b"Left 4 Dead 2\0");
        packet.extend_from_slice(&550u16.to_le_bytes());
        packet.extend_from_slice(&[8, 8, 0, b'd', b'l', 0, 1]);
        packet.extend_from_slice(b"2.2.4.6\0");
        packet.push(0xA0);
        packet.extend_from_slice(&27015u16.to_le_bytes());
        packet.extend_from_slice(b"anne,confogl\0");

        let info = parse_server_info(&packet).expect("valid A2S_INFO response");
        assert_eq!(info.protocol, 17);
        assert_eq!(info.name, "Anne Test");
        assert_eq!(info.map, "c2m1_highway");
        assert_eq!(info.app_id, 550);
        assert_eq!(info.players, 8);
        assert_eq!(info.max_players, 8);
        assert!(info.vac);
        assert_eq!(info.port, Some(27015));
        assert_eq!(info.keywords.as_deref(), Some("anne,confogl"));
    }

    #[test]
    fn extracts_sourcebans_addresses() {
        let html = r#"
            <a href="steam://connect/51.79.176.131:27015">connect</a>
            <td>51.79.176.131:27025</td>
            <a href='steam://connect/example.org:27015/password'>host</a>
            <td>coop.l4d2zone.pl:27015</td>
        "#;

        let addresses = extract_sourcebans_addresses(html).expect("addresses");
        assert!(addresses.contains(&"51.79.176.131:27015".to_owned()));
        assert!(addresses.contains(&"51.79.176.131:27025".to_owned()));
        assert!(addresses.contains(&"example.org:27015".to_owned()));
        assert!(addresses.contains(&"coop.l4d2zone.pl:27015".to_owned()));
    }

    #[test]
    fn normalizes_sourcebans_root_url() {
        let url = normalize_sourcebans_url("https://example.com/sourcebans").expect("url");
        assert_eq!(
            url.as_str(),
            "https://example.com/sourcebans/index.php?p=servers"
        );
    }

    #[test]
    fn parses_rules_response() {
        let mut packet = Vec::new();
        packet.extend_from_slice(&[0xFF, 0xFF, 0xFF, 0xFF, 0x45]);
        packet.extend_from_slice(&2u16.to_le_bytes());
        packet.extend_from_slice(b"hostname\0Anne Server\0");
        packet.extend_from_slice(b"sv_tags\0confogl,anne\0");

        let rules = parse_rules_response(&packet).expect("valid rules");
        assert_eq!(
            rules.get("hostname").map(String::as_str),
            Some("Anne Server")
        );
        assert_eq!(
            rules.get("sv_tags").map(String::as_str),
            Some("confogl,anne")
        );
    }
}
