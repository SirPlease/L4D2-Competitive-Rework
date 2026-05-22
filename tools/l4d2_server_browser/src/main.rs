use clap::{Parser, ValueEnum};
use regex::Regex;
use reqwest::blocking::Client;
use serde::{Deserialize, Serialize};
use std::collections::{BTreeSet, HashMap, HashSet, VecDeque};
use std::fs;
use std::io;
use std::net::{Ipv4Addr, SocketAddr, SocketAddrV4, ToSocketAddrs, UdpSocket};
use std::path::PathBuf;
use std::sync::{Arc, Mutex};
use std::thread;
use std::time::{Duration, Instant};

const DEFAULT_MASTER: &str = "hl2master.steampowered.com:27011";
const DEFAULT_FILTER: &str = "\\appid\\550";
const DEFAULT_MASTER_GROUP: &str = "Steam Master";
const USER_AGENT: &str = "l4d2-server-browser/0.2";

fn main() {
    if let Err(err) = run() {
        eprintln!("error: {err}");
        std::process::exit(1);
    }
}

fn run() -> Result<(), String> {
    let cli = Cli::parse();
    let loaded_config = load_config(cli.config.as_ref())?;
    let mut settings = RuntimeSettings::default();
    let mut manual_groups = Vec::new();
    let mut subscriptions = Vec::new();

    if let Some(config) = loaded_config {
        settings.apply_file_master(config.master)?;
        manual_groups.extend(config.groups.into_iter().map(ManualGroup::try_from).collect::<Result<Vec<_>, _>>()?);
        subscriptions.extend(
            config
                .sourcebans
                .into_iter()
                .map(SourceBansSubscription::try_from)
                .collect::<Result<Vec<_>, _>>()?,
        );
    }

    settings.apply_cli(&cli)?;
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

    let registry = collect_sources(&settings, &manual_groups, &subscriptions)?;
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

    rows = apply_filters(rows, &settings);
    sort_rows(&mut rows, settings.sort);

    if settings.json {
        print_json(&rows)?;
    } else {
        print_table(&rows);
    }

    Ok(())
}

#[derive(Parser, Debug)]
#[command(name = "l4d2-server-browser")]
#[command(about = "Left 4 Dead 2 server browser with groups and SourceBans subscriptions.")]
struct Cli {
    #[arg(long)]
    config: Option<PathBuf>,

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

#[derive(Debug, Deserialize, Default)]
struct BrowserConfig {
    #[serde(default)]
    master: Option<FileMaster>,
    #[serde(default)]
    groups: Vec<FileGroup>,
    #[serde(default)]
    sourcebans: Vec<FileSourceBans>,
}

#[derive(Debug, Deserialize, Default)]
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

#[derive(Debug, Deserialize)]
struct FileGroup {
    name: String,
    servers: Vec<String>,
}

#[derive(Debug, Deserialize)]
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
            Err(err) => eprintln!("warning: SourceBans subscription {} failed: {err}", subscription.url),
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

fn add_endpoint(registry: &mut HashMap<SocketAddrV4, RegistryEntry>, endpoint: Endpoint, group: &str) {
    let entry = registry.entry(endpoint.socket).or_insert_with(|| RegistryEntry {
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
    let offset = if packet.len() >= 6 && packet.starts_with(&[0xFF, 0xFF, 0xFF, 0xFF]) && packet[4] == 0x66 {
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
    let mut url = reqwest::Url::parse(&parse_input).map_err(|err| format!("invalid URL {input}: {err}"))?;
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
    let connect_re = Regex::new(r#"(?i)steam://connect/([^"'<>\s]+)"#).map_err(|err| err.to_string())?;
    let ip_re = Regex::new(
        r#"\b((?:(?:25[0-5]|2[0-4]\d|1?\d?\d)\.){3}(?:25[0-5]|2[0-4]\d|1?\d?\d)):(\d{2,5})\b"#,
    )
    .map_err(|err| err.to_string())?;
    let host_re = Regex::new(r#"\b([A-Za-z0-9][A-Za-z0-9.-]*\.[A-Za-z]{2,})(?::)(\d{2,5})\b"#)
        .map_err(|err| err.to_string())?;

    let mut seen = BTreeSet::new();
    for capture in connect_re.captures_iter(&body) {
        if let Some(raw) = capture.get(1) {
            let address = raw.as_str().split('/').next().unwrap_or(raw.as_str()).to_owned();
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
    let socket = resolve_ipv4(&address).map_err(|err| format!("failed to resolve {address}: {err}"))?;

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

fn query_server_info(addr: SocketAddrV4, timeout: Duration) -> Result<(ServerInfo, Duration), String> {
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

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_master_response() {
        let packet = [
            0xFF, 0xFF, 0xFF, 0xFF, 0x66, 0x0A, 1, 2, 3, 4, 0x69, 0x87, 0, 0, 0, 0, 0, 0,
        ];

        let addrs = parse_master_response(&packet).expect("valid master response");
        assert_eq!(addrs, vec![SocketAddrV4::new(Ipv4Addr::new(1, 2, 3, 4), 27015)]);
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
        assert_eq!(url.as_str(), "https://example.com/sourcebans/index.php?p=servers");
    }
}
