" =============================================================================
" Filename: autoload/calendar/day/russia.vim
" Author: itchyny
" License: MIT License
" Last Change: 2013/10/19 18:11:31.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

let s:constructor = calendar#constructor#day_hybrid#new(1918, 2, 14)

function! calendar#day#russia#new(y, m, d)
  return s:constructor.new(a:y, a:m, a:d)
endfunction

function! calendar#day#russia#new_mjd(mjd)
  return s:constructor.new_mjd(a:mjd)
endfunction

function! calendar#day#russia#today()
  return s:constructor.today()
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
