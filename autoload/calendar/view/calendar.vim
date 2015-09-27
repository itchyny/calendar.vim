" =============================================================================
" Filename: autoload/calendar/view/calendar.vim
" Author: itchyny
" License: MIT License
" Last Change: 2015/09/26 14:00:12.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

function! calendar#view#calendar#new(source) abort
  return extend(s:constructor.new(a:source), { 'source': deepcopy(a:source) })
endfunction

let s:self = {}

let s:self.views = {}

function! s:self.width() dict abort
  return self.view.width()
endfunction

function! s:self.height() dict abort
  return self.view.height()
endfunction

function! s:self.set_selected(selected) dict abort
  let self._selected = a:selected
  call self.view.set_selected(a:selected)
  return self
endfunction

function! s:self.set_size() dict abort
  let w = self.maxwidth()
  let h = self.maxheight()
  let index = self.get_index()
  if !has_key(self.views, index)
    let self.views[index] = calendar#view#{index}#new(self.source)
    if has_key(self, 'min_max_hour') && has_key(self.views[index], 'set_min_max_hour')
      call self.views[index].set_min_max_hour(self.min_max_hour)
    endif
  endif
  let self.view = self.views[index]
  if index ==# 'clock'
    call calendar#async#new('b:calendar.redraw()', 1)
  endif
  call self.view.set_size()
  let self.size.x = self.view.size.x
  let self.size.y = self.view.size.y
  return self
endfunction

function! s:self.is_selected() dict abort
  return self.view.is_selected()
endfunction

function! s:self.on_resize() dict abort
  return self.view.on_resize()
endfunction

function! s:self.contents() dict abort
  let contents = self.view.contents()
  if has_key(self.view, 'get_min_max_hour')
    let self.min_max_hour = self.view.get_min_max_hour()
    for c in values(self.views)
      if has_key(c, 'set_min_max_hour')
        call c.set_min_max_hour(self.min_max_hour)
      endif
    endfor
  endif
  return contents
endfunction

function! s:self.updated() dict abort
  return self.view.updated()
endfunction

function! s:self.timerange() dict abort
  return self.view.timerange()
endfunction

function! s:self.action(action) dict abort
  if !has_key(self, 'view') || !has_key(self.view, 'action')
    return
  endif
  if a:action =~# '^start_insert'
    let event_view = b:calendar.view.event_view()
    if type(event_view) == type({})
      call event_view.insert_new_event(a:action ==# 'start_insert_quick' ? a:action : 'start_insert_next_line', {})
    endif
  elseif a:action ==# 'visual'
    call b:calendar.start_visual()
  elseif a:action ==# 'visual_line'
    call b:calendar.start_line_visual()
  elseif a:action ==# 'visual_block'
    call b:calendar.start_block_visual()
  elseif a:action ==# 'exit_visual'
    call b:calendar.exit_visual()
  elseif a:action ==# 'command_enter' && mode() ==# 'c' && (getcmdtype() ==# '/' || getcmdtype() ==# '?')
        \ || a:action ==# 'next_match' || a:action ==# 'prev_match'
    let iscmd = a:action ==# 'command_enter'
    let pattern = iscmd ? getcmdline() : @/
    let day = b:calendar.day()
    let events = b:calendar.event.get_events(day.get_year(), day.get_month())
    let [year, month] = day.month().add(3).get_ym()
    let events = extend(events, b:calendar.event.get_events(year, month))
    let [year, month] = day.month().add(-3).get_ym()
    let events = extend(events, b:calendar.event.get_events(year, month))
    if iscmd && getcmdtype() ==# '/' || a:action ==# 'next_match' &&  v:searchforward
          \                          || a:action ==# 'prev_match' && !v:searchforward
      let indexes = range(1 - iscmd, 160) + range(0, -160, -1)
      let status = '/' . pattern
    else
      let indexes = range(-1 + iscmd, -160, -1) + range(160)
      let status = '?' . pattern
    endif
    let exitvalue = iscmd ? "\<C-c>:\<C-u>silent call b:calendar.update()\<CR>"
          \                     . ":\<C-u>silent let v:searchforward=" . (getcmdtype() ==# '/') . "\<CR>"
          \                     . ":\<C-u>echo " . string(status) . "\<CR>" : 0
    if iscmd
      let @/ = pattern
    else
      echo status
    endif
    try
      for i in indexes
        let ymd = join(day.add(i).get_ymd(), '-')
        for evt in get(get(events, ymd, { 'events': [] } ), 'events', [])
          if get(get(evt, 'start', {}), 'date', get(get(evt, 'start', {}), 'dateTime', '')) . ' '
                \ . get(get(evt, 'end', {}), 'date', get(get(evt, 'end', {}), 'dateTime', '')) . ' '
                \ . get(evt, 'summary', '') =~ pattern " do not use =~# (use 'ignorecase')
            call b:calendar.move_day(i)
            return exitvalue
          endif
        endfor
      endfor
    catch
    endtry
    return exitvalue
  else
    return self.view.action(a:action)
  endif
endfunction

let s:constructor = calendar#constructor#view#new(s:self)

let &cpo = s:save_cpo
unlet s:save_cpo
