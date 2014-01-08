" =============================================================================
" Filename: autoload/calendar/google/task.vim
" Author: itchyny
" License: MIT License
" Last Change: 2014/01/08 15:18:05.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

let s:cache = calendar#cache#new('google')

let s:task_cache = s:cache.new('task')

function! calendar#google#task#get_url(type)
  return 'https://www.googleapis.com/tasks/v1/' . a:type
endfunction

function! calendar#google#task#getTaskList()
  let taskList = s:cache.get('taskList')
  if type(taskList) != type({})
    call calendar#google#client#get_async(s:newid(['taskList', 0]),
          \ 'calendar#google#task#getTaskList_response',
          \ calendar#google#task#get_url('users/@me/lists'))
    return {}
  else
    return taskList
  endif
endfunction

function! calendar#google#task#getTaskList_response(id, response)
  let [_tasklist, err; rest] = s:getdata(a:id)
  if a:response.status =~# '^2'
    let cnt = calendar#webapi#decode(a:response.content)
    let content = type(cnt) == type({}) ? cnt : {}
    if has_key(content, 'items') && type(content.items) == type([])
      silent! call s:cache.save('taskList', content)
      silent! let b:calendar.task._updated = 1
      silent! call b:calendar.update()
    endif
  elseif a:response.status == 401
    if err == 0
      call calendar#google#client#refresh_token()
      call calendar#google#client#get_async(s:newid(['taskList', err + 1]),
            \ 'calendar#google#task#getTaskList_response',
            \ calendar#google#task#get_url('users/@me/lists'))
    endif
  endif
endfunction

let s:task = []
let s:initial_download = 0
function! calendar#google#task#getTasks()
  if !s:initial_download
    let s:initial_download = 1
    if calendar#timestamp#update('google#task.vim', 1, 60 * 60)
      call calendar#async#new('calendar#google#task#downloadTasks(1)')
    endif
  endif
  let task = []
  let taskList = calendar#google#task#getTaskList()
  let flg = 1
  if has_key(taskList, 'items') && type(taskList.items) == type([])
    for item in taskList.items
      call add(task, deepcopy(item))
      let task[-1].items = []
      unlet! cnt
      let cnt = s:task_cache.new(item.id).get('information')
      if type(cnt) == type({}) && cnt != {}
        if flg && get(get(s:task, len(task) - 1, {}), 'etag', '') ==# get(cnt, 'etag', ',')
          break
        endif
        let flg = 0
        let i = 0
        let task[-1].etag = cnt.etag
        while type(cnt) == type({})
          unlet! cnt
          let cnt = s:task_cache.new(item.id).get(i)
          if type(cnt) == type({}) && cnt != {} && has_key(cnt, 'items') && type(cnt.items) == type([])
            call extend(task[-1].items, deepcopy(cnt.items))
          endif
          let i += 1
        endwhile
      else
        call calendar#google#task#downloadTasks()
      endif
    endfor
  endif
  if !flg
    let s:task = task
  endif
  return s:task
endfunction

" Optional argument: Force download.
function! calendar#google#task#downloadTasks(...)
  let taskList = calendar#google#task#getTaskList()
  if has_key(taskList, 'items') && type(taskList.items) == type([]) && len(taskList.items)
    let j = 0
    while j < len(taskList.items)
      let item = taskList.items[j]
      unlet! cnt
      let cnt = s:task_cache.new(item.id).get('information')
      if type(cnt) != type({}) || cnt == {} || get(a:000, 0)
        let opt = { 'tasklist': item.id }
        call calendar#google#client#get_async(s:newid(['download', 0, 0, 0, item.id]),
              \ 'calendar#google#task#response',
              \ calendar#google#task#get_url('lists/' . item.id . '/tasks'), opt)
        break
      endif
      let j += 1
    endwhile
    if j == len(taskList.items)
      silent! let b:calendar.task._updated = 1
      silent! call b:calendar.update()
    endif
  endif
endfunction

function! calendar#google#task#response(id, response)
  let taskList = calendar#google#task#getTaskList()
  let [_download, err, j, i, id; rest] = s:getdata(a:id)
  let opt = { 'tasklist': id }
  if a:response.status =~# '^2'
    let cnt = calendar#webapi#decode(a:response.content)
    let content = type(cnt) == type({}) ? cnt : {}
    if has_key(content, 'items')
      silent! call s:task_cache.new(id).save(i, content)
      if i == 0
        call remove(content, 'items')
        silent! call s:task_cache.new(id).save('information', content)
      endif
      if has_key(content, 'nextPageToken')
        let opt = extend(opt, { 'pageToken': content.nextPageToken })
        call calendar#google#client#get_async(s:newid(['download', err, j, i + 1, id]),
              \ 'calendar#google#task#response',
              \ calendar#google#task#get_url('lists/' . id . '/tasks'), opt)
      else
        let j += 1
        while j < len(taskList.items)
          let item = taskList.items[j]
          unlet! cnt
          let cnt = s:task_cache.new(item.id).get('information')
          if type(cnt) != type({}) || cnt == {}
            call calendar#google#client#get_async(s:newid(['download', 0, j, 0, item.id]),
                  \ 'calendar#google#task#response',
                  \ calendar#google#task#get_url('lists/' . item.id . '/tasks'), opt)
            break
          endif
          let j += 1
        endwhile
        if j == len(taskList.items)
          silent! let b:calendar.task._updated = 1
          silent! call b:calendar.update()
        endif
      endif
    endif
  elseif a:response.status == 401
    if i == 0 && err == 0
      call calendar#google#client#refresh_token()
      call calendar#google#client#get_async(s:newid(['download', err + 1, j, i, id]),
            \ 'calendar#google#task#response',
            \ calendar#google#task#get_url('lists/' . id . '/tasks'), opt)
    endif
  endif
endfunction

function! calendar#google#task#insert(id, previous, title)
  call calendar#google#client#post_async(s:newid(['insert', 0, a:id, a:title]),
        \ 'calendar#google#task#insert_response',
        \ calendar#google#task#get_url('lists/' . a:id . '/tasks'),
        \ extend({ 'tasklist': a:id }, a:previous !=# '' ? { 'previous': a:previous } : {}),
        \ { 'title': a:title })
endfunction

function! calendar#google#task#insert_response(id, response)
  let [_insert, err, id, title; rest] = s:getdata(a:id)
  if a:response.status =~# '^2'
    call calendar#google#task#downloadTasks(1)
  elseif a:response.status == 401
    if err == 0
      call calendar#google#client#refresh_token()
      call calendar#google#client#post_async(s:newid(['insert', 1, id, title]),
            \ 'calendar#google#task#insert_response',
            \ calendar#google#task#get_url('lists/' . id . '/tasks'),
            \ { 'tasklist': id }, { 'title': title })
    endif
  endif
endfunction

function! calendar#google#task#clear_completed(id)
  call calendar#google#client#post_async(s:newid(['clear_completed', 0, a:id]),
        \ 'calendar#google#task#clear_completed_response',
        \ calendar#google#task#get_url('lists/' . a:id . '/clear'),
        \ { 'tasklist': a:id })
endfunction

function! calendar#google#task#clear_completed_response(id, response)
  let [_clear_completed, err, id; rest] = s:getdata(a:id)
  if a:response.status =~# '^2'
    call calendar#google#task#downloadTasks(1)
  elseif a:response.status == 401
    if err == 0
      call calendar#google#client#refresh_token()
      call calendar#google#client#post_async(s:newid(['clear_completed', 1, id]),
            \ 'calendar#google#task#clear_completed_response',
            \ calendar#google#task#get_url('lists/' . id . '/clear'),
            \ { 'tasklist': id })
    endif
  endif
endfunction

function! calendar#google#task#update(id, taskid, title)
  call calendar#google#client#put_async(s:newid(['update', 0, a:id, a:taskid, a:title]),
        \ 'calendar#google#task#update_response',
        \ calendar#google#task#get_url('lists/' . a:id . '/tasks/' . a:taskid),
        \ { 'tasklist': a:id, 'task': a:taskid },
        \ { 'id': a:taskid, 'title': a:title })
endfunction

function! calendar#google#task#update_response(id, response)
  let [_update, err, id, taskid, title; rest] = s:getdata(a:id)
  if a:response.status =~# '^2'
    call calendar#google#task#downloadTasks(1)
  elseif a:response.status == 401
    if err == 0
      call calendar#google#client#refresh_token()
      call calendar#google#client#put_async(s:newid(['update', 1, id, taskid]),
            \ 'calendar#google#task#update_response',
            \ calendar#google#task#get_url('lists/' . id . '/tasks/' . taskid),
            \ { 'tasklist': id, 'task': taskid },
            \ { 'id': taskid, 'title': title })
    endif
  endif
endfunction

function! calendar#google#task#complete(id, taskid)
  call calendar#google#client#put_async(s:newid(['complete', 0, a:id, a:taskid]),
        \ 'calendar#google#task#complete_response',
        \ calendar#google#task#get_url('lists/' . a:id . '/tasks/' . a:taskid),
        \ { 'tasklist': a:id, 'task': a:taskid },
        \ { 'id': a:taskid, 'status': 'completed' })
endfunction

function! calendar#google#task#complete_response(id, response)
  let [_complete, err, id, taskid; rest] = s:getdata(a:id)
  if a:response.status =~# '^2'
    call calendar#google#task#downloadTasks(1)
  elseif a:response.status == 401
    if err == 0
      call calendar#google#client#refresh_token()
      call calendar#google#client#put_async(s:newid(['complete', 1, id, taskid]),
            \ 'calendar#google#task#complete_response',
            \ calendar#google#task#get_url('lists/' . id . '/tasks/' . taskid),
            \ { 'tasklist': id, 'task': taskid },
            \ { 'id': taskid, 'status': 'completed' })
    endif
  endif
endfunction

function! calendar#google#task#uncomplete(id, taskid)
  call calendar#google#client#put_async(s:newid(['uncomplete', 0, a:id, a:taskid]),
        \ 'calendar#google#task#uncomplete_response',
        \ calendar#google#task#get_url('lists/' . a:id . '/tasks/' . a:taskid),
        \ { 'tasklist': a:id, 'task': a:taskid },
        \ { 'id': a:taskid, 'status': 'needsAction' })
endfunction

function! calendar#google#task#uncomplete_response(id, response)
  let [_uncomplete, err, id, taskid; rest] = s:getdata(a:id)
  if a:response.status =~# '^2'
    call calendar#google#task#downloadTasks(1)
  elseif a:response.status == 401
    if err == 0
      call calendar#google#client#refresh_token()
      call calendar#google#client#put_async(s:newid(['uncomplete', 1, id, taskid]),
            \ 'calendar#google#task#uncomplete_response',
            \ calendar#google#task#get_url('lists/' . id . '/tasks/' . taskid),
            \ { 'tasklist': id, 'task': taskid },
            \ { 'id': taskid, 'status': 'needsAction' })
    endif
  endif
endfunction

let s:id_data = {}
function! s:newid(data)
  let id = join([ 'google', 'task', a:data[0] ], '_') . calendar#util#id()
  let s:id_data[id] = a:data
  return id
endfunction

function! s:getdata(id)
  return s:id_data[a:id]
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
