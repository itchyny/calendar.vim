" =============================================================================
" Filename: autoload/calendar/view/day_7.vim
" Author: itchyny
" License: MIT License
" Last Change: 2013/12/31 14:26:39.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

function! calendar#view#day_7#new(source)
  return s:constructor.new(a:source)
endfunction

let s:self = {}
let s:self.daynum = 7

let s:constructor = calendar#constructor#view_days#new(s:self)

let &cpo = s:save_cpo
unlet s:save_cpo
