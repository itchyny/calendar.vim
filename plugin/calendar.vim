" =============================================================================
" Filename: plugin/calendar.vim
" Author: itchyny
" License: MIT License
" Last Change: 2014/12/14 00:51:34.
" =============================================================================

if exists('g:loaded_calendar') && g:loaded_calendar
  finish
endif

let s:save_cpo = &cpo
set cpo&vim

" :Calendar command
command! -nargs=* -complete=customlist,calendar#argument#complete
       \ Calendar call calendar#new(<q-args>)

" <Plug>(calendar)
nnoremap <silent> <Plug>(calendar) :<C-u>Calendar<CR>
vnoremap <silent> <Plug>(calendar) :<C-u>Calendar<CR>

let g:loaded_calendar = 1

let &cpo = s:save_cpo
unlet s:save_cpo
