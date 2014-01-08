" =============================================================================
" Filename: autoload/calendar/view/clock_date_time.vim
" Author: itchyny
" License: MIT License
" Last Change: 2014/01/09 00:41:40.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

function! calendar#view#clock_date_time#new(source)
  return s:constructor.new(a:source)
endfunction

let s:self = {}
let s:self.y_height = 1
let s:self.smaller = 1

function! s:self.max_letter() dict
  return [printf('%s (Mon) 12:33:33', calendar#day#join_date([12, 30]))]
endfunction

function! s:self.get_letter() dict
  let [h, i, s] = calendar#time#now().get_hms()
  let [y, m, d] = calendar#day#today().get_ymd()
  let w = calendar#message#en#get().day_name[calendar#day#today().week()]
  if calendar#setting#get('clock_12hour')
    let h = calendar#time#hour12(h)
  endif
  return [printf('%s (%s) %d:%02d:%02d', calendar#day#join_date([m, d]), w, h, i, s)]
endfunction

let s:constructor = calendar#constructor#view_clock#new(s:self)

let &cpo = s:save_cpo
unlet s:save_cpo
