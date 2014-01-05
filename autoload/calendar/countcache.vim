" =============================================================================
" Filename: autoload/calendar/countcache.vim
" Author: itchyny
" License: MIT License
" Last Change: 2013/12/28 23:03:14.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

" CountCache object, caching anything with countdown.
" Caching is imporant for speeding up. However, storing everything causes the
" cache to grow bigger and bigger. For efficient caching, this CountCache object
" is used. Basically, data are stored with numbers.
"    [ num, data ]
" The number refers to how many times the data is referenced to. And when saving
" to the cache file, data are saved if the data was referenced many times enough.
" When restoring the data from the cache file, all the counts are subtracted
" one, so that data will disappear if it is not referenced to for a long time.

let s:cache = calendar#cache#new('countcache')
let s:caches = []

function! calendar#countcache#new(name)
  let self = extend(copy(s:self), { 'name': a:name })
  let cache = s:cache.get(a:name)
  " When restoring from the cache file, negate each count by 1.
  " Also, keep the number small (50 in max) so that the number will not overflow.
  let self.cache = type(cache) == type({}) ? map(cache, '[min([v:val[0] - 1, 50]), v:val[1]]') : {}
  call add(s:caches, self)
  return self
endfunction

" Saving the cache to the cache file.
function! calendar#countcache#save()
  for c in s:caches
    silent! call s:cache.save(c.name, filter(c.cache, 'v:val[0] > 29'))
  endfor
endfunction

augroup CalendarCountCache
  autocmd!
  autocmd VimLeavePre * silent! call calendar#countcache#save()
augroup END

let s:self = {}

" Check if the key is found in the cache.
function! s:self.has_key(k) dict
  return has_key(self.cache, a:k)
endfunction

" Be sure to check has_key before getting the data.
function! s:self.get(k) dict
  let self.cache[a:k][0] += 1
  return self.cache[a:k][1]
endfunction

" Save a data with a key.
function! s:self.save(k, v) dict
  let self.cache[a:k] = [ get(self.cache, a:k, [0])[0] + 1, a:v ]
  return a:v
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
