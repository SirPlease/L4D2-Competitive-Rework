import { initI18n, setLocale, t } from './i18n.js';

const tauriInvoke = window.__TAURI__?.core?.invoke;

const state = {
  tab: "servers",
  configPath: "",
  lists: null,
  rows: [],
  group: null,
  search: "",
  onlyWithPlayers: false,
  hideTimeout: true,
  selectedSourcebans: null,
  busy: false,
  apiToken: null,
  apiBaseUrl: "",
  steamUser: null,
  inspectorOpen: false,
  selectedAddress: null,
  selectedSocket: null,
  inspectorTab: "players",
  sortKey: "players",
  sortDesc: true,
  autoRefreshTimer: null
};

const $ = (selector) => document.querySelector(selector);
const $$ = (selector) => Array.from(document.querySelectorAll(selector));

async function invoke(command, args = {}) {
  if (tauriInvoke) {
    return tauriInvoke(command, args);
  }
  // No mock fallback for all new commands to keep it clean.
  return Promise.resolve(null);
}

function summarizeRows(rows) {
  const groups = new Map();
  let online = 0;
  let players = 0;
  for (const row of rows) {
    if (!row.error) online += 1;
    players += row.players;
    for (const group of row.groups) {
      groups.set(group, (groups.get(group) ?? 0) + 1);
    }
  }
  return {
    total: rows.length,
    online,
    players,
    groups: Array.from(groups.entries()),
  };
}

function setBusy(value, labelKey = "btnRefresh") {
  state.busy = value;
  $("#refreshBtn").disabled = value;
  $("#refreshBtn").textContent = value ? t("statusRefreshing") : t(labelKey);
}

function setStatus(message) {
  $("#statusLine").textContent = message;
}

function compactPath(path) {
  if (!path) return t("configNotSet");
  if (path.length <= 44) return path;
  return `${path.slice(0, 18)}...${path.slice(-22)}`;
}

function setTab(tab) {
  state.tab = tab;
  $$(".nav-item").forEach((button) => {
    button.classList.toggle("active", button.dataset.tab === tab);
  });
  $$(".view").forEach(v => v.classList.remove("active"));
  $(`#${tab}View`).classList.add("active");
  
  const titleMap = {
    servers: "navServers",
    globalPlayers: "navGlobalPlayers",
    broadcast: "navBroadcast",
    subscriptions: "navSubscriptions",
    settings: "navSettings"
  };
  $("#viewTitle").textContent = t(titleMap[tab]);
  $("#refreshBtn").style.display = (tab === "servers" || tab === "globalPlayers" || tab === "broadcast") ? "" : "none";

  if (tab === "globalPlayers") loadGlobalPlayers();
  if (tab === "broadcast") loadBroadcastHistory();
}

async function loadConfigLists() {
  try {
    state.lists = await invoke("load_config_lists", { path: state.configPath || null });
    state.configPath = state.lists.config_path;
    state.apiBaseUrl = state.lists.api_base_url;
    $("#configPath").textContent = compactPath(state.configPath);
    $("#apiBaseUrlInput").value = state.apiBaseUrl;
    renderSubscriptions();
    renderManualServers();
    
    // Attempt API Me if we have a token stored locally for now.
    const savedToken = localStorage.getItem("apiToken");
    if (savedToken && state.apiBaseUrl) {
      state.apiToken = savedToken;
      try {
        const user = await invoke("api_me", { baseUrl: state.apiBaseUrl, token: state.apiToken });
        state.steamUser = user;
        updateSteamUserUI();
      } catch (err) {
        state.apiToken = null;
        localStorage.removeItem("apiToken");
        updateSteamUserUI();
      }
    }
  } catch (err) {
    console.error(err);
  }
}

async function refreshServers() {
  if (state.tab !== "servers") return;
  setBusy(true);
  setStatus(t("statusRefreshing"));
  try {
    const payload = await invoke("refresh_servers", {
      query: {
        config_path: state.configPath || null,
        search: state.search,
        group: state.group || null,
        only_with_players: state.onlyWithPlayers,
        hide_timeout: state.hideTimeout,
        limit: 300,
      },
    });
    if (!payload) return; // For mock safety
    state.configPath = payload.config_path;
    state.rows = payload.rows;
    // apply basic client-side sorting since we didn't pass sort arguments
    sortRowsClientSide();
    renderMetrics(payload.summary);
    renderGroups(payload.summary.groups);
    renderServerRows();
    setStatus(`${t("navServers")} : ${payload.rows.length}`);
  } catch (error) {
    setStatus(`Error: ${error}`);
  } finally {
    setBusy(false);
  }
}

function sortRowsClientSide() {
  state.rows.sort((a, b) => {
    let cmp = 0;
    if (state.sortKey === "name") cmp = a.name.localeCompare(b.name);
    else if (state.sortKey === "address") cmp = a.address.localeCompare(b.address);
    else if (state.sortKey === "players") cmp = (a.players || 0) - (b.players || 0);
    else if (state.sortKey === "ping") cmp = (a.ping_ms || 9999) - (b.ping_ms || 9999);
    else if (state.sortKey === "map") cmp = a.map.localeCompare(b.map);
    else if (state.sortKey === "group") cmp = a.group_label.localeCompare(b.group_label);
    
    return state.sortDesc ? -cmp : cmp;
  });
}

function handleSortClick(key) {
  if (state.sortKey === key) {
    state.sortDesc = !state.sortDesc;
  } else {
    state.sortKey = key;
    state.sortDesc = (key === "players");
  }
  sortRowsClientSide();
  renderServerRows();
}

function renderMetrics(summary) {
  $("#metricTotal").textContent = summary.total;
  $("#metricOnline").textContent = summary.online;
  $("#metricPlayers").textContent = summary.players;
}

function renderGroups(groups) {
  const root = $("#groupTabs");
  root.replaceChildren();
  const all = document.createElement("button");
  all.type = "button";
  all.className = `group-chip ${!state.group ? "active" : ""}`;
  all.textContent = t("allServers");
  all.addEventListener("click", () => {
    state.group = null;
    refreshServers();
  });
  root.append(all);

  for (const [name, count] of groups) {
    const button = document.createElement("button");
    button.type = "button";
    button.className = `group-chip ${state.group === name ? "active" : ""}`;
    button.textContent = `${name} ${count}`;
    button.addEventListener("click", () => {
      state.group = name;
      refreshServers();
    });
    root.append(button);
  }
}

function renderServerRows() {
  const tbody = $("#serverRows");
  tbody.replaceChildren();
  if (state.rows.length === 0) {
    const row = document.createElement("tr");
    const cell = document.createElement("td");
    cell.colSpan = 7;
    cell.className = "empty";
    cell.textContent = t("noServers");
    row.append(cell);
    tbody.append(row);
    return;
  }

  for (const server of state.rows) {
    const row = document.createElement("tr");
    if (state.selectedAddress === server.address) {
      row.classList.add("selected");
    }

    const nameCell = document.createElement("td");
    const name = document.createElement("span");
    name.className = "server-name";
    name.title = server.name;
    name.textContent = server.name;
    const status = document.createElement("span");
    status.className = `server-status ${
      server.error ? "timeout" : server.players > 0 ? "" : "empty"
    }`;
    status.textContent = server.error ? t("statusTimeout") : server.players > 0 ? t("statusActive") : t("statusEmpty");
    nameCell.append(name, status);

    const addressCell = document.createElement("td");
    addressCell.className = "mono";
    addressCell.textContent = server.address;

    const playersCell = document.createElement("td");
    playersCell.textContent = `${server.players}/${server.max_players}`;

    const pingCell = document.createElement("td");
    pingCell.textContent = server.ping_ms === null ? "-" : `${server.ping_ms}ms`;

    const mapCell = document.createElement("td");
    mapCell.textContent = server.map || "-";

    const groupCell = document.createElement("td");
    groupCell.textContent = server.group_label || "-";

    const actionCell = document.createElement("td");
    const connect = document.createElement("button");
    connect.type = "button";
    connect.textContent = t("btnConnect");
    connect.addEventListener("click", (e) => {
      e.stopPropagation();
      openSteam(server.socket);
    });
    actionCell.append(connect);

    row.append(
      nameCell,
      addressCell,
      playersCell,
      pingCell,
      mapCell,
      groupCell,
      actionCell,
    );

    row.addEventListener("click", () => {
      state.selectedAddress = server.address;
      state.selectedSocket = server.socket;
      openInspector(server.name, server.address);
      renderServerRows(); // re-render to update selected class
    });

    tbody.append(row);
  }
}

// ----- Inspector Logic -----

function openInspector(name, address) {
  state.inspectorOpen = true;
  $("#inspectorPanel").style.display = "flex";
  $("#inspectorTitle").textContent = name;
  refreshInspector();
}

function closeInspector() {
  state.inspectorOpen = false;
  state.selectedAddress = null;
  state.selectedSocket = null;
  $("#inspectorPanel").style.display = "none";
  renderServerRows();
}

function setInspectorTab(tab) {
  state.inspectorTab = tab;
  $$(".ins-tab").forEach(b => b.classList.toggle("active", b.dataset.ins === tab));
  $$(".ins-view").forEach(v => v.classList.remove("active"));
  $(`#ins${tab.charAt(0).toUpperCase() + tab.slice(1)}`).classList.add("active");
  refreshInspector();
}

async function refreshInspector() {
  if (!state.inspectorOpen || !state.selectedAddress) return;
  const address = state.selectedAddress;
  
  if (state.inspectorTab === "players") {
    try {
      const players = await invoke("query_players", { configPath: state.configPath, address });
      const tbody = $("#insPlayersRows");
      tbody.replaceChildren();
      for (const p of players) {
        const tr = document.createElement("tr");
        tr.innerHTML = `<td>${p.name}</td><td>${p.score}</td><td>${(p.duration_secs / 60).toFixed(0)}m</td>`;
        tbody.append(tr);
      }
    } catch (e) {
      console.error(e);
    }
  } else if (state.inspectorTab === "cvar") {
    try {
      const cvars = await invoke("read_cvars", { req: { config_path: state.configPath, address, password: null, names: null, timeout_ms: 2500 }});
      const tbody = $("#insCvarRows");
      tbody.replaceChildren();
      for (const c of cvars) {
        const tr = document.createElement("tr");
        tr.innerHTML = `<td>${c.name}</td><td>${c.value}</td>`;
        tbody.append(tr);
      }
    } catch (e) {
      console.error(e);
    }
  } else if (state.inspectorTab === "network") {
    try {
      // Assuming socket address is 'ip:port'
      const ip = state.selectedSocket ? state.selectedSocket.split(":")[0] : address.split(":")[0];
      const net = await invoke("fetch_network_info", { address, ip });
      $("#netIp").textContent = net.ip;
      $("#netCountry").textContent = `${net.country} - ${net.region}`;
      $("#netIsp").textContent = net.isp;
    } catch (e) {
      console.error(e);
    }
  }
}

async function sendRcon() {
  const password = $("#rconPassword").value;
  const command = $("#rconCommand").value;
  if (!password || !command || !state.selectedAddress) return;
  
  const term = $("#rconTerminal");
  term.textContent += `\n> ${command}\n`;
  try {
    const res = await invoke("run_rcon", { req: {
      config_path: state.configPath,
      address: state.selectedAddress,
      password,
      command,
      timeout_ms: 5000
    }});
    term.textContent += res + "\n";
  } catch (e) {
    term.textContent += `Error: ${e}\n`;
  }
  term.scrollTop = term.scrollHeight;
  $("#rconCommand").value = "";
}


// ----- Subscriptions & Manual Servers -----

function renderSubscriptions() {
  const list = $("#subscriptionList");
  list.replaceChildren();
  const items = state.lists?.sourcebans ?? [];
  if (items.length === 0) {
    const empty = document.createElement("div");
    empty.className = "empty";
    empty.textContent = t("noSubscriptions");
    list.append(empty);
    return;
  }
  for (const item of items) {
    const button = document.createElement("button");
    button.type = "button";
    button.className = `subscription-item ${
      state.selectedSourcebans === item.index ? "active" : ""
    }`;
    const title = document.createElement("strong");
    title.textContent = item.name;
    const detail = document.createElement("span");
    detail.textContent = item.source_label;
    button.append(title, detail);
    button.addEventListener("click", () => selectSubscription(item));
    list.append(button);
  }
}

function renderManualServers() {
  const list = $("#manualList");
  list.replaceChildren();
  const items = state.lists?.manual_servers ?? [];
  if (items.length === 0) {
    const empty = document.createElement("div");
    empty.className = "empty";
    empty.textContent = t("noManualServers");
    list.append(empty);
    return;
  }
  for (const item of items) {
    const row = document.createElement("div");
    row.className = "manual-item";
    
    const info = document.createElement("div");
    const title = document.createElement("strong");
    title.textContent = item.server;
    const detail = document.createElement("span");
    detail.textContent = item.group;
    info.append(title, detail);
    
    const delBtn = document.createElement("button");
    delBtn.className = "danger";
    delBtn.textContent = t("btnDelete");
    delBtn.addEventListener("click", async () => {
      try {
        state.lists = await invoke("delete_manual_server", { req: {
          config_path: state.configPath,
          group: item.group,
          server: item.server
        }});
        renderManualServers();
        refreshServers();
      } catch (e) {
        setStatus(`${t("deleteFailed")}: ${e}`);
      }
    });
    
    row.style.display = "flex";
    row.style.justifyContent = "space-between";
    row.style.alignItems = "center";
    
    row.append(info, delBtn);
    list.append(row);
  }
}

function selectSubscription(item) {
  state.selectedSourcebans = item.index;
  $("#subscriptionEditorTitle").textContent = t("editSubscription");
  $("#subscriptionNameInput").value = item.name;
  $("#subscriptionUrlInput").value = item.url;
  $("#subscriptionTextInput").value = "";
  $("#deleteSubscriptionBtn").disabled = false;
  renderSubscriptions();
}

function clearSubscriptionEditor() {
  state.selectedSourcebans = null;
  $("#subscriptionEditorTitle").textContent = t("newSubscription");
  $("#subscriptionNameInput").value = t("defaultGroup");
  $("#subscriptionUrlInput").value = "";
  $("#subscriptionTextInput").value = "";
  $("#deleteSubscriptionBtn").disabled = true;
  renderSubscriptions();
}

async function saveSubscription() {
  const input = {
    config_path: state.configPath || null,
    index: state.selectedSourcebans,
    name: $("#subscriptionNameInput").value.trim(),
    url: $("#subscriptionUrlInput").value.trim(),
    text: $("#subscriptionTextInput").value,
  };
  if (!input.name) return;
  try {
    state.lists = await invoke("save_sourcebans", { input });
    state.configPath = state.lists.config_path;
    $("#subscriptionTextInput").value = "";
    renderSubscriptions();
    setStatus(t("statusSaved"));
    refreshServers();
  } catch (error) {
    setStatus(`${t("saveFailed")}: ${error}`);
  }
}

async function deleteSubscription() {
  if (state.selectedSourcebans === null) return;
  try {
    state.lists = await invoke("delete_sourcebans", {
      path: state.configPath || null,
      index: state.selectedSourcebans,
    });
    clearSubscriptionEditor();
    renderSubscriptions();
    setStatus(t("statusDeleted"));
    refreshServers();
  } catch (error) {
    setStatus(`${t("deleteFailed")}: ${error}`);
  }
}

async function addManualServer() {
  const group = $("#manualGroupInput").value.trim();
  const server = $("#manualServerInput").value.trim();
  if (!group || !server) return;
  try {
    state.lists = await invoke("add_manual_server", {
      path: state.configPath || null,
      group,
      server,
    });
    $("#manualServerInput").value = "";
    renderManualServers();
    setStatus(t("statusAdded"));
    refreshServers();
  } catch (error) {
    setStatus(`${t("addFailed")}: ${error}`);
  }
}

// ----- Steam Auth & API -----

async function startSteamLogin() {
  const baseUrl = $("#apiBaseUrlInput").value.trim();
  if (!baseUrl) return;
  state.apiBaseUrl = baseUrl;
  
  try {
    const start = await invoke("steam_login_start", { baseUrl });
    $("#steamLoginModal").style.display = "block";
    $("#steamLoginUrl").href = start.verification_url;
    $("#steamLoginUrl").textContent = start.verification_url;
    $("#steamLoginCode").textContent = start.user_code;
    
    pollSteamLogin(baseUrl, start.device_code, start.expires_in, start.interval);
  } catch (e) {
    $("#apiStatusMessage").textContent = `${t("loginStartFailed")}: ${e}`;
  }
}

async function pollSteamLogin(baseUrl, deviceCode, expires, interval) {
  const endTime = Date.now() + (expires * 1000);
  
  while (Date.now() < endTime) {
    await new Promise(r => setTimeout(r, interval * 1000));
    if ($("#steamLoginModal").style.display === "none") break; // Cancelled
    
    try {
      const res = await invoke("steam_login_poll", { req: { base_url: baseUrl, device_code: deviceCode }});
      if (res) { // Success
        state.apiToken = res.token;
        state.steamUser = {
          steam_id: res.steam_id,
          steam_name: res.steam_name,
          avatar: res.avatar,
          is_admin: res.is_admin
        };
        localStorage.setItem("apiToken", res.token);
        $("#steamLoginModal").style.display = "none";
        updateSteamUserUI();
        
        await invoke("save_api_config", { req: { config_path: state.configPath, base_url: baseUrl, token: res.token } });
        return;
      }
    } catch (e) {
      $("#apiStatusMessage").textContent = `${t("pollFailed")}: ${e}`;
      break;
    }
  }
  $("#steamLoginModal").style.display = "none";
}

async function logoutApi() {
  if (!state.apiToken) return;
  try {
    await invoke("api_logout", { baseUrl: state.apiBaseUrl, token: state.apiToken });
  } catch (e) {} // ignore
  
  state.apiToken = null;
  state.steamUser = null;
  localStorage.removeItem("apiToken");
  await invoke("save_api_config", { req: { config_path: state.configPath, base_url: state.apiBaseUrl, token: null } });
  updateSteamUserUI();
}

function updateSteamUserUI() {
  if (state.steamUser) {
    $("#steamUserInfo").style.display = "flex";
    $("#steamAvatar").src = state.steamUser.avatar;
    $("#steamName").textContent = state.steamUser.steam_name;
    $("#steamLoginBtn").style.display = "none";
    $("#steamLogoutBtn").style.display = "inline-block";
    $("#apiStatusMessage").textContent = t("loggedIn");
  } else {
    $("#steamUserInfo").style.display = "none";
    $("#steamLoginBtn").style.display = "inline-block";
    $("#steamLogoutBtn").style.display = "none";
    $("#apiStatusMessage").textContent = "";
  }
}

// ----- Global Players -----

async function loadGlobalPlayers() {
  if (!state.apiToken) {
    $("#globalPlayerRows").innerHTML = `<tr><td colspan="5" class="empty">${t("loginRequired")}</td></tr>`;
    return;
  }
  try {
    const players = await invoke("load_global_players", { baseUrl: state.apiBaseUrl, token: state.apiToken, configPath: state.configPath });
    const tbody = $("#globalPlayerRows");
    tbody.replaceChildren();
    for (const p of players) {
      const tr = document.createElement("tr");
      tr.innerHTML = `
        <td>${p.name}</td>
        <td>${p.server_name}</td>
        <td>${p.score}</td>
        <td>${(p.duration_secs / 60).toFixed(0)}m</td>
        <td>${p.points ?? '-'}</td>
      `;
      tbody.append(tr);
    }
  } catch (e) {
    $("#globalPlayerRows").innerHTML = `<tr><td colspan="5" class="empty">${e}</td></tr>`;
  }
}

// ----- Broadcast -----

async function sendBroadcastMessage() {
  const msg = $("#broadcastInput").value.trim();
  if (!msg || !state.apiToken) return;
  try {
    const res = await invoke("send_broadcast", { req: { base_url: state.apiBaseUrl, token: state.apiToken, message: msg } });
    $("#broadcastInput").value = "";
    setStatus(res);
    loadBroadcastHistory();
  } catch (e) {
    setStatus(`${t("saveFailed")}: ${e}`);
  }
}

async function loadBroadcastHistory() {
  if (!state.apiToken) {
    $("#broadcastRows").innerHTML = `<tr><td colspan="3" class="empty">${t("loginRequired")}</td></tr>`;
    return;
  }
  try {
    const msgs = await invoke("load_broadcast_history", { baseUrl: state.apiBaseUrl, token: state.apiToken });
    const tbody = $("#broadcastRows");
    tbody.replaceChildren();
    for (const m of msgs) {
      const tr = document.createElement("tr");
      tr.innerHTML = `
        <td>${new Date(m.sent_at).toLocaleString()}</td>
        <td>${m.sender_name}</td>
        <td>${m.message}</td>
      `;
      tbody.append(tr);
    }
  } catch (e) {
    $("#broadcastRows").innerHTML = `<tr><td colspan="3" class="empty">${e}</td></tr>`;
  }
}

async function checkUpdate() {
  try {
    const info = await invoke("check_update");
    if (info.available) {
      $("#updateStatusMessage").textContent = t("updateAvailable", { latest: info.latest_version, current: info.current_version });
    } else {
      $("#updateStatusMessage").textContent = t("updateCurrent", { current: info.current_version });
    }
  } catch (e) {
    $("#updateStatusMessage").textContent = `${t("updateFailed")}: ${e}`;
  }
}

async function openSteam(address) {
  try {
    await invoke("open_steam_connect", { address });
  } catch {
    window.location.href = `steam://connect/${address}`;
  }
}

function bindEvents() {
  $$(".nav-item").forEach((button) => {
    button.addEventListener("click", () => setTab(button.dataset.tab));
  });
  
  $("#refreshBtn").addEventListener("click", () => {
    if (state.tab === "servers") refreshServers();
    else if (state.tab === "globalPlayers") loadGlobalPlayers();
    else if (state.tab === "broadcast") loadBroadcastHistory();
  });
  
  $("#onlyPlayersInput").addEventListener("change", (event) => {
    state.onlyWithPlayers = event.currentTarget.checked;
    refreshServers();
  });
  $("#hideTimeoutInput").addEventListener("change", (event) => {
    state.hideTimeout = event.currentTarget.checked;
    refreshServers();
  });
  let searchTimer = 0;
  $("#searchInput").addEventListener("input", (event) => {
    state.search = event.currentTarget.value;
    clearTimeout(searchTimer);
    searchTimer = setTimeout(refreshServers, 220);
  });
  
  // Settings
  $("#newSubscriptionBtn").addEventListener("click", clearSubscriptionEditor);
  $("#saveSubscriptionBtn").addEventListener("click", saveSubscription);
  $("#deleteSubscriptionBtn").addEventListener("click", deleteSubscription);
  $("#addManualBtn").addEventListener("click", addManualServer);
  
  // Sort
  $$("th.sortable").forEach(th => {
    th.addEventListener("click", () => handleSortClick(th.dataset.sort));
  });
  
  // Inspector
  $("#closeInspectorBtn").addEventListener("click", closeInspector);
  $$(".ins-tab").forEach(tab => {
    tab.addEventListener("click", () => setInspectorTab(tab.dataset.ins));
  });
  $("#rconSendBtn").addEventListener("click", sendRcon);
  $("#rconCommand").addEventListener("keypress", (e) => {
    if (e.key === 'Enter') sendRcon();
  });
  
  // Steam
  $("#steamLoginBtn").addEventListener("click", startSteamLogin);
  $("#steamLogoutBtn").addEventListener("click", logoutApi);
  $("#checkUpdateBtn").addEventListener("click", checkUpdate);
  
  // Broadcast
  $("#broadcastSendBtn").addEventListener("click", sendBroadcastMessage);
  
  // i18n
  $("#languageSelect").addEventListener("change", (e) => {
    setLocale(e.target.value);
  });
}

async function boot() {
  initI18n();
  // Set dropdown to match current locale
  const savedLocale = localStorage.getItem("appLocale");
  if (savedLocale) {
    $("#languageSelect").value = savedLocale;
  }
  
  bindEvents();
  clearSubscriptionEditor();
  try {
    if (tauriInvoke) {
      state.configPath = await invoke("config_path");
    }
    $("#configPath").textContent = compactPath(state.configPath);
    await loadConfigLists();
    await refreshServers();
    
    // Auto refresh every 10 seconds
    setInterval(() => {
      if (state.tab === "servers" && !state.busy) {
        refreshServers();
      }
    }, 10000);
    
  } catch (error) {
    setStatus(`${t("initFailed")}: ${error}`);
  }
}

boot();
