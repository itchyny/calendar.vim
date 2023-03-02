" =============================================================================
" Filename: autoload/calendar/cache.vim
" Author: itchyny
" License: MIT License
" Last Change: 2023/03/02 22:09:59.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

" Cache object.
function! calendar#cache#new(...) abort
  let self = copy(s:self)
  let self.subpath = a:0 ? a:1 : ''
  let self.subpath .= len(self.subpath) && self.subpath[len(self.subpath) - 1] !~ '^[/\\]$' ? '/' : ''
  call s:setfperm_dir(self.dir())
  return self
endfunction

function! calendar#cache#clear() abort
  for path in s:clearpath
    call delete(path, 'rf')
  endfor
endfunction

let s:clearpath = []

augroup CalendarCache
  autocmd!
  autocmd VimLeavePre * call calendar#cache#clear()
augroup END

let s:self = {}

function! s:self.new(...) dict abort
  return calendar#cache#new(self.subpath . (a:0 ? self.escape(a:1) : ''))
endfunction

function! s:self.escape(key) dict abort
  return substitute(a:key, '[^a-zA-Z0-9_.-]', '\=printf("%%%02X",char2nr(submatch(0)))', 'g')
endfunction

if has('win32')
  function! s:self.dir() dict abort
    return substitute(substitute(s:expand_homedir(calendar#setting#get('cache_directory')), '[/\\]$', '', '') . '/' . self.subpath, '/', '\', 'g')
  endfunction
else
  function! s:self.dir() dict abort
    return substitute(s:expand_homedir(calendar#setting#get('cache_directory')), '[/\\]$', '', '') . '/' . self.subpath
  endfunction
endif

function! s:expand_homedir(path) abort
  if a:path !~# '^[~]/'
    return a:path
  endif
  return expand('~') . a:path[1:]
endfunction

function! s:self.path(key) dict abort
  return self.dir() . self.escape(a:key)
endfunction

function! s:self.rmdir_on_exit() dict abort
  call add(s:clearpath, self.dir())
endfunction

function! s:self.check_dir(...) dict abort
  let dir = self.dir()
  if !get(a:000, 0)
    return !isdirectory(dir)
  endif
  if !isdirectory(dir)
    try
      call mkdir(dir, 'p')
      call s:setfperm(dir)
    catch
    endtry
  endif
  if !isdirectory(dir)
    call calendar#echo#error(calendar#message#get('mkdir_fail') . ': ' . dir)
    return 1
  endif
endfunction

function! s:self.save(key, val) dict abort
  if self.check_dir(1)
    return 1
  endif
  let path = self.path(a:key)
  if filereadable(path) && !filewritable(path)
    call calendar#echo#error(calendar#message#get('cache_file_unwritable') . ': ' . path)
    return 1
  endif
  try
    call writefile([json_encode(a:val)], path)
    call s:setfperm_file(path)
  catch
    call calendar#echo#error(calendar#message#get('cache_write_fail') . ': ' . path)
    return 1
  endtry
endfunction

function! s:self.get(key) dict abort
  if self.check_dir()
    return 1
  endif
  let path = self.path(a:key)
  if filereadable(path)
    call s:setfperm_file(path)
    let result = join(readfile(path), '')
    try " use js_decode to read contents saved before using JSON
      return exists('*js_decode') ? js_decode(result) : json_decode(result)
    catch
      return 1
    endtry
  else
    return 1
  endif
endfunction

function! s:self.get_raw(key) dict abort
  if self.check_dir()
    return 1
  endif
  let path = self.path(a:key)
  if filereadable(path)
    call s:setfperm_file(path)
    return readfile(path)
  else
    return 1
  endif
endfunction

function! s:self.delete(key) dict abort
  if self.check_dir()
    return 1
  endif
  let path = self.path(a:key)
  return delete(path)
endfunction

function! s:self.clear() dict abort
  call delete(self.dir(), 'rf')
endfunction

function! s:setfperm_dir(dir) abort
  let expected = 'rwx------'
  if getfperm(a:dir) !=# expected
    call setfperm(a:dir, expected)
  endif
endfunction
function! s:setfperm_file(path) abort
  let expected = 'rw-------'
  if getfperm(a:path) !=# expected
    call setfperm(a:path, expected)
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
