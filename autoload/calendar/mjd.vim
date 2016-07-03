" =============================================================================
" Filename: autoload/calendar/mjd.vim
" Author: itchyny
" License: MIT License
" Last Change: 2016/07/04 02:12:27.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

" Modified Julian Day
" This object is a very basic component for calendar calculation.
" Reference: http://en.wikipedia.org/wiki/Julian_day
function! calendar#mjd#new(mjd) abort
  let m = a:mjd + 3
  let week = m % 7 + 7 * ((m < 0) && (m % 7))
  return extend(copy(s:self), { 'mjd': a:mjd, 'week': week })
endfunction

let s:self = {}

function! s:self.add(diff) dict abort
  return calendar#mjd#new(self.mjd + a:diff)
endfunction

function! s:self.sub(mjd) dict abort
  return self.mjd - a:mjd.mjd
endfunction

function! s:self.eq(mjd) dict abort
  return self.mjd == a:mjd.mjd
endfunction

function! s:self.is_after(mjd) dict abort
  return self.mjd > a:mjd.mjd
endfunction

function! s:self.is_after_or_eq(mjd) dict abort
  return self.mjd >= a:mjd.mjd
endfunction

function! s:self.is_before(mjd) dict abort
  return self.mjd < a:mjd.mjd
endfunction

function! s:self.is_before_or_eq(mjd) dict abort
  return self.mjd <= a:mjd.mjd
endfunction

function! s:self.is_sunday() dict abort
  return self.week == 0
endfunction

function! s:self.is_monday() dict abort
  return self.week == 1
endfunction

function! s:self.is_tuesday() dict abort
  return self.week == 2
endfunction

function! s:self.is_wednesday() dict abort
  return self.week == 3
endfunction

function! s:self.is_thursday() dict abort
  return self.week == 4
endfunction

function! s:self.is_friday() dict abort
  return self.week == 5
endfunction

function! s:self.is_saturday() dict abort
  return self.week == 6
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
