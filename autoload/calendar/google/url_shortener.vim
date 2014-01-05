" =============================================================================
" Filename: autoload/calendar/google/url_shortener.vim
" Author: itchyny
" License: MIT License
" Last Change: 2013/12/26 23:18:27.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

function! calendar#google#url_shortener#new()
  return copy(s:self)
endfunction

let s:self = {}

function! s:self.get_url() dict
  return 'https://www.googleapis.com/urlshortener/v1/url'
endfunction

function! s:self.shorten(url) dict
  let response = calendar#webapi#post(self.get_url(), {}, { 'longUrl': a:url })
  if response.status == 200
    let content = calendar#webapi#decode(response.content)
    if !has_key(content, 'id')
      return a:url
    else
      return content.id
    endif
  endif
  return a:url
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
