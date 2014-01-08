" =============================================================================
" Filename: autoload/calendar/task.vim
" Author: itchyny
" License: MIT License
" Last Change: 2014/01/08 15:04:29.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

" Task controller.
" This object handles both local task and Google Task.
function! calendar#task#new()
  return copy(s:self)
endfunction

let s:cache = calendar#cache#new('local')

let s:task_cache = s:cache.new('task')

let s:self = {}

let s:self._updated = 0

function! s:self.updated() dict
  return [self._updated]
endfunction

function! s:self.get_taskList() dict
  if calendar#setting#get('google_task')
    return calendar#google#task#getTaskList()
  else
    if has_key(self, 'localtasklist')
      return self.localtasklist
    else
      let taskList = s:cache.get('taskList')
      if type(taskList) == type({}) && has_key(taskList, 'items') && type(taskList.items) == type([])
        let self.localtasklist = taskList
      else
        let self.localtasklist = { 'items': [{'id': calendar#util#id(), 'title': get(calendar#message#get('task'), 'title', 'Task')}] }
        silent! call s:cache.save('taskList', self.localtasklist)
      endif
    endif
    return self.localtasklist
  endif
endfunction

function! s:self.get_task() dict
  if calendar#setting#get('google_task')
    let self.task = self.get_google_task()
  else
    if has_key(self, 'localtask')
      let self.task = self.localtask
    else
      let self.task = self.get_local_task()
      let self.localtask = self.task
    endif
  endif
  let self._updated = 0
  return self.task
endfunction

function! s:self.get_google_task() dict
  if has_key(self, 'task') && !self._updated
    return self.task
  endif
  return calendar#google#task#getTasks()
endfunction

function! s:self.get_local_task() dict
  let taskList = self.get_taskList()
  let task = []
  if has_key(taskList, 'items') && type(taskList.items) == type([])
    for item in taskList.items
      call add(task, deepcopy(item))
      let task[-1].items = []
      unlet! cnt
      let cnt = s:task_cache.new(item.id).get('information')
      if type(cnt) == type({}) && cnt != {}
        let i = 0
        while type(cnt) == type({})
          unlet! cnt
          let cnt = s:task_cache.new(item.id).get(i)
          if type(cnt) == type({}) && cnt != {} && has_key(cnt, 'items') && type(cnt.items) == type([])
            call extend(task[-1].items, deepcopy(cnt.items))
          endif
          let i += 1
        endwhile
      endif
    endfor
  endif
  return task
endfunction

function! s:self.get_tasklist_index(id) dict
  if has_key(self, 'task') && !calendar#setting#get('google_task')
    let j = -1
    for i in range(len(self.task))
      if self.task[i].id ==# a:id
        let j = i
        break
      endif
    endfor
    if len(self.task)
      return 0
    endif
    return j
  endif
  return -1
endfunction

function! s:self.get_index(listindex, id) dict
  if has_key(self, 'task') && !calendar#setting#get('google_task')
    if a:listindex >= 0
      let j = -1
      for i in range(len(self.task[a:listindex].items))
        if self.task[0].items[i].id ==# a:id
          let j = i
          break
        endif
      endfor
      return j
    endif
  endif
  return -1
endfunction

function! s:self.insert(listid, previous, title) dict
  if !has_key(self, 'task')
    call self.get_task()
  endif
  let self._updated = 1
  if calendar#setting#get('google_task')
    call calendar#google#task#insert(a:listid, a:previous, a:title)
  else
    let k = self.get_tasklist_index(a:listid)
    if k >= 0
      let j = self.get_index(k, a:previous) + 1
      call insert(self.localtask[k].items, { 'title': a:title, 'id': calendar#util#id() }, j)
      silent! call self.save()
    endif
  endif
endfunction

function! s:self.update(listid, taskid, title) dict
  if !has_key(self, 'task')
    call self.get_task()
  endif
  let self._updated = 1
  if calendar#setting#get('google_task')
    call calendar#google#task#update(a:listid, a:taskid, a:title)
  else
    let k = self.get_tasklist_index(a:listid)
    if k >= 0
      let j = self.get_index(k, a:taskid)
      if j >= 0
        call extend(self.localtask[k].items[j], { 'title': a:title })
        silent! call self.save()
      endif
    endif
  endif
endfunction

function! s:self.complete(listid, taskid) dict
  if !has_key(self, 'task')
    call self.get_task()
  endif
  let self._updated = 1
  if calendar#setting#get('google_task')
    call calendar#google#task#complete(a:listid, a:taskid)
  else
    let k = self.get_tasklist_index(a:listid)
    if k >= 0
      let j = self.get_index(k, a:taskid)
      if j >= 0
        call extend(self.localtask[0].items[j], { 'status': 'completed' })
        silent! call self.save()
      endif
    endif
  endif
endfunction

function! s:self.uncomplete(listid, taskid) dict
  if !has_key(self, 'task')
    call self.get_task()
  endif
  let self._updated = 1
  if calendar#setting#get('google_task')
    call calendar#google#task#uncomplete(a:listid, a:taskid)
  else
    let k = self.get_tasklist_index(a:listid)
    if k >= 0
      let j = self.get_index(k, a:taskid)
      if j >= 0
        if has_key(self.localtask[0].items[j], 'status')
          call remove(self.localtask[0].items[j], 'status')
        endif
        silent! call self.save()
      endif
    endif
  endif
endfunction

function! s:self.clear_completed(listid) dict
  if !has_key(self, 'task')
    call self.get_task()
  endif
  let self._updated = 1
  if calendar#setting#get('google_task')
    call calendar#google#task#clear_completed(a:listid)
  else
    if has_key(self, 'localtask')
      for task in self.localtask
        call filter(task.items, 'get(v:val, "status", "") !=# "completed"')
      endfor
      silent! call self.save()
    endif
  endif
endfunction

function! s:self.save() dict
  if calendar#setting#get('google_task')
  else
    if has_key(self, 'localtask')
      for task in self.localtask
        silent! call s:task_cache.new(task.id).save(0, task)
        silent! call s:task_cache.new(task.id).save('information', { 'id': task.id, 'title': task.title })
      endfor
    endif
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
