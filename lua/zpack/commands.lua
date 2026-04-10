local state = require('zpack.state')
local util = require('zpack.utils')
local hooks = require('zpack.hooks')

local M = {}

local validate_prefix = function(prefix)
  if prefix == '' then
    return true
  end
  if not prefix:match('^%u[%a%d]*$') then
    return false
  end
  return true
end

local create_command = function(name, fn, opts)
  local ok, err = pcall(vim.api.nvim_create_user_command, name, fn, opts)
  if not ok then
    util.schedule_notify(('Failed to create command %s: %s'):format(name, err), vim.log.levels.ERROR)
    return false
  end
  return true
end

local filter_completions = function(list, prefix)
  if prefix == '' then return list end
  local lower_prefix = prefix:lower()
  return vim.tbl_filter(function(name)
    return name:lower():find(lower_prefix, 1, true) == 1
  end, list)
end

local is_registered_or_notify = function(plugin_name)
  if not vim.tbl_contains(state.registered_plugin_names, plugin_name) then
    util.schedule_notify(('Plugin "%s" not found in spec'):format(plugin_name), vim.log.levels.ERROR)
    return false
  end
  return true
end

-- Branches avoid passing trailing nils because vim.pack.update uses
-- select('#', ...) to distinguish "no args" from "nil args".
local run_pack_update = function(plugin_name, update_opts, error_prefix)
  local names
  if plugin_name ~= '' then
    if not is_registered_or_notify(plugin_name) then return end
    names = { plugin_name }
  end
  local ok, err
  if names and update_opts then
    ok, err = pcall(vim.pack.update, names, update_opts)
  elseif names then
    ok, err = pcall(vim.pack.update, names)
  elseif update_opts then
    ok, err = pcall(vim.pack.update, nil, update_opts)
  else
    ok, err = pcall(vim.pack.update)
  end
  if not ok then
    util.schedule_notify(('%s: %s'):format(error_prefix, err), vim.log.levels.ERROR)
  end
end

local get_installed_or_notify = function(plugin_name)
  local ok, result = pcall(vim.pack.get, { plugin_name }, { info = false })
  if not ok or not result or not result[1] then
    util.schedule_notify(('Plugin "%s" not installed'):format(plugin_name), vim.log.levels.ERROR)
    return nil
  end
  return result[1]
end

M.clean_unused = function()
  local to_delete = {}
  local installed = vim.pack.get(nil, { info = false }) or {}

  for _, pack in ipairs(installed) do
    local src = pack.spec.src
    if not state.spec_registry[src] and not string.find(src, 'zpack') then
      table.insert(to_delete, pack.spec.name)
    end
  end

  if #to_delete == 0 then
    util.schedule_notify("No unused plugins to clean", vim.log.levels.INFO)
    return
  end

  util.schedule_notify(("Deleting %d unused plugin(s)..."):format(#to_delete), vim.log.levels.INFO)

  vim.pack.del(to_delete)
end

---@param prefix string
M.setup = function(prefix)
  if not validate_prefix(prefix) then
    util.schedule_notify(
      ('Invalid cmd_prefix "%s": must be empty or start with uppercase letter and contain only letters/digits'):format(
        prefix),
      vim.log.levels.ERROR
    )
    return
  end

  local complete_registered = function(arg_lead)
    return filter_completions(state.registered_plugin_names, arg_lead)
  end

  create_command(prefix .. 'Update', function(opts)
    run_pack_update(opts.args, nil, 'Update failed')
  end, {
    nargs = '?',
    desc = 'Update all plugins or a specific plugin',
    complete = complete_registered,
  })

  create_command(prefix .. 'Restore', function(opts)
    run_pack_update(opts.args, { target = 'lockfile' }, 'Restore failed (have you run :' .. prefix .. 'Update?)')
  end, {
    nargs = '?',
    desc = 'Restore all plugins or a specific plugin to lockfile state',
    complete = complete_registered,
  })

  create_command(prefix .. 'Clean', function()
    M.clean_unused()
  end, {
    desc = 'Remove unused plugins',
  })

  create_command(prefix .. 'Build', function(opts)
    local plugin_name = opts.args
    if plugin_name == '' then
      if not opts.bang then
        util.schedule_notify(('Use :%sBuild! to run build hooks for all plugins'):format(prefix), vim.log.levels.WARN)
        return
      end
      hooks.run_all_builds()
      return
    end

    local pack = get_installed_or_notify(plugin_name)
    if not pack then
      return
    end

    local registry_entry = state.spec_registry[pack.spec.src]
    local spec = registry_entry and registry_entry.merged_spec
    if not spec or not spec.build then
      util.schedule_notify(('Plugin "%s" has no build hook'):format(plugin_name), vim.log.levels.WARN)
      return
    end

    local pack_spec = state.src_to_pack_spec[pack.spec.src]
    if pack_spec then
      require('zpack.plugin_loader').process_spec(pack_spec, { bang = true })
    end
    hooks.execute_build(spec.build, registry_entry.plugin)
    util.schedule_notify(('Running build hook for %s'):format(plugin_name), vim.log.levels.INFO)
  end, {
    nargs = '?',
    bang = true,
    desc = 'Run build hook for a specific plugin or all plugins',
    complete = function(arg_lead) return filter_completions(state.plugin_names_with_build, arg_lead) end,
  })

  create_command(prefix .. 'Load', function(opts)
    local plugin_name = opts.args
    if plugin_name == '' then
      if not opts.bang then
        util.schedule_notify(('Use :%sLoad! to load all unloaded plugins'):format(prefix), vim.log.levels.WARN)
        return
      end
      local count = vim.tbl_count(state.unloaded_plugin_names)
      if count == 0 then
        util.schedule_notify('All plugins are already loaded', vim.log.levels.INFO)
        return
      end
      local loader = require('zpack.plugin_loader')
      for _, pack_spec in ipairs(state.registered_plugins) do
        local entry = state.spec_registry[pack_spec.src]
        if entry and entry.load_status ~= "loaded" then
          loader.process_spec(pack_spec)
        end
      end
      util.schedule_notify(('Loaded %d plugin(s)'):format(count), vim.log.levels.INFO)
      return
    end

    local pack = get_installed_or_notify(plugin_name)
    if not pack then
      return
    end

    local registry_entry = state.spec_registry[pack.spec.src]
    if not registry_entry then
      util.schedule_notify(('Plugin "%s" not found in registry'):format(plugin_name), vim.log.levels.ERROR)
      return
    end

    if registry_entry.load_status == "loaded" then
      util.schedule_notify(('Plugin "%s" is already loaded'):format(plugin_name), vim.log.levels.INFO)
      return
    end

    local loader = require('zpack.plugin_loader')
    loader.process_spec(pack.spec, {})
    util.schedule_notify(('Loaded %s'):format(plugin_name), vim.log.levels.INFO)
  end, {
    nargs = '?',
    bang = true,
    desc = 'Load all unloaded plugins or a specific plugin',
    complete = function(arg_lead)
      local names = vim.tbl_keys(state.unloaded_plugin_names)
      -- sorted on each invocation; negligible for typical plugin counts
      table.sort(names, function(a, b) return a:lower() < b:lower() end)
      return filter_completions(names, arg_lead)
    end,
  })

  create_command(prefix .. 'Delete', function(opts)
    local plugin_name = opts.args
    if plugin_name == '' then
      if not opts.bang then
        util.schedule_notify(
          ('Use :%sDelete! to confirm deletion of all installed plugin(s)'):format(prefix),
          vim.log.levels.WARN
        )
        return
      end
      local names = {}
      for i = #state.registered_plugins, 1, -1 do
        table.insert(names, state.registered_plugins[i].name)
      end
      table.insert(names, 'zpack.nvim')

      util.schedule_notify(("Deleting all %d installed plugin(s)..."):format(#names), vim.log.levels.INFO)
      vim.pack.del(names, { force = true })
      state.clear_plugin_lists()
      util.schedule_notify(
        "All plugins deleted. This can result in errors in your current session. Restart Neovim to re-install them or remove them from your spec.",
        vim.log.levels.WARN)
      return
    end

    local pack = get_installed_or_notify(plugin_name)
    if not pack then
      return
    end

    vim.pack.del({ plugin_name }, { force = true })
    state.remove_plugin(plugin_name, pack.spec.src)
    util.schedule_notify(
      ('%s deleted. This can result in errors in your current session. Restart Neovim to re-install it or remove it from your spec.')
      :format(plugin_name),
      vim.log.levels.WARN
    )
  end, {
    nargs = '?',
    bang = true,
    desc = 'Delete all plugins or a specific plugin',
    complete = function(arg_lead) return filter_completions(state.registered_plugin_names, arg_lead) end,
  })
end

return M
