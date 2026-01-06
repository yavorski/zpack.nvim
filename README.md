<h1 align="center">
  <img height="80px" src="https://github.com/user-attachments/assets/079c0646-7043-4397-b826-e4e893b2cf60" alt="zpack.nvim">
</h1>
<div align="center">
  <img src="https://img.shields.io/github/actions/workflow/status/zuqini/zpack.nvim/tests.yml?style=for-the-badge&logo=githubactions&logoColor=white&label=tests&labelColor=1e1b4b"> <img src="https://img.shields.io/github/issues/zuqini/zpack.nvim?style=for-the-badge&logo=github&logoColor=white&color=8b5cf6&labelColor=1e1b4b"> <img src="https://img.shields.io/github/issues-pr/zuqini/zpack.nvim?style=for-the-badge&logo=github&logoColor=white&color=8b5cf6&labelColor=1e1b4b">

  <img src="https://img.shields.io/github/last-commit/zuqini/zpack.nvim?style=for-the-badge&logo=neovim&color=8b5cf6&labelColor=1e1b4b"> <img src="https://img.shields.io/github/license/zuqini/zpack.nvim?style=for-the-badge&logo=opensourceinitiative&logoColor=white&color=8b5cf6&labelColor=1e1b4b">
</div>

A thin layer on top of Neovim's native `vim.pack`, adding support for lazy-loading and the widely adopted lazy.nvim-like declarative spec.

**[Why zpack?](#why-zpack)** | **[Examples](#examples)** | **[Spec Reference](#spec-reference)** | **[Migrating from lazy.nvim](#migrating-from-lazynvim)**

## Requirements

- Neovim 0.12.0+

## Installation

```lua
-- install with vim.pack directly
vim.pack.add({ 'https://github.com/zuqini/zpack.nvim' })
```

## Usage

```lua
-- Make sure to setup `mapleader` and `maplocalleader` before loading
-- zpack.nvim so that keymaps referenced from zpack.Spec are aware
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- automatically import specs from `./lua/plugins/`
require('zpack').setup()
```

#### Directory Structure

Under the default setting, create plugin specs in `lua/plugins/`:

```
lua/
  plugins/
    treesitter.lua
    lsp.lua
    ...
```

Each file returns a spec or list of specs (see [examples](#examples) or [spec reference](#spec-reference)):

```lua
-- ./lua/plugins/fundo.lua
return {
  'kevinhwang91/nvim-fundo',
  dependencies = { "kevinhwang91/promise-async" },
  cond = not vim.g.vscode,
  version = 'main',
  build = function() require('fundo').install() end,
  opts = {},
  config = function(_, opts)
    vim.o.undofile = true
    require('fundo').setup(opts)
  end,
}
```

#### Commands

zpack provides the following commands (default prefix: `Z`, customizable via `cmd_prefix` option):

- `:ZUpdate [plugin]` - Update all plugins, or a specific plugin if provided (supports tab completion). See `:h vim.pack.update()`
- `:ZClean` - Remove plugins that are no longer in your spec
- `:ZBuild[!] [plugin]` - Run build hook for a specific plugin, or all plugins with `!` (supports tab completion)
- `:ZLoad[!] [plugin]` - Load a specific unloaded plugin, or all unloaded plugins with `!` (supports tab completion)
- `:ZDelete[!] [plugin]` - Remove a specific plugin, or all plugins with `!` (supports tab completion)
  - Deleting active plugins in your spec can result in errors in your current session. Restart Neovim to re-install them.


#### Configurations

```lua
require('zpack').setup({
  -- { import = 'plugins' }  -- default import spec if not explicitly passed in via [1] or spec
  defaults = {
    confirm = true,          -- set to false to skip vim.pack install prompts (default: true)
    cond = nil,              -- global condition for all plugins, e.g. not vim.g.is_vscode (default: nil)
  },
  performance = {
    vim_loader = true,       -- enables vim.loader for faster startup (default: true)
  },
  cmd_prefix = 'Z',          -- command prefix: :ZUpdate, :ZClean, etc. (default: 'Z')
})
```

Plugin-level settings always take precedence over `defaults`.

#### Importing Specs

```lua
-- automatically import specs from `./lua/plugins/`
require('zpack').setup()

-- or import from a custom directory e.g. `./lua/a/b/plugins/`
require('zpack').setup({ { import = 'a.b.plugins' } })

-- or add your specs inline in setup
require('zpack').setup({
  { 'neovim/nvim-lspconfig', config = function() ... end },
  ...
  { import = 'plugins.mini' }, -- or additionally import from `./lua/plugins/mini/`
})

-- or via the spec field
require('zpack').setup({
  spec = {
    { 'neovim/nvim-lspconfig', config = function() ... end },
    ...
  },
})
```

## Why zpack?

Neovim 0.12+ includes a built-in package manager (`vim.pack`) that handles plugin installation, updates, and version management. zpack is a thin layer that adds lazy-loading capabilities and support for a lazy.nvim-like declarative spec while completely leveraging the native infrastructure.

#### Features
- [z***pack***] is completely native
    - Install and manage your plugins _(including zpack)_ all within `vim.pack`
- [<img width="14" src="https://github.com/user-attachments/assets/1c28419d-f791-4aa4-ada1-b34fb12e95d5">pack] is "batteries included"
    - Add plugins using the same lazy.nvim spec provided by plugin authors you know and love
    - Minimal configurations necessary
- [💤pack] powers up `vim.pack` without the frills
    - Powerful lazy-loading triggers
    - Build triggers for installation/updates
    - Basic plugin management commands

zpack might be for you if:
- you're a lazy.nvim user, love its declarative spec, and its wide adoption by plugin authors, but you don't need most of its advanced features
- you're a lazy.nvim user, want to migrate to `vim.pack`, but don't want to rewrite your entire plugins spec from scratch
- you want to use `vim.pack`, but still looking for a few core quality of life features like:
    - run build commands only when plugin installs/updates
    - a minimalist set of commands and tools to manage your plugin's lifecycle e.g. updates, cleaning, and builds
    - lazy-loading triggers for a faster startup on slower machines
    - lazy.nvim's declarative plugin spec support to keep your main neovim config neat and tidy

As a thin layer, zpack does not provide:
- UI dashboard for your plugins
- Advanced profiling, dev mode, change-detection, etc.

If you're a lazy.nvim user, see [Migrating from lazy.nvim](#migrating-from-lazynvim)

## Examples
For more examples, refer to example config:
- [zpack installation and setup](https://github.com/zuqini/nvim/blob/main/init.lua)
- [plugins directory structure](https://github.com/zuqini/nvim/tree/main/lua/plugins)

#### Plugin Spec

```lua
return {
  'nvim-mini/mini.bracketed',
  -- If `opts` or `config = true` is set,
  -- the config hook calls `require(MAIN).setup(opts)` by default.
  opts = {}, -- calls `require('mini.bracketed').setup({})`
}
```

```lua
return {
  'nvim-lualine/lualine.nvim',
  opts = { theme = 'tokyonight' },
  -- Explicitly define a `config` function hook if you need to run custom logic on plugin load.
  -- The resolved `zpack.Plugin` and `opts` table are passed as its arguments:
  config = function(_, opts)
    vim.opt.showmode = false 
    require('lualine').setup(opts)
  end,
}
```

#### Lazy Load on Command

```lua
return {
  'nvim-tree/nvim-tree.lua',
  cmd = { 'NvimTreeToggle', 'NvimTreeFocus' },
  opts = {},
}
```

#### Lazy Load on Keymap

```lua
return {
  'folke/flash.nvim',
  keys = {
    { 's', function() require('flash').jump() end, mode = { 'n', 'x', 'o' }, desc = 'Flash' },
    { 'S', function() require('flash').treesitter() end, mode = { 'n', 'x', 'o' }, desc = 'Flash Treesitter' },
  },
  opts = {},
}
```

#### Lazy Load on Event

```lua
return {
  'windwp/nvim-autopairs',
  event = 'InsertEnter', -- Also supports 'VeryLazy'
  opts = {},
}
```

#### Lazy Load on Event with Pattern

```lua
-- Inline pattern
return {
  'rust-lang/rust.vim',
  event = 'BufReadPre *.rs',
}

-- Or using EventSpec for multiple patterns
return {
  'polyglot-plugin',
  event = {
    event = 'BufReadPre',
    pattern = { '*.lua', '*.rs' },
  },
  opts = {},
}
```

#### Lazy Load on FileType

Load plugin when opening files of specific types. Automatically re-triggers `BufReadPre`, `BufReadPost`, and `FileType` events to ensure LSP clients and Treesitter attach properly:

```lua
return {
  'rust-lang/rust.vim',
  ft = { 'rust', 'toml' },
}
```

#### Conditional Loading

Use `enabled` to skip `vim.pack.add` entirely, or `cond` to conditionally load after calling `vim.pack.add`:

```lua
return {
  'project-specific-plugin',
  enabled = vim.fn.has('linux') == 1, -- skip installation
  cond = function() return vim.fn.filereadable('.project-marker') == 1 end, -- skip loading
  opts = {},
}
```

#### Build Hook

```lua
return {
  'nvim-telescope/telescope-fzf-native.nvim',
  build = 'make',
}
```

#### Dependencies

```lua
return {
  'nvim-telescope/telescope.nvim',
  cmd = 'Telescope',
  dependencies = {
    'nvim-lua/plenary.nvim',
    { 'nvim-tree/nvim-web-devicons', opts = {} },
  },
}
```

Dependencies are automatically loaded before the parent plugin when the parent's lazy trigger fires.

#### Version Pinning

`vim.pack.add` expects `version` to be `string|vim.VersionRange`:

```lua
return {
  'mrcjkb/rustaceanvim',
  version = vim.version.range('^6'), -- semver version
  -- version = 'main', -- branch
  -- version = 'v1.0.0', -- tag
  -- version = 'abc123', -- commit
}
```
See `:h vim.pack.Spec`, `:h vim.version.range()`, and `:h vim.VersionRange`.

##### Version Pinning for lazy.nvim compatibility

```lua
return {
  'mrcjkb/rustaceanvim',
  sem_version = '^6',  -- corresponds to lazy.nvim spec's `version`, auto-wrapped to vim.version.range()
  -- branch = 'main',
  -- tag = 'v1.0.0',
  -- commit = 'abc123',
}
```

#### Load Priority

Control plugin load order with priority (higher values load first; default: 50):

```lua
-- to load colorscheme early
return {
  'folke/tokyonight.nvim',
  priority = 1000,
  config = function() vim.cmd('colorscheme tokyonight') end,
}
```

#### Using Plugin Data in Hooks

All lifecycle hooks (`init`, `config`, `build`, `cond`) and lazy-loading triggers (`event`, `cmd`, `keys`, `ft`) can be functions that receive a `zpack.Plugin` object containing the resolved plugin path and spec:

```lua
return {
  'some/plugin',
  build = function(plugin)
    -- plugin.path: absolute path to the plugin directory
    -- plugin.spec: the vim.pack.Spec with resolved name, src, version
    vim.fn.system({ 'make', '-C', plugin.path })
  end,
}
```

#### Explicit Main Module

If automatic module detection fails, specify the module explicitly with `main`:

```lua
return {
  'some/plugin-with-unusual-structure',
  main = 'plugin.core',
  opts = {},
}
```

#### Multiple Plugins in One File

```lua
return {
  { 'nvim-lua/plenary.nvim' },
  { 'nvim-tree/nvim-web-devicons' },
  { 'nvim-lualine/lualine.nvim', opts = { theme = 'auto' } },
  { import = 'plugins.mini' },
}
```

## Spec Reference

```lua
{
  -- Plugin source (provide exactly one)
  [1] = "user/repo",                    -- Plugin short name. Expands to https://github.com/{user/repo}
  src = "https://...",                  -- Custom git URL or local path
  dir = "/path/to/plugin",              -- Local plugin directory (lazy.nvim compat, ~ expanded, mapped to src)
  url = "https://...",                  -- Custom git URL (lazy.nvim compat, mapped to src)

  -- Dependencies
  dependencies = string|string[]|zpack.Spec|zpack.Spec[], -- Plugin dependencies

  -- Loading control
  enabled = true|false|function,        -- Enable/disable plugin
  cond = true|false|function(plugin),   -- Condition to load plugin
  lazy = true|false,                    -- Force eager loading when false (auto-detected)
  priority = 50,                        -- Load priority (higher = earlier, default: 50)

  -- Plugin configuration
  opts = {},                            -- Options passed to setup(), triggers auto-setup
  -- opts = function(plugin, opts) return {} end, -- Can also be a function

  -- Lifecycle hooks
  init = function(plugin) end,          -- Runs before plugin loads, useful for certain vim plugins
  config = function(plugin, opts) end,  -- Runs after plugin loads, receives resolved opts
  -- config = true,                      -- Calls require(main).setup({})
  build = string|function(plugin),      -- Build command or function

  -- Lazy loading triggers (auto-sets lazy=true unless overridden)
  -- All triggers can also be functions that receive zpack.Plugin and return the respective type
  event = string|string[]|zpack.EventSpec|(string|zpack.EventSpec)[]|function(plugin), -- Autocommand event(s). Supports 'VeryLazy' and inline patterns: "BufReadPre *.lua"
  pattern = string|string[],            -- Global fallback pattern(s) for all events
  cmd = string|string[]|function(plugin), -- Command(s) to create
  keys = zpack.KeySpec|zpack.KeySpec[]|function(plugin), -- Keymap(s) to create
  ft = string|string[]|function(plugin), -- FileType(s) to lazy load on

  -- Source control (version for `vim.pack.add`, string|vim.VersionRange)
  version = "main",                     -- Git branch, tag, or commit
  -- version = vim.version.range("1.*"), -- Or semver range via vim.version.range()

  -- Source control (lazy.nvim compat, mapped to version)
  sem_version = "^1.0.0",               -- Semver string (corresponds to lazy.nvim spec's version), auto-wrapped to vim.version.range()
  branch = "main",                      -- Git branch
  tag = "v1.0.0",                       -- Git tag
  commit = "abc123",                    -- Git commit

  -- Plugin metadata
  name = "my-plugin",                   -- Custom plugin name (optional, overrides auto-derived name)
  main = "module.name",                 -- Explicit main module (auto-detected if not set)
  module = false,                       -- Disable module-based lazy loading for this plugin

  -- Spec imports
  import = "plugins.lsp",               -- Import from lua/{path}/*.lua and lua/{path}/*/init.lua
}
```

### zpack.Plugin Reference

The plugin data object passed to hooks and trigger functions:

```lua
{
  spec = vim.pack.Spec,           -- The resolved vim.pack spec (name, src, version)
  path = string,                  -- Absolute path to the plugin directory
}
```

### zpack.EventSpec Reference

```lua
{
  event = string|string[],        -- Event name(s) to trigger on
  pattern = string|string[],      -- Pattern(s) for the event (optional)
}
```

### zpack.KeySpec Reference

```lua
{
  [1] = "<leader>ff",             -- LHS keymap (required)
  [2] = function() end,           -- RHS function
  desc = "description",           -- Keymap description
  mode = "n"|{"n","v"},           -- Mode(s), default: "n"
  remap = true|false,             -- Allow remapping, default: false
  nowait = true|false,            -- Default: false
}
```

## Migrating from lazy.nvim

Most of your lazy.nvim plugin specs will work as-is with zpack. However, zpack follows `vim.pack` conventions over lazy.nvim conventions, and is missing a few advanced features:
- **version pinning**: lazy.nvim's `version` field maps to zpack's `sem_version`. See [Version Pinning](#version-pinning-for-lazynvim-compatibility)
- **dev mode**: Use `src = vim.fn.expand('~/projects/my_plugin.nvim')` for local development
- **profiling**: Use `nvim --startuptime startuptime.log`. Also refer to example [Neovim Profiler script](https://gist.github.com/zuqini/35993710f81983fbfa6baca67bdb32ed)

### Snacks.nvim dashboard with zpack.nvim

The default [Snacks.nvim](https://github.com/folke/snacks.nvim) dashboard configuration includes a startup time section that has a hard dependency on lazy.nvim. This will cause errors with any other plugin manager, not just zpack.

To work around this, remove the startup section from your dashboard configuration:

```lua
require('snacks').setup({
  dashboard = {
    sections = {
      { section = "header" },
      { section = "keys", gap = 1, padding = 1 },
      -- { section = "startup" }, -- Remove this line (depends on lazy.nvim)
    },
  }
})
```

See [snacks.nvim#1778](https://github.com/folke/snacks.nvim/issues/1778) for more details.

## Acknowledgements

zpack's spec design and several features are inspired by [lazy.nvim](https://github.com/folke/lazy.nvim). Credit to folke for the excellent plugin manager that influenced this project.

zpack's logo is designed by [DodolCat](https://www.instagram.com/_dodolcat/).
