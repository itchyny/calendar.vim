" =============================================================================
" Filename: autoload/calendar/message/default.vim
" Author: itchyny
" License: MIT License
" Last Change: 2013/11/30 00:38:14.
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
    let message.day_name        = map(range(3, 9), "strftime('%a', 60 * 60 * 25 * v:val)")
    let message.day_name_long   = map(range(3, 9), "strftime('%A', 60 * 60 * 25 * v:val)")
    let message.month_name      = map(range(12)  , "strftime('%b', 60 * 60 * 24 * 32 * v:val)")
    let message.month_name_long = map(range(12)  , "strftime('%B', 60 * 60 * 24 * 32 * v:val)")
  endif
  return message
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
