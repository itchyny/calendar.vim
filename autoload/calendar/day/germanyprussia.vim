" =============================================================================
" Filename: autoload/calendar/day/germanyprussia.vim
" Author: itchyny
" License: MIT License
" Last Change: 2013/12/26 15:37:50.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

let s:constructor = calendar#constructor#day_hybrid#new(1610, 9, 2)

function! calendar#day#germanyprussia#new(y, m, d)
  return s:constructor.new(a:y, a:m, a:d)
endfunction

function! calendar#day#germanyprussia#new_mjd(mjd)
  return s:constructor.new_mjd(a:mjd)
endfunction

function! calendar#day#germanyprussia#today()
  return s:constructor.today()
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
