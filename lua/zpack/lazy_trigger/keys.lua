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

    local keys_value = util.try_resolve_field(spec.keys, plugin, pack_spec.name or pack_spec.src, 'keys')
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
      local any_ok = false
      for _, pack_spec in ipairs(key_info.pack_specs) do
        if loader.try_process_spec(pack_spec) then
          any_ok = true
        end
      end
      -- Proxy already self-deleted; if no plugin loaded, feeding lhs would
      -- type it literally into the buffer.
      if not any_ok then
        return
      end
      -- A malformed key spec is pcall-swallowed by apply_keys, so the lhs
      -- may end up unmapped. Skip the re-feed unless the spec expected a
      -- real keymap — a nil-rhs spec (e.g. `{ 'i', mode = 'o' }`) is the
      -- "load + fall through to native binding" pattern and must still feed.
      if key_info.key_spec[2] ~= nil
        and vim.fn.maparg(lhs, key_info.split_mode) == '' then
        return
      end
      -- 'i' prepends to typeahead so queued keys (e.g. trailing 'b' in 'vib')
      -- still run after the re-fed lhs. <Ignore> bridges the expr/typeahead
      -- boundary without disturbing operator-pending state.
      vim.api.nvim_feedkeys(vim.keycode('<Ignore>' .. lhs), 'i', false)
    end, {
      desc = key_spec.desc,
      mode = key_info.split_mode,
      -- expr is forced on regardless of key_spec.expr so the proxy preserves
      -- operator-pending state across the lazy-load trigger (issue #26). The
      -- real keymap installed on load honors the user's key_spec.expr.
      -- Tradeoff: expr callbacks run under textlock, so configs that mutate
      -- text/windows synchronously during the first triggering press hit
      -- E565 and must defer with vim.schedule().
      expr = true,
      nowait = key_spec.nowait,
      silent = key_spec.silent,
      remap = key_spec.remap,
      noremap = key_spec.noremap,
    })
  end
end

return M
