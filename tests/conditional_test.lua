local helpers = require('helpers')

return function()
  helpers.describe("Conditional Loading", function()
    helpers.test("enabled=false prunes plugin from registry", function()
      helpers.setup_test_env()
      local state = require('zpack.state')

      require('zpack').setup({
        spec = {
          {
            'test/plugin',
            enabled = false,
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local src = 'https://github.com/test/plugin'
      helpers.assert_nil(state.spec_registry[src], "enabled=false plugin should be pruned from spec_registry")
      helpers.assert_false(
        vim.tbl_contains(state.registered_plugin_names, 'plugin'),
        "Plugin should not be in registered_plugin_names when enabled=false"
      )
      helpers.assert_nil(
        _G.test_state.registered_pack_specs['plugin'],
        "Plugin should not be passed to vim.pack.add when enabled=false"
      )

      helpers.cleanup_test_env()
    end)

    helpers.test("enabled=true allows plugin registration", function()
      helpers.setup_test_env()
      local state = require('zpack.state')

      require('zpack').setup({
        spec = {
          {
            'test/plugin',
            enabled = true,
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local src = 'https://github.com/test/plugin'
      helpers.assert_not_nil(state.spec_registry[src], "Plugin should be registered when enabled=true")

      helpers.cleanup_test_env()
    end)

    helpers.test("enabled function returning false prunes plugin from registry", function()
      helpers.setup_test_env()
      local state = require('zpack.state')

      require('zpack').setup({
        spec = {
          {
            'test/plugin',
            enabled = function() return false end,
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local src = 'https://github.com/test/plugin'
      helpers.assert_nil(state.spec_registry[src], "enabled fn returning false should prune from spec_registry")
      helpers.assert_false(
        vim.tbl_contains(state.registered_plugin_names, 'plugin'),
        "Plugin should not be in registered_plugin_names"
      )
      helpers.assert_nil(
        _G.test_state.registered_pack_specs['plugin'],
        "Plugin should not be passed to vim.pack.add"
      )

      helpers.cleanup_test_env()
    end)

    helpers.test("enabled function returning nil counts as disabled and prunes", function()
      helpers.setup_test_env()
      local state = require('zpack.state')

      require('zpack').setup({
        spec = {
          {
            'test/plugin',
            enabled = function() return nil end,
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      helpers.assert_nil(
        state.spec_registry['https://github.com/test/plugin'],
        "enabled fn returning nil should be treated as disabled and pruned"
      )
      helpers.assert_nil(
        _G.test_state.registered_pack_specs['plugin'],
        "nil-returning enabled should not reach vim.pack.add"
      )

      helpers.cleanup_test_env()
    end)

    helpers.test("enabled function returning true allows registration", function()
      helpers.setup_test_env()
      local state = require('zpack.state')

      require('zpack').setup({
        spec = {
          {
            'test/plugin',
            enabled = function() return true end,
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local src = 'https://github.com/test/plugin'
      helpers.assert_not_nil(
        state.spec_registry[src],
        "Plugin should be registered when enabled function returns true"
      )

      helpers.cleanup_test_env()
    end)

    helpers.test("cond=false prevents plugin loading", function()
      helpers.setup_test_env()
      local utils = require('zpack.utils')

      local spec = {
        'test/plugin',
        cond = false,
      }

      local should_load = utils.check_cond(spec)
      helpers.assert_false(should_load, "Plugin should not load when cond=false")

      helpers.cleanup_test_env()
    end)

    helpers.test("cond=true allows plugin loading", function()
      helpers.setup_test_env()
      local utils = require('zpack.utils')

      local spec = {
        'test/plugin',
        cond = true,
      }

      local should_load = utils.check_cond(spec)
      helpers.assert_true(should_load, "Plugin should load when cond=true")

      helpers.cleanup_test_env()
    end)

    helpers.test("cond function returning false prevents loading", function()
      helpers.setup_test_env()
      local utils = require('zpack.utils')

      local spec = {
        'test/plugin',
        cond = function() return false end,
      }

      local should_load = utils.check_cond(spec)
      helpers.assert_false(should_load, "Plugin should not load when cond function returns false")

      helpers.cleanup_test_env()
    end)

    helpers.test("cond function returning true allows loading", function()
      helpers.setup_test_env()
      local utils = require('zpack.utils')

      local spec = {
        'test/plugin',
        cond = function() return true end,
      }

      local should_load = utils.check_cond(spec)
      helpers.assert_true(should_load, "Plugin should load when cond function returns true")

      helpers.cleanup_test_env()
    end)

    helpers.test("cond nil defaults to true", function()
      helpers.setup_test_env()
      local utils = require('zpack.utils')

      local spec = {
        'test/plugin',
      }

      local should_load = utils.check_cond(spec)
      helpers.assert_true(should_load, "Plugin should load when cond is nil (default true)")

      helpers.cleanup_test_env()
    end)

    helpers.test("enabled and cond work together", function()
      helpers.setup_test_env()
      local state = require('zpack.state')

      require('zpack').setup({
        spec = {
          {
            'test/plugin',
            enabled = true,
            cond = false,
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local src = 'https://github.com/test/plugin'
      helpers.assert_not_nil(
        state.spec_registry[src],
        "Plugin should be registered (enabled=true)"
      )

      local utils = require('zpack.utils')
      local spec = state.spec_registry[src].merged_spec
      local should_load = utils.check_cond(spec)
      helpers.assert_false(should_load, "Plugin should not load (cond=false)")

      helpers.cleanup_test_env()
    end)

    helpers.test("enabled prevents config execution", function()
      helpers.setup_test_env()
      local config_ran = false

      require('zpack').setup({
        spec = {
          {
            'test/plugin',
            enabled = false,
            config = function()
              config_ran = true
            end,
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      helpers.assert_false(config_ran, "Config should not run when enabled=false")

      helpers.cleanup_test_env()
    end)

    helpers.test("lazy=false overrides lazy triggers", function()
      helpers.setup_test_env()
      local lazy_module = require('zpack.lazy')

      local spec = {
        'test/plugin',
        cmd = 'TestCommand',
        lazy = false,
      }

      helpers.assert_false(lazy_module.is_lazy(spec), "Plugin should not be lazy when lazy=false")

      helpers.cleanup_test_env()
    end)

    helpers.test("lazy=true forces lazy loading even without triggers", function()
      helpers.setup_test_env()
      local lazy_module = require('zpack.lazy')

      local spec = {
        'test/plugin',
        lazy = true,
      }

      helpers.assert_true(lazy_module.is_lazy(spec), "Plugin should be lazy when lazy=true")

      helpers.cleanup_test_env()
    end)

    helpers.test("default_cond=false prevents loading when spec.cond is nil", function()
      helpers.setup_test_env()
      local utils = require('zpack.utils')

      local spec = {
        'test/plugin',
      }

      local should_load = utils.check_cond(spec, nil, false)
      helpers.assert_false(should_load, "Plugin should not load when default_cond=false and spec.cond is nil")

      helpers.cleanup_test_env()
    end)

    helpers.test("default_cond function returning false prevents loading", function()
      helpers.setup_test_env()
      local utils = require('zpack.utils')

      local spec = {
        'test/plugin',
      }

      local should_load = utils.check_cond(spec, nil, function() return false end)
      helpers.assert_false(should_load, "Plugin should not load when default_cond function returns false")

      helpers.cleanup_test_env()
    end)

    helpers.test("spec.cond overrides default_cond", function()
      helpers.setup_test_env()
      local utils = require('zpack.utils')

      local spec = {
        'test/plugin',
        cond = true,
      }

      local should_load = utils.check_cond(spec, nil, false)
      helpers.assert_true(should_load, "Plugin should load when spec.cond=true even if default_cond=false")

      helpers.cleanup_test_env()
    end)

    helpers.test("spec.cond=false overrides default_cond=true", function()
      helpers.setup_test_env()
      local utils = require('zpack.utils')

      local spec = {
        'test/plugin',
        cond = false,
      }

      local should_load = utils.check_cond(spec, nil, true)
      helpers.assert_false(should_load, "Plugin should not load when spec.cond=false even if default_cond=true")

      helpers.cleanup_test_env()
    end)

    helpers.test("cond function receives nil-safe plugin arg at merge-pipeline time", function()
      helpers.setup_test_env()
      local state = require('zpack.state')

      require('zpack').setup({
        spec = {
          {
            'test/plugin',
            cond = function(plugin) return plugin ~= nil end,
            config = function() end,
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()

      local entry = state.spec_registry['https://github.com/test/plugin']
      helpers.assert_not_nil(entry, "Registry entry should exist")
      helpers.assert_equal(
        entry.cond_result,
        true,
        "cond function should receive a non-nil plugin arg at registration"
      )

      helpers.cleanup_test_env()
    end)

    helpers.test("check_enabled handles merge_and-composed functions without crashing", function()
      helpers.setup_test_env()
      local merge = require('zpack.merge')
      local utils = require('zpack.utils')

      local base = { enabled = function() return true end }
      local incoming = { enabled = function() return false end }
      local merged = merge.merge_specs(base, incoming)

      helpers.assert_equal(type(merged.enabled), "function", "merged enabled should be a function")
      local result = utils.check_enabled(merged)
      helpers.assert_false(result, "merged function AND_LOGIC should evaluate to false")

      local both_true = merge.merge_specs(
        { enabled = function() return true end },
        { enabled = function() return true end }
      )
      helpers.assert_true(utils.check_enabled(both_true), "both-true functions should merge to true")

      helpers.cleanup_test_env()
    end)
  end)
end
