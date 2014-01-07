" =============================================================================
" Filename: autoload/calendar/message/default.vim
" Author: itchyny
" License: MIT License
" Last Change: 2014/01/07 13:41:38.
" =============================================================================

scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

function! calendar#message#default#get()
  return extend(s:english_message, s:message())
endfunction

let s:english_message = deepcopy(calendar#message#en#get())

function! s:message()
  let message = {}
  if exists('*strftime')
    let message.day_name        = s:get_day_name(0)
    let message.day_name_long   = s:get_day_name(1)
    let message.month_name      = map(range(12), "strftime('%b', 60 * 60 * 24 * (32 * v:val + 5))")
    let message.month_name_long = map(range(12), "strftime('%B', 60 * 60 * 24 * (32 * v:val + 5))")
  endif
  return message
endfunction

function! s:get_day_name(long)
  let names = []
  let time = 60 * 60 * (24 * 3 + 10)
  let format = a:long ? '%A' : '%a'
  while len(names) < 7
    let newname = strftime(format, time)
    if !len(names) || names[-1] !=# newname
      call add(names, newname)
    endif
    let time += 60 * 60 * 23
  endwhile
  return names
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
