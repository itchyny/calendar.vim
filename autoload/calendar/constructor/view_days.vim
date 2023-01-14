" =============================================================================
" Filename: autoload/calendar/constructor/view_days.vim
" Author: itchyny
" License: MIT License
" Last Change: 2023/01/14 18:35:10.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

function! calendar#constructor#view_days#new(instance) abort
  return extend({ 'instance': a:instance }, s:constructor)
endfunction

let s:constructor = {}

function! s:constructor.new(source) dict abort
  return extend(extend(s:super_constructor.new(a:source), s:instance), self.instance)
endfunction

let s:instance = {}

function! s:instance.height() dict abort
  return max([self.maxheight(), 6])
endfunction

function! s:instance.on_resize() dict abort
  let self.frame = copy(calendar#setting#frame())
  let width = strdisplaywidth(self.frame.vertical)
  let self.view = {}
  let self.view.width = (self.sizex() - width) / self.daynum / width * width
  let h = max([(self.sizey() - 3) / 6, 1])
  let self.view.week_count = 5
  let self.view.dayheight = h < 3 ? h : max([(self.sizey() - 3) / max([self.view.week_count, 5]), 1])
  let self.view.hourheight = max([(self.sizey() - self.view.dayheight) / 24, 3])
  let self.view.blockmin = 60 / (self.view.hourheight - 1)
  if !(self.view.width > 3 && self.view.dayheight > 1)
    let self.frame = calendar#setting#get('frame_space')
    let width = 1
    let self.view.width = (self.sizex() - width) / self.daynum
  endif
  let self.frame.width = strdisplaywidth(self.frame.vertical)
  let self.frame.strlen = len(self.frame.vertical)
  let self.element = {}
  let self.element.splitter = repeat(self.frame.horizontal, (self.view.width - width) / width)
  let self.element.white = repeat(' ', (self.view.width - width) / width * width)
  let self.element.vwhite = self.frame.vertical . self.element.white
  let self.element.format = '%2d' . repeat(' ', (self.view.width - width) / width * width - 2)
  let self.view.realwidth = self.view.width - width + self.frame.strlen
  let self.view.inner_width = self.view.width - width
  let self.view.offset = self.view.dayheight > 1 ? 3 : 1
  let self.view.locale = calendar#setting#get('locale')
  call self.set_day_name()
  let self._cache_key = []
endfunction

function! s:instance.width() dict abort
  let frame = calendar#setting#frame()
  let width = strdisplaywidth(frame.vertical)
  let w = max([(self.maxwidth() - calendar#setting#get('clock_12hour') * 7) / 8, 3])
  let hh = self.height()
  let h = max([(hh - 3) / 6, 1])
  let h = h < 3 ? h : max([(hh - 3) / calendar#week#week_count(b:calendar.month()), 1])
  if !(w > 3 && h > 1)
    let width = 1
  endif
  let daynum = self.daynum
  if daynum == 1
    let views = calendar#setting#get('views')
    let i = index(views, 'day_1')
    if i >= 0
      let days = filter([i > 0 ? views[i - 1] : '', i + 1 < len(views) ? views[i + 1] : ''], 'v:val =~# ''^day_\d$''')
      if len(days)
        let num = substitute(days[0], 'day_', '', '') + 0
        if 1 < num && num <= 7
          let daynum = num
        endif
      endif
    endif
  endif
  return w * 7 / daynum / width * width * daynum + width
endfunction

function! s:instance.get_min_day() dict abort
  let day = b:calendar.day()
  if has_key(self, 'min_day')
    if day.sub(self.min_day) < 0
      let self.min_day = day
    elseif day.sub(self.max_day) > 0
      let self.min_day = day.add(-self.daynum + 1)
    endif
  else
    let self.min_day = day
  endif
  let self.max_day = self.min_day.add(self.daynum - 1)
  return self.min_day
endfunction

function! s:instance.cache_key() dict abort
  if has_key(self, 'min_hour') && (self.min_hour < 0 || self.max_hour > 23)
    return []
  else
    return copy(self.min_max_hour()) + self.get_min_day().get_ymd() + [b:calendar.day().get_month()]
          \ + calendar#day#today().get_ymd() + [calendar#setting#get('frame'), calendar#setting#get('first_day')]
          \ + b:calendar.event.updated() + [get(g:, 'calendar_google_event_download')]
  endif
endfunction

function! s:instance.min_max_hour() dict abort
  let height = self.height() - self.view.offset - self.view.dayheight
  let heighthour = height / self.view.hourheight
  let time = b:calendar.time()
  let hour = time.hour()
  if has_key(self, 'min_hour')
    if hour < self.min_hour
      let min = hour
    elseif hour > self.max_hour
      let min = self.min_hour + hour - self.max_hour
    else
      let min = self.min_hour
    endif
  else
    let min = time.hour() - heighthour / 2 + 2
  endif
  let min = max([min, 0])
  let max = min([min + heighthour - 1, 23])
  let min = max([max - heighthour + 1, 0])
  let max = min([min + heighthour - 1, 23])
  return [min, max]
endfunction

function! s:instance.set_min_max_hour(hours) dict abort
  let [self.min_hour, self.max_hour] = a:hours
endfunction

function! s:instance.get_min_max_hour() dict abort
  return [self.min_hour, self.max_hour]
endfunction

function! s:instance.set_day_name() dict abort
  let [h, w, ww] = [self.view.dayheight, self.view.width, self.view.realwidth]
  let key = h . ',' . w . ',' . ww . ',' . calendar#setting#get('frame') . ','
        \ . calendar#setting#get('locale') . ',' . calendar#week#week_index(self.get_min_day()) . ',' . calendar#setting#get('first_day')
  if !has_key(self, 'day_name_cache')
    let self.day_name_cache = {}
  endif
  if has_key(self.day_name_cache, key)
    let [self.day_name_text, self.day_name_syntax] = self.day_name_cache[key]
    return
  endif
  let day_name = copy(calendar#message#get('day_name_long'))
  let maxlen = max(map(copy(day_name), 'strdisplaywidth(v:val)'))
  if maxlen >= self.view.inner_width
    let day_name = copy(calendar#message#get('day_name'))
  endif
  let s = repeat([''], 3)
  let syntax = []
  let x = self.frame.strlen
  let idx = self.get_min_day().week()
  for i in range(idx, idx + self.daynum - 1)
    if h > 1
      let s[0] .= (i > idx ? self.frame.top : self.frame.topleft) . self.element.splitter
      let s[2] .= (i > idx ? self.frame.junction : self.frame.left) . self.element.splitter
    endif
    let name = day_name[i % 7]
    let wid = strdisplaywidth(name)
    if wid >= self.view.inner_width
      let name = calendar#string#truncate(name, max([2, self.view.inner_width]))
      let wid = strdisplaywidth(name)
    endif
    let len = strdisplaywidth(self.element.splitter)
    let whiteleft = repeat(' ', (len - wid) / 2)
    let whiteright = repeat(' ', len - len(whiteleft) - wid)
    let weekstr = whiteleft . name . whiteright
    let s[h > 1] .= self.frame.vertical . weekstr
    let syn = i % 7 == 0 ? 'SundayTitle' : i % 7 == 6 ? 'SaturdayTitle' : 'DayTitle'
    if len(syntax)
      call add(syntax[-1].syn, [syn, h > 1, x, x + len(weekstr), 0])
    else
      call add(syntax, calendar#text#new(len(weekstr), x, h > 1, syn))
    endif
    let x += len(weekstr) + self.frame.strlen
  endfor
  if h > 1
    let s[0] .= self.frame.topright
    let s[1] .= self.frame.vertical
    let s[2] .= self.frame.right
  endif
  let self.day_name_text = s
  let self.day_name_syntax = syntax
  let self.day_name_cache[key] = [s, syntax]
endfunction

function! s:get_time_events(events, blockmin) abort
  let time_events = {}
  let timestrs_by_timestr = {}
  let i = 0
  for event in a:events
    if get(event, 'isTimeEvent') && (event.ymd == event.endymd ||
          \  (event.endhms == [0, 0, 0] &&
          \    calendar#day#new(event.endymd[0], event.endymd[1], event.endymd[2]).sub(
          \      calendar#day#new(event.ymd[0], event.ymd[1], event.ymd[2])) == 1))
      let hour = event.hms[0]
      let min = event.hms[1] / a:blockmin * a:blockmin
      let endhour = event.ymd == event.endymd ? event.endhms[0] : 24
      let endmin = event.endhms[1]
      let event_timestrs = []
      let adjacent_timestrs = {}
      while hour < endhour || hour == endhour && min < endmin
        let timestr = hour . ':' . min
        if !has_key(time_events, timestr)
          let time_events[timestr] = []
        endif
        call add(event_timestrs, timestr)
        let timestrs_by_timestr[timestr] = extend(adjacent_timestrs, get(timestrs_by_timestr, timestr, {(timestr): 0}))
        let min += a:blockmin
        if min >= 60
          let min = 0
          let hour += 1
        endif
      endwhile
      let index = max(map(keys(adjacent_timestrs), 'len(time_events[v:val])'))
      let event_count = index + 1
      for j in range(index)
        if len(filter(copy(event_timestrs), 'get(get(time_events[v:val], ' . j . ', []), 0, -1) >= 0')) == 0
          let index = j
          let event_count -= 1
          break
        endif
      endfor
      for timestr in event_timestrs
        let style = len(event_timestrs) == 1 ? 'single' : timestr ==# event_timestrs[0] ? 'top' : timestr ==# event_timestrs[-1] ? 'bottom' : 'middle'
        if index < len(time_events[timestr])
          let time_events[timestr][index] = [i, style, get(event, 'syntax', ''), 0]
        else
          while len(time_events[timestr]) < index
            call add(time_events[timestr], [-1, 'empty', '', 0])
          endwhile
          call add(time_events[timestr], [i, style, get(event, 'syntax', ''), 0])
        endif
      endfor
      for timestr in keys(adjacent_timestrs)
        for event in time_events[timestr]
          let event[3] = event_count
        endfor
      endfor
    endif
    let i += 1
  endfor
  return time_events
endfunction

function! s:instance.set_contents() dict abort
  if self.frame.type !=# calendar#setting#get('frame') | call self.on_resize() | endif
  call self.set_day_name()
  let [f, v, e] = [self.frame, self.view, self.element]
  let [h, w, ww] = [v.dayheight, v.width, v.realwidth]
  let height = self.height() - v.offset - h
  let bottompad = (self.height() - v.offset - h) % v.hourheight + 1
  let self.has_today = 0
  let hh = 1 <= h - 2 ? range(1, h - 2) : []
  let s = repeat([''], self.sizey())
  let today = calendar#day#today()
  let month = b:calendar.month()
  let day = b:calendar.day()
  let syntax = deepcopy(self.day_name_syntax)
  for i in range(len(self.day_name_text))
    let s[i] = self.day_name_text[i]
  endfor
  let [so, st, su, sa, tsu, tsa] = ['OtherMonth', 'Today', 'Sunday', 'Saturday', 'TodaySunday', 'TodaySaturday']
  let [i, j] = [0, 0]
  let days = month.get_days()
  let prev_days = month.add(-1).get_days()
  let next_days = month.add(1).get_days()
  let wn = calendar#week#week_index(days[0])
  let sub = day.sub(wn ? prev_days[-wn] : days[0])
  let wnum = sub / 7
  let ld = wn + len(days)
  let events = b:calendar.event.get_events(day.get_year(), day.get_month())
  let head = self.get_min_day().sub(wn ? prev_days[-wn] : days[0])
  let range = range(head, head + self.daynum - 1)
  let [self.min_hour, self.max_hour] = self.min_max_hour()
  let longevt = []
  let longtimeevt = []
  let self.timeevent_syntax = []
  let event_start_time = calendar#setting#get('event_start_time')
  let event_start_time_minwidth = calendar#setting#get('event_start_time_minwidth')
  let clock_12hour = calendar#setting#get('clock_12hour')
  for p in range
    let d = p < wn ? prev_days[-wn + p] : p < ld ? days[p - wn] : next_days[p - ld]
    let evts = get(events, join(d.get_ymd(), '-'), { 'events': [] } )
    let y = v.offset + h * j
    let s[y] .= f.vertical
    let s[y] .= self.oneday(d.get_day(), evts)
    let is_today = today.eq(d)
    if is_today
      let self.has_today = 1
    endif
    let syn = is_today ? st : d.is_sunday() || get(evts, 'hasHoliday') ? su : d.is_saturday() ? sa : ''
    if syn !=# ''
      let l = is_today ? len(calendar#string#truncate_reverse(s[y], v.inner_width)) : 2
      let syn2 = !is_today ? '' : d.is_sunday() || get(evts, 'hasHoliday') ? tsu : d.is_saturday() ? tsa : ''
      let x = len(calendar#string#truncate(s[y], w * i + f.width))
      if syn2 !=# ''
        let x += 2
        let l -= 2
      endif
      call add(syntax, calendar#text#new(l, x, y, syn))
      if syn2 !=# ''
        let l = 2
        let x = len(calendar#string#truncate(s[y], w * i + f.width))
        if len(syntax) && syntax[-1].y == y
          call add(syntax[-1].syn, [syn2, y, x, x + l, 0])
        else
          call add(syntax, calendar#text#new(l, x, y, syn2))
        endif
      endif
    endif
    let z = 0
    let longevtIndex = 0
    for x in hh
      if longevtIndex < len(longevt) && longevt[longevtIndex].viewoffset == x
        let lastday = d.get_day() == longevt[longevtIndex].endymd[2] ||
              \ (get(longevt[longevtIndex], 'isTimeEvent') &&
              \  longevt[longevtIndex].endhms == [0, 0, 0] &&
              \  calendar#day#new(longevt[longevtIndex].endymd[0], longevt[longevtIndex].endymd[1], longevt[longevtIndex].endymd[2]).sub(d) == 1
              \ )
        let eventtext = repeat('=', v.inner_width - lastday) . (lastday ? ']' : '')
        let splitter = i ? repeat('=', f.width) : f.vertical
        let s[y + x] .= splitter . eventtext
        if has_key(longevt[longevtIndex], 'syntax')
          let l = len(eventtext)
          let syn = longevt[longevtIndex].syntax
          let yy = y + x
          let xx = len(s[y + x]) - l - (i ? f.width : 0)
          let l = l + (i ? f.width : 0)
          call add(syntax, calendar#text#new(l, xx, yy, syn))
        endif
        let longevtIndex += 1
      else
        while z < len(evts.events) && (!has_key(evts.events[z], 'summary') || evts.events[z].isHoliday || evts.events[z].isMoon || evts.events[z].isDayNum || evts.events[z].isWeekNum)
          let z += 1
        endwhile
        if z < len(evts.events)
          let is_long_event = evts.events[z].ymd != evts.events[z].endymd &&
                \ (!get(evts.events[z], 'isTimeEvent') ||
                \   evts.events[z].endhms != [0, 0, 0] ||
                \   calendar#day#new(evts.events[z].endymd[0], evts.events[z].endymd[1], evts.events[z].endymd[2]).sub(
                \     calendar#day#new(evts.events[z].ymd[0], evts.events[z].ymd[1], evts.events[z].ymd[2])
                \   ) > 1
                \ )
          if is_long_event
            let trailing = ' ' . repeat('=', v.inner_width)
            call add(longevt, extend(evts.events[z], { 'viewoffset': x }))
          else
            let trailing = ''
          endif
          let starttime = event_start_time && self.view.width >= event_start_time_minwidth
                \ && get(evts.events[z], 'isTimeEvent') ? evts.events[z].starttime . ' ' : ''
          let eventtext = calendar#string#truncate(starttime . evts.events[z].summary . trailing, v.inner_width)
          if has_key(evts.events[z], 'syntax')
            let l = len(eventtext)
            let xx = len(s[y + x]) + len(f.vertical)
            let yy = y + x
            call add(syntax, calendar#text#new(l, xx, yy, evts.events[z].syntax))
          endif
          let s[y + x] .= f.vertical . eventtext
          let z += 1
        else
          let s[y + x] .= e.vwhite
        endif
      endif
    endfor
    call sort(filter(longevt, 'calendar#view#month#longevt_filter(v:val, d)'), 'calendar#view#month#sorter')
    let time_events = s:get_time_events(evts.events, v.blockmin)
    for k in range(height)
      if k < height - bottompad
        if (k + 1) % v.hourheight
          let hour = self.min_hour + k / v.hourheight
          let min = (k % v.hourheight) * v.blockmin
          let timestr = hour . ':' . min
          if has_key(time_events, timestr) && len(time_events[timestr])
            let event_count = time_events[timestr][0][3]
            let tevts = map(copy(time_events[timestr]), 'v:val[0] >= 0 ? evts.events[v:val[0]] : {}')
            let onelen = max([(v.inner_width + 2) / event_count - f.width, f.width * 3])
            let hourcontents = ''
            let texts = []
            let syns = []
            let totallen = 0
            let yy = v.offset + h + k
            let ya = yy - 1
            let framelen = v.inner_width / f.width * f.strlen
            let xx = len(s[ya]) - framelen
            for ii in range(len(tevts))
              let l = event_count > 1 ? (max([0, min([onelen, v.inner_width - totallen])]) - 1) / f.width * f.width : v.inner_width
              if l >= f.width * 2
                let style = time_events[timestr][ii][1]
                if style ==# 'top' || style ==# 'single'
                  let eventsummary = get(tevts[ii], 'summary', '')
                  let smallspace = repeat(' ', f.width - 1 - (strdisplaywidth(eventsummary) + f.width - 1) % f.width)
                  call add(texts, calendar#string#truncate(eventsummary . smallspace . repeat(f.horizontal, l), l - f.width) . (style ==# 'top' ? f.topright : f.horizontal))
                  let xx += l / f.width * f.strlen + f.strlen
                else
                  let border = style ==# 'empty' ? repeat(repeat(' ', f.width), 2) : style ==# 'middle' ? repeat([f.vertical], 2) : [f.bottomleft, f.bottomright]
                  call add(texts, border[0] . repeat(style =~# 'empty\|middle' ? repeat(' ', f.width) : f.horizontal, l / f.width - 2) . border[1])
                  if style ==# 'empty'
                    let xx += l / f.width * f.strlen + f.strlen
                  else
                    if (k % v.hourheight) == 0 && k
                      let cutlen = len(s[ya][(xx):])
                      let leftpart = s[ya][:len(s[ya]) - cutlen - 1]
                      let rightpart = s[ya][len(s[ya]) - cutlen + l / f.width * f.strlen :]
                      let s[ya] = leftpart . f.vertical . repeat(' ', l - f.width * 2) . f.vertical . rightpart
                      call add(syntax, calendar#text#new(l - f.width * 2 + f.strlen * 2, xx, ya, get(tevts[ii], 'syntax', '')))
                      let xx += l - 2 * f.width + 2 * f.strlen + f.strlen
                    endif
                  endif
                endif
                call add(syns, get(tevts[ii], 'syntax', ''))
                let totallen += onelen
              else
                let xx += l / f.width * f.strlen + f.strlen
              endif
            endfor
            let xx = len(s[yy]) + f.strlen
            let hourcontents = calendar#string#truncate(join(texts, repeat(' ', f.width)), v.inner_width)
            for ii in range(len(texts))
              let l = len(texts[ii])
              if len(syns[ii])
                call extend(time_events[timestr][ii], [l, xx, yy, syns[ii]])
                call add(syntax, calendar#text#new(l, xx, yy, syns[ii]))
              endif
              let xx += l + f.width
            endfor
          else
            let hourcontents = e.white
          endif
          let s[v.offset + h + k] .= repeat(f.vertical . hourcontents, 1)
        else
          let s[v.offset + h + k] .= repeat(f.vertical . e.splitter, 1)
        endif
      endif
    endfor
    call add(self.timeevent_syntax, copy(time_events))
    if h > 1
      let frame = i ? (j + 1 == 7 ? f.bottom : f.junction) : j + 1 == 7 ? f.bottomleft : f.left
      let s[y + h - 1] .= frame . e.splitter
    endif
    if i == 6
      let [i, j] = [0, j + 1]
    else
      let i = i + 1
    endif
  endfor
  for i in range(1)
    for j in range(h - 1)
      let s[v.offset + h * i + j] .= f.vertical
    endfor
    let s[v.offset + h * i + h - 1] .= (i + 1 == 7 ? f.bottomright : f.right)
  endfor
  let s[self.height() - bottompad] .= f.bottomleft . repeat(e.splitter . f.bottom, self.daynum - 1) . e.splitter . f.bottomright
  for j in range(height)
    if j < height - bottompad
      let s[v.offset + h + j] .= f.vertical
    endif
    if !((j + 1) % v.hourheight)
      let hour = self.min_hour + j / v.hourheight + 1
      if clock_12hour
        let postfix = hour < 12 || hour == 24 ? ' a.m.' : ' p.m.'
        let hour = calendar#time#hour12(hour)
      else
        let postfix = ''
      endif
      let s[v.offset + h + j] .= printf('%2d:%02d', hour, 0) . postfix
    endif
    if !j
      let hour = self.min_hour
      if clock_12hour
        let postfix = ' a.m.'
        let hour = calendar#time#hour12(hour)
      else
        let postfix = ''
      endif
      let s[v.offset + h - 1] .= printf('%2d:%02d', hour, 0) . postfix
    endif
  endfor
  let self._cache_key = self.cache_key()
  let self.days = map(range(len(s)), 'calendar#text#new(s[v:val], 0, v:val, "")')
  let self.syntax = syntax
  let self.min_day = self.get_min_day()
endfunction

function! s:instance.contents() dict abort
  if self._cache_key != self.cache_key() | call self.set_contents() | endif
  let [f, v, e] = [self.frame, self.view, self.element]
  let select = []
  let select_over = []
  let cursor = []
  let now = calendar#time#now()
  if self.is_selected()
    for [i, hour] in self.select_index()
      for h in range(v.hourheight - 1)
        let y = v.offset + v.dayheight + v.hourheight * (hour - self.min_hour) + h
        let x = len(calendar#string#truncate(self.days[y].s, v.width * i + f.width))
        let z = len(calendar#string#truncate(self.days[y].s, v.width * (i + 1)))
        let timestr = hour . ':' . (v.blockmin * h)
        if has_key(self.timeevent_syntax[i], timestr)
          for time_event in self.timeevent_syntax[i][timestr]
            if len(time_event) == 8
              call add(select_over, calendar#text#new(time_event[4], time_event[5], time_event[6], time_event[7] . 'Select'))
            endif
          endfor
        endif
        call add(select, calendar#text#new(z - x, x, y, 'Select'))
      endfor
    endfor
    let y = v.offset + v.dayheight + v.hourheight * (hour - self.min_hour)
    let x = len(calendar#string#truncate(self.days[y].s, v.width * i + f.width))
    let cursor = [calendar#text#new(0, x, y, 'Cursor')]
  endif
  if self.has_today
    let i = calendar#day#today().sub(self.get_min_day())
    let h = now.minute()/ (60 / (self.view.hourheight - 1))
    if self.min_hour <= now.hour() && now.hour() <= self.max_hour
      let y = v.offset + v.dayheight + v.hourheight * (now.hour() - self.min_hour) + h
      let x = len(calendar#string#truncate(self.days[y].s, v.width * i + f.width))
      let z = len(calendar#string#truncate(self.days[y].s, v.width * (i + 1)))
      let nowsyn = [calendar#text#new(z - x, x, y, 'Today')]
    else
      let nowsyn = []
    endif
  else
    let nowsyn = []
  endif
  return deepcopy(self.days) + select + deepcopy(self.syntax) + select_over + cursor + nowsyn
endfunction

function! s:instance.select_index() dict abort
  let lasti = b:calendar.day().sub(self.get_min_day())
  let lasthour = b:calendar.time().hour()
  if !b:calendar.visual_mode()
    return [[lasti, lasthour]]
  endif
  let last = lasti * 24 + lasthour
  let starti = b:calendar.visual_start_day().sub(self.get_min_day())
  let starthour = b:calendar.visual_start_time().hour()
  let start = starti * 24 + starthour
  let ret = []
  if b:calendar.is_visual()
    for i in range(min([start, last]), max([start, last]))
      let j = s:div(i, 24)
      let k = i - j * 24
      if [j, k] != [lasti, lasthour] && 0 <= j && j < self.daynum && self.min_hour <= k && k <= self.max_hour
        call add(ret, [j, k])
      endif
    endfor
  elseif b:calendar.is_line_visual()
    for j in range(min([starti, lasti]), max([starti, lasti]))
      for k in range(24)
        if [j, k] != [lasti, lasthour] && 0 <= j && j < self.daynum && self.min_hour <= k && k <= self.max_hour
          call add(ret, [j, k])
        endif
      endfor
    endfor
  elseif b:calendar.is_block_visual()
    for j in range(min([starti, lasti]), max([starti, lasti]))
      for k in range(min([starthour, lasthour]), max([starthour, lasthour]))
        if [j, k] != [lasti, lasthour] && 0 <= j && j < self.daynum && self.min_hour <= k && k <= self.max_hour
          call add(ret, [j, k])
        endif
      endfor
    endfor
  else
  endif
  call add(ret, [lasti, lasthour])
  return ret
endfunction

function! s:div(x, y) abort
  return a:x/a:y-((a:x<0)&&(a:x%a:y))
endfunction

function! s:instance.timerange() dict abort
  let hour = b:calendar.time().hour()
  if !b:calendar.visual_mode()
    return printf('%d:00-%d:00 ', hour, hour + 1)
  endif
  let x = b:calendar.day()
  let xh = b:calendar.time().hour()
  let y = b:calendar.visual_start_day()
  let yh = b:calendar.visual_start_time().hour()
  let recurrence = ''
  if x.sub(y) > 0 || x.eq(y) && xh > yh
    let [x, xh, y, yh] = [y, yh, x, xh]
  endif
  if b:calendar.is_line_visual()
    return calendar#day#join_date_range(x, y) . ' '
  elseif b:calendar.is_block_visual()
    let recday = y.sub(x) + 1
    let recurrence = recday > 1 ? recday . 'days ' : ''
    let y = x
    if xh > yh
      let [xh, yh] = [yh, xh]
    endif
  endif
  if x.eq(y) && recurrence ==# ''
    return printf('%d:00 - %d:00 ', xh, yh + 1)
  elseif x.get_year() == y.get_year()
    return printf('%s %d:00 - %s %d:00 %s',
          \ calendar#day#join_date([x.get_month(), x.get_day()]), xh,
          \ calendar#day#join_date([y.get_month(), y.get_day()]), yh + 1,
          \ recurrence)
  else
    return printf('%s %d:00 - %s %d:00 %s',
          \ calendar#day#join_date([x.get_year(), x.get_month(), x.get_day()]), xh,
          \ calendar#day#join_date([y.get_year(), y.get_month(), y.get_day()]), yh + 1,
          \ recurrence)
  endif
endfunction

function! s:instance.action(action) dict abort
  let d = b:calendar.day()
  let hday = b:calendar.month().head_day()
  let lday = b:calendar.month().last_day()
  let hour = b:calendar.time().hour()
  let wnum = d.sub(self.get_min_day())
  if a:action ==# 'left'
    call b:calendar.move_day(get(self, 'stopend') ? max([-v:count1, -wnum]) : -v:count1)
  elseif a:action ==# 'right'
    call b:calendar.move_day(get(self, 'stopend') ? min([v:count1, -wnum + self.daynum - 1]) : v:count1)
  elseif index(['prev', 'next', 'space', 'add', 'subtract'], a:action) >= 0
    call b:calendar.move_day(v:count1 * (index(['prev', 'subtract'], a:action) >= 0 ? -1 : 1))
  elseif index(['down', 'up'], a:action) >= 0
    call b:calendar.move_hour(v:count1 * (a:action ==# 'down' ? 1 : -1))
  elseif index(['plus', 'minus'], a:action) >= 0
    let h = v:count1 * (a:action ==# 'plus' ? 1 : -1)
    while h > 23 - hour
      let h = h - 24
      let wnum -= self.daynum
    endwhile
    while h < - hour
      let h = h + 24
      let wnum += self.daynum
    endwhile
    call b:calendar.move_hour(h)
    if has_key(self, 'min_day') && has_key(self, 'max_day')
      if self.min_day.sub(d.add(-wnum)) > 0 || self.max_day.sub(d.add(-wnum)) < 0
        let self.min_day = self.min_day.add(s:div(-wnum + self.daynum - 1, self.daynum) * self.daynum)
        let self.max_day = self.max_day.add(s:div(-wnum + self.daynum - 1, self.daynum) * self.daynum)
      endif
    endif
    call b:calendar.move_day(-wnum)
  elseif index(['down_big', 'up_big'], a:action) >= 0
    let diff = self.max_hour - self.min_hour
    let dir = a:action ==# 'down_big' ? 1 : -1
    let di = max([min([v:count1 * dir * diff * 2 / 3, 23 - hour]), - hour])
    if dir > 0
      let self.min_hour = self.min_hour + v:count1 * dir * diff
      let self.max_hour = self.min_hour + diff
    else
      let self.max_hour = self.max_hour + v:count1 * dir * diff
      let self.min_hour = self.max_hour - diff
    endif
    call b:calendar.move_hour(di)
  elseif index(['down_large', 'up_large'], a:action) >= 0
    let diff = self.max_hour - self.min_hour
    let dir = a:action ==# 'down_large' ? 1 : -1
    let di = max([min([(dir > 0 ? self.max_hour : self.min_hour) - hour + (v:count1 - 1) * dir * diff, 23 - hour]), - hour])
    if dir > 0
      let self.min_hour = self.min_hour + v:count1 * dir * diff
      let self.max_hour = self.min_hour + diff
    else
      let self.max_hour = self.max_hour + v:count1 * dir * diff
      let self.min_hour = self.max_hour - diff
    endif
    call b:calendar.move_hour(di)
  elseif a:action ==# 'line_head'
    call b:calendar.move_day(-wnum)
  elseif a:action ==# 'line_middle'
    call b:calendar.move_day(-wnum + (self.daynum - 1) / 2)
  elseif a:action ==# 'line_last'
    call b:calendar.move_day(self.daynum - 1 - wnum)
  elseif a:action ==# 'bar'
    call b:calendar.move_day(-wnum + min([v:count1 - 1, self.daynum - 1]))
  elseif a:action ==# 'first_line' || a:action ==# 'first_line_head' || (a:action ==# 'last_line' && v:count)
    call b:calendar.move_hour((v:count ? min([v:count1, 23]) : 0) - hour)
  elseif a:action ==# 'last_line'
    call b:calendar.move_hour((v:count ? max([v:count1, 23]) : 23) - hour)
  elseif a:action ==# 'last_line_last'
    call b:calendar.move_hour((v:count ? max([v:count1, 23]) : 23) - hour)
  elseif index(['scroll_down', 'scroll_up'], a:action) >= 0
    let diff = v:count1 * (a:action =~# 'down' ? 1 : -1)
    let old_hours = [self.min_hour, self.max_hour]
    let self.min_hour += diff
    let self.max_hour += diff
    let new_hours = self.min_max_hour()
    if old_hours == new_hours
      call b:calendar.move_hour(diff)
    endif
  elseif index(['scroll_top_head', 'scroll_top', 'scroll_bottom_head', 'scroll_bottom'], a:action) >= 0
    let self.min_hour += 23 * (a:action =~# 'top' ? 1 : -1)
    let self.max_hour += 23 * (a:action =~# 'top' ? 1 : -1)
    call b:calendar.move_day(a:action =~# 'head' ? -wnum : 0)
  elseif index(['scroll_center_head', 'scroll_center'], a:action) >= 0
    let diff = self.max_hour - self.min_hour
    let self.min_hour = hour - diff / 2 + 1
    let self.max_hour = self.min_hour + diff
    call b:calendar.move_day(a:action =~# 'head' ? -wnum : 0)
  elseif a:action ==# 'command_enter' && mode() ==# 'c' && getcmdtype() ==# ':'
    let cmd = calendar#util#getcmdline()
    if cmd =~# '^\s*\d\+\s*$'
      let c = max([min([matchstr(cmd, '\d\+') * 1, 23]), 0])
      call b:calendar.move_hour(c - hour)
      return calendar#util#update_keys()
    endif
  endif
endfunction

let s:super_constructor = calendar#constructor#view#new(s:instance)

let &cpo = s:save_cpo
unlet s:save_cpo
