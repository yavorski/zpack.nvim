local state = require('zpack.state')
local util = require('zpack.utils')

local M = {}

---@type { [string]: true }
local currently_loading_sources = {}

---@type { [string]: { src: string, topmod: string }|false }
local module_lookup_cache = {}

---@type { [string]: { [string]: true } }
local scanned_lua_directories = {}

---@type { [string]: string[] }
local topmod_to_plugin_sources = {}

---@type vim.pack.Spec[]
local lazy_pack_specs = {}

-- Profiling config
local profiling = {
  loader = false,
  require = false,
}

-- Profiling data
local profile = {
  loader_calls = 0,
  cache_hits = 0,
  find_cache_hits = 0,
  find_calls = 0,
  find_time = 0,
  process_spec_time = 0,
  loadfile_time = 0,
  total_time = 0,
  modules_checked = {},
}

---@param opts? { loader?: boolean, require?: boolean }
function M.setup(opts)
  if opts then
    if opts.loader ~= nil then
      profiling.loader = opts.loader
    end
    if opts.require ~= nil then
      profiling.require = opts.require
    end
  end
end

function M.get_profile()
  return profile
end

function M.print_profile()
  if not profiling.loader then
    print("Profiling disabled. Enable with: profiling = { loader = true }")
    return
  end
  print(string.format([[
Module Loader Profile:
  loader() calls:     %d
  cache hits:         %d (find_cache: %d)
  find_src calls:     %d
  find_src time:      %.3f ms
  process_spec time:  %.3f ms
  loadfile time:      %.3f ms
  total loader time:  %.3f ms
]],
    profile.loader_calls,
    profile.cache_hits,
    profile.find_cache_hits,
    profile.find_calls,
    profile.find_time * 1000,
    profile.process_spec_time * 1000,
    profile.loadfile_time * 1000,
    profile.total_time * 1000
  ))

  if profiling.require then
    print("Modules checked (sorted by count):")
    local sorted = {}
    for mod, count in pairs(profile.modules_checked) do
      table.insert(sorted, { mod = mod, count = count })
    end
    table.sort(sorted, function(a, b) return a.count > b.count end)
    for i, entry in ipairs(sorted) do
      if i > 20 then
        print(string.format("  ... and %d more", #sorted - 20))
        break
      end
      print(string.format("  %3d x %s", entry.count, entry.mod))
    end
  else
    print("Enable profiling.require to see modules checked")
  end
end

local function get_time()
  return vim.uv.hrtime() / 1e9
end

---Scan a plugin's /lua directory for top-level modules
---@param path string plugin path
---@return { [string]: true }? topmods map of top-level module names
local function scan_lua_dir(path)
  if scanned_lua_directories[path] then
    return scanned_lua_directories[path]
  end

  local lua_dir = path .. "/lua"
  local handle = vim.uv.fs_scandir(lua_dir)
  if not handle then
    scanned_lua_directories[path] = {}
    return nil
  end

  local topmods = {}
  while true do
    local name, ftype = vim.uv.fs_scandir_next(handle)
    if not name then
      break
    end

    local topname
    if name:sub(-4) == ".lua" then
      topname = name:sub(1, -5)
    elseif ftype == "directory" or ftype == "link" then
      topname = name
    end

    if topname then
      topmods[topname] = true
    end
  end

  scanned_lua_directories[path] = topmods
  return topmods
end

---Find plugin source by scanning filesystem for the top-level module
---@param topmod string top-level module name
---@return string? src plugin source if found
local function find_src_by_scanning(topmod)
  if topmod_to_plugin_sources[topmod] then
    for _, src in ipairs(topmod_to_plugin_sources[topmod]) do
      local registry_entry = state.spec_registry[src]
      if registry_entry and registry_entry.load_status == "pending" then
        return src
      end
    end
    return nil
  end

  local srcs = {}
  local norm_topmod = util.normalize_name(topmod)

  for _, pack_spec in ipairs(lazy_pack_specs) do
    local registry_entry = state.spec_registry[pack_spec.src]
    if registry_entry then
      local spec = registry_entry.merged_spec
      if spec and spec.module ~= false then
        local matched = false

        if registry_entry.plugin and registry_entry.plugin.path then
          local path = registry_entry.plugin.path
          local topmods = scan_lua_dir(path)
          if topmods and topmods[topmod] then
            matched = true
          elseif topmods and next(topmods) then
            for mod_name in pairs(topmods) do
              if util.normalize_name(mod_name) == norm_topmod then
                matched = true
                break
              end
            end
          end
        end

        if not matched then
          if spec.main and util.normalize_name(spec.main) == norm_topmod then
            matched = true
          elseif pack_spec.name and util.normalize_name(pack_spec.name) == norm_topmod then
            matched = true
          end
        end

        if matched then
          table.insert(srcs, pack_spec.src)
          if registry_entry.load_status == "pending" then
            topmod_to_plugin_sources[topmod] = srcs
            return pack_spec.src
          end
        end
      end
    end
  end

  topmod_to_plugin_sources[topmod] = srcs
  return nil
end

---Initialize module loader with lazy plugins
---@param lazy_packs vim.pack.Spec[]
function M.initialize_cache(lazy_packs)
  module_lookup_cache = {}
  scanned_lua_directories = {}
  topmod_to_plugin_sources = {}
  lazy_pack_specs = lazy_packs
end

function M.debug_index()
  return topmod_to_plugin_sources
end

---Find plugin source by scanning filesystem for the module
---@param modname string
---@return string? src, string? topmod
local function find_src_for_module(modname)
  local cached = module_lookup_cache[modname]
  if cached == false then
    if profiling.loader then
      profile.find_cache_hits = profile.find_cache_hits + 1
      profile.cache_hits = profile.cache_hits + 1
    end
    return nil, nil
  end
  if cached then
    if profiling.loader then
      profile.find_cache_hits = profile.find_cache_hits + 1
      profile.cache_hits = profile.cache_hits + 1
    end
    return cached.src, cached.topmod
  end

  local start = profiling.loader and get_time() or 0
  if profiling.loader then
    profile.find_calls = profile.find_calls + 1
  end

  local parts = {}
  for part in modname:gmatch("[^%.]+") do
    table.insert(parts, part)
  end

  for i = #parts, 1, -1 do
    local prefix = table.concat(parts, ".", 1, i)
    local src = find_src_by_scanning(prefix)
    if src then
      module_lookup_cache[modname] = { src = src, topmod = parts[1] }
      if profiling.loader then
        profile.find_time = profile.find_time + (get_time() - start)
      end
      return src, parts[1]
    end
  end

  module_lookup_cache[modname] = false
  if profiling.loader then
    profile.find_time = profile.find_time + (get_time() - start)
  end
  return nil, nil
end

---Custom loader that triggers packadd for lazy plugins
---@param modname string
---@return function|string|nil
function M.loader(modname)
  local total_start = profiling.loader and get_time() or 0
  if profiling.loader then
    profile.loader_calls = profile.loader_calls + 1
  end
  if profiling.require then
    profile.modules_checked[modname] = (profile.modules_checked[modname] or 0) + 1
  end

  local src, topmod = find_src_for_module(modname)

  if not src then
    if profiling.loader then
      profile.total_time = profile.total_time + (get_time() - total_start)
    end
    return nil
  end

  local registry_entry = state.spec_registry[src]
  if not registry_entry or registry_entry.load_status ~= "pending" or currently_loading_sources[src] then
    if profiling.loader then
      profile.total_time = profile.total_time + (get_time() - total_start)
    end
    return nil
  end

  local pack_spec = state.src_to_pack_spec[src]
  if not pack_spec then
    if profiling.loader then
      profile.total_time = profile.total_time + (get_time() - total_start)
    end
    return nil
  end

  currently_loading_sources[src] = true
  local process_start = profiling.loader and get_time() or 0
  -- Clear the flag unconditionally so a throw doesn't wedge later
  -- requires into the early-return above. Re-raise for caller.
  local ok, err = pcall(require('zpack.plugin_loader').process_spec, pack_spec, { bang = true })
  if profiling.loader then
    profile.process_spec_time = profile.process_spec_time + (get_time() - process_start)
  end
  currently_loading_sources[src] = nil
  if not ok then
    error(err, 0)
  end

  if topmod then
    topmod_to_plugin_sources[topmod] = nil
  end

  local mod = package.loaded[modname]
  if mod ~= nil then
    if profiling.loader then
      profile.total_time = profile.total_time + (get_time() - total_start)
    end
    return function()
      return mod
    end
  end

  local plugin = registry_entry.plugin
  if plugin and plugin.path then
    local basename = modname:gsub("%.", "/")
    local lua_dir = plugin.path .. "/lua/"
    local path = lua_dir .. basename .. ".lua"
    local loadfile_start = profiling.loader and get_time() or 0
    local stat = vim.uv.fs_stat(path)
    if stat then
      ---@diagnostic disable-next-line: redundant-parameter
      local loader = loadfile(path, nil, nil, stat)
      if profiling.loader then
        profile.loadfile_time = profile.loadfile_time + (get_time() - loadfile_start)
        profile.total_time = profile.total_time + (get_time() - total_start)
      end
      return loader
    end
    path = lua_dir .. basename .. "/init.lua"
    loadfile_start = profiling.loader and get_time() or 0
    stat = vim.uv.fs_stat(path)
    if stat then
      ---@diagnostic disable-next-line: redundant-parameter
      local loader = loadfile(path, nil, nil, stat)
      if profiling.loader then
        profile.loadfile_time = profile.loadfile_time + (get_time() - loadfile_start)
        profile.total_time = profile.total_time + (get_time() - total_start)
      end
      return loader
    end
  end

  if profiling.loader then
    profile.total_time = profile.total_time + (get_time() - total_start)
  end
  return nil
end

function M.install()
  table.insert(package.loaders, 3, M.loader)
end

return M
