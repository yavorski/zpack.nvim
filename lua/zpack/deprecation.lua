local utils = require('zpack.utils')

local M = {}

M.removed = {
  add = {
    message = "zpack.add() has been removed. Pass specs directly to setup():",
    replacement = [[
require('zpack').setup({ { 'user/plugin' } })
require('zpack').setup({ spec = { { 'user/plugin' } } }) -- or via the spec field
]]
  },
  auto_import = {
    message = "auto_import option has been removed. Pass specs directly to setup():",
    replacement = [[
require('zpack').setup({ { 'user/plugin' } })
require('zpack').setup({ spec = { { 'user/plugin' } } }) -- or via the spec field
]]
  },
}

M.deprecated = {
  confirm = {
    message = "opts.confirm is deprecated. Use opts.defaults.confirm instead:",
    replacement = "require('zpack').setup({ defaults = { confirm = false } })",
  },
  disable_vim_loader = {
    message = "opts.disable_vim_loader is deprecated. Use opts.performance.vim_loader instead:",
    replacement = "require('zpack').setup({ performance = { vim_loader = false } })",
  },
  plugins_dir = {
    message = "opts.plugins_dir is deprecated. Use { import = 'dir' } in spec instead:",
    replacement = "require('zpack').setup({ { import = 'plugins' } })",
  },
}

M.notify_removed = function(key)
  local entry = M.removed[key]
  if not entry then return end
  utils.schedule_notify(
    ("REMOVED: %s\n\n%s"):format(entry.message, entry.replacement),
    vim.log.levels.WARN
  )
end

M.notify_deprecated = function(key)
  local entry = M.deprecated[key]
  if not entry then return end
  utils.schedule_notify(
    ("DEPRECATED: %s\n\n%s"):format(entry.message, entry.replacement),
    vim.log.levels.WARN
  )
end

return M
