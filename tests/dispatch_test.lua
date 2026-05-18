local helpers = require('helpers')

return function()
  helpers.describe(":ZPack subcommand dispatch", function()
    helpers.test("a bang on a non-bang subcommand warns and does not run", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = { { 'test/plugin-a' } },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      _G.test_state.notifications = {}

      -- An installed plugin absent from the spec gives `clean` something to
      -- delete, so a wrongly-accepted bang would surface as a non-zero
      -- vim_pack_del_calls below.
      _G.test_state.registered_pack_specs['orphan-plugin'] = {
        src = 'test/orphan-plugin',
        name = 'orphan-plugin',
      }

      vim.cmd('ZPack! clean')
      helpers.flush_pending()

      helpers.assert_equal(#_G.test_state.vim_pack_del_calls, 0, "clean must not run when given a rejected bang")

      local found_warning = false
      for _, notif in ipairs(_G.test_state.notifications) do
        if notif.msg:find('does not accept') and notif.level == vim.log.levels.WARN then
          found_warning = true
          break
        end
      end
      helpers.assert_true(found_warning, "should warn that clean does not accept a bang")

      helpers.cleanup_test_env()
    end)

    helpers.test("extra positional arguments warn and do not run", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = { { 'test/plugin-a' } },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      _G.test_state.notifications = {}

      vim.cmd('ZPack update plugin-a extra-arg')
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
      helpers.assert_true(found_warning, "should warn about too many arguments")
      helpers.assert_false(misleading_error, 'must not emit the misleading joined-args "not found in spec" error')

      helpers.cleanup_test_env()
    end)

    helpers.test("clean rejects positional arguments", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = { { 'test/plugin-a' } },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      _G.test_state.notifications = {}

      vim.cmd('ZPack clean junk')
      helpers.flush_pending()

      local found_warning = false
      local clean_ran = false
      for _, notif in ipairs(_G.test_state.notifications) do
        if notif.msg:find('no arguments') and notif.level == vim.log.levels.WARN then
          found_warning = true
        end
        if notif.msg:find('unused plugin') then
          clean_ran = true
        end
      end
      helpers.assert_true(found_warning, "should warn that clean accepts no arguments")
      helpers.assert_false(clean_ran, "clean must not run when given arguments")

      helpers.cleanup_test_env()
    end)

    helpers.test("completion after a bang-attached subcommand targets its arguments", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = { { 'test/lazy-plugin', cmd = 'TestCommand' } },
        defaults = { confirm = false },
      })

      helpers.flush_pending()

      local completions = vim.fn.getcompletion('ZPack!load ', 'cmdline')
      helpers.assert_table_contains(completions, 'lazy-plugin',
        "':ZPack!load ' should complete unloaded plugin names, not subcommands")

      helpers.cleanup_test_env()
    end)
  end)
end
