" =============================================================================
" Filename: autoload/calendar/view/week.vim
" Author: itchyny
" License: MIT License
" Last Change: 2013/12/31 15:10:26.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

function! calendar#view#week#new(source)
  return s:constructor.new(a:source)
endfunction

let s:self = {}
let s:self.daynum = 7
let s:self.stopend = 1

function! s:self.get_min_day() dict
  let day = b:calendar.day()
  return day.add(-calendar#week#week_number(day))
endfunction

let s:constructor = calendar#constructor#view_days#new(s:self)

let &cpo = s:save_cpo
unlet s:save_cpo
