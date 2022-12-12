" =============================================================================
" Filename: autoload/calendar/day.vim
" Author: itchyny
" License: MIT License
" Last Change: 2022/12/12 20:17:43.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

" Day object switching the calendar based on the user's setting.
function! calendar#day#new(y, m, d) abort
  return calendar#day#{calendar#setting#get('calendar')}#new(a:y, a:m, a:d)
endfunction

" Day object from mjd.
function! calendar#day#new_mjd(mjd) abort
  return calendar#day#{calendar#setting#get('calendar')}#new_mjd(a:mjd)
endfunction

" Today.
function! calendar#day#today() abort
  return calendar#day#new_mjd(calendar#day#today_mjd())
endfunction

" Today's mjd.
function! calendar#day#today_mjd() abort
  let [y, m, d] = [strftime('%Y') + 0, strftime('%m') + 0, strftime('%d') + 0]
  if get(s:, '_ymd', []) == [y, m, d]
    return s:_mjd
  endif
  let s:_ymd = [y, m, d]
  let s:_mjd = calendar#day#gregorian#new(y, m, d).mjd
  return s:_mjd
endfunction

" Join the year, month and day using the endian, separator settings.
function! calendar#day#join_date(ymd) abort
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

function! calendar#day#join_date_range(x, y) abort
  let [x, y] = a:x.sub(a:y) < 0 ? [a:x, a:y] : [a:y, a:x]
  if x.get_ymd() == y.get_ymd()
    return calendar#day#join_date([x.get_month(), x.get_day()])
  elseif x.get_year() == y.get_year()
    return printf('%s - %s',
          \ calendar#day#join_date([x.get_month(), x.get_day()]),
          \ calendar#day#join_date([y.get_month(), y.get_day()]))
  else
    return printf('%s - %s',
          \ calendar#day#join_date([x.get_year(), x.get_month(), x.get_day()]),
          \ calendar#day#join_date([y.get_year(), y.get_month(), y.get_day()]))
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
