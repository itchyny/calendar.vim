" =============================================================================
" Filename: autoload/calendar/view/task.vim
" Author: itchyny
" License: MIT License
" Last Change: 2014/01/08 15:38:51.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

function! calendar#view#task#new(source)
  return s:constructor.new(a:source)
endfunction

let s:self = {}

let s:self._select_line = 1

function! s:self.get_key() dict
  return b:calendar.task.updated()
endfunction

function! s:self.get_raw_contents() dict
  return b:calendar.task.get_task()
endfunction

function! s:self.action(action) dict
  let task = self.current_contents()
  let taskid = get(task, 'id', '')
  let prevtask = self.prev_contents()
  let prevtaskid = get(prevtask, 'id', '')
  if index(['delete', 'delete_line'], a:action) >= 0
    call b:calendar.task.complete(self.current_group_id(), taskid)
  elseif index(['undo_line'], a:action) >= 0
    call b:calendar.task.uncomplete(self.current_group_id(), taskid)
  elseif index(['start_insert', 'start_insert_append', 'start_insert_head', 'start_insert_last', 'change', 'change_line'], a:action) >= 0
    if taskid !=# ''
      let head = index(['start_insert', 'start_insert_head'], a:action) >= 0
      let change = index(['change', 'change_line'], a:action) >= 0
      let msg = calendar#message#get('input_task') . (change ? get(task, 'title', '') . ' -> ' : '')
      let title = input(msg, change ? '' : get(task, 'title', '') . (head ? "\<Home>" : ''))
      if title !=# ''
        call b:calendar.task.update(self.current_group_id(), taskid, title)
      endif
    else
      return self.action('start_insert_next_line')
    endif
  elseif index(['start_insert_next_line', 'start_insert_prev_line'], a:action) >= 0
    let title = input(calendar#message#get('input_task'))
    if title !=# ''
      let next = a:action ==# 'start_insert_next_line'
      if next
        let self.select += 1
      endif
      call b:calendar.task.insert(self.current_group_id(), next ? taskid : prevtaskid, title)
    endif
  elseif a:action ==# 'clear'
    let title = input(calendar#message#get('clear_completed_task'))
    if title =~# '^[yY]\%[es]$'
      call b:calendar.task.clear_completed(self.current_group_id())
    endif
  else
    return self._action(a:action)
  endif
endfunction

let s:constructor = calendar#constructor#view_textbox#new(s:self)

let &cpo = s:save_cpo
unlet s:save_cpo
