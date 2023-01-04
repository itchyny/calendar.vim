" =============================================================================
" Filename: autoload/calendar/util.vim
" Author: itchyny
" License: MIT License
" Last Change: 2023/01/05 08:33:15.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

" Name of this application.
function! calendar#util#name() abort
  return 'calendar.vim'
endfunction

" License of this application.
function! calendar#util#license() abort
  return 'MIT License'
endfunction

" Name of the author.
function! calendar#util#author() abort
  return 'itchyny (https://github.com/itchyny)'
endfunction

" Repository URL.
function! calendar#util#repository() abort
  return 'https://github.com/itchyny/calendar.vim'
endfunction

" Bug tracker URL.
function! calendar#util#issue() abort
  return 'https://github.com/itchyny/calendar.vim/issues'
endfunction

" winwidth
" Take the minimum width if the calendar buffer is displayed in multiple
" windows. For example, a calendar is viewed on a vertically splitted window
" and execute top new.
function! calendar#util#winwidth() abort
  return min(map(filter(range(1,winnr('$')),'winbufnr(v:val)==winbufnr(0)'),'winwidth(v:val)'))-1
endfunction

" winheight
" Take the minimum height.
function! calendar#util#winheight() abort
  return min(map(filter(range(1,winnr('$')),'winbufnr(v:val)==winbufnr(0)'),'winheight(v:val)'))
endfunction

" Used for the return value of cnoremap.
function! calendar#util#update_keys() abort
  silent! call histadd(':', getcmdline())
  return "\<End>\<C-u>silent call b:calendar.update()\<CR>"
endfunction

" Get the command line, substituting the leading colons.
function! calendar#util#getcmdline() abort
  return substitute(getcmdline(), '^\(\s*:\)*\s*', '', '')
endfunction

" Yank text
function! calendar#util#yank(text) abort
  let @" = a:text
  if has('clipboard') || has('xterm_clipboard')
    let @+ = a:text
  endif
endfunction

" Id generator
let s:id = 0
function! calendar#util#id() abort
  let [y, m, d] = calendar#day#today().get_ymd()
  let [h, i, s] = calendar#time#now().get_hms()
  let s:id = (s:id + 1) % 10000
  return printf('%04d%02d%02d%02d%02d%02d%04d', y, m, d, h, i, s, s:id)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
