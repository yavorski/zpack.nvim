# Commands

zpack provides a single user command, `:ZPack`, with subcommands. The command
name is configurable via the [`cmd_name`](../README.md#configurations) option —
a short name like `Z` or `Zp` is recommended for ease of use.

## Subcommands

- `:ZPack[!] update [plugin]` — Update all plugins, or a specific plugin if provided (supports tab completion). `!` applies updates immediately, skipping the confirmation buffer. Honors `pin = true` for bulk updates. See `:h vim.pack.update()`
- `:ZPack[!] restore [plugin]` — Restore all plugins, or a specific plugin, to the lockfile state (supports tab completion). `!` applies the restore immediately, skipping the confirmation buffer. Requires a lockfile to exist (created automatically by `:ZPack update`). See `:h vim.pack.update()`
- `:ZPack clean` — Remove plugins that are no longer in your spec
- `:ZPack[!] build [plugin]` — Run build hook for a specific plugin, or all plugins with `!` (supports tab completion)
- `:ZPack[!] load [plugin]` — Load a specific unloaded plugin, or all unloaded plugins with `!` (supports tab completion)
- `:ZPack[!] delete [plugin]` — Remove a specific plugin, or all plugins with `!` (supports tab completion)
  - Deleting active plugins in your spec can result in errors in your current session. Restart Neovim to re-install them.
- `:ZPack sync` — Bulk update + clean in one step (always force-applies; use `:ZPack update` without `!` for a preview). lazy.nvim parity for `:Lazy sync`
- `:ZPack reload {plugin}` — Re-source a plugin (runs `deactivate`, clears `package.loaded`, re-runs config). lazy.nvim parity for `:Lazy reload`

## Native vim.pack equivalents (Neovim 0.13+)

Several subcommands map to native `vim.pack` commands you can use interchangeably:

| `:ZPack` | Neovim 0.13+ native |
| --- | --- |
| `:ZPack update [plugin]` | `:packupdate [plugin]` |
| `:ZPack! update [plugin]` | `:packupdate! [plugin]` |
| `:ZPack restore [plugin]` | `:packupdate ++lockfile [plugin]` |
| `:ZPack! restore [plugin]` | `:packupdate! ++lockfile [plugin]` |
| `:ZPack delete {plugin}` | `:packdel! {plugin}` |
| `:ZPack! delete` | `:packdel! ++all` |

`:ZPack! delete` removes only zpack-managed plugins, while `:packdel! ++all` removes *every* installed plugin (including any absent from your spec).

`clean`, `build`, and `load` have no native equivalent. The `:ZPack` subcommands are concise, consistent shortcuts — reach for the native commands when you want their extra flags (e.g. `:packupdate ++offline`).
