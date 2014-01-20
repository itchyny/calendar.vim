" =============================================================================
" Filename: autoload/calendar/day.vim
" Author: itchyny
" License: MIT License
" Last Change: 2014/01/20 21:23:47.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

" Day object switching the calendar based on the user's setting.
function! calendar#day#new(y, m, d)
  return calendar#day#{calendar#setting#get('calendar')}#new(a:y, a:m, a:d)
endfunction

" Day object from mjd.
function! calendar#day#new_mjd(mjd)
  return calendar#day#{calendar#setting#get('calendar')}#new_mjd(a:mjd)
endfunction

" Today.
function! calendar#day#today()
  return calendar#day#new_mjd(calendar#day#today_mjd())
endfunction

" Today's mjd.
function! calendar#day#today_mjd()
  let [y, m, d] = s:ymd()
  if has_key(s:, '_y') && s:_y == [y, m, d]
    return s:_m
  endif
  let s:_y = [y, m, d]
  let s:_m = calendar#day#gregorian#new(y, m, d).mjd
  return s:_m
endfunction

" Today's [ year, month, day ].
if exists('*strftime')
  function! s:ymd()
    return [strftime('%Y') * 1, strftime('%m') * 1, strftime('%d') * 1]
  endfunction
else
  function! s:ymd()
    return [system('date "+%Y"') * 1, system('date "+%m"') * 1, system('date "+%d"') * 1]
  endfunction
endif

" Join the year, month and day using the endian, separator settings.
function! calendar#day#join_date(ymd)
  let endian = calendar#setting#get('date_endian')
  let use_month_name = calendar#setting#get('date_month_name')
  let sep1 = calendar#setting#get('date_separator')
  let sep2 = use_month_name ? '' : sep1
  let ymd = a:ymd
  if len(a:ymd) == 3
    let [y, m, d] = a:ymd
    let mm = use_month_name ? calendar#message#get('month_name')[m - 1] : m
    if endian ==# 'big'
      let ymd = [y, sep1, mm, sep2, d]
    elseif endian ==# 'middle'
      let ymd = [mm, sep2, d, sep1, y]
    else
      let ymd = [d, sep2, mm, sep1, y]
    endif
  elseif len(a:ymd) == 2
    let [m, d] = a:ymd
    let mm = use_month_name ? calendar#message#get('month_name')[m - 1] : m
    if endian ==# 'big' || endian ==# 'middle'
      let ymd = [mm, sep2, d]
    else
      let ymd = [d, sep2, mm]
    endif
  endif
  return join(ymd, '')
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
