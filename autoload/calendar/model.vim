" =============================================================================
" Filename: autoload/calendar/model.vim
" Author: itchyny
" License: MIT License
" Last Change: 2013/11/22 21:49:10.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

" Model object
" This object keeps time, day and month.
function! calendar#model#new()
  return copy(s:self)
endfunction

let s:self = {}

function! s:self.time() dict
  return self._time
endfunction

function! s:self.set_time(time) dict
  let self._time = a:time
  return self
endfunction

function! s:self.second() dict
  return self._time.second()
endfunction

function! s:self.minute() dict
  return self._time.minute()
endfunction

function! s:self.hour() dict
  return self._time.hour()
endfunction

function! s:self.move_second(diff) dict
  let [d, new_time] = self.time().add_second(a:diff)
  call self.set_time(new_time)
  call self.move_day(d)
endfunction

function! s:self.move_minute(diff) dict
  let [d, new_time] = self.time().add_minute(a:diff)
  call self.set_time(new_time)
  call self.move_day(d)
endfunction

function! s:self.move_hour(diff) dict
  let [d, new_time] = self.time().add_hour(a:diff)
  call self.set_time(new_time)
  call self.move_day(d)
endfunction

function! s:self.day() dict
  return self._day
endfunction

function! s:self.set_day(day) dict
  let self._day = a:day
  return self
endfunction

function! s:self.month() dict
  return self._month
endfunction

function! s:self.set_month(month) dict
  let self._month = a:month
  return self
endfunction

function! s:self.set_month_from_day() dict
  return self.set_month(self.day().month())
endfunction

function! s:self.year() dict
  return self._day.year()
endfunction

function! s:self.get_days() dict
  return self.month().get_days()
endfunction

function! s:self.move_day(diff) dict
  let new_day = self.day().add(a:diff)
  call self.set_day(new_day)
  if !self.month().eq(new_day.month())
    call self.set_month_from_day()
  endif
endfunction

function! s:self.move_month(diff) dict
  call self.set_day(self.day().add_month(a:diff))
  call self.set_month_from_day()
endfunction

function! s:self.move_year(diff) dict
  call self.set_day(self.day().add_year(a:diff))
  call self.set_month_from_day()
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
