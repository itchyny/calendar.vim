" =============================================================================
" Filename: autoload/calendar/week.vim
" Author: itchyny
" License: MIT License
" Last Change: 2013/11/10 23:01:48.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

" Week object
"   week: week string (one of s:weeks)
"   default: week string (one of s:weeks), the default value which is used when
"            the first argument is not found in s:weeks.
function! calendar#week#new(week, default)
  let self = extend(copy(s:self), { '_week': a:week, '_default': a:default })
  let self.week = self.get()
  let self.index = index(s:weeks, self.week)
  return self
endfunction

function! calendar#week#first_day_index()
  let w = calendar#setting#get('first_day')
  return calendar#week#new(w, 'sunday').index
endfunction

function! calendar#week#last_day_index()
  let w = calendar#setting#get('first_day')
  return calendar#week#new(w, 'sunday').add(6).index
endfunction

function! calendar#week#is_first_day(day)
  return a:day.week() == calendar#week#first_day_index()
endfunction

function! calendar#week#is_last_day(day)
  return a:day.week() == calendar#week#last_day_index()
endfunction

function! calendar#week#week_number(day)
  return (a:day.week() + 7 - calendar#week#first_day_index()) % 7
endfunction

function! calendar#week#week_count(month)
  return (len(a:month.get_days()) + calendar#week#week_number(a:month.head_day()) + 6) / 7
endfunction

let s:self = {}

let s:weeks = [ 'sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday' ]

function! s:self.new(week, default) dict
  return calendar#week#new(a:week, a:default)
endfunction

function! s:self.new_index(index) dict
  let index = a:index % 7 + 7 * ((a:index < 0) && (a:index % 7))
  return calendar#week#new(s:weeks[index], s:weeks[index])
endfunction

function! s:self.get() dict
  if has_key(self, 'week') | return self.week | endif
  let flg = 0
  for index in range(len(s:weeks))
    if self._week =~? s:weeks[index]
      let flg = 1
      break
    endif
  endfor
  let self.week = flg ? s:weeks[index] : self._default
  return self.week
endfunction

function! s:self.add(diff) dict
  return self.new_index(self.index + a:diff)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
