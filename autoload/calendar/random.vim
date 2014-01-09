" =============================================================================
" Filename: autoload/calendar/random.vim
" Author: itchyny
" License: MIT License
" Last Change: 2014/01/09 12:31:51.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

" Random seed.
if has('reltime')
  let rel = reltime() + reltime()
  if len(rel) > 3
    let [s:x, s:y, s:z, s:w; s:rest] = rel
  else
    let [s:x, s:y, s:z, s:w] = [1, 2, 3, 4]
  endif
else
  let [s:x, s:y, s:z, s:w] = [1, 2, 3, 4]
endif

" Random number.
"   calendar#random#number()     : an unbounded random integer number.
"   calendar#random#number(a)    : an unbounded random number larger than a.
"   calendar#random#number(a, b) : a random number from [a, a + b - 1].
function! calendar#random#number(...)
  let a = a:0 ? a:1 : 0
  let b = a:0 > 1 ? a:2 : 0x1000000
  let t = calendar#util#xor(s:x, (s:x * 0x800))
  let [s:x, s:y, s:z] = [s:y, s:z, s:w]
  let s:w = calendar#util#xor(calendar#util#xor(s:w, (s:w / 0x80000)), calendar#util#xor(t, (t / 0x100)))
  return (a + s:w) % b
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
