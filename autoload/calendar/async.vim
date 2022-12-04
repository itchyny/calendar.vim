" =============================================================================
" Filename: autoload/calendar/async.vim
" Author: itchyny
" License: MIT License
" Last Change: 2022/12/04 13:02:06.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

" Register a command to be executed asyncronously.
" Optional argument: Allow duplication of commands.
function! calendar#async#new(command, ...) abort
  if !exists('b:calendar_async')
    let b:calendar_async = []
  endif
  if len(b:calendar_async) == 0
    call timer_start(200, 'calendar#async#call')
    execute 'augroup CalendarAsync' . bufnr('')
      autocmd!
      autocmd BufEnter,WinEnter <buffer> call calendar#async#call()
    augroup END
  endif
  let i = 0
  for [c, num, dup] in b:calendar_async
    if c ==# a:command
      let i += 1
      if i > 2 * (a:0 && a:1) || !a:0
        return
      endif
    endif
  endfor
  call add(b:calendar_async, [a:command, 0, a:0 && a:1])
endfunction

" Execute the registered commands.
function! calendar#async#call(...) abort
  if !exists('b:calendar_async')
    return
  endif
  let del = []
  let done = {}
  let cnt = 0
  let len = len(b:calendar_async)
  for i in range(len)
    let expression = b:calendar_async[i][0]
    if has_key(done, expression)
      call add(del, i)
      continue
    endif
    if cnt > 1 && !b:calendar_async[i][2]
      continue
    endif
    let done[expression] = 1
    let cnt += 1
    let ret = eval(expression)
    let b:calendar_async[i][1] += 1
    if !ret || b:calendar_async[i][1] > 100
      call add(del, i)
    endif
  endfor
  for i in reverse(del)
    call remove(b:calendar_async, i)
  endfor
  if len(b:calendar_async)
    call timer_start(200, 'calendar#async#call')
  else
    execute 'autocmd! CalendarAsync' . bufnr('')
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
