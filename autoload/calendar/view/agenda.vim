" =============================================================================
" Filename: autoload/calendar/view/agenda.vim
" Author: itchyny
" License: MIT License
" Last Change: 2015/06/27 18:22:45.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

function! calendar#view#agenda#new(source) abort
  return calendar#view#event#new(extend(deepcopy(a:source), { 'agenda': 1 }))
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
