use anne_server_browser::{
    add_tauri_manual_server, delete_tauri_sourcebans, load_tauri_config_lists,
    load_tauri_server_rows, open_tauri_steam_connect, save_tauri_sourcebans, tauri_config_path,
    TauriConfigLists, TauriServerQuery, TauriServerRows, TauriSourceBansInput,
};

#[tauri::command]
fn config_path() -> String {
    tauri_config_path()
}

#[tauri::command]
fn load_config_lists(path: Option<String>) -> Result<TauriConfigLists, String> {
    load_tauri_config_lists(path)
}

#[tauri::command]
fn refresh_servers(query: TauriServerQuery) -> Result<TauriServerRows, String> {
    load_tauri_server_rows(query)
}

#[tauri::command]
fn add_manual_server(
    path: Option<String>,
    group: String,
    server: String,
) -> Result<TauriConfigLists, String> {
    add_tauri_manual_server(path, group, server)
}

#[tauri::command]
fn save_sourcebans(input: TauriSourceBansInput) -> Result<TauriConfigLists, String> {
    save_tauri_sourcebans(input)
}

#[tauri::command]
fn delete_sourcebans(path: Option<String>, index: usize) -> Result<TauriConfigLists, String> {
    delete_tauri_sourcebans(path, index)
}

#[tauri::command]
fn open_steam_connect(address: String) -> Result<(), String> {
    open_tauri_steam_connect(address)
}

fn main() {
    tauri::Builder::default()
        .invoke_handler(tauri::generate_handler![
            config_path,
            load_config_lists,
            refresh_servers,
            add_manual_server,
            save_sourcebans,
            delete_sourcebans,
            open_steam_connect,
        ])
        .run(tauri::generate_context!())
        .expect("failed to run Anne刷服器");
}
