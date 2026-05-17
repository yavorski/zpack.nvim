local helpers = require('helpers')

return function()
  helpers.describe("Command Name Configuration", function()
    helpers.test("default cmd_name creates :ZPack command", function()
      helpers.setup_test_env()

      require('zpack').setup({ spec = {}, defaults = { confirm = false } })

      local cmds = vim.api.nvim_get_commands({})
      helpers.assert_not_nil(cmds['ZPack'], "ZPack command should exist")

      helpers.cleanup_test_env()
    end)

    helpers.test("custom cmd_name creates the configured command", function()
      helpers.setup_test_env()

      require('zpack').setup({ spec = {}, defaults = { confirm = false }, cmd_name = 'Pack' })

      local cmds = vim.api.nvim_get_commands({})
      helpers.assert_not_nil(cmds['Pack'], "Pack command should exist")
      helpers.assert_nil(cmds['ZPack'], "Default ZPack command should not exist with custom name")

      helpers.cleanup_test_env()
      helpers.delete_zpack_commands('Pack')
    end)

    helpers.test("subcommand completion lists available subcommands", function()
      helpers.setup_test_env()

      require('zpack').setup({ spec = {}, defaults = { confirm = false } })

      local completions = vim.fn.getcompletion('ZPack ', 'cmdline')
      helpers.assert_table_contains(completions, 'update', "update subcommand")
      helpers.assert_table_contains(completions, 'restore', "restore subcommand")
      helpers.assert_table_contains(completions, 'clean', "clean subcommand")
      helpers.assert_table_contains(completions, 'build', "build subcommand")
      helpers.assert_table_contains(completions, 'load', "load subcommand")
      helpers.assert_table_contains(completions, 'delete', "delete subcommand")

      helpers.cleanup_test_env()
    end)

    helpers.test("empty cmd_name is rejected", function()
      helpers.setup_test_env()

      require('zpack').setup({ spec = {}, defaults = { confirm = false }, cmd_name = '' })

      local cmds = vim.api.nvim_get_commands({})
      helpers.assert_nil(cmds['ZPack'], "ZPack command should not exist when cmd_name rejected")

      helpers.cleanup_test_env()
    end)

    helpers.test("lowercase cmd_name is rejected", function()
      helpers.setup_test_env()

      require('zpack').setup({ spec = {}, defaults = { confirm = false }, cmd_name = 'pack' })

      local cmds = vim.api.nvim_get_commands({})
      helpers.assert_nil(cmds['pack'], "Commands with lowercase name should not be created")
      helpers.assert_nil(cmds['ZPack'], "Default command should not be created")

      helpers.cleanup_test_env()
    end)

    helpers.test("cmd_name with hyphen is rejected", function()
      helpers.setup_test_env()

      require('zpack').setup({ spec = {}, defaults = { confirm = false }, cmd_name = 'My-Pack' })

      local cmds = vim.api.nvim_get_commands({})
      helpers.assert_nil(cmds['My-Pack'], "Command with hyphen should not be created")
      helpers.assert_nil(cmds['ZPack'], "Default command should not be created")

      helpers.cleanup_test_env()
    end)

    helpers.test("cmd_name starting with digit is rejected", function()
      helpers.setup_test_env()

      require('zpack').setup({ spec = {}, defaults = { confirm = false }, cmd_name = '123' })

      local cmds = vim.api.nvim_get_commands({})
      helpers.assert_nil(cmds['123'], "Command starting with digit should not be created")
      helpers.assert_nil(cmds['ZPack'], "Default command should not be created")

      helpers.cleanup_test_env()
    end)

    helpers.test("cmd_name with special characters is rejected", function()
      helpers.setup_test_env()

      require('zpack').setup({ spec = {}, defaults = { confirm = false }, cmd_name = 'Pack!' })

      local cmds = vim.api.nvim_get_commands({})
      helpers.assert_nil(cmds['Pack!'], "Command with special char should not be created")
      helpers.assert_nil(cmds['ZPack'], "Default command should not be created")

      helpers.cleanup_test_env()
    end)

    helpers.test("cmd_name with whitespace is rejected", function()
      helpers.setup_test_env()

      require('zpack').setup({ spec = {}, defaults = { confirm = false }, cmd_name = ' Z' })

      local cmds = vim.api.nvim_get_commands({})
      helpers.assert_nil(cmds[' Z'], "Command with whitespace should not be created")
      helpers.assert_nil(cmds['ZPack'], "Default command should not be created")

      helpers.cleanup_test_env()
    end)

    helpers.test("cmd_name with digits after first letter is valid", function()
      helpers.setup_test_env()

      require('zpack').setup({ spec = {}, defaults = { confirm = false }, cmd_name = 'Z2' })

      local cmds = vim.api.nvim_get_commands({})
      helpers.assert_not_nil(cmds['Z2'], "Z2 command should exist")

      helpers.cleanup_test_env()
      helpers.delete_zpack_commands('Z2')
    end)
  end)
end
