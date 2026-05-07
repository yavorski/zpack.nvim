local util = require('zpack.utils')

local M = {}

local SUPPORTED_OPTS = { 'desc', 'remap', 'nowait', 'expr', 'silent', 'replace_keycodes' }

---@param lhs string
---@param rhs string|fun()
---@param opts? zpack.KeymapOpts
M.map = function(lhs, rhs, opts)
  opts = opts or {}
  local set_opts = {}
  for _, k in ipairs(SUPPORTED_OPTS) do
    set_opts[k] = opts[k]
  end
  -- Mirror Neovim's documented expr→replace_keycodes default so zpack owns the contract.
  if set_opts.expr and set_opts.replace_keycodes == nil then
    set_opts.replace_keycodes = true
  end
  vim.keymap.set(opts.mode or { 'n' }, lhs, rhs, set_opts)
end

---@param keys zpack.KeySpec|zpack.KeySpec[]|string
M.apply_keys = function(keys)
  local key_list = util.normalize_keys(keys) --[[@as zpack.KeySpec[] ]]

  for _, key in ipairs(key_list) do
    if key[2] ~= nil then
      local opts = { mode = key.mode }
      for _, k in ipairs(SUPPORTED_OPTS) do
        opts[k] = key[k]
      end
      -- lazy.nvim compat: noremap is the inverse of remap. Translate at the
      -- spec boundary so M.map only speaks vim.keymap.set's vocabulary.
      -- Explicit `remap` wins; the alias is consulted only when remap is unset.
      if opts.remap == nil and key.noremap ~= nil then
        opts.remap = not key.noremap
      end
      M.map(key[1], key[2], opts)
    end
  end
end

return M
