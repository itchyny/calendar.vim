" =============================================================================
" Filename: autoload/calendar/day/holland.vim
" Author: itchyny
" License: MIT License
" Last Change: 2013/10/19 18:11:33.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

let s:constructor = calendar#constructor#day_hybrid#new(1583, 1, 1)

function! calendar#day#holland#new(y, m, d)
  return s:constructor.new(a:y, a:m, a:d)
endfunction

function! calendar#day#holland#new_mjd(mjd)
  return s:constructor.new_mjd(a:mjd)
endfunction

function! calendar#day#holland#today()
  return s:constructor.today()
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
