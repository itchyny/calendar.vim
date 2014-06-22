" =============================================================================
" Filename: autoload/calendar/google/client.vim
" Author: itchyny
" License: MIT License
" Last Change: 2014/06/12 22:36:02.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

let s:cache = calendar#cache#new('google')

let s:shortener = calendar#google#url_shortener#new()

let s:auth_url = 'https://accounts.google.com/o/oauth2/auth'

let s:token_url = 'https://accounts.google.com/o/oauth2/token'

function! s:client()
  return extend(deepcopy(calendar#setting#get('google_client')), { 'response_type': 'code' })
endfunction

function! s:get_url()
  let client = s:client()
  let param = {}
  for x in ['client_id', 'redirect_uri', 'scope', 'response_type']
    if has_key(client, x)
      let param[x] = client[x]
    endif
  endfor
  return s:auth_url . '?' . calendar#webapi#encodeURI(param)
endfunction

function! calendar#google#client#access_token_response(response, content)
  if a:response.status == 200
    if !has_key(a:content, 'access_token')
      call calendar#echo#error_message('google_access_token_fail')
      return 1
    else
      silent! call s:cache.save('access_token', a:content)
      if has_key(a:content, 'refresh_token') && type(a:content.refresh_token) == type('')
        silent! call s:cache.save('refresh_token', { 'refresh_token': a:content.refresh_token })
      endif
    endif
  else
    call calendar#echo#error_message('google_access_token_fail')
    return 1
  endif
endfunction

let s:access_token_check = 0
function! calendar#google#client#access_token()
  let cache = s:cache.get('access_token')
  if type(cache) != type({}) || type(cache) == type({}) && !has_key(cache, 'access_token')
    if !s:access_token_check
      let s:access_token_check = 1
      call calendar#async#new('calendar#google#client#access_token_async()')
    endif
    return 1
  else
    let content = cache
  endif
  let s:access_token_check = 0
  return content.access_token
endfunction

function! calendar#google#client#access_token_async()
  let client = s:client()
  let url = s:get_url()
  let _url = url
  let short_url = s:shortener.shorten(url)
  if type(short_url) == type('')
    let url = short_url
  endif
  call calendar#webapi#open_url(url)
  try
    let code = input(printf(calendar#message#get('access_url_input_code'), url) . "\n" . calendar#message#get('input_code'))
  catch
    return
  endtry
  if code !=# ''
    let response = calendar#webapi#post_nojson(s:token_url, {}, {
          \ 'client_id': client.client_id,
          \ 'client_secret': client.client_secret,
          \ 'code': code,
          \ 'redirect_uri': client.redirect_uri,
          \ 'grant_type': 'authorization_code'})
    let content = calendar#webapi#decode(response.content)
    if calendar#google#client#access_token_response(response, content)
      return
    endif
  else
    return
  endif
  let g:calendar_google_event_downloading_list = 0
  let g:calendar_google_event_download = 3
  silent! let b:calendar.event._updated = 3
  silent! call b:calendar.update()
endfunction

function! calendar#google#client#get(url, ...)
  return s:request('get', a:url, a:0 ? a:1 : {}, a:0 > 1 ? a:2 : {})
endfunction

function! calendar#google#client#put(url, ...)
  return s:request('put', a:url, a:0 ? a:1 : {}, a:0 > 1 ? a:2 : {})
endfunction

function! calendar#google#client#post(url, ...)
  return s:request('post', a:url, a:0 ? a:1 : {}, a:0 > 1 ? a:2 : {})
endfunction

function! calendar#google#client#delete(url, ...)
  return s:request('delete', a:url, a:0 ? a:1 : {}, a:0 > 1 ? a:2 : {})
endfunction

function! s:request(method, url, param, body)
  let client = s:client()
  let access_token = calendar#google#client#access_token()
  if type(access_token) != type('')
    return 1
  endif
  let param = extend(a:param, { 'oauth_token': access_token })
  let response = calendar#webapi#{a:method}(a:url, param, a:body)
  if response.status == 200
    return calendar#webapi#decode(response.content)
  elseif response.status == 401
    let cache = s:cache.get('refresh_token')
    if has_key(cache, 'refresh_token') && type(cache.refresh_token) == type('')
      let response = calendar#webapi#post_nojson(s:token_url, {}, {
            \ 'client_id': client.client_id,
            \ 'client_secret': client.client_secret,
            \ 'refresh_token': cache.refresh_token,
            \ 'grant_type': 'refresh_token'})
      let content = calendar#webapi#decode(response.content)
      if calendar#google#client#access_token_response(response, content)
        return 1
      endif
      let param = extend(param, { 'oauth_token': content.access_token })
      let response = calendar#webapi#{a:method}(a:url, param, a:body)
      if response.status == 200
        return calendar#webapi#decode(response.content)
      endif
    endif
  else
    return 1
  endif
endfunction

function! calendar#google#client#refresh_token()
  let client = s:client()
  let cache = s:cache.get('refresh_token')
  if type(cache) == type({}) && has_key(cache, 'refresh_token') && type(cache.refresh_token) == type('')
    let response = calendar#webapi#post_nojson(s:token_url, {}, {
          \ 'client_id': client.client_id,
          \ 'client_secret': client.client_secret,
          \ 'refresh_token': cache.refresh_token,
          \ 'grant_type': 'refresh_token'})
    let content = calendar#webapi#decode(response.content)
    if calendar#google#client#access_token_response(response, content)
      return 1
    endif
  endif
endfunction

function! calendar#google#client#get_async(id, cb, url, ...)
  call s:request_async(a:id, a:cb, 'get', a:url, a:0 ? a:1 : {}, a:0 > 1 ? a:2 : {})
endfunction

function! calendar#google#client#delete_async(id, cb, url, ...)
  call s:request_async(a:id, a:cb, 'delete', a:url, a:0 ? a:1 : {}, a:0 > 1 ? a:2 : {})
endfunction

function! calendar#google#client#put_async(id, cb, url, ...)
  call s:request_async(a:id, a:cb, 'put', a:url, a:0 ? a:1 : {}, a:0 > 1 ? a:2 : {})
endfunction

function! calendar#google#client#patch_async(id, cb, url, ...)
  call s:request_async(a:id, a:cb, 'patch', a:url, a:0 ? a:1 : {}, a:0 > 1 ? a:2 : {})
endfunction

function! calendar#google#client#post_async(id, cb, url, ...)
  call s:request_async(a:id, a:cb, 'post', a:url, a:0 ? a:1 : {}, a:0 > 1 ? a:2 : {})
endfunction

function! s:request_async(id, cb, method, url, param, body)
  let access_token = calendar#google#client#access_token()
  if type(access_token) != type('')
    return 1
  endif
  let param = extend(a:param, { 'oauth_token': access_token })
  call calendar#webapi#{a:method}_async(a:id, a:cb, a:url, param, a:body)
endfunction

function! calendar#google#client#get_async_use_api_key(id, cb, url, ...)
  call s:request_async_use_api_key(a:id, a:cb, 'get', a:url, a:0 ? a:1 : {}, a:0 > 1 ? a:2 : {})
endfunction

function! calendar#google#client#post_async_use_api_key(id, cb, url, ...)
  call s:request_async_use_api_key(a:id, a:cb, 'post', a:url, a:0 ? a:1 : {}, a:0 > 1 ? a:2 : {})
endfunction

function! s:request_async_use_api_key(id, cb, method, url, param, body)
  let client = s:client()
  let param = extend(a:param, { 'key': client.api_key })
  call calendar#webapi#{a:method}_async(a:id, a:cb, a:url, param, a:body)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
