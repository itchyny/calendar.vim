" =============================================================================
" Filename: autoload/calendar/view/ymd_monthdayyear.vim
" Author: itchyny
" License: MIT License
" Last Change: 2015/03/29 06:34:01.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

function! calendar#view#ymd_monthdayyear#new(source) abort
  return s:constructor.new(a:source)
endfunction

let s:self = {}

let s:self.ymd = [ 'month', 'day', 'year' ]

let s:constructor = calendar#constructor#view_ymd#new(s:self)

let &cpo = s:save_cpo
unlet s:save_cpo
