" =============================================================================
" Filename: autoload/calendar/google/calendar.vim
" Author: itchyny
" License: MIT License
" Last Change: 2014/01/10 11:28:00.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

let s:cache = calendar#cache#new('google')

let s:event_cache = s:cache.new('event')

let g:calendar_google_event_download = 0
let g:calendar_google_event_downloading = {}
let g:calendar_google_event_downloading_list = 0

function! calendar#google#calendar#get_url(type)
  return 'https://www.googleapis.com/calendar/v3/' . a:type
endfunction

function! calendar#google#calendar#getCalendarList()
  if g:calendar_google_event_downloading_list
    return {}
  endif
  let calendarList = s:cache.get('calendarList')
  if type(calendarList) != type({})
    let g:calendar_google_event_downloading_list = 1
    call calendar#google#client#get_async(s:newid(['calendarList', 0]),
          \ 'calendar#google#calendar#getCalendarList_response',
          \ calendar#google#calendar#get_url('users/me/calendarList'))
    return {}
  else
    let content = calendarList
  endif
  return content
endfunction

function! calendar#google#calendar#getCalendarList_response(id, response)
  let [_calendarlist, err; rest] = s:getdata(a:id)
  if a:response.status =~# '^2'
    let cnt = calendar#webapi#decode(a:response.content)
    let content = type(cnt) == type({}) ? cnt : {}
    if has_key(content, 'items') && type(content.items) == type([])
      silent! call s:cache.save('calendarList', content)
      let g:calendar_google_event_downloading_list = 0
      let g:calendar_google_event_download = 3
      silent! let b:calendar.event._updated = 10
      silent! call b:calendar.update()
    endif
  elseif a:response.status == 401
    if err == 0
      call calendar#google#client#refresh_token()
      call calendar#google#client#get_async(s:newid(['calendarList', err + 1]),
            \ 'calendar#google#calendar#getCalendarList_response',
            \ calendar#google#calendar#get_url('users/@me/lists'))
    endif
  endif
endfunction

function! calendar#google#calendar#getMyCalendarList()
  let calendarList = calendar#google#calendar#getCalendarList()
  let validCalendar = filter(get(deepcopy(calendarList), 'items', []), 'type(v:val) == type({}) && has_key(v:val, "summary") && has_key(v:val, "id")')
  return filter(validCalendar, 'get(v:val, "selected") && get(v:val, "accessRole", "") ==# "owner"')
endfunction

function! calendar#google#calendar#getEventSummary(year, month)
  let calendarList = calendar#google#calendar#getCalendarList()
  let events = []
  if has_key(calendarList, 'items') && type(calendarList.items) == type([]) && len(calendarList.items)
    for item in calendarList.items
      unlet! cnt
      if get(item, 'selected')
        let cnt = s:event_cache.new(item.id).new(printf('%04d', a:year)).new(printf('%02d', a:month)).get('information')
        if type(cnt) == type({}) && has_key(cnt, 'summary')
          call add(events, cnt)
        else
          call calendar#google#calendar#downloadEvents(a:year, a:month)
          break
        endif
      endif
    endfor
  endif
  return events
endfunction

function! calendar#google#calendar#initialDownload(year, month, index)
  let myCalendarList = calendar#google#calendar#getMyCalendarList()
  let key = join([a:year, a:month], '/')
  if a:index < len(myCalendarList) && get(s:initial_download, key, 2) < 2
    call calendar#async#new(printf('calendar#google#calendar#downloadEvents(%d, %d, "%s", %d)', a:year, a:month, myCalendarList[a:index].id, a:index))
  endif
endfunction

let s:initial_download = {}
let s:event_download = {}
function! calendar#google#calendar#getEventsInitial(year, month)
  let myCalendarList = calendar#google#calendar#getMyCalendarList()
  let events = {}
  let key = join([a:year, a:month], '/')
  if !get(s:initial_download, key)
    let s:initial_download[key] = 1
    if len(myCalendarList) && calendar#timestamp#update(join(['google', 'calendar.vim', a:year, a:month], '#'), 1, 2 * 60 * 60)
      call calendar#async#new(printf('calendar#google#calendar#initialDownload(%d, %d, 0)', a:year, a:month))
    endif
  endif
endfunction

" The optional argument: Forcing initial download. s:initial_download is used to check.
function! calendar#google#calendar#getEvents(year, month, ...)
  let calendarList = calendar#google#calendar#getCalendarList()
  let myCalendarList = calendar#google#calendar#getMyCalendarList()
  let events = {}
  let key = join([a:year, a:month], '/')
  if a:0 && a:1
    call calendar#google#calendar#getEventsInitial(a:year, a:month)
  endif
  if has_key(calendarList, 'items') && type(calendarList.items) == type([]) && len(calendarList.items)
    for item in calendarList.items
      if !get(item, 'selected')
        continue
      endif
      let isHoliday = item.id =~# 'holiday@group.v.calendar.google.com'
      let isMoon = item.summary ==# 'Phases of the Moon' && &enc ==# 'utf-8' && &fenc ==# 'utf-8'
      let isDayNum = item.summary ==# 'Day of the Year'
      let isWeekNum = item.summary ==# 'Week Numbers'
      let syn = calendar#color#new_syntax(get(item, 'id', ''), get(item, 'foregroundColor', ''), get(item, 'backgroundColor'))
      unlet! cnt
      let cnt = s:event_cache.new(item.id).new(printf('%04d', a:year)).new(printf('%02d', a:month)).get('information')
      if type(cnt) == type({}) && has_key(cnt, 'summary')
        unlet! c
        let c = {}
        let index = 0
        while type(c) == type({})
          unlet! c
          let c = s:event_cache.new(item.id).new(printf('%04d', a:year)).new(printf('%02d', a:month)).get(index)
          if type(c) == type({}) && has_key(c, 'items') && type(c.items) == type([])
            for itm in c.items
              if has_key(itm, 'start') && (has_key(itm.start, 'date') || has_key(itm.start, 'dateTime'))
                    \ && has_key(itm, 'end') && (has_key(itm.end, 'date') || has_key(itm.end, 'dateTime'))
                let date = has_key(itm.start, 'date') ? itm.start.date : has_key(itm.start, 'dateTime') ? matchstr(itm.start.dateTime, '\d\+-\d\+-\d\+') : ''
                let ymd = map(split(date, '-'), 'v:val + 0')
                let enddate = has_key(itm.end, 'date') ? itm.end.date : has_key(itm.end, 'dateTime') ? matchstr(itm.end.dateTime, '\d\+-\d\+-\d\+') : ''
                let endymd = map(split(enddate, '-'), 'v:val + 0')
                if len(date) && len(ymd) == 3 && len(endymd) == 3 && [a:year, a:month] == [ymd[0], ymd[1]]
                  let date = printf('%4d-%02d-%02d', ymd[0], ymd[1], ymd[2])
                  if has_key(itm.end, 'date')
                    let endymd = calendar#day#new(endymd[0], endymd[1], endymd[2]).add(-1).get_ymd()
                  endif
                  if !has_key(events, date)
                    let events[date] = { 'events': [], 'hasHoliday': 0, 'hasMoon': 0, 'hasDayNum': 0, 'hasWeekNum': 0 }
                  endif
                  call add(events[date].events,
                        \ extend(deepcopy(itm),
                        \ { 'calendarId': item.id
                        \ , 'calendarSummary': item.summary
                        \ , 'syntax': syn
                        \ , 'isHoliday': isHoliday
                        \ , 'isMoon': isMoon
                        \ , 'isDayNum': isDayNum
                        \ , 'isWeekNum': isWeekNum
                        \ , 'ymd': ymd
                        \ , 'endymd': endymd }))
                  if isHoliday
                    let events[date].hasHoliday = 1
                    let events[date].holidayIndex = len(events[date].events) - 1
                  endif
                  if isMoon
                    let events[date].hasMoon = 1
                    let events[date].moonIndex = len(events[date].events) - 1
                    let summary = events[date].events[-1].summary
                    let dark = &bg ==# 'dark'
                    let moon = summary =~# '^New moon'      ? (dark ? "\u25cb" : "\u25cf")
                          \  : summary =~# '^First quarter' ? (dark ? "\u25d1" : "\u25d0")
                          \  : summary =~# '^Full moon'     ? (dark ? "\u25cf" : "\u25cb")
                          \  : summary =~# '^Last quarter'  ? (dark ? "\u25d0" : "\u25d1")
                          \  : ''
                    let moon = calendar#string#truncate(moon, 2)
                    let events[date].events[-1].moon = moon
                    if len(moon)
                      let events[date].events[-1].summary = moon . ' ' . events[date].events[-1].summary
                    endif
                  endif
                  if isDayNum
                    let events[date].hasDayNum = 1
                    let events[date].daynumIndex = len(events[date].events) - 1
                    let summary = events[date].events[-1].summary
                    let events[date].events[-1].daynum = matchstr(summary, '\d\+')
                  endif
                  if isWeekNum
                    let events[date].hasWeekNum = 1
                    let events[date].weeknumIndex = len(events[date].events) - 1
                    let summary = events[date].events[-1].summary
                    let events[date].events[-1].weeknum = matchstr(summary, '\d\+')
                  endif
                endif
              endif
            endfor
          endif
          let index += 1
        endwhile
      elseif !get(s:event_download, key)
        let s:event_download[key] = 1
        call calendar#google#calendar#downloadEvents(a:year, a:month)
        break
      endif
    endfor
  endif
  return events
endfunction

function! calendar#google#calendar#getHolidays(year, month)
  let _calendarList = s:cache.get('calendarList')
  let calendarList = type(_calendarList) == type({}) ? _calendarList : {}
  let events = {}
  if has_key(calendarList, 'items') && type(calendarList.items) == type([]) && len(calendarList.items)
    for item in calendarList.items
      if !get(item, 'selected')
        continue
      endif
      if item.id =~# 'holiday@group.v.calendar.google.com'
        unlet! cnt
        let cnt = s:event_cache.new(item.id).new(printf('%04d', a:year)).new(printf('%02d', a:month)).get('information')
        if type(cnt) == type({}) && has_key(cnt, 'summary')
          unlet! c
          let c = {}
          let index = 0
          while type(c) == type({})
            unlet! c
            let c = s:event_cache.new(item.id).new(printf('%04d', a:year)).new(printf('%02d', a:month)).get(index)
            if type(c) == type({}) && has_key(c, 'items') && type(c.items) == type([])
              for itm in c.items
                if has_key(itm, 'start') && (has_key(itm.start, 'date') || has_key(itm.start, 'dateTime'))
                  let date = has_key(itm.start, 'date') ? itm.start.date
                        \  : has_key(itm.start, 'dateTime') ? matchstr(itm.start.dateTime, '\d\+-\d\+-\d\+') : ''
                  let ymd = map(split(date, '-'), 'v:val + 0')
                  let enddate = has_key(itm.end, 'date') ? itm.end.date : has_key(itm.end, 'dateTime') ? matchstr(itm.end.dateTime, '\d\+-\d\+-\d\+') : ''
                  let endymd = map(split(enddate, '-'), 'v:val + 0')
                  if len(date) && len(ymd) == 3 && len(endymd) == 3
                    let date = printf('%4d-%02d-%02d', ymd[0], ymd[1], ymd[2])
                    if has_key(itm.end, 'date')
                      let endymd = calendar#day#new(endymd[0], endymd[1], endymd[2]).add(-1).get_ymd()
                    endif
                    if !has_key(events, date)
                      let events[date] = { 'events': [], 'hasHoliday': 1, 'hasMoon': 0, 'hasDayNum': 0, 'hasWeekNum': 0 }
                    endif
                    call add(events[date].events,
                          \ extend(deepcopy(itm),
                          \ { 'calendarId': item.id
                          \ , 'calendarSummary': item.summary
                          \ , 'isHoliday': 1
                          \ , 'isMoon': 0
                          \ , 'isDayNum': 0
                          \ , 'isWeekNum': 0
                          \ , 'ymd': ymd
                          \ , 'endymd': endymd }))
                  endif
                endif
              endfor
            endif
            let index += 1
          endwhile
          break
        endif
      endif
    endfor
  endif
  return events
endfunction

" The optional argument is:
"   The first argument: Specify the calendar id. If this argument is given,
"                       the only one calendar is downloaded.
"   The second argument: Initial download. See calendar#google#calendar#initialDownload.
function! calendar#google#calendar#downloadEvents(year, month, ...)
  let calendarList = calendar#google#calendar#getCalendarList()
  let key = join([a:year, a:month], '/')
  if a:0 < 1
    let s:initial_download[key] = 2
  endif
  let month = a:month + 1
  let year = a:year
  if month > 12
    let [year, month] = [year + 1, month - 12]
  endif
  let [timemin, timemax] = [printf('%04d-%02d-01T00:00:00Z', a:year, a:month), printf('%04d-%02d-01T00:00:00Z', year, month)]
  if has_key(g:calendar_google_event_downloading, timemin)
    let g:calendar_google_event_downloading[timemin] = 1
  endif
  if has_key(calendarList, 'items') && type(calendarList.items) == type([]) && len(calendarList.items)
    let j = 0
    while j < len(calendarList.items)
      let item = calendarList.items[j]
      if !get(item, 'selected') || a:0 && item.id !=# a:1
        let j += 1
        continue
      endif
      unlet! cnt
      let cnt = s:event_cache.new(item.id).new(printf('%04d', a:year)).new(printf('%02d', a:month)).get('information')
      if type(cnt) != type({}) || !has_key(cnt, 'summary') || a:0
        let opt = { 'timeMin': timemin, 'timeMax': timemax, 'singleEvents': 'true' }
        call calendar#google#client#get_async(s:newid(['download', 0, 0, 0, timemin, timemax, printf('%04d', a:year), printf('%02d', a:month), item.id]),
              \ 'calendar#google#calendar#response',
              \ calendar#google#calendar#get_url('calendars/' . item.id . '/events'), opt)
        break
      endif
      let j += 1
    endwhile
    if a:0 > 1
      call calendar#async#new(printf('calendar#google#calendar#initialDownload(%d, %d, %d)', a:year, a:month, a:2 + 1))
    endif
  endif
endfunction

function! calendar#google#calendar#response(id, response)
  let calendarList = calendar#google#calendar#getCalendarList()
  let [_download, err, j, i, timemin, timemax, year, month, id; rest] = s:getdata(a:id)
  let opt = { 'timeMin': timemin, 'timeMax': timemax, 'singleEvents': 'true' }
  if a:response.status =~# '^2'
    let cnt = calendar#webapi#decode(a:response.content)
    let content = type(cnt) == type({}) ? cnt : {}
    if has_key(content, 'items')
      silent! call s:event_cache.new(id).new(year).new(month).save(i, content)
      if i == 0
        call remove(content, 'items')
        silent! call s:event_cache.new(id).new(year).new(month).save('information', content)
      endif
      if has_key(content, 'nextPageToken')
        let opt = extend(opt, { 'pageToken': content.nextPageToken })
        call calendar#google#client#get_async(s:newid(['download', err, j, i + 1, timemin, timemax, year, month, id]),
              \ 'calendar#google#calendar#response',
              \ calendar#google#calendar#get_url('calendars/' . id . '/events'), opt)
      else
        let g:calendar_google_event_download = 2
        let j += 1
        while j < len(calendarList.items)
          let item = calendarList.items[j]
          if !get(item, 'selected')
            let j += 1
            continue
          endif
          unlet! cnt
          let cnt = s:event_cache.new(item.id).new(year).new(month).get('information')
          if type(cnt) != type({}) || !has_key(cnt, 'summary')
            call calendar#google#client#get_async(s:newid(['download', 0, j, 0, timemin, timemax, year, month, item.id]),
                  \ 'calendar#google#calendar#response',
                  \ calendar#google#calendar#get_url('calendars/' . item.id . '/events'), opt)
            break
          endif
          let j += 1
        endwhile
        if j == len(calendarList.items)
          let g:calendar_google_event_download = 3
          silent! let b:calendar.event._updated = 10
          silent! call b:calendar.update()
        endif
      endif
    endif
  elseif a:response.status == 401 || a:response.status == 404
    if i == 0 && err == 0
      call calendar#google#client#refresh_token()
      call calendar#google#client#get_async(s:newid(['download', err + 1, j, i, timemin, timemax, year, month, id]),
            \ 'calendar#google#calendar#response',
            \ calendar#google#calendar#get_url('calendars/' . id . '/events'), opt)
    else
      call calendar#google#client#get_async_use_api_key(s:newid(['download', err + 1, j, 0, timemin, timemax, year, month, id]),
            \ 'calendar#google#calendar#response',
            \ calendar#google#calendar#get_url('calendars/' . s:event_cache.escape(id) . '/events'), opt)
    endif
  endif
endfunction

function! calendar#google#calendar#update(calendarId, eventId, title, year, month)
  call calendar#google#client#patch_async(s:newid(['update', 0, a:year, a:month, a:calendarId, a:eventId, a:title]),
        \ 'calendar#google#calendar#update_response',
        \ calendar#google#calendar#get_url('calendars/' . a:calendarId . '/events/' . a:eventId),
        \ { 'calendarId': a:calendarId, 'eventId': a:eventId },
        \ { 'id': a:eventId, 'summary': a:title })
endfunction

function! calendar#google#calendar#update_response(id, response)
  let [_update, err, year, month, calendarId, eventId, title; rest] = s:getdata(a:id)
  if a:response.status =~# '^2'
    call calendar#google#calendar#downloadEvents(year, month, calendarId)
  elseif a:response.status == 401
    if err == 0
      call calendar#google#client#refresh_token()
      call calendar#google#client#patch_async(s:newid(['update', 0, year, month, calendarId, eventId, title]),
            \ 'calendar#google#calendar#update_response',
            \ calendar#google#calendar#get_url('calendars/' . calendarId . '/events/' . eventId),
            \ { 'calendarId': calendarId, 'eventId': eventId },
            \ { 'id': eventId, 'summary': title })
    endif
  endif
endfunction

function! calendar#google#calendar#insert(calendarId, title, start, end, year, month)
  let start = a:start =~# 'T\d' && len(a:start) > 10 ? { 'dateTime': a:start } : { 'date': a:start }
  let end = a:end =~# 'T\d' && len(a:end) > 10 ? { 'dateTime': a:end } : { 'date': a:end }
  let calendars = filter(calendar#google#calendar#getMyCalendarList(), 'v:val.id ==# a:calendarId')
  let timezone = get(get(calendars, 0, get(calendar#google#calendar#getMyCalendarList(), 0, {})), 'timeZone', 'Z')
  let location = matchstr(a:title, '\%( at \)\@<=.\+$')
  let loc = len(location) ? { 'location': location } : {}
  if timezone ==# 'Z'
    if has_key(start, 'dateTime')
      let start.dateTime .= timezone
    endif
    if has_key(end, 'dateTime')
      let end.dateTime .= timezone
    endif
    let tz = {}
  else
    if has_key(start, 'dateTime')
      let start.timeZone = timezone
    endif
    if has_key(end, 'dateTime')
      let end.timeZone = timezone
    endif
  endif
  call calendar#google#client#post_async(s:newid(['insert', 0, a:year, a:month, a:calendarId, a:start, a:end, a:title]),
        \ 'calendar#google#calendar#insert_response',
        \ calendar#google#calendar#get_url('calendars/' . a:calendarId . '/events'),
        \ { 'calendarId': a:calendarId },
        \ extend({ 'summary': a:title, 'start': start, 'end': end, 'transparency': 'transparent' }, loc))
endfunction

function! calendar#google#calendar#insert_response(id, response)
  let [_insert, err, year, month, calendarId, start, end, title; rest] = s:getdata(a:id)
  if a:response.status =~# '^2'
    call calendar#google#calendar#downloadEvents(year, month, calendarId)
  elseif a:response.status == 401
    if err == 0
      call calendar#google#client#refresh_token()
      call calendar#google#client#post_async(s:newid(['insert', 0, year, month, calendarId, start, end, title]),
            \ 'calendar#google#calendar#insert_response',
            \ calendar#google#calendar#get_url('calendars/' . calendarId . '/events'),
            \ { 'calendarId': calendarId },
            \ { 'summary': title, 'start': start, 'end': end })
    endif
  endif
endfunction

function! calendar#google#calendar#delete(calendarId, eventId, year, month)
  call calendar#google#client#delete_async(s:newid(['delete', 0, a:year, a:month, a:calendarId, a:eventId]),
        \ 'calendar#google#calendar#delete_response',
        \ calendar#google#calendar#get_url('calendars/' . a:calendarId . '/events/' . a:eventId),
        \ { 'calendarId': a:calendarId, 'eventId': a:eventId }, {})
endfunction

function! calendar#google#calendar#delete_response(id, response)
  let [_delete, err, year, month, calendarId, eventId; rest] = s:getdata(a:id)
  if a:response.status =~# '^2' || a:response.status ==# '410'
    call calendar#google#calendar#downloadEvents(year, month, calendarId)
  elseif a:response.status == 401
    if err == 0
      call calendar#google#client#refresh_token()
      call calendar#google#client#delete_async(s:newid(['delete', 0, calendarId, eventId]),
            \ 'calendar#google#calendar#delete_response',
            \ calendar#google#calendar#get_url('calendars/' . calendarId . '/events/' . eventId),
            \ { 'calendarId': calendarId, 'eventId': eventId })
    endif
  endif
endfunction

let s:id_data = {}
function! s:newid(data)
  let id = join([ 'google', 'calendar', a:data[0] ], '_') . calendar#util#id()
  let s:id_data[id] = a:data
  return id
endfunction

function! s:getdata(id)
  return s:id_data[a:id]
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
