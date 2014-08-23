" =============================================================================
" Filename: autoload/calendar/task/local.vim
" Author: itchyny
" License: MIT License
" Last Change: 2014/08/23 08:27:26.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

function! calendar#task#local#new()
  return deepcopy(s:self)
endfunction

let s:cache = calendar#cache#new('local')

let s:task_cache = s:cache.new('task')

let s:self = {}

function! s:self.get_taskList() dict
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
endfunction

function! s:self.get_task() dict
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
  let self.localtask = task
  return task
endfunction

function! s:self.insert(listid, previous, title, ...) dict
  let k = self.get_tasklist_index(a:listid)
  if k >= 0
    let j = self.get_index(k, a:previous) + 1
    call insert(self.localtask[k].items, { 'title': a:title, 'id': calendar#util#id() }, j)
    silent! call self.save()
  endif
endfunction

function! s:self.move(listid, taskid, previous) dict
  let k = self.get_tasklist_index(a:listid)
  if k >= 0
    let j = self.get_index(k, a:taskid)
    let pj = a:previous ==# '' ? 0 : self.get_index(k, a:previous)
    if j >= 0 && pj >= 0
      let task = deepcopy(self.localtask[k].items[j])
      call remove(self.localtask[k].items, j)
      let pj = a:previous ==# '' ? -1 : self.get_index(k, a:previous)
      call insert(self.localtask[k].items, task, pj + 1)
      silent! call self.save()
    endif
  endif
endfunction

function! s:self.update(listid, taskid, title, ...) dict
  let k = self.get_tasklist_index(a:listid)
  if k >= 0
    let j = self.get_index(k, a:taskid)
    if j >= 0
      call extend(self.localtask[k].items[j], { 'title': a:title })
      silent! call self.save()
    endif
  endif
endfunction

function! s:self.complete(listid, taskid) dict
  let k = self.get_tasklist_index(a:listid)
  if k >= 0
    let j = self.get_index(k, a:taskid)
    if j >= 0
      call extend(self.localtask[0].items[j], { 'status': 'completed' })
      silent! call self.save()
    endif
  endif
endfunction

function! s:self.uncomplete(listid, taskid) dict
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
endfunction

function! s:self.clear_completed(listid) dict
  if has_key(self, 'localtask')
    for task in self.localtask
      call filter(task.items, 'get(v:val, "status", "") !=# "completed"')
    endfor
    silent! call self.save()
  endif
endfunction

function! s:self.save() dict
  if has_key(self, 'localtask')
    for task in self.localtask
      silent! call s:task_cache.new(task.id).save(0, task)
      silent! call s:task_cache.new(task.id).save('information', { 'id': task.id, 'title': task.title })
    endfor
  endif
endfunction

function! s:self.get_tasklist_index(id) dict
  if has_key(self, 'localtask')
    let j = -1
    for i in range(len(self.localtask))
      if self.localtask[i].id ==# a:id
        let j = i
        break
      endif
    endfor
    if j < 0 && len(self.localtask)
      return 0
    endif
    return j
  endif
  return -1
endfunction

function! s:self.get_index(listindex, id) dict
  if has_key(self, 'localtask')
    if 0 <= a:listindex && a:listindex < len(self.localtask)
      let j = -1
      for i in range(len(self.localtask[a:listindex].items))
        if self.localtask[0].items[i].id ==# a:id
          let j = i
          break
        endif
      endfor
      return j
    endif
  endif
  return -1
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
