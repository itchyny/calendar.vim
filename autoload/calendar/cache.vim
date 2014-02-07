" =============================================================================
" Filename: autoload/calendar/cache.vim
" Author: itchyny
" License: MIT License
" Last Change: 2014/02/07 21:46:15.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

" Cache object.
function! calendar#cache#new(...)
  let self = copy(s:self)
  let self.subpath = a:0 ? a:1 : ''
  let self.subpath .= len(self.subpath) && self.subpath[len(self.subpath) - 1] !~ '^[/\\]$' ? '/' : ''
  return self
endfunction

function! calendar#cache#clear()
  for path in s:clearpath
    call calendar#util#rmdir(path, 'rf')
  endfor
endfunction

let s:clearpath = []

augroup CalendarCache
  autocmd!
  autocmd VimLeavePre * call calendar#cache#clear()
augroup END

let s:self = {}

function! s:self.new(...) dict
  return calendar#cache#new(self.subpath . (a:0 ? self.escape(a:1) : ''))
endfunction

function! s:self.escape(key) dict
  return substitute(a:key, '[^a-zA-Z0-9_.-]', '\=printf("%%%02X",char2nr(submatch(0)))', 'g')
endfunction

if has('win32') || has('win64')
  function! s:self.dir() dict
    return substitute(substitute(calendar#setting#get('cache_directory'), '[/\\]$', '', '') . '/' . self.subpath, '/', '\', 'g')
  endfunction
else
  function! s:self.dir() dict
    return substitute(calendar#setting#get('cache_directory'), '[/\\]$', '', '') . '/' . self.subpath
  endfunction
endif

function! s:self.path(key) dict
  return self.dir() . self.escape(a:key)
endfunction

function! s:self.rmdir_on_exit() dict
  call add(s:clearpath, self.dir())
endfunction

function! s:self.check_dir(...) dict
  let dir = self.dir()
  if !get(a:000, 0)
    return !isdirectory(dir)
  endif
  if !isdirectory(dir)
    try
      if exists('*mkdir')
        call mkdir(dir, 'p')
      else
        call calendar#util#system('mkdir -p ' .  shellescape(dir))
      endif
    catch
    endtry
  endif
  if !isdirectory(dir)
    call calendar#echo#error(calendar#message#get('mkdir_fail') . ': ' . dir)
    return 1
  endif
endfunction

function! s:self.save(key, val) dict
  if self.check_dir(1)
    return 1
  endif
  let path = self.path(a:key)
  if filereadable(path) && !filewritable(path)
    call calendar#echo#error(calendar#message#get('cache_file_unwritable') . ': ' . path)
    return 1
  endif
  try
    call writefile(calendar#cache#string(a:val), path)
  catch
    call calendar#echo#error(calendar#message#get('cache_write_fail') . ': ' . path)
    return 1
  endtry
endfunction

function! s:self.get(key) dict
  if self.check_dir()
    return 1
  endif
  let path = self.path(a:key)
  if filereadable(path)
    let result = readfile(path)
    try
      if len(result)
        sandbox return eval(join(result, ''))
      else
        return 1
      endif
    catch
      return 1
    endtry
  else
    return 1
  endif
endfunction

function! s:self.get_raw(key) dict
  if self.check_dir()
    return 1
  endif
  let path = self.path(a:key)
  if filereadable(path)
    return readfile(path)
  else
    return 1
  endif
endfunction

function! s:self.delete(key) dict
  if self.check_dir()
    return 1
  endif
  let path = self.path(a:key)
  return delete(path)
endfunction

" string() with making newlines and indents properly.
function! calendar#cache#string(v, ...)
  let r = []
  let f = 1
  let s = a:0 ? a:1 : ''
  if type(a:v) == type([])
    call add(r, '[ ')
    let s .= '  '
    for i in range(len(a:v))
      call add(r, s . string(a:v[i]) . ',')
    endfor
    if r[-1][len(r[-1]) - 1] ==# ','
      let r[-1] = r[-1][:-2]
    endif
    call add(r, ' ]')
  elseif type(a:v) == type({})
    call add(r, '{ ')
    let s .= '  '
    for k in keys(a:v)
      if type(a:v[k]) == type({}) || type(a:v[k]) == type([]) && len(a:v[k]) > 2
        let result = calendar#cache#string(a:v[k], s . repeat(' ', len(string(k)) + 2))
        let result[-1] .= ','
        call add(r, s . string(k) . ': ' . result[0])
        call remove(result, 0)
        call extend(r, result)
      else
        call add(r, s . string(k) . ': ' . string(a:v[k]) . ',')
      endif
    endfor
    if r[-1][len(r[-1]) - 1] ==# ','
      let r[-1] = r[-1][:-2]
    endif
    call add(r, ' }')
  else
    call add(r, s . string(a:v))
    let f = 0
  endif
  if f
    if len(r[1]) > len(s) + 1
      let r[1] = r[1][len(s):]
    endif
    let r[0] .= r[1]
    call remove(r, 1)
    if len(r) > 1
      let r[-2] .= r[-1]
      call remove(r, -1)
    endif
  endif
  return r
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
