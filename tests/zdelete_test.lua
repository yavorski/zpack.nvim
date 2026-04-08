local helpers = require('helpers')

return function()
  helpers.describe("ZDelete Command", function()
    helpers.test("ZDelete single plugin uses force=true", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          { 'test/plugin-a' },
          { 'test/plugin-b' },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()

      vim.cmd('ZDelete plugin-a')
      helpers.flush_pending()

      helpers.assert_equal(#_G.test_state.vim_pack_del_calls, 1, "vim.pack.del should be called once")
      local call = _G.test_state.vim_pack_del_calls[1]
      helpers.assert_not_nil(call.opts, "opts should be passed to vim.pack.del")
      helpers.assert_true(call.opts.force, "force option should be true")
      helpers.assert_table_contains(call.names, 'plugin-a', "plugin-a should be in delete list")

      helpers.cleanup_test_env()
    end)

    helpers.test("ZDelete! all plugins uses force=true", function()
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

      vim.cmd('ZDelete!')
      helpers.flush_pending()

      helpers.assert_equal(#_G.test_state.vim_pack_del_calls, 1, "vim.pack.del should be called once")
      local call = _G.test_state.vim_pack_del_calls[1]
      helpers.assert_not_nil(call.opts, "opts should be passed to vim.pack.del")
      helpers.assert_true(call.opts.force, "force option should be true")
      helpers.assert_equal(#call.names, 4, "all 4 plugins (3 + zpack.nvim) should be in delete list")
      helpers.assert_table_contains(call.names, 'zpack.nvim', "zpack.nvim should be in delete list")

      helpers.cleanup_test_env()
    end)

    helpers.test("ZDelete without bang and no arg shows warning", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          { 'test/plugin-a' },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()

      vim.cmd('ZDelete')
      helpers.flush_pending()

      helpers.assert_equal(#_G.test_state.vim_pack_del_calls, 0, "vim.pack.del should not be called")

      helpers.cleanup_test_env()
    end)

    helpers.test("ZDelete clears dependency graph entries for deleted plugin", function()
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

      vim.cmd('ZDelete plugin-b')
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

    helpers.test("ZDelete clears src_to_pack_spec for deleted plugin", function()
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

      vim.cmd('ZDelete plugin-a')
      helpers.flush_pending()

      helpers.assert_nil(state.src_to_pack_spec[src_a], "plugin-a src_to_pack_spec entry should be cleared")
      helpers.assert_not_nil(state.src_to_pack_spec[src_b], "plugin-b src_to_pack_spec entry should remain")

      helpers.cleanup_test_env()
    end)

    helpers.test("ZDelete non-existent plugin does not call vim.pack.del", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          { 'test/plugin-a' },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()

      vim.cmd('ZDelete non-existent-plugin')
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
