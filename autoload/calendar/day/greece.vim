" =============================================================================
" Filename: autoload/calendar/day/greece.vim
" Author: itchyny
" License: MIT License
" Last Change: 2013/10/25 17:14:35.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

let s:constructor = calendar#constructor#day_hybrid#new(1923, 3, 1)

function! calendar#day#greece#new(y, m, d)
  return s:constructor.new(a:y, a:m, a:d)
endfunction

function! calendar#day#greece#new_mjd(mjd)
  return s:constructor.new_mjd(a:mjd)
endfunction

function! calendar#day#greece#today()
  return s:constructor.today()
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
