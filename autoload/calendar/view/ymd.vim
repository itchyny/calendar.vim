" =============================================================================
" Filename: autoload/calendar/view/ymd.vim
" Author: itchyny
" License: MIT License
" Last Change: 2015/03/29 06:33:59.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

function! calendar#view#ymd#new(source) abort
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
  let index = self.get_index()
  let endian = calendar#setting#get('date_endian')
  if index ==# 'year'
    let name = 'ymd_year'
  elseif index ==# 'month'
    let name = endian ==# 'big' ? 'ymd_yearmonth' : 'ymd_monthyear'
  else
    let name = endian ==# 'big' ? 'ymd_yearmonthday' : endian ==# 'middle' ? 'ymd_monthdayyear' : 'ymd_daymonthyear'
  endif
  if !has_key(self.views, name)
    let self.views[name] = calendar#view#{name}#new(self.source)
  endif
  let self.view = self.views[name]
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
  return self.view.contents()
endfunction

function! s:self.action(action) dict abort
  return self.view.action(a:action)
endfunction

let s:constructor = calendar#constructor#view#new(s:self)

let &cpo = s:save_cpo
unlet s:save_cpo
