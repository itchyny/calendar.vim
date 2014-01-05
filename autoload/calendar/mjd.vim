" =============================================================================
" Filename: autoload/calendar/mjd.vim
" Author: itchyny
" License: MIT License
" Last Change: 2013/10/23 16:37:59.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

" Modified Julian Day
" This object is a very basic component for calendar calculation.
" Reference: http://en.wikipedia.org/wiki/Julian_day
function! calendar#mjd#new(mjd)
  return extend(copy(s:self), { 'mjd': a:mjd })
endfunction

let s:self = {}

function! s:self.new(mjd) dict
  return calendar#mjd#new(a:mjd)
endfunction

function! s:self.get() dict
  return self.mjd
endfunction

function! s:self.add(diff) dict
  return self.new(self.mjd + a:diff)
endfunction

function! s:self.sub(mjd) dict
  return self.get() - a:mjd.get()
endfunction

function! s:self.eq(mjd) dict
  return self.get() == a:mjd.get()
endfunction

function! s:self.week() dict
  let m = self.mjd + 3
  return m % 7 + 7 * ((m < 0) && (m % 7))
endfunction

function! s:self.is_sunday() dict
  return self.week() == 0
endfunction

function! s:self.is_monday() dict
  return self.week() == 1
endfunction

function! s:self.is_tuesday() dict
  return self.week() == 2
endfunction

function! s:self.is_wednesday() dict
  return self.week() == 3
endfunction

function! s:self.is_thursday() dict
  return self.week() == 4
endfunction

function! s:self.is_friday() dict
  return self.week() == 5
endfunction

function! s:self.is_saturday() dict
  return self.week() == 6
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
