" =============================================================================
" Filename: autoload/calendar/controller.vim
" Author: itchyny
" License: MIT License
" Last Change: 2014/01/10 13:12:49.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

" Calendar controller. This object is the top-level object, b:calendar.
function! calendar#controller#new()
  let self = deepcopy(s:self)
  let self.model = calendar#model#new()
  let self.view = calendar#view#new()
  let self.task = calendar#task#new()
  let self.event = calendar#event#new()
  let self.mark = calendar#mark#new()
  return self
endfunction

let s:self = {}

let s:self.pos = [0, 0]

let s:self.cursor_pos = [0, 0]

let s:self.mode = ''

let s:self.action_name = ''

let s:self.syntaxnames = ['Select', 'Sunday', 'Saturday',
      \ 'TodaySunday', 'TodaySaturday', 'Today',
      \ 'OtherMonth', 'DayTitle', 'SundayTitle', 'SaturdayTitle',
      \ 'NormalSpace', 'Comment', 'SelectComment']

function! s:self.time() dict
  return self.model.time()
endfunction

function! s:self.set_time(time) dict
  return self.model.set_time(a:time)
endfunction

function! s:self.second() dict
  return self.model.second()
endfunction

function! s:self.minute() dict
  return self.model.minute()
endfunction

function! s:self.hour() dict
  return self.model.hour()
endfunction

function! s:self.move_second(diff) dict
  call self.model.move_second(a:diff)
endfunction

function! s:self.move_minute(diff) dict
  call self.model.move_minute(a:diff)
endfunction

function! s:self.move_hour(diff) dict
  call self.model.move_hour(a:diff)
endfunction

function! s:self.day() dict
  return self.model.day()
endfunction

function! s:self.set_day(day) dict
  return self.model.set_day(a:day)
endfunction

function! s:self.month() dict
  return self.model.month()
endfunction

function! s:self.set_month() dict
  return self.model.set_month(self.day().month())
endfunction

function! s:self.year() dict
  return self.model.year()
endfunction

function! s:self.get_days() dict
  return self.model.get_days()
endfunction

function! s:self.move_day(diff) dict
  call self.model.move_day(a:diff)
endfunction

function! s:self.move_month(diff) dict
  call self.model.move_month(a:diff)
endfunction

function! s:self.move_year(diff) dict
  call self.model.move_year(a:diff)
endfunction

function! s:self.go(day) dict
  call self.set_day(a:day)
  call self.set_month()
  call self.update()
endfunction

function! s:self.prepare() dict
  let [self.winheight, self.winwidth] = [calendar#util#winheight(), calendar#util#winwidth()]
  call calendar#mapping#new()
  call calendar#autocmd#new()
  call calendar#setlocal#new()
endfunction

function! s:self.update() dict
  call self.prepare()
  call self.redraw(0)
endfunction

function! s:self.update_force() dict
  call self.prepare()
  call self.redraw(1)
endfunction

function! s:self.update_force_redraw() dict
  call self.event.clear_cache()
  call self.prepare()
  call self.redraw(1, 1)
endfunction

function! s:self.update_if_resized() dict
  if self.winheight != calendar#util#winheight() || self.winwidth != calendar#util#winwidth()
    call self.update_force_redraw()
  endif
endfunction

function! s:self.redraw(...) dict
  if histget(':', -1) ==# 'silent call b:calendar.update()'
    silent! call histdel(':', -1)
  endif
  let u = self.view.gather(a:0 ? a:1 : 0)
  if type(u) != type([])
    return
  endif
  call calendar#setlocal#modifiable()
  silent % delete _
  if a:0 > 1 && a:2
    redraw
  endif
  call setline(1, map(range(calendar#util#winheight()), 'u[v:val].s'))
  for name in self.syntaxnames + get(b:, 'calendar_syntaxnames', [])
    exec 'silent! syntax clear Calendar' . name
  endfor
  let c = 'Cursor'
  let a = 'syntax match Calendar%s /\%%>%dl\%%<%dl\%%%dc.*\%%%dc/'
  let b = 'syntax match Calendar%s /\%%%dl\%%%dc.*\%%%dc/'
  for t in u
    for s in t.syn
      if len(s[0]) && s[1] >= 0 && s[2] >= 0
        if s[0] ==# c
          let self.pos = [s[2], s[1]]
        elseif s[4]
          exe printf(a, s[0], s[1], s[1] + s[4] + 1, s[2] + 1, s[3] + 1)
        else
          exe printf(b, s[0], s[1] + 1, s[2] + 1, s[3] + 1)
        endif
      endif
    endfor
  endfor
  call self.cursor()
  call calendar#setlocal#nomodifiable()
endfunction

function! s:self.cursor() dict
  let b:calendar.cursor_pos = [self.pos[1] + 1, self.pos[0] + 1]
  call cursor(b:calendar.cursor_pos[0], b:calendar.cursor_pos[1])
endfunction

function! s:self.cursor_moved() dict
  let [g, l, c] = [getline('.'), line('.'), col('.')]
  let [pl, pc] = b:calendar.cursor_pos
  if [pl, pc] != [l, c]
   let [wp, wn] = map([getline(pl)[:pc + 1], g[:c + 1]], 'calendar#string#strdisplaywidth(v:val)')
    if pl == l
      call self.action(len(g) <= c * 2 && c * 2 <= (len(g) + 3) ? 'line_middle'
            \ : g[:c - 2] =~? '^\s*$' ? 'line_head'
            \ : len(g) == c ?           'line_last'
            \ : pc < c ?                'right'
            \ :                         'left')
    elseif wp - wn < 2 && wp - wn > -2
      call self.action(pl < l ? 'down' : 'up')
    elseif l == 1 && (c > 2 && getline(1)[:c - 2] =~? '^ *$' || c <= 2)
      call self.action('first_line')
    elseif l == line('$') && c > 2 && getline(1)[:c - 2] =~? '^ *$'
      call self.action('last_line_last')
    endif
  endif
endfunction

function! s:self.action(action) dict
  let action = a:action
  let prevmode = self.mode
  let self.mode = ''
  for prefix in [ 'delete', 'yank', 'change' ]
    if action ==# prefix
      if prevmode ==# prefix
        let self.mode = ''
        let action .= '_line'
        break
      else
        let self.mode = prefix
        return
      endif
    endif
  endfor
  let self.action_name = action
  if action ==# 'command_enter'
    let cmdline = calendar#util#getcmdline()
    if cmdline =~# '^\s*marks\s*$'
      call self.mark.showmarks()
      return calendar#util#update_keys()
    elseif cmdline =~# '^\s*\(ma\%[rk]\s\+\|k\s*\)[a-z]\s*$'
      let mark = matchstr(cmdline, '[a-z]\(\s*$\)\@=')
      call self.mark.set(mark)
      return calendar#util#update_keys()
    elseif cmdline =~# '^\s*delm\%[arks]!\s*$'
      call self.mark.delmarks()
      return calendar#util#update_keys()
    elseif cmdline =~# '^\s*delm\%[arks]\s\+[a-z]\s*$'
      let mark = matchstr(cmdline, '[a-z]\(\s*$\)\@=')
      call self.mark.delmarks(mark)
      return calendar#util#update_keys()
    endif
  endif
  let ret = self.view.action(action)
  if type(ret) == type(0) && ret == 0
    call self.update()
  endif
  return ret
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
