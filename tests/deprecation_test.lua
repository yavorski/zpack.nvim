local helpers = require('helpers')

return function()
  helpers.describe("Deprecated Options", function()
    helpers.test("deprecated confirm option shows warning", function()
      helpers.setup_test_env()

      require('zpack').setup({ spec = {}, confirm = false })

      helpers.flush_pending()

      local found_deprecation = false
      for _, notif in ipairs(_G.test_state.notifications) do
        if notif.msg:find("DEPRECATED") and notif.msg:find("confirm") then
          found_deprecation = true
          break
        end
      end

      helpers.assert_true(found_deprecation, "Should show deprecation warning for confirm")

      helpers.cleanup_test_env()
    end)

    helpers.test("deprecated disable_vim_loader option shows warning", function()
      helpers.setup_test_env()

      require('zpack').setup({ spec = {}, disable_vim_loader = true })

      helpers.flush_pending()

      local found_deprecation = false
      for _, notif in ipairs(_G.test_state.notifications) do
        if notif.msg:find("DEPRECATED") and notif.msg:find("disable_vim_loader") then
          found_deprecation = true
          break
        end
      end

      helpers.assert_true(found_deprecation, "Should show deprecation warning for disable_vim_loader")

      helpers.cleanup_test_env()
    end)

    helpers.test("deprecated plugins_dir option shows warning", function()
      helpers.setup_test_env()

      require('zpack').setup({ plugins_dir = 'my_plugins' })

      helpers.flush_pending()

      local found_deprecation = false
      for _, notif in ipairs(_G.test_state.notifications) do
        if notif.msg:find("DEPRECATED") and notif.msg:find("plugins_dir") then
          found_deprecation = true
          break
        end
      end

      helpers.assert_true(found_deprecation, "Should show deprecation warning for plugins_dir")

      helpers.cleanup_test_env()
    end)

    helpers.test("invoking legacy :Z* commands emits the cmd_prefix deprecation warning once", function()
      helpers.setup_test_env()

      require('zpack').setup({ spec = { { 'test/plugin-a' } }, defaults = { confirm = false } })

      helpers.flush_pending()
      _G.test_state.notifications = {}

      vim.cmd('ZClean')
      vim.cmd('ZUpdate') -- a *different* legacy command must NOT re-emit the warning
      helpers.flush_pending()

      local count = 0
      for _, notif in ipairs(_G.test_state.notifications) do
        if notif.msg:find("DEPRECATED") and notif.msg:find("cmd_prefix") then
          count = count + 1
        end
      end
      helpers.assert_equal(count, 1, "deprecation warning must fire exactly once across all legacy commands")

      helpers.cleanup_test_env()
    end)

    helpers.test("legacy :ZDelete delegates to the new delete subcommand with force=true", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = { { 'test/plugin-a' }, { 'test/plugin-b' } },
        defaults = { confirm = false },
      })

      helpers.flush_pending()

      vim.cmd('ZDelete plugin-a')
      helpers.flush_pending()

      helpers.assert_equal(#_G.test_state.vim_pack_del_calls, 1, "vim.pack.del must be called by legacy shim")
      local call = _G.test_state.vim_pack_del_calls[1]
      helpers.assert_true(call.opts.force, "legacy :ZDelete must propagate force=true to Sub.delete")
      helpers.assert_table_contains(call.names, 'plugin-a', "legacy :ZDelete plugin-a must target plugin-a")

      helpers.cleanup_test_env()
    end)

    helpers.test("deprecated options still register plugins", function()
      helpers.setup_test_env()
      local state = require('zpack.state')

      require('zpack').setup({
        spec = { { 'test/plugin' } },
        confirm = false,
      })

      helpers.flush_pending()

      local src = 'https://github.com/test/plugin'
      helpers.assert_not_nil(state.spec_registry[src], "Plugin should be registered")

      helpers.cleanup_test_env()
    end)
  end)
end
