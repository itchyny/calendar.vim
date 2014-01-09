" =============================================================================
" Filename: autoload/calendar/webapi.vim
" Author: itchyny
" License: MIT License
" Last Change: 2014/01/07 12:26:13.
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
call s:cache.rmdir_on_exit()

function! s:response()
  return { 'status': 500, 'message': '', 'header': [], 'content': [] }
endfunction

function! s:urlencode_char(c, ...)
  let is_binary = get(a:000, 1)
  if !is_binary
    let c = iconv(a:c, &encoding, "utf-8")
    if c == ""
      let c = a:c
    endif
  endif
  let s = ""
  for i in range(strlen(c))
    let s .= printf("%%%02X", char2nr(c[i]))
  endfor
  return s
endfunction

function! s:nr2byte(nr)
  if a:nr < 0x80
    return nr2char(a:nr)
  elseif a:nr < 0x800
    return nr2char(a:nr/64+192).nr2char(a:nr%64+128)
  else
    return nr2char(a:nr/4096%16+224).nr2char(a:nr/64%64+128).nr2char(a:nr%64+128)
  endif
endfunction

function! s:nr2enc_char(charcode)
  if &encoding == 'utf-8'
    return nr2char(a:charcode)
  endif
  let char = s:nr2byte(a:charcode)
  if strlen(char) > 1
    let char = strtrans(iconv(char, 'utf-8', &encoding))
  endif
  return char
endfunction

function! calendar#webapi#encodeURI(items, ...)
  let is_binary = get(a:000, 1)
  let ret = ''
  if type(a:items) == 4
    for key in sort(keys(a:items))
      if strlen(ret) | let ret .= "&" | endif
      let ret .= key . "=" . calendar#webapi#encodeURI(a:items[key])
    endfor
  elseif type(a:items) == 3
    for item in sort(a:items)
      if strlen(ret) | let ret .= "&" | endif
      let ret .= item
    endfor
  else
    let ret = substitute(a:items, '[^a-zA-Z0-9_.~-]', '\=s:urlencode_char(submatch(0), is_binary)', 'g')
  endif
  return ret
endfunction

function! s:execute(command)
  let res = calendar#util#system(a:command)
  let pos = stridx(res, "\r\n\r\n")
  if pos != -1
    let content = strpart(res, pos+4)
  else
    let pos = stridx(res, "\n\n")
    let content = strpart(res, pos+2)
  endif
  let header = split(res[:pos-1], '\r\?\n')
  let matched = matchlist(get(header, 0), '^HTTP/1\.\d\s\+\(\d\+\)\s\+\(.*\)')
  if !empty(matched)
    let [status, message] = matched[1 : 2]
    call remove(header, 0)
  else
    if v:shell_error || len(matched)
      let [status, message] = ['500', "Couldn't connect to host"]
    else
      let [status, message] = ['200', 'OK']
    endif
  endif
  return {
        \ "status" : status,
        \ "message" : message,
        \ "header" : header,
        \ "content" : content
        \}
endfunction

function! calendar#webapi#get(url, ...)
  return s:request(1, {}, a:url, get(a:000, 0, {}), get(a:000, 1, {}), get(a:000, 2, 'GET'))
endfunction

function! calendar#webapi#post(url, ...)
  return s:request(1, {}, a:url, get(a:000, 0, {}), get(a:000, 1, {}), get(a:000, 2, 'POST'))
endfunction

function! calendar#webapi#delete(url, ...)
  return s:request(1, {}, a:url, get(a:000, 0, {}), get(a:000, 1, {}), get(a:000, 2, 'DELETE'))
endfunction

function! calendar#webapi#patch(url, ...)
  return s:request(1, {}, a:url, get(a:000, 0, {}), get(a:000, 1, {}), get(a:000, 2, 'PATCH'))
endfunction

function! calendar#webapi#put(url, ...)
  return s:request(1, {}, a:url, get(a:000, 0, {}), get(a:000, 1, {}), get(a:000, 2, 'PUT'))
endfunction

function! calendar#webapi#post_nojson(url, ...)
  return s:request(0, {}, a:url, get(a:000, 0, {}), get(a:000, 1, {}), get(a:000, 2, 'POST'))
endfunction

function! calendar#webapi#get_async(id, cb, url, ...)
  return s:request(1, { 'id': a:id, 'cb': a:cb } , a:url, get(a:000, 0, {}), get(a:000, 1, {}), get(a:000, 2, 'GET'))
endfunction

function! calendar#webapi#post_async(id, cb, url, ...)
  return s:request(1, { 'id': a:id, 'cb': a:cb }, a:url, get(a:000, 0, {}), get(a:000, 1, {}), get(a:000, 2, 'POST'))
endfunction

function! calendar#webapi#delete_async(id, cb, url, ...)
  return s:request(1, { 'id': a:id, 'cb': a:cb }, a:url, get(a:000, 0, {}), get(a:000, 1, {}), get(a:000, 2, 'DELETE'))
endfunction

function! calendar#webapi#patch_async(id, cb, url, ...)
  return s:request(1, { 'id': a:id, 'cb': a:cb }, a:url, get(a:000, 0, {}), get(a:000, 1, {}), get(a:000, 2, 'PATCH'))
endfunction

function! calendar#webapi#put_async(id, cb, url, ...)
  return s:request(1, { 'id': a:id, 'cb': a:cb }, a:url, get(a:000, 0, {}), get(a:000, 1, {}), get(a:000, 2, 'PUT'))
endfunction

function! calendar#webapi#post_nojson_async(id, cb, url, ...)
  return s:request(0, { 'id': a:id, 'cb': a:cb }, a:url, get(a:000, 0, {}), get(a:000, 1, {}), get(a:000, 2, 'POST'))
endfunction

function! s:request(json, async, url, ...)
  let url = a:url
  let param = a:0 > 0 ? a:000[0] : {}
  let postdata = a:0 > 1 ? a:000[1] : {}
  let method = a:0 > 2 ? a:000[2] : "POST"
  let paramstr = calendar#webapi#encodeURI(param)
  let withbody = method !=# 'GET' && method !=# 'DELETE'
  let headdata = {}
  if strlen(paramstr)
    let url .= "?" . paramstr
  endif
  let quote = s:_quote()
  if withbody
    let postdatastr = a:json ? calendar#webapi#encode(postdata) : join(s:postdata(postdata), "\n")
    let file = tempname()
    let headdata['Content-Length'] = len(postdatastr)
    if a:json
      let headdata['Content-Type'] = 'application/json'
    endif
  endif
  if executable('curl')
    let command = printf('curl -s -k -i -N -X %s', method)
    let command .= s:make_header_args(headdata, '-H ', quote)
    let command .= " " . quote . url . quote
    if withbody
      let command .= " --data-binary @" . quote . file . quote
    endif
  elseif executable('wget')
    let command = 'wget -O- --save-headers --server-response -q'
    let headdata['X-HTTP-Method-Override'] = method
    let command .= s:make_header_args(headdata, '--header=', quote)
    let command .= " " . quote . url . quote
    if withbody
      let command .= " --post-data @" . quote . file . quote
    endif
  else
    call calendar#echo#error_message('curl_wget_not_found')
    return 1
  endif
  if withbody
    call writefile(split(postdatastr, "\n"), file, "b")
  endif
  if a:async != {}
    let command .= ' > ' . quote . s:cache.path(a:async.id) . quote . ' &'
    call s:cache.delete(a:async.id)
    call calendar#async#new('calendar#webapi#callback(' . string(a:async.id) . ',' . string(a:async.cb) . ')')
    call calendar#util#system(command)
  else
    let ret = s:execute(command)
    if withbody
      call delete(file)
    endif
    return ret
  endif
endfunction

let s:callback_count = {}
let s:callback_datalen = {}
function! calendar#webapi#callback(id, cb)
  let data = s:cache.get_raw(a:id)
  if type(data) == type([])
    let prevdatalen = get(s:callback_datalen, a:id)
    let s:callback_datalen[a:id] = len(data)
    if len(data) == 0 || len(data) != prevdatalen
      return 1
    endif
    let s:callback_count[a:id] = get(s:callback_count, a:id) + 1
    if s:callback_count[a:id] < 3
      return 1
    endif
    call remove(s:callback_count, a:id)
    if len(data)
      let i = 0
      while i < len(data) && data[i] !~# '^\r\?$'
        let i += 1
      endwhile
      let header = data[:i]
      let content = join(data[(i):], "\n")
      let matched = matchlist(get(header, 0), '^HTTP/1\.\d\s\+\(\d\+\)\s\+\(.*\)')
      if !empty(matched)
        let [status, message] = matched[1 : 2]
        call remove(header, 0)
      else
        if len(matched)
          let [status, message] = ['500', "Couldn't connect to host"]
        else
          let [status, message] = ['200', 'OK']
        endif
      endif
      let response = {
            \ "status" : status,
            \ "message" : message,
            \ "header" : header,
            \ "content" : content
            \ }
      if len(a:cb)
        exec 'call ' . a:cb . '(a:id, response)'
      endif
    else
      return 1
    endif
    call s:cache.delete(a:id)
    return 0
  endif
  return 1
endfunction

function! calendar#webapi#null()
  return 0
endfunction

function! calendar#webapi#true()
  return 1
endfunction

function! calendar#webapi#false()
  return 0
endfunction

function! calendar#webapi#encode(val)
  if type(a:val) == 0
    return a:val
  elseif type(a:val) == 1
    let json = '"' . escape(a:val, '\"') . '"'
    let json = substitute(json, "\r", '\\r', 'g')
    let json = substitute(json, "\n", '\\n', 'g')
    let json = substitute(json, "\t", '\\t', 'g')
    let json = substitute(json, '\([[:cntrl:]]\)', '\=printf("\x%02d", char2nr(submatch(1)))', 'g')
    return iconv(json, &encoding, "utf-8")
  elseif type(a:val) == 2
    let s = string(a:val)
    if s == "function('calendar#webapi#null')"
      return 'null'
    elseif s == "function('calendar#webapi#true')"
      return 'true'
    elseif s == "function('calendar#webapi#false')"
      return 'false'
    endif
  elseif type(a:val) == 3
    return '[' . join(map(copy(a:val), 'calendar#webapi#encode(v:val)'), ',') . ']'
  elseif type(a:val) == 4
    return '{' . join(map(keys(a:val), 'calendar#webapi#encode(v:val).":".calendar#webapi#encode(a:val[v:val])'), ',') . '}'
  else
    return string(a:val)
  endif
endfunction

function! calendar#webapi#decode(json)
  let json = iconv(a:json, "utf-8", &encoding)
  let json = substitute(json, '\n', '', 'g')
  let json = substitute(json, '\\u34;', '\\"', 'g')
  if v:version >= 703 && has('patch780')
    let json = substitute(json, '\\u\(\x\x\x\x\)', '\=iconv(nr2char(str2nr(submatch(1), 16), 1), "utf-8", &encoding)', 'g')
  else
    let json = substitute(json, '\\u\(\x\x\x\x\)', '\=s:nr2enc_char("0x".submatch(1))', 'g')
  endif
  let [null,true,false] = [0,1,0]
  try
    sandbox let ret = eval(json)
  catch
    let ret = {}
  endtry
  return ret
endfunction

function! calendar#webapi#open_url(url)
  if has('win32') || has('win64')
    silent! call calendar#util#system('start rundll32 url.dll,FileProtocolHandler "' . a:url . '" &')
  elseif executable('xdg-open')
    silent! call calendar#util#system('xdg-open "' . a:url . '" &')
  elseif executable('open')
    silent! call calendar#util#system('open "' . a:url . '" &')
  endif
endfunction

function! s:make_header_args(headdata, option, quote)
  let args = ''
  for key in keys(a:headdata)
    unlet! value
    let value = type(a:headdata[key]) == type('') || type(a:headdata[key]) == type(0) ? a:headdata[key] :
          \     type(a:headdata[key]) == type({}) ? '' :
          \     type(a:headdata[key]) == type([]) ? '[' . join(map(a:headdata[key], 's:make_header_args(v:val, a:option, a:quote)'), ',') . ']' : ''
    if has('win16') || has('win32') || has('win64') || has('win95')
      let value = substitute(value, '"', '"""', 'g')
    endif
    let args .= ' ' . a:option . a:quote . key . ': ' . value . a:quote
  endfor
  return args
endfunction

function! s:decodeURI(str)
  let ret = a:str
  let ret = substitute(ret, '+', ' ', 'g')
  let ret = substitute(ret, '%\(\x\x\)', '\=printf("%c", str2nr(submatch(1), 16))', 'g')
  return ret
endfunction

function! s:escape(str)
  return substitute(a:str, '[^a-zA-Z0-9_.-]', '\=printf("%%%02X", char2nr(submatch(0)))', 'g')
endfunction

function! s:encodeURI(items)
  let ret = ''
  if type(a:items) == type({})
    for key in sort(keys(a:items))
      if strlen(ret)
        let ret .= "&"
      endif
      let ret .= key . "=" . s:encodeURI(a:items[key])
    endfor
  elseif type(a:items) == type([])
    for item in sort(a:items)
      if strlen(ret)
        let ret .= "&"
      endif
      let ret .= item
    endfor
  else
    let ret = s:escape(a:items)
  endif
  return ret
endfunction

function! s:postdata(data)
  if type(a:data) == type({})
    return [s:encodeURI(a:data)]
  elseif type(a:data) == type([])
    return a:data
  else
    return split(a:data, "\n")
  endif
endfunction

function! s:_quote()
  return &shellxquote == '"' ?  "'" : '"'
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
