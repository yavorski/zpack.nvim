---@diagnostic disable: duplicate-set-field
local helpers = require('helpers')

return function()
  helpers.describe("Version Normalization", function()
    helpers.test("version field takes priority over other version fields", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          {
            'test/plugin',
            version = 'main',
            branch = 'develop',
            tag = 'v1.0.0',
          },
        },
        defaults = { confirm = false },
      })

      local vim_pack_call = _G.test_state.vim_pack_calls[1]
      helpers.assert_not_nil(vim_pack_call, "vim.pack.add should have been called")
      helpers.assert_equal(vim_pack_call[1].version, 'main', "version field should take priority")

      helpers.cleanup_test_env()
    end)

    helpers.test("sem_version field is wrapped with vim.version.range()", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          {
            'test/plugin',
            sem_version = '^6',
          },
        },
        defaults = { confirm = false },
      })

      local vim_pack_call = _G.test_state.vim_pack_calls[1]
      helpers.assert_not_nil(vim_pack_call, "vim.pack.add should have been called")

      local version = vim_pack_call[1].version
      helpers.assert_not_nil(version, "version should be set")
      helpers.assert_equal(type(version), 'table', "sem_version should be converted to vim.VersionRange")
      helpers.assert_not_nil(version.from, "vim.VersionRange should have 'from' field")

      helpers.cleanup_test_env()
    end)

    helpers.test("branch field maps to version", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          {
            'test/plugin',
            branch = 'develop',
          },
        },
        defaults = { confirm = false },
      })

      local vim_pack_call = _G.test_state.vim_pack_calls[1]
      helpers.assert_not_nil(vim_pack_call, "vim.pack.add should have been called")
      helpers.assert_equal(vim_pack_call[1].version, 'develop', "branch should map to version")

      helpers.cleanup_test_env()
    end)

    helpers.test("tag field maps to version", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          {
            'test/plugin',
            tag = 'v1.0.0',
          },
        },
        defaults = { confirm = false },
      })

      local vim_pack_call = _G.test_state.vim_pack_calls[1]
      helpers.assert_not_nil(vim_pack_call, "vim.pack.add should have been called")
      helpers.assert_equal(vim_pack_call[1].version, 'v1.0.0', "tag should map to version")

      helpers.cleanup_test_env()
    end)

    helpers.test("commit field maps to version", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          {
            'test/plugin',
            commit = 'abc123def',
          },
        },
        defaults = { confirm = false },
      })

      local vim_pack_call = _G.test_state.vim_pack_calls[1]
      helpers.assert_not_nil(vim_pack_call, "vim.pack.add should have been called")
      helpers.assert_equal(vim_pack_call[1].version, 'abc123def', "commit should map to version")

      helpers.cleanup_test_env()
    end)

    helpers.test("sem_version takes priority over branch/tag/commit", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          {
            'test/plugin',
            sem_version = '^1.0.0',
            branch = 'main',
            tag = 'v1.0.0',
            commit = 'abc123',
          },
        },
        defaults = { confirm = false },
      })

      local vim_pack_call = _G.test_state.vim_pack_calls[1]
      helpers.assert_not_nil(vim_pack_call, "vim.pack.add should have been called")

      local version = vim_pack_call[1].version
      helpers.assert_equal(type(version), 'table', "sem_version should be used and converted to vim.VersionRange")

      helpers.cleanup_test_env()
    end)

    helpers.test("branch takes priority over tag and commit", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          {
            'test/plugin',
            branch = 'develop',
            tag = 'v1.0.0',
            commit = 'abc123',
          },
        },
        defaults = { confirm = false },
      })

      local vim_pack_call = _G.test_state.vim_pack_calls[1]
      helpers.assert_not_nil(vim_pack_call, "vim.pack.add should have been called")
      helpers.assert_equal(vim_pack_call[1].version, 'develop', "branch should take priority over tag and commit")

      helpers.cleanup_test_env()
    end)

    helpers.test("tag takes priority over commit", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          {
            'test/plugin',
            tag = 'v2.0.0',
            commit = 'abc123',
          },
        },
        defaults = { confirm = false },
      })

      local vim_pack_call = _G.test_state.vim_pack_calls[1]
      helpers.assert_not_nil(vim_pack_call, "vim.pack.add should have been called")
      helpers.assert_equal(vim_pack_call[1].version, 'v2.0.0', "tag should take priority over commit")

      helpers.cleanup_test_env()
    end)

    helpers.test("no version fields results in nil version", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          { 'test/plugin' },
        },
        defaults = { confirm = false },
      })

      local vim_pack_call = _G.test_state.vim_pack_calls[1]
      helpers.assert_not_nil(vim_pack_call, "vim.pack.add should have been called")
      helpers.assert_nil(vim_pack_call[1].version, "version should be nil when no version fields provided")

      helpers.cleanup_test_env()
    end)

    helpers.test("vim.VersionRange passed directly through version field", function()
      helpers.setup_test_env()

      local range = vim.version.range('^6')
      require('zpack').setup({
        spec = {
          {
            'test/plugin',
            version = range,
          },
        },
        defaults = { confirm = false },
      })

      local vim_pack_call = _G.test_state.vim_pack_calls[1]
      helpers.assert_not_nil(vim_pack_call, "vim.pack.add should have been called")
      helpers.assert_equal(vim_pack_call[1].version, range, "vim.VersionRange should be passed through directly")

      helpers.cleanup_test_env()
    end)

    helpers.test("semver-like version emits warning when vim.pack.add fails", function()
      helpers.setup_test_env()

      local mock_vim_pack_add = vim.pack.add
      vim.pack.add = function()
        error("some error from vim.pack.add")
      end

      local ok = pcall(function()
        require('zpack').setup({
          spec = {
            {
              'test/plugin',
              version = '1.*',
            },
          },
          defaults = { confirm = false },
        })
      end)

      helpers.assert_equal(ok, false, "setup should fail when vim.pack.add throws")
      helpers.assert_equal(#_G.test_state.notifications >= 2, true, "header and detail warnings should be emitted")

      local found_header = false
      local found_detail = false
      for _, notif in ipairs(_G.test_state.notifications) do
        if notif.msg:match('`vim%.pack%.add` failed') then
          found_header = true
        end
        if notif.msg:match('sem_version') and notif.msg:match('1%.%*') then
          found_detail = true
        end
      end
      helpers.assert_equal(found_header, true, "should have header mentioning vim.pack.add failed")
      helpers.assert_equal(found_detail, true, "should have detail mentioning sem_version")

      vim.pack.add = mock_vim_pack_add
      helpers.cleanup_test_env()
    end)

    helpers.test("multiple semver-like versions emit multiple warnings", function()
      helpers.setup_test_env()

      local mock_vim_pack_add = vim.pack.add
      vim.pack.add = function()
        error("some error from vim.pack.add")
      end

      local ok = pcall(function()
        require('zpack').setup({
          spec = {
            { 'test/plugin-a', version = '1.*' },
            { 'test/plugin-b', version = '^2.0.0' },
            { 'test/plugin-c', version = 'main' },
          },
          defaults = { confirm = false },
        })
      end)

      helpers.assert_equal(ok, false, "setup should fail when vim.pack.add throws")

      local found_header = false
      local detail_count = 0
      local found_plugin_a = false
      local found_plugin_b = false
      for _, notif in ipairs(_G.test_state.notifications) do
        if notif.msg:match('`vim%.pack%.add` failed') then
          found_header = true
        end
        if notif.msg:match('sem_version') then
          detail_count = detail_count + 1
          if notif.msg:match('1%.%*') and notif.msg:match('plugin%-a') then
            found_plugin_a = true
          end
          if notif.msg:match('%^2%.0%.0') and notif.msg:match('plugin%-b') then
            found_plugin_b = true
          end
        end
      end

      helpers.assert_equal(found_header, true, "should have single header message")
      helpers.assert_equal(detail_count, 2, "should emit exactly 2 detail warnings for semver-like versions")
      helpers.assert_equal(found_plugin_a, true, "should warn about plugin-a with 1.*")
      helpers.assert_equal(found_plugin_b, true, "should warn about plugin-b with ^2.0.0")

      vim.pack.add = mock_vim_pack_add
      helpers.cleanup_test_env()
    end)

    helpers.test("no warning when vim.pack.add fails but no semver-like versions", function()
      helpers.setup_test_env()

      local mock_vim_pack_add = vim.pack.add
      vim.pack.add = function()
        error("some error from vim.pack.add")
      end

      local ok = pcall(function()
        require('zpack').setup({
          spec = {
            {
              'test/plugin',
              version = 'nonexistent-branch',
            },
          },
          defaults = { confirm = false },
        })
      end)

      helpers.assert_equal(ok, false, "setup should fail when vim.pack.add throws")

      local found_warning = false
      for _, notif in ipairs(_G.test_state.notifications) do
        if notif.msg:match('sem_version') then
          found_warning = true
          break
        end
      end
      helpers.assert_equal(found_warning, false, "no warning should be emitted for non-semver-like versions")

      vim.pack.add = mock_vim_pack_add
      helpers.cleanup_test_env()
    end)
  end)
end
