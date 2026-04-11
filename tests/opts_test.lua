local helpers = require('helpers')

return function()
  helpers.describe("Plugin opts and auto-setup", function()
    helpers.test("opts table is recorded on the registry entry", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          {
            'test/plugin',
            opts = { enabled = true, theme = 'dark' },
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local state = require('zpack.state')
      local src = 'https://github.com/test/plugin'
      local entry = state.spec_registry[src]
      helpers.assert_true(entry.has_opts, "has_opts should be true")
      -- opts is intentionally not stored on merged_spec; the raw value lives
      -- on sorted_specs and is resolved at load time via resolve_opts.
      helpers.assert_nil(entry.merged_spec.opts, "merged_spec.opts must always be nil")
      helpers.assert_equal(entry.sorted_specs[1].opts.enabled, true)
      helpers.assert_equal(entry.sorted_specs[1].opts.theme, 'dark')

      helpers.cleanup_test_env()
    end)

    helpers.test("opts function is recorded on the sorted spec", function()
      helpers.setup_test_env()
      local opts_fn = function() return { test = true } end

      require('zpack').setup({
        spec = {
          {
            'test/plugin',
            opts = opts_fn,
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local state = require('zpack.state')
      local src = 'https://github.com/test/plugin'
      local entry = state.spec_registry[src]
      helpers.assert_true(entry.has_opts, "has_opts should be true for function-form opts")
      helpers.assert_nil(entry.merged_spec.opts, "merged_spec.opts must always be nil")
      helpers.assert_equal(type(entry.sorted_specs[1].opts), 'function')

      helpers.cleanup_test_env()
    end)

    helpers.test("main field is stored in spec", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          {
            'test/plugin',
            main = 'custom.module',
            opts = {},
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local state = require('zpack.state')
      local src = 'https://github.com/test/plugin'
      local spec = state.spec_registry[src].merged_spec
      helpers.assert_equal(spec.main, 'custom.module')

      helpers.cleanup_test_env()
    end)

    helpers.test("config = true is stored in spec", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          {
            'test/plugin',
            config = true,
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local state = require('zpack.state')
      local src = 'https://github.com/test/plugin'
      local spec = state.spec_registry[src].merged_spec
      helpers.assert_equal(spec.config, true)

      helpers.cleanup_test_env()
    end)

    helpers.test("config function receives opts as second argument", function()
      helpers.setup_test_env()
      local received_opts = nil

      require('zpack').setup({
        spec = {
          {
            'test/plugin',
            opts = { foo = 'bar', num = 42 },
            config = function(plugin, opts)
              received_opts = opts
            end,
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      helpers.assert_not_nil(received_opts, "config should receive opts")
      helpers.assert_equal(received_opts.foo, 'bar')
      helpers.assert_equal(received_opts.num, 42)

      helpers.cleanup_test_env()
    end)

    helpers.test("config function receives resolved opts from function", function()
      helpers.setup_test_env()
      local received_opts = nil

      require('zpack').setup({
        spec = {
          {
            'test/plugin',
            opts = function(plugin)
              return { from_fn = true, path = plugin.path }
            end,
            config = function(plugin, opts)
              received_opts = opts
            end,
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      helpers.assert_not_nil(received_opts, "config should receive resolved opts")
      helpers.assert_equal(received_opts.from_fn, true)
      helpers.assert_not_nil(received_opts.path, "opts function should receive plugin data")

      helpers.cleanup_test_env()
    end)

    helpers.test("config receives empty table when no opts specified", function()
      helpers.setup_test_env()
      local received_opts = nil

      require('zpack').setup({
        spec = {
          {
            'test/plugin',
            config = function(plugin, opts)
              received_opts = opts
            end,
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      helpers.assert_not_nil(received_opts, "config should receive opts table")
      helpers.assert_equal(type(received_opts), 'table')

      helpers.cleanup_test_env()
    end)

    helpers.test("lazy plugin with opts triggers config on load", function()
      helpers.setup_test_env()
      local config_ran = false
      local received_opts = nil

      require('zpack').setup({
        spec = {
          {
            'test/plugin',
            cmd = 'TestCommand',
            opts = { lazy_opt = true },
            config = function(plugin, opts)
              config_ran = true
              received_opts = opts
            end,
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      helpers.assert_false(config_ran, "config should not run at setup for lazy plugin")

      pcall(vim.cmd, 'TestCommand')
      helpers.flush_pending()

      helpers.assert_true(config_ran, "config should run when lazy plugin loads")
      helpers.assert_equal(received_opts.lazy_opt, true)

      helpers.cleanup_test_env()
    end)

    helpers.test("custom config function replaces auto-setup", function()
      helpers.setup_test_env()
      local config_call_count = 0

      require('zpack').setup({
        spec = {
          {
            'test/plugin',
            opts = { some = 'opts' },
            config = function(plugin, opts)
              config_call_count = config_call_count + 1
            end,
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      helpers.assert_equal(config_call_count, 1, "config should be called exactly once")

      helpers.cleanup_test_env()
    end)

    helpers.test("opts without config does not call config function", function()
      helpers.setup_test_env()
      local config_ran = false

      require('zpack').setup({
        spec = {
          {
            'test/plugin',
            opts = { enabled = true },
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      helpers.assert_false(config_ran, "no config function should be called")

      helpers.cleanup_test_env()
    end)
  end)

  helpers.describe("resolve_main caching", function()
    helpers.test("resolve_main result is cached in plugin.main", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          {
            'test/plugin',
            main = 'custom.module',
            opts = {},
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local state = require('zpack.state')
      local utils = require('zpack.utils')
      local src = 'https://github.com/test/plugin'
      local entry = state.spec_registry[src]

      local spec = entry.merged_spec
      utils.resolve_main(entry.plugin, spec)
      helpers.assert_equal(entry.plugin.main, 'custom.module')

      helpers.cleanup_test_env()
    end)

    helpers.test("resolve_main uses cached value on subsequent calls", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          {
            'test/plugin',
            main = 'cached.module',
            opts = {},
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local state = require('zpack.state')
      local utils = require('zpack.utils')
      local src = 'https://github.com/test/plugin'
      local entry = state.spec_registry[src]

      local spec = entry.merged_spec
      local first_result = utils.resolve_main(entry.plugin, spec)
      spec.main = 'changed.module'
      local second_result = utils.resolve_main(entry.plugin, spec)

      helpers.assert_equal(first_result, 'cached.module')
      helpers.assert_equal(second_result, 'cached.module', "should use cached value")

      helpers.cleanup_test_env()
    end)
  end)

  helpers.describe("mini.* plugin handling", function()
    helpers.test("mini.* plugin uses plugin name as main module", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          {
            'nvim-mini/mini.surround',
            opts = {},
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local state = require('zpack.state')
      local utils = require('zpack.utils')
      local src = 'https://github.com/nvim-mini/mini.surround'
      local entry = state.spec_registry[src]

      local spec = entry.merged_spec
      local main = utils.resolve_main(entry.plugin, spec)
      helpers.assert_equal(main, 'mini.surround')

      helpers.cleanup_test_env()
    end)

    helpers.test("mini.nvim does not use special handling", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          {
            'nvim-mini/mini.nvim',
            opts = {},
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local state = require('zpack.state')
      local utils = require('zpack.utils')
      local src = 'https://github.com/nvim-mini/mini.nvim'
      local entry = state.spec_registry[src]

      local spec = entry.merged_spec
      local main = utils.resolve_main(entry.plugin, spec)
      helpers.assert_nil(main, "mini.nvim should not match special case")

      helpers.cleanup_test_env()
    end)
  end)

  helpers.describe("plugin.main in config hooks", function()
    helpers.test("plugin.main is available in config function", function()
      helpers.setup_test_env()
      local received_main = nil

      require('zpack').setup({
        spec = {
          {
            'test/plugin',
            main = 'test.module',
            config = function(plugin, opts)
              received_main = plugin.main
            end,
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      helpers.assert_equal(received_main, 'test.module')

      helpers.cleanup_test_env()
    end)

    helpers.test("plugin.main is nil when not detected", function()
      helpers.setup_test_env()
      local received_main = "not_set"

      require('zpack').setup({
        spec = {
          {
            'test/plugin',
            config = function(plugin, opts)
              received_main = plugin.main
            end,
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      helpers.assert_nil(received_main)

      helpers.cleanup_test_env()
    end)
  end)

  helpers.describe("normalize_name utility", function()
    helpers.test("removes nvim- prefix", function()
      helpers.setup_test_env()
      local utils = require('zpack.utils')

      helpers.assert_equal(utils.normalize_name('nvim-treesitter'), 'treesitter')
      helpers.assert_equal(utils.normalize_name('vim-surround'), 'surround')

      helpers.cleanup_test_env()
    end)

    helpers.test("removes .nvim suffix", function()
      helpers.setup_test_env()
      local utils = require('zpack.utils')

      helpers.assert_equal(utils.normalize_name('telescope.nvim'), 'telescope')
      helpers.assert_equal(utils.normalize_name('plugin.vim'), 'plugin')

      helpers.cleanup_test_env()
    end)

    helpers.test("removes -lua and .lua suffixes", function()
      helpers.setup_test_env()
      local utils = require('zpack.utils')

      helpers.assert_equal(utils.normalize_name('plenary-lua'), 'plenary')
      helpers.assert_equal(utils.normalize_name('plugin.lua'), 'plugin')

      helpers.cleanup_test_env()
    end)

    helpers.test("converts to lowercase and removes non-alpha", function()
      helpers.setup_test_env()
      local utils = require('zpack.utils')

      helpers.assert_equal(utils.normalize_name('My-Plugin_123'), 'myplugin')
      helpers.assert_equal(utils.normalize_name('CAPS'), 'caps')

      helpers.cleanup_test_env()
    end)

    helpers.test("handles complex names", function()
      helpers.setup_test_env()
      local utils = require('zpack.utils')

      helpers.assert_equal(utils.normalize_name('nvim-lspconfig'), 'lspconfig')
      helpers.assert_equal(utils.normalize_name('telescope-fzf-native.nvim'), 'telescopefzfnative')

      helpers.cleanup_test_env()
    end)
  end)
end
