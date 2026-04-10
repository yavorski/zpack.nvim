# Public API

The functions and types on this page are the supported surface for third-party tooling (e.g. UIs like [zshow.nvim](https://github.com/sairyy/zshow.nvim)) that needs to inspect the plugins zpack is managing.

See `:help zpack-public-api` for the vimdoc version of this reference.

## Entry point

The canonical module is `require('zpack.api')`. For convenience, `VERSION`, `get_plugins()`, and `get_plugin(name)` are also re-exported on the root module (`require('zpack')`). Everything else lives under `zpack.api.*`.

```lua
local api = require('zpack.api')
api.VERSION             -- integer, currently 1
api.get_plugins()       -- zpack.PluginInfo[]
api.get_plugin(name)    -- zpack.PluginInfo?
```

Everything the API exposes is defined in `lua/zpack/api/`. Modules outside that directory are **internal** — their shapes may change between commits. If you were previously reading `require('zpack.state').spec_registry` or similar, migrate to `require('zpack.api').get_plugins()`: the API fields (`name`, `src`, `status`, `lazy`, `path`) cover what dashboards and pickers typically need, and `enabled = false` plugins are now pruned from the internal registry so direct reads will miss them.

Install-state queries (the currently checked-out git revision, available updates, on-disk size, etc.) are intentionally **not** part of this API — they are owned by Neovim's `vim.pack` module, which is itself public and stable. If you need the installed rev for a plugin, call `vim.pack.get({ info.name }, { info = false })` directly; zpack does not re-export it.

## Stability

- The intent is for functions and fields listed here to remain stable, and new fields may be added additively.
- `zpack.api.VERSION` is bumped whenever the contract changes in a consumer-observable way. Consumers that depend on new fields can gate on it:
  ```lua
  if require('zpack.api').VERSION >= 2 then
    -- use a field that will be introduced in v2
  end
  ```
- A formal deprecation policy is not yet in place — it will be introduced the first time an existing field needs to be retired, rather than promised in advance.
- `require('zpack.state')` and every other module under `zpack.*` (other than `zpack.api`) are **internal**. Their shapes may change without notice; do not depend on them.

## Functions

### `api.get_plugins()`

Return a snapshot of every plugin zpack knows about, sorted by `name`. Plugins disabled by `enabled = false` (and any dep-only plugins that become unreferenced as a result) are pruned during setup and will **not** appear here — use `enabled` for hard disables that should vanish from the registry, and `cond` for runtime conditions that should remain visible with `status = "disabled"`. The returned array is freshly allocated on each call; entries must be treated as read-only. zpack itself is **not** listed — it bootstraps via `vim.pack.add` outside this API, and consumers that need to show it can query `vim.pack.get` directly.

```lua
for _, info in ipairs(require('zpack.api').get_plugins()) do
  print(info.name, info.status)
end
```

**Returns:** `zpack.PluginInfo[]`

### `api.get_plugin(name)`

Look up a single plugin by its resolved `zpack.PluginInfo.name`. Returns a plugin registered under `name`, or `nil` when none is registered; never throws. `vim.pack.add` rejects name collisions within a single `setup()`, so at most one entry can ever match.

```lua
local info = require('zpack.api').get_plugin('telescope.nvim')
if info and info.status == 'loaded' then
  -- ...
end
```

**Parameters:**
- `name` (`string`) — Resolved plugin name to look up.

**Returns:** `zpack.PluginInfo?`

### `require('zpack').get_plugins()` / `require('zpack').get_plugin(name)`

Convenience aliases for the functions above, for consumers that don't want a second `require`.

## `zpack.PluginInfo`

Snapshot of a registered plugin returned by the functions above. Treat as read-only.

```lua
{
  name   = string,                        -- resolved plugin name
  src    = string,                        -- git URL or local path passed to
                                          --   vim.pack.add
  status = "loaded"|"pending"             -- current load/enablement state
         | "loading"|"disabled"
         | "installing",
  lazy   = boolean,                       -- configured to lazy-load?
  path   = string?,                       -- absolute plugin directory
                                          -- (nil while status == "installing")
}
```

### Fields

#### `name` (`string`)

Resolved plugin name and the stable lookup key for `get_plugin(name)`. Matches the name zpack uses for tab completion, commands like `:ZUpdate`, and the directory under `site/pack/zpack/opt`. Unique within a single `setup()`.

#### `src` (`string`)

The git URL or local path zpack passed to `vim.pack.add` for this plugin — the same value you would put in a spec's `src` / `dir` / `url` field, or the URL zpack derived from the `"user/repo"` shorthand. Unique within a single `setup()`, and safe to pass back to `vim.pack.get` or display in a UI. Use `name` (not `src`) as the `get_plugin(...)` lookup key.

#### `status` (`"loaded"|"pending"|"loading"|"disabled"|"installing"`)

Current state of the plugin:

- `"loaded"` — plugin has been loaded into the session
- `"pending"` — registered but not yet loaded (e.g. a lazy plugin whose trigger has not fired)
- `"loading"` — currently mid-load (observable inside the plugin's own `config` callback when it is lazy-loaded)
- `"disabled"` — `cond` resolved to `false`. The plugin **is** registered with `vim.pack.add` (so `path` is populated), but zpack skips its config/load steps. Plugins disabled by `enabled = false` are pruned entirely and do not appear in this API — and `:ZClean` will delete them from disk on its next run, which is the intended hard-disable semantic. Use `cond = false` if you want the plugin to stay installed.
- `"installing"` — spec is registered but `vim.pack.add`'s load callback has not fired yet (typically a fresh install awaiting user confirmation or an async download). `path` is `nil` for these entries. `get_plugin(name)` can still resolve them: the reported `name` is derived from the spec (explicit `name`, or the basename of `src` with `.git` stripped, matching `vim.pack`'s own derivation) and stays stable as the entry transitions to `pending` / `loaded`.

#### `lazy` (`boolean`)

Whether the plugin is configured to lazy-load — either by `lazy = true` or by setting a trigger like `event`, `cmd`, `keys`, or `ft`. Resolved from the merged spec during setup, so the value is stable across the `installing → pending → loaded` lifecycle. For function-form triggers (e.g. `event = function(plugin) ... end`), the pre-install answer is computed without a plugin argument; the post-install callback re-computes it with the real plugin, so in rare cases a function-form trigger may disagree between those two states.

#### `path` (`string?`)

Absolute path to the plugin directory on disk. Populated by `vim.pack.add`'s load callback, which resolves the path before `cond` is evaluated — so `path` is present for every `loaded`/`pending`/`loading`/`disabled` entry. It is `nil` only while `status == "installing"` (the load callback has not fired yet, typically a fresh install awaiting user confirmation); check `status` or nil-guard before using it.

### Install-state queries (rev, updates, etc.)

Not part of this API. Use `vim.pack.get({ info.name }, { info = false })` to fetch the checked-out revision, or pass `{ info = true }` for upstream/update information. `vim.pack` is itself public and stable, so zpack deliberately does not re-export or wrap it.
