" =============================================================================
" Filename: autoload/calendar/view/month_4x2.vim
" Author: itchyny
" License: MIT License
" Last Change: 2015/03/29 06:33:38.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

function! calendar#view#month_4x2#new(source) abort
  return s:constructor.new(a:source)
endfunction

let s:self = {}
let s:self.x_months = 4
let s:self.y_months = 2

let s:constructor = calendar#constructor#view_months#new(s:self)

let &cpo = s:save_cpo
unlet s:save_cpo
