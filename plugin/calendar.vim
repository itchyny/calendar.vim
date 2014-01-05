" =============================================================================
" Filename: plugin/calendar.vim
" Author: itchyny
" License: MIT License
" Last Change: 2013/12/25 00:23:40.
" =============================================================================

if exists('g:loaded_calendar') && g:loaded_calendar
  finish
endif

let s:save_cpo = &cpo
set cpo&vim

" :Calendar command
command! -nargs=* -complete=customlist,calendar#argument#complete
       \ Calendar call calendar#new(<q-args>)

" Respect mattn's calendar.vim {{{
let s:thisfile = expand('<sfile>')
function! s:load()
  let files = split(globpath(&rtp, 'autoload/calendar.vim'), '\n')
  if len(files) < 2 | return | endif
  let filenames = map(copy(files), 'reverse(split(v:val, "/"))')
  let thisfilename = reverse(split(s:thisfile, '/'))
  if len(filenames) > 1
    let matchnum = []
    for filename in filenames
      let num = -1
      for i in range(len(filename))
        if i >= len(thisfilename) || filename[i] !=# thisfilename[i] && filename[i] !=# 'autoload'
          let num = i
          break
        endif
      endfor
      call add(matchnum, num)
    endfor
    call filter(matchnum, 'v:val > 0')
    let i = index(matchnum, max(matchnum))
    if 0 <= i && i < len(filenames)
      execute 'silent! source ' . files[i]
    endif
  endif
endfunction
call s:load()
" }}}

let g:loaded_calendar = 1

let &cpo = s:save_cpo
unlet s:save_cpo
