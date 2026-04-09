local M = {}

local triggers = {
  FileType = "BufReadPost",
  BufReadPost = "BufReadPre",
}

---@param event string
---@return string[]
local function build_chain(event)
  local chain = {}
  local current = event
  while current do
    table.insert(chain, 1, current)
    current = triggers[current]
  end
  return chain
end

---@param event string
---@return table<string, table<number, boolean>?>
M.snapshot = function(event)
  local chain = build_chain(event)
  local snap = {}
  for _, ev in ipairs(chain) do
    if ev == "FileType" then
      snap[ev] = nil
    else
      local existing = {}
      for _, au in ipairs(vim.api.nvim_get_autocmds({ event = ev })) do
        if au.group then
          existing[au.group] = true
        end
      end
      snap[ev] = existing
    end
  end
  return snap
end

---@param ev string
---@param buf number
---@param ev_data? any
---@param snap table<string, table<number, boolean>?>
local function fire_new_groups(ev, buf, ev_data, snap)
  local pre_existing = snap[ev]
  if pre_existing == nil then
    pcall(vim.api.nvim_exec_autocmds, ev, {
      buffer = buf,
      data = ev_data,
      modeline = false,
    })
    return
  end

  local fired = {}
  for _, au in ipairs(vim.api.nvim_get_autocmds({ event = ev })) do
    if au.group and not pre_existing[au.group] and not fired[au.group] then
      fired[au.group] = true
      pcall(vim.api.nvim_exec_autocmds, ev, {
        buffer = buf,
        group = au.group_name,
        data = ev_data,
        modeline = false,
      })
    end
  end
end

---@param event string
---@param buf number
---@param data? any
---@param snapshot table<string, table<number, boolean>?>
M.exec = function(event, buf, data, snapshot)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  local chain = build_chain(event)

  for _, ev in ipairs(chain) do
    if not vim.api.nvim_buf_is_valid(buf) then
      return
    end
    fire_new_groups(ev, buf, ev == event and data or nil, snapshot)
  end
end

return M
