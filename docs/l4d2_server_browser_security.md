# Anne server browser security notes

## glib RUSTSEC-2024-0429

Dependabot reports `RUSTSEC-2024-0429` for the Rust `glib` crate. The patched range starts at `glib >= 0.20.0`, but the Tauri app cannot currently resolve to that version:

```text
glib v0.18.5
└── gtk v0.18.2
    └── tauri v2.11.2
        └── anne-server-browser-tauri
```

`cargo update -p glib --precise 0.20.0` fails because `gtk v0.18.2` requires `glib = "^0.18"`. As of Tauri `2.11.2`, Tauri's Linux/BSD dependency set still includes `gtk = "0.18"` and `webkit2gtk = "2"`, so there is no non-vulnerable `glib` version that Cargo can choose for the Linux Tauri dependency graph.

The advisory is an unsoundness issue in `glib::VariantStrIter`. This project does not directly call `glib`; it is present only through Tauri's Linux webview stack.

Revisit this when one of these becomes available:

- a Tauri release that no longer depends on `gtk 0.18`,
- a Tauri-supported Linux backend based on maintained GTK bindings,
- or a project decision to drop the Linux Tauri bundle from the Rust dependency graph.

Until then, Dependabot cannot fix this by editing `Cargo.lock`; the actionable state is to keep Tauri current and re-check when Tauri publishes a dependency migration.
