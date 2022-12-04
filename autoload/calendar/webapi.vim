" =============================================================================
" Filename: autoload/calendar/webapi.vim
" Author: itchyny
" License: MIT License
" Last Change: 2022/12/04 13:27:31.
" =============================================================================

" Web interface.
" Most part of this file was copied from webapi-vim and vital.vim.
" Thank you Yasuhiro Matsumoto, for distributing useful scripts under public
" domain.

" Maintainer and License of the original script {{{
" Last Change: 2010-09-10
" Maintainer:   Yasuhiro Matsumoto <mattn.jp@gmail.com>
" License:      This file is placed in the public domain.
" }}}

let s:save_cpo = &cpo
set cpo&vim

let s:cache = calendar#cache#new('download')
call s:cache.check_dir(1)
if !calendar#setting#get('debug')
  call s:cache.rmdir_on_exit()
endif

function! calendar#webapi#get(url, ...) abort
  return s:request(1, {}, a:url, get(a:000, 0, {}), get(a:000, 1, {}), get(a:000, 2, 'GET'))
endfunction

function! calendar#webapi#post(url, ...) abort
  return s:request(1, {}, a:url, get(a:000, 0, {}), get(a:000, 1, {}), get(a:000, 2, 'POST'))
endfunction

function! calendar#webapi#delete(url, ...) abort
  return s:request(1, {}, a:url, get(a:000, 0, {}), get(a:000, 1, {}), get(a:000, 2, 'DELETE'))
endfunction

function! calendar#webapi#patch(url, ...) abort
  return s:request(1, {}, a:url, get(a:000, 0, {}), get(a:000, 1, {}), get(a:000, 2, 'PATCH'))
endfunction

function! calendar#webapi#put(url, ...) abort
  return s:request(1, {}, a:url, get(a:000, 0, {}), get(a:000, 1, {}), get(a:000, 2, 'PUT'))
endfunction

function! calendar#webapi#post_nojson(url, ...) abort
  return s:request(0, {}, a:url, get(a:000, 0, {}), get(a:000, 1, {}), get(a:000, 2, 'POST'))
endfunction

function! calendar#webapi#get_async(id, cb, url, ...) abort
  return s:request(1, { 'id': a:id, 'cb': a:cb } , a:url, get(a:000, 0, {}), get(a:000, 1, {}), get(a:000, 2, 'GET'))
endfunction

function! calendar#webapi#post_async(id, cb, url, ...) abort
  return s:request(1, { 'id': a:id, 'cb': a:cb }, a:url, get(a:000, 0, {}), get(a:000, 1, {}), get(a:000, 2, 'POST'))
endfunction

function! calendar#webapi#delete_async(id, cb, url, ...) abort
  return s:request(1, { 'id': a:id, 'cb': a:cb }, a:url, get(a:000, 0, {}), get(a:000, 1, {}), get(a:000, 2, 'DELETE'))
endfunction

function! calendar#webapi#patch_async(id, cb, url, ...) abort
  return s:request(1, { 'id': a:id, 'cb': a:cb }, a:url, get(a:000, 0, {}), get(a:000, 1, {}), get(a:000, 2, 'PATCH'))
endfunction

function! calendar#webapi#put_async(id, cb, url, ...) abort
  return s:request(1, { 'id': a:id, 'cb': a:cb }, a:url, get(a:000, 0, {}), get(a:000, 1, {}), get(a:000, 2, 'PUT'))
endfunction

function! calendar#webapi#post_nojson_async(id, cb, url, ...) abort
  return s:request(0, { 'id': a:id, 'cb': a:cb }, a:url, get(a:000, 0, {}), get(a:000, 1, {}), get(a:000, 2, 'POST'))
endfunction

function! s:request(json, async, url, param, postdata, method) abort
  let url = a:url
  let paramstr = calendar#webapi#encodeURI(a:param)
  let withbody = a:method !=# 'GET' && a:method !=# 'DELETE'
  let header = {}
  if paramstr !=# ''
    let url .= '?' . paramstr
  endif
  let postfile = ''
  if withbody
    let postdatastr = a:json ? json_encode(a:postdata) : join(s:postdata(a:postdata), "\n")
    let postfile = tempname()
    call writefile(split(postdatastr, "\n"), postfile, 'b')
    let header['Content-Length'] = len(postdatastr)
    if a:json
      let header['Content-Type'] = 'application/json'
    endif
  endif
  let command = s:command(url, a:method, header, postfile, a:async == {} ? '' : s:cache.path(a:async.id))
  if type(command) != type('')
    return { 'status': '0', 'message': '', 'header': '', 'content': '' }
  endif
  call s:cache.check_dir(1)
  if a:async == {}
    let response = calendar#webapi#parse(systemlist(command))
    if withbody
      call delete(postfile)
    endif
    return response
  else
    if !calendar#setting#get('debug')
      call s:cache.delete(a:async.id)
    endif
    call calendar#async#new('calendar#webapi#callback(' . string(a:async.id) . ',' . string(a:async.cb) . ')')
    if has('win32')
      silent! call system('cmd /c start /min ' . command)
    else
      silent! call system(command . ' &')
    endif
  endif
endfunction

function! s:command(url, method, header, postfile, output) abort
  let quote = s:_quote()
  if executable('curl')
    let command = 'curl --http1.1 --suppress-connect-headers -s -k -i -N -X ' . a:method
    let command .= s:make_header_args(a:header, '-H ', quote)
    if a:postfile !=# ''
      let command .= ' --data-binary @' . quote . a:postfile . quote
    endif
    if a:output !=# ''
      let command .= ' -o ' . quote . a:output . quote
    endif
    let command .= ' ' . quote . a:url . quote
    return command
  elseif executable('wget')
    let command = 'wget -O- --server-response -q'
    let a:header['X-HTTP-Method-Override'] = a:method
    let command .= s:make_header_args(a:header, '--header=', quote)
    if a:postfile !=# ''
      let command .= ' --post-file=' . quote . a:postfile . quote
    else
      let command .= ' --method=' . a:method
    endif
    let command .= ' ' . quote . a:url . quote
    if a:output !=# ''
      let command .= ' > ' . quote . a:output . quote . ' 2>&1'
    endif
    return command
  else
    call calendar#echo#error_message('curl_wget_not_found')
    return 1
  endif
endfunction

let s:callback_datalen = {}
function! calendar#webapi#callback(id, cb) abort
  let data = s:cache.get_raw(a:id)
  if type(data) != type([])
    return 1
  endif
  let prevdatalen = get(s:callback_datalen, a:id)
  let s:callback_datalen[a:id] = len(data)
  if len(data) == 0 || len(data) != prevdatalen
    return 1
  endif
  let response = calendar#webapi#parse(data)
  if empty(response)
    return 1
  elseif a:cb !=# ''
    call call(a:cb, [a:id, response])
  endif
  if !calendar#setting#get('debug')
    call s:cache.delete(a:id)
  endif
  unlet s:callback_datalen[a:id]
  return 0
endfunction

function! calendar#webapi#parse(data) abort
  if len(a:data) == 0
    return { 'status': '0', 'message': '', 'header': '', 'content': '' }
  endif
  let i = 0
  while i < len(a:data) && a:data[i] =~# '^  ' " for wget
    let a:data[i] = a:data[i][2:]
    let i += 1
  endwhile
  if i > 0
    call insert(a:data, '', i)
    let i = 0
  endif
  while i < len(a:data) && (a:data[i] =~# '\v^HTTP/[12]%(\.\d)? 3' ||
        \ (i + 2 < len(a:data) && a:data[i] =~# '\v^HTTP/1\.\d \d{3}' &&
        \ a:data[i + 1] =~# '\v^\r?$' && a:data[i + 2] =~# '\v^HTTP/1\.\d \d{3}'))
    while i < len(a:data) && a:data[i] !~# '\v^\r?$'
      let i += 1
    endwhile
    let i += 1
  endwhile
  while i < len(a:data) && a:data[i] !~# '\v^\r?$'
    let i += 1
  endwhile
  let header = a:data[:i]
  let content = join(a:data[(i):], "\n")
  let matched = matchlist(get(header, 0, ''), '\v^HTTP/[12]%(\.\d)?\s+(\d+)\s*(.*)')
  if !empty(matched)
    let [status, message] = matched[1 : 2]
    call remove(header, 0)
  else
    let [status, message] = ['200', 'OK']
  endif
  return { 'status': status, 'message': message, 'header': header, 'content': content }
endfunction

function! calendar#webapi#open_url(url) abort
  if has('win32')
    silent! call system('cmd /c start "" "' . a:url . '"')
  elseif executable('xdg-open')
    silent! call system('xdg-open "' . a:url . '" &')
  elseif executable('open')
    silent! call system('open "' . a:url . '" &')
  endif
endfunction

function! calendar#webapi#echo_error(response) abort
  let message = get(a:response, 'message', '')
  if has_key(a:response, 'content')
    let cnt = json_decode(a:response.content)
    if type(cnt) == type({}) && len(get(get(cnt, 'error', {}), 'message', ''))
      let message = get(get(cnt, 'error', {}), 'message', '')
    endif
  endif
  if message !=# ''
    call calendar#echo#error(message)
  endif
endfunction

function! s:make_header_args(headdata, option, quote) abort
  let args = ''
  for key in keys(a:headdata)
    unlet! value
    let value = type(a:headdata[key]) == type('') || type(a:headdata[key]) == type(0) ? a:headdata[key] :
          \     type(a:headdata[key]) == type({}) ? '' :
          \     type(a:headdata[key]) == type([]) ? '[' . join(map(a:headdata[key], 's:make_header_args(v:val, a:option, a:quote)'), ',') . ']' : ''
    if has('win32')
      let value = substitute(value, '"', '"""', 'g')
    endif
    let args .= ' ' . a:option . a:quote . key . ': ' . value . a:quote
  endfor
  return args
endfunction

function! s:decodeURI(str) abort
  let ret = a:str
  let ret = substitute(ret, '+', ' ', 'g')
  let ret = substitute(ret, '%\(\x\x\)', '\=printf("%c", str2nr(submatch(1), 16))', 'g')
  return ret
endfunction

function! s:escape(str) abort
  return substitute(a:str, '[^a-zA-Z0-9_.-]', '\=printf("%%%02X", char2nr(submatch(0)))', 'g')
endfunction

function! calendar#webapi#encodeURI(items) abort
  let ret = ''
  if type(a:items) == type({})
    for key in sort(keys(a:items))
      if ret !=# ''
        let ret .= '&'
      endif
      let ret .= key . '=' . calendar#webapi#encodeURI(a:items[key])
    endfor
  elseif type(a:items) == type([])
    for item in sort(a:items)
      if ret !=# ''
        let ret .= '&'
      endif
      let ret .= item
    endfor
  else
    let ret = s:escape(a:items)
  endif
  return ret
endfunction

function! s:postdata(data) abort
  if type(a:data) == type({})
    return [calendar#webapi#encodeURI(a:data)]
  elseif type(a:data) == type([])
    return a:data
  else
    return split(a:data, "\n")
  endif
endfunction

function! s:_quote() abort
  return &shellxquote == '"' ?  "'" : '"'
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
