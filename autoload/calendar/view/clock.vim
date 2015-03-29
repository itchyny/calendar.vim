" =============================================================================
" Filename: autoload/calendar/view/clock.vim
" Author: itchyny
" License: MIT License
" Last Change: 2015/03/29 06:32:40.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

function! calendar#view#clock#new(source) abort
  let instance = s:constructor.new(deepcopy(a:source))
  let instance.views = {}
  for name in [ 'clock_date', 'clock_date_monthday', 'clock_date_time', 'clock_date_monthday_time', 'clock_time', 'clock_time_hourmin' ]
    let instance.views[name] = calendar#view#{name}#new(a:source)
  endfor
  return instance
endfunction

let s:self = {}
let s:self.y_height = 1

function! s:self.width() dict abort
  let [date_scale, time_scale] = [self.views.clock_date.get_scale(2), self.views.clock_time.get_scale(2)]
  if (date_scale == 0 || time_scale <= 1) && self.views.clock_date_monthday.get_scale(2) > 0
    let self.date_view = self.views.clock_date_monthday
  else
    let self.date_view = self.views.clock_date
  endif
  if time_scale == 0 && self.views.clock_time_hourmin.get_scale(2) > 0
    let self.time_view = self.views.clock_time_hourmin
  else
    let self.time_view = self.views.clock_time
  endif
  let [date_scale, time_scale] = [self.date_view.get_scale(2), self.time_view.get_scale(2)]
  let [h, w] = [self.maxheight(), self.maxwidth()]
  if h < 5 || w < 10 || self.date_view.height() + self.time_view.height() + self.get_padding() > h || date_scale == 0 && time_scale == 0
    if w < 7
      let self.date_view = self.views.clock_time_hourmin
    elseif w < 10
      let self.date_view = self.views.clock_time
    elseif h < 5
      let self.date_view = self.views.clock_date_time
    elseif self.views.clock_date_time.get_scale(1)
      let self.date_view = self.views.clock_date_time
    elseif self.views.clock_date_monthday_time.get_scale(1)
      let self.date_view = self.views.clock_date_monthday_time
    elseif self.views.clock_time.get_scale(1)
      let self.date_view = self.views.clock_time
    elseif time_scale || self.views.clock_time_hourmin.get_scale(1)
      let self.date_view = self.views.clock_time_hourmin
    elseif self.views.clock_date_time.width() < w
      let self.date_view = self.views.clock_date_time
    elseif self.views.clock_date_monthday_time.width() < w
      let self.date_view = self.views.clock_date_monthday_time
    elseif self.views.clock_time.width() < w
      let self.date_view = self.views.clock_time
    else
      let self.date_view = self.views.clock_time_hourmin
    endif
    call self.time_view.set_visible(0)
    call self.date_view.set_selected(1)
    call self.time_view.set_selected(0)
    let self.date_view.colnum = 1
  else
    let self.date_view.colnum = 2
    let self.time_view.colnum = 2
    call self.time_view.set_visible(1)
    call self.date_view.set_selected(0)
    call self.time_view.set_selected(1)
  endif
  return max([self.date_view.width(), self.time_view.width()])
endfunction

function! s:self.height() dict abort
  let date_height = self.date_view.height()
  let time_height = self.time_view.height()
  return date_height + (time_height + self.get_padding()) * self.time_view.is_visible()
endfunction

function! s:self.set_selected(selected) dict abort
  let self._selected = a:selected
  call self.time_view.set_selected(a:selected)
  return self
endfunction

function! s:self.set_size() dict abort
  let self._size = copy(self.size)
  let self.size.x = self.width()
  let self.size.y = self.height()
  if self._size != self.size
    call self.date_view.set_size()
    call self.time_view.set_size()
  endif
  return self
endfunction

function! s:self.is_selected() dict abort
  return self.time_view.is_selected()
endfunction

function! s:self.get_padding() dict abort
  let date_height = self.date_view.height()
  let time_height = self.time_view.height()
  return min([(self.time_view.scale + self.date_view.scale),
        \ max([0, (self.maxheight() - date_height - time_height) / 3])])
endfunction

function! s:self.contents() dict abort
  let date_contents = self.date_view.contents()
  let diff = - get(self.source, 'top', 0)
  if !self.time_view.is_visible()
    for c in date_contents
      call c.move(0, diff)
    endfor
    return date_contents
  endif
  let time_contents = self.time_view.contents()
  let date_height = self.date_view.sizey() + self.get_padding()
  let date_width = self.date_view.sizex()
  let time_width = self.time_view.sizex()
  if date_width > time_width
    for c in date_contents
      call c.move(0, diff)
    endfor
    for c in time_contents
      call c.move((date_width - time_width) / 2, date_height + diff)
    endfor
  else
    for c in date_contents
      call c.move((time_width - date_width) / 2, diff)
    endfor
    for c in time_contents
      call c.move(0, date_height + diff)
    endfor
  endif
  return date_contents + time_contents
endfunction

function! s:self.on_resize() dict abort
  call self.date_view.on_resize()
  call self.time_view.on_resize()
endfunction

function! s:self.updated() dict abort
  return self.date_view.updated() || self.time_view.updated()
endfunction

function! s:self.action(action) dict abort
  return self.time_view.action(a:action)
endfunction

let s:constructor = calendar#constructor#view#new(s:self)

let &cpo = s:save_cpo
unlet s:save_cpo
