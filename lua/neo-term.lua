vim.api.nvim_create_augroup('neo-term.lua', { clear = true })
-------------------------------------------------------------------------------------------------------
local M = { }
local _parent_buf_to_term_buf = { }
local _enter_views = { }
local _open_win_to_term_win = { }


local function remove_invalid_mappings()
  for i, v in ipairs(_parent_buf_to_term_buf) do
    if not (
        vim.api.nvim_buf_is_valid(i)
        and vim.api.nvim_buf_is_valid(v)
      ) then
      _parent_buf_to_term_buf[i] = nil
    end
  end
  for i, v in ipairs(_open_win_to_term_win) do
    if v ~= nil
      and not vim.api.nvim_win_is_valid(v) then
      _open_win_to_term_win[i] = nil
    end
  end
end

local function add_cool_black()
  vim.api.nvim_create_autocmd({ 'VimEnter', 'ColorScheme' }, {
    group = 'neo-term.lua',
    pattern = '*',
    callback = function () vim.cmd('hi __NEO_TERM_COOL_BLACK guibg=#101010') end
  })
end
add_cool_black()

-------------------------------------------------------------------------------------------------------

function M.setup(opt)
  M.term_mode_hl = opt.term_mode_hl ~= nil and opt.term_mode_hl or '__NEO_TERM_COOL_BLACK'
  M.split_size = opt.split_size ~= nil and opt.split_size or 0.35
  M.split_on_top = opt.split_on_top ~= nil and opt.split_on_top or false
  M.exclude_filetypes = opt.exclude_filetypes ~= nil and opt.exclude_filetypes or {}
  M.exclude_buftypes = opt.exclude_buftypes ~= nil and opt.exclude_buftypes or {}

  -- Setup pivots
  vim.api.nvim_create_autocmd({ 'BufEnter', 'TermLeave' }, {
    group = 'neo-term.lua',
    pattern = '*',
    callback = function ()
      remove_invalid_mappings()
      vim.cmd('set winhl=') -- Start from no highlight.
    end
  })
  vim.api.nvim_create_autocmd({ 'BufEnter', 'TermOpen' }, {
    group = 'neo-term.lua',
    pattern = 'term://*',
    callback = function ()
      if vim.api.nvim_buf_get_option(0, 'buflisted') then
        vim.cmd('startinsert') -- Auto-`a` on enter termbuf.
        vim.api.nvim_create_augroup('neo-term.lua/ResetWinhl', { clear = true })
        vim.api.nvim_create_autocmd('TermEnter', {
          -- Enable au-`ResetWinhl` on enter termbuf.
          group = 'neo-term.lua/ResetWinhl',
          pattern = '*',
          command = string.gsub(
            [[ if &buflisted | set winhl=Normal:$term_mode_hl | endif ]],
            '$(%S+)',
            { term_mode_hl = M.term_mode_hl }
          )
        })
      end
    end
  })
  vim.api.nvim_create_autocmd('BufLeave', {
    group = 'neo-term.lua',
    pattern = 'term://*',
    callback = function ()
      if vim.api.nvim_buf_get_option(0, 'buflisted') then
        vim.cmd('stopinsert') -- Disable auto-`a` on exit termbuf.
      end
    end
  })
end

function M.open_termbuf()
  for _, v in ipairs(M.exclude_filetypes) do if vim.bo.filetype == v then return end end
  for _, v in ipairs(M.exclude_buftypes) do if vim.bo.buftype == v then return end end

  local open_win = vim.api.nvim_get_current_win()
  local _term_win = _open_win_to_term_win[open_win]
  -- should leave immediately on open_win hit.
  if _term_win ~= nil and vim.api.nvim_win_is_valid(_term_win) then
    vim.api.nvim_set_current_win(_term_win)
    return
  end

  local parent_buf = vim.api.nvim_get_current_buf()
  local parent_win_height = vim.fn.getwininfo(vim.api.nvim_get_current_win())[1].height
  local termbuf_size = parent_win_height * M.split_size
  local parent_size = parent_win_height - termbuf_size

  -- this makes things easier
  local _splitbelow = vim.opt.splitbelow
  _enter_views[vim.api.nvim_get_current_buf()] = vim.fn.winsaveview()
  if M.split_on_top then
    vim.opt.splitbelow = false
  else
    vim.opt.splitbelow = true
  end

  if M.split_on_top then
    vim.cmd('normal! L')
  else
    vim.cmd('normal! H')
  end
  vim.cmd('split')
  vim.cmd('resize ' .. termbuf_size)
  vim.cmd('wincmd p')
  vim.cmd('resize ' .. parent_size)
  vim.cmd('wincmd p') -- cursor at termbuf split
  local term_win = vim.api.nvim_get_current_win()
  _open_win_to_term_win[open_win] = term_win

  if -- termbuf for this buf exists
    _parent_buf_to_term_buf[parent_buf] ~= nil
    and vim.api.nvim_buf_is_valid(_parent_buf_to_term_buf[parent_buf]) then
    vim.api.nvim_set_current_buf(_parent_buf_to_term_buf[parent_buf])
  else
    vim.cmd('term')
    _parent_buf_to_term_buf[parent_buf] = vim.api.nvim_win_get_buf(0)
  end

  vim.opt.splitbelow = _splitbelow
end

function M.close_termbuf()
  -- double check for users.
  if not vim.bo.buftype == 'terminal' then return end
  vim.cmd('NeoTermEnterNormal')

  local term_buf = vim.api.nvim_get_current_buf()
  vim.cmd('q')
  local final_buf = vim.api.nvim_get_current_buf()
  if _parent_buf_to_term_buf[final_buf] == term_buf then
    vim.fn.winrestview(_enter_views[final_buf])
  end
end

function M.remove_augroup_resetwinhl()
  vim.api.nvim_create_augroup('neo-term.lua/ResetWinhl', { clear = true })
end

local function setup_vim_commands()
  vim.cmd [[
    command! NeoTermOpen lua require'neo-term'.open_termbuf()
    command! NeoTermClose lua require'neo-term'.close_termbuf()
    command! NeoTermEnterNormal lua vim.api.nvim_feedkeys('', 't', true)
  ]]
end

setup_vim_commands()

return M
