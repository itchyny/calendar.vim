" =============================================================================
" Filename: autoload/calendar/day/bulgaria.vim
" Author: itchyny
" License: MIT License
" Last Change: 2013/10/25 17:11:17.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

let s:constructor = calendar#constructor#day_hybrid#new(1916, 4, 14)

function! calendar#day#bulgaria#new(y, m, d)
  return s:constructor.new(a:y, a:m, a:d)
endfunction

function! calendar#day#bulgaria#new_mjd(mjd)
  return s:constructor.new_mjd(a:mjd)
endfunction

function! calendar#day#bulgaria#today()
  return s:constructor.today()
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
