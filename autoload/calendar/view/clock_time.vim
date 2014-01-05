" =============================================================================
" Filename: autoload/calendar/view/clock_time.vim
" Author: itchyny
" License: MIT License
" Last Change: 2013/12/09 23:13:11.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

function! calendar#view#clock_time#new(source)
  return s:constructor.new(a:source)
endfunction

let s:self = {}
let s:self.y_height = 1
let s:self.colnum = 2

function! s:self.max_letter() dict
  return ['20:33:33']
endfunction

function! s:self.get_letter() dict
  let [h, m, s] = calendar#time#now().get_hms()
  return [printf('%d:%02d:%02d', h, m, s)]
endfunction

let s:constructor = calendar#constructor#view_clock#new(s:self)

let &cpo = s:save_cpo
unlet s:save_cpo
