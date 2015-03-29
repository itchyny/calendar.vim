" =============================================================================
" Filename: autoload/calendar/view/clock_time_hourmin.vim
" Author: itchyny
" License: MIT License
" Last Change: 2015/03/29 06:32:52.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

function! calendar#view#clock_time_hourmin#new(source) abort
  return s:constructor.new(a:source)
endfunction

let s:self = {}
let s:self.y_height = 1
let s:self.colnum = 2

function! s:self.max_letter() dict abort
  return ['20:33']
endfunction

function! s:self.get_letter() dict abort
  let [h, m, s] = calendar#time#now().get_hms()
  if calendar#setting#get('clock_12hour')
    let h = calendar#time#hour12(h)
  endif
  return [printf('%d:%02d', h, m)]
endfunction

let s:constructor = calendar#constructor#view_clock#new(s:self)

let &cpo = s:save_cpo
unlet s:save_cpo
