local helpers = require('helpers')

return function()
  helpers.describe("ZPack delete", function()
    helpers.test("delete single plugin uses force=true", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          { 'test/plugin-a' },
          { 'test/plugin-b' },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()

      vim.cmd('ZPack delete plugin-a')
      helpers.flush_pending()

      helpers.assert_equal(#_G.test_state.vim_pack_del_calls, 1, "vim.pack.del should be called once")
      local call = _G.test_state.vim_pack_del_calls[1]
      helpers.assert_not_nil(call.opts, "opts should be passed to vim.pack.del")
      helpers.assert_true(call.opts.force, "force option should be true")
      helpers.assert_table_contains(call.names, 'plugin-a', "plugin-a should be in delete list")

      helpers.cleanup_test_env()
    end)

    helpers.test("ZPack! delete all plugins uses force=true", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          { 'test/plugin-a' },
          { 'test/plugin-b' },
          { 'test/plugin-c' },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()

      vim.cmd('ZPack! delete')
      helpers.flush_pending()

      helpers.assert_equal(#_G.test_state.vim_pack_del_calls, 1, "vim.pack.del should be called once")
      local call = _G.test_state.vim_pack_del_calls[1]
      helpers.assert_not_nil(call.opts, "opts should be passed to vim.pack.del")
      helpers.assert_true(call.opts.force, "force option should be true")
      helpers.assert_equal(#call.names, 4, "all 4 plugins (3 + zpack.nvim) should be in delete list")
      helpers.assert_table_contains(call.names, 'zpack.nvim', "zpack.nvim should be in delete list")

      helpers.cleanup_test_env()
    end)

    helpers.test("delete! clears state for every registered plugin", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          { 'test/plugin-a' },
          { 'test/plugin-b' },
          { 'test/plugin-c' },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()

      local state = require('zpack.state')
      helpers.assert_equal(#state.registered_plugins, 3, "3 plugins registered before delete!")

      vim.cmd('ZPack! delete')
      helpers.flush_pending()

      helpers.assert_equal(#state.registered_plugins, 0, "registered_plugins should be empty after delete!")
      helpers.assert_nil(next(state.spec_registry), "spec_registry should be empty after delete!")
      helpers.assert_nil(next(state.src_to_pack_spec), "src_to_pack_spec should be empty after delete!")

      helpers.cleanup_test_env()
    end)

    helpers.test("delete! also wipes state for cond-disabled plugins", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          { 'test/plugin-a' },
          { 'test/plugin-b', cond = false },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()

      local state = require('zpack.state')
      local src_b = 'https://github.com/test/plugin-b'
      -- A cond-disabled plugin is installed and tracked in spec_registry, but
      -- never reaches registered_plugins -- the set delete! used to wipe.
      helpers.assert_equal(#state.registered_plugins, 1, "cond-disabled plugin is not in registered_plugins")
      helpers.assert_not_nil(state.spec_registry[src_b], "cond-disabled plugin has a registry entry")

      vim.cmd('ZPack! delete')
      helpers.flush_pending()

      helpers.assert_nil(next(state.spec_registry), "delete! should wipe spec_registry, including cond-disabled plugins")
      helpers.assert_nil(next(state.src_to_pack_spec), "src_to_pack_spec should be empty after delete!")

      helpers.cleanup_test_env()
    end)

    helpers.test("delete without bang and no arg shows warning", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          { 'test/plugin-a' },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()

      vim.cmd('ZPack delete')
      helpers.flush_pending()

      helpers.assert_equal(#_G.test_state.vim_pack_del_calls, 0, "vim.pack.del should not be called")

      helpers.cleanup_test_env()
    end)

    helpers.test("delete clears dependency graph entries for deleted plugin", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          { 'test/plugin-a', dependencies = { 'test/plugin-b' } },
          { 'test/plugin-b', dependencies = { 'test/plugin-c' } },
          { 'test/plugin-c' },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()

      local state = require('zpack.state')
      local src_b = 'https://github.com/test/plugin-b'
      local src_a = 'https://github.com/test/plugin-a'
      local src_c = 'https://github.com/test/plugin-c'
      helpers.assert_not_nil(state.dependency_graph[src_b], "plugin-b should have dependency graph entry")
      helpers.assert_not_nil(state.reverse_dependency_graph[src_b], "plugin-b should have reverse dependency graph entry")

      vim.cmd('ZPack delete plugin-b')
      helpers.flush_pending()

      helpers.assert_nil(state.dependency_graph[src_b], "plugin-b dependency graph entry should be cleared")
      helpers.assert_nil(state.reverse_dependency_graph[src_b], "plugin-b reverse dependency graph entry should be cleared")

      local a_deps = state.dependency_graph[src_a]
      if a_deps then
        helpers.assert_nil(a_deps[src_b], "plugin-b should be removed from plugin-a's dependencies")
      end

      local c_rdeps = state.reverse_dependency_graph[src_c]
      if c_rdeps then
        helpers.assert_nil(c_rdeps[src_b], "plugin-b should be removed from plugin-c's reverse dependencies")
      end

      helpers.cleanup_test_env()
    end)

    helpers.test("delete clears src_to_pack_spec for deleted plugin", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          { 'test/plugin-a' },
          { 'test/plugin-b' },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()

      local state = require('zpack.state')
      local src_a = 'https://github.com/test/plugin-a'
      local src_b = 'https://github.com/test/plugin-b'
      helpers.assert_not_nil(state.src_to_pack_spec[src_a], "plugin-a should have src_to_pack_spec entry")

      vim.cmd('ZPack delete plugin-a')
      helpers.flush_pending()

      helpers.assert_nil(state.src_to_pack_spec[src_a], "plugin-a src_to_pack_spec entry should be cleared")
      helpers.assert_not_nil(state.src_to_pack_spec[src_b], "plugin-b src_to_pack_spec entry should remain")

      helpers.cleanup_test_env()
    end)

    helpers.test("external vim.pack.del syncs zpack state via PackChanged", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          { 'test/plugin-a' },
          { 'test/plugin-b' },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()

      local state = require('zpack.state')
      local src_a = 'https://github.com/test/plugin-a'
      local src_b = 'https://github.com/test/plugin-b'
      helpers.assert_not_nil(state.spec_registry[src_a], "plugin-a should be registered")
      helpers.assert_table_contains(state.registered_plugin_names, 'plugin-a', "plugin-a should be in registered names")

      -- Simulate :packdel / a direct vim.pack.del call, bypassing :ZPack delete.
      vim.pack.del({ 'plugin-a' })
      helpers.flush_pending()

      helpers.assert_nil(state.spec_registry[src_a], "plugin-a should be removed from registry")
      helpers.assert_not_nil(state.spec_registry[src_b], "plugin-b should remain registered")

      local still_listed = false
      for _, name in ipairs(state.registered_plugin_names) do
        if name == 'plugin-a' then
          still_listed = true
        end
      end
      helpers.assert_false(still_listed, "plugin-a should no longer be in registered names")

      helpers.cleanup_test_env()
    end)

    helpers.test("firing a deleted lazy plugin's trigger does not error or load it", function()
      helpers.setup_test_env()
      local loaded = false

      require('zpack').setup({
        spec = {
          {
            'test/plugin-a',
            cmd = 'TestCommand',
            config = function()
              loaded = true
            end,
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()

      helpers.assert_not_nil(
        vim.api.nvim_get_commands({}).TestCommand,
        "lazy cmd trigger should be registered before deletion"
      )

      -- Remove the plugin while its lazy trigger is still live.
      vim.pack.del({ 'plugin-a' })
      helpers.flush_pending()

      local ok = pcall(vim.cmd, 'TestCommand')
      helpers.flush_pending()

      helpers.assert_true(ok, "firing a deleted lazy plugin's command should not error")
      helpers.assert_false(loaded, "deleted lazy plugin should not load when its trigger fires")

      helpers.cleanup_test_env()
    end)

    helpers.test("delete non-existent plugin does not call vim.pack.del", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          { 'test/plugin-a' },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()

      vim.cmd('ZPack delete non-existent-plugin')
      helpers.flush_pending()

      helpers.assert_equal(#_G.test_state.vim_pack_del_calls, 0, "vim.pack.del should not be called for non-existent plugin")

      local found_error = false
      for _, notif in ipairs(_G.test_state.notifications) do
        if notif.msg:find('not installed') and notif.level == vim.log.levels.ERROR then
          found_error = true
          break
        end
      end
      helpers.assert_true(found_error, "should notify error for non-existent plugin")

      helpers.cleanup_test_env()
    end)
  end)
end
