" =============================================================================
" Filename: autoload/calendar/event/local.vim
" Author: itchyny
" License: MIT License
" Last Change: 2014/12/03 13:53:47.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

function! calendar#event#local#new()
  return deepcopy(s:self)
endfunction

let s:cache = calendar#cache#new('local')

let s:event_cache = s:cache.new('event')

let s:self = {}
let s:self._key = {}
let s:self._events = {}

function! s:self.get_events_one_month(year, month, ...) dict
  let events = {}
  let calendarList = self.calendarList()
  let [y, m] = [printf('%04d', a:year), printf('%02d', a:month)]
  for calendar in calendarList
    let syn = calendar#color#new_syntax(get(calendar, 'id', ''), get(calendar, 'foregroundColor', ''), get(calendar, 'backgroundColor'))
    unlet! c
    let c = s:event_cache.new(calendar.id).new(y).new(m).get('0')
    if type(c) == type({}) && has_key(c, 'items') && type(c.items) == type([])
      for itm in c.items
        if has_key(itm, 'start') && (has_key(itm.start, 'date') || has_key(itm.start, 'dateTime'))
              \ && has_key(itm, 'end') && (has_key(itm.end, 'date') || has_key(itm.end, 'dateTime'))
          let date = has_key(itm.start, 'date') ? itm.start.date : has_key(itm.start, 'dateTime') ? matchstr(itm.start.dateTime, '\d\+-\d\+-\d\+') : ''
          let ymd = map(split(date, '-'), 'v:val + 0')
          let enddate = has_key(itm.end, 'date') ? itm.end.date : has_key(itm.end, 'dateTime') ? matchstr(itm.end.dateTime, '\d\+-\d\+-\d\+') : ''
          let endymd = map(split(enddate, '-'), 'v:val + 0')
          if date !=# '' && len(ymd) == 3 && len(endymd) == 3
            let date = join(ymd, '-')
            if has_key(itm.end, 'date')
              let endymd = ymd == [endymd[0], endymd[1], endymd[2] - 1] ? ymd : calendar#day#new(endymd[0], endymd[1], endymd[2]).add(-1).get_ymd()
            endif
            if !has_key(events, date)
              let events[date] = { 'events': [] }
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
  return events
endfunction

function! s:self.update(calendarId, eventId, title, year, month, ...) dict
  let calendarList = self.calendarList()
  let [y, m] = [printf('%04d', a:year), printf('%02d', a:month)]
  for calendar in calendarList
    if calendar.id ==# a:calendarId
      let c = s:event_cache.new(calendar.id).new(y).new(m).get('0')
      let cnt = type(c) == type({}) && has_key(c, 'items') && type(c.items) == type([]) ? c : { 'items': [] }
      for i in range(len(cnt.items))
        if cnt.items[i].id ==# a:eventId
          let cnt.items[i].summary = a:title
          call extend(cnt.items[i], a:0 ? a:1 : {})
          silent! call s:event_cache.new(calendar.id).new(y).new(m).save('0', cnt)
          return
        endif
      endfor
    endif
  endfor
endfunction

function! s:self.insert(calendarId, title, start, end, year, month, ...) dict
  let calendarList = self.calendarList()
  let [y, m] = [printf('%04d', a:year), printf('%02d', a:month)]
  if a:start =~# '^\d\+[-/]\d\+[-/]\d\+'
    let ymd = map(split(matchstr(a:start, '^\d\+[-/]\d\+[-/]\d\+'), '[-/]'), 'v:val + 0')
    let [y, m] = [printf('%04d', ymd[0]), printf('%02d', ymd[1])]
  elseif a:start =~# '^\d\+[-/]\d\+'
    let md = map(split(matchstr(a:start, '^\d\+[-/]\d\+'), '[-/]'), 'v:val + 0')
    let m = printf('%04d', md[0])
  endif
  for calendar in calendarList
    if calendar.id ==# a:calendarId
      let c = s:event_cache.new(calendar.id).new(y).new(m).get('0')
      let cnt = type(c) == type({}) && has_key(c, 'items') && type(c.items) == type([]) ? c : { 'items': [] }
      call add(cnt.items,
            \ { 'id': calendar#util#id()
            \ , 'summary': a:title
            \ , 'start': a:start =~# 'T\d\+' ? { 'dateTime': a:start } : { 'date': a:start }
            \ , 'end': a:end =~# 'T\d\+' ? { 'dateTime': a:end } : { 'date': a:end }
            \ })
      silent! call s:event_cache.new(calendar.id).new(y).new(m).save('0', cnt)
      return
    endif
  endfor
endfunction

function! s:self.delete(calendarId, eventId, year, month) dict
  let calendarList = self.calendarList()
  let [y, m] = [printf('%04d', a:year), printf('%02d', a:month)]
  for calendar in calendarList
    if calendar.id ==# a:calendarId
      let c = s:event_cache.new(calendar.id).new(y).new(m).get('0')
      let cnt = type(c) == type({}) && has_key(c, 'items') && type(c.items) == type([]) ? c : { 'items': [] }
      for i in range(len(cnt.items))
        if cnt.items[i].id ==# a:eventId
          call remove(cnt.items, i)
          silent! call s:event_cache.new(calendar.id).new(y).new(m).save('0', cnt)
          return
        endif
      endfor
    endif
  endfor
endfunction

function! s:self.calendarList() dict
  if has_key(self, '_calendarList')
    return self._calendarList
  endif
  let self._calendarList = []
  let cnt = s:cache.get('calendarList')
  if type(cnt) == type({}) && has_key(cnt, 'items') && type(cnt.items) == type([])
    let self._calendarList = filter(cnt.items, 'has_key(v:val, "id") && has_key(v:val, "summary")')
  endif
  return self._calendarList
endfunction

function! s:self.createCalendar() dict
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
          \ { 'id': calendar#util#id()
          \ , 'summary': calendarTitle
          \ , 'backgroundColor': newcolors[0]
          \ , 'foregroundColor': '#000000'
          \ })
    silent! call s:cache.save('calendarList', c)
    if has_key(self, '_calendarList')
      unlet! self._calendarList
    endif
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
