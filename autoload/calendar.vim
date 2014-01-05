" =============================================================================
" Filename: autoload/calendar.vim
" Author: itchyny
" License: MIT License
" Last Change: 2013/12/28 12:57:26.
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

  " Store the options which are given as the argument.
  let b:_calendar = variables

  " Start calendar.
  let b:calendar = calendar#controller#new()
  " Set time
  call b:calendar.set_time(calendar#time#now())
  " Set day and update the buffer.
  call b:calendar.go(calendar#argument#day(args, calendar#day#today().get_ymd()))

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
