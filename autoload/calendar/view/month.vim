" =============================================================================
" Filename: autoload/calendar/view/month.vim
" Author: itchyny
" License: MIT License
" Last Change: 2014/01/07 10:06:22.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

function! calendar#view#month#new(source)
  return s:constructor.new(a:source)
endfunction

let s:self = {}

function! s:self.width() dict
  let frame = calendar#setting#frame()
  let width = calendar#string#strdisplaywidth(frame.vertical)
  let w = max([self.maxwidth() / 8, 3])
  let hh = self.height()
  let h = max([(hh - 3) / 6, 1])
  let h = h < 3 ? h : max([(hh - 3) / calendar#week#week_count(b:calendar.month()), 1])
  if !(w > 3 && h > 1)
    let width = 1
  endif
  return w / width * width * 7 + width
endfunction

function! s:self.height() dict
  return max([self.maxheight(), 6])
endfunction

function! s:self.on_resize() dict
  let self.frame = copy(calendar#setting#frame())
  let self.view = {}
  let self.view.width = self.sizex() / 7
  let h = max([(self.sizey() - 3) / 6, 1])
  let self.view.week_count = calendar#week#week_count(b:calendar.month())
  let self.view.height = h < 3 ? h : max([(self.sizey() - 3) / max([self.view.week_count, 5]), 1])
  if !(self.view.width > 3 && self.view.height > 1)
    let self.frame = calendar#setting#get('frame_space')
  endif
  let self.frame.width = calendar#string#strdisplaywidth(self.frame.vertical)
  let self.frame.strlen = len(self.frame.vertical)
  let self.element = {}
  let self.element.splitter = repeat(self.frame.horizontal, (self.view.width - self.frame.width) / self.frame.width)
  let self.element.white = repeat(' ', self.view.width - self.frame.width)
  let self.element.vwhite = self.frame.vertical . self.element.white
  let self.element.format = '%2d' . repeat(' ', self.view.width - 2 - self.frame.width)
  let self.view.realwidth = self.view.width - self.frame.width + self.frame.strlen
  let self.view.inner_width = self.view.width - self.frame.width
  let self.view.offset = self.view.height > 1 ? 3 : 1
  let self.view.locale = calendar#setting#get('locale')
  call self.set_day_name()
  let self._month = [0, 0]
  let self._today = [0, 0, 0]
endfunction

function! s:self.set_day_name() dict
  let [h, w, ww] = [self.view.height, self.view.width, self.view.realwidth]
  let key = h . ',' . w . ',' . ww . ',' . calendar#setting#get('frame') . ',' . calendar#setting#get('locale') . ',' . calendar#setting#get('first_day')
  if !has_key(self, 'day_name_cache')
    let self.day_name_cache = {}
  endif
  if has_key(self.day_name_cache, key)
    let [self.day_name_text, self.day_name_syntax] = self.day_name_cache[key]
    return
  endif
  let day_name = copy(calendar#message#get('day_name_long'))
  let maxlen = max(map(copy(day_name), 'calendar#string#strdisplaywidth(v:val)'))
  if maxlen >= self.view.inner_width
    let day_name = copy(calendar#message#get('day_name'))
  endif
  let s = repeat([''], 3)
  let syntax = []
  let x = self.frame.strlen
  let idx = calendar#week#first_day_index()
  for i in range(idx, idx + 6)
    if h > 1
      let s[0] .= (i > idx ? self.frame.top : self.frame.topleft) . self.element.splitter
      let s[2] .= (i > idx ? self.frame.junction : self.frame.left) . self.element.splitter
    endif
    let name = day_name[i % 7]
    let wid = calendar#string#strdisplaywidth(name)
    if wid >= self.view.inner_width
      let name = calendar#string#truncate(name, max([2, self.view.inner_width]))
      let wid = calendar#string#strdisplaywidth(name)
    endif
    let len = calendar#string#strdisplaywidth(self.element.splitter)
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

function! s:self.add_syntax(x, y, l, syn, ...) dict
  if has_key(self.syntax_index, a:y)
    call add(self.syntax[self.syntax_index[a:y]].syn, [a:syn, a:y, a:x, a:x + a:l, 0])
  else
    let self.syntax_index[a:y] = len(self.syntax)
    call add(self.syntax, calendar#text#new(a:l, a:x, a:y, a:syn))
  endif
  if a:0 && len(a:1)
    if !has_key(self.syntax_name, a:1)
      let self.syntax_name[a:1] = {}
    endif
    let self.syntax_name[a:1][a:y] = a:syn
  endif
endfunction

function! s:self.set_contents() dict
  if self.view.week_count != calendar#week#week_count(b:calendar.month()) || self.frame.type !=# calendar#setting#get('frame') | call self.on_resize() | endif
  call self.set_day_name()
  let [f, v, e] = [self.frame, self.view, self.element]
  let [h, w, ww] = [v.height, v.width, v.realwidth]
  let hh = 1 <= h - 2 ? range(1, h - 2) : []
  let s = repeat([''], self.sizey())
  let today = calendar#day#today()
  let month = b:calendar.month()
  let day = b:calendar.day()
  let self.syntax = deepcopy(self.day_name_syntax)
  let self.syntax_index = {}
  for i in range(len(self.day_name_text))
    let s[i] = self.day_name_text[i]
  endfor
  let [so, st, su, sa, tsu, tsa] = ['OtherMonth', 'Today', 'Sunday', 'Saturday', 'TodaySunday', 'TodaySaturday']
  let [i, j] = [0, 0]
  let days = month.get_days()
  let prev_days = calendar#week#is_first_day(days[0]) ? [] : month.add(-1).get_days()
  let next_days = calendar#week#is_last_day(days[-1]) ? [] : month.add(1).get_days()
  let wn = calendar#week#week_number(days[0])
  let ld = wn + len(days)
  let events = b:calendar.event.get_events(day.get_year(), day.get_month())
  let longevt = []
  let self.syntax_name = {}
  for p in range(v.week_count * 7)
    let d = p < wn ? prev_days[-wn + p] : p < ld ? days[p - wn] : next_days[p - ld]
    let othermonth = p < wn || ld <= p
    let evts = get(events, printf('%d-%02d-%02d', d.get_year(), d.get_month(), d.get_day()), { 'events': [] } )
    let y = v.offset + h * j
    if get(evts, 'hasHoliday')
      let s[y] .= f.vertical . calendar#string#truncate(printf('%2d ', d.get_day()) . evts.events[evts.holidayIndex].summary, v.inner_width)
    else
      let s[y] .= f.vertical . printf(e.format, d.get_day())
    endif
    let right = get(evts, 'hasDayNum') ? evts.events[evts.daynumIndex].daynum : ''
    if get(evts, 'hasWeekNum') && w > len(right) + 6 + f.width
      let right = evts.events[evts.weeknumIndex].weeknum . (len(right) ? ' ' : '') . right
    endif
    if get(evts, 'hasMoon') && w > len(right) + 5 + f.width
      let right = evts.events[evts.moonIndex].moon . right
    endif
    if w > len(right) + 3 + f.width && len(right)
      let cut = calendar#string#truncate_reverse(s[y], calendar#string#strdisplaywidth(right) + 1)
      let s[y] = s[y][:-len(cut)-1] . ' ' . right
    endif
    let is_today = today.eq(d)
    let syn = othermonth ? so : is_today ? st : d.is_sunday() || get(evts, 'hasHoliday') ? su : d.is_saturday() ? sa : ''
    if len(syn)
      let l = is_today || othermonth ? len(calendar#string#truncate_reverse(s[y], v.inner_width)) : 2
      let syn2 = !is_today ? '' : d.is_sunday() || get(evts, 'hasHoliday') ? tsu : d.is_saturday() ? tsa : ''
      let x = len(calendar#string#truncate(s[y], w * i + f.width))
      if len(syn2)
        let x += 2
        let l -= 2
      endif
      call self.add_syntax(x, y, l, syn)
      if len(syn2)
        let l = 2
        let x = len(calendar#string#truncate(s[y], w * i + f.width))
        call self.add_syntax(x, y, l, syn2)
      endif
    endif
    let z = 0
    let longevtIndex = 0
    for x in hh
      if longevtIndex < len(longevt) && longevt[longevtIndex].viewoffset == x
        let lastday = d.get_day() == longevt[longevtIndex].endymd[2]
        let eventtext = repeat('=', v.inner_width - lastday) . (lastday ? ']' : '')
        let splitter = i ? repeat('=', f.width) : f.vertical
        let s[y + x] .= splitter . eventtext
        let l = len(eventtext) + (i ? f.width : 0)
        let xx = len(s[y + x]) - l
        let yy = y + x
        if othermonth
          call self.add_syntax(xx, yy, l, so)
        elseif has_key(longevt[longevtIndex], 'syntax')
          call self.add_syntax(xx, yy, l, longevt[longevtIndex].syntax, i . ',' . j)
        endif
        let longevtIndex += 1
      else
        while z < len(evts.events) && (!has_key(evts.events[z], 'summary') || evts.events[z].isHoliday || evts.events[z].isMoon || evts.events[z].isDayNum || evts.events[z].isWeekNum)
          let z += 1
        endwhile
        if z < len(evts.events)
          if evts.events[z].ymd != evts.events[z].endymd
            let trailing = ' ' . repeat('=', v.inner_width)
            call add(longevt, extend(evts.events[z], { 'viewoffset': x }))
          else
            let trailing = ''
          endif
          let eventtext = calendar#string#truncate(evts.events[z].summary . trailing, v.inner_width)
          let s[y + x] .= f.vertical . eventtext
          let l = len(eventtext)
          let xx = len(s[y + x]) - l
          let yy = y + x
          if othermonth
            call self.add_syntax(xx, yy, l, so)
          elseif has_key(evts.events[z], 'syntax')
            call self.add_syntax(xx, yy, l, evts.events[z].syntax, i . ',' . j)
          endif
          let z += 1
        else
          let s[y + x] .= e.vwhite
        endif
      endif
    endfor
    call sort(filter(longevt, 'calendar#day#new(v:val.endymd[0], v:val.endymd[1], v:val.endymd[2]).sub(d) > 0 && has_key(v:val, "viewoffset")'), 'calendar#view#month#sorter')
    if h > 1
      let frame = i ? (j + 1 == v.week_count ? f.bottom : f.junction) : j + 1 == v.week_count ? f.bottomleft : f.left
      let s[y + h - 1] .= frame . self.element.splitter
    endif
    if i == 6
      let [i, j] = [0, j + 1]
    else
      let i = i + 1
    endif
  endfor
  for i in range(v.week_count)
    for j in range(h - 1)
      let s[v.offset + h * i + j] .= f.vertical
    endfor
    let s[v.offset + h * i + h - 1] .= (i + 1 == v.week_count ? f.bottomright : f.right)
  endfor
  let self._month = month.get_ym()
  let self._today = today.get_ymd()
  let self.days = map(range(len(s)), 'calendar#text#new(s[v:val], 0, v:val, "")')
endfunction

function! calendar#view#month#sorter(l, r)
  return a:l.viewoffset == a:r.viewoffset ? 0 : a:l.viewoffset > a:r.viewoffset ? 1 : -1
endfunction

function! s:self.contents() dict
  if self.view.week_count != calendar#week#week_count(b:calendar.month()) || self.frame.type !=# calendar#setting#get('frame')
    call self.on_resize()
  endif
  if self._month != b:calendar.month().get_ym() || self._today != calendar#day#today().get_ymd() || get(g:, 'calendar_google_event_download') > 0 || b:calendar.event._updated
    if has_key(g:, 'calendar_google_event_download') && get(g:, 'calendar_google_event_download') > 0
      let g:calendar_google_event_download -= 1
    endif
    call self.set_contents()
  endif
  let select = []
  let select_over = []
  let cursor = []
  if self.is_selected()
    let [f, v, n] = [self.frame, self.view, self.syntax_name]
    let ij = b:calendar.day().sub(b:calendar.get_days()[0]) + calendar#week#week_number(b:calendar.get_days()[0])
    let [i, j] = [ij % 7, ij / 7]
    let key = i . ',' . j
    let l = v.width * i + f.width
    let r = v.width * (i + 1)
    let hh = range(max([v.height - 1, 1]))
    let y = v.offset + v.height * j
    for h in hh
      let x = len(calendar#string#strwidthpart(self.days[y].s, l))
      let z = len(calendar#string#strwidthpart(self.days[y].s, r))
      if !h
        let cursor = [calendar#text#new(0, x + 2, y, 'Cursor')]
      endif
      if has_key(n, key) && has_key(n[key], y)
        call add(select_over, calendar#text#new(z - x, x, y, n[key][y] . 'Select'))
      else
        call add(select, calendar#text#new(z - x, x, y, 'Select'))
      endif
      let y += 1
    endfor
  endif
  return deepcopy(self.days) + select + deepcopy(self.syntax) + select_over + cursor
endfunction

function! s:self.action(action) dict
  let d = b:calendar.day()
  let month = b:calendar.month()
  let days = b:calendar.get_days()
  let hday = month.head_day()
  let lday = month.last_day()
  let wnum = calendar#week#week_number(d)
  let hwnum = calendar#week#week_number(hday)
  let lwnum = calendar#week#week_number(lday)
  if a:action ==# 'left'
    call b:calendar.move_day(max([-v:count1, -wnum]))
  elseif a:action ==# 'right'
    call b:calendar.move_day(min([v:count1, -wnum + 6]))
  elseif index(['prev', 'next', 'space', 'add', 'subtract'], a:action) >= 0
    call b:calendar.move_day(v:count1 * (index(['prev', 'subtract'], a:action) >= 0 ? -1 : 1))
  elseif index(['down', 'up'], a:action) >= 0
    call b:calendar.move_day(v:count1 * (a:action ==# 'down' ? 1 : -1) * 7)
  elseif index(['plus', 'minus'], a:action) >= 0
    call b:calendar.move_day(v:count1 * (a:action ==# 'plus' ? 1 : -1) * 7 - wnum)
  elseif index(['down_big', 'up_big'], a:action) >= 0
    call b:calendar.move_day(v:count1 * (a:action ==# 'down_big' ? 1 : -1) * 14)
  elseif index(['down_large', 'up_large'], a:action) >= 0
    call b:calendar.move_month(v:count1 * (a:action ==# 'down_large' ? 1 : -1))
  elseif a:action ==# 'line_head'
    call b:calendar.move_day(max([-d.sub(hday), -wnum]))
  elseif a:action ==# 'line_middle'
    call b:calendar.move_day(-wnum + 3)
  elseif a:action ==# 'line_last'
    call b:calendar.move_day(min([-d.sub(lday), 6-wnum]))
  elseif a:action ==# 'bar'
    call b:calendar.move_day(-wnum + min([v:count1 - 1, 6]))
  elseif a:action ==# 'first_line' || (a:action ==# 'last_line' && v:count)
    call b:calendar.move_day(-d.sub(hday) + (v:count1 > 1) * (min([v:count1 - 1, calendar#week#week_count(month) - 1]) * 7 - hwnum))
  elseif a:action ==# 'last_line'
    call b:calendar.move_day(-d.sub(lday)-lwnum)
  elseif a:action ==# 'first_line_head'
    call b:calendar.move_day(-d.sub(hday)-hwnum + (v:count1 > 1) * (min([v:count1 - 1, calendar#week#week_count(month) - 1]) * 7 - hwnum))
  elseif a:action ==# 'last_line_last'
    if v:count
      call b:calendar.move_day(-d.sub(hday) + (min([v:count1 - 1, calendar#week#week_count(month) - 1]) * 7 - hwnum) + 6)
    else
      call b:calendar.move_day(-d.sub(lday)-lwnum+6)
    endif
  elseif a:action ==# 'command_enter' && mode() ==# 'c' && getcmdtype() ==# ':'
    let cmd = calendar#util#getcmdline()
    if cmd =~# '^\s*\d\+\s*$'
      let c = matchstr(cmd, '\d\+') * 1
      if c < 100
        let c = max([min([c, lday.get_day()]), hday.get_day()])
        let [y, m] = month.get_ym()
        call b:calendar.move_day(d.new(y, m, c).sub(d))
        return calendar#util#update_keys()
      else
        call b:calendar.move_year(c - d.get_year())
        return calendar#util#update_keys()
      endif
    endif
  endif
endfunction

let s:constructor = calendar#constructor#view#new(s:self)

let &cpo = s:save_cpo
unlet s:save_cpo
