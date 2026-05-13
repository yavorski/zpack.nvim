local util = require('zpack.utils')
local state = require('zpack.state')
local keymap = require('zpack.keymap')
local loader = require('zpack.plugin_loader')

local M = {}

---Create a unique key identifier from lhs and mode
---@param lhs string The key mapping (e.g., "<leader>ff")
---@param mode string The mode (e.g., "n", "v")
---@return string Unique identifier
local create_key_id = function(lhs, mode)
  return lhs .. '-' .. mode
end

---@param registered_pack_specs vim.pack.Spec[]
M.setup = function(registered_pack_specs)
  local key_to_info = {}
  for _, pack_spec in ipairs(registered_pack_specs) do
    local registry_entry = state.spec_registry[pack_spec.src]
    local spec = registry_entry.merged_spec --[[@as zpack.Spec]]
    local plugin = registry_entry.plugin

    local keys_value = util.resolve_field(spec.keys, plugin)
    if keys_value then
      local keys = util.normalize_keys(keys_value) --[[@as zpack.KeySpec[] ]]
      for _, key in ipairs(keys) do
        local lhs = key[1]
        local mode = key.mode or 'n'
        local modes = util.normalize_string_list(mode) --[[@as string[] ]]

        for _, m in ipairs(modes) do
          local key_id = create_key_id(lhs, m)
          if not key_to_info[key_id] then
            key_to_info[key_id] = {
              split_mode = m,
              pack_specs = {},
              key_spec = key,
            }
          end
          table.insert(key_to_info[key_id].pack_specs, pack_spec)
        end
      end
    end
  end

  -- Create keymaps
  for _, key_info in pairs(key_to_info) do
    local lhs = key_info.key_spec[1]
    local key_spec = key_info.key_spec
    keymap.map(lhs, function()
      pcall(vim.keymap.del, key_info.split_mode, lhs)
      for _, pack_spec in ipairs(key_info.pack_specs) do
        loader.process_spec(pack_spec)
      end
      -- 'i' inserts at the front of typeahead so queued keys (e.g. trailing 'b'
      -- in 'vib') run after the re-fed lhs; without 'i' the lhs is appended,
      -- so the queued keys would run first and 'vib' would degrade to 'vb'.
      vim.api.nvim_feedkeys(vim.keycode(lhs), 'i', false)
    end, {
      desc = key_spec.desc,
      mode = key_info.split_mode,
      -- Forward user-facing opts so the first (proxy) press matches subsequent
      -- presses through the real keymap. expr/replace_keycodes are the only
      -- omissions: the proxy's rhs is a Lua callback returning nil, so making
      -- it expr would feed nil keys and the plugin would never load.
      nowait = key_spec.nowait,
      silent = key_spec.silent,
      remap = key_spec.remap,
      noremap = key_spec.noremap,
    })
  end
end

return M
