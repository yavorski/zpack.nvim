local helpers = require('helpers')

return function()
  helpers.describe("Spec Merging", function()
    helpers.test("duplicate specs are merged", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          { 'test/plugin', opts = { a = 1 } },
          { 'test/plugin', opts = { b = 2 } },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local state = require('zpack.state')
      local src = 'https://github.com/test/plugin'

      helpers.assert_equal(#state.spec_registry[src].specs, 2, "should have 2 specs")
      helpers.assert_not_nil(state.spec_registry[src].merged_spec, "should have merged_spec")

      helpers.cleanup_test_env()
    end)

    helpers.test("opts are deep merged", function()
      helpers.setup_test_env()
      local received_opts = nil

      require('zpack').setup({
        spec = {
          { 'test/plugin', opts = { a = 1, nested = { x = 1 } } },
          {
            'test/plugin',
            opts = { b = 2, nested = { y = 2 } },
            config = function(plugin, opts)
              received_opts = opts
            end,
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      helpers.assert_not_nil(received_opts, "config should receive merged opts")
      helpers.assert_equal(received_opts.a, 1)
      helpers.assert_equal(received_opts.b, 2)
      helpers.assert_equal(received_opts.nested.x, 1)
      helpers.assert_equal(received_opts.nested.y, 2)

      helpers.cleanup_test_env()
    end)

    helpers.test("override fields use last value", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          { 'test/plugin', priority = 10, main = 'first' },
          { 'test/plugin', priority = 20, main = 'second' },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local state = require('zpack.state')
      local src = 'https://github.com/test/plugin'
      local spec = state.spec_registry[src].merged_spec

      helpers.assert_equal(spec.priority, 20)
      helpers.assert_equal(spec.main, 'second')

      helpers.cleanup_test_env()
    end)

    helpers.test("list fields are extended uniquely", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          { 'test/plugin', event = 'BufReadPre', cmd = 'Cmd1' },
          { 'test/plugin', event = { 'BufWritePost', 'BufReadPre' }, cmd = 'Cmd2' },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local state = require('zpack.state')
      local src = 'https://github.com/test/plugin'
      local spec = state.spec_registry[src].merged_spec

      helpers.assert_equal(#spec.event, 2, "should have 2 unique events")
      helpers.assert_equal(#spec.cmd, 2, "should have 2 commands")

      helpers.cleanup_test_env()
    end)

    helpers.test("config function uses last declared", function()
      helpers.setup_test_env()
      local config_count = 0
      local which_config = nil

      require('zpack').setup({
        spec = {
          {
            'test/plugin',
            config = function()
              config_count = config_count + 1
              which_config = 'first'
            end,
          },
          {
            'test/plugin',
            config = function()
              config_count = config_count + 1
              which_config = 'second'
            end,
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      helpers.assert_equal(config_count, 1, "config should only run once")
      helpers.assert_equal(which_config, 'second', "should use last config")

      helpers.cleanup_test_env()
    end)

    helpers.test("function-based opts receives accumulated opts", function()
      helpers.setup_test_env()
      local received_accumulated = nil

      require('zpack').setup({
        spec = {
          { 'test/plugin', opts = { base = true } },
          {
            'test/plugin',
            opts = function(plugin, accumulated)
              received_accumulated = accumulated
              return vim.tbl_extend('force', accumulated, { added = true })
            end,
            config = function() end,
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      helpers.assert_not_nil(received_accumulated, "should receive accumulated opts")
      helpers.assert_equal(received_accumulated.base, true)

      helpers.cleanup_test_env()
    end)

    helpers.test("standalone specs have priority over dependency specs", function()
      helpers.setup_test_env()
      local received_opts = nil

      require('zpack').setup({
        spec = {
          {
            'test/parent',
            dependencies = {
              { 'test/dep', opts = { from_dep = true, conflict = 'dep' } },
            },
          },
          {
            'test/dep',
            opts = { from_standalone = true, conflict = 'standalone' },
            config = function(plugin, opts)
              received_opts = opts
            end,
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      helpers.assert_not_nil(received_opts)
      helpers.assert_equal(received_opts.from_dep, true)
      helpers.assert_equal(received_opts.from_standalone, true)
      helpers.assert_equal(received_opts.conflict, 'standalone', "standalone should win")

      helpers.cleanup_test_env()
    end)

    helpers.test("standalone branch is not overridden by nil dependency branch", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          {
            'test/parent',
            dependencies = {
              'test/dep',
            },
          },
          {
            'test/dep',
            branch = 'main',
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local state = require('zpack.state')
      local src = 'https://github.com/test/dep'

      local merged_spec = state.spec_registry[src].merged_spec
      helpers.assert_equal(merged_spec.branch, 'main', "standalone branch should be preserved")

      local pack_spec = state.src_to_pack_spec[src]
      helpers.assert_equal(pack_spec.version, 'main', "pack_spec.version should use merged branch")

      helpers.cleanup_test_env()
    end)

    helpers.test("dependency branch is used when standalone has no branch", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          {
            'test/parent',
            dependencies = {
              { 'test/dep', branch = 'develop' },
            },
          },
          {
            'test/dep',
            config = function() end,
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local state = require('zpack.state')
      local src = 'https://github.com/test/dep'

      local merged_spec = state.spec_registry[src].merged_spec
      helpers.assert_equal(merged_spec.branch, 'develop', "dependency branch should be used when standalone has none")

      local pack_spec = state.src_to_pack_spec[src]
      helpers.assert_equal(pack_spec.version, 'develop', "pack_spec.version should use dependency branch")

      helpers.cleanup_test_env()
    end)
  end)

  helpers.describe("Merge Module Unit Tests", function()
    helpers.test("merge_specs deep merges opts", function()
      helpers.setup_test_env()
      local merge = require('zpack.merge')

      local base = { opts = { a = 1, nested = { x = 1 } } }
      local incoming = { opts = { b = 2, nested = { y = 2 } } }
      local result = merge.merge_specs(base, incoming)

      helpers.assert_equal(result.opts.a, 1)
      helpers.assert_equal(result.opts.b, 2)
      helpers.assert_equal(result.opts.nested.x, 1)
      helpers.assert_equal(result.opts.nested.y, 2)

      helpers.cleanup_test_env()
    end)

    helpers.test("merge_specs extends list fields uniquely", function()
      helpers.setup_test_env()
      local merge = require('zpack.merge')

      local base = { event = { 'A', 'B' } }
      local incoming = { event = { 'B', 'C' } }
      local result = merge.merge_specs(base, incoming)

      helpers.assert_equal(#result.event, 3)

      helpers.cleanup_test_env()
    end)

    helpers.test("merge_specs uses AND logic for cond", function()
      helpers.setup_test_env()
      local merge = require('zpack.merge')

      local base = { cond = true }
      local incoming = { cond = false }
      local result = merge.merge_specs(base, incoming)

      helpers.assert_equal(result.cond, false)

      helpers.cleanup_test_env()
    end)

    helpers.test("merge_and for enabled: function returning false composes to false", function()
      helpers.setup_test_env()
      local merge = require('zpack.merge')
      local utils = require('zpack.utils')

      local base = { enabled = function() return false end }
      local incoming = { enabled = true }
      local result = merge.merge_specs(base, incoming)

      helpers.assert_equal(type(result.enabled), "function", "merged enabled should be callable")
      helpers.assert_false(
        utils.check_enabled(result),
        "enabled fn returning false must propagate through merge, not collapse via ternary"
      )

      helpers.cleanup_test_env()
    end)

    helpers.test("merge_and for cond: function returning false composes to false", function()
      helpers.setup_test_env()
      local merge = require('zpack.merge')
      local utils = require('zpack.utils')

      local base = { cond = function() return false end }
      local incoming = { cond = true }
      local result = merge.merge_specs(base, incoming)

      helpers.assert_equal(type(result.cond), "function", "merged cond should be callable")
      helpers.assert_false(
        utils.check_cond(result, {}),
        "cond fn returning false must propagate through merge, not collapse via ternary"
      )

      helpers.cleanup_test_env()
    end)

    helpers.test("merge_and_enabled: merged function is called with no arguments", function()
      helpers.setup_test_env()
      local merge = require('zpack.merge')
      local utils = require('zpack.utils')

      local received_arg
      local base = { enabled = function(...) received_arg = select('#', ...); return true end }
      local incoming = { enabled = function() return true end }
      local result = merge.merge_specs(base, incoming)
      utils.check_enabled(result)

      helpers.assert_equal(
        received_arg,
        0,
        "enabled functions must receive zero arguments when composed via merge"
      )

      helpers.cleanup_test_env()
    end)

    helpers.test("sort_specs puts dependencies before standalone", function()
      helpers.setup_test_env()
      local merge = require('zpack.merge')

      local specs = {
        { _is_dependency = true, _import_order = 0 },
        { _is_dependency = false, _import_order = 1 },
        { _is_dependency = true, _import_order = 2 },
      }
      local sorted = merge.sort_specs(specs)

      helpers.assert_true(sorted[1]._is_dependency, "first should be dependency")
      helpers.assert_true(sorted[2]._is_dependency, "second should be dependency")
      helpers.assert_false(sorted[3]._is_dependency, "last should be standalone (wins)")

      helpers.cleanup_test_env()
    end)

    helpers.test("resolve_opts accumulates through function opts", function()
      helpers.setup_test_env()
      local merge = require('zpack.merge')

      local specs = {
        { opts = { a = 1 } },
        {
          opts = function(plugin, acc)
            return vim.tbl_extend('force', acc, { b = 2 })
          end,
        },
        { opts = { c = 3 } },
      }
      local result = merge.resolve_opts(specs, {})

      helpers.assert_equal(result.a, 1)
      helpers.assert_equal(result.b, 2)
      helpers.assert_equal(result.c, 3)

      helpers.cleanup_test_env()
    end)

    helpers.test("keys with different modes are not deduplicated", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          { 'test/plugin', keys = { { '<leader>a', mode = 'n', desc = 'normal' } } },
          { 'test/plugin', keys = { { '<leader>a', mode = 'v', desc = 'visual' } } },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local state = require('zpack.state')
      local src = 'https://github.com/test/plugin'
      local merged = state.spec_registry[src].merged_spec

      helpers.assert_equal(#merged.keys, 2, "both keys should be kept (different modes)")

      helpers.cleanup_test_env()
    end)

    helpers.test("keys with same lhs and mode are deduplicated", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          { 'test/plugin', keys = { { '<leader>a', mode = 'n', desc = 'first' } } },
          { 'test/plugin', keys = { { '<leader>a', mode = 'n', desc = 'second' } } },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local state = require('zpack.state')
      local src = 'https://github.com/test/plugin'
      local merged = state.spec_registry[src].merged_spec

      helpers.assert_equal(#merged.keys, 1, "duplicate keys should be deduplicated")
      helpers.assert_equal(merged.keys[1].desc, 'first', "first declaration wins")

      helpers.cleanup_test_env()
    end)

    helpers.test("keys with same modes in different order are deduplicated", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          { 'test/plugin', keys = { { '<leader>a', mode = { 'n', 'v' }, desc = 'first' } } },
          { 'test/plugin', keys = { { '<leader>a', mode = { 'v', 'n' }, desc = 'second' } } },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local state = require('zpack.state')
      local src = 'https://github.com/test/plugin'
      local merged = state.spec_registry[src].merged_spec

      helpers.assert_equal(#merged.keys, 1, "keys with same modes in different order should be deduplicated")

      helpers.cleanup_test_env()
    end)
  end)
end
