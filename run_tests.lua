local project_root = vim.fn.getcwd()

if vim.fn.filereadable(project_root .. '/run_tests.lua') == 0 then
  error('run_tests.lua must be run from the zpack.nvim root directory. Are you in the right directory?')
end

package.path = project_root .. '/lua/?.lua;'
  .. project_root .. '/lua/?/init.lua;'
  .. project_root .. '/tests/?.lua;'
  .. package.path

require('run_all')
vim.cmd('qa!')
