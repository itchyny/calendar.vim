" =============================================================================
" Filename: autoload/calendar/view/event.vim
" Author: itchyny
" License: MIT License
" Last Change: 2020/02/08 16:03:06.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

function! calendar#view#event#new(source) abort
  return s:constructor.new(a:source)
endfunction

let s:self = {}

let s:self._select_line = 1

function! s:self.get_key() dict abort
  return b:calendar.day().get_ymd() + [get(g:, 'calendar_google_event_download')] + b:calendar.event.updated()
endfunction

function! s:self.get_raw_contents() dict abort
  let [year, month, day] = b:calendar.day().get_ymd()
  let key = join([year, month, day], '-')
  let agenda = get(self.source, 'agenda', 0)
  let events = agenda ? s:get_agenda_events() : deepcopy(get(get(b:calendar.event.get_events_one_month(year, month), key, {}), 'events', []))
  let cnt = []
  let ev = {}
  for e in events
    if !has_key(e, 'summary')
      continue
    endif
    let starttime = get(e, 'isTimeEvent') && has_key(e, 'starttime') ? e.starttime : ''
    let endtime = get(e, 'isTimeEvent') && has_key(e, 'endtime') ? e.endtime : ''
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
    let key = agenda ? e.ymdnum : e.calendarId
    if !has_key(ev, key)
      call add(cnt, { 'title': agenda ? calendar#day#join_date(e.ymd) : e.calendarSummary, 'items': [], 'ymdnum': e.ymdnum })
      let ev[key] = len(cnt) - 1
    endif
    let i = ev[key]
    call add(cnt[i].items, e)
  endfor
  if agenda
    call sort(cnt, 'calendar#view#event#agenda_group_sorter')
    for c in cnt
      call sort(c.items, 'calendar#view#event#agenda_sorter')
    endfor
  else
    for c in cnt
      call sort(c.items, 'calendar#view#event#sorter')
    endfor
  endif
  return cnt
endfunction

function! s:get_agenda_events() abort
  let [year, month, day] = b:calendar.day().get_ymd()
  let current_ymdnum = ((year * 100 + month) * 100) + day
  let [eyear, emonth, eday] = b:calendar.day().add(7).get_ymd()
  let end_ymdnum = ((eyear * 100 + emonth) * 100) + eday
  let current_sec = calendar#time#now().seconds()
  let events = []
  let event_source = b:calendar.event.get_events_one_month(year, month)
  for key in keys(event_source)
    let event = get(get(event_source[key], 'events', []), 0, {})
    let ymdnum = get(event, 'ymdnum', 0)
    if current_ymdnum == ymdnum
      for event in event_source[key].events
        if current_sec <= get(event, 'sec', 0)
          call extend(events, [event])
        endif
      endfor
    elseif current_ymdnum < ymdnum && ymdnum < end_ymdnum
      call extend(events, event_source[key].events)
    endif
  endfor
  return events
endfunction

function! calendar#view#event#sorter(x, y) abort
  return a:x.calendarId ==# a:y.calendarId
        \ ? (a:x.sec == a:y.sec
        \   ? (get(a:x, 'summary', '') > get(a:y, 'summary', '') ? 1 : -1)
        \ : a:x.sec > a:y.sec ? 1 : -1) : 0
endfunction

function! calendar#view#event#agenda_sorter(x, y) abort
  return a:x.ymdnum == a:y.ymdnum ? (a:x.sec == a:y.sec
        \   ? (get(a:x, 'summary', '') > get(a:y, 'summary', '') ? 1 : -1)
        \ : a:x.sec > a:y.sec ? 1 : -1)
        \ : a:x.ymdnum > a:y.ymdnum ? 1 : -1
endfunction

function! calendar#view#event#agenda_group_sorter(x, y) abort
  return a:x.ymdnum > a:y.ymdnum ? 1 : -1
endfunction

function! s:self.action(action) dict abort
  let event = self.current_contents()
  let calendarId = get(event, 'calendarId', '')
  let [year, month, day] = b:calendar.day().get_ymd()
  let eventid = get(event, 'id', '')
  if index(['delete', 'delete_line'], a:action) >= 0
    if calendar#setting#get('yank_deleting')
      call self.yank()
    endif
    if calendarId !=# '' && (calendar#setting#get('skip_event_delete_confirm') || input(calendar#message#get('delete_event')) =~# '\c^y\%[es]$')
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
  elseif index(['start_insert_next_line', 'start_insert_prev_line', 'start_insert_quick'], a:action) >= 0
    call self.insert_new_event(a:action)
  elseif a:action ==# 'move_event'
    call self.move_event()
  else
    return self._action(a:action)
  endif
endfunction

function! s:self.insert_new_event(action, ...) dict abort
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
    if a:action ==# 'start_insert_quick'
      let primaryCalendarId = get(get(filter(deepcopy(calendars), 'get(v:val, "primary")'), 0, {}), 'id', '')
      let idx = index(map(deepcopy(calendars), 'get(v:val, "id", "")'), primaryCalendarId)
    elseif len(calendars) > 1
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

function! s:self.move_event() dict abort
  let event = self.current_contents()
  let calendarId = get(event, 'calendarId', '')
  let [year, month, day] = b:calendar.day().get_ymd()
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
  let destination = get(get(calendars, idx, get(calendars, 0, {})), 'id', '')
  call b:calendar.event.move(calendarId, event.id, destination, year, month)
endfunction

function! s:parse_title(title, ...) abort
  let title = a:title
  let [year, month, day] = b:calendar.day().get_ymd()
  let [nyear, nmonth, nday] = b:calendar.day().new(year, month, day).add(1).get_ymd()
  let date = join([year, month, day], '-')
  let ndate = join([nyear, nmonth, nday], '-')
  let [startdate, enddate] = ['', '']
  if title =~# '\v^\s*\d+:\d+(:\d+)?\s*-\s*\d+:\d+(:\d+)?'
    let time = matchstr(title, '\v^\s*\d+:\d+(:\d+)?\s*-\s*\d+:\d+(:\d+)?')
    let starttime = matchstr(time, '\v^\s*\d+:\d+(:\d+)?')
    let endtime = matchstr(time[len(starttime):], '\v\d+:\d+(:\d+)?')
    if starttime =~# '\v^\s*2[4-9]:'
      let hour = substitute(matchstr(starttime, '\v^\s*2[4-9]'), '\v\s*', '', '')
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
  elseif title =~# '\v^\s*\d+[-/]\d+([-/]\d+)?\s+\d+:\d+(:\d+)?\s*-\s*(\d+[-/]\d+([-/]\d+)?\s+)?\d+:\d+(:\d+)?'
    let time = matchstr(title, '\v^\s*\d+[-/]\d+([-/]\d+)?\s+\d+:\d+(:\d+)?\s*-\s*(\d+[-/]\d+([-/]\d+)?\s+)?\d+:\d+(:\d+)?')
    let starttime = matchstr(time, '\v^\s*\d+[-/]\d+([-/]\d+)?\s+\d+:\d+(:\d+)?\s*')
    let endtime = matchstr(time[len(starttime):], '\v(\d+[-/]\d+([-/]\d+)?\s+)?\d+:\d+(:\d+)?')
    let starttime = substitute(starttime, '\v^\s*|\s*$', '', 'g')
    let endtime = substitute(endtime, '\v^\s*|\s*$', '', 'g')
    if endtime !~# '\v^\d+[-/]\d+([-/]\d+)?'
      let endtime = matchstr(starttime, '\v^\d+[-/]\d+([-/]\d+)?\s+') . endtime
    endif
    let title = substitute(title[len(time):], '^\s*', '', '')
    let [startdate, enddate] = [s:format_time(starttime), s:format_time(endtime)]
  elseif title =~# '\v^\s*\d+[-/]\d+([-/]\d+)?%(\s*-\s*\d+[-/]\d+([-/]\d+)?|\s+)'
    let time = matchstr(title, '\v^\s*\d+[-/]\d+([-/]\d+)?%(\s*-\s*\d+[-/]\d+([-/]\d+)?|\s+)')
    let starttime = matchstr(time, '\v^\s*\d+[-/]\d+([-/]\d+)?\s*')
    let endtime = matchstr(time[len(starttime):], '\v\d+[-/]\d+([-/]\d+)?')
    let title = substitute(title[len(time):], '^\s*', '', '')
    let [startdate, enddate] = [s:format_time(starttime), s:format_time_end(endtime !=# '' ? endtime : starttime)]
    if startdate =~# '\v^\d+-\d+-\d+$' && enddate =~# '\v^\d+-\d+-\d+$'
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
  elseif !a:0 || !a:1
    let [startdate, enddate] = [date, ndate]
  endif
  let recurrence = {}
  if title =~# '\v^\s*\d+(weeks|days)\s+'
    let rec = matchstr(title, '\v^\s*\d+(weeks|days)\s+')
    let title = substitute(title[len(rec):], '^\s*', '', '')
    let recurrence = {}
    let key = matchstr(rec, '\(week\|day\)')
    let recurrence[key] = matchstr(rec, '\d\+') + 0
    if title =~# '\v^\s*\d+:\d+(:\d+)?\s*-\s*\d+:\d+(:\d+)?' && startdate !~# 'T'
      let time = matchstr(title, '\v^\s*\d+:\d+(:\d+)?\s*-\s*\d+:\d+(:\d+)?')
      let starttime = matchstr(time, '\v^\s*\d+:\d+(:\d+)?')
      let endtime = matchstr(time[len(starttime):], '\v\d+:\d+(:\d+)?')
      let title = substitute(title[len(time):], '^\s*', '', '')
      let [startdate, enddate] = [s:format_time(startdate . 'T' . starttime), s:format_time(startdate . 'T' . endtime)]
    endif
  endif
  return [title, startdate, enddate, recurrence]
endfunction

function! s:format_time(time) abort
  let time = substitute(a:time, '\v^\s+|\s+$', '', 'g')
  let endian = calendar#setting#get('date_endian')
  if time =~# '\v^\d+-\d+-\d+T\s*$'
    return substitute(time, 'T\s*$', '', '')
  elseif time =~# '\v^\d+[-/]\d+[-/]\d+\s*$'
    let [y, m, d] = split(time, '[-/]')
    if d > 1000
      let [y, m, d] = endian ==# 'little' ? [d, m, y] : [d, y, m]
      if m > 12
        let [d, m] = [m, d]
      endif
    endif
    return join([y, m, d], '-')
  elseif time =~# '\v^\d+[-/]\d+\s*$'
    let [m, d] = split(time, '[-/]')
    if m > 12
      let [d, m] = [m, d]
    endif
    let y = b:calendar.day().get_year()
    return join([y, m, d], '-')
  elseif time =~# '\v^\d+[-/]\d+\s+\d+:'
    let [date, t] = split(time, '\v\s+')
    let [m, d] = split(date, '[-/]')
    if m > 12
      let [d, m] = [m, d]
    endif
    let y = b:calendar.day().get_year()
    return join([y, m, d], '-') . 'T' . s:format_time(t)
  elseif time =~# '\v^\d+[-/]\d+[-/]\d+\s+\d+:'
    let [date, t] = split(time, '\v\s+')
    let [y, m, d] = split(date, '[-/]')
    if d > 1000
      let [y, m, d] = endian ==# 'little' ? [d, m, y] : [d, y, m]
      if m > 12
        let [d, m] = [m, d]
      endif
    endif
    return join([y, m, d], '-') . 'T' . s:format_time(t)
  elseif time =~# '\v^\d+-\d+-\d+T\d+$'
    return time . ':00:00'
  elseif time =~# '\v^\d+-\d+-\d+T\d+:\d+$'
    return time . ':00'
  elseif time =~# '\v^\d+-\d+-\d+T\d+:\d+:\d+$'
    return time
  elseif time =~# '\v^\d+:\d+$'
    return time . ':00'
  endif
  return time
endfunction

function! s:format_time_end(time) abort
  let time = s:format_time(a:time)
  if time =~# '\v^\d+-\d+-\d+$'
    let ymdstr = matchstr(time, '\v^\d+-\d+-\d+$')
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
