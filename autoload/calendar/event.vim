" =============================================================================
" Filename: autoload/calendar/event.vim
" Author: itchyny
" License: MIT License
" Last Change: 2014/01/05 12:29:03.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

" Event controller.
" This object handles both local and Google Calendar.
function! calendar#event#new()
  return deepcopy(s:self)
endfunction

let s:cache = calendar#cache#new('local')

let s:event_cache = s:cache.new('event')

let s:self = {}

let s:self._key = {}
let s:self._events = {}
let s:self.__events = {}
let s:self._holidays = {}
let s:self._updated = 0

function! s:self.updated() dict
  if self._updated > 0
    let self._updated -= 1
  endif
  return [self._updated]
endfunction

function! s:self.get_events_one_month(year, month, ...) dict
  if calendar#setting#get('google_calendar')
    let key = a:year . '-' . a:month
    if has_key(self._key, key) && has_key(self._events, key) && get(g:, 'calendar_google_event_download', 1) <= 0 && self._events[key] != {}
      return self._events[key]
    endif
    if has_key(self._key, key)
      unlet self._key[key]
    endif
    if has_key(g:, 'calendar_google_event_download')
      if get(g:, 'calendar_google_event_download') > 1
        let g:calendar_google_event_download -= 1
      endif
    endif
    let self._events[key] = calendar#google#calendar#getEvents(a:year, a:month, a:0 && a:1)
    let self._key[key] = 1
    return self._events[key]
  else
    let events = {}
    let calendarList = self.calendarList()
    for calendar in calendarList
      let syn = calendar#color#new_syntax(get(calendar, 'id', ''), get(calendar, 'foregroundColor', ''), get(calendar, 'backgroundColor'))
      unlet! c
      let c = s:event_cache.new(calendar.id).new(printf('%04d', a:year)).new(printf('%02d', a:month)).get('0')
      if type(c) == type({}) && has_key(c, 'items') && type(c.items) == type([])
        for itm in c.items
          if has_key(itm, 'start') && (has_key(itm.start, 'date') || has_key(itm.start, 'dateTime'))
                \ && has_key(itm, 'end') && (has_key(itm.end, 'date') || has_key(itm.end, 'dateTime'))
            let date = has_key(itm.start, 'date') ? itm.start.date : has_key(itm.start, 'dateTime') ? matchstr(itm.start.dateTime, '\d\+-\d\+-\d\+') : ''
            let ymd = map(split(date, '-'), 'v:val + 0')
            let enddate = has_key(itm.end, 'date') ? itm.end.date : has_key(itm.end, 'dateTime') ? matchstr(itm.end.dateTime, '\d\+-\d\+-\d\+') : ''
            let endymd = map(split(enddate, '-'), 'v:val + 0')
            if len(date) && len(ymd) == 3 && len(endymd) == 3
              let date = printf('%4d-%02d-%02d', ymd[0], ymd[1], ymd[2])
              if has_key(itm.end, 'date')
                let endymd = calendar#day#new(endymd[0], endymd[1], endymd[2]).add(-1).get_ymd()
              endif
              if !has_key(events, date)
                let events[date] = { 'events': [], 'hasHoliday': 0, 'hasMoon': 0, 'hasDayNum': 0, 'hasWeekNum': 0 }
              endif
              call add(events[date].events, extend(deepcopy(itm),
                    \ { 'calendarId': calendar.id
                    \ , 'calendarSummary': calendar.summary
                    \ , 'syntax': syn
                    \ , 'isHoliday': 0
                    \ , 'isMoon': 0
                    \ , 'isDayNum': 0
                    \ , 'isWeekNum': 0
                    \ , 'ymd': ymd
                    \ , 'endymd': endymd }))
            endif
          endif
        endfor
      endif
    endfor
    let holiday = self.get_holidays(a:year, a:month)
    for day in keys(holiday)
      if len(holiday[day].events)
        if !has_key(events, day)
          let events[day] = { 'events': [], 'hasHoliday': 0, 'hasMoon': 0, 'hasDayNum': 0, 'hasWeekNum': 0 }
        endif
        let events[day].hasHoliday = 1
        let events[day].holidayIndex = len(events[day].events)
        call extend(events[day].events, holiday[day].events)
      endif
    endfor
    return events
  endif
endfunction

function! s:self.clear_cache() dict
  let self._events = {}
  let self.__events = {}
  let self._holidays = {}
endfunction

function! s:self.get_events(year, month) dict
  let key = a:year . '-' . a:month
  if self._updated > 1
    let self._updated -= 1
  endif
  if has_key(self.__events, key) && (!calendar#setting#get('google_calendar') || get(g:, 'calendar_google_event_download', 1) <= 0) && !self._updated
    return self.__events[key]
  endif
  let events = self.get_events_one_month(a:year, a:month, 1)
  let [year, month] = calendar#day#new(a:year, a:month, 1).month().add(1).get_ym()
  call extend(events, self.get_events_one_month(year, month, 0))
  let [year, month] = calendar#day#new(a:year, a:month, 1).month().add(-1).get_ym()
  call extend(events, self.get_events_one_month(year, month, 0))
  let self.__events[key] = events
  return self.__events[key]
endfunction

function! s:self.get_holidays(year, month) dict
  let key = a:year . '-' . a:month
  if has_key(self._holidays, key) && (!calendar#setting#get('google_calendar') || get(g:, 'calendar_google_event_download', 1) <= 0)
    return self._holidays[key]
  endif
  let self._holidays[key] = calendar#google#calendar#getHolidays(a:year, a:month)
  return self._holidays[key]
endfunction

function! s:self.update(calendarId, eventId, title, year, month) dict
  if calendar#setting#get('google_calendar')
    call calendar#google#calendar#update(a:calendarId, a:eventId, a:title, a:year, a:month)
  else
    let calendarList = self.calendarList()
    for calendar in calendarList
      if calendar.id ==# a:calendarId
        let c = s:event_cache.new(calendar.id).new(printf('%04d', a:year)).new(printf('%02d', a:month)).get('0')
        let cnt = type(c) == type({}) && has_key(c, 'items') && type(c.items) == type([]) ? c : { 'items': [] }
        for i in range(len(cnt.items))
          if cnt.items[i].id ==# a:eventId
            let cnt.items[i].summary = a:title
            silent! call s:event_cache.new(calendar.id).new(printf('%04d', a:year)).new(printf('%02d', a:month)).save('0', cnt)
            let self._updated = 10
            return
          endif
        endfor
      endif
    endfor
  endif
endfunction

function! s:self.insert(calendarId, title, start, end, year, month) dict
  if calendar#setting#get('google_calendar')
    call calendar#google#calendar#insert(a:calendarId, a:title, a:start, a:end, a:year, a:month)
  else
    let calendarList = self.calendarList()
    for calendar in calendarList
      if calendar.id ==# a:calendarId
        let c = s:event_cache.new(calendar.id).new(printf('%04d', a:year)).new(printf('%02d', a:month)).get('0')
        let cnt = type(c) == type({}) && has_key(c, 'items') && type(c.items) == type([]) ? c : { 'items': [] }
        call add(cnt.items,
              \ { 'id': self.newid()
              \ , 'summary': a:title
              \ , 'start': a:start =~# 'T\d\+' ? { 'dateTime': a:start } : { 'date': a:start }
              \ , 'end': a:end =~# 'T\d\+' ? { 'dateTime': a:end } : { 'date': a:end }
              \ })
        silent! call s:event_cache.new(calendar.id).new(printf('%04d', a:year)).new(printf('%02d', a:month)).save('0', cnt)
        let self._updated = 10
        return
      endif
    endfor
  endif
endfunction

function! s:self.delete(calendarId, eventId, year, month) dict
  if calendar#setting#get('google_calendar')
    call calendar#google#calendar#delete(a:calendarId, a:eventId, a:year, a:month)
  else
    let calendarList = self.calendarList()
    for calendar in calendarList
      if calendar.id ==# a:calendarId
        let c = s:event_cache.new(calendar.id).new(printf('%04d', a:year)).new(printf('%02d', a:month)).get('0')
        let cnt = type(c) == type({}) && has_key(c, 'items') && type(c.items) == type([]) ? c : { 'items': [] }
        for i in range(len(cnt.items))
          if cnt.items[i].id ==# a:eventId
            call remove(cnt.items, i)
            silent! call s:event_cache.new(calendar.id).new(printf('%04d', a:year)).new(printf('%02d', a:month)).save('0', cnt)
            let self._updated = 10
            return
          endif
        endfor
      endif
    endfor
  endif
endfunction

function! s:self.calendarList() dict
  if calendar#setting#get('google_calendar')
    return calendar#google#calendar#getMyCalendarList()
  else
    if has_key(self, '_calendarList')
      return self._calendarList
    endif
    let self._calendarList = []
    let cnt = s:cache.get('calendarList')
    if type(cnt) == type({}) && has_key(cnt, 'items') && type(cnt.items) == type([])
      let self._calendarList = filter(cnt.items, 'has_key(v:val, "id") && has_key(v:val, "summary")')
    endif
    return self._calendarList
  endif
endfunction

function! s:self.createCalendar() dict
  if calendar#setting#get('google_calendar')
  else
    let cnt = s:cache.get('calendarList')
    if type(cnt) == type({}) && has_key(cnt, 'items') && type(cnt.items) == type([])
      let c = cnt
    else
      let c = { 'items': [] }
    endif
    redraw
    let calendarTitle = input(calendar#message#get('input_calendar_name'))
    if len(calendarTitle)
      let colors = []
      for itm in c.items
        if has_key(itm, 'backgroundColor')
          call add(colors, itm.backgroundColor)
        endif
      endfor
      let newcolors = filter(calendar#color#colors(), 'index(colors, v:val) >= 0')
      if len(newcolors) == 0
        let newcolors = calendar#color#colors()
      endif
      call add(c.items,
            \ { 'id': self.newid()
            \ , 'summary': calendarTitle
            \ , 'backgroundColor': newcolors[0]
            \ , 'foregroundColor': '#000000'
            \ })
      silent! call s:cache.save('calendarList', c)
      if has_key(self, '_calendarList')
        unlet! self._calendarList
      endif
    endif
  endif
endfunction

function! s:self.newid() dict
  let ymd = calendar#day#today().get_ymd()
  let hms = calendar#time#now().get_hms()
  let rnd = [calendar#random#number(1000000, 9000000) + 1000000]
  return join(ymd + hms + rnd, '_')
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
