" =============================================================================
" Filename: autoload/calendar/echo.vim
" Author: itchyny
" License: MIT License
" Last Change: 2014/05/11 14:11:45.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

" Echo messages.

function! calendar#echo#echo(msg)
  echo a:msg
endfunction

function! calendar#echo#message(msg)
  call calendar#echo#message_raw(calendar#setting#get('message_prefix') . a:msg)
endfunction

function! calendar#echo#message_raw(msg)
  redraw
  echo ''
  for msg in split(a:msg, '\n')
    echo msg
  endfor
endfunction

function! calendar#echo#error(msg)
  call calendar#echo#error_raw(calendar#setting#get('message_prefix') . a:msg)
endfunction

function! calendar#echo#error_raw(msg)
  redraw
  echo ''
  echohl ErrorMsg
  for msg in split(a:msg, '\n')
    echo msg
  endfor
  echohl None
endfunction

function! calendar#echo#normal_message(name)
  call calendar#echo#message(calendar#message#get(a:name))
endfunction

function! calendar#echo#error_message(name)
  call calendar#echo#error(calendar#message#get(a:name))
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
