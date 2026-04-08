local helpers = require('helpers')

return function()
  helpers.describe("is_single_spec heuristic", function()
    helpers.test("single spec with string source and opts is detected", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          { 'test/plugin', opts = { foo = true } },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local state = require('zpack.state')
      local entry = state.spec_registry['https://github.com/test/plugin']

      helpers.assert_not_nil(entry, "plugin should be registered")
      helpers.assert_equal(entry.merged_spec.opts.foo, true, "opts should be preserved")

      helpers.cleanup_test_env()
    end)

    helpers.test("list of bare string specs is treated as list", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          { 'test/plugin-a' },
          { 'test/plugin-b' },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local state = require('zpack.state')

      helpers.assert_not_nil(state.spec_registry['https://github.com/test/plugin-a'])
      helpers.assert_not_nil(state.spec_registry['https://github.com/test/plugin-b'])

      helpers.cleanup_test_env()
    end)

    helpers.test("single dependency spec with opts preserves all fields", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          {
            'test/parent',
            dependencies = {
              'test/dep',
              init = function() _G._test_dep_init_called = true end,
              opts = { select = { lookahead = true } },
            },
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local state = require('zpack.state')
      local dep_entry = state.spec_registry['https://github.com/test/dep']

      helpers.assert_not_nil(dep_entry, "dependency should be registered")
      helpers.assert_not_nil(dep_entry.merged_spec.opts, "opts should be preserved on dependency")
      helpers.assert_equal(dep_entry.merged_spec.opts.select.lookahead, true,
        "opts fields should be preserved")
      helpers.assert_not_nil(dep_entry.merged_spec.init, "init should be preserved on dependency")

      _G._test_dep_init_called = nil
      helpers.cleanup_test_env()
    end)

    helpers.test("list of string dependencies are all registered", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          {
            'test/parent',
            dependencies = { 'test/dep-a', 'test/dep-b' },
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local state = require('zpack.state')

      helpers.assert_not_nil(state.spec_registry['https://github.com/test/dep-a'],
        "first string dep should be registered")
      helpers.assert_not_nil(state.spec_registry['https://github.com/test/dep-b'],
        "second string dep should be registered")

      helpers.cleanup_test_env()
    end)

    helpers.test("list of table specs is treated as list", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          { 'test/plugin-a', opts = {} },
          { 'test/plugin-b', opts = { bar = true } },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local state = require('zpack.state')

      helpers.assert_not_nil(state.spec_registry['https://github.com/test/plugin-a'],
        "first spec should be registered")
      helpers.assert_not_nil(state.spec_registry['https://github.com/test/plugin-b'],
        "second spec should be registered")

      helpers.cleanup_test_env()
    end)

    helpers.test("single dependency with config preserves config function", function()
      helpers.setup_test_env()
      local config_called = false

      require('zpack').setup({
        spec = {
          {
            'test/parent',
            dependencies = {
              'test/dep-with-config',
              config = function() config_called = true end,
            },
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local state = require('zpack.state')
      local dep_entry = state.spec_registry['https://github.com/test/dep-with-config']

      helpers.assert_not_nil(dep_entry, "dependency should be registered")
      helpers.assert_not_nil(dep_entry.merged_spec.config, "config should be preserved on dependency")

      helpers.cleanup_test_env()
    end)
  end)
end
