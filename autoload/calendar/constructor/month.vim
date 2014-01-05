" =============================================================================
" Filename: autoload/calendar/constructor/month.vim
" Author: itchyny
" License: MIT License
" Last Change: 2013/12/28 13:06:54.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

function! calendar#constructor#month#new(day_constructor)
  return extend({ 'day_constructor': a:day_constructor, 'cache': {} }, s:constructor)
endfunction

let s:constructor = {}

function! s:constructor.new(y, m) dict
  let instance = copy(s:instance)
  let instance.day_constructor = self.day_constructor
  let instance._ym = [a:y, a:m]
  let instance.constructor = self
  return instance
endfunction

let s:instance = {}

function! s:instance.new(y, m) dict
  return self.constructor.new(a:y, a:m)
endfunction

function! s:div(x, y)
  return a:x/a:y-((a:x<0)&&(a:x%a:y))
endfunction

function! s:instance.add(diff) dict
  let [y, m] = self.get_ym()
  let m += a:diff - 1
  let y += s:div(m, 12)
  let m -= 12 * s:div(m, 12)
  let m += 1
  return self.new(y, m)
endfunction

function! s:instance.sub(month) dict
  let [ya, ma] = self.get_ym()
  let [yb, mb] = a:month.get_ym()
  return (ya - yb) * 12 + (ma - mb)
endfunction

function! s:instance.eq(month) dict
  return self.get_ym() == a:month.get_ym()
endfunction

function! s:instance.eq_month(month) dict
  return self.eq(a:month)
endfunction

function! s:instance.eq_year(month) dict
  return self.year().eq(a:month.year())
endfunction

function! s:instance.is_valid() dict
  return self.head_day().is_valid() && self.last_day().is_valid()
endfunction

function! s:instance.get_ym() dict
  if has_key(self, 'ym') | return self.ym | endif
  let self.ym = self.head_day().get_ymd()[:1]
  return self.ym
endfunction

function! s:instance.get_ym_string() dict
  if has_key(self, 'ym_string') | return self.ym_string | endif
  let ymd = self.head_day().get_ymd()
  let self.ym_string = ymd[0] . '/' . ymd[1]
  return self.ym_string
endfunction

function! s:instance.get_year() dict
  return self.get_ym()[0]
endfunction

function! s:instance.get_month() dict
  return self.get_ym()[1]
endfunction

function! s:instance.get_day() dict
  return self.head_day().get_day()
endfunction

function! s:instance.head_day() dict
  if has_key(self, '_head_day') | return self._head_day | endif
  let y = self._ym[0]
  let m = self._ym[1]
  let self._head_day = self.day_constructor.new(self._ym[0], self._ym[1], 1)
  if !self._head_day.is_valid()
    let yy = self._ym[0]
    let mm = self._ym[1] - 1
    if mm < 1
      let [yy, mm] = [yy - 1, mm + 12]
    endif
    let self._head_day = self.day_constructor.new(yy, mm, 1)
    while self._head_day.get_year() < y || self._head_day.get_month() < m
      let self._head_day = self._head_day.add(1)
    endwhile
  endif
  return self._head_day
endfunction

function! s:instance.last_day() dict
  if has_key(self, '_last_day') | return self._last_day | endif
  let [y, m] = [self._ym[0], self._ym[1]]
  let m += 1
  if m > 12 | let [y, m] = [y + 1, m - 12] | endif
  let self._last_day = self.new(y, m).head_day().add(-1)
  return self._last_day
endfunction

function! s:instance.days() dict
  if has_key(self, '_days') | return self._days | endif
  let self._days = self.last_day().sub(self.head_day()) + 1
  return self._days
endfunction

function! s:instance.get_days() dict
  if has_key(self, '__days') | return self.__days | endif
  if has_key(self.constructor.cache, self.get_ym_string())
    return self.constructor.cache[self.get_ym_string()]
  endif
  let days = []
  call add(days, self.head_day())
  while !self.last_day().eq(days[-1])
    call add(days, days[-1].add(1))
  endwhile
  let self.__days = days
  let self.constructor.cache[self.get_ym_string()] = days
  return days
endfunction

function! s:instance.day() dict
  return self.head_day()
endfunction

function! s:instance.month() dict
  if has_key(self, '_month') | return self._month | endif
  let [y, m] = self.get_ym()
  let self._month = self.new(y, m)
  return self._month
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
