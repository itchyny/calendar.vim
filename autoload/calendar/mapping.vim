" =============================================================================
" Filename: autoload/calendar/mapping.vim
" Author: itchyny
" License: MIT License
" Last Change: 2014/12/07 19:47:53.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

" Setting mappings in the calendar buffer.

function! calendar#mapping#new()

  let save_cpo = &cpo
  set cpo&vim

  if &l:filetype ==# 'calendar'
    if has_key(get(b:, 'calendar', {}), 'view')
      let v = b:calendar.view
      if maparg('<ESC>', 'n') !=# '<Plug>(calendar_escape)'
        if v._help || v._event || v._task || b:calendar.visual_mode()
          if v:version > 703
            nmap <buffer><nowait> <ESC> <Plug>(calendar_escape)
          else
            nmap <buffer>         <ESC> <Plug>(calendar_escape)
          endif
        endif
      else
        if !(v._help || v._event || v._task || b:calendar.visual_mode())
          nunmap <buffer> <ESC>
        endif
      endif
    endif
    let &cpo = save_cpo
    return
  endif

  " normal mode mapping
  let actions = ['left', 'right', 'down', 'up', 'prev', 'next', 'move_down', 'move_up',
        \ 'down_big', 'up_big', 'down_large', 'up_large',
        \ 'line_head', 'line_middle', 'line_last', 'bar',
        \ 'first_line', 'last_line', 'first_line_head', 'last_line_last', 'space',
        \ 'scroll_top_head', 'scroll_top', 'scroll_center_head', 'scroll_center', 'scroll_bottom_head', 'scroll_bottom',
        \ 'add', 'subtract', 'status', 'plus', 'minus', 'task', 'event', 'close_task', 'close_event',
        \ 'delete', 'delete_line', 'yank', 'yank_line', 'change', 'change_line',
        \ 'undo', 'undo_line', 'tab', 'shift_tab',
        \ 'today', 'enter', 'view_left',  'view_right', 'redraw', 'clear', 'help', 'hide', 'exit',
        \ 'visual', 'visual_line', 'visual_block', 'exit_visual',
        \ 'start_insert', 'start_insert_append', 'start_insert_head', 'start_insert_last',
        \ 'start_insert_prev_line', 'start_insert_next_line',
        \ ]
  for action in actions
    exec printf("nnoremap <buffer><silent> <Plug>(calendar_%s) :<C-u>call b:calendar.action('%s')<CR>", action, action)
  endfor

  " escape
  nmap <buffer><silent><expr> <Plug>(calendar_escape)
        \ b:calendar.view._help ? "\<Plug>(calendar_help)" :
        \ b:calendar.view._event ? "\<Plug>(calendar_event)" :
        \ b:calendar.visual_mode() ? "\<Plug>(calendar_exit_visual)" :
        \ b:calendar.view._task ? "\<Plug>(calendar_task)" :
        \ ""

  " mark
  let marks = map(range(97, 97 + 25), 'nr2char(v:val)')
  for mark in marks
    exec printf("nmap <buffer><silent> m%s :<C-u>call b:calendar.mark.set('%s')<CR>", mark, mark)
    exec printf("nmap <buffer><silent> `%s :<C-u>call b:calendar.mark.get('%s')<CR>", mark, mark)
    exec printf("nmap <buffer><silent> '%s :<C-u>call b:calendar.mark.get('%s')<CR>", mark, mark)
    exec printf("nmap <buffer><silent> g`%s :<C-u>call b:calendar.mark.get('%s')<CR>", mark, mark)
    exec printf("nmap <buffer><silent> g'%s :<C-u>call b:calendar.mark.get('%s')<CR>", mark, mark)
  endfor
  for mark in ['`', "'"]
    exec printf("nmap <buffer><silent> %s%s :<C-u>call b:calendar.mark.get('%s')<CR>", mark, mark, mark ==# "'" ? mark . mark : mark)
  endfor

  " command line mapping
  cnoremap <buffer><silent><expr> <Plug>(calendar_command_enter) b:calendar.action('command_enter')

  let l:default_nmappings = {}
  
  " move neighborhood/page
  let l:default_nmappings['<Plug>(calendar_left)']       = ['h', '<Left>', '<BS>', '<C-h>', 'gh', 'g<Left>']
  let l:default_nmappings['<Plug>(calendar_right)']      = ['l', '<Right>', 'gl', 'g<Right>']
  let l:default_nmappings['<Plug>(calendar_down)']       = ['j', '<Down>', 'gj', 'g<Down>', '<S-Down>', '<C-e>', '<C-n>']
  let l:default_nmappings['<Plug>(calendar_up)']         = ['k', '<Up>', 'gk', 'g<Up>', '<S-Up>', '<C-y>', '<C-p>']
  let l:default_nmappings['<Plug>(calendar_move_down)']  = ['<C-j>', '<C-S-Down>']
  let l:default_nmappings['<Plug>(calendar_move_up)']    = ['<C-k>', '<C-S-Up>']
  let l:default_nmappings['<Plug>(calendar_next)']       = ['w', 'W', 'e', '<S-Right>', '<C-Right>']
  let l:default_nmappings['<Plug>(calendar_prev)']       = ['b', 'B', 'ge', 'gE', '<S-Left>', '<C-Left>']
  let l:default_nmappings['<Plug>(calendar_down_big)']   = ['<C-d>']
  let l:default_nmappings['<Plug>(calendar_up_big)']     = ['<C-u>']
  let l:default_nmappings['<Plug>(calendar_down_large)'] = ['<C-f>', '<PageDown>']
  let l:default_nmappings['<Plug>(calendar_up_large)']   = ['<C-b>', '<PageUp>']
  
  " move column
  let l:default_nmappings['<Plug>(calendar_line_head)']      = ['0', '^', 'g0', '<Home>', 'g<Home>', 'g^']
  let l:default_nmappings['<Plug>(calendar_line_middle)']    = ['gm']
  let l:default_nmappings['<Plug>(calendar_line_last)']      = ['$', 'g$', 'g_', '<End>', 'g<End>']
  let l:default_nmappings['<Plug>(calendar_first_line)']     = ['gg', '<C-Home>', '(', '{', '[[', '[]']
  let l:default_nmappings['<Plug>(calendar_last_line)']      = ['G', ')', '}', ']]', '][']
  let l:default_nmappings['<Plug>(calendar_last_line_last)'] = ['<C-End>']
  let l:default_nmappings['<Plug>(calendar_bar)']            = ['<Bar>']
  
  " scroll
  let l:default_nmappings['<Plug>(calendar_scroll_top_head)']    = ['z<CR>']
  let l:default_nmappings['<Plug>(calendar_scroll_top)']         = ['zt']
  let l:default_nmappings['<Plug>(calendar_scroll_center_head)'] = ['z.']
  let l:default_nmappings['<Plug>(calendar_scroll_center)']      = ['zz']
  let l:default_nmappings['<Plug>(calendar_scroll_bottom_head)'] = ['z-']
  let l:default_nmappings['<Plug>(calendar_scroll_bottom)']      = ['zb']
  
  " delete
  let l:default_nmappings['<Plug>(calendar_delete)']      = ['d']
  let l:default_nmappings['<Plug>(calendar_delete_line)'] = ['D']
  
  " yank
  let l:default_nmappings['<Plug>(calendar_yank)']      = ['y']
  let l:default_nmappings['<Plug>(calendar_yank_line)'] = ['Y']
  
  " change
  let l:default_nmappings['<Plug>(calendar_change)']      = ['c']
  let l:default_nmappings['<Plug>(calendar_change_line)'] = ['C']
  
  " utility
  let l:default_nmappings['<Plug>(calendar_undo)']       = ['<Undo>', 'u']
  let l:default_nmappings['<Plug>(calendar_undo_line)']  = ['U']
  let l:default_nmappings['<Plug>(calendar_tab)']        = ['<TAB>']
  let l:default_nmappings['<Plug>(calendar_shift_tab)']  = ['<S-Tab>']
  let l:default_nmappings['<Plug>(calendar_today)']      = ['t']
  let l:default_nmappings['<Plug>(calendar_enter)']      = ['<CR>']
  let l:default_nmappings['<Plug>(calendar_add)']        = ['<C-a>']
  let l:default_nmappings['<Plug>(calendar_subtract)']   = ['<C-x>']
  let l:default_nmappings['<Plug>(calendar_status)']     = ['<C-g>']
  let l:default_nmappings['<Plug>(calendar_plus)']       = ['+']
  let l:default_nmappings['<Plug>(calendar_minus)']      = ['-']
  let l:default_nmappings['<Plug>(calendar_task)']       = ['T']
  let l:default_nmappings['<Plug>(calendar_event)']      = ['E']
  let l:default_nmappings['<Plug>(calendar_view_left)']  = ['<']
  let l:default_nmappings['<Plug>(calendar_view_right)'] = ['>']
  let l:default_nmappings['<Plug>(calendar_space)']      = ['<Space>']
  let l:default_nmappings['<Plug>(calendar_redraw)']     = ['<C-l>', '<C-r>']
  let l:default_nmappings['<Plug>(calendar_clear)']      = ['L']
  let l:default_nmappings['<Plug>(calendar_help)']       = ['?']
  let l:default_nmappings['<Plug>(calendar_hide)']       = ['q']
  let l:default_nmappings['<Plug>(calendar_exit)']       = ['Q']
  
  " nop
  let l:default_nmappings['<Nop>'] = ['H', 'M', 'J', 'p', 'P', 'r', 'R', '~']
  
  " insert mode
  let l:default_nmappings['<Plug>(calendar_start_insert)']           = ['i']
  let l:default_nmappings['<Plug>(calendar_start_insert_append)']    = ['a']
  let l:default_nmappings['<Plug>(calendar_start_insert_head)']      = ['I']
  let l:default_nmappings['<Plug>(calendar_start_insert_last)']      = ['A']
  let l:default_nmappings['<Plug>(calendar_start_insert_prev_line)'] = ['O']
  let l:default_nmappings['<Plug>(calendar_start_insert_next_line)'] = ['o']
  
  " visual mode
  let l:default_nmappings['<Plug>(calendar_visual)']       = ['v', 'gh']
  let l:default_nmappings['<Plug>(calendar_visual_line)']  = ['V', 'gH']
  let l:default_nmappings['<Plug>(calendar_visual_block)'] = ['<C-v>', 'g<C-h>']
  
  " check for user defined mappings
  if !exists('g:calendar_nmappings')
    let g:calendar_nmappings = l:default_nmappings
  else
    for key in keys(l:default_nmappings)
      if !has_key(g:calendar_nmappings, key)
        let g:calendar_nmappings[key] = l:default_nmappings[key]     
      endif
    endfor
  endif

  " apply normal mode mappings
  for key in keys(g:calendar_nmappings)
     for elem in g:calendar_nmappings[key]
        exe 'nmap <buffer> '.elem.' '.key
     endfor
  endfor

  " command line
  cmap <buffer> <CR> <Plug>(calendar_command_enter)

  " mouse wheel
  map <buffer> <ScrollWheelUp> <Plug>(calendar_prev)
  map <buffer> <ScrollWheelDown> <Plug>(calendar_next)

  let &cpo = save_cpo

endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
