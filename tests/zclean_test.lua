local helpers = require('helpers')

return function()
  helpers.describe("ZClean Command", function()
    helpers.test("ZClean detects orphan plugins not in spec", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          { 'test/plugin-a' },
          { 'test/plugin-b' },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()

      _G.test_state.registered_pack_specs['orphan-plugin'] = {
        src = 'test/orphan-plugin',
        name = 'orphan-plugin',
      }

      vim.cmd('ZClean')
      helpers.flush_pending()

      helpers.assert_equal(#_G.test_state.vim_pack_del_calls, 1, "vim.pack.del should be called")
      local call = _G.test_state.vim_pack_del_calls[1]
      helpers.assert_table_contains(call.names, 'orphan-plugin', "orphan plugin should be in delete list")
      helpers.assert_equal(#call.names, 1, "only orphan plugin should be deleted")

      helpers.cleanup_test_env()
      helpers.delete_zpack_commands()
    end)

    helpers.test("ZClean does not delete plugins in spec", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          { 'test/plugin-a' },
          { 'test/plugin-b' },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()

      vim.cmd('ZClean')
      helpers.flush_pending()

      helpers.assert_equal(#_G.test_state.vim_pack_del_calls, 0, "vim.pack.del should not be called")

      local found_info = false
      for _, notif in ipairs(_G.test_state.notifications) do
        if notif.msg:find('No unused plugins') and notif.level == vim.log.levels.INFO then
          found_info = true
          break
        end
      end
      helpers.assert_true(found_info, "Should show info that no unused plugins exist")

      helpers.cleanup_test_env()
      helpers.delete_zpack_commands()
    end)

    helpers.test("ZClean detects multiple orphan plugins", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          { 'test/plugin-a' },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()

      _G.test_state.registered_pack_specs['orphan-1'] = {
        src = 'test/orphan-1',
        name = 'orphan-1',
      }
      _G.test_state.registered_pack_specs['orphan-2'] = {
        src = 'test/orphan-2',
        name = 'orphan-2',
      }

      vim.cmd('ZClean')
      helpers.flush_pending()

      helpers.assert_equal(#_G.test_state.vim_pack_del_calls, 1, "vim.pack.del should be called once")
      local call = _G.test_state.vim_pack_del_calls[1]
      helpers.assert_equal(#call.names, 2, "both orphan plugins should be deleted")

      helpers.cleanup_test_env()
      helpers.delete_zpack_commands()
    end)
  end)
end
