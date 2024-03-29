" =============================================================================
" Filename: plugin/calendar.vim
" Author: itchyny
" License: MIT License
" Last Change: 2022/12/04 13:00:25.
" =============================================================================

if exists('g:loaded_calendar') || v:version < 800
  finish
endif
let g:loaded_calendar = 1

let s:save_cpo = &cpo
set cpo&vim

" :Calendar command
command! -nargs=* -complete=customlist,calendar#argument#complete
       \ Calendar call calendar#new(<q-args>)

" <Plug>(calendar)
nnoremap <silent> <Plug>(calendar) :<C-u>Calendar<CR>
vnoremap <silent> <Plug>(calendar) :<C-u>Calendar<CR>

let &cpo = s:save_cpo
unlet s:save_cpo
