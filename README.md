NeoTerm.lua
-----

Attach a term-buffer for each window.

## DEMO

https://user-images.githubusercontent.com/24765272/174679989-55301311-632a-4abe-9521-1df890f47f54.mov


## Feat.

- ~0ms load time (=150 lines)
- Built from the best layout-preserving buffer deletion plugin [`nyngwang/NeoNoName.lua`](https://github.com/nyngwang/NeoNoName.lua)
- Focus on UX:
  - Easy to config (you won't forget how to update the config 10 years later)
  - Copy-paste-and-lets-go config below
  - Auto enter insert-mode on `BufEnter` termbuf (Wow)
  - Customizable(`term_mode_hl`) background color on enter termbuf insert-mode (Wow!)
  - Stabilized layout on toggle (`row`,`col`,`topline` are all kept)
- Compatibility with other plugins
  - [`akinsho/bufferline.nvim`](https://github.com/akinsho/bufferline.nvim):
    - Feat. support: Call `BufferLineCycleNext/Prev` from termbuf insert-mode (Wow)
    - Example provided below (Go copy-paste it!)


## Config

```lua
local NOREF_NOERR_TRUNC = { noremap = true, silent = true, nowait = true }

use {
  'nyngwang/NeoTerm.lua',
  requires = { 'nyngwang/NeoNoName.lua' },
  config = function ()
    require('neo-term').setup {
      -- term_mode_hl = 'CoolBlack' -- this is #101010
      -- split_size = 0.35
    }
    vim.keymap.set('n', '<M-Tab>', function ()
      if vim.bo.buftype == 'terminal' then vim.cmd('normal! a')
      else vim.cmd('NeoTermOpen') end
    end, NOREF_NOERR_TRUNC)
    vim.keymap.set('t', '<M-Tab>', function () vim.cmd('NeoTermClose') end, NOREF_NOERR_TRUNC)
    vim.keymap.set('t', '<C-w>', function () vim.cmd('NeoTermEnterNormal') end, NOREF_NOERR_TRUNC)
  end
}
```

My extreme customization example:

```lua
    local split_wins = {}
    vim.keymap.set('n', '<M-Tab>', function ()
      if vim.bo.filetype == 'neo-tree' then return end
      local cur_win = vim.api.nvim_get_current_win()
      if split_wins[cur_win] then
        if vim.bo.buftype == 'terminal' then vim.cmd('normal! a')
        else
          vim.cmd('q')
          table.remove(split_wins, cur_win)
        end
        return
      end
      -- cur_win is a new parent
      vim.cmd('NeoTermOpen')
      split_wins[vim.api.nvim_get_current_win()] = true
    end, NOREF_NOERR_TRUNC)
    vim.keymap.set('t', '<M-Tab>', function ()
      table.remove(split_wins, vim.api.nvim_get_current_win())
      vim.cmd('NeoTermClose')
    end, NOREF_NOERR_TRUNC)
```


### bufferline.nvim

```lua
local NOREF_NOERR_TRUNC = { noremap = true, silent = true, nowait = true }
local EXPR_NOREF_NOERR_TRUNC = { expr = true, noremap = true, silent = true, nowait = true }

-- Swap Adjacent Buffer-Tab's
vim.keymap.set('t', '<M-}>', function ()
  require('neo-term').remove_augroup_resetwinhl()
  return '<C-\\><C-N> | <cmd>normal <M-}><CR>'
end, EXPR_NOREF_NOERR_TRUNC)
vim.keymap.set('n', '<M-}>', function ()
  vim.cmd('BufferLineCycleNext')
  vim.cmd('normal M')
end, NOREF_NOERR_TRUNC)
vim.keymap.set('t', '<M-{>', function ()
  require('neo-term').remove_augroup_resetwinhl()
  return '<C-\\><C-N> | <cmd>normal <M-{><CR>'
end, EXPR_NOREF_NOERR_TRUNC)
vim.keymap.set('n', '<M-{>', function ()
  vim.cmd('BufferLineCyclePrev')
  vim.cmd('normal M')
end, NOREF_NOERR_TRUNC)
```

Result:

https://user-images.githubusercontent.com/24765272/174679408-ec594bb9-a04e-4c40-bc27-ca774abdc196.mov

