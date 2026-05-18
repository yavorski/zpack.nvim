local helpers = require('helpers')

return function()
  helpers.describe("Legacy cmd_prefix Commands (deprecated)", function()
    helpers.test("default prefix registers Z-prefixed legacy commands", function()
      helpers.setup_test_env()

      require('zpack').setup({ spec = {}, defaults = { confirm = false } })

      local cmds = vim.api.nvim_get_commands({})
      helpers.assert_not_nil(cmds['ZUpdate'], "ZUpdate command should exist")
      helpers.assert_not_nil(cmds['ZRestore'], "ZRestore command should exist")
      helpers.assert_not_nil(cmds['ZClean'], "ZClean command should exist")
      helpers.assert_not_nil(cmds['ZBuild'], "ZBuild command should exist")
      helpers.assert_not_nil(cmds['ZLoad'], "ZLoad command should exist")
      helpers.assert_not_nil(cmds['ZDelete'], "ZDelete command should exist")

      helpers.cleanup_test_env()
    end)

    helpers.test("custom cmd_prefix registers prefixed legacy commands", function()
      helpers.setup_test_env()

      require('zpack').setup({ spec = {}, defaults = { confirm = false }, cmd_prefix = 'Pack' })

      local cmds = vim.api.nvim_get_commands({})
      helpers.assert_not_nil(cmds['PackUpdate'], "PackUpdate command should exist")
      helpers.assert_not_nil(cmds['PackDelete'], "PackDelete command should exist")
      helpers.assert_nil(cmds['ZUpdate'], "default ZUpdate should not exist with a custom prefix")

      helpers.cleanup_test_env()
      helpers.delete_zpack_commands(nil, 'Pack')
    end)

    helpers.test("empty cmd_prefix registers bare legacy commands", function()
      helpers.setup_test_env()

      require('zpack').setup({ spec = {}, defaults = { confirm = false }, cmd_prefix = '' })

      local cmds = vim.api.nvim_get_commands({})
      helpers.assert_not_nil(cmds['Update'], "Update command should exist")
      helpers.assert_not_nil(cmds['Delete'], "Delete command should exist")

      helpers.cleanup_test_env()
      helpers.delete_zpack_commands(nil, '')
    end)

    helpers.test("cmd_prefix with digits after the first letter is valid", function()
      helpers.setup_test_env()

      require('zpack').setup({ spec = {}, defaults = { confirm = false }, cmd_prefix = 'Z2' })

      local cmds = vim.api.nvim_get_commands({})
      helpers.assert_not_nil(cmds['Z2Update'], "Z2Update command should exist")
      helpers.assert_not_nil(cmds['Z2Delete'], "Z2Delete command should exist")

      helpers.cleanup_test_env()
      helpers.delete_zpack_commands(nil, 'Z2')
    end)

    helpers.test("invoking a legacy command warns with its :ZPack replacement", function()
      helpers.setup_test_env()

      require('zpack').setup({ spec = { { 'test/plugin-a' } }, defaults = { confirm = false } })

      helpers.flush_pending()
      _G.test_state.notifications = {}

      vim.cmd('ZClean')
      helpers.flush_pending()

      local found = false
      for _, notif in ipairs(_G.test_state.notifications) do
        if notif.msg:find(":ZClean is deprecated", 1, true)
          and notif.msg:find("Use :ZPack clean", 1, true) then
          found = true
          break
        end
      end
      helpers.assert_true(found, "invoking :ZClean should warn to use :ZPack clean")

      helpers.cleanup_test_env()
    end)

    helpers.test("legacy commands reference the configured cmd_name", function()
      helpers.setup_test_env()

      require('zpack').setup({ spec = {}, defaults = { confirm = false }, cmd_name = 'MyPack' })

      helpers.flush_pending()
      _G.test_state.notifications = {}

      vim.cmd('ZLoad') -- no bang, no arg -> warns "Use :<cmd_name>! load"
      helpers.flush_pending()

      local found = false
      for _, notif in ipairs(_G.test_state.notifications) do
        if notif.msg:find(':MyPack! load', 1, true) then
          found = true
          break
        end
      end
      helpers.assert_true(found, "legacy :ZLoad should point at the configured :MyPack command")

      helpers.cleanup_test_env()
      helpers.delete_zpack_commands('MyPack')
    end)

    helpers.test("legacy command with extra arguments warns like the dispatcher", function()
      helpers.setup_test_env()

      require('zpack').setup({ spec = { { 'test/plugin-a' } }, defaults = { confirm = false } })

      helpers.flush_pending()
      _G.test_state.notifications = {}

      vim.cmd('ZUpdate plugin-a extra-arg')
      helpers.flush_pending()

      helpers.assert_equal(#_G.test_state.vim_pack_update_calls, 0, "update must not run when given extra arguments")

      local found_warning = false
      local misleading_error = false
      for _, notif in ipairs(_G.test_state.notifications) do
        if notif.msg:find('at most one argument') and notif.level == vim.log.levels.WARN then
          found_warning = true
        end
        if notif.msg:find('not found in spec') then
          misleading_error = true
        end
      end
      helpers.assert_true(found_warning, "legacy :ZUpdate should warn about too many arguments")
      helpers.assert_false(misleading_error, 'legacy :ZUpdate must not emit the misleading joined-args error')

      helpers.cleanup_test_env()
    end)

    helpers.test("legacy clean rejects positional arguments without a raw Vim error", function()
      helpers.setup_test_env()

      require('zpack').setup({ spec = { { 'test/plugin-a' } }, defaults = { confirm = false } })

      helpers.flush_pending()
      _G.test_state.notifications = {}

      local ok = pcall(vim.cmd, 'ZClean junk')
      helpers.flush_pending()

      helpers.assert_true(ok, "legacy :ZClean junk must not raise a raw Vim parse error")

      local found_warning = false
      for _, notif in ipairs(_G.test_state.notifications) do
        if notif.msg:find('no arguments') and notif.level == vim.log.levels.WARN then
          found_warning = true
          break
        end
      end
      helpers.assert_true(found_warning, "legacy :ZClean should warn that clean accepts no arguments")

      helpers.cleanup_test_env()
    end)

    helpers.test("invalid cmd_prefix emits an error plus a deprecation notice and registers no legacy commands", function()
      helpers.setup_test_env()

      require('zpack').setup({ spec = {}, defaults = { confirm = false }, cmd_prefix = 'My-Pack' })

      helpers.flush_pending()

      local cmds = vim.api.nvim_get_commands({})
      helpers.assert_nil(cmds['My-PackUpdate'], "no legacy commands should be registered for an invalid prefix")
      helpers.assert_nil(cmds['ZUpdate'], "an invalid prefix should not fall back to the default Z prefix")
      helpers.assert_not_nil(cmds['ZPack'], "the primary :ZPack command should still be registered")

      local found_error = false
      local found_deprecation = false
      for _, notif in ipairs(_G.test_state.notifications) do
        if notif.msg:find('Invalid cmd_prefix') and notif.level == vim.log.levels.ERROR then
          found_error = true
        end
        if notif.msg:find('DEPRECATED') and notif.msg:find('cmd_prefix', 1, true)
          and notif.level == vim.log.levels.WARN then
          found_deprecation = true
        end
      end
      helpers.assert_true(found_error, "an invalid cmd_prefix should emit an error notification")
      helpers.assert_true(found_deprecation, "an invalid cmd_prefix should also emit the cmd_prefix deprecation notice")

      helpers.cleanup_test_env()
    end)

    helpers.test("non-string cmd_prefix does not abort setup", function()
      helpers.setup_test_env()

      local ok = pcall(require('zpack').setup, {
        spec = {},
        defaults = { confirm = false },
        cmd_prefix = {},
      })
      helpers.assert_true(ok, "setup() must not abort when cmd_prefix is not a string")

      helpers.flush_pending()

      local cmds = vim.api.nvim_get_commands({})
      helpers.assert_not_nil(cmds['ZPack'], "the primary :ZPack command should still be registered")

      local found_error = false
      for _, notif in ipairs(_G.test_state.notifications) do
        if notif.msg:find('Invalid cmd_prefix') and notif.level == vim.log.levels.ERROR then
          found_error = true
          break
        end
      end
      helpers.assert_true(found_error, "a non-string cmd_prefix should emit an error notification")

      helpers.cleanup_test_env()
    end)
  end)
end
