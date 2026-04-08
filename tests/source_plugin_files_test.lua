local helpers = require('helpers')

return function()
  helpers.describe("source_plugin_files", function()
    helpers.test("sources lua files from plugin/ directory", function()
      helpers.setup_test_env()

      local utils = require('zpack.utils')
      local tmpdir = vim.fn.tempname()
      local plugin_dir = tmpdir .. "/plugin"
      vim.fn.mkdir(plugin_dir, "p")

      local test_file = plugin_dir .. "/test_plugin.lua"
      local f = io.open(test_file, "w")
      f:write("_G._test_source_plugin_ran = true\n")
      f:close()

      _G._test_source_plugin_ran = nil
      utils.source_plugin_files(tmpdir)

      helpers.assert_true(_G._test_source_plugin_ran == true,
        "plugin/ lua file should be sourced")

      _G._test_source_plugin_ran = nil
      vim.fn.delete(tmpdir, "rf")
      helpers.cleanup_test_env()
    end)

    helpers.test("sources lua files from after/plugin/ directory", function()
      helpers.setup_test_env()

      local utils = require('zpack.utils')
      local tmpdir = vim.fn.tempname()
      local after_dir = tmpdir .. "/after/plugin"
      vim.fn.mkdir(after_dir, "p")

      local test_file = after_dir .. "/test_after.lua"
      local f = io.open(test_file, "w")
      f:write("_G._test_source_after_ran = true\n")
      f:close()

      _G._test_source_after_ran = nil
      utils.source_plugin_files(tmpdir)

      helpers.assert_true(_G._test_source_after_ran == true,
        "after/plugin/ lua file should be sourced")

      _G._test_source_after_ran = nil
      vim.fn.delete(tmpdir, "rf")
      helpers.cleanup_test_env()
    end)

    helpers.test("does not source same path twice", function()
      helpers.setup_test_env()

      local utils = require('zpack.utils')
      local tmpdir = vim.fn.tempname()
      local plugin_dir = tmpdir .. "/plugin"
      vim.fn.mkdir(plugin_dir, "p")

      local test_file = plugin_dir .. "/counter.lua"
      local f = io.open(test_file, "w")
      f:write("_G._test_source_count = (_G._test_source_count or 0) + 1\n")
      f:close()

      _G._test_source_count = nil
      utils.source_plugin_files(tmpdir)
      utils.source_plugin_files(tmpdir)

      helpers.assert_equal(_G._test_source_count, 1,
        "file should only be sourced once even with multiple calls")

      _G._test_source_count = nil
      vim.fn.delete(tmpdir, "rf")
      helpers.cleanup_test_env()
    end)

    helpers.test("handles missing directories gracefully", function()
      helpers.setup_test_env()

      local utils = require('zpack.utils')
      local tmpdir = vim.fn.tempname()
      vim.fn.mkdir(tmpdir, "p")

      -- Should not error when plugin/ and after/plugin/ don't exist
      local ok, err = pcall(utils.source_plugin_files, tmpdir)
      helpers.assert_true(ok, "should not error on missing directories: " .. tostring(err))

      vim.fn.delete(tmpdir, "rf")
      helpers.cleanup_test_env()
    end)

    helpers.test("skips non-lua non-vim files", function()
      helpers.setup_test_env()

      local utils = require('zpack.utils')
      local tmpdir = vim.fn.tempname()
      local plugin_dir = tmpdir .. "/plugin"
      vim.fn.mkdir(plugin_dir, "p")

      -- Create a .txt file that should be ignored
      local txt_file = plugin_dir .. "/readme.txt"
      local f = io.open(txt_file, "w")
      f:write("_G._test_txt_sourced = true\n")
      f:close()

      -- Create a .lua file that should be sourced
      local lua_file = plugin_dir .. "/real.lua"
      f = io.open(lua_file, "w")
      f:write("_G._test_lua_sourced = true\n")
      f:close()

      _G._test_txt_sourced = nil
      _G._test_lua_sourced = nil
      utils.source_plugin_files(tmpdir)

      helpers.assert_nil(_G._test_txt_sourced, ".txt file should not be sourced")
      helpers.assert_true(_G._test_lua_sourced == true, ".lua file should be sourced")

      _G._test_txt_sourced = nil
      _G._test_lua_sourced = nil
      vim.fn.delete(tmpdir, "rf")
      helpers.cleanup_test_env()
    end)
  end)
end
