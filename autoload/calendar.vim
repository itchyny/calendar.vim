" =============================================================================
" Filename: autoload/calendar.vim
" Author: itchyny
" License: MIT License
" Last Change: 2022/12/13 00:16:52.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

" Creates a new buffer and start calendar.
function! calendar#new(args) abort

  " Argument parsing
  let [isnewbuffer, command, variables, args] = calendar#argument#parse(a:args)

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

endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
