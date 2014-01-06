" =============================================================================
" Filename: autoload/calendar/constructor/view_textbox.vim
" Author: itchyny
" License: MIT License
" Last Change: 2014/01/06 23:38:45.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

function! calendar#constructor#view_textbox#new(instance)
  return extend({ 'instance': a:instance }, s:constructor)
endfunction

let s:constructor = {}

function! s:constructor.new(source) dict
  return extend(extend(s:super_constructor.new(a:source), s:instance), self.instance)
endfunction

let s:instance = {}
let s:instance._key = []
let s:instance.__key = []
let s:instance._texts = []
let s:instance.select = 0
let s:instance.noindex = []
let s:instance._select_title = 0
let s:instance.completed = []
let s:instance.length = 0
let s:instance._current_contents = {}
let s:instance._prev_contents = {}
let s:instance._current_group_id = ''
let s:instance._nocontents = 1

function! s:instance.width() dict
  let frame = calendar#setting#frame()
  let width = calendar#string#strdisplaywidth(frame.vertical)
  return self.maxwidth() / width * width + 2
endfunction

function! s:instance.contents() dict
  if self._key == [self.is_selected(), self.select, self.sizex(), self.sizey(), get(self, 'min_index'), get(self, 'max_index')] + self.get_key()
    return deepcopy(self._texts)
  endif
  let s = []
  let frame = calendar#setting#frame()
  let width = calendar#string#strdisplaywidth(frame.vertical)
  let top = frame.topleft . repeat(frame.horizontal, (self.sizex() - 2) / width - 2) . frame.topright
  let bottom = frame.bottomleft . repeat(frame.horizontal, (self.sizex() - 2) / width - 2) . frame.bottomright
  let w = self.sizex() - 4 - width * 2
  let sizey = self.sizey() - 1
  let self.cnt = self.get_contents()
  let self.length = len(self.cnt)
  if len(self.cnt)
    for i in range(min([len(self.cnt) - self.min_index, sizey]))
      call add(s, self.cnt[self.min_index + i])
    endfor
  endif
  if len(s) < sizey
    for i in range(sizey - len(s))
      call add(s, '')
    endfor
  else
    let s = s[:sizey]
  endif
  call map(s, 'calendar#string#truncate(v:val, w)')
  let texts = map(range(len(s)), 'calendar#text#new(" " . frame.vertical . " " . s[v:val] . " " . frame.vertical . " ", 0, v:val + 1, "")')
  call insert(texts, calendar#text#new(' ' . top . ' ', 0, 0, ''), 0)
  call add(texts, calendar#text#new(' ' . bottom . ' ', 0, len(s), ''))
  for i in self.completed
    if self.min_index <= i && i < self.min_index + sizey
      let len = len(calendar#string#truncate(get(self.cnt, i, ''), w)) + 2
      call add(texts, calendar#text#new(len, 1 + len(frame.vertical), 1 + i - self.min_index, 'Comment'))
    endif
  endfor
  if self.is_selected()
    if self.select < len(self.cnt)
      if self._select_line
        let len = len(calendar#string#truncate(get(self.cnt, self.select, ''), w)) + 2
        let [x, y] = [1 + len(frame.vertical), 1 + self.select - self.min_index]
        let syn = index(self.completed, self.select) < 0 ? 'Select' : 'SelectComment'
        call add(texts, calendar#text#new(len, x, y, syn))
      endif
    endif
    call add(texts, calendar#text#new(0, 1 + len(frame.vertical), 1 + self.select - self.min_index, 'Cursor'))
  endif
  let self._texts = deepcopy(texts)
  let self._key = [self.is_selected(), self.select, self.sizex(), self.sizey(), get(self, 'min_index'), get(self, 'max_index')] + self.get_key()
  return texts
endfunction

function! s:instance.get_key() dict
  return []
endfunction

function! s:instance.get_contents() dict
  if self.__key == [self.select, self.sizex(), self.sizey(), get(self, 'min_index'), get(self, 'max_index')] + self.get_key()
    return self.cnt
  endif
  let self.noindex = []
  let self.completed = []
  let cnt = []
  let frame = calendar#setting#frame()
  let width = calendar#string#strdisplaywidth(frame.vertical)
  let cnts = self.get_raw_contents()
  let self.raw_cnts = cnts
  let w = self.sizex() - width * 2
  if len(cnts)
    let self._current_contents = {}
    let self._prev_contents = {}
    for j in range(len(cnts))
      let t = cnts[j]
      if len(cnt)
        if !self._select_title
          call add(self.noindex, len(cnt))
        endif
        call add(cnt, '')
      endif
      if !self._select_title
        call add(self.noindex, len(cnt))
      endif
      call add(cnt, repeat(' ', max([(self.sizex() - 4 - width * 2 - calendar#string#strdisplaywidth(t.title)) / 2, 0])) . t.title)
      if !self._select_title
        call add(self.noindex, len(cnt))
      endif
      call add(cnt, '')
      while index(self.noindex, self.select) >= 0
        let self.select += 1
      endwhile
      if j == len(cnts) - 1
        let self.select = min([self.select, len(cnt) + len(t.items) - 1])
      endif
      for tt in t.items
        if len(cnt) == self.select - 1
          let self._prev_contents = deepcopy(tt)
        endif
        if len(cnt) == self.select
          let self._current_contents = deepcopy(tt)
          let self._current_group_id = get(t, 'id', '')
        endif
        if get(tt, 'status', '') ==# 'completed'
          call add(self.completed, len(cnt))
        endif
        call add(cnt, get(tt, 'title', get(tt, 'summary', '')))
      endfor
    endfor
    if self._nocontents && has_key(self, 'min_index') && has_key(self, 'max_index')
      unlet! self.min_index self.max_index
    endif
    let [self.min_index, self.max_index] = self.min_max_index(len(cnt))
    let self._nocontents = 0
  else
    let [self.min_index, self.max_index] = [0, 0]
    let self._nocontents = 1
    let self.select = 0
    let self._prev_contents = {}
    let self._current_contents = {}
    let self._current_group_id = ''
  endif
  let self.__key = [self.select, self.sizex(), self.sizey(), get(self, 'min_index'), get(self, 'max_index')] + self.get_key()
  return cnt
endfunction

function! s:instance.min_max_index(length) dict
  let height = self.sizey() - 2
  let length = max([a:length, height])
  if has_key(self, 'min_index')
    if self.select < self.min_index
      let min = self.select
    elseif self.select >= self.max_index
      let min = self.min_index + self.select - self.max_index
    else
      let min = self.min_index
    endif
  else
    let min = self.select - height / 2 + 2
  endif
  let min = max([min, 0])
  let max = min([min + height - 1, length - 1])
  let min = max([max - height + 1, 0])
  let max = min([min + height - 1, length - 1])
  return [min, max]
endfunction

function! s:instance.move_select(diff) dict
  let self.select = max([min([self.select + a:diff, self.length - 1]), 0])
  let diff = a:diff > 0 ? 1 : -1
  while index(self.noindex, self.select) >= 0
    if self.select < 3
      let self.min_index = - self.length
      let diff = 1
    endif
    let self.select += diff
  endwhile
  let self.select = max([min([self.select, self.length - 1]), 0])
endfunction

function! s:instance.current_contents() dict
  return self._current_contents
endfunction

function! s:instance.prev_contents() dict
  return self._prev_contents
endfunction

function! s:instance.current_group_id() dict
  return self._current_group_id
endfunction

function! s:instance._action(action) dict
  let hour = self.select
  if index(['down', 'up'], a:action) >= 0
    call self.move_select(v:count1 * (a:action ==# 'down' ? 1 : -1))
  elseif index(['down_big', 'up_big'], a:action) >= 0
    let diff = self.max_index - self.min_index
    let dir = a:action ==# 'down_big' ? 1 : -1
    let di = max([min([v:count1 * dir * diff * 2 / 3, self.length - 1 - hour]), - hour])
    if dir > 0
      let self.min_index = self.min_index + v:count1 * dir * diff
      let self.max_index = self.min_index + diff
    else
      let self.max_index = self.max_index + v:count1 * dir * diff
      let self.min_index = self.max_index - diff
    endif
    call self.move_select(di)
  elseif index(['down_large', 'up_large'], a:action) >= 0
    let diff = self.max_index - self.min_index
    let dir = a:action ==# 'down_large' ? 1 : -1
    let di = max([min([(dir > 0 ? self.max_index : self.min_index) - hour + (v:count1 - 1) * dir * diff, self.length - 1 - hour]), - hour])
    if dir > 0
      let self.min_index = self.min_index + v:count1 * dir * diff
      let self.max_index = self.min_index + diff
    else
      let self.max_index = self.max_index + v:count1 * dir * diff
      let self.min_index = self.max_index - diff
    endif
    call self.move_select(di)
  elseif a:action ==# 'first_line' || a:action ==# 'first_line_head' || (a:action ==# 'last_line' && v:count)
    call self.move_select((v:count ? min([v:count1, self.length - 1]) : 0) - hour)
  elseif a:action ==# 'last_line'
    call self.move_select((v:count ? max([v:count1, self.length - 1]) : self.length - 1) - hour)
  elseif a:action ==# 'last_line_last'
    call self.move_select((v:count ? max([v:count1, self.length - 1]) : self.length - 1) - hour)
  elseif index(['scroll_top_head', 'scroll_top', 'scroll_bottom_head', 'scroll_bottom', 'scroll_center_head', 'scroll_center'], a:action) >= 0
    let diff = a:action =~# 'center' ? hour - (self.max_index - self.min_index) / 2 + 1 - self.min_index : (self.length - 1) * (a:action =~# 'top' ? 1 : -1)
    let self.min_index += diff
    let self.max_index += diff
  elseif a:action ==# 'status'
    let message = get(self.current_contents(), 'title', get(self.current_contents(), 'summary', ''))
    if len(message)
      call calendar#echo#message(message)
    endif
    return 1
  elseif index(['yank', 'yank_line'], a:action) >= 0
    let message = get(self.current_contents(), 'title', get(self.current_contents(), 'summary', ''))
    if len(message)
      call calendar#util#yank(message)
    endif
    return 1
  elseif a:action ==# 'command_enter' && mode() ==# 'c' && getcmdtype() ==# ':'
    let cmd = calendar#util#getcmdline()
    if cmd =~# '^\s*\d\+\s*$'
      let c = max([min([matchstr(cmd, '\d\+') * 1 - 1, self.length - 1]), 0])
      let idxes = filter(range(self.length), 'index(self.noindex, v:val) < 0')
      call self.move_select(get(idxes, c, get(idxes, -1, 0)) - hour)
      return calendar#util#update_keys()
    endif
  endif
endfunction

function! s:instance.action(action) dict
  return self._action(a:action)
endfunction

let s:super_constructor = calendar#constructor#view#new(s:instance)

let &cpo = s:save_cpo
unlet s:save_cpo
