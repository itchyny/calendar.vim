" =============================================================================
" Filename: autoload/calendar/constructor/view.vim
" Author: itchyny
" License: MIT License
" Last Change: 2014/02/08 22:12:28.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

function! calendar#constructor#view#new(instance)
  return extend({ 'instance': a:instance }, s:constructor)
endfunction

let s:constructor = {}

function! s:constructor.new(source) dict
  let instance = extend(deepcopy(s:instance), deepcopy(self.instance))
  let instance.size = { 'x': 0, 'y': 0 }
  let instance._size = instance.size
  let instance.source = a:source
  let instance._selected = 0
  return instance
endfunction

let s:instance = {}

function! s:instance.set_visible(value) dict
  let self._visible = a:value
endfunction

function! s:instance.is_visible() dict
  sandbox return has_key(self, '_visible') ? self._visible : has_key(self.source, 'visible') ? eval(self.source.visible) : 1
endfunction

function! s:instance.on_top() dict
  sandbox return has_key(self.source, 'on_top') ? eval(self.source.on_top) : 0
endfunction

function! s:instance.width() dict
  return self.maxwidth()
endfunction

function! s:instance.height() dict
  return self.maxheight()
endfunction

function! s:instance.sizex() dict
  return self.size.x
endfunction

function! s:instance.sizey() dict
  return self.size.y
endfunction

function! s:instance.set_size() dict
  let self._size = copy(self.size)
  let self.size.x = self.width()
  let self.size.y = self.height()
  if self._size != self.size && has_key(self, 'on_resize')
    call self.on_resize()
  endif
  return self
endfunction

function! s:instance.left() dict
  sandbox return has_key(self.source, 'left') ? eval(self.source.left) : 0
endfunction

function! s:instance.top() dict
  sandbox return has_key(self.source, 'top') ? eval(self.source.top) : 0
endfunction

function! s:instance.maxwidth() dict
  sandbox return has_key(self.source, 'maxwidth') ? eval(self.source.maxwidth) : calendar#util#winwidth() - 1
endfunction

function! s:instance.maxheight() dict
  sandbox return has_key(self.source, 'maxheight') ? eval(self.source.maxheight) : calendar#util#winheight()
endfunction

function! s:instance.is_center() dict
  return get(self.source, 'align', '') ==# 'center'
endfunction

function! s:instance.is_vcenter() dict
  return get(self.source, 'valign', '') ==# 'center'
endfunction

function! s:instance.is_right() dict
  return get(self.source, 'align', '') ==# 'right'
endfunction

function! s:instance.is_bottom() dict
  return get(self.source, 'valign', '') ==# 'bottom'
endfunction

function! s:instance.is_absolute() dict
  return get(self.source, 'position', '') ==# 'absolute'
endfunction

function! s:instance.get_top() dict
  return max([self.top() + (self.is_vcenter() ? (self.maxheight() - self.size.y) / 2 : self.is_bottom() ? (self.maxheight() - self.size.y) : 0), 0])
endfunction

function! s:instance.get_left() dict
  return max([self.left() + (self.is_center() ? (self.maxwidth() - self.size.x + 1) / 2 : self.is_right() ? (self.maxwidth() - self.size.x) : 0), 0])
endfunction

function! s:instance.display_point() dict
  return 1
endfunction

function! s:instance.gather(...) dict
  let c = self.contents()
  let l = self.get_left()
  let p = self.get_top() + (a:0 ? a:1 : 0)
  return map(c, 'v:val.move(l, p)')
endfunction

function! s:instance.set_selected(selected) dict
  let self._selected = a:selected
  return self
endfunction

function! s:instance.is_selected() dict
  return self._selected
endfunction

function! s:instance.set_index(index) dict
  let self._index = a:index
endfunction

function! s:instance.get_index() dict
  return self._index
endfunction

function! s:instance.updated() dict
  return 1
endfunction

function! s:instance.timerange() dict
  return ''
endfunction

function! s:instance.action(action) dict
  return 0
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
