" =============================================================================
" Filename: autoload/calendar/view/calendar.vim
" Author: itchyny
" License: MIT License
" Last Change: 2014/01/09 07:43:12.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

function! calendar#view#calendar#new(source)
  return extend(s:constructor.new(a:source), { 'source': deepcopy(a:source) })
endfunction

let s:self = {}

let s:self.views = {}

function! s:self.width() dict
  return self.view.width()
endfunction

function! s:self.height() dict
  return self.view.height()
endfunction

function! s:self.set_selected(selected) dict
  let self._selected = a:selected
  call self.view.set_selected(a:selected)
  return self
endfunction

function! s:self.set_size() dict
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

function! s:self.is_selected() dict
  return self.view.is_selected()
endfunction

function! s:self.on_resize() dict
  return self.view.on_resize()
endfunction

function! s:self.contents() dict
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

function! s:self.updated() dict
  return self.view.updated()
endfunction

function! s:self.timerange() dict
  return self.view.timerange()
endfunction

function! s:self.action(action) dict
  if a:action =~# '^start_insert'
    let event_view = b:calendar.view.event_view()
    if type(event_view) == type({})
      call event_view.insert_new_event('start_insert_next_line', {})
    endif
  else
    return self.view.action(a:action)
  endif
endfunction

let s:constructor = calendar#constructor#view#new(s:self)

let &cpo = s:save_cpo
unlet s:save_cpo
