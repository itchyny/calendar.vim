" =============================================================================
" Filename: autoload/calendar/time.vim
" Author: itchyny
" License: MIT License
" Last Change: 2014/01/09 00:39:55.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

" Time object
"   h: hour
"   m: minute 
"   s: second 
function! calendar#time#new(h, m, s)
  return extend(copy(s:self), { 'h': a:h, 'm': a:m, 's': a:s })
endfunction

function! calendar#time#now()
  if exists("*strftime")
    return calendar#time#new(strftime('%H') * 1, strftime('%M') * 1, strftime('%S') * 1)
  else
    return calendar#time#new(system('date "+%H"') * 1, system('date "+%M"') * 1, system('date "+%S"') * 1)
  endif
endfunction

function! calendar#time#hour12(h)
  return a:h == 0 ? 12 : a:h < 13 ? a:h : a:h - 12
endfunction

let s:self = {}

function! s:div(x, y)
  return a:x/a:y-((a:x<0)&&(a:x%a:y))
endfunction

function! s:self.new(h, m, s) dict
  return calendar#time#new(a:h, a:m, a:s)
endfunction

function! s:self.get_hms() dict
  return [self.h, self.m, self.s]
endfunction

function! s:self.add_hour(diff) dict
  let [h, m, s] = self.get_hms()
  let d = 0
  let h += a:diff
  let d += s:div(h, 24)
  let h -= 24 * s:div(h, 24)
  return [d, self.new(h, m, s)]
endfunction

function! s:self.add_minute(diff) dict
  let [h, m, s] = self.get_hms()
  let d = 0
  let m += a:diff
  let h += s:div(m, 60)
  let m -= 60 * s:div(m, 60)
  let d += s:div(h, 24)
  let h -= 24 * s:div(h, 24)
  return [d, self.new(h, m, s)]
endfunction

function! s:self.add_second(diff) dict
  let [h, m, s] = self.get_hms()
  let d = 0
  let s += a:diff
  let m += s:div(s, 60)
  let s -= 60 * s:div(s, 60)
  let h += s:div(m, 60)
  let m -= 60 * s:div(m, 60)
  let d += s:div(h, 24)
  let h -= 24 * s:div(h, 24)
  return [d, self.new(h, m, s)]
endfunction

function! s:self.second() dict
  return self.get_hms()[2]
endfunction

function! s:self.minute() dict
  return self.get_hms()[1]
endfunction

function! s:self.hour() dict
  return self.get_hms()[0]
endfunction

function! s:self.seconds() dict
  return (self.hour() * 60 + self.minute()) * 60 + self.second()
endfunction

function! s:self.sub(time) dict
  return self.seconds() - a:time.seconds()
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
