" =============================================================================
" Filename: autoload/calendar/view/task.vim
" Author: itchyny
" License: MIT License
" Last Change: 2017/07/02 08:29:59.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

function! calendar#view#task#new(source) abort
  return s:constructor.new(a:source)
endfunction

let s:self = {}

let s:self._select_line = 1

function! s:self.get_key() dict abort
  return b:calendar.task.updated()
endfunction

function! s:self.get_raw_contents() dict abort
  return b:calendar.task.get_task()
endfunction

function! s:self.action(action) dict abort
  let task = self.current_contents()
  let taskid = get(task, 'id', '')
  let prevtask = self.prev_contents()
  let prevtaskid = get(prevtask, 'id', '')
  if index(['delete', 'delete_line'], a:action) >= 0
    if calendar#setting#get('yank_deleting')
      call self.yank()
    endif
    if calendar#setting#get('task_delete')
      if input(calendar#message#get('delete_task')) =~# '\c^y\%[es]$'
        call b:calendar.task.delete(self.current_group_id(), taskid)
      endif
    else
      call b:calendar.task.complete(self.current_group_id(), taskid)
    endif
  elseif index(['undo_line'], a:action) >= 0
    call b:calendar.task.uncomplete(self.current_group_id(), taskid)
  elseif index(['move_down', 'move_up'], a:action) >= 0
    let prevprevtaskid = get(self.prevprev_contents(), 'id', '')
    let nexttaskid = get(self.next_contents(), 'id', '')
    let newprevioustaskid = a:action ==# 'move_down' ? nexttaskid : prevprevtaskid
    if newprevioustaskid !=# '' || a:action ==# 'move_up'
      call b:calendar.task.move(self.current_group_id(), taskid, newprevioustaskid)
      let self.select += a:action ==# 'move_up' ? -1 : 1
    endif
  elseif index(['start_insert', 'start_insert_append', 'start_insert_head', 'start_insert_last', 'change', 'change_line'], a:action) >= 0
    if taskid !=# ''
      let head = index(['start_insert', 'start_insert_head'], a:action) >= 0
      let change = index(['change', 'change_line'], a:action) >= 0
      let msg = calendar#message#get('input_task') . (change ? get(task, 'title', '') . ' -> ' : '')
      let title = input(msg, change ? '' : get(task, 'title', '') . (head ? "\<Home>" : ''))
      if title !=# ''
        if get(task, 'title') =~# '\v^\d+[-/]\d+' && title !~# '\v^\s*\d+[-/]\d+'
          let duedate = '-1'
        else
          let [title, duedate] = s:parse_title(title)
        endif
        call b:calendar.task.update(self.current_group_id(), taskid, title, duedate ==# '' ? {} : { 'due': duedate })
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
      let [title, duedate] = s:parse_title(title)
      call b:calendar.task.insert(self.current_group_id(), next ? taskid : prevtaskid, title, duedate ==# '' ? {} : { 'due': duedate })
    endif
  elseif a:action ==# 'clear'
    if input(calendar#message#get('clear_completed_task')) =~# '^\cy\%[es]$'
      call b:calendar.task.clear_completed(self.current_group_id())
    endif
  else
    return self._action(a:action)
  endif
endfunction

function! s:parse_title(title) abort
  let title = a:title
  let duedate = ''
  let endian = calendar#setting#get('date_endian')
  if title =~# '\v^\s*\d+[-/]\d+([-/]\d+)?\s+'
    let time = matchstr(title, '\v^\s*\d+[-/]\d+([-/]\d+)?\s+')
    let title = substitute(title[len(time):], '^\s*', '', '')
    if time =~# '\v\d+[-/]\d+[-/]\d+'
      let [y, m, d] = split(substitute(time, '\s', '', 'g'), '[-/]')
      if d > 1000
        let [y, m, d] = endian ==# 'little' ? [d, m, y] : [d, y, m]
        if m > 12
          let [d, m] = [m, d]
        endif
      endif
      let duedate = join([y, m, d], '-')
    elseif time =~# '\v\d+[-/]\d+'
      let [m, d] = split(substitute(time, '\s', '', 'g'), '[-/]')
      if m > 12
        let [d, m] = [m, d]
      endif
      let [year, month, day] = b:calendar.day().get_ymd()
      let duedate = join([m < month - 1 ? year + 1 : year, m, d], '-')
    endif
  endif
  return [duedate ==# '' ? a:title : title, duedate . (duedate !=# '' ? 'T00:00:00.000Z' : '')]
endfunction

let s:constructor = calendar#constructor#view_textbox#new(s:self)

let &cpo = s:save_cpo
unlet s:save_cpo
