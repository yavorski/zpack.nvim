local helpers = require('helpers')

return function()
  helpers.describe("ZLoad Command", function()
    helpers.test("ZLoad command is created with default prefix", function()
      helpers.setup_test_env()

      require('zpack').setup({ spec = {}, defaults = { confirm = false } })

      local cmds = vim.api.nvim_get_commands({})
      helpers.assert_not_nil(cmds['ZLoad'], "ZLoad command should exist")

      helpers.cleanup_test_env()
      helpers.delete_zpack_commands()
    end)

    helpers.test("lazy plugin is tracked as unloaded", function()
      helpers.setup_test_env()
      local state = require('zpack.state')

      require('zpack').setup({
        spec = {
          {
            'test/lazy-plugin',
            cmd = 'TestCommand',
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      helpers.assert_true(
        state.unloaded_plugin_names['lazy-plugin'] == true,
        "Lazy plugin should be tracked as unloaded"
      )

      helpers.cleanup_test_env()
      helpers.delete_zpack_commands()
    end)

    helpers.test("startup plugin is not tracked as unloaded", function()
      helpers.setup_test_env()
      local state = require('zpack.state')

      require('zpack').setup({
        spec = {
          {
            'test/startup-plugin',
            config = function() end,
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      helpers.assert_nil(
        state.unloaded_plugin_names['startup-plugin'],
        "Startup plugin should not be in unloaded list"
      )

      helpers.cleanup_test_env()
      helpers.delete_zpack_commands()
    end)

    helpers.test("plugin is removed from unloaded list when loaded", function()
      helpers.setup_test_env()
      local state = require('zpack.state')

      require('zpack').setup({
        spec = {
          {
            'test/lazy-plugin',
            cmd = 'TestCommand',
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      helpers.assert_true(
        state.unloaded_plugin_names['lazy-plugin'] == true,
        "Plugin should be unloaded initially"
      )

      pcall(vim.cmd, 'TestCommand')
      helpers.flush_pending()

      helpers.assert_nil(
        state.unloaded_plugin_names['lazy-plugin'],
        "Plugin should be removed from unloaded list after loading"
      )

      helpers.cleanup_test_env()
      helpers.delete_zpack_commands()
    end)

    helpers.test("ZLoad without bang shows warning", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          {
            'test/lazy-plugin',
            cmd = 'TestCommand',
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      _G.test_state.notifications = {}

      pcall(vim.cmd, 'ZLoad')
      helpers.flush_pending()

      local found_warning = false
      for _, notif in ipairs(_G.test_state.notifications) do
        if notif.msg:find('ZLoad!') and notif.level == vim.log.levels.WARN then
          found_warning = true
          break
        end
      end
      helpers.assert_true(found_warning, "Should show warning about using ZLoad!")

      helpers.cleanup_test_env()
      helpers.delete_zpack_commands()
    end)

    helpers.test("ZLoad! loads all unloaded plugins", function()
      helpers.setup_test_env()
      local state = require('zpack.state')
      local config_called = {}

      require('zpack').setup({
        spec = {
          {
            'test/plugin-a',
            cmd = 'TestA',
            config = function() config_called['plugin-a'] = true end,
          },
          {
            'test/plugin-b',
            cmd = 'TestB',
            config = function() config_called['plugin-b'] = true end,
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      helpers.assert_equal(vim.tbl_count(state.unloaded_plugin_names), 2, "Should have 2 unloaded plugins")

      vim.cmd('ZLoad!')
      helpers.flush_pending()

      helpers.assert_equal(vim.tbl_count(state.unloaded_plugin_names), 0, "Should have 0 unloaded plugins")
      helpers.assert_true(config_called['plugin-a'], "Plugin A config should be called")
      helpers.assert_true(config_called['plugin-b'], "Plugin B config should be called")

      helpers.cleanup_test_env()
      helpers.delete_zpack_commands()
    end)

    helpers.test("ZLoad! with no unloaded plugins shows info message", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          {
            'test/startup-plugin',
            config = function() end,
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      _G.test_state.notifications = {}

      vim.cmd('ZLoad!')
      helpers.flush_pending()

      local found_info = false
      for _, notif in ipairs(_G.test_state.notifications) do
        if notif.msg:find('All plugins are already loaded') and notif.level == vim.log.levels.INFO then
          found_info = true
          break
        end
      end
      helpers.assert_true(found_info, "Should show info that all plugins are loaded")

      helpers.cleanup_test_env()
      helpers.delete_zpack_commands()
    end)

    helpers.test("ZLoad already loaded plugin shows info message", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          {
            'test/startup-plugin',
            config = function() end,
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      _G.test_state.notifications = {}

      pcall(vim.cmd, 'ZLoad startup-plugin')
      helpers.flush_pending()

      local found_info = false
      for _, notif in ipairs(_G.test_state.notifications) do
        if notif.msg:find('already loaded') and notif.level == vim.log.levels.INFO then
          found_info = true
          break
        end
      end
      helpers.assert_true(found_info, "Should show info that plugin is already loaded")

      helpers.cleanup_test_env()
      helpers.delete_zpack_commands()
    end)
  end)
end
