local util = require('zpack.utils')
local state = require('zpack.state')
local loader = require('zpack.plugin_loader')
local refire = require('zpack.lazy_trigger.refire')

local M = {}

---@param pack_spec vim.pack.Spec
---@param ft zpack.FtValue
M.setup = function(pack_spec, ft)
  local filetypes = util.normalize_string_list(ft)

  util.autocmd("FileType", function(ev)
    -- Same gate as lazy_trigger/event.lua: skip when a sibling already
    -- loaded (avoid double-fire) or is mid-load (avoid spurious circular-
    -- dependency notify).
    local entry = state.spec_registry[pack_spec.src]
    if entry and entry.load_status ~= "pending" then
      return
    end
    local snap = refire.snapshot("FileType")
    if not loader.try_process_spec(pack_spec) then
      return
    end
    refire.exec(ev, snap)
  end, { group = state.lazy_group, pattern = filetypes, once = true })
end

return M
