" =============================================================================
" Filename: autoload/calendar/day/hungary.vim
" Author: itchyny
" License: MIT License
" Last Change: 2013/10/25 17:05:08.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

let s:constructor = calendar#constructor#day_hybrid#new(1587, 11, 1)

function! calendar#day#hungary#new(y, m, d)
  return s:constructor.new(a:y, a:m, a:d)
endfunction

function! calendar#day#hungary#new_mjd(mjd)
  return s:constructor.new_mjd(a:mjd)
endfunction

function! calendar#day#hungary#today()
  return s:constructor.today()
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
