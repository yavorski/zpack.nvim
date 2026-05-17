local helpers = require('helpers')

local M = {}

function M.create_tests(config)
  local command = config.command
  local expected_opts = config.expected_opts
  local error_prefix = config.error_prefix

  return function()
    helpers.describe(command, function()
      helpers.test(command .. " without args calls vim.pack.update correctly", function()
        helpers.setup_test_env()

        require('zpack').setup({
          spec = {
            { 'test/plugin-a' },
            { 'test/plugin-b' },
          },
          defaults = { confirm = false },
        })

        helpers.flush_pending()

        vim.cmd(command)
        helpers.flush_pending()

        helpers.assert_equal(#_G.test_state.vim_pack_update_calls, 1, "vim.pack.update should be called once")
        local call = _G.test_state.vim_pack_update_calls[1]
        helpers.assert_nil(call.names, "names should be nil for all")
        if expected_opts then
          helpers.assert_not_nil(call.opts, "opts should be passed")
          for k, v in pairs(expected_opts) do
            helpers.assert_equal(call.opts[k], v, ("opts.%s should be '%s'"):format(k, v))
          end
        else
          helpers.assert_nil(call.opts, "opts should be nil")
        end

        helpers.cleanup_test_env()
      end)

      helpers.test(command .. " with plugin name targets that plugin", function()
        helpers.setup_test_env()

        require('zpack').setup({
          spec = {
            { 'test/plugin-a' },
            { 'test/plugin-b' },
          },
          defaults = { confirm = false },
        })

        helpers.flush_pending()

        vim.cmd(command .. ' plugin-a')
        helpers.flush_pending()

        helpers.assert_equal(#_G.test_state.vim_pack_update_calls, 1, "vim.pack.update should be called once")
        local call = _G.test_state.vim_pack_update_calls[1]
        helpers.assert_not_nil(call.names, "names should be provided")
        helpers.assert_table_contains(call.names, 'plugin-a', "plugin-a should be in names list")
        if expected_opts then
          for k, v in pairs(expected_opts) do
            helpers.assert_equal(call.opts[k], v, ("opts.%s should be '%s'"):format(k, v))
          end
        else
          helpers.assert_nil(call.opts, "opts should be nil")
        end

        helpers.cleanup_test_env()
      end)

      helpers.test(command .. " with registered but not installed plugin still calls vim.pack.update", function()
        helpers.setup_test_env()

        require('zpack').setup({
          spec = {
            { 'test/plugin-a' },
            { 'test/plugin-b' },
          },
          defaults = { confirm = false },
        })

        helpers.flush_pending()

        _G.test_state.registered_pack_specs['plugin-a'] = nil

        vim.cmd(command .. ' plugin-a')
        helpers.flush_pending()

        helpers.assert_equal(#_G.test_state.vim_pack_update_calls, 1, "vim.pack.update should be called once")
        local call = _G.test_state.vim_pack_update_calls[1]
        helpers.assert_not_nil(call.names, "names should be provided")
        helpers.assert_table_contains(call.names, 'plugin-a', "plugin-a should be in names list")

        helpers.cleanup_test_env()
      end)

      helpers.test(command .. " with plugin not in spec shows error", function()
        helpers.setup_test_env()

        require('zpack').setup({
          spec = {
            { 'test/plugin-a' },
          },
          defaults = { confirm = false },
        })

        helpers.flush_pending()

        vim.cmd(command .. ' non-existent-plugin')
        helpers.flush_pending()

        helpers.assert_equal(#_G.test_state.vim_pack_update_calls, 0, "vim.pack.update should not be called")

        local found_error = false
        for _, notif in ipairs(_G.test_state.notifications) do
          if notif.msg:find('not found in spec') and notif.level == vim.log.levels.ERROR then
            found_error = true
            break
          end
        end
        helpers.assert_true(found_error, "should notify error for plugin not in spec")

        helpers.cleanup_test_env()
      end)

      helpers.test(command .. " tab completion returns registered plugin names", function()
        helpers.setup_test_env()

        require('zpack').setup({
          spec = {
            { 'test/plugin-a' },
            { 'test/plugin-b' },
          },
          defaults = { confirm = false },
        })

        helpers.flush_pending()

        local completions = vim.fn.getcompletion(command .. ' ', 'cmdline')
        helpers.assert_table_contains(completions, 'plugin-a', "should complete plugin-a")
        helpers.assert_table_contains(completions, 'plugin-b', "should complete plugin-b")

        helpers.cleanup_test_env()
      end)

      if expected_opts and expected_opts.target == 'lockfile' then
        helpers.test(command .. " shows error when no lockfile exists", function()
          helpers.setup_test_env()

          require('zpack').setup({
            spec = {
              { 'test/plugin-a' },
            },
            defaults = { confirm = false },
          })

          helpers.flush_pending()

          local call_log = _G.test_state.vim_pack_update_calls
          local prev_update = vim.pack.update
          vim.pack.update = function(names, opts)
            table.insert(call_log, { names = names, opts = opts })
            error("no lockfile found")
          end

          vim.cmd(command)
          vim.pack.update = prev_update
          helpers.flush_pending()

          local found_error = false
          for _, notif in ipairs(_G.test_state.notifications) do
            if notif.msg:find(error_prefix) and notif.msg:find('lockfile') and notif.level == vim.log.levels.ERROR then
              found_error = true
              break
            end
          end
          helpers.assert_true(found_error, "should notify error when no lockfile exists")

          helpers.cleanup_test_env()
        end)
      end

      helpers.test(command .. " shows friendly error when vim.pack.update fails", function()
        helpers.setup_test_env()

        require('zpack').setup({
          spec = {
            { 'test/plugin-a' },
          },
          defaults = { confirm = false },
        })

        helpers.flush_pending()

        local call_log = _G.test_state.vim_pack_update_calls
        local prev_update = vim.pack.update
        vim.pack.update = function(names, opts)
          table.insert(call_log, { names = names, opts = opts })
          error("simulated failure")
        end

        vim.cmd(command)
        vim.pack.update = prev_update
        helpers.flush_pending()

        local found_error = false
        for _, notif in ipairs(_G.test_state.notifications) do
          if notif.msg:find(error_prefix) and notif.level == vim.log.levels.ERROR then
            found_error = true
            break
          end
        end
        helpers.assert_true(found_error, "should notify friendly error when vim.pack.update fails")

        helpers.cleanup_test_env()
      end)
    end)
  end
end

return M
