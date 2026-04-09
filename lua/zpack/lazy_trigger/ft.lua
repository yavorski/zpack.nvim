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
    local snap = refire.snapshot("FileType")
    local ok, err = pcall(loader.process_spec, pack_spec)
    if not ok then
      vim.schedule(function()
        vim.notify(("Failed to load plugin: %s"):format(err), vim.log.levels.ERROR)
      end)
      return
    end
    refire.exec("FileType", ev.buf, ev.data, snap)
  end, { group = state.lazy_group, pattern = filetypes, once = true })
end

return M
