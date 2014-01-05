" =============================================================================
" Filename: autoload/calendar/view/day.vim
" Author: itchyny
" License: MIT License
" Last Change: 2013/12/31 14:36:19.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

function! calendar#view#day#new(source)
  return s:constructor.new(a:source)
endfunction

let s:self = {}
let s:self.daynum = 1

let s:constructor = calendar#constructor#view_days#new(s:self)

let &cpo = s:save_cpo
unlet s:save_cpo
