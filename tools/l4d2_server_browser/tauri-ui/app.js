const tauriInvoke = window.__TAURI__?.core?.invoke;

const mockState = {
  path: "/Users/example/Library/Application Support/Anne刷服器/anne-server-browser.toml",
  lists: {
    config_path: "/Users/example/Library/Application Support/Anne刷服器/anne-server-browser.toml",
    api_base_url: "https://anne.trygek.com",
    sourcebans: [
      {
        index: 0,
        name: "电信服刷服器",
        url: "https://anne.trygek.com/bans/index.php?p=servers",
        source_label: "https://anne.trygek.com/bans/index.php?p=servers · 已缓存 40 个服务器",
        server_count: 40,
      },
    ],
    manual_servers: [
      { index: 0, group: "电信服刷服器", server: "45.125.45.95:28001" },
    ],
  },
};

const mockRows = [
  {
    address: "45.125.45.95:28001",
    socket: "45.125.45.95:28001",
    groups: ["电信服刷服器"],
    group_label: "电信服刷服器",
    name: "Anne Happy 01",
    map: "c2m1_highway",
    ping_ms: 34,
    players: 8,
    max_players: 8,
    bots: 0,
    error: null,
    status: "有人",
    steam_url: "steam://connect/45.125.45.95:28001",
    is_anne: true,
  },
  {
    address: "hbbgp.trygek.com:31001",
    socket: "45.125.45.95:31001",
    groups: ["电信服刷服器"],
    group_label: "电信服刷服器",
    name: "Anne Practice 02",
    map: "c5m1_waterfront",
    ping_ms: 42,
    players: 0,
    max_players: 8,
    bots: 0,
    error: null,
    status: "空服",
    steam_url: "steam://connect/45.125.45.95:31001",
    is_anne: true,
  },
  {
    address: "example.org:27015",
    socket: "203.0.113.10:27015",
    groups: ["社区服"],
    group_label: "社区服",
    name: "Community Versus",
    map: "-",
    ping_ms: null,
    players: 0,
    max_players: 0,
    bots: 0,
    error: "timeout",
    status: "超时",
    steam_url: "steam://connect/203.0.113.10:27015",
    is_anne: false,
  },
];

const state = {
  tab: "servers",
  configPath: "",
  lists: null,
  rows: [],
  group: "全部服务器",
  search: "",
  onlyWithPlayers: false,
  hideTimeout: true,
  selectedSourcebans: null,
  busy: false,
};

const $ = (selector) => document.querySelector(selector);
const $$ = (selector) => Array.from(document.querySelectorAll(selector));

async function invoke(command, args = {}) {
  if (tauriInvoke) {
    return tauriInvoke(command, args);
  }
  return mockInvoke(command, args);
}

async function mockInvoke(command, args) {
  await new Promise((resolve) => setTimeout(resolve, 120));
  if (command === "config_path") {
    return mockState.path;
  }
  if (command === "load_config_lists") {
    return mockState.lists;
  }
  if (command === "refresh_servers") {
    const query = args.query ?? {};
    let rows = [...mockRows];
    if (query.group && query.group !== "全部服务器") {
      rows = rows.filter((row) => row.groups.includes(query.group));
    }
    if (query.only_with_players) {
      rows = rows.filter((row) => row.players > 0);
    }
    if (query.hide_timeout) {
      rows = rows.filter((row) => !row.error);
    }
    if (query.search) {
      const needle = query.search.toLowerCase();
      rows = rows.filter((row) =>
        [row.name, row.address, row.socket, row.map, row.group_label]
          .join(" ")
          .toLowerCase()
          .includes(needle),
      );
    }
    return {
      config_path: mockState.path,
      rows,
      summary: summarizeRows(rows),
    };
  }
  if (command === "add_manual_server") {
    mockState.lists.manual_servers.push({
      index: mockState.lists.manual_servers.length,
      group: args.group,
      server: args.server,
    });
    return mockState.lists;
  }
  if (command === "save_sourcebans") {
    const input = args.input;
    const item = {
      index:
        input.index ?? mockState.lists.sourcebans.length,
      name: input.name,
      url: input.url,
      source_label: input.url || "粘贴文本",
      server_count: input.text ? 1 : 0,
    };
    if (input.index === null || input.index === undefined) {
      mockState.lists.sourcebans.push(item);
    } else {
      mockState.lists.sourcebans[input.index] = item;
    }
    return mockState.lists;
  }
  if (command === "delete_sourcebans") {
    mockState.lists.sourcebans.splice(args.index, 1);
    mockState.lists.sourcebans.forEach((item, index) => {
      item.index = index;
    });
    return mockState.lists;
  }
  return null;
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

function setBusy(value, label = "刷新") {
  state.busy = value;
  $("#refreshBtn").disabled = value;
  $("#refreshBtn").textContent = value ? "刷新中" : label;
}

function setStatus(message) {
  $("#statusLine").textContent = message;
}

function compactPath(path) {
  if (!path) return "未设置配置";
  if (path.length <= 44) return path;
  return `${path.slice(0, 18)}...${path.slice(-22)}`;
}

function setTab(tab) {
  state.tab = tab;
  $$(".nav-item").forEach((button) => {
    button.classList.toggle("active", button.dataset.tab === tab);
  });
  $("#serversView").classList.toggle("active", tab === "servers");
  $("#subscriptionsView").classList.toggle("active", tab === "subscriptions");
  $("#settingsView").classList.toggle("active", tab === "settings");
  $("#viewTitle").textContent =
    tab === "servers" ? "服务器" : tab === "subscriptions" ? "网页订阅" : "设置";
  $("#refreshBtn").style.display = tab === "servers" ? "" : "none";
}

async function loadConfigLists() {
  state.lists = await invoke("load_config_lists", { path: state.configPath || null });
  state.configPath = state.lists.config_path;
  $("#configPath").textContent = compactPath(state.configPath);
  renderSubscriptions();
  renderManualServers();
}

async function refreshServers() {
  setBusy(true);
  setStatus("正在刷新服务器");
  try {
    const payload = await invoke("refresh_servers", {
      query: {
        config_path: state.configPath || null,
        search: state.search,
        group: state.group,
        only_with_players: state.onlyWithPlayers,
        hide_timeout: state.hideTimeout,
        limit: 300,
      },
    });
    state.configPath = payload.config_path;
    state.rows = payload.rows;
    renderMetrics(payload.summary);
    renderGroups(payload.summary.groups);
    renderServerRows();
    setStatus(`已刷新 ${payload.rows.length} 个服务器`);
  } catch (error) {
    setStatus(`刷新失败：${error}`);
  } finally {
    setBusy(false);
  }
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
  all.className = `group-chip ${state.group === "全部服务器" ? "active" : ""}`;
  all.textContent = "全部服务器";
  all.addEventListener("click", () => {
    state.group = "全部服务器";
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
    cell.textContent = "没有匹配的服务器";
    row.append(cell);
    tbody.append(row);
    return;
  }

  for (const server of state.rows) {
    const row = document.createElement("tr");

    const nameCell = document.createElement("td");
    const name = document.createElement("span");
    name.className = "server-name";
    name.title = server.name;
    name.textContent = server.name;
    const status = document.createElement("span");
    status.className = `server-status ${
      server.error ? "timeout" : server.players > 0 ? "" : "empty"
    }`;
    status.textContent = server.status;
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
    connect.textContent = "进入";
    connect.addEventListener("click", () => openSteam(server.socket));
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
    tbody.append(row);
  }
}

function renderSubscriptions() {
  const list = $("#subscriptionList");
  list.replaceChildren();
  const items = state.lists?.sourcebans ?? [];
  if (items.length === 0) {
    const empty = document.createElement("div");
    empty.className = "empty";
    empty.textContent = "还没有订阅";
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
    empty.textContent = "还没有手动服务器";
    list.append(empty);
    return;
  }
  for (const item of items) {
    const row = document.createElement("div");
    row.className = "manual-item";
    const title = document.createElement("strong");
    title.textContent = item.server;
    const detail = document.createElement("span");
    detail.textContent = item.group;
    row.append(title, detail);
    list.append(row);
  }
}

function selectSubscription(item) {
  state.selectedSourcebans = item.index;
  $("#subscriptionEditorTitle").textContent = "编辑订阅";
  $("#subscriptionNameInput").value = item.name;
  $("#subscriptionUrlInput").value = item.url;
  $("#subscriptionTextInput").value = "";
  $("#deleteSubscriptionBtn").disabled = false;
  renderSubscriptions();
}

function clearSubscriptionEditor() {
  state.selectedSourcebans = null;
  $("#subscriptionEditorTitle").textContent = "新建订阅";
  $("#subscriptionNameInput").value = "电信服刷服器";
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
  if (!input.name) {
    setStatus("订阅名称不能为空");
    return;
  }
  try {
    state.lists = await invoke("save_sourcebans", { input });
    state.configPath = state.lists.config_path;
    $("#subscriptionTextInput").value = "";
    renderSubscriptions();
    setStatus("订阅已保存");
    refreshServers();
  } catch (error) {
    setStatus(`保存失败：${error}`);
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
    setStatus("订阅已删除");
    refreshServers();
  } catch (error) {
    setStatus(`删除失败：${error}`);
  }
}

async function addManualServer() {
  const group = $("#manualGroupInput").value.trim();
  const server = $("#manualServerInput").value.trim();
  if (!group || !server) {
    setStatus("分组和地址不能为空");
    return;
  }
  try {
    state.lists = await invoke("add_manual_server", {
      path: state.configPath || null,
      group,
      server,
    });
    $("#manualServerInput").value = "";
    renderManualServers();
    setStatus("服务器已添加");
    refreshServers();
  } catch (error) {
    setStatus(`添加失败：${error}`);
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
  $("#refreshBtn").addEventListener("click", refreshServers);
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
  $("#newSubscriptionBtn").addEventListener("click", clearSubscriptionEditor);
  $("#saveSubscriptionBtn").addEventListener("click", saveSubscription);
  $("#deleteSubscriptionBtn").addEventListener("click", deleteSubscription);
  $("#addManualBtn").addEventListener("click", addManualServer);
}

async function boot() {
  bindEvents();
  clearSubscriptionEditor();
  try {
    state.configPath = await invoke("config_path");
    $("#configPath").textContent = compactPath(state.configPath);
    await loadConfigLists();
    await refreshServers();
  } catch (error) {
    setStatus(`启动失败：${error}`);
  }
}

boot();
