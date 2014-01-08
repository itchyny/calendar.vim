" =============================================================================
" Filename: autoload/calendar/setting.vim
" Author: itchyny
" License: MIT License
" Last Change: 2014/01/09 00:24:26.
" =============================================================================

scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim

" Obtaining settings.
"    1: b:_calendar[option] is set by :Calendar -option=value
"    2: g:calendar_option is set in vimrc. let g:calendar_option = value
"    3: s:option() is the default value.
" Firstly, check the buffer variable if exists. It is set from argument. See
" calendar#new(args) for more detail. If the buffer was not found as a buffer
" variable, check the global variable. A user can set the variable in the vimrc
" file. Lastly, returns the default setting. All the default settings are
" defined in this file. Conversely, all the variables defined in this file can
" be configured by users from their vimrc file.
function! calendar#setting#get(name)
  return get(get(b:, '_calendar', {}), a:name, get(g:, 'calendar_' . a:name, s:{a:name}()))
endfunction

function! calendar#setting#get_default(name)
  return s:{a:name}()
endfunction

function! s:locale()
  return substitute(v:lang, '[.-]', '_', 'g')
endfunction

function! s:calendar()
  return 'default'
endfunction

function! s:first_day()
  return v:lang =~# '\%(US\|CA\|JP\|IL\)\|^\%(ja\)' ? 'sunday' : 'monday'
endfunction

function! s:date_endian()
  return v:lang =~# '\%(JP\|KR\|HU\|LT\|IR\|MN\)\|^\%(ja\|zh\)' ? 'big'
     \ : v:lang =~# 'US' ? 'middle'
     \ : 'little'
endfunction

function! s:date_separator()
  return v:lang =~# '\%(AM\|AT\|AZ\|BY\|BG\|HR\|CZ\|EE\|FI\|GE\|DE\|HU\|IS\|KZ\|KG\|LV\|MN\|NO\|RO\|RU\|SK\|CH\|TM\|UA\)' ? '.'
     \ : v:lang =~# '\%(BD\|CN\|DK\|FR\|IN\|IE\|LT\|NL\|SE\|TW\)' ? '-'
     \ : '/'
endfunction

function! s:date_month_name()
  return 0
endfunction

function! s:clock_12hour()
  return 0
endfunction

function! s:cache_directory()
  if has_key(s:, 'c')
    return s:c
  endif
  let s:c = expand('~/.cache/calendar.vim/')
  return s:c
endfunction

function! s:google_calendar()
  return 0
endfunction

function! s:google_task()
  return 0
endfunction

function! s:updatetime()
  return 200
endfunction

function! s:view()
  return 'month'
endfunction

function! s:views()
  return ['year', 'month', 'week', 'day_4', 'day', 'clock']
endfunction

function! s:view_source()
  return [
        \ { 'type': 'ymd'
        \ , 'top': '1'
        \ , 'align': 'center'
        \ , 'maxwidth': 'b:calendar.view.task_visible() ? calendar#util#winwidth() * 5 / 6 : calendar#util#winwidth() - 1'
        \ , 'visible': 'b:calendar.view.get_calendar_views() !=# "clock"'
        \ } ,
        \ { 'type': 'event'
        \ , 'left': '(calendar#util#winwidth() - self.width()) / 2'
        \ , 'top': '(calendar#util#winheight() - self.height()) / 2'
        \ , 'on_top': '1'
        \ , 'position': 'absolute'
        \ , 'maxwidth': 'max([calendar#util#winwidth() / 3, 15])'
        \ , 'maxheight': 'max([calendar#util#winheight() / 2, 3])'
        \ , 'visible': 'b:calendar.view._event && b:calendar.view.get_calendar_views() !=# "clock"'
        \ },
        \ { 'type': 'task'
        \ , 'align': 'right'
        \ , 'left': 'calendar#util#winwidth() * 5 / 6'
        \ , 'top': '(calendar#util#winheight() - self.height()) / 2'
        \ , 'position': 'absolute'
        \ , 'maxwidth': 'calendar#util#winwidth() / 6'
        \ , 'maxheight': 'max([calendar#util#winheight() * 5 / 6, 3])'
        \ , 'visible': 'b:calendar.view._task'
        \ },
        \ { 'type': 'help'
        \ , 'align': 'center'
        \ , 'position': 'absolute'
        \ , 'on_top': '1'
        \ , 'left': '(calendar#util#winwidth() - self.width()) / 2'
        \ , 'top': '(calendar#util#winheight() - self.height()) / 2'
        \ , 'maxwidth': 'max([min([calendar#util#winwidth() / 2, min([77, calendar#util#winwidth()])]), min([30, calendar#util#winwidth()])])'
        \ , 'maxheight': 'max([calendar#util#winheight() * 3 / 5, 3])'
        \ , 'visible': 'b:calendar.view._help'
        \ },
        \ { 'type': 'calendar'
        \ , 'top': 'b:calendar.view.get_calendar_views() ==# "clock" ? 0 : 3'
        \ , 'align': 'center'
        \ , 'maxwidth': 'b:calendar.view.task_visible() ? calendar#util#winwidth() * 5 / 6  : calendar#util#winwidth() - 1'
        \ , 'maxheight': 'calendar#util#winheight() - (b:calendar.view.get_calendar_views() ==# "clock" ? 0 : 3)'
        \ },
        \ ]
endfunction

function! calendar#setting#frame()
  return calendar#setting#get('frame_' . calendar#setting#get('frame'))
endfunction

function! s:frame()
  return &enc ==# 'utf-8' && &fenc ==# 'utf-8' ? 'unicode' : 'default'
endfunction

function! s:frame_default()
  return { 'type': 'default', 'vertical': '|', 'horizontal': '-', 'junction': '+',
         \ 'left': '+', 'right': '+', 'top': '+', 'bottom': '+',
         \ 'topleft': '+', 'topright': '+', 'bottomleft': '+', 'bottomright': '+' }
endfunction

function! s:frame_unicode()
  if &enc ==# 'utf-8' && &fenc ==# 'utf-8'
    return { 'type': 'unicode', 'vertical': "\u2502", 'horizontal': "\u2500", 'junction': "\u253C",
           \ 'left': "\u251C", 'right': "\u2524", 'top': "\u252C", 'bottom': "\u2534",
           \ 'topleft': "\u250C", 'topright': "\u2510", 'bottomleft': "\u2514", 'bottomright': "\u2518" }
  else
    return s:frame_default()
  endif
endfunction

function! s:frame_unicode_bold()
  if &enc ==# 'utf-8' && &fenc ==# 'utf-8'
    return { 'type': 'unicode_bold', 'vertical': "\u2503", 'horizontal': "\u2501", 'junction': "\u254B",
           \ 'left': "\u2523", 'right': "\u252B", 'top': "\u2533", 'bottom': "\u253B",
           \ 'topleft': "\u250F", 'topright': "\u2513", 'bottomleft': "\u2517", 'bottomright': "\u251B" }
  else
    return s:frame_default()
  endif
endfunction

function! s:frame_unicode_round()
  if &enc ==# 'utf-8' && &fenc ==# 'utf-8'
    return extend(s:frame_unicode_bold(), {
          \ 'type': 'unicode_round', 'topleft': "\u256D", 'topright': "\u256E",
          \ 'bottomleft': "\u2570", 'bottomright': "\u256F" })
  else
    return s:frame_default()
  endif
endfunction

function! s:frame_unicode_double()
  if &enc ==# 'utf-8' && &fenc ==# 'utf-8'
    return { 'type': 'unicode_double', 'vertical': "\u2551", 'horizontal': "\u2550", 'junction': "\u256C",
           \ 'left': "\u2560", 'right': "\u2563", 'top': "\u2566", 'bottom': "\u2569",
           \ 'topleft': "\u2554", 'topright': "\u2557", 'bottomleft': "\u255A", 'bottomright': "\u255D" }
  else
    return s:frame_default()
  endif
endfunction

function! s:frame_space()
  return { 'type': 'space', 'vertical': ' ', 'horizontal': ' ', 'junction': ' ',
         \ 'left': ' ', 'right': ' ', 'top': ' ', 'bottom': ' ',
         \ 'topleft': ' ', 'topright': ' ', 'bottomleft': ' ', 'bottomright': ' ' }
endfunction

function! s:google_client()
  if has_key(s:, 'g')
    return s:g
  endif
  let s:g = calendar#cipher#decipher({
        \ 'redirect_uri': 'zws?njyk?|l?tfzym?735?ttg',
        \ 'client_id': '::88>5<99<8:3fuux3lttlqjzxjwhtsyjsy3htr',
        \ 'scope': 'myyux?44|||3lttlqjfunx3htr4fzym4hfqjsifw%myyux?44|||3lttlqjfunx3htr4fzym4yfxpx',
        \ 'api_key': 'FN fX~GKkSs}QJgNYquJ=^sJJU:u<[9_dmT:MF=',
        \ 'client_secret': 'FZShKZt{{9|G2U ku[WYLOut'}, 100)
  return s:g
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
