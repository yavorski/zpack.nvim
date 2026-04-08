local helpers = require('helpers')

return function()
  helpers.describe("Command Prefix Configuration", function()
    helpers.test("default prefix creates Z-prefixed commands", function()
      helpers.setup_test_env()

      require('zpack').setup({ spec = {}, defaults = { confirm = false } })

      local cmds = vim.api.nvim_get_commands({})
      helpers.assert_not_nil(cmds['ZUpdate'], "ZUpdate command should exist")
      helpers.assert_not_nil(cmds['ZClean'], "ZClean command should exist")
      helpers.assert_not_nil(cmds['ZBuild'], "ZBuild command should exist")
      helpers.assert_not_nil(cmds['ZLoad'], "ZLoad command should exist")
      helpers.assert_not_nil(cmds['ZRestore'], "ZRestore command should exist")
      helpers.assert_not_nil(cmds['ZDelete'], "ZDelete command should exist")

      helpers.cleanup_test_env()
    end)

    helpers.test("custom prefix creates correctly prefixed commands", function()
      helpers.setup_test_env()

      require('zpack').setup({ spec = {}, defaults = { confirm = false }, cmd_prefix = 'Pack' })

      local cmds = vim.api.nvim_get_commands({})
      helpers.assert_not_nil(cmds['PackUpdate'], "PackUpdate command should exist")
      helpers.assert_not_nil(cmds['PackClean'], "PackClean command should exist")
      helpers.assert_not_nil(cmds['PackBuild'], "PackBuild command should exist")
      helpers.assert_not_nil(cmds['PackLoad'], "PackLoad command should exist")
      helpers.assert_not_nil(cmds['PackRestore'], "PackRestore command should exist")
      helpers.assert_not_nil(cmds['PackDelete'], "PackDelete command should exist")

      helpers.assert_nil(cmds['ZUpdate'], "ZUpdate command should not exist with custom prefix")
      helpers.assert_nil(cmds['ZClean'], "ZClean command should not exist with custom prefix")
      helpers.assert_nil(cmds['ZBuild'], "ZBuild command should not exist with custom prefix")
      helpers.assert_nil(cmds['ZLoad'], "ZLoad command should not exist with custom prefix")
      helpers.assert_nil(cmds['ZRestore'], "ZRestore command should not exist with custom prefix")
      helpers.assert_nil(cmds['ZDelete'], "ZDelete command should not exist with custom prefix")

      helpers.cleanup_test_env()
      helpers.delete_zpack_commands('Pack')
    end)

    helpers.test("empty prefix creates commands without prefix", function()
      helpers.setup_test_env()

      require('zpack').setup({ spec = {}, defaults = { confirm = false }, cmd_prefix = '' })

      local cmds = vim.api.nvim_get_commands({})
      helpers.assert_not_nil(cmds['Update'], "Update command should exist")
      helpers.assert_not_nil(cmds['Clean'], "Clean command should exist")
      helpers.assert_not_nil(cmds['Build'], "Build command should exist")
      helpers.assert_not_nil(cmds['Load'], "Load command should exist")
      helpers.assert_not_nil(cmds['Restore'], "Restore command should exist")
      helpers.assert_not_nil(cmds['Delete'], "Delete command should exist")

      helpers.cleanup_test_env()
      helpers.delete_zpack_commands('')
    end)

    helpers.test("lowercase prefix is rejected", function()
      helpers.setup_test_env()

      require('zpack').setup({ spec = {}, defaults = { confirm = false }, cmd_prefix = 'pack' })

      local cmds = vim.api.nvim_get_commands({})
      helpers.assert_nil(cmds['packUpdate'], "Commands should not be created with lowercase prefix")
      helpers.assert_nil(cmds['ZUpdate'], "Default commands should not be created")

      helpers.cleanup_test_env()
    end)

    helpers.test("prefix with hyphen is rejected", function()
      helpers.setup_test_env()

      require('zpack').setup({ spec = {}, defaults = { confirm = false }, cmd_prefix = 'My-Pack' })

      local cmds = vim.api.nvim_get_commands({})
      helpers.assert_nil(cmds['My-PackUpdate'], "Commands should not be created with hyphen prefix")
      helpers.assert_nil(cmds['ZUpdate'], "Default commands should not be created")

      helpers.cleanup_test_env()
    end)

    helpers.test("prefix starting with digit is rejected", function()
      helpers.setup_test_env()

      require('zpack').setup({ spec = {}, defaults = { confirm = false }, cmd_prefix = '123' })

      local cmds = vim.api.nvim_get_commands({})
      helpers.assert_nil(cmds['123Update'], "Commands should not be created with digit prefix")
      helpers.assert_nil(cmds['ZUpdate'], "Default commands should not be created")

      helpers.cleanup_test_env()
    end)

    helpers.test("prefix with special characters is rejected", function()
      helpers.setup_test_env()

      require('zpack').setup({ spec = {}, defaults = { confirm = false }, cmd_prefix = 'Pack!' })

      local cmds = vim.api.nvim_get_commands({})
      helpers.assert_nil(cmds['Pack!Update'], "Commands should not be created with special char prefix")
      helpers.assert_nil(cmds['ZUpdate'], "Default commands should not be created")

      helpers.cleanup_test_env()
    end)

    helpers.test("prefix with whitespace is rejected", function()
      helpers.setup_test_env()

      require('zpack').setup({ spec = {}, defaults = { confirm = false }, cmd_prefix = ' Z' })

      local cmds = vim.api.nvim_get_commands({})
      helpers.assert_nil(cmds[' ZUpdate'], "Commands should not be created with whitespace prefix")
      helpers.assert_nil(cmds['ZUpdate'], "Default commands should not be created")

      helpers.cleanup_test_env()
    end)

    helpers.test("prefix with digits after first letter is valid", function()
      helpers.setup_test_env()

      require('zpack').setup({ spec = {}, defaults = { confirm = false }, cmd_prefix = 'Z2' })

      local cmds = vim.api.nvim_get_commands({})
      helpers.assert_not_nil(cmds['Z2Update'], "Z2Update command should exist")
      helpers.assert_not_nil(cmds['Z2Clean'], "Z2Clean command should exist")
      helpers.assert_not_nil(cmds['Z2Build'], "Z2Build command should exist")
      helpers.assert_not_nil(cmds['Z2Load'], "Z2Load command should exist")
      helpers.assert_not_nil(cmds['Z2Restore'], "Z2Restore command should exist")
      helpers.assert_not_nil(cmds['Z2Delete'], "Z2Delete command should exist")

      helpers.cleanup_test_env()
      helpers.delete_zpack_commands('Z2')
    end)
  end)
end
