" =============================================================================
" Filename: autoload/calendar/view/day_3.vim
" Author: itchyny
" License: MIT License
" Last Change: 2015/03/29 06:32:55.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

function! calendar#view#day_3#new(source) abort
  return s:constructor.new(a:source)
endfunction

let s:self = {}
let s:self.daynum = 3

let s:constructor = calendar#constructor#view_days#new(s:self)

let &cpo = s:save_cpo
unlet s:save_cpo
