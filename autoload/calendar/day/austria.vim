" =============================================================================
" Filename: autoload/calendar/day/austria.vim
" Author: itchyny
" License: MIT License
" Last Change: 2013/10/25 17:01:23.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

" Brixen, Salzburg and Tyrol
let s:constructor = calendar#constructor#day_hybrid#new(1583, 10, 16)

function! calendar#day#austria#new(y, m, d)
  return s:constructor.new(a:y, a:m, a:d)
endfunction

function! calendar#day#austria#new_mjd(mjd)
  return s:constructor.new_mjd(a:mjd)
endfunction

function! calendar#day#austria#today()
  return s:constructor.today()
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
