local helpers = require('helpers')

return function()
  helpers.describe("Dependencies Field", function()
    helpers.test("string dependency is registered", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          {
            'test/parent',
            dependencies = { 'test/dep' },
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local state = require('zpack.state')

      helpers.assert_not_nil(state.spec_registry['https://github.com/test/parent'])
      helpers.assert_not_nil(state.spec_registry['https://github.com/test/dep'])

      helpers.cleanup_test_env()
    end)

    helpers.test("array of string dependencies are registered", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          {
            'test/parent',
            dependencies = { 'test/dep1', 'test/dep2' },
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local state = require('zpack.state')

      helpers.assert_not_nil(state.spec_registry['https://github.com/test/dep1'])
      helpers.assert_not_nil(state.spec_registry['https://github.com/test/dep2'])

      helpers.cleanup_test_env()
    end)

    helpers.test("inline spec dependency is registered", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          {
            'test/parent',
            dependencies = {
              { 'test/dep', opts = { from_dep = true } },
            },
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local state = require('zpack.state')
      local dep_entry = state.spec_registry['https://github.com/test/dep']

      helpers.assert_not_nil(dep_entry)
      helpers.assert_equal(dep_entry.specs[1].opts.from_dep, true)

      helpers.cleanup_test_env()
    end)

    helpers.test("dependency graph is populated", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          {
            'test/parent',
            dependencies = { 'test/dep1', 'test/dep2' },
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local state = require('zpack.state')
      local parent_src = 'https://github.com/test/parent'

      helpers.assert_not_nil(state.dependency_graph[parent_src])
      helpers.assert_equal(vim.tbl_count(state.dependency_graph[parent_src]), 2)

      helpers.cleanup_test_env()
    end)

    helpers.test("dependency specs are marked as dependencies", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          {
            'test/parent',
            dependencies = {
              { 'test/dep', opts = {} },
            },
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local state = require('zpack.state')
      local dep_entry = state.spec_registry['https://github.com/test/dep']

      helpers.assert_true(dep_entry.specs[1]._is_dependency, "dependency spec should be marked")

      helpers.cleanup_test_env()
    end)

    helpers.test("standalone spec is not marked as dependency", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          { 'test/plugin', opts = {} },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local state = require('zpack.state')
      local entry = state.spec_registry['https://github.com/test/plugin']

      helpers.assert_false(entry.specs[1]._is_dependency or false)

      helpers.cleanup_test_env()
    end)

    helpers.test("dependencies are loaded before parent on lazy trigger", function()
      helpers.setup_test_env()
      local load_order = {}

      require('zpack').setup({
        spec = {
          {
            'test/parent',
            cmd = 'ParentCmd',
            dependencies = { 'test/dep' },
            config = function()
              table.insert(load_order, 'parent')
            end,
          },
          {
            'test/dep',
            config = function()
              table.insert(load_order, 'dep')
            end,
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      helpers.assert_equal(#load_order, 1, "only standalone dep should load at startup")
      helpers.assert_equal(load_order[1], 'dep')

      pcall(vim.cmd, 'ParentCmd')
      helpers.flush_pending()

      helpers.assert_equal(#load_order, 2, "parent should load on trigger")
      helpers.assert_equal(load_order[2], 'parent')

      helpers.cleanup_test_env()
    end)

    helpers.test("startup plugin dependencies are loaded before parent", function()
      helpers.setup_test_env()
      local load_order = {}

      require('zpack').setup({
        spec = {
          {
            'test/parent',
            opts = {},
            dependencies = {
              { 'test/dep', config = function() table.insert(load_order, 'dep') end },
            },
            config = function() table.insert(load_order, 'parent') end,
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()

      helpers.assert_equal(#load_order, 2, "both plugins should load at startup")
      helpers.assert_equal(load_order[1], 'dep', "dependency should load first")
      helpers.assert_equal(load_order[2], 'parent', "parent should load second")

      helpers.cleanup_test_env()
    end)

    helpers.test("dependency-only plugin inherits lazy from parent", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          {
            'test/parent',
            cmd = 'LazyCmd',
            dependencies = {
              { 'test/dep-only' },
            },
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local state = require('zpack.state')

      helpers.assert_true(
        state.unloaded_plugin_names['dep-only'] or false,
        "dependency-only plugin should be lazy when parent is lazy"
      )

      helpers.cleanup_test_env()
    end)

    helpers.test("standalone spec overrides lazy inheritance from dependency", function()
      helpers.setup_test_env()
      local load_order = {}

      require('zpack').setup({
        spec = {
          {
            'test/lazy-parent',
            cmd = 'LazyCmd',
            dependencies = {
              { 'test/shared' },
            },
          },
          {
            'test/shared',
            config = function() table.insert(load_order, 'shared') end,
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local state = require('zpack.state')

      helpers.assert_equal(#load_order, 1, "shared should load at startup")
      helpers.assert_equal(load_order[1], 'shared')
      helpers.assert_nil(
        state.unloaded_plugin_names['shared'],
        "standalone spec should make plugin startup, not lazy"
      )
      helpers.assert_true(
        state.unloaded_plugin_names['lazy-parent'] or false,
        "lazy-parent should still be lazy"
      )

      helpers.cleanup_test_env()
    end)

    helpers.test("nested dependencies are supported", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          {
            'test/parent',
            dependencies = {
              {
                'test/child',
                dependencies = {
                  { 'test/grandchild' },
                },
              },
            },
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local state = require('zpack.state')

      helpers.assert_not_nil(state.spec_registry['https://github.com/test/parent'])
      helpers.assert_not_nil(state.spec_registry['https://github.com/test/child'])
      helpers.assert_not_nil(state.spec_registry['https://github.com/test/grandchild'])

      helpers.cleanup_test_env()
    end)

    helpers.test("duplicate dependencies are not added twice to graph", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          {
            'test/parent',
            dependencies = { 'test/dep', 'test/dep' },
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local state = require('zpack.state')
      local parent_src = 'https://github.com/test/parent'

      helpers.assert_equal(vim.tbl_count(state.dependency_graph[parent_src]), 1, "should not duplicate dependency")

      helpers.cleanup_test_env()
    end)

    helpers.test("reverse dependency graph is populated", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          {
            'test/parent',
            dependencies = { 'test/dep' },
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local state = require('zpack.state')
      local dep_src = 'https://github.com/test/dep'
      local parent_src = 'https://github.com/test/parent'

      helpers.assert_not_nil(state.reverse_dependency_graph[dep_src])
      helpers.assert_true(state.reverse_dependency_graph[dep_src][parent_src], "parent should be in reverse graph")

      helpers.cleanup_test_env()
    end)

    helpers.test("circular dependency is detected at runtime and handled gracefully", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          {
            'test/a',
            dependencies = {
              {
                'test/b',
                dependencies = { 'test/a' },
              },
            },
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local state = require('zpack.state')
      local a_src = 'https://github.com/test/a'
      local b_src = 'https://github.com/test/b'

      helpers.assert_not_nil(state.spec_registry[a_src], "a should be registered")
      helpers.assert_not_nil(state.spec_registry[b_src], "b should be registered")
      helpers.assert_equal(state.spec_registry[a_src].load_status, "loaded", "a should be loaded")
      helpers.assert_equal(state.spec_registry[b_src].load_status, "loaded", "b should be loaded")

      helpers.cleanup_test_env()
    end)

    helpers.test("self-dependency is detected at runtime and handled gracefully", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          {
            'test/self',
            dependencies = { 'test/self' },
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local state = require('zpack.state')
      local src = 'https://github.com/test/self'

      helpers.assert_not_nil(state.spec_registry[src], "plugin should be registered")
      helpers.assert_equal(state.spec_registry[src].load_status, "loaded", "plugin should be loaded")

      helpers.cleanup_test_env()
    end)

    helpers.test("three-way circular dependency in startup plugins is handled gracefully", function()
      helpers.setup_test_env()
      local load_order = {}

      require('zpack').setup({
        spec = {
          {
            'test/p1',
            dependencies = { 'test/p2' },
            config = function() table.insert(load_order, 'p1') end,
          },
          {
            'test/p2',
            dependencies = { 'test/p3' },
            config = function() table.insert(load_order, 'p2') end,
          },
          {
            'test/p3',
            dependencies = { 'test/p1' },
            config = function() table.insert(load_order, 'p3') end,
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local state = require('zpack.state')

      helpers.assert_equal(state.spec_registry['https://github.com/test/p1'].load_status, "loaded")
      helpers.assert_equal(state.spec_registry['https://github.com/test/p2'].load_status, "loaded")
      helpers.assert_equal(state.spec_registry['https://github.com/test/p3'].load_status, "loaded")
      helpers.assert_equal(#load_order, 3, "all three plugins should load despite cycle")

      helpers.cleanup_test_env()
    end)

    helpers.test("standalone spec loads before dependent even when also declared as dependency", function()
      helpers.setup_test_env()
      local load_order = {}

      -- Simulates blink.lua + pkl.lua scenario:
      -- LuaSnip defined standalone in blink.lua AND as dependency in pkl.lua
      -- blink.cmp defined after LuaSnip in same file
      -- LuaSnip should load first due to import order
      require('zpack').setup({
        spec = {
          { 'test/luasnip', config = function() table.insert(load_order, 'luasnip') end },
          { 'test/blink', config = function() table.insert(load_order, 'blink') end },
          {
            'test/pkl',
            ft = 'pkl',
            dependencies = { 'test/luasnip' },
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()

      helpers.assert_equal(#load_order, 2, "both startup plugins should load")
      helpers.assert_equal(load_order[1], 'luasnip', "luasnip should load first (lower import order)")
      helpers.assert_equal(load_order[2], 'blink', "blink should load second")

      helpers.cleanup_test_env()
    end)

    helpers.test("src_to_pack_spec index is populated", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          { 'test/plugin' },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local state = require('zpack.state')
      local src = 'https://github.com/test/plugin'

      helpers.assert_not_nil(state.src_to_pack_spec[src], "src_to_pack_spec should be populated")
      helpers.assert_equal(state.src_to_pack_spec[src].src, src)

      helpers.cleanup_test_env()
    end)

    helpers.test("src_to_pack_spec contains resolved pack_spec with name", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          { 'test/no-explicit-name' },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local state = require('zpack.state')
      local src = 'https://github.com/test/no-explicit-name'

      helpers.assert_not_nil(state.src_to_pack_spec[src], "src_to_pack_spec should be populated")
      helpers.assert_not_nil(state.src_to_pack_spec[src].name, "pack_spec should have resolved name")
      helpers.assert_equal(state.src_to_pack_spec[src].name, "no-explicit-name")

      helpers.cleanup_test_env()
    end)

    helpers.test("startup plugin with lazy dependency loads dep before config", function()
      helpers.setup_test_env()
      local load_order = {}

      require('zpack').setup({
        spec = {
          {
            'test/lazy-dep',
            event = 'VeryLazy',
            config = function() table.insert(load_order, 'lazy-dep') end,
          },
          {
            'test/startup-parent',
            dependencies = { 'test/lazy-dep' },
            config = function() table.insert(load_order, 'startup-parent') end,
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()

      helpers.assert_equal(#load_order, 2, "both plugins should load")
      helpers.assert_equal(load_order[1], 'lazy-dep', "lazy dependency should load first")
      helpers.assert_equal(load_order[2], 'startup-parent', "startup parent should load second")

      helpers.cleanup_test_env()
    end)

    helpers.test("startup plugin with multiple lazy dependencies loads all deps", function()
      helpers.setup_test_env()
      local load_order = {}

      require('zpack').setup({
        spec = {
          { 'test/lazy-dep1', cmd = 'Dep1Cmd', config = function() table.insert(load_order, 'lazy-dep1') end },
          { 'test/lazy-dep2', ft = 'testft', config = function() table.insert(load_order, 'lazy-dep2') end },
          {
            'test/startup-parent',
            dependencies = { 'test/lazy-dep1', 'test/lazy-dep2' },
            config = function() table.insert(load_order, 'startup-parent') end,
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()

      helpers.assert_equal(#load_order, 3, "all three plugins should load")
      helpers.assert_true(
        vim.tbl_contains(vim.list_slice(load_order, 1, 2), 'lazy-dep1'),
        "lazy-dep1 should load before parent"
      )
      helpers.assert_true(
        vim.tbl_contains(vim.list_slice(load_order, 1, 2), 'lazy-dep2'),
        "lazy-dep2 should load before parent"
      )
      helpers.assert_equal(load_order[3], 'startup-parent', "startup parent should load last")

      helpers.cleanup_test_env()
    end)

    helpers.test("dependency-only plugin is loaded for startup parent even when lazy parent exists", function()
      helpers.setup_test_env()
      local load_order = {}

      require('zpack').setup({
        spec = {
          {
            'test/lazy-parent',
            cmd = 'LazyCmd',
            dependencies = {
              { 'test/shared-dep', config = function() table.insert(load_order, 'shared-dep') end },
            },
          },
          {
            'test/startup-parent',
            dependencies = { 'test/shared-dep' },
            config = function() table.insert(load_order, 'startup-parent') end,
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()

      helpers.assert_equal(#load_order, 2, "shared-dep and startup-parent should load")
      helpers.assert_equal(load_order[1], 'shared-dep', "shared dependency should load first")
      helpers.assert_equal(load_order[2], 'startup-parent', "startup parent should load second")

      local state = require('zpack.state')
      helpers.assert_true(
        state.unloaded_plugin_names['lazy-parent'] or false,
        "lazy-parent should still be unloaded"
      )

      helpers.cleanup_test_env()
    end)

    helpers.test("deeply nested startup dependencies (4+ levels) load in order", function()
      helpers.setup_test_env()
      local load_order = {}

      require('zpack').setup({
        spec = {
          {
            'test/level-a',
            dependencies = {
              {
                'test/level-b',
                dependencies = {
                  {
                    'test/level-c',
                    dependencies = {
                      {
                        'test/level-d',
                        dependencies = {
                          { 'test/level-e', config = function() table.insert(load_order, 'e') end },
                        },
                        config = function() table.insert(load_order, 'd') end,
                      },
                    },
                    config = function() table.insert(load_order, 'c') end,
                  },
                },
                config = function() table.insert(load_order, 'b') end,
              },
            },
            config = function() table.insert(load_order, 'a') end,
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()

      helpers.assert_equal(#load_order, 5, "all 5 levels should load")
      helpers.assert_equal(load_order[1], 'e', "deepest dependency (e) should load first")
      helpers.assert_equal(load_order[2], 'd', "d should load second")
      helpers.assert_equal(load_order[3], 'c', "c should load third")
      helpers.assert_equal(load_order[4], 'b', "b should load fourth")
      helpers.assert_equal(load_order[5], 'a', "root (a) should load last")

      helpers.cleanup_test_env()
    end)

    helpers.test("diamond dependency pattern loads shared dependency once", function()
      helpers.setup_test_env()
      local load_order = {}

      -- Diamond pattern:
      --     A (shared base)
      --    / \
      --   B   C
      --    \ /
      --     D (root)
      require('zpack').setup({
        spec = {
          {
            'test/d-root',
            dependencies = {
              {
                'test/d-left',
                dependencies = { { 'test/d-base', config = function() table.insert(load_order, 'base') end } },
                config = function() table.insert(load_order, 'left') end,
              },
              {
                'test/d-right',
                dependencies = { 'test/d-base' },
                config = function() table.insert(load_order, 'right') end,
              },
            },
            config = function() table.insert(load_order, 'root') end,
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local state = require('zpack.state')

      local base_count = 0
      for _, name in ipairs(load_order) do
        if name == 'base' then base_count = base_count + 1 end
      end

      helpers.assert_equal(base_count, 1, "shared base should load exactly once")
      helpers.assert_equal(#load_order, 4, "all 4 plugins should load")

      local base_pos = vim.fn.index(load_order, 'base') + 1
      local left_pos = vim.fn.index(load_order, 'left') + 1
      local right_pos = vim.fn.index(load_order, 'right') + 1
      local root_pos = vim.fn.index(load_order, 'root') + 1

      helpers.assert_true(base_pos < left_pos, "base should load before left")
      helpers.assert_true(base_pos < right_pos, "base should load before right")
      helpers.assert_true(left_pos < root_pos, "left should load before root")
      helpers.assert_true(right_pos < root_pos, "right should load before root")

      helpers.assert_equal(
        state.spec_registry['https://github.com/test/d-base'].load_status,
        "loaded",
        "base should be fully loaded"
      )

      helpers.cleanup_test_env()
    end)

    local function has_warning_matching(fragments)
      for _, notif in ipairs(_G.test_state.notifications) do
        if notif.level == vim.log.levels.WARN then
          local all_match = true
          for _, frag in ipairs(fragments) do
            if not notif.msg:find(frag, 1, true) then
              all_match = false
              break
            end
          end
          if all_match then
            return true
          end
        end
      end
      return false
    end

    helpers.test("cond=false on a dep still runs user config and warns", function()
      helpers.setup_test_env()
      local state = require('zpack.state')
      _G.test_state.dep_config_ran = nil

      require('zpack').setup({
        spec = {
          {
            'test/parent',
            dependencies = { 'test/dep' },
          },
          {
            'test/dep',
            cond = false,
            opts = { foo = 1 },
            config = function(_, opts)
              _G.test_state.dep_config_ran = opts
            end,
          },
        },
        defaults = { confirm = false },
      })

      helpers.wait_for_condition(function()
        return _G.test_state.dep_config_ran ~= nil
      end, 200)

      local dep_entry = state.spec_registry['https://github.com/test/dep']
      helpers.assert_not_nil(dep_entry, "dep registry entry should exist")
      helpers.assert_equal(dep_entry.cond_result, false, "dep cond_result should be false")

      helpers.assert_not_nil(_G.test_state.dep_config_ran, "config should have run via dep chain")
      helpers.assert_equal(_G.test_state.dep_config_ran.foo, 1, "user opts should have been passed")

      helpers.assert_true(
        has_warning_matching({ 'test/dep', 'test/parent', 'cond=false' }),
        "expected a cond=false override warning mentioning test/dep and test/parent"
      )

      _G.test_state.dep_config_ran = nil
      helpers.cleanup_test_env()
    end)

    helpers.test("enabled=false on a dep does not run user config and propagates to disable parent", function()
      helpers.setup_test_env()
      local state = require('zpack.state')
      _G.test_state.dep_config_ran = nil

      require('zpack').setup({
        spec = {
          {
            'test/parent',
            dependencies = { 'test/dep' },
          },
          {
            'test/dep',
            enabled = false,
            opts = { foo = 1 },
            config = function(_, opts)
              _G.test_state.dep_config_ran = opts
            end,
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()

      helpers.assert_nil(
        state.spec_registry['https://github.com/test/dep'],
        "disabled dep should be pruned from spec_registry"
      )
      helpers.assert_nil(
        state.spec_registry['https://github.com/test/parent'],
        "parent should be pruned after propagation (required dep is disabled)"
      )

      helpers.assert_nil(_G.test_state.dep_config_ran, "config should NOT have run")
      helpers.assert_nil(
        _G.test_state.registered_pack_specs['dep'],
        "disabled dep should not be passed to vim.pack.add"
      )
      helpers.assert_nil(
        _G.test_state.registered_pack_specs['parent'],
        "propagation-disabled parent should not reach vim.pack.add"
      )

      helpers.assert_true(
        has_warning_matching({ 'test/parent', 'test/dep', 'enabled=false' }),
        "expected a propagation warning naming the parent, dep, and enabled=false"
      )

      _G.test_state.dep_config_ran = nil
      helpers.cleanup_test_env()
    end)

    helpers.test("cond=false standalone runs no config and emits no dep warning", function()
      helpers.setup_test_env()
      _G.test_state.dep_config_ran = nil

      require('zpack').setup({
        spec = {
          {
            'test/solo',
            cond = false,
            opts = { foo = 1 },
            config = function(_, opts)
              _G.test_state.dep_config_ran = opts
            end,
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()

      helpers.assert_nil(_G.test_state.dep_config_ran, "standalone cond=false should not run config")
      helpers.assert_false(
        has_warning_matching({ 'cond=false' }),
        "unexpected cond=false override warning for standalone plugin"
      )

      _G.test_state.dep_config_ran = nil
      helpers.cleanup_test_env()
    end)

    helpers.test("enabled AND_LOGIC: one spec false disables the merged plugin", function()
      helpers.setup_test_env()
      local state = require('zpack.state')

      require('zpack').setup({
        spec = {
          {
            'test/shared',
            enabled = false,
          },
          {
            'test/shared',
            opts = { foo = 1 },
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()

      helpers.assert_nil(
        state.spec_registry['https://github.com/test/shared'],
        "plugin with any fragment disabling it should be pruned"
      )
      helpers.assert_false(
        vim.tbl_contains(state.registered_plugin_names, 'shared'),
        "disabled plugin should not be in registered_plugin_names"
      )
      helpers.assert_nil(
        _G.test_state.registered_pack_specs['shared'],
        "disabled plugin should not be passed to vim.pack.add"
      )

      helpers.cleanup_test_env()
    end)

    helpers.test("enabled AND_LOGIC with two functions: one false disables plugin", function()
      helpers.setup_test_env()
      local state = require('zpack.state')

      require('zpack').setup({
        spec = {
          {
            'test/shared',
            enabled = function() return true end,
          },
          {
            'test/shared',
            enabled = function() return false end,
            opts = { foo = 1 },
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()

      helpers.assert_nil(
        state.spec_registry['https://github.com/test/shared'],
        "merged function AND_LOGIC yielding false should prune the plugin"
      )
      helpers.assert_nil(
        _G.test_state.registered_pack_specs['shared'],
        "function-disabled plugin should not be passed to vim.pack.add"
      )

      helpers.cleanup_test_env()
    end)

    helpers.test("enabled=false on a parent prunes its exclusive dep subtree", function()
      helpers.setup_test_env()
      local state = require('zpack.state')

      require('zpack').setup({
        spec = {
          {
            'test/disabled-parent',
            enabled = false,
            dependencies = { 'test/exclusive-dep' },
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()

      helpers.assert_nil(
        state.spec_registry['https://github.com/test/exclusive-dep'],
        "exclusive dep of a disabled parent should not be registered"
      )
      helpers.assert_nil(
        _G.test_state.registered_pack_specs['exclusive-dep'],
        "exclusive dep should not reach vim.pack.add"
      )

      helpers.cleanup_test_env()
    end)

    helpers.test("enabled=function(false) on a parent prunes its exclusive dep subtree", function()
      helpers.setup_test_env()
      local state = require('zpack.state')

      require('zpack').setup({
        spec = {
          {
            'test/fn-disabled-parent',
            enabled = function() return false end,
            dependencies = { 'test/fn-exclusive-dep' },
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()

      helpers.assert_nil(
        state.spec_registry['https://github.com/test/fn-exclusive-dep'],
        "exclusive dep of a function-disabled parent should not be registered"
      )

      helpers.cleanup_test_env()
    end)

    helpers.test("shared dep survives when one of its parents is enabled=false", function()
      helpers.setup_test_env()
      local state = require('zpack.state')

      require('zpack').setup({
        spec = {
          {
            'test/dead-parent',
            enabled = false,
            dependencies = { 'test/shared-dep' },
          },
          {
            'test/live-parent',
            dependencies = { 'test/shared-dep' },
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()

      helpers.assert_not_nil(
        state.spec_registry['https://github.com/test/shared-dep'],
        "shared dep should still be registered via the live parent"
      )
      helpers.assert_not_nil(
        _G.test_state.registered_pack_specs['shared-dep'],
        "shared dep should reach vim.pack.add via the live parent"
      )
      helpers.assert_nil(
        _G.test_state.registered_pack_specs['dead-parent'],
        "dead parent should not reach vim.pack.add"
      )

      helpers.cleanup_test_env()
    end)

    helpers.test("multi-fragment: enabled=false in one fragment prunes dep from another fragment", function()
      helpers.setup_test_env()
      local state = require('zpack.state')

      require('zpack').setup({
        spec = {
          { 'test/leaky-parent', enabled = false },
          { 'test/leaky-parent', dependencies = { 'test/leaky-dep' } },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()

      helpers.assert_nil(
        state.spec_registry['https://github.com/test/leaky-dep'],
        "dep registered via a fragment whose merged enabled=false must be pruned post-merge"
      )
      helpers.assert_nil(
        _G.test_state.registered_pack_specs['leaky-dep'],
        "orphaned dep should not reach vim.pack.add"
      )
      helpers.assert_nil(
        _G.test_state.registered_pack_specs['leaky-parent'],
        "disabled parent should not reach vim.pack.add"
      )

      helpers.cleanup_test_env()
    end)

    helpers.test("enabled=false on a parent transitively prunes an exclusive dep chain", function()
      helpers.setup_test_env()
      local state = require('zpack.state')

      require('zpack').setup({
        spec = {
          {
            'test/chain-a',
            enabled = false,
            dependencies = {
              { 'test/chain-b', dependencies = { 'test/chain-c' } },
            },
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()

      helpers.assert_nil(
        state.spec_registry['https://github.com/test/chain-b'],
        "exclusive dep B should be pruned"
      )
      helpers.assert_nil(
        state.spec_registry['https://github.com/test/chain-c'],
        "transitive exclusive dep C should be pruned"
      )
      helpers.assert_nil(
        _G.test_state.registered_pack_specs['chain-b'],
        "B should not reach vim.pack.add"
      )
      helpers.assert_nil(
        _G.test_state.registered_pack_specs['chain-c'],
        "C should not reach vim.pack.add"
      )

      helpers.cleanup_test_env()
    end)

    helpers.test("nested A->B->C: middle plugin cond=false still loads its own deps", function()
      helpers.setup_test_env()
      _G.test_state.b_config_ran = nil
      _G.test_state.c_config_ran = nil

      require('zpack').setup({
        spec = {
          {
            'test/n-a',
            dependencies = { 'test/n-b' },
          },
          {
            'test/n-b',
            cond = false,
            dependencies = { 'test/n-c' },
            opts = { b = true },
            config = function(_, opts)
              _G.test_state.b_config_ran = opts
            end,
          },
          {
            'test/n-c',
            opts = { c = true },
            config = function(_, opts)
              _G.test_state.c_config_ran = opts
            end,
          },
        },
        defaults = { confirm = false },
      })

      helpers.wait_for_condition(function()
        return _G.test_state.b_config_ran ~= nil and _G.test_state.c_config_ran ~= nil
      end, 200)

      helpers.assert_not_nil(
        _G.test_state.b_config_ran,
        "cond=false middle dep still runs config when pulled via dep chain"
      )
      helpers.assert_not_nil(
        _G.test_state.c_config_ran,
        "transitive dep C should load via B"
      )
      helpers.assert_true(
        has_warning_matching({ 'test/n-b', 'test/n-a', 'cond=false' }),
        "expected cond=false override warning naming B and its parent A"
      )

      _G.test_state.b_config_ran = nil
      _G.test_state.c_config_ran = nil
      helpers.cleanup_test_env()
    end)

    helpers.test("cond function on a dep receives the live plugin", function()
      helpers.setup_test_env()
      _G.test_state.cond_plugin_arg = nil

      require('zpack').setup({
        spec = {
          {
            'test/cond-fn-parent',
            dependencies = { 'test/cond-fn-dep' },
          },
          {
            'test/cond-fn-dep',
            cond = function(plugin)
              _G.test_state.cond_plugin_arg = plugin
              return true
            end,
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()

      helpers.assert_not_nil(
        _G.test_state.cond_plugin_arg,
        "cond function on a dep should receive the plugin arg at register time"
      )
      helpers.assert_not_nil(
        _G.test_state.cond_plugin_arg.spec,
        "plugin arg should carry spec"
      )

      _G.test_state.cond_plugin_arg = nil
      helpers.cleanup_test_env()
    end)

    helpers.test("lazy parent with cond=false dep: dep loads and warns at trigger time", function()
      helpers.setup_test_env()
      _G.test_state.lazy_dep_config_ran = nil

      require('zpack').setup({
        spec = {
          {
            'test/lazy-cond-parent',
            event = 'User ZpackTestTrigger',
            dependencies = { 'test/lazy-cond-dep' },
          },
          {
            'test/lazy-cond-dep',
            cond = false,
            opts = { trig = true },
            config = function(_, opts)
              _G.test_state.lazy_dep_config_ran = opts
            end,
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      helpers.assert_nil(
        _G.test_state.lazy_dep_config_ran,
        "dep should not load before lazy parent triggers"
      )

      vim.api.nvim_exec_autocmds('User', { pattern = 'ZpackTestTrigger' })
      helpers.flush_pending()

      helpers.assert_not_nil(
        _G.test_state.lazy_dep_config_ran,
        "dep should load when lazy parent triggers"
      )
      helpers.assert_true(
        has_warning_matching({ 'test/lazy-cond-dep', 'test/lazy-cond-parent', 'cond=false' }),
        "expected cond=false warning when lazy parent triggers"
      )

      _G.test_state.lazy_dep_config_ran = nil
      helpers.cleanup_test_env()
    end)

    helpers.test("cross-file import: cond=false dep pulled in as dep of another file still runs with warning", function()
      helpers.setup_test_env()
      local state = require('zpack.state')
      _G.test_state.imported_dep_config_ran = nil

      local utils = require('zpack.utils')
      local original_lsdir = utils.lsdir
      local original_stdpath = vim.fn.stdpath
      vim.fn.stdpath = function() return '/mock/config' end
      utils.lsdir = function(path)
        if path == '/mock/config/lua/zpack_test_import_cond' then
          return {
            { name = 'dep_with_cond.lua', type = 'file' },
            { name = 'parent_using_dep.lua', type = 'file' },
          }
        end
        return {}
      end

      package.loaded['zpack_test_import_cond.dep_with_cond'] = {
        {
          'test/imported-dep',
          cond = false,
          opts = { from_user = true },
          config = function(_, opts)
            _G.test_state.imported_dep_config_ran = opts
          end,
        },
      }
      package.loaded['zpack_test_import_cond.parent_using_dep'] = {
        { 'test/imported-parent', dependencies = { 'test/imported-dep' } },
      }

      require('zpack').setup({
        spec = { { import = 'zpack_test_import_cond' } },
        defaults = { confirm = false },
      })

      helpers.wait_for_condition(function()
        return _G.test_state.imported_dep_config_ran ~= nil
      end, 200)

      helpers.assert_not_nil(
        _G.test_state.imported_dep_config_ran,
        "imported dep's user config should run via dep chain"
      )
      helpers.assert_equal(
        _G.test_state.imported_dep_config_ran.from_user,
        true,
        "user-supplied opts should flow through"
      )
      local dep_entry = state.spec_registry['https://github.com/test/imported-dep']
      helpers.assert_equal(dep_entry.cond_result, false, "cond_result should be false")
      helpers.assert_true(
        has_warning_matching({ 'test/imported-dep', 'test/imported-parent', 'cond=false' }),
        "expected cond=false warning across imports"
      )

      utils.lsdir = original_lsdir
      vim.fn.stdpath = original_stdpath
      package.loaded['zpack_test_import_cond.dep_with_cond'] = nil
      package.loaded['zpack_test_import_cond.parent_using_dep'] = nil
      _G.test_state.imported_dep_config_ran = nil
      helpers.cleanup_test_env()
    end)

    helpers.test("cross-file import: enabled=false dep pulled in as dep of another file skips user config", function()
      helpers.setup_test_env()
      _G.test_state.imported_dep_config_ran = nil

      local utils = require('zpack.utils')
      local original_lsdir = utils.lsdir
      local original_stdpath = vim.fn.stdpath
      vim.fn.stdpath = function() return '/mock/config' end
      utils.lsdir = function(path)
        if path == '/mock/config/lua/zpack_test_import_en' then
          return {
            { name = 'dep_with_enabled.lua', type = 'file' },
            { name = 'parent_using_dep.lua', type = 'file' },
          }
        end
        return {}
      end

      package.loaded['zpack_test_import_en.dep_with_enabled'] = {
        {
          'test/en-dep',
          enabled = false,
          opts = { from_user = true },
          config = function(_, opts)
            _G.test_state.imported_dep_config_ran = opts
          end,
        },
      }
      package.loaded['zpack_test_import_en.parent_using_dep'] = {
        { 'test/en-parent', dependencies = { 'test/en-dep' } },
      }

      require('zpack').setup({
        spec = { { import = 'zpack_test_import_en' } },
        defaults = { confirm = false },
      })

      helpers.flush_pending()

      helpers.assert_nil(
        _G.test_state.imported_dep_config_ran,
        "enabled=false dep should NOT run user config even when pulled via import+dep"
      )
      helpers.assert_nil(
        _G.test_state.registered_pack_specs['en-dep'],
        "enabled=false dep should not reach vim.pack.add"
      )
      helpers.assert_nil(
        _G.test_state.registered_pack_specs['en-parent'],
        "parent should be propagation-disabled when its required dep is enabled=false"
      )
      helpers.assert_true(
        has_warning_matching({ 'test/en-parent', 'test/en-dep', 'enabled=false' }),
        "expected propagation warning naming parent, dep, and enabled=false"
      )

      utils.lsdir = original_lsdir
      vim.fn.stdpath = original_stdpath
      package.loaded['zpack_test_import_en.dep_with_enabled'] = nil
      package.loaded['zpack_test_import_en.parent_using_dep'] = nil
      _G.test_state.imported_dep_config_ran = nil
      helpers.cleanup_test_env()
    end)

    helpers.test("diamond dep with one cond=false path still loads shared dep", function()
      helpers.setup_test_env()
      local state = require('zpack.state')

      require('zpack').setup({
        spec = {
          {
            'test/live-diamond-parent',
            dependencies = { 'test/diamond-dep' },
          },
          {
            'test/cond-diamond-parent',
            cond = false,
            dependencies = { 'test/diamond-dep' },
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()

      helpers.assert_not_nil(
        state.spec_registry['https://github.com/test/diamond-dep'],
        "diamond dep should be registered"
      )
      helpers.assert_not_nil(
        _G.test_state.registered_pack_specs['diamond-dep'],
        "diamond dep should reach vim.pack.add"
      )
      helpers.assert_not_nil(
        _G.test_state.registered_pack_specs['live-diamond-parent'],
        "live diamond parent should load"
      )

      helpers.cleanup_test_env()
    end)

    helpers.test("enabled=false on a dep transitively disables a grandparent chain", function()
      helpers.setup_test_env()
      local state = require('zpack.state')

      require('zpack').setup({
        spec = {
          {
            'test/prop-grand',
            dependencies = { 'test/prop-mid' },
          },
          {
            'test/prop-mid',
            dependencies = { 'test/prop-leaf' },
          },
          {
            'test/prop-leaf',
            enabled = false,
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()

      helpers.assert_nil(
        state.spec_registry['https://github.com/test/prop-leaf'],
        "leaf should be pruned"
      )
      helpers.assert_nil(
        state.spec_registry['https://github.com/test/prop-mid'],
        "mid should be pruned (propagation-disabled, depends on leaf)"
      )
      helpers.assert_nil(
        state.spec_registry['https://github.com/test/prop-grand'],
        "grand should be pruned (propagation-disabled, depends transitively on leaf)"
      )

      for _, name in ipairs({ 'prop-grand', 'prop-mid', 'prop-leaf' }) do
        helpers.assert_nil(
          _G.test_state.registered_pack_specs[name],
          name .. " should not reach vim.pack.add"
        )
      end

      helpers.assert_true(
        has_warning_matching({ 'test/prop-mid', 'test/prop-leaf', 'enabled=false' }),
        "expected propagation warning: mid disabled because leaf has enabled=false"
      )
      helpers.assert_true(
        has_warning_matching({ 'test/prop-grand', 'test/prop-mid', 'enabled=false' }),
        "expected propagation warning: grand disabled because mid has enabled=false"
      )

      helpers.cleanup_test_env()
    end)

    helpers.test("enabled=false on a shared dep disables all dependents", function()
      helpers.setup_test_env()
      local state = require('zpack.state')

      require('zpack').setup({
        spec = {
          {
            'test/shared-dep-a',
            dependencies = { 'test/shared-disabled' },
          },
          {
            'test/shared-dep-b',
            dependencies = { 'test/shared-disabled' },
          },
          {
            'test/shared-disabled',
            enabled = false,
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()

      helpers.assert_nil(
        state.spec_registry['https://github.com/test/shared-dep-a'],
        "dep-a should be pruned (propagation-disabled)"
      )
      helpers.assert_nil(
        state.spec_registry['https://github.com/test/shared-dep-b'],
        "dep-b should be pruned (propagation-disabled)"
      )
      helpers.assert_nil(
        _G.test_state.registered_pack_specs['shared-dep-a'],
        "dep-a should not reach vim.pack.add"
      )
      helpers.assert_nil(
        _G.test_state.registered_pack_specs['shared-dep-b'],
        "dep-b should not reach vim.pack.add"
      )

      helpers.cleanup_test_env()
    end)

    helpers.test("enabled=false propagates even when the parent has other healthy deps", function()
      helpers.setup_test_env()
      local state = require('zpack.state')

      require('zpack').setup({
        spec = {
          {
            'test/multi-dep-parent',
            dependencies = { 'test/healthy-dep', 'test/sick-dep' },
          },
          {
            'test/sick-dep',
            enabled = false,
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()

      helpers.assert_nil(
        state.spec_registry['https://github.com/test/multi-dep-parent'],
        "parent with one disabled required dep should be pruned"
      )
      helpers.assert_nil(
        _G.test_state.registered_pack_specs['multi-dep-parent'],
        "parent should not reach vim.pack.add"
      )
      helpers.assert_nil(
        _G.test_state.registered_pack_specs['healthy-dep'],
        "healthy dep is now exclusive to a disabled parent, should be pruned"
      )

      helpers.cleanup_test_env()
    end)

    helpers.test("enabled=function(false) on a dep propagates to parent", function()
      helpers.setup_test_env()
      local state = require('zpack.state')

      require('zpack').setup({
        spec = {
          {
            'test/fn-prop-parent',
            dependencies = { 'test/fn-prop-dep' },
          },
          {
            'test/fn-prop-dep',
            enabled = function() return false end,
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()

      helpers.assert_nil(
        state.spec_registry['https://github.com/test/fn-prop-parent'],
        "parent should be pruned when dep's enabled function returns false"
      )
      helpers.assert_nil(
        _G.test_state.registered_pack_specs['fn-prop-parent'],
        "parent should not reach vim.pack.add"
      )

      helpers.cleanup_test_env()
    end)

    helpers.test("cond=false on a dep does NOT propagate to parent (soft gate preserved)", function()
      helpers.setup_test_env()
      local state = require('zpack.state')

      require('zpack').setup({
        spec = {
          {
            'test/cond-soft-parent',
            dependencies = { 'test/cond-soft-dep' },
          },
          {
            'test/cond-soft-dep',
            cond = false,
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()

      local parent_entry = state.spec_registry['https://github.com/test/cond-soft-parent']
      helpers.assert_not_nil(parent_entry, "parent entry should exist")
      helpers.assert_false(
        parent_entry.enabled_result == false,
        "parent must NOT be disabled just because a dep has cond=false (cond is soft)"
      )
      helpers.assert_not_nil(
        _G.test_state.registered_pack_specs['cond-soft-parent'],
        "parent should still reach vim.pack.add"
      )
      helpers.assert_not_nil(
        _G.test_state.registered_pack_specs['cond-soft-dep'],
        "cond=false dep should still reach vim.pack.add as a dep of an enabled parent"
      )

      helpers.cleanup_test_env()
    end)

    helpers.test("enabled function is evaluated once per spec, not eagerly at import", function()
      helpers.setup_test_env()
      local call_count = 0

      require('zpack').setup({
        spec = {
          {
            'test/single-eval',
            enabled = function()
              call_count = call_count + 1
              return false
            end,
            dependencies = { 'test/single-eval-dep' },
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()

      helpers.assert_equal(
        call_count,
        1,
        "enabled function should be called exactly once (post-merge), not also at import time"
      )

      helpers.cleanup_test_env()
    end)

    helpers.test("cond_result is nil before register_all and set after", function()
      helpers.setup_test_env()
      local state = require('zpack.state')

      require('zpack').setup({
        spec = {
          { 'test/cond-none' },
          { 'test/cond-yes', cond = true },
          { 'test/cond-no', cond = false },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()

      helpers.assert_equal(
        state.spec_registry['https://github.com/test/cond-none'].cond_result,
        true,
        "plugin without cond should end up with cond_result=true after register_all"
      )
      helpers.assert_equal(
        state.spec_registry['https://github.com/test/cond-yes'].cond_result,
        true,
        "plugin with cond=true should end up with cond_result=true after register_all"
      )
      helpers.assert_equal(
        state.spec_registry['https://github.com/test/cond-no'].cond_result,
        false,
        "plugin with cond=false should end up with cond_result=false after register_all"
      )

      helpers.cleanup_test_env()
    end)
  end)
end
