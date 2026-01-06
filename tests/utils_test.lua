local helpers = require('helpers')

return function()
  helpers.describe("lsdir utility", function()
    helpers.test("lsdir returns entries for existing directory", function()
      helpers.setup_test_env()

      local utils = require('zpack.utils')
      local entries = utils.lsdir(vim.fn.stdpath('config') .. '/lua')

      helpers.assert_equal(type(entries), 'table')

      helpers.cleanup_test_env()
    end)

    helpers.test("lsdir returns empty table for non-existent directory", function()
      helpers.setup_test_env()

      local utils = require('zpack.utils')
      local entries = utils.lsdir('/non/existent/path/that/does/not/exist')

      helpers.assert_equal(type(entries), 'table')
      helpers.assert_equal(#entries, 0)

      helpers.cleanup_test_env()
    end)

    helpers.test("lsdir caches results", function()
      helpers.setup_test_env()

      local utils = require('zpack.utils')
      local test_path = '/test/cache/path'

      local call_count = 0
      local original_fs_scandir = vim.uv.fs_scandir
      vim.uv.fs_scandir = function(path)
        if path == test_path then
          call_count = call_count + 1
          return nil
        end
        return original_fs_scandir(path)
      end

      utils.lsdir(test_path)
      utils.lsdir(test_path)
      utils.lsdir(test_path)

      helpers.assert_equal(call_count, 1, "fs_scandir should only be called once due to caching")

      vim.uv.fs_scandir = original_fs_scandir
      helpers.cleanup_test_env()
    end)

    helpers.test("lsdir entries have name and type", function()
      helpers.setup_test_env()

      local utils = require('zpack.utils')
      local original_fs_scandir = vim.uv.fs_scandir
      local original_fs_scandir_next = vim.uv.fs_scandir_next

      local call_idx = 0
      vim.uv.fs_scandir = function(path)
        if path == '/mock/dir' then
          return 'mock_handle'
        end
        return original_fs_scandir(path)
      end
      vim.uv.fs_scandir_next = function(handle)
        if handle == 'mock_handle' then
          call_idx = call_idx + 1
          if call_idx == 1 then
            return 'file.lua', 'file'
          elseif call_idx == 2 then
            return 'subdir', 'directory'
          end
          return nil
        end
        return original_fs_scandir_next(handle)
      end

      local entries = utils.lsdir('/mock/dir')

      helpers.assert_equal(#entries, 2)
      helpers.assert_equal(entries[1].name, 'file.lua')
      helpers.assert_equal(entries[1].type, 'file')
      helpers.assert_equal(entries[2].name, 'subdir')
      helpers.assert_equal(entries[2].type, 'directory')

      vim.uv.fs_scandir = original_fs_scandir
      vim.uv.fs_scandir_next = original_fs_scandir_next
      helpers.cleanup_test_env()
    end)

    helpers.test("reset_lsdir_cache clears cache", function()
      helpers.setup_test_env()

      local utils = require('zpack.utils')
      local test_path = '/test/reset/path'

      local call_count = 0
      local original_fs_scandir = vim.uv.fs_scandir
      vim.uv.fs_scandir = function(path)
        if path == test_path then
          call_count = call_count + 1
          return nil
        end
        return original_fs_scandir(path)
      end

      utils.lsdir(test_path)
      helpers.assert_equal(call_count, 1)

      utils.reset_lsdir_cache()
      utils.lsdir(test_path)
      helpers.assert_equal(call_count, 2, "fs_scandir should be called again after cache reset")

      vim.uv.fs_scandir = original_fs_scandir
      helpers.cleanup_test_env()
    end)
  end)

  helpers.describe("is_semver_like utility", function()
    helpers.test("detects wildcard patterns", function()
      helpers.setup_test_env()
      local utils = require('zpack.utils')

      helpers.assert_equal(utils.is_semver_like('1.*'), true)
      helpers.assert_equal(utils.is_semver_like('*'), true)
      helpers.assert_equal(utils.is_semver_like('1.2.*'), true)
      helpers.assert_equal(utils.is_semver_like('1.2.x'), true)
      helpers.assert_equal(utils.is_semver_like('1.x'), true)
      helpers.assert_equal(utils.is_semver_like('1.X'), true)
      helpers.assert_equal(utils.is_semver_like('1.2.X'), true)
      helpers.assert_equal(utils.is_semver_like('1.2.y'), true)
      helpers.assert_equal(utils.is_semver_like('1.a.b'), true)

      helpers.cleanup_test_env()
    end)

    helpers.test("detects range operators", function()
      helpers.setup_test_env()
      local utils = require('zpack.utils')

      helpers.assert_equal(utils.is_semver_like('>=1.0.0'), true)
      helpers.assert_equal(utils.is_semver_like('<=2.0.0'), true)
      helpers.assert_equal(utils.is_semver_like('>1.0'), true)
      helpers.assert_equal(utils.is_semver_like('<2.0'), true)
      helpers.assert_equal(utils.is_semver_like('^1.0.0'), true)
      helpers.assert_equal(utils.is_semver_like('~1.0.0'), true)
      helpers.assert_equal(utils.is_semver_like('foo=bar'), true)

      helpers.cleanup_test_env()
    end)

    helpers.test("detects bare semver patterns", function()
      helpers.setup_test_env()
      local utils = require('zpack.utils')

      helpers.assert_equal(utils.is_semver_like('1.0.0'), true)
      helpers.assert_equal(utils.is_semver_like('1.2'), true)
      helpers.assert_equal(utils.is_semver_like('1.2.3.4'), true)

      helpers.cleanup_test_env()
    end)

    helpers.test("returns false for branch/tag names", function()
      helpers.setup_test_env()
      local utils = require('zpack.utils')

      helpers.assert_equal(utils.is_semver_like('main'), false)
      helpers.assert_equal(utils.is_semver_like('master'), false)
      helpers.assert_equal(utils.is_semver_like('v1.0.0'), false)
      helpers.assert_equal(utils.is_semver_like('v1.x'), false)
      helpers.assert_equal(utils.is_semver_like('release-1.0'), false)
      helpers.assert_equal(utils.is_semver_like('feature/foo'), false)

      helpers.cleanup_test_env()
    end)

    helpers.test("returns false for non-strings", function()
      helpers.setup_test_env()
      local utils = require('zpack.utils')

      helpers.assert_equal(utils.is_semver_like(nil), false)
      helpers.assert_equal(utils.is_semver_like(123), false)
      helpers.assert_equal(utils.is_semver_like({}), false)

      helpers.cleanup_test_env()
    end)
  end)
end
