" =============================================================================
" Filename: autoload/calendar/day/spain.vim
" Author: itchyny
" License: MIT License
" Last Change: 2013/10/25 16:58:06.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

let s:constructor = calendar#constructor#day_hybrid#new(1582, 10, 15)

function! calendar#day#spain#new(y, m, d)
  return s:constructor.new(a:y, a:m, a:d)
endfunction

function! calendar#day#spain#new_mjd(mjd)
  return s:constructor.new_mjd(a:mjd)
endfunction

function! calendar#day#spain#today()
  return s:constructor.today()
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
