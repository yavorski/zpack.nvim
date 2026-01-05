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
      helpers.delete_zpack_commands()
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
      helpers.assert_equal(#call.names, 3, "all 3 plugins should be in delete list")

      helpers.cleanup_test_env()
      helpers.delete_zpack_commands()
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
      helpers.delete_zpack_commands()
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
        if notif.msg:find('not found') and notif.level == vim.log.levels.ERROR then
          found_error = true
          break
        end
      end
      helpers.assert_true(found_error, "should notify error for non-existent plugin")

      helpers.cleanup_test_env()
      helpers.delete_zpack_commands()
    end)
  end)
end
