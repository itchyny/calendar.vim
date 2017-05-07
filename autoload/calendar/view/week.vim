" =============================================================================
" Filename: autoload/calendar/view/week.vim
" Author: itchyny
" License: MIT License
" Last Change: 2017/05/07 23:06:40.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

function! calendar#view#week#new(source) abort
  return s:constructor.new(a:source)
endfunction

let s:self = {}
let s:self.daynum = 7
let s:self.stopend = 1

function! s:self.get_min_day() dict abort
  let day = b:calendar.day()
  return day.add(-calendar#week#week_index(day))
endfunction

let s:constructor = calendar#constructor#view_days#new(s:self)

let &cpo = s:save_cpo
unlet s:save_cpo
