" =============================================================================
" Filename: autoload/calendar/view/year.vim
" Author: itchyny
" License: MIT License
" Last Change: 2015/03/29 06:33:54.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

function! calendar#view#year#new(source) abort
  let instance = s:constructor.new(a:source)
  let instance.views = {}
  for name in [ 'month_1x1', 'month_1x3', 'month_3x1', 'month_4x1',
        \      'month_5x1', 'month_3x4', 'month_4x3', 'month_2x6', 'month_6x2', ]
    let instance.views[name] = calendar#view#{name}#new(instance.source)
  endfor
  return instance
endfunction

let s:self = {}

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
  let views = ['month_4x3', 'month_3x4', 'month_6x2', 'month_2x6', 'month_5x1', 'month_4x1', 'month_3x1', 'month_1x3']
  let view_name = ''
  let view_point = -1
  for i in range(len(views))
    let p = self.views[views[i]].display_point()
    if (view_point < 0 || view_point > p) && p > 0
      let view_point = p
      let view_name = views[i]
    endif
    if view_name != '' && i % 2
      break
    endif
  endfor
  let self.view = self.views[view_name ==# '' ? 'month_1x1' : view_name]
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

function! s:self.updated() dict abort
  return self.view.updated()
endfunction

function! s:self.action(action) dict abort
  return self.view.action(a:action)
endfunction

let s:constructor = calendar#constructor#view#new(s:self)

let &cpo = s:save_cpo
unlet s:save_cpo
