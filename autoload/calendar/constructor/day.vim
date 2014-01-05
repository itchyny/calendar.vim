" =============================================================================
" Filename: autoload/calendar/constructor/day.vim
" Author: itchyny
" License: MIT License
" Last Change: 2013/11/10 11:34:43.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

function! calendar#constructor#day#new(instance)
  let constructor = extend({ 'instance': a:instance }, s:constructor)
  let constructor.month_constructor = calendar#constructor#month#new(constructor)
  let constructor.year_constructor = calendar#constructor#year#new(constructor)
  return constructor
endfunction

let s:constructor = {}

function! s:constructor.new(y, m, d) dict
  return extend(self.instance.new(a:y, a:m, a:d), { 'constructor': self })
endfunction

function! s:constructor.new_mjd(mjd) dict
  return extend(extend(copy(s:instance), self.instance), { 'mjd': a:mjd, 'constructor': self })
endfunction

let s:instance = {}

function! s:div(x, y)
  return a:x/a:y-((a:x<0)&&(a:x%a:y))
endfunction

function! s:instance.add(diff) dict
  return self.new_mjd(self.mjd.add(a:diff))
endfunction

function! s:instance.add_month(diff) dict
  let [y, m, d] = self.get_ymd()
  let m += a:diff - 1
  let y += s:div(m, 12)
  let m -= 12 * s:div(m, 12)
  let m += 1
  let new_day = self.new(y, m, d)
  let new_month = self.constructor.month_constructor.new(y, m)
  if !new_day.is_valid()
    if new_day.sub(new_month.head_day()) > 0
      while !(new_day.eq_month(new_month.head_day()))
        let new_day = new_day.add(-1)
      endwhile
    else
      while !(new_day.eq_month(new_month.head_day()))
        let new_day = new_day.add(1)
      endwhile
    endif
  endif
  return new_day
endfunction

function! s:instance.add_year(diff) dict
  return self.add_month(a:diff * 12)
endfunction

function! s:instance.sub(day) dict
  return self.mjd.sub(a:day.mjd)
endfunction

function! s:instance.week() dict
  return self.mjd.week()
endfunction

function! s:instance.today() dict
  return self.new_mjd(calendar#day#today_mjd())
endfunction

function! s:instance.eq(day) dict
  return self.mjd.eq(a:day.mjd)
endfunction

function! s:instance.eq_month(day) dict
  return self.month().eq(a:day.month())
endfunction

function! s:instance.eq_year(day) dict
  return self.year().eq(a:day.year())
endfunction

function! s:instance.eq_week(day) dict
  return self.week() == a:day.week()
endfunction

function! s:instance.is_sunday() dict
  return self.mjd.is_sunday()
endfunction

function! s:instance.is_monday() dict
  return self.mjd.is_monday()
endfunction

function! s:instance.is_tuesday() dict
  return self.mjd.is_tuesday()
endfunction

function! s:instance.is_wednesday() dict
  return self.mjd.is_wednesday()
endfunction

function! s:instance.is_thursday() dict
  return self.mjd.is_thursday()
endfunction

function! s:instance.is_friday() dict
  return self.mjd.is_friday()
endfunction

function! s:instance.is_saturday() dict
  return self.mjd.is_saturday()
endfunction

function! s:instance.is_valid() dict
  return !has_key(self, '_ymd') || self._ymd == self.get_ymd()
endfunction

function! s:instance.get_year() dict
  return self.get_ymd()[0]
endfunction

function! s:instance.get_month() dict
  return self.get_ymd()[1]
endfunction

function! s:instance.get_day() dict
  return self.get_ymd()[2]
endfunction

function! s:instance.month() dict
  if has_key(self, '_month') | return self._month | endif
  let [y, m, d] = self.get_ymd()
  let self._month = self.constructor.month_constructor.new(y, m)
  return self._month
endfunction

function! s:instance.year() dict
  if has_key(self, '_year') | return self._year | endif
  let self._year = self.constructor.year_constructor.new(self.get_year())
  return self._year
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
