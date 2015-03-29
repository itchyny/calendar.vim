" =============================================================================
" Filename: autoload/calendar/mjd.vim
" Author: itchyny
" License: MIT License
" Last Change: 2015/03/29 06:30:49.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

" Modified Julian Day
" This object is a very basic component for calendar calculation.
" Reference: http://en.wikipedia.org/wiki/Julian_day
function! calendar#mjd#new(mjd) abort
  return extend(copy(s:self), { 'mjd': a:mjd })
endfunction

let s:self = {}

function! s:self.new(mjd) dict abort
  return calendar#mjd#new(a:mjd)
endfunction

function! s:self.get() dict abort
  return self.mjd
endfunction

function! s:self.add(diff) dict abort
  return self.new(self.mjd + a:diff)
endfunction

function! s:self.sub(mjd) dict abort
  return self.get() - a:mjd.get()
endfunction

function! s:self.eq(mjd) dict abort
  return self.get() == a:mjd.get()
endfunction

function! s:self.week() dict abort
  let m = self.mjd + 3
  return m % 7 + 7 * ((m < 0) && (m % 7))
endfunction

function! s:self.is_sunday() dict abort
  return self.week() == 0
endfunction

function! s:self.is_monday() dict abort
  return self.week() == 1
endfunction

function! s:self.is_tuesday() dict abort
  return self.week() == 2
endfunction

function! s:self.is_wednesday() dict abort
  return self.week() == 3
endfunction

function! s:self.is_thursday() dict abort
  return self.week() == 4
endfunction

function! s:self.is_friday() dict abort
  return self.week() == 5
endfunction

function! s:self.is_saturday() dict abort
  return self.week() == 6
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
