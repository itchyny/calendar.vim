" =============================================================================
" Filename: autoload/calendar/view/event.vim
" Author: itchyny
" License: MIT License
" Last Change: 2014/10/18 19:45:59.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

function! calendar#view#event#new(source)
  return s:constructor.new(a:source)
endfunction

let s:self = {}

let s:self._select_line = 1

function! s:self.get_key() dict
  return b:calendar.day().get_ymd() + [get(g:, 'calendar_google_event_download')] + b:calendar.event.updated()
endfunction

function! s:self.get_raw_contents() dict
  let [year, month, day] = b:calendar.day().get_ymd()
  let key = join([year, month, day], '-')
  let events = deepcopy(get(get(b:calendar.event.get_events_one_month(year, month), key, {}), 'events', []))
  let cnt = []
  let ev = {}
  for e in events
    if !has_key(e, 'summary')
      continue
    endif
    let starttime = has_key(e, 'start') && has_key(e.start, 'dateTime') ? substitute(substitute(e.start.dateTime, '^\d\+-\d\+-\d\+T\|[-+]\d\+:\d\+$\|Z$', '', 'g'), ':00$', '', '') : ''
    let endtime = has_key(e, 'end') && has_key(e.end, 'dateTime') ? substitute(substitute(e.end.dateTime, '^\d\+-\d\+-\d\+T\|[-+]\d\+:\d\+$\|Z$', '', 'g'), ':00$', '', '') : ''
    let sameyear = e.ymd[0] == e.endymd[0]
    let samedate = e.ymd == e.endymd
    if sameyear
      let startdate = calendar#day#join_date(e.ymd[1:])
      let enddate = calendar#day#join_date(e.endymd[1:])
    else
      let startdate = calendar#day#join_date(e.ymd)
      let enddate = calendar#day#join_date(e.endymd)
    endif
    if starttime !=# '' || endtime !=# ''
      let e.title = (samedate ? '' : startdate . ' ') . starttime . ' - ' . (samedate ? '' : enddate . ' ') . endtime . ' ' . e.summary
    else
      if !samedate
        let e.title = startdate . ' - ' . enddate . ' ' . e.summary
      endif
    endif
    if !has_key(ev, e.calendarId)
      call add(cnt, { 'title': e.calendarSummary, 'items': [] })
      let ev[e.calendarId] = len(cnt) - 1
    endif
    let i = ev[e.calendarId]
    call add(cnt[i].items, e)
  endfor
  for c in cnt
    call sort(c.items, 'calendar#view#event#sorter')
  endfor
  return cnt
endfunction

function! calendar#view#event#sorter(l, r)
  let l = get(a:l, 'title', get(a:l, 'summary', ''))
  let r = get(a:r, 'title', get(a:l, 'summary', ''))
  return l =~# '^\d' && r !~# '^\d' ? 1 :
       \ l !~# '^\d' && r =~# '^\d' ? -1 :
       \ l > r ? 1 : -1
endfunction

function! s:self.action(action) dict
  let event = self.current_contents()
  let calendarId = get(event, 'calendarId', '')
  let [year, month, day] = b:calendar.day().get_ymd()
  let eventid = get(event, 'id', '')
  if index(['delete', 'delete_line'], a:action) >= 0
    call self.yank()
    if calendarId !=# ''
      call b:calendar.event.delete(calendarId, eventid, year, month)
    endif
  elseif index(['start_insert', 'start_insert_append', 'start_insert_head', 'start_insert_last', 'change', 'change_line'], a:action) >= 0
    if eventid !=# '' && calendarId !=# ''
      let head = index(['start_insert', 'start_insert_head'], a:action) >= 0
      let change = index(['change', 'change_line'], a:action) >= 0
      let msg = calendar#message#get('input_event') . (change ? get(event, 'summary', get(event, 'title', '')) . ' -> ' : '')
      let title = input(msg, change ? '' : get(event, 'summary', get(event, 'title', '')) . (head ? "\<Home>" : ''))
      if title !=# ''
        let [title, startdate, enddate, recurrence] = s:parse_title(title, 1)
        let opt = {}
        if startdate !=# ''
          call extend(opt, { 'start': startdate =~# 'T\d' ? { 'dateTime': startdate } : { 'date': startdate  } })
        endif
        if enddate !=# ''
          call extend(opt, { 'end': enddate =~# 'T\d' ? { 'dateTime': enddate } : { 'date': enddate } })
        endif
        call extend(opt, recurrence)
        call b:calendar.event.update(calendarId, eventid, title, year, month, opt)
      endif
    else
      return self.action('start_insert_next_line')
    endif
  elseif index(['start_insert_next_line', 'start_insert_prev_line'], a:action) >= 0
    call self.insert_new_event(a:action)
  else
    return self._action(a:action)
  endif
endfunction

function! s:self.insert_new_event(action, ...) dict
  let event = a:0 ? a:1 : self.current_contents()
  let calendarId = get(event, 'calendarId', '')
  let [year, month, day] = b:calendar.day().get_ymd()
  let input_prefix = b:calendar.view.current_view().timerange()
  let title = input(calendar#message#get('input_event'), input_prefix)
  if title !=# ''
    let next = a:action ==# 'start_insert_next_line'
    if next
      let self.select += 1
    endif
    let [title, startdate, enddate, recurrence] = s:parse_title(title)
    let calendars = b:calendar.event.calendarList()
    if len(calendars) == 0
      if calendar#setting#get('google_calendar')
        return
      else
        call b:calendar.event.createCalendar()
        let calendars = b:calendar.event.calendarList()
        if len(calendars) == 0
          return
        endif
      endif
    endif
    if len(calendars) > 1
      let msg = []
      let idx = 0
      let _idx = -1
      let i = 0
      call add(msg, 'index title')
      for cal in calendars
        if cal.id ==# calendarId
          let _idx = i
          call add(msg, printf('[%2d]  %s', i, cal.summary))
        else
          call add(msg, printf(' %2d   %s', i, cal.summary))
        endif
        let i += 1
      endfor
      if _idx < 0
        let cal = calendars[0]
        let msg[1] = printf('[%2d]  %s', 0, cal.summary)
        let _idx = 0
      endif
      call calendar#echo#message_raw(join(msg, "\n"))
      let idx = input(calendar#message#get('input_calendar_index'))
      if idx ==# ''
        let idx = _idx
      else
        let idx = min([max([idx, 0]), len(calendars)])
      endif
    else
      let idx = 0
    endif
    let calendarId = get(get(calendars, idx, get(calendars, 0, {})), 'id', '')
    call b:calendar.event.insert(calendarId, title, startdate, enddate, year, month, recurrence)
  endif
endfunction

function! s:parse_title(title, ...)
  let title = a:title
  let [year, month, day] = b:calendar.day().get_ymd()
  let [nyear, nmonth, nday] = b:calendar.day().new(year, month, day).add(1).get_ymd()
  let date = join([year, month, day], '-')
  let ndate = join([nyear, nmonth, nday], '-')
  let [startdate, enddate] = ['', '']
  if title =~# '^\s*\d\+:\d\+\%(:\d\+\)\?\s*-\s*\d\+:\d\+\%(:\d\+\)\?'
    let time = matchstr(title, '^\s*\d\+:\d\+\%(:\d\+\)\?\s*-\s*\d\+:\d\+\%(:\d\+\)\?')
    let starttime = matchstr(time, '^\s*\d\+:\d\+\%(:\d\+\)\?')
    let endtime = matchstr(time[len(starttime):], '\d\+:\d\+\%(:\d\+\)\?')
    if starttime =~# '^\s*2[4-9]:'
      let hour = substitute(matchstr(starttime, '^\s*2[4-9]'), '\s*', '', '')
      let starttime = (hour - 24) . starttime[len(hour):]
      let startday = ndate
    else
      let startday = date
    endif
    if endtime =~# '^2[4-9]:'
      let hour = matchstr(endtime, '^2[4-9]')
      let endtime = (hour - 24) . endtime[len(hour):]
      let endday = ndate
    else
      let endday = date
    endif
    let title = substitute(title[len(time):], '^\s*', '', '')
    let [startdate, enddate] = [s:format_time(startday . 'T' . starttime), s:format_time(endday . 'T' . endtime)]
  elseif title =~# '^\s*\d\+[-/]\d\+\%([-/]\d\+\)\?\s*-\s*\d\+[-/]\d\+\%([-/]\d\+\)\?'
    let time = matchstr(title, '^\s*\d\+[-/]\d\+\%([-/]\d\+\)\?\s*-\s*\d\+[-/]\d\+\%([-/]\d\+\)\?')
    let starttime = matchstr(time, len(split(time, '-')) == 2 ? '^\s*\d\+/\d\+\%(/\d\+\)\?\s*' : '^\s*\d\+[-/]\d\+\%([-/]\d\+\)\?\s*')
    let endtime = matchstr(time[len(starttime):], '\d\+[-/]\d\+\%([-/]\d\+\)\?')
    let title = substitute(title[len(time):], '^\s*', '', '')
    let [startdate, enddate] = [s:format_time(starttime), s:format_time_end(endtime)]
    if startdate =~# '^\d\+-\d\+-\d\+$' && enddate =~# '^\d\+-\d\+-\d\+$'
      let [sy, sm, sd] = map(split(startdate, '-'), 'v:val + 0')
      let [ey, em, ed] = map(split(enddate, '-'), 'v:val + 0')
      if sy == ey && sm > em
        if [year, month] == [ey, em]
          let startdate = join([sy - 1, sm, sd], '-')
        else
          let enddate = join([ey + 1, em, ed], '-')
        endif
      endif
    endif
  elseif title =~# '^\s*\d\+[-/]\d\+\%([-/]\d\+\)\?\s\+\d\+:\d\+\%(:\d\+\)\?\s*-\s*\d\+[-/]\d\+\%([-/]\d\+\)\?\s\+\d\+:\d\+\%(:\d\+\)\?'
    let time = matchstr(title, '^\s*\d\+[-/]\d\+\%([-/]\d\+\)\?\s\+\d\+:\d\+\%(:\d\+\)\?\s*-\s*\d\+[-/]\d\+\%([-/]\d\+\)\?\s\+\d\+:\d\+\%(:\d\+\)\?')
    let starttime = matchstr(time, '^\s*\d\+[-/]\d\+\%([-/]\d\+\)\?\s\+\d\+:\d\+\%(:\d\+\)\?\s*')
    let endtime = matchstr(time[len(starttime):], '\d\+[-/]\d\+\%([-/]\d\+\)\?\s\+\d\+:\d\+\%(:\d\+\)\?')
    let starttime = substitute(starttime, '^\s*\|\s*$', '', 'g')
    let endtime = substitute(endtime, '^\s*\|\s*$', '', 'g')
    let title = substitute(title[len(time):], '^\s*', '', '')
    let [startdate, enddate] = [s:format_time(starttime), s:format_time(endtime)]
  elseif !a:0 || !a:1
    let [startdate, enddate] = [date, ndate]
  endif
  let recurrence = {}
  if title =~# '^\s*\d\+\%(weeks\|days\)\s\+'
    let rec = matchstr(title, '^\s*\d\+\%(weeks\|days\)\s\+')
    let title = substitute(title[len(rec):], '^\s*', '', '')
    let recurrence = {}
    let key = matchstr(rec, '\(week\|day\)')
    let recurrence[key] = matchstr(rec, '\d\+') + 0
    if title =~# '^\s*\d\+:\d\+\%(:\d\+\)\?\s*-\s*\d\+:\d\+\%(:\d\+\)\?' && startdate !~# 'T'
      let time = matchstr(title, '^\s*\d\+:\d\+\%(:\d\+\)\?\s*-\s*\d\+:\d\+\%(:\d\+\)\?')
      let starttime = matchstr(time, '^\s*\d\+:\d\+\%(:\d\+\)\?')
      let endtime = matchstr(time[len(starttime):], '\d\+:\d\+\%(:\d\+\)\?')
      let title = substitute(title[len(time):], '^\s*', '', '')
      let [startdate, enddate] = [s:format_time(startdate . 'T' . starttime), s:format_time(startdate . 'T' . endtime)]
    endif
  endif
  return [title, startdate, enddate, recurrence]
endfunction

function! s:format_time(time)
  let time = substitute(a:time, '^\s\+\|\s\+$', '', 'g')
  let endian = calendar#setting#get('date_endian')
  if time =~# '^\d\+-\d\+-\d\+T\s*$'
    return substitute(time, 'T\s*$', '', '')
  elseif time =~# '^\d\+[-/]\d\+[-/]\d\+\s*$'
    let [y, m, d] = split(time, '[-/]')
    if d > 1000
      let [y, m, d] = endian ==# 'little' ? [d, m, y] : [d, y, m]
      if m > 12
        let [d, m] = [m, d]
      endif
    endif
    return join([y, m, d], '-')
  elseif time =~# '^\d\+[-/]\d\+\s*$'
    let [m, d] = split(time, '[-/]')
    if m > 12
      let [d, m] = [m, d]
    endif
    let y = b:calendar.day().get_year()
    return join([y, m, d], '-')
  elseif time =~# '^\d\+[-/]\d\+\s\+\d\+:'
    let [date, t] = split(time, '\s\+')
    let [m, d] = split(date, '[-/]')
    if m > 12
      let [d, m] = [m, d]
    endif
    let y = b:calendar.day().get_year()
    return join([y, m, d], '-') . 'T' . s:format_time(t)
  elseif time =~# '^\d\+[-/]\d\+[-/]\d\+\s\+\d\+:'
    let [date, t] = split(time, '\s\+')
    let [y, m, d] = split(date, '[-/]')
    if d > 1000
      let [y, m, d] = endian ==# 'little' ? [d, m, y] : [d, y, m]
      if m > 12
        let [d, m] = [m, d]
      endif
    endif
    return join([y, m, d], '-') . 'T' . s:format_time(t)
  elseif time =~# '^\d\+-\d\+-\d\+T\d\+$'
    return time . ':00:00'
  elseif time =~# '^\d\+-\d\+-\d\+T\d\+:\d\+$'
    return time . ':00'
  elseif time =~# '^\d\+-\d\+-\d\+T\d\+:\d\+:\d\+$'
    return time
  elseif time =~# '^\d\+:\d\+$'
    return time . ':00'
  endif
  return time
endfunction

function! s:format_time_end(time)
  let time = s:format_time(a:time)
  if time =~# '^\d\+-\d\+-\d\+$'
    let ymdstr = matchstr(time, '^\d\+-\d\+-\d\+$')
    let ymd = map(split(ymdstr, '-'), 'v:val + 0')
    if len(ymd) == 3
      let newdate = calendar#day#new(ymd[0], ymd[1], ymd[2]).add(1)
      return join(newdate.get_ymd(), '-')
    endif
  endif
  return time
endfunction

let s:constructor = calendar#constructor#view_textbox#new(s:self)

let &cpo = s:save_cpo
unlet s:save_cpo
