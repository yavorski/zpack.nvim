local helpers = require('helpers')

local PLUGIN_INFO_KEYS = {
  name = true,
  src = true,
  status = true,
  lazy = true,
  path = true,
}

local function find_by_name(list, name)
  for _, info in ipairs(list) do
    if info.name == name then
      return info
    end
  end
  return nil
end

return function()
  helpers.describe("Public API (zpack.get_plugins / get_plugin)", function()
    helpers.test("get_plugins returns an entry for each registered plugin", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          { 'test/alpha' },
          { 'test/beta' },
        },
        defaults = { confirm = false },
      })
      helpers.flush_pending()

      local list = require('zpack').get_plugins()
      helpers.assert_not_nil(find_by_name(list, 'alpha'), "alpha should be in get_plugins()")
      helpers.assert_not_nil(find_by_name(list, 'beta'), "beta should be in get_plugins()")

      helpers.cleanup_test_env()
    end)

    helpers.test("get_plugins entry shape has name, src, status, lazy", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          { 'test/alpha' },
        },
        defaults = { confirm = false },
      })
      helpers.flush_pending()

      local info = find_by_name(require('zpack').get_plugins(), 'alpha')
      helpers.assert_not_nil(info, "alpha should be listed")
      helpers.assert_equal(info.name, 'alpha', "name should be resolved plugin name")
      helpers.assert_equal(info.src, 'https://github.com/test/alpha', "src should be git URL")
      helpers.assert_equal(info.status, 'loaded', "eagerly loaded plugin should report loaded")
      helpers.assert_equal(info.lazy, false, "non-lazy plugin should report lazy=false")

      helpers.cleanup_test_env()
    end)

    helpers.test("PluginInfo exposes exactly the documented key set", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          { 'test/alpha' },
          { 'test/gamma', cond = false },
          { 'test/delta', lazy = true },
        },
        defaults = { confirm = false },
      })
      helpers.flush_pending()

      local list = require('zpack').get_plugins()
      helpers.assert_true(#list >= 3, "all three plugins should be listed")
      for _, info in ipairs(list) do
        for k in pairs(info) do
          helpers.assert_true(
            PLUGIN_INFO_KEYS[k] == true,
            ("PluginInfo leaked undocumented key %q on %q — if this is intentional, bump zpack.api.VERSION and update PLUGIN_INFO_KEYS"):format(k, tostring(info.name))
          )
        end
        -- Every key must be present (rawget catches silent-nil regressions
        -- that `pairs` iteration would miss).
        for k in pairs(PLUGIN_INFO_KEYS) do
          helpers.assert_true(
            rawget(info, k) ~= nil,
            ("PluginInfo is missing required key %q on %q"):format(k, tostring(info.name))
          )
        end
      end

      helpers.cleanup_test_env()
    end)

    helpers.test("enabled=false plugins are pruned and not returned", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          { 'test/alpha', enabled = false },
          { 'test/beta' },
        },
        defaults = { confirm = false },
      })
      helpers.flush_pending()

      local list = require('zpack').get_plugins()
      helpers.assert_nil(find_by_name(list, 'alpha'), "enabled=false plugin must not appear in get_plugins()")
      helpers.assert_not_nil(find_by_name(list, 'beta'), "beta should still be listed")

      helpers.cleanup_test_env()
    end)

    helpers.test("enabled=false plugins do not reach vim.pack.add", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          { 'test/alpha', enabled = false },
          { 'test/beta' },
        },
        defaults = { confirm = false },
      })
      helpers.flush_pending()

      helpers.assert_nil(_G.test_state.registered_pack_specs['alpha'], "alpha must not be installed")
      helpers.assert_not_nil(_G.test_state.registered_pack_specs['beta'], "beta should be installed")

      helpers.cleanup_test_env()
    end)

    helpers.test("get_plugin returns nil for enabled=false plugins", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          { 'test/alpha', enabled = false },
        },
        defaults = { confirm = false },
      })
      helpers.flush_pending()

      helpers.assert_nil(require('zpack').get_plugin('alpha'), "pruned plugin must not be findable")

      helpers.cleanup_test_env()
    end)

    helpers.test("lazy plugins report lazy=true and status=pending", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          { 'test/alpha', lazy = true },
        },
        defaults = { confirm = false },
      })
      helpers.flush_pending()

      local info = find_by_name(require('zpack').get_plugins(), 'alpha')
      helpers.assert_not_nil(info, "lazy alpha should be listed")
      helpers.assert_equal(info.lazy, true, "lazy should be true")
      helpers.assert_equal(info.status, 'pending', "unloaded lazy plugin should be pending")

      helpers.cleanup_test_env()
    end)

    helpers.test("get_plugin returns a single entry by name", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          { 'test/alpha' },
          { 'test/beta' },
        },
        defaults = { confirm = false },
      })
      helpers.flush_pending()

      local info = require('zpack').get_plugin('beta')
      helpers.assert_not_nil(info, "get_plugin should find beta")
      helpers.assert_equal(info.name, 'beta', "name should match")
      helpers.assert_equal(info.src, 'https://github.com/test/beta', "src should match")

      helpers.cleanup_test_env()
    end)

    helpers.test("get_plugin returns nil for unknown name", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = { { 'test/alpha' } },
        defaults = { confirm = false },
      })
      helpers.flush_pending()

      helpers.assert_nil(require('zpack').get_plugin('does-not-exist'), "unknown name should return nil")
      helpers.assert_nil(require('zpack').get_plugin(''), "empty name should return nil")

      helpers.cleanup_test_env()
    end)

    helpers.test("cond=false reports status=disabled", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          { 'test/alpha', cond = false },
        },
        defaults = { confirm = false },
      })
      helpers.flush_pending()

      local info = require('zpack').get_plugin('alpha')
      helpers.assert_not_nil(info, "cond-disabled alpha should still be listed")
      helpers.assert_equal(info.status, 'disabled', "cond=false should report disabled")

      helpers.cleanup_test_env()
    end)

    helpers.test("cond function returning false reports status=disabled", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          { 'test/alpha', cond = function() return false end },
        },
        defaults = { confirm = false },
      })
      helpers.flush_pending()

      local info = require('zpack').get_plugin('alpha')
      helpers.assert_not_nil(info, "cond-fn-disabled alpha should still be listed")
      helpers.assert_equal(info.status, 'disabled', "cond() == false should report disabled")

      helpers.cleanup_test_env()
    end)

    helpers.test("cond_disabled lazy plugin still reports lazy=true", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          { 'test/alpha', cond = false, lazy = true },
        },
        defaults = { confirm = false },
      })
      helpers.flush_pending()

      local info = require('zpack').get_plugin('alpha')
      helpers.assert_not_nil(info, "alpha should be listed")
      helpers.assert_equal(info.status, 'disabled', "cond=false should report disabled")
      helpers.assert_equal(info.lazy, true, "lazy field must be honest even when cond-disabled")

      helpers.cleanup_test_env()
    end)

    helpers.test("cond_disabled event-triggered plugin reports lazy=true", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          { 'test/alpha', cond = false, event = 'BufReadPost' },
        },
        defaults = { confirm = false },
      })
      helpers.flush_pending()

      local info = require('zpack').get_plugin('alpha')
      helpers.assert_not_nil(info, "alpha should be listed")
      helpers.assert_equal(info.lazy, true, "event-triggered plugin should report lazy=true even when cond-disabled")

      helpers.cleanup_test_env()
    end)

    helpers.test("disable propagates and prunes parent + child", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          { 'test/parent', dependencies = { 'test/child' } },
          { 'test/child', enabled = false },
        },
        defaults = { confirm = false },
      })
      helpers.flush_pending()

      helpers.assert_nil(require('zpack').get_plugin('parent'), "parent should be pruned after dep-propagated disable")
      helpers.assert_nil(require('zpack').get_plugin('child'), "child should be pruned after explicit disable")

      helpers.cleanup_test_env()
    end)

    helpers.test("dep-only plugin is pruned when its only parent is disabled", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          { 'test/parent', enabled = false, dependencies = { 'test/dep' } },
        },
        defaults = { confirm = false },
      })
      helpers.flush_pending()

      helpers.assert_nil(require('zpack').get_plugin('parent'), "disabled parent should be pruned")
      helpers.assert_nil(require('zpack').get_plugin('dep'), "dep-only child of disabled parent should be pruned")
      helpers.assert_nil(_G.test_state.registered_pack_specs['dep'], "orphaned dep must not reach vim.pack.add")

      helpers.cleanup_test_env()
    end)

    helpers.test("dep with another live parent survives when one parent is disabled", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          { 'test/keeper', dependencies = { 'test/shared' } },
          { 'test/dropper', enabled = false, dependencies = { 'test/shared' } },
        },
        defaults = { confirm = false },
      })
      helpers.flush_pending()

      helpers.assert_not_nil(require('zpack').get_plugin('keeper'), "keeper should survive")
      helpers.assert_not_nil(require('zpack').get_plugin('shared'), "shared dep should survive (still referenced by keeper)")
      helpers.assert_nil(require('zpack').get_plugin('dropper'), "dropper should be pruned")

      helpers.cleanup_test_env()
    end)

    helpers.test("status reports loading while a lazy-loaded plugin's config is running", function()
      helpers.setup_test_env()
      local observed_status
      require('zpack').setup({
        spec = {
          {
            'test/alpha',
            lazy = true,
            config = function()
              local info = require('zpack').get_plugin('alpha')
              observed_status = info and info.status
            end,
          },
        },
        defaults = { confirm = false },
      })
      helpers.flush_pending()

      -- Before lazy-load, alpha is pending.
      helpers.assert_equal(require('zpack').get_plugin('alpha').status, 'pending', "lazy plugin starts pending")

      pcall(vim.cmd, 'ZLoad! alpha')

      helpers.assert_equal(observed_status, 'loading', "get_plugin inside config must see status=loading")
      helpers.assert_equal(require('zpack').get_plugin('alpha').status, 'loaded', "status should be loaded after load completes")

      helpers.cleanup_test_env()
    end)

    helpers.test("PluginInfo does not expose a rev field (install state is vim.pack's)", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = { { 'test/alpha' } },
        defaults = { confirm = false },
      })
      helpers.flush_pending()

      local info = require('zpack').get_plugin('alpha')
      helpers.assert_not_nil(info, "alpha should exist")
      helpers.assert_nil(
        rawget(info, 'rev'),
        "rev was intentionally removed from PluginInfo — consumers must use vim.pack.get"
      )

      helpers.cleanup_test_env()
    end)

    helpers.test("get_plugins surfaces entries whose load callback has not fired as installing", function()
      helpers.setup_test_env()

      -- Simulate vim.pack deferring the load callback (e.g. fresh install
      -- awaiting confirmation): record the spec but don't invoke opts.load.
      vim.pack.add = function(specs, _opts)
        table.insert(_G.test_state.vim_pack_calls, specs)
        for _, pack_spec in ipairs(specs) do
          local name = pack_spec.name or pack_spec.src:match('[^/]+$')
          pack_spec.name = name
          _G.test_state.registered_pack_specs[name] = pack_spec
        end
      end

      local ok, err = pcall(function()
        require('zpack').setup({
          spec = { { 'test/alpha' } },
          defaults = { confirm = false },
        })
        helpers.flush_pending()
      end)
      helpers.assert_true(ok, "setup must not throw when load callback is deferred: " .. tostring(err))

      local info = find_by_name(require('zpack').get_plugins(), 'alpha')
      helpers.assert_not_nil(info, "pending-install entries must surface in get_plugins()")
      helpers.assert_equal(info.status, 'installing', "deferred-load entry should report status=installing")
      helpers.assert_equal(info.path, nil, "installing entries have no resolved path yet")
      helpers.assert_equal(info.name, 'alpha', "installing entry should still carry a derivable name")

      -- get_plugin() is symmetric with get_plugins(): name_to_src is populated
      -- at resolve_all time from merged_spec.name (or a derived basename), so
      -- installing entries are findable by the same name they will carry once
      -- the load callback fires.
      local looked_up = require('zpack').get_plugin('alpha')
      helpers.assert_not_nil(looked_up, "get_plugin must resolve installing entries")
      helpers.assert_equal(looked_up.status, 'installing', "looked-up installing entry keeps status=installing")
      helpers.assert_equal(looked_up.name, 'alpha', "looked-up installing entry has the same name as in get_plugins()")

      helpers.cleanup_test_env()
    end)

    helpers.test("get_plugins does not include zpack itself", function()
      helpers.setup_test_env()
      _G.test_state.registered_pack_specs['zpack.nvim'] = {
        name = 'zpack.nvim',
        src = 'https://github.com/zuqini/zpack.nvim',
      }

      require('zpack').setup({
        spec = { { 'test/alpha' } },
        defaults = { confirm = false },
      })
      helpers.flush_pending()

      local list = require('zpack').get_plugins()
      helpers.assert_nil(
        find_by_name(list, 'zpack.nvim'),
        "zpack.nvim should not be in the API — consumers that need it can query vim.pack.get directly"
      )
      helpers.assert_not_nil(find_by_name(list, 'alpha'), "user plugins should still be returned")

      helpers.cleanup_test_env()
    end)

    helpers.test("get_plugins() is sorted by name", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          { 'test/charlie' },
          { 'test/alpha' },
          { 'test/bravo' },
        },
        defaults = { confirm = false },
      })
      helpers.flush_pending()

      local list = require('zpack').get_plugins()
      local names = {}
      for _, info in ipairs(list) do
        table.insert(names, info.name)
      end
      local prev = nil
      for _, name in ipairs(names) do
        if prev ~= nil then
          helpers.assert_true(prev <= name, "get_plugins() must be sorted by name")
        end
        prev = name
      end

      helpers.cleanup_test_env()
    end)

    helpers.test("get_plugin tolerates non-string arguments", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = { { 'test/alpha' } },
        defaults = { confirm = false },
      })
      helpers.flush_pending()

      helpers.assert_nil(require('zpack').get_plugin(nil), "nil should return nil, not throw")
      helpers.assert_nil(require('zpack').get_plugin(42), "number should return nil, not throw")

      helpers.cleanup_test_env()
    end)

    helpers.test("zpack.api.VERSION is exposed as an integer >= 1", function()
      helpers.setup_test_env()

      require('zpack').setup({ spec = {}, defaults = { confirm = false } })
      helpers.flush_pending()

      local version = require('zpack.api').VERSION
      helpers.assert_equal(type(version), 'number', "VERSION must be numeric")
      helpers.assert_true(version >= 1, "VERSION must be >= 1")

      helpers.cleanup_test_env()
    end)

    helpers.test("lazy via event trigger reports lazy=true", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          { 'test/alpha', event = 'BufReadPost' },
        },
        defaults = { confirm = false },
      })
      helpers.flush_pending()

      local info = require('zpack').get_plugin('alpha')
      helpers.assert_not_nil(info, "alpha should be listed")
      helpers.assert_equal(info.lazy, true, "event-triggered plugin should report lazy=true")

      helpers.cleanup_test_env()
    end)

    helpers.test("lazy flag does not flip across installing → loaded lifecycle", function()
      helpers.setup_test_env()

      -- First setup: defer the load callback so alpha surfaces as installing
      -- with an event-triggered spec. The lazy flag must already be true.
      vim.pack.add = function(specs, _opts)
        table.insert(_G.test_state.vim_pack_calls, specs)
        for _, pack_spec in ipairs(specs) do
          local name = pack_spec.name or pack_spec.src:match('[^/]+$')
          pack_spec.name = name
          _G.test_state.registered_pack_specs[name] = pack_spec
        end
      end

      require('zpack').setup({
        spec = { { 'test/alpha', event = 'BufReadPost' } },
        defaults = { confirm = false },
      })
      helpers.flush_pending()

      local installing = require('zpack').get_plugin('alpha')
      helpers.assert_not_nil(installing, "installing entry must be findable")
      helpers.assert_equal(installing.status, 'installing', "alpha should be installing")
      helpers.assert_equal(
        installing.lazy, true,
        "event-triggered plugin must report lazy=true even before the load callback fires"
      )

      helpers.cleanup_test_env()
    end)

    helpers.test("force-loaded cond=false plugin reports loaded, not disabled", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          { 'test/alpha', cond = false },
        },
        defaults = { confirm = false },
      })
      helpers.flush_pending()

      -- Pre-condition: alpha is registered and reports disabled.
      helpers.assert_equal(
        require('zpack').get_plugin('alpha').status, 'disabled',
        "cond=false plugin starts disabled"
      )

      -- `:ZLoad! alpha` force-loads past the cond gate (used e.g. when a
      -- consumer deliberately wants the plugin loaded despite its cond).
      pcall(vim.cmd, 'ZLoad! alpha')

      helpers.assert_equal(
        require('zpack').get_plugin('alpha').status, 'loaded',
        "force-loaded cond=false plugin must report loaded, not disabled"
      )

      helpers.cleanup_test_env()
    end)

    helpers.test("cond=false dep pulled in by a live parent reports loaded", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          {
            'test/parent',
            dependencies = { { 'test/helper', cond = false } },
          },
        },
        defaults = { confirm = false },
      })
      helpers.flush_pending()

      -- Parent is eagerly loaded, which pulls helper in as a required dep.
      -- plugin_loader warns that helper has cond=false but loads it anyway,
      -- so derive_status must honor load_status over cond_result.
      local helper = require('zpack').get_plugin('helper')
      helpers.assert_not_nil(helper, "cond=false dep should still be registered")
      helpers.assert_equal(
        helper.status, 'loaded',
        "cond=false dep force-loaded by a live parent must report loaded"
      )

      helpers.cleanup_test_env()
    end)

    helpers.test("get_plugin(info.name) round-trips every get_plugins() entry", function()
      helpers.setup_test_env()

      require('zpack').setup({
        spec = {
          { 'test/alpha' },
          { 'test/beta', lazy = true },
          { 'test/gamma', cond = false },
          { 'test/delta', event = 'BufReadPost' },
        },
        defaults = { confirm = false },
      })
      helpers.flush_pending()

      local list = require('zpack').get_plugins()
      helpers.assert_true(#list >= 4, "all four plugins should be listed")
      for _, info in ipairs(list) do
        local looked_up = require('zpack').get_plugin(info.name)
        helpers.assert_not_nil(
          looked_up,
          ("get_plugin(%q) must round-trip get_plugins() entry"):format(info.name)
        )
        helpers.assert_equal(
          looked_up.name, info.name,
          "round-tripped name must match the original entry"
        )
        helpers.assert_equal(
          looked_up.src, info.src,
          "round-tripped src must match the original entry"
        )
      end

      helpers.cleanup_test_env()
    end)
  end)
end
