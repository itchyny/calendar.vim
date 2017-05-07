" =============================================================================
" Filename: autoload/calendar/week.vim
" Author: itchyny
" License: MIT License
" Last Change: 2017/05/07 22:52:34.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

let s:cache = {}
function! calendar#week#first_day_index() abort
  let first_day = calendar#setting#get('first_day')
  if has_key(s:cache, first_day)
    return s:cache[first_day]
  endif
  let s:cache[first_day] = s:get_index(first_day, 0)
  return s:cache[first_day]
endfunction

function! calendar#week#last_day_index() abort
  return (calendar#week#first_day_index() + 6) % 7
endfunction

function! calendar#week#is_first_day(day) abort
  return a:day.week() == calendar#week#first_day_index()
endfunction

function! calendar#week#is_last_day(day) abort
  return a:day.week() == calendar#week#last_day_index()
endfunction

function! calendar#week#week_number(day) abort
  return (a:day.week() + 7 - calendar#week#first_day_index()) % 7
endfunction

function! calendar#week#week_count(month) abort
  return (a:month.last_day().sub(a:month.head_day()) + 1 + calendar#week#week_number(a:month.head_day()) + 6) / 7
endfunction

function! calendar#week#week_number_year(day) abort
  if calendar#setting#get('first_day') =~? 'monday'
    let d = a:day.year().head_day().add(3)
    let diff = a:day.sub(d) + calendar#week#week_number(d)
    if diff >= 0
      return (diff + 7) / 7
    else
      let day = d.add(-4)
      let d = day.year().head_day().add(3)
      return (day.sub(d) + calendar#week#week_number(d) + 7) / 7
    endif
  else
    let d = a:day.year().head_day()
    return (a:day.sub(d) + calendar#week#week_number(d) + 7) / 7
  endif
endfunction

let s:weeks = [ 'sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday' ]

function! s:get_index(week, default) abort
  let found = 0
  for index in range(len(s:weeks))
    if a:week =~? s:weeks[index]
      let found = 1
      break
    endif
  endfor
  return found ? index : a:default
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
