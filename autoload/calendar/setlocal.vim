" =============================================================================
" Filename: autoload/calendar/setlocal.vim
" Author: itchyny
" License: MIT License
" Last Change: 2022/12/04 12:54:35.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

" All the setlocal commands are executed using the functions in this file.

" Set all the local settings for the current calendar buffer.
function! calendar#setlocal#new() abort
  setlocal nomodifiable buftype=nofile noswapfile readonly
        \ bufhidden=hide wrap nowrap nobuflisted nofoldenable foldcolumn=0
        \ nolist completefunc= omnifunc=
        \ nocursorcolumn nocursorline nomodeline
        \ nonumber norelativenumber undolevels=-1 colorcolumn=
  call calendar#setlocal#filetype()
endfunction

" Set modifiable so that the controller can modify the contents in the buffer.
function! calendar#setlocal#modifiable() abort
  setlocal modifiable noreadonly
endfunction

" Set nomodifiable after the controller modify the contents in the buffer.
function! calendar#setlocal#nomodifiable() abort
  setlocal nomodifiable readonly
endfunction

" Set filetype once.
function! calendar#setlocal#filetype() abort
  if &l:filetype !=# 'calendar'
    setlocal filetype=calendar
  endif
endfunction

" Set filetype forcibly. (see 'autocmd ColorScheme' in autocmd.vim)
function! calendar#setlocal#filetype_force() abort
  setlocal filetype=
  setlocal filetype=calendar
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
