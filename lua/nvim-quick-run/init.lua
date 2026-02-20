-- 在垂直分割窗口中运行命令并显示输出

local M = {}

--- 运行指定命令并在新垂直分割窗口中显示输出
-- @param cmd string 要执行的命令
function M.run_command(cmd)
  if not cmd or cmd == "" then
    print("未指定命令")
    return
  end

  -- 1. 创建新缓冲区
  local buf = vim.api.nvim_create_buf(true, true)                   -- 列表缓冲区，不关联文件
  vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = buf }) -- 窗口关闭时删除缓冲区
  vim.api.nvim_set_option_value('buftype', 'nofile', { buf = buf }) -- 无文件缓冲区
  vim.api.nvim_set_option_value('swapfile', false, { buf = buf })   -- 禁用交换文件
  vim.api.nvim_set_option_value('modifiable', true, { buf = buf })  -- 临时可写，用于填充内容

  -- 2. 创建垂直分割窗口（右侧分割）
  vim.api.nvim_command('rightbelow vnew')
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf) -- 将缓冲区附加到窗口

  -- 3. 设置窗口选项
  vim.api.nvim_set_option_value('wrap', false, { win = win })      -- 自动换行
  vim.api.nvim_set_option_value('cursorline', true, { win = win }) -- 显示光标行

  -- 4. 执行命令并捕获输出
  local output = vim.fn.system(cmd)
  if output == "" then
    output = "命令未打印输出"
  end

  if vim.v.shell_error ~= 0 then
    output = "命令执行失败，错误信息：\n" .. output
  end

  -- 5. 将输出按行分割并写入缓冲区
  local lines = vim.split(output, "\n")
  -- 去除末尾空行（如果存在）
  while #lines > 0 and lines[#lines] == "" do
    table.remove(lines)
  end
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  -- 6. 将缓冲区设为只读，防止意外修改
  vim.api.nvim_set_option_value('modifiable', false, { buf = buf })
  vim.api.nvim_set_option_value('readonly', true, { buf = buf })

  -- 7. 设置缓冲区本地按键映射：q 和 <Esc> 关闭窗口
  local opts = { noremap = true, silent = true }
  vim.api.nvim_buf_set_keymap(buf, 'n', 'q', ':close<CR>', opts)
  vim.api.nvim_buf_set_keymap(buf, 'n', '<Esc>', ':close<CR>', opts)

  -- 8. 提示信息（可选）
  print("命令已执行，按 q 或 <Esc> 关闭窗口")
end

-- 定义用户命令 :RunInSplit {command}
vim.api.nvim_create_user_command(
  'QuickRun',
  function(opts)
    M.run_command(opts.args)
  end,
  { nargs = 1, complete = 'command' } -- 支持命令补全
)

return M
