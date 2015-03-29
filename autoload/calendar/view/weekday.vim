" =============================================================================
" Filename: autoload/calendar/view/weekday.vim
" Author: itchyny
" License: MIT License
" Last Change: 2015/03/29 06:33:47.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

function! calendar#view#weekday#new(source) abort
  return s:constructor.new(a:source)
endfunction

let s:self = {}
let s:self.daynum = 5

function! s:self.height() dict abort
  let day = b:calendar.day()
  if day.week() == 0
    if index(['left', 'prev', 'subtract'], b:calendar.action_name) >= 0
      call b:calendar.move_day(-2)
    else
      call b:calendar.move_day(1)
    endif
  elseif day.week() == 6
    if index(['left', 'prev', 'subtract'], b:calendar.action_name) >= 0
      call b:calendar.move_day(-1)
    else
      call b:calendar.move_day(2)
    endif
  endif
  return max([self.maxheight(), 6])
endfunction

function! s:self.get_min_day() dict abort
  let day = b:calendar.day()
  return day.add(-day.week()+1)
endfunction

let s:constructor = calendar#constructor#view_days#new(s:self)

let &cpo = s:save_cpo
unlet s:save_cpo
