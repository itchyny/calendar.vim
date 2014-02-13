" =============================================================================
" Filename: autoload/calendar.vim
" Author: itchyny
" License: MIT License
" Last Change: 2014/02/12 23:42:42.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

" Creates a new buffer and start calendar.
function! calendar#new(args)

  " Argument parsing
  let [isnewbuffer, command, variables, args] = calendar#argument#parse(a:args)

  " Open mattn's calendar.
  if get(variables, 'mattn', '') ==# '1'
    let split = get(variables, 'split', '')
    let position = get(variables, 'position', '')
    let type = split ==# 'horizontal' ? 1 : position ==# 'tab' ? 2 : position ==# 'below' ? 3 : 0
    return calendar#show(type)
  endif

  " Open a new buffer.
  try | silent execute command | catch | return | endtry

  " Clear the previous syntaxes.
  silent! call b:calendar.clear()

  " Store the options which are given as the argument.
  let b:_calendar = variables

  " Start calendar.
  let b:calendar = calendar#controller#new()
  " Set time
  call b:calendar.set_time(calendar#time#now())
  " Set day and update the buffer.
  call b:calendar.go(calendar#argument#day(args, calendar#day#today().get_ymd()))

  " Save b:calendar and b:_calendar.
  call calendar#save()

endfunction

let s:calendar = {}
let s:_calendar = {}

" Save b:calendar and b:_calendar.
function! calendar#save()
  let nr = bufnr('')
  if has_key(b:, 'calendar')
    let s:calendar[nr] = b:calendar
  endif
  if has_key(b:, '_calendar')
    let s:_calendar[nr] = b:_calendar
  endif
endfunction

" Revive b:calendar and b:_calendar.
function! calendar#revive()
  let nr = bufnr('')
  if !has_key(b:, 'calendar') && has_key(s:calendar, nr)
    let b:calendar = get(s:calendar, nr, {})
  endif
  if !has_key(b:, '_calendar') && has_key(s:_calendar, nr)
    let b:_calendar = get(s:_calendar, nr, {})
  endif
endfunction

" Respect mattn's calendar.vim {{{
let s:thisfile = expand('<sfile>')
function! calendar#show(...)
  let files = split(globpath(&rtp, 'autoload/calendar.vim'), '\n')
  let filenames = map(copy(files), 'reverse(split(v:val, "/"))')
  let thisfilename = reverse(split(s:thisfile, '/'))
  if len(filenames) > 1
    let matchnum = []
    for filename in filenames
      let num = -1
      for i in range(len(filename))
        if i >= len(thisfilename) || filename[i] != thisfilename[i]
          let num = i
          break
        endif
      endfor
      call add(matchnum, num)
    endfor
    call filter(matchnum, 'v:val > 0')
    let i = index(matchnum, min(matchnum))
    if 0 <= i && i < len(filenames)
      let tmp = tempname()
      call writefile(map(readfile(files[i]), 'substitute(v:val, "calendar#", "Calendar_", "g")'), tmp)
      execute 'source ' . tmp
      call delete(tmp)
      call call('Calendar_show', a:000)
    endif
  endif
endfunction
" }}}

let &cpo = s:save_cpo
unlet s:save_cpo
