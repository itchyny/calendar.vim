" =============================================================================
" Filename: autoload/calendar/model.vim
" Author: itchyny
" License: MIT License
" Last Change: 2014/01/13 00:14:19.
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

function! s:self._start_visual(mode) dict
  if self.visual_mode() == 0
    let self._visual_start_day = deepcopy(self._day)
    let self._visual_start_time = deepcopy(self._time)
  endif
  let self._visual = get(self, '_visual') == a:mode ? 0 : a:mode
endfunction

function! s:self.start_visual() dict
  call self._start_visual(1)
endfunction

function! s:self.start_line_visual() dict
  call self._start_visual(2)
endfunction

function! s:self.start_block_visual() dict
  call self._start_visual(3)
endfunction

function! s:self.exit_visual() dict
  let self._visual = 0
  return self
endfunction

function! s:self.visual_mode() dict
  return get(self, '_visual')
endfunction

function! s:self.is_visual() dict
  return get(self, '_visual') == 1
endfunction

function! s:self.is_line_visual() dict
  return get(self, '_visual') == 2
endfunction

function! s:self.is_block_visual() dict
  return get(self, '_visual') == 3
endfunction

function! s:self.visual_start_day() dict
  return get(self, '_visual_start_day', self._day)
endfunction

function! s:self.visual_start_time() dict
  return get(self, '_visual_start_time', self._time)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
