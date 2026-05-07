local helpers = require('helpers')

return function()
  helpers.describe("Lazy Loading - Keymaps", function()
    helpers.test("KeySpec supports string shorthand", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          {
            'test/plugin',
            keys = '<leader>tk',
            config = function() end,
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local keymaps = vim.api.nvim_get_keymap('n')
      local found = false
      for _, map in ipairs(keymaps) do
        if map.lhs == ' tk' then
          found = true
          break
        end
      end
      helpers.assert_true(found, "String key should create keymap")

      helpers.cleanup_test_env()
    end)

    helpers.test("KeySpec supports table format with desc", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          {
            'test/plugin',
            keys = {
              { '<leader>td', function() end, desc = 'Test description' },
            },
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local keymaps = vim.api.nvim_get_keymap('n')
      local found_with_desc = false
      for _, map in ipairs(keymaps) do
        if map.lhs == ' td' and map.desc == 'Test description' then
          found_with_desc = true
          break
        end
      end
      helpers.assert_true(found_with_desc, "KeySpec should create keymap with description")

      helpers.cleanup_test_env()
    end)

    helpers.test("KeySpec supports custom modes", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          {
            'test/plugin',
            keys = {
              { '<leader>tv', function() end, mode = { 'n', 'v' } },
            },
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local normal_maps = vim.api.nvim_get_keymap('n')
      local visual_maps = vim.api.nvim_get_keymap('v')

      local found_in_normal = false
      local found_in_visual = false

      for _, map in ipairs(normal_maps) do
        if map.lhs == ' tv' then
          found_in_normal = true
          break
        end
      end

      for _, map in ipairs(visual_maps) do
        if map.lhs == ' tv' then
          found_in_visual = true
          break
        end
      end

      helpers.assert_true(found_in_normal, "KeySpec should create keymap in normal mode")
      helpers.assert_true(found_in_visual, "KeySpec should create keymap in visual mode")

      helpers.cleanup_test_env()
    end)

    helpers.test("lazy keys plugin does not load at startup", function()
      helpers.setup_test_env()
      local state = require('zpack.state')

      require('zpack').setup({
        spec = {
          {
            'test/plugin',
            keys = '<leader>tl',
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local src = 'https://github.com/test/plugin'
      helpers.assert_equal(
        state.spec_registry[src].load_status,
        "pending",
        "Lazy keys plugin should not be loaded at startup"
      )

      helpers.cleanup_test_env()
    end)

    helpers.test("KeySpec forwards expr=true", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          {
            'test/plugin',
            lazy = false,
            keys = {
              { '<leader>te', function() return 'foo' end, expr = true },
            },
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local keymaps = vim.api.nvim_get_keymap('n')
      local found = false
      for _, map in ipairs(keymaps) do
        if map.lhs == ' te' then
          found = true
          helpers.assert_equal(map.expr, 1, "expr should be forwarded to vim.keymap.set")
          break
        end
      end
      helpers.assert_true(found, "Eager KeySpec should create keymap")

      helpers.cleanup_test_env()
    end)

    helpers.test("KeySpec expr=true: rhs return value is fed as keys", function()
      helpers.setup_test_env()

      local target_hits = 0
      vim.keymap.set('n', 'gxxq', function() target_hits = target_hits + 1 end)

      local rhs_called = 0
      require('zpack').setup({
        spec = {
          {
            'test/plugin',
            lazy = false,
            keys = {
              -- remap=true so the returned 'gxxq' goes through the target mapping below.
              { 'gxxe', function() rhs_called = rhs_called + 1; return 'gxxq' end, expr = true, remap = true },
            },
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      vim.api.nvim_feedkeys('gxxe', 'mx', false)
      helpers.assert_equal(rhs_called, 1, "expr rhs should be invoked when lhs is fed")
      helpers.assert_equal(target_hits, 1, "rhs return value should be replayed as keys")

      pcall(vim.keymap.del, 'n', 'gxxe')
      pcall(vim.keymap.del, 'n', 'gxxq')
      helpers.cleanup_test_env()
    end)

    helpers.test("KeySpec forwards silent=true", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          {
            'test/plugin',
            lazy = false,
            keys = {
              { '<leader>ts', function() end, silent = true },
            },
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local keymaps = vim.api.nvim_get_keymap('n')
      local found = false
      for _, map in ipairs(keymaps) do
        if map.lhs == ' ts' then
          found = true
          helpers.assert_equal(map.silent, 1, "silent should be forwarded to vim.keymap.set")
          break
        end
      end
      helpers.assert_true(found, "Eager KeySpec should create keymap")

      helpers.cleanup_test_env()
    end)

    helpers.test("KeySpec forwards noremap=true", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          {
            'test/plugin',
            lazy = false,
            keys = {
              { '<leader>tn', function() end, noremap = true },
            },
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local keymaps = vim.api.nvim_get_keymap('n')
      local found = false
      for _, map in ipairs(keymaps) do
        if map.lhs == ' tn' then
          found = true
          helpers.assert_equal(map.noremap, 1, "noremap should be forwarded to vim.keymap.set")
          break
        end
      end
      helpers.assert_true(found, "Eager KeySpec should create keymap")

      helpers.cleanup_test_env()
    end)

    -- vim.keymap.set ignores `noremap` and derives it from `remap`. Without the
    -- alias translation in keymap.lua, the keymap below would still come out
    -- non-remappable (noremap=1) because `remap` defaults to false.
    helpers.test("KeySpec forwards noremap=false (lazy.nvim alias for remap=true)", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          {
            'test/plugin',
            lazy = false,
            keys = {
              { '<leader>tnf', function() end, noremap = false },
            },
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local keymaps = vim.api.nvim_get_keymap('n')
      local found = false
      for _, map in ipairs(keymaps) do
        if map.lhs == ' tnf' then
          found = true
          helpers.assert_equal(map.noremap, 0, "noremap=false should produce a remappable keymap")
          break
        end
      end
      helpers.assert_true(found, "Eager KeySpec should create keymap")

      helpers.cleanup_test_env()
    end)

    -- Explicit `remap` should win over `noremap` when both are set.
    helpers.test("KeySpec: explicit remap takes precedence over noremap alias", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          {
            'test/plugin',
            lazy = false,
            keys = {
              { '<leader>tnp', function() end, remap = true, noremap = true },
            },
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local keymaps = vim.api.nvim_get_keymap('n')
      local found = false
      for _, map in ipairs(keymaps) do
        if map.lhs == ' tnp' then
          found = true
          helpers.assert_equal(map.noremap, 0, "remap=true wins; resulting keymap should be remappable")
          break
        end
      end
      helpers.assert_true(found, "Eager KeySpec should create keymap")

      helpers.cleanup_test_env()
    end)

    helpers.test("KeySpec forwards replace_keycodes=true with expr", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          {
            'test/plugin',
            lazy = false,
            keys = {
              { '<leader>tr', function() return '<Esc>' end, expr = true, replace_keycodes = true },
            },
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local keymaps = vim.api.nvim_get_keymap('n')
      local found = false
      for _, map in ipairs(keymaps) do
        if map.lhs == ' tr' then
          found = true
          helpers.assert_equal(map.expr, 1, "expr should be forwarded")
          helpers.assert_equal(map.replace_keycodes, 1, "replace_keycodes should be forwarded")
          break
        end
      end
      helpers.assert_true(found, "Eager KeySpec should create keymap")

      helpers.cleanup_test_env()
    end)

    helpers.test("Lazy proxy keymap is not expr", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          {
            'test/plugin',
            keys = {
              { '<leader>tx', function() return 'foo' end, expr = true },
            },
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local keymaps = vim.api.nvim_get_keymap('n')
      local found = false
      for _, map in ipairs(keymaps) do
        if map.lhs == ' tx' then
          found = true
          helpers.assert_equal(map.expr, 0, "Lazy proxy mapping must not be expr")
          break
        end
      end
      helpers.assert_true(found, "Lazy proxy keymap should be installed")

      helpers.cleanup_test_env()
    end)

    helpers.test("KeySpec forwards remap=true alone", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          {
            'test/plugin',
            lazy = false,
            keys = {
              { '<leader>tra', function() end, remap = true },
            },
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local keymaps = vim.api.nvim_get_keymap('n')
      local found = false
      for _, map in ipairs(keymaps) do
        if map.lhs == ' tra' then
          found = true
          helpers.assert_equal(map.noremap, 0, "remap=true should produce a remappable keymap")
          break
        end
      end
      helpers.assert_true(found, "Eager KeySpec should create keymap")

      helpers.cleanup_test_env()
    end)

    helpers.test("KeySpec defaults replace_keycodes to true when expr=true", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          {
            'test/plugin',
            lazy = false,
            keys = {
              { '<leader>trd', function() return '<Esc>' end, expr = true },
            },
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local keymaps = vim.api.nvim_get_keymap('n')
      local found = false
      for _, map in ipairs(keymaps) do
        if map.lhs == ' trd' then
          found = true
          helpers.assert_equal(map.expr, 1, "expr should be forwarded")
          helpers.assert_equal(map.replace_keycodes, 1, "replace_keycodes should default to true when expr=true")
          break
        end
      end
      helpers.assert_true(found, "Eager KeySpec should create keymap")

      helpers.cleanup_test_env()
    end)

    helpers.test("Lazy proxy keymap forwards nowait=true", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          {
            'test/plugin',
            keys = {
              { '<leader>tw', function() end, nowait = true },
            },
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local keymaps = vim.api.nvim_get_keymap('n')
      local found = false
      for _, map in ipairs(keymaps) do
        if map.lhs == ' tw' then
          found = true
          helpers.assert_equal(map.nowait, 1, "Lazy proxy should forward nowait")
          break
        end
      end
      helpers.assert_true(found, "Lazy proxy keymap should be installed")

      helpers.cleanup_test_env()
    end)

    helpers.test("Lazy proxy keymap forwards silent=true", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          {
            'test/plugin',
            keys = {
              { '<leader>tsl', function() end, silent = true },
            },
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local keymaps = vim.api.nvim_get_keymap('n')
      local found = false
      for _, map in ipairs(keymaps) do
        if map.lhs == ' tsl' then
          found = true
          helpers.assert_equal(map.silent, 1, "Lazy proxy should forward silent")
          break
        end
      end
      helpers.assert_true(found, "Lazy proxy keymap should be installed")

      helpers.cleanup_test_env()
    end)

    helpers.test("KeySpec preserves explicit replace_keycodes=false override", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          {
            'test/plugin',
            lazy = false,
            keys = {
              { '<leader>tro', function() return '<Esc>' end, expr = true, replace_keycodes = false },
            },
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local keymaps = vim.api.nvim_get_keymap('n')
      local found = false
      for _, map in ipairs(keymaps) do
        if map.lhs == ' tro' then
          found = true
          helpers.assert_equal(map.expr, 1, "expr should be forwarded")
          helpers.assert_equal(map.replace_keycodes, 0, "explicit replace_keycodes=false must override the expr-implied default")
          break
        end
      end
      helpers.assert_true(found, "Eager KeySpec should create keymap")

      helpers.cleanup_test_env()
    end)

    helpers.test("Lazy proxy keymap forwards remap=true", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          {
            'test/plugin',
            keys = {
              { '<leader>txr', function() end, remap = true },
            },
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local keymaps = vim.api.nvim_get_keymap('n')
      local found = false
      for _, map in ipairs(keymaps) do
        if map.lhs == ' txr' then
          found = true
          helpers.assert_equal(map.noremap, 0, "Lazy proxy should reflect remap=true (noremap=0)")
          break
        end
      end
      helpers.assert_true(found, "Lazy proxy keymap should be installed")

      helpers.cleanup_test_env()
    end)

    helpers.test("Lazy proxy keymap translates noremap=false alias", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          {
            'test/plugin',
            keys = {
              { '<leader>txn', function() end, noremap = false },
            },
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local keymaps = vim.api.nvim_get_keymap('n')
      local found = false
      for _, map in ipairs(keymaps) do
        if map.lhs == ' txn' then
          found = true
          helpers.assert_equal(map.noremap, 0, "Lazy proxy should translate noremap=false to remap=true")
          break
        end
      end
      helpers.assert_true(found, "Lazy proxy keymap should be installed")

      helpers.cleanup_test_env()
    end)

    -- vim.keymap.set raises if replace_keycodes is set without expr. The opts
    -- whitelist used to forward replace_keycodes unconditionally, which would
    -- crash apply_keys for a user spec like { lhs, rhs, replace_keycodes = true }.
    helpers.test("KeySpec drops replace_keycodes when expr is unset", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          {
            'test/plugin',
            lazy = false,
            keys = {
              { '<leader>trk', function() end, replace_keycodes = true },
            },
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()
      local keymaps = vim.api.nvim_get_keymap('n')
      local found = false
      for _, map in ipairs(keymaps) do
        if map.lhs == ' trk' then
          found = true
          helpers.assert_equal(map.expr, 0, "expr should not be implied")
          helpers.assert_equal(map.replace_keycodes, 0, "replace_keycodes should be dropped when expr is unset")
          break
        end
      end
      helpers.assert_true(found, "Eager KeySpec should create keymap without crashing")

      helpers.cleanup_test_env()
    end)

    -- Covers the post-trigger apply_keys path (plugin_loader.lua → apply_keys),
    -- which the eager `lazy = false` tests above don't exercise. After the proxy
    -- fires and the plugin loads, the real keymap must carry the user's opts.
    helpers.test("Lazy proxy load handoff: real keymap forwards silent and noremap alias", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          {
            'test/plugin',
            keys = {
              { '<leader>tlh', function() end, silent = true, noremap = false },
            },
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()

      local function find_map(lhs)
        for _, map in ipairs(vim.api.nvim_get_keymap('n')) do
          if map.lhs == lhs then return map end
        end
        return nil
      end

      vim.api.nvim_feedkeys(' tlh', 'mx', false)
      helpers.flush_pending()

      local real = find_map(' tlh')
      helpers.assert_not_nil(real, "Real keymap should exist after lazy proxy fires")
      helpers.assert_equal(real.silent, 1, "Post-load real keymap should forward silent=true")
      helpers.assert_equal(real.noremap, 0, "Post-load real keymap should reflect noremap=false alias")

      helpers.cleanup_test_env()
    end)

    helpers.test("Lazy proxy load handoff installs the real expr keymap", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          {
            'test/plugin',
            keys = {
              { '<leader>txp', function() return '' end, expr = true },
            },
          },
        },
        defaults = { confirm = false },
      })

      helpers.flush_pending()

      local function find_map(lhs)
        for _, map in ipairs(vim.api.nvim_get_keymap('n')) do
          if map.lhs == lhs then return map end
        end
        return nil
      end

      local proxy = find_map(' txp')
      helpers.assert_not_nil(proxy, "Proxy keymap should be installed")
      helpers.assert_equal(proxy.expr, 0, "Proxy must not be expr")

      vim.api.nvim_feedkeys(' txp', 'mx', false)
      helpers.flush_pending()

      local real = find_map(' txp')
      helpers.assert_not_nil(real, "Real keymap should exist after lazy proxy fires")
      helpers.assert_equal(real.expr, 1, "Post-load real keymap should be expr=true")

      helpers.cleanup_test_env()
    end)
  end)
end
