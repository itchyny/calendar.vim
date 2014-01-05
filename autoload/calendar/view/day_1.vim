" =============================================================================
" Filename: autoload/calendar/view/day_1.vim
" Author: itchyny
" License: MIT License
" Last Change: 2013/12/08 09:53:19.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

function! calendar#view#day_1#new(source)
  return s:constructor.new(a:source)
endfunction

let s:self = {}
let s:self.daynum = 1

let s:constructor = calendar#constructor#view_days#new(s:self)

let &cpo = s:save_cpo
unlet s:save_cpo
