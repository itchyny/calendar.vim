" =============================================================================
" Filename: autoload/calendar/google/task.vim
" Author: itchyny
" License: MIT License
" Last Change: 2015/03/29 06:30:30.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

let s:cache = calendar#cache#new('google')

let s:task_cache = s:cache.new('task')

function! calendar#google#task#get_url(type) abort
  return 'https://www.googleapis.com/tasks/v1/' . a:type
endfunction

function! calendar#google#task#getTaskList() abort
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

function! calendar#google#task#getTaskList_response(id, response) abort
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
function! calendar#google#task#getTasks() abort
  if calendar#timestamp#update('google_task', 3 * 60 * 60)
    call calendar#async#new('calendar#google#task#downloadTasks(1)')
  endif
  let task = []
  let taskList = calendar#google#task#getTaskList()
  let flg = 1
  if has_key(taskList, 'items') && type(taskList.items) == type([])
    for tasklist in taskList.items
      call add(task, deepcopy(tasklist))
      let task[-1].items = []
      unlet! cnt
      let cnt = s:task_cache.new(tasklist.id).get('information')
      if type(cnt) == type({}) && cnt != {}
        " if flg && get(get(s:task, len(task) - 1, {}), 'etag', '') ==# get(cnt, 'etag', ',')
        "   echo [get(get(s:task, len(task) - 1, {}), 'etag', '') , get(cnt, 'etag', ',')]
        "   break
        " endif
        let flg = 0
        let i = 0
        let task[-1].etag = cnt.etag
        while type(cnt) == type({})
          unlet! cnt
          let cnt = s:task_cache.new(tasklist.id).get(i)
          if type(cnt) == type({}) && cnt != {} && has_key(cnt, 'items') && type(cnt.items) == type([])
            call extend(task[-1].items, deepcopy(cnt.items))
            for item in task[-1].items
              if has_key(item, 'due') && item.due =~# '\d\+-\d\+-\d\+T'
                let [y, m, d] = map(split(substitute(substitute(item.due, 'T.*', '', ''), '\s', '', 'g'), '[-/]'), 'substitute(v:val, "^0", "", "") + 0')
                let ty = calendar#day#today().get_year()
                let due = calendar#day#join_date(ty == y ? [m, d] : [y, m, d])
                let item.title = due . ' ' . get(item, 'title', '')
              endif
              if has_key(item, 'notes') && item.notes !=# ''
                let item.title = get(item, 'title', '') . ' note: ' . get(item, 'notes', '')
              endif
            endfor
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
function! calendar#google#task#downloadTasks(...) abort
  let taskList = calendar#google#task#getTaskList()
  if has_key(taskList, 'items') && type(taskList.items) == type([]) && len(taskList.items)
    let j = 0
    while j < len(taskList.items)
      let item = taskList.items[j]
      unlet! cnt
      let cnt = s:task_cache.new(item.id).get('information')
      if type(cnt) != type({}) || cnt == {} || get(a:000, 0) && (a:0 <= 1 || item.id ==# get(a:000, 1, ''))
        let opt = { 'tasklist': item.id }
        call calendar#google#client#get_async(s:newid(['download', 0, j, 0, item.id, a:000]),
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

function! calendar#google#task#response(id, response) abort
  let taskList = calendar#google#task#getTaskList()
  let [_download, err, j, i, id, force; rest] = s:getdata(a:id)
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
        call calendar#google#client#get_async(s:newid(['download', err, j, i + 1, id, force]),
              \ 'calendar#google#task#response',
              \ calendar#google#task#get_url('lists/' . id . '/tasks'), opt)
      else
        let k = i + 1
        while filereadable(s:task_cache.new(id).path(k))
          silent! call s:task_cache.new(id).delete(k)
          let k += 1
        endwhile
        let j += 1
        while j < len(taskList.items)
          let item = taskList.items[j]
          unlet! cnt
          let cnt = s:task_cache.new(item.id).get('information')
          let opt = { 'tasklist': item.id }
          if type(cnt) != type({}) || cnt == {} || get(force, 0) && (len(force) <= 1 || item.id ==# get(force, 1, ''))
            call calendar#google#client#get_async(s:newid(['download', 0, j, 0, item.id, force]),
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
      let opt = { 'tasklist': id }
      call calendar#google#client#refresh_token()
      call calendar#google#client#get_async(s:newid(['download', err + 1, j, i, id, force]),
            \ 'calendar#google#task#response',
            \ calendar#google#task#get_url('lists/' . id . '/tasks'), opt)
    endif
  endif
endfunction

function! calendar#google#task#insert(id, previous, title, ...) abort
  let opt = extend({ 'tasklist': a:id }, a:previous !=# '' ? { 'previous': a:previous } : {})
  let due = ''
  if a:0
    let due = get(a:1, 'due', '')
    if due !=# ''
      let due = due . (due =~# 'Z$' ? '' : 'Z')
    endif
  endif
  let note = ''
  if a:title =~# ' note: '
    let note = matchstr(a:title, ' note: .*$')
    let title = a:title[:(len(a:title) - len(note)) - 1]
    let note = substitute(note, ' note:\s*', '', '')
  else
    let note = ''
    let title = a:title
  endif
  call calendar#google#client#post_async(s:newid(['insert', 0, a:id, title, note, due, opt]),
        \ 'calendar#google#task#insert_response',
        \ calendar#google#task#get_url('lists/' . a:id . '/tasks'),
        \ opt, extend({ 'title': title, 'notes': note }, due ==# '' ? {} : { 'due': due ==# '-1Z' ? function('calendar#webapi#null') : due }))
endfunction

function! calendar#google#task#insert_response(id, response) abort
  let [_insert, err, id, title, note, due, opt; rest] = s:getdata(a:id)
  if a:response.status =~# '^2'
    call calendar#google#task#downloadTasks(1, id)
  elseif a:response.status == 401
    if err == 0
      call calendar#google#client#refresh_token()
      call calendar#google#client#post_async(s:newid(['insert', 1, id, title, note, due, opt]),
            \ 'calendar#google#task#insert_response',
            \ calendar#google#task#get_url('lists/' . id . '/tasks'),
            \ opt, extend({ 'title': title, 'notes': note }, due ==# '' ? {} : { 'due': due ==# '-1Z' ? function('calendar#webapi#null') : due }))
    endif
  endif
endfunction

function! calendar#google#task#move(id, taskid, previous) abort
  let opt = extend({ 'tasklist': a:id }, a:previous !=# '' ? { 'previous': a:previous } : {})
  call calendar#google#client#post_async(s:newid(['move', 0, a:id, a:taskid, opt]),
        \ 'calendar#google#task#move_response',
        \ calendar#google#task#get_url('lists/' . a:id . '/tasks/' . a:taskid . '/move'),
        \ opt, {})
endfunction

function! calendar#google#task#move_response(id, response) abort
  let [_move, err, id, taskid, opt; rest] = s:getdata(a:id)
  if a:response.status =~# '^2'
    call calendar#google#task#downloadTasks(1, id)
  elseif a:response.status == 401
    if err == 0
      call calendar#google#client#refresh_token()
      call calendar#google#client#post_async(s:newid(['move', 1, id, taskid, opt]),
            \ 'calendar#google#task#move_response',
            \ calendar#google#task#get_url('lists/' . id . '/tasks/' . taskid . '/move'),
            \ opt, {})
    endif
  endif
endfunction

function! calendar#google#task#clear_completed(id) abort
  call calendar#google#client#post_async(s:newid(['clear_completed', 0, a:id]),
        \ 'calendar#google#task#clear_completed_response',
        \ calendar#google#task#get_url('lists/' . a:id . '/clear'),
        \ { 'tasklist': a:id })
endfunction

function! calendar#google#task#clear_completed_response(id, response) abort
  let [_clear_completed, err, id; rest] = s:getdata(a:id)
  if a:response.status =~# '^2'
    call calendar#google#task#downloadTasks(1, id)
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

function! calendar#google#task#update(id, taskid, title, ...) abort
  let due = ''
  if a:0
    let due = get(a:1, 'due', '')
    if due !=# ''
      let due = due . (due =~# 'Z$' ? '' : 'Z')
    endif
  endif
  let note = ''
  if a:title =~# ' note: '
    let note = matchstr(a:title, ' note: .*$')
    let title = a:title[:(len(a:title) - len(note)) - 1]
    let note = substitute(note, ' note:\s*', '', '')
  else
    let note = ''
    let title = a:title
  endif
  call calendar#google#client#put_async(s:newid(['update', 0, a:id, a:taskid, title, note, due]),
        \ 'calendar#google#task#update_response',
        \ calendar#google#task#get_url('lists/' . a:id . '/tasks/' . a:taskid),
        \ { 'tasklist': a:id, 'task': a:taskid },
        \ extend({ 'id': a:taskid, 'title': title, 'notes': note }, due ==# '' ? {} : { 'due': due ==# '-1Z' ? function('calendar#webapi#null') : due }))
endfunction

function! calendar#google#task#update_response(id, response) abort
  let [_update, err, id, taskid, title, note, due; rest] = s:getdata(a:id)
  if a:response.status =~# '^2'
    call calendar#google#task#downloadTasks(1, id)
  elseif a:response.status == 401
    if err == 0
      call calendar#google#client#refresh_token()
      call calendar#google#client#put_async(s:newid(['update', 1, id, taskid, title, note, due]),
            \ 'calendar#google#task#update_response',
            \ calendar#google#task#get_url('lists/' . id . '/tasks/' . taskid),
            \ { 'tasklist': id, 'task': taskid },
            \ extend({ 'id': taskid, 'title': title, 'notes': note }, due ==# '' ? {} : { 'due': due ==# '-1Z' ? function('calendar#webapi#null') : due }))
    endif
  endif
endfunction

function! calendar#google#task#complete(id, taskid) abort
  call calendar#google#client#put_async(s:newid(['complete', 0, a:id, a:taskid]),
        \ 'calendar#google#task#complete_response',
        \ calendar#google#task#get_url('lists/' . a:id . '/tasks/' . a:taskid),
        \ { 'tasklist': a:id, 'task': a:taskid },
        \ { 'id': a:taskid, 'status': 'completed' })
endfunction

function! calendar#google#task#complete_response(id, response) abort
  let [_complete, err, id, taskid; rest] = s:getdata(a:id)
  if a:response.status =~# '^2'
    call calendar#google#task#downloadTasks(1, id)
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

function! calendar#google#task#uncomplete(id, taskid) abort
  call calendar#google#client#put_async(s:newid(['uncomplete', 0, a:id, a:taskid]),
        \ 'calendar#google#task#uncomplete_response',
        \ calendar#google#task#get_url('lists/' . a:id . '/tasks/' . a:taskid),
        \ { 'tasklist': a:id, 'task': a:taskid },
        \ { 'id': a:taskid, 'status': 'needsAction' })
endfunction

function! calendar#google#task#uncomplete_response(id, response) abort
  let [_uncomplete, err, id, taskid; rest] = s:getdata(a:id)
  if a:response.status =~# '^2'
    call calendar#google#task#downloadTasks(1, id)
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
function! s:newid(data) abort
  let id = join([ 'google', 'task', a:data[0] ], '_') . '_' . calendar#util#id()
  let s:id_data[id] = a:data
  return id
endfunction

function! s:getdata(id) abort
  return s:id_data[a:id]
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
